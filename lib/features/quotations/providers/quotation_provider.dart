import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../invoices/models/invoice_item.dart';
import '../../invoices/providers/invoice_provider.dart';
import '../../products/models/product.dart';
import '../models/quotation.dart';

class QuotationProvider extends ChangeNotifier {
  final List<Quotation> _quotations = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Draft', 'Sent', 'Accepted', 'Rejected', 'Expired', 'Converted'
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  // Pagination metadata from backend
  int _currentPage = 1;
  int _pageSize = 50;
  int _totalCount = 0;
  int _totalPages = 1;

  Quotation? _editingQuotation;

  List<Quotation> get quotations => _quotations;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  DateTime? get startDateFilter => _startDateFilter;
  DateTime? get endDateFilter => _endDateFilter;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount > 0 ? _totalCount : _quotations.length;
  Quotation? get editingQuotation => _editingQuotation;

  List<Quotation> get filteredQuotations {
    return _quotations.where((q) {
      final matchesSearch = _searchQuery.trim().isEmpty ||
          q.quotationNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          q.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          q.referenceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          q.salesperson.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          q.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          q.mobileNumber.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == 'All' ||
          q.status.displayName.toLowerCase() == _statusFilter.toLowerCase() ||
          q.status.apiValue.toLowerCase() == _statusFilter.toLowerCase();

      final matchesStart = _startDateFilter == null || !q.quotationDate.isBefore(_startDateFilter!);
      final matchesEnd = _endDateFilter == null || !q.quotationDate.isAfter(_endDateFilter!);

      return matchesSearch && matchesStatus && matchesStart && matchesEnd;
    }).toList()
      ..sort((a, b) => b.quotationDate.compareTo(a.quotationDate));
  }

  // Summary Metrics
  int get draftCount => _quotations.where((q) => q.status == QuotationStatus.draft).length;
  int get sentCount => _quotations.where((q) => q.status == QuotationStatus.sent).length;
  int get acceptedCount => _quotations.where((q) => q.status == QuotationStatus.accepted).length;
  int get rejectedCount => _quotations.where((q) => q.status == QuotationStatus.rejected).length;
  int get expiredCount => _quotations.where((q) => q.status == QuotationStatus.expired).length;
  int get convertedCount => _quotations.where((q) => q.status == QuotationStatus.converted).length;

  double get totalValue => _quotations.fold(0.0, (sum, q) => sum + q.grandTotal);
  double get acceptedValue => _quotations
      .where((q) => q.status == QuotationStatus.accepted || q.status == QuotationStatus.converted)
      .fold(0.0, (sum, q) => sum + q.grandTotal);

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setDateRange({DateTime? startDate, DateTime? endDate}) {
    _startDateFilter = startDate;
    _endDateFilter = endDate;
    notifyListeners();
  }

  void setEditingQuotation(Quotation? quotation) {
    _editingQuotation = quotation;
    notifyListeners();
  }

  String getNextQuotationNumber({String prefix = 'EST'}) {
    int maxNum = 0;
    for (final q in _quotations) {
      final match = RegExp(r'(\d+)').firstMatch(q.quotationNumber);
      if (match != null) {
        final val = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (val > maxNum) maxNum = val;
      }
    }
    final next = maxNum + 1;
    return '$prefix-${next.toString().padLeft(6, '0')}';
  }

