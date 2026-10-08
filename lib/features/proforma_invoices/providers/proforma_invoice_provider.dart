import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../models/proforma_invoice.dart';

class ProformaInvoiceProvider extends ChangeNotifier {
  final List<ProformaInvoice> _proformaInvoices = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Filter state
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Draft', 'Sent', 'Invoiced', 'Expired', 'Approved', 'Cancelled'
  DateTime? _startDate;
  DateTime? _endDate;

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  int _pageSize = 10;
  String? _nextPageUrl;
  String? _previousPageUrl;

  ProformaInvoice? _editingProforma;
  Timer? _debounceTimer;

  List<ProformaInvoice> get proformaInvoices => _proformaInvoices;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  int get pageSize => _pageSize;
  String? get nextPageUrl => _nextPageUrl;
  String? get previousPageUrl => _previousPageUrl;
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;
  ProformaInvoice? get editingProforma => _editingProforma;

  List<ProformaInvoice> get filteredProformaInvoices => _proformaInvoices;

  // Summary Metrics
  int get draftCount => _proformaInvoices.where((p) => p.status == ProformaStatus.draft).length;
  int get sentCount => _proformaInvoices.where((p) => p.status == ProformaStatus.sent).length;
  int get invoicedCount => _proformaInvoices.where((p) => p.status == ProformaStatus.invoiced).length;
  int get expiredCount => _proformaInvoices.where((p) => p.status == ProformaStatus.expired).length;
  double get totalValue => _proformaInvoices.fold(0.0, (sum, p) => sum + p.grandTotal);

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void setSearchQuery(String query, {bool immediate = false}) {
    _searchQuery = query;
    _debounceTimer?.cancel();
    if (immediate) {
      _currentPage = 1;
      fetchProformaInvoices(refresh: true);
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        _currentPage = 1;
        fetchProformaInvoices(refresh: true);
      });
    }
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    if (_statusFilter == filter) return;
    _statusFilter = filter;
    _currentPage = 1;
    notifyListeners();
    fetchProformaInvoices(refresh: true);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _currentPage = 1;
    notifyListeners();
    fetchProformaInvoices(refresh: true);
  }

  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    _currentPage = 1;
    notifyListeners();
    fetchProformaInvoices(refresh: true);
  }

  void setPageSize(int size) {
    if (_pageSize == size) return;
    _pageSize = size;
    _currentPage = 1;
    notifyListeners();
    fetchProformaInvoices(refresh: true);
  }

  void goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    fetchProformaInvoices(page: page);
  }

  void setEditingProforma(ProformaInvoice? proforma) {
    _editingProforma = proforma;
    notifyListeners();
  }

  String getNextProformaNumber({String prefix = 'PFI'}) {
    int maxNum = 0;
    for (final p in _proformaInvoices) {
      final match = RegExp(r'(\d+)').firstMatch(p.proformaNumber);
      if (match != null) {
        final val = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (val > maxNum) maxNum = val;
      }
    }
    final next = maxNum + 1;
    return '$prefix-${next.toString().padLeft(6, '0')}';
  }

  ProformaInvoice? getProformaById(String id) {
    try {
      return _proformaInvoices.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  String _mapStatusToApi(String filter) {
    switch (filter.toLowerCase().trim()) {
      case 'draft':
        return 'draft';
      case 'sent':
        return 'sent';
      case 'invoiced':
      case 'converted':
        return 'invoiced';
      case 'expired':
        return 'expired';
      case 'approved':
        return 'approved';
      case 'cancelled':
        return 'cancelled';
      default:
        return '';
    }
  }

  /// 1. List Proforma Invoices with pagination and filters
  Future<void> fetchProformaInvoices({bool refresh = false, int? page}) async {
    final targetPage = page ?? (refresh ? 1 : _currentPage);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String>[
        'page=$targetPage',
        'page_size=$_pageSize',
      ];

      if (_searchQuery.trim().isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(_searchQuery.trim())}');
      }

      final apiStatus = _mapStatusToApi(_statusFilter);
      if (apiStatus.isNotEmpty) {
        queryParams.add('status=$apiStatus');
      }

      if (_startDate != null) {
        queryParams.add('start_date=${DateFormat('yyyy-MM-dd').format(_startDate!)}');
      }

      if (_endDate != null) {
        queryParams.add('end_date=${DateFormat('yyyy-MM-dd').format(_endDate!)}');
      }

      final url = '/api/v1/proforma-invoices/?${queryParams.join('&')}';
      debugPrint('Fetching proforma invoices: $url');
      final response = await ApiService().get(url);

      if (response['success'] == true || (response['statusCode'] == null || response['statusCode'] < 400)) {
        final data = response['data'];
        List<dynamic> results = [];

        if (data is Map<String, dynamic>) {
          _totalCount = (data['count'] as num?)?.toInt() ?? 0;
          _currentPage = (data['page'] as num?)?.toInt() ?? targetPage;
          _totalPages = (data['total_pages'] as num?)?.toInt() ?? 1;
          _nextPageUrl = data['next']?.toString();
          _previousPageUrl = data['previous']?.toString();

          if (data['results'] is List) {
            results = data['results'] as List<dynamic>;
          }
        } else if (data is List) {
          results = data;
          _totalCount = results.length;
          _currentPage = 1;
          _totalPages = 1;
        } else if (response['results'] is List) {
          results = response['results'] as List<dynamic>;
          _totalCount = results.length;
        }

        _proformaInvoices.clear();
        for (final item in results) {
          if (item is Map<String, dynamic>) {
            _proformaInvoices.add(ProformaInvoice.fromJson(item));
          }
        }
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to load proforma invoices';
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching proforma invoices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 3. Get Proforma Invoice Details
  Future<ProformaInvoice?> fetchProformaDetails(String id) async {
    try {
      final response = await ApiService().get('/api/v1/proforma-invoices/$id/');
      if (response['success'] == true && response['data'] is Map<String, dynamic>) {
        final p = ProformaInvoice.fromJson(response['data'] as Map<String, dynamic>);
        final index = _proformaInvoices.indexWhere((item) => item.id == id);
        if (index >= 0) {
          _proformaInvoices[index] = p;
        } else {
          _proformaInvoices.add(p);
        }
        notifyListeners();
        return p;
      }
    } catch (e) {
      debugPrint('Error fetching proforma invoice details: $e');
    }
    return getProformaById(id);
  }

  /// 2. Create Proforma Invoice
  Future<bool> createProformaInvoice(ProformaInvoice proforma) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = proforma.toCreatePayload();
      debugPrint('Creating proforma invoice payload: $payload');
      final response = await ApiService().post('/api/v1/proforma-invoices/', payload);

      if (response['success'] == true || (response['statusCode'] != null && response['statusCode'] < 300)) {
        await fetchProformaInvoices(refresh: true);
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to create proforma invoice';
        _isSaving = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// 4. Update Proforma Invoice (Full or Partial)
  Future<bool> updateProformaInvoice(String id, ProformaInvoice proforma) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = proforma.toUpdatePayload();
      debugPrint('Updating proforma invoice payload: $payload');
      final response = await ApiService().put('/api/v1/proforma-invoices/$id/', payload);

      if (response['success'] == true || (response['statusCode'] != null && response['statusCode'] < 300)) {
        await fetchProformaInvoices(refresh: true);
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to update proforma invoice';
        _isSaving = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Save helper
  Future<bool> saveProformaInvoice(ProformaInvoice proforma) async {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    final isExistingBackend = uuidRegex.hasMatch(proforma.id) && _proformaInvoices.any((p) => p.id == proforma.id);

    if (isExistingBackend) {
      return updateProformaInvoice(proforma.id, proforma);
    } else {
      return createProformaInvoice(proforma);
    }
  }

  /// 4. Update Status (Partial PATCH)
  Future<bool> updateStatus(
    String id,
    ProformaStatus status, {
    String? notes,
    DateTime? dueDate,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'status': status.toApiString,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (dueDate != null) 'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
      };

      final response = await ApiService().patch('/api/v1/proforma-invoices/$id/', payload);

      if (response['success'] == true || (response['statusCode'] != null && response['statusCode'] < 300)) {
        final index = _proformaInvoices.indexWhere((p) => p.id == id);
        if (index >= 0) {
          _proformaInvoices[index] = _proformaInvoices[index].copyWith(status: status, updatedAt: DateTime.now());
        }
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to update status';
        _isSaving = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// 5. Delete Proforma Invoice (Soft-delete)
  Future<bool> deleteProformaInvoice(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().delete('/api/v1/proforma-invoices/$id/');

      if (response['success'] == true || (response['statusCode'] != null && response['statusCode'] < 300)) {
        _proformaInvoices.removeWhere((p) => p.id == id);
        if (_totalCount > 0) _totalCount--;
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to delete proforma invoice';
        _isSaving = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// 6. Restore Proforma Invoice
  Future<bool> restoreProformaInvoice(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/v1/proforma-invoices/$id/restore/', {});

      if (response['success'] == true || (response['statusCode'] != null && response['statusCode'] < 300)) {
        await fetchProformaInvoices(refresh: true);
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to restore proforma invoice';
        _isSaving = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// 7. Convert to Final Sales Invoice
  Future<Map<String, dynamic>?> convertToInvoice(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/v1/proforma-invoices/$id/convert-to-invoice/', {});

      if (response['success'] == true || (response['statusCode'] != null && response['statusCode'] < 300)) {
        // Update local proforma status to invoiced
        final index = _proformaInvoices.indexWhere((p) => p.id == id);
        if (index >= 0) {
          _proformaInvoices[index] = _proformaInvoices[index].copyWith(status: ProformaStatus.invoiced, updatedAt: DateTime.now());
        }
        _isSaving = false;
        notifyListeners();
        return (response['data'] as Map<String, dynamic>?) ?? {};
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to convert to invoice';
        _isSaving = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }
}

