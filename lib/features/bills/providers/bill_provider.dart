import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../models/bill.dart';

class BillProvider extends ChangeNotifier {
  final List<Bill> _bills = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _statusFilter = 'All';

  List<Bill> get bills => _bills;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  List<Bill> get filteredBills {
    return _bills.where((bill) {
      final matchesSearch = _searchQuery.trim().isEmpty ||
          bill.billNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          bill.vendorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          bill.referenceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          bill.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == 'All' ||
          bill.status.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  String getNextBillNumber() {
    int maxNum = 0;
    for (final b in _bills) {
      final match = RegExp(r'(\d+)').firstMatch(b.billNumber);
      if (match != null) {
        final val = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (val > maxNum) maxNum = val;
      }
    }
    final next = maxNum + 1;
    return 'BILL-${next.toString().padLeft(3, '0')}';
  }

  Future<void> fetchBills({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/v1/bills');
      if (response['statusCode'] != null && response['statusCode'] >= 400) {
        _errorMessage = response['message']?.toString();
      } else {
        List<dynamic> list = [];
        final rawData = response['results'] ?? response['data'] ?? response['content'];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map) {
          if (rawData['results'] is List) {
            list = rawData['results'] as List<dynamic>;
          } else if (rawData['content'] is List) {
            list = rawData['content'] as List<dynamic>;
          } else if (rawData['items'] is List) {
            list = rawData['items'] as List<dynamic>;
          }
        } else if (response['results'] is List) {
          list = response['results'] as List<dynamic>;
        }

        _bills.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _bills.add(Bill.fromJson(item));
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

  Future<Bill?> createBill(Bill bill) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = bill.toApiJson();
      final response = await ApiService().post(
        '/api/v1/bills',
        payload,
      );

      if (response['statusCode'] != null && response['statusCode'] >= 400) {
        _errorMessage = response['message']?.toString() ?? 'Failed to create bill';
        debugPrint('API Error creating bill: $_errorMessage');
      }

      Bill created;
      if (response['success'] == true && response['data'] != null) {
        created = Bill.fromJson(response['data'] as Map<String, dynamic>);
      } else if (response.containsKey('id') || response.containsKey('bill_number')) {
        created = Bill.fromJson(response);
      } else {
        created = bill.copyWith(
          id: bill.id.isEmpty
              ? 'bill_${DateTime.now().millisecondsSinceEpoch}'
              : bill.id,
        );
      }
      _bills.insert(0, created);
      return created;
    } catch (e) {
      debugPrint('Exception creating bill via API: $e');
      _errorMessage = e.toString();
      // Save locally as fallback
      final fallback = bill.copyWith(
        id: bill.id.isEmpty
            ? 'bill_${DateTime.now().millisecondsSinceEpoch}'
            : bill.id,
      );
      _bills.insert(0, fallback);
      return fallback;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateBill(Bill bill) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = bill.toApiJson();
      await ApiService().put('/api/v1/bills/${bill.id}', payload);
      final index = _bills.indexWhere((b) => b.id == bill.id);
      if (index != -1) {
        _bills[index] = bill;
      }
      return true;
    } catch (e) {
      debugPrint('Exception updating bill via API: $e');
      _errorMessage = e.toString();
      final index = _bills.indexWhere((b) => b.id == bill.id);
      if (index != -1) {
        _bills[index] = bill;
      }
      return true;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBill(String id) async {
    try {
      await ApiService().delete('/api/v1/bills/$id');
    } catch (_) {}
    _bills.removeWhere((b) => b.id == id);
    notifyListeners();
    return true;
  }

  Future<void> updateBillStatus(String id, String status) async {
    final index = _bills.indexWhere((b) => b.id == id);
    if (index != -1) {
      final updated = _bills[index].copyWith(status: status);
      _bills[index] = updated;
      notifyListeners();
      try {
        await ApiService().patch('/api/v1/bills/$id/status', {'status': status});
      } catch (_) {}
    }
  }
}