  Quotation? getQuotationById(String id) {
    try {
      return _quotations.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 1. List Estimates (Filter / Pagination) via GET /api/v1/estimates
  Future<void> fetchQuotations({
    bool refresh = false,
    int page = 1,
    int? pageSize,
    String? search,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_isLoading && !refresh) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPage = page;
      if (pageSize != null) _pageSize = pageSize;

      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'page_size': _pageSize.toString(),
      };

      final qSearch = search ?? _searchQuery;
      if (qSearch.trim().isNotEmpty) {
        queryParams['search'] = qSearch.trim();
      }

      final qStatus = status ?? _statusFilter;
      if (qStatus != 'All') {
        final parsed = QuotationStatus.fromString(qStatus);
        queryParams['status'] = parsed.apiValue;
      }

      final sDate = startDate ?? _startDateFilter;
      if (sDate != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(sDate);
      }

      final eDate = endDate ?? _endDateFilter;
      if (eDate != null) {
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(eDate);
      }

      final uri = Uri(
        path: '/api/v1/estimates',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      Map<String, dynamic>? response;
      try {
        response = await ApiService().get(uri.toString());
      } catch (_) {
        // Fallback endpoint if needed
        try {
          response = await ApiService().get('/api/v1/quotations');
        } catch (_) {}
      }

      if (response != null && (response['statusCode'] == null || response['statusCode'] < 400)) {
        List<dynamic> list = [];
        final dataNode = response['data'];

        if (dataNode is Map<String, dynamic>) {
          if (dataNode['count'] is num) _totalCount = (dataNode['count'] as num).toInt();
          if (dataNode['page'] is num) _currentPage = (dataNode['page'] as num).toInt();
          if (dataNode['total_pages'] is num) _totalPages = (dataNode['total_pages'] as num).toInt();

          final rawResults = dataNode['results'] ?? dataNode['items'] ?? dataNode['content'];
          if (rawResults is List) {
            list = rawResults;
          }
        } else if (dataNode is List) {
          list = dataNode;
        } else if (response['results'] is List) {
          list = response['results'] as List<dynamic>;
        }

        if (list.isNotEmpty) {
          _quotations.clear();
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              _quotations.add(Quotation.fromJson(item));
            }
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 3. Get Estimate Details via GET /api/v1/estimates/{id}
  Future<Quotation?> getEstimateById(String id) async {
    try {
      final response = await ApiService().get('/api/v1/estimates/$id');
      if (response['data'] is Map<String, dynamic>) {
        final estimate = Quotation.fromJson(response['data'] as Map<String, dynamic>);
        final idx = _quotations.indexWhere((q) => q.id == estimate.id);
        if (idx >= 0) {
          _quotations[idx] = estimate;
        } else {
          _quotations.insert(0, estimate);
        }
        notifyListeners();
        return estimate;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return getQuotationById(id);
  }

  /// 2 & 4. Create or Update Estimate via POST/PUT /api/v1/estimates
  Future<bool> saveQuotation(Quotation quotation) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isExisting = _quotations.any((q) => q.id == quotation.id && q.id.length > 10 && !q.id.contains('-local'));
      Map<String, dynamic>? response;
      final payload = quotation.toJson();

      if (isExisting) {
        // Update Estimate: PUT or PATCH /api/v1/estimates/{id}
        try {
          response = await ApiService().put('/api/v1/estimates/${quotation.id}', payload);
        } catch (_) {
          try {
            response = await ApiService().patch('/api/v1/estimates/${quotation.id}', payload);
          } catch (_) {}
        }
      } else {
        // Create Estimate: POST /api/v1/estimates
        try {
          response = await ApiService().post('/api/v1/estimates', payload);
        } catch (_) {
          try {
            response = await ApiService().post('/api/v1/quotations', payload);
          } catch (_) {}
        }
      }

      Quotation saved = quotation;
      if (response != null && response['data'] is Map<String, dynamic>) {
        final respData = response['data'] as Map<String, dynamic>;
        saved = quotation.copyWith(
          id: (respData['id'] ?? quotation.id).toString(),
          quotationNumber: (respData['estimate_number'] ?? respData['quotation_number'] ?? quotation.quotationNumber).toString(),
          status: respData['status'] != null ? QuotationStatus.fromString(respData['status'].toString()) : quotation.status,
          grandTotal: respData['grand_total'] != null ? (respData['grand_total'] as num).toDouble() : quotation.grandTotal,
        );
      }

      final index = _quotations.indexWhere((q) => q.id == saved.id || (q.quotationNumber.isNotEmpty && q.quotationNumber == saved.quotationNumber));
      if (index >= 0) {
        _quotations[index] = saved;
      } else {
        _quotations.insert(0, saved);
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// 5. Delete Estimate (Soft Delete) via DELETE /api/v1/estimates/{id}
  Future<bool> deleteQuotation(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      try {
        await ApiService().delete('/api/v1/estimates/$id');
      } catch (_) {
        try {
          await ApiService().delete('/api/v1/quotations/$id');
        } catch (_) {}
      }

      _quotations.removeWhere((q) => q.id == id);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// 6. Restore Deleted Estimate via POST /api/v1/estimates/{id}/restore
  Future<bool> restoreQuotation(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/v1/estimates/$id/restore', {});
      if (response['data'] is Map<String, dynamic>) {
        final restored = Quotation.fromJson(response['data'] as Map<String, dynamic>);
        final idx = _quotations.indexWhere((q) => q.id == id);
        if (idx >= 0) {
          _quotations[idx] = restored;
        } else {
          _quotations.insert(0, restored);
        }
      } else {
        await fetchQuotations(refresh: true);
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Update Estimate status directly
  Future<bool> updateStatus(String id, QuotationStatus status) async {
    final index = _quotations.indexWhere((q) => q.id == id);
    if (index < 0) return false;

    try {
      try {
        await ApiService().patch('/api/v1/estimates/$id', {'status': status.apiValue});
      } catch (_) {
        try {
          await ApiService().put('/api/v1/estimates/$id', {'status': status.apiValue});
        } catch (_) {}
      }

      _quotations[index] = _quotations[index].copyWith(status: status, updatedAt: DateTime.now());
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 7. Convert Estimate to Invoice via POST /api/v1/estimates/{id}/convert-to-invoice
  Future<Map<String, dynamic>> convertToInvoice(Quotation quotation, BuildContext context) async {
    final invoiceProvider = context.read<InvoiceProvider>();
    try {
      Map<String, dynamic>? response;
      try {
        response = await ApiService().post('/api/v1/estimates/${quotation.id}/convert-to-invoice', {});
      } catch (_) {}

      String? invoiceId;
      String? invoiceNumber;

      if (response != null && response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        invoiceId = data['invoice_id']?.toString();
        invoiceNumber = data['invoice_number']?.toString();
      }

      // Mark the quotation as converted locally
      final index = _quotations.indexWhere((q) => q.id == quotation.id);
      if (index >= 0) {
        _quotations[index] = _quotations[index].copyWith(status: QuotationStatus.converted, updatedAt: DateTime.now());
      }

      // Also sync state with InvoiceProvider so the newly converted invoice draft is ready
      invoiceProvider.startNewInvoice();

      if (quotation.customer != null) {
        invoiceProvider.selectCustomer(quotation.customer!);
      }

      invoiceProvider.updateNotes(quotation.notes);
      invoiceProvider.updateTerms(quotation.termsAndConditions);

      for (final item in quotation.items) {
        final dummyProduct = Product(
          id: item.productId ?? DateTime.now().microsecondsSinceEpoch.toString(),
          name: item.name,
          sku: item.hsnSac.isNotEmpty ? item.hsnSac : 'ITEM-${DateTime.now().microsecondsSinceEpoch}',
          description: item.description,
          category: 'General',
          brand: 'General',
          stock: 100,
          minStock: 10,
          purchasePrice: 0.0,
          sellingPrice: item.unitPrice,
          unitOfMeasurement: item.unit,
          unitAbbreviation: item.unit,
          gst: item.gstRate,
          hsnSacCode: item.hsnSac,
          createdAt: DateTime.now(),
        );

        final invoiceItem = InvoiceItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          product: dummyProduct,
          quantity: item.quantity.toInt() > 0 ? item.quantity.toInt() : 1,
          unitPrice: item.unitPrice,
          description: item.description,
          discountPercentage: item.discountType == '%' ? item.discount : 0.0,
          taxPercentage: item.gstRate,
          discountType: item.discountType,
          discountValue: item.discount,
          hsnSac: item.hsnSac,
          unit: item.unit,
          itemName: item.name,
        );

        invoiceProvider.addItem(invoiceItem);
      }

      notifyListeners();

      return {
        'success': true,
        'invoice_id': invoiceId,
        'invoice_number': invoiceNumber,
      };
    } catch (e) {
      _errorMessage = 'Failed to convert estimate to invoice: $e';
      notifyListeners();
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
