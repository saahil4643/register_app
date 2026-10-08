import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../models/credit_note.dart';

class CreditNoteProvider extends ChangeNotifier {
  final List<CreditNote> _creditNotes = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Filter state
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Open', 'Partially Applied', 'Refunded', 'Closed', 'Draft'
  DateTime? _startDate;
  DateTime? _endDate;

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  int _pageSize = 10;
  String? _nextPageUrl;
  String? _previousPageUrl;

  CreditNote? _editingCreditNote;
  Timer? _debounceTimer;

  List<CreditNote> get creditNotes => _creditNotes;
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
  CreditNote? get editingCreditNote => _editingCreditNote;

  /// Returns list of credit notes. When API pagination is active, creditNotes is already filtered.
  List<CreditNote> get filteredCreditNotes => _creditNotes;

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
      fetchCreditNotes(refresh: true);
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        _currentPage = 1;
        fetchCreditNotes(refresh: true);
      });
    }
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    if (_statusFilter == filter) return;
    _statusFilter = filter;
    _currentPage = 1;
    notifyListeners();
    fetchCreditNotes(refresh: true);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _currentPage = 1;
    notifyListeners();
    fetchCreditNotes(refresh: true);
  }

  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    _currentPage = 1;
    notifyListeners();
    fetchCreditNotes(refresh: true);
  }

  void setPageSize(int size) {
    if (_pageSize == size) return;
    _pageSize = size;
    _currentPage = 1;
    notifyListeners();
    fetchCreditNotes(refresh: true);
  }

  void goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    fetchCreditNotes(page: page);
  }

  void setEditingCreditNote(CreditNote? creditNote) {
    _editingCreditNote = creditNote;
    notifyListeners();
  }

  String getNextCreditNoteNumber({String prefix = 'CN'}) {
    int maxNum = 0;
    for (final cn in _creditNotes) {
      final match = RegExp(r'(\d+)').firstMatch(cn.creditNoteNumber);
      if (match != null) {
        final val = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (val > maxNum) maxNum = val;
      }
    }
    final next = maxNum + 1;
    return '$prefix-${next.toString().padLeft(6, '0')}';
  }

  CreditNote? getCreditNoteById(String id) {
    try {
      return _creditNotes.firstWhere((cn) => cn.id == id);
    } catch (_) {
      return null;
    }
  }

  String _mapStatusToApi(String filter) {
    switch (filter.toLowerCase().trim()) {
      case 'open':
      case 'open (unapplied)':
        return 'open';
      case 'partially applied':
        return 'partially_applied';
      case 'refunded':
        return 'refunded';
      case 'closed':
        return 'closed';
      case 'draft':
        return 'draft';
      default:
        return '';
    }
  }

  /// 1. List Credit Notes with pagination and filters
  Future<void> fetchCreditNotes({bool refresh = false, int? page}) async {
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

      final url = '/api/v1/credit-notes/?${queryParams.join('&')}';
      debugPrint('Fetching credit notes: $url');
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

        _creditNotes.clear();
        for (final item in results) {
          if (item is Map<String, dynamic>) {
            _creditNotes.add(CreditNote.fromJson(item));
          }
        }
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to load credit notes';
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching credit notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 3. Get Credit Note Details (with line items and customer info)
  Future<CreditNote?> fetchCreditNoteDetails(String id) async {
    try {
      final response = await ApiService().get('/api/v1/credit-notes/$id/');
      if (response['success'] == true && response['data'] is Map<String, dynamic>) {
        final cn = CreditNote.fromJson(response['data'] as Map<String, dynamic>);
        final index = _creditNotes.indexWhere((item) => item.id == id);
        if (index >= 0) {
          _creditNotes[index] = cn;
        } else {
          _creditNotes.add(cn);
        }
        notifyListeners();
        return cn;
      }
    } catch (e) {
      debugPrint('Error fetching credit note details: $e');
    }
    return getCreditNoteById(id);
  }

  /// 2. Create Credit Note
  Future<bool> createCreditNote(CreditNote creditNote) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = creditNote.toCreatePayload();
      debugPrint('Creating credit note payload: $payload');
      final response = await ApiService().post('/api/v1/credit-notes/', payload);

      if (response['success'] == true || (response['statusCode'] != null && response['statusCode'] < 300)) {
        await fetchCreditNotes(refresh: true);
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to create credit note';
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

  /// 4. Update Credit Note (Full or Partial)
  Future<bool> updateCreditNote(String id, CreditNote creditNote) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = creditNote.toUpdatePayload();
      debugPrint('Updating credit note payload: $payload');
      final response = await ApiService().put('/api/v1/credit-notes/$id/', payload);

      if (response['success'] == true || (response['statusCode'] != null && response['statusCode'] < 300)) {
        await fetchCreditNotes(refresh: true);
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to update credit note';
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

  /// Save method that switches between create and update based on existence
  Future<bool> saveCreditNote(CreditNote creditNote) async {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    final isExistingBackend = uuidRegex.hasMatch(creditNote.id) && _creditNotes.any((cn) => cn.id == creditNote.id);

    if (isExistingBackend) {
      return updateCreditNote(creditNote.id, creditNote);
    } else {
      return createCreditNote(creditNote);
    }
  }

  /// 4. Update Status (Partial PATCH)
  Future<bool> updateStatus(
    String id,
    CreditNoteStatus status, {
    String? reason,
    String? notes,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'status': status.toApiString,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await ApiService().patch('/api/v1/credit-notes/$id/', payload);

      if (response['success'] == true || (response['statusCode'] != null && response['statusCode'] < 300)) {
        final index = _creditNotes.indexWhere((cn) => cn.id == id);
        if (index >= 0) {
          _creditNotes[index] = _creditNotes[index].copyWith(status: status, updatedAt: DateTime.now());
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

  /// 5. Delete Credit Note (Soft-delete)
  Future<bool> deleteCreditNote(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().delete('/api/v1/credit-notes/$id/');

      if (response['success'] == true || (response['statusCode'] != null && response['statusCode'] < 300)) {
        _creditNotes.removeWhere((cn) => cn.id == id);
        if (_totalCount > 0) _totalCount--;
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to delete credit note';
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

  /// 6. Restore Credit Note
  Future<bool> restoreCreditNote(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/v1/credit-notes/$id/restore/', {});

      if (response['success'] == true || (response['statusCode'] != null && response['statusCode'] < 300)) {
        await fetchCreditNotes(refresh: true);
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to restore credit note';
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
}

