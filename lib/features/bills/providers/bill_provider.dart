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
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/v1/bills');
      if (response['success'] == true && response['data'] != null) {
        final rawData = response['data'];
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['results'] is List) {
          list = rawData['results'] as List<dynamic>;
        }
        _bills.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _bills.add(Bill.fromJson(item));
          }
        }
      }
    } catch (_) {
      // Populated with fallback mock data if API is not yet available
      if (_bills.isEmpty) {
        _populateDefaultBills();
      }
    } finally {
      if (_bills.isEmpty) {
        _populateDefaultBills();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Bill?> createBill(Bill bill) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post(
        '/api/v1/bills',
        bill.toJson(),
      );

      Bill created;
      if (response['success'] == true && response['data'] != null) {
        created = Bill.fromJson(response['data'] as Map<String, dynamic>);
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
      await ApiService().put('/api/v1/bills/${bill.id}', bill.toJson());
      final index = _bills.indexWhere((b) => b.id == bill.id);
      if (index != -1) {
        _bills[index] = bill;
      }
      return true;
    } catch (_) {
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

  void _populateDefaultBills() {
    if (_bills.isNotEmpty) return;
    _bills.addAll([
      Bill(
        id: 'bill_001',
        billNumber: 'BILL-001',
        vendorId: 'v_1',
        vendorName: 'Apex Logistics',
        category: 'Logistics & Freight',
        billDate: DateTime.now().subtract(const Duration(days: 6)),
        dueDate: DateTime.now().add(const Duration(days: 24)),
        referenceNumber: 'INV-APEX-9012',
        items: [
          BillItem(
            id: 'item_b1',
            name: 'Fleet Transport & Warehousing Charges',
            hsnCode: '996511',
            quantity: 1,
            unit: 'Nos',
            rate: 28000.0,
            gstRate: 18.0,
            discount: 0.0,
            discountType: 'amount',
          ),
          BillItem(
            id: 'item_b2',
            name: 'Transit Cargo Insurance Fee',
            hsnCode: '997133',
            quantity: 1,
            unit: 'Nos',
            rate: 2500.0,
            gstRate: 18.0,
            discount: 250.0,
            discountType: 'amount',
          ),
        ],
        subtotal: 30500.0,
        totalDiscount: 250.0,
        totalTax: 5445.0,
        totalAmount: 35695.0,
        paidAmount: 0.0,
        paymentMode: 'Bank Transfer',
        status: 'Pending',
        notes: 'Monthly billing for north-zone regional transit.',
        internalNote: 'Checked with warehouse gate entry logs.',
        termsAndConditions: '1. Bill is payable within the agreed credit period.\n2. Late payments will attract interest as per agreed terms.\n3. Discrepancies must be reported within 7 days of receipt.\n4. All disputes are subject to PUNE jurisdiction only.',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      Bill(
        id: 'bill_002',
        billNumber: 'BILL-002',
        vendorId: 'v_2',
        vendorName: 'CloudScale Tech',
        category: 'IT & Software',
        billDate: DateTime.now().subtract(const Duration(days: 2)),
        dueDate: DateTime.now().add(const Duration(days: 28)),
        referenceNumber: 'TAX-CS-3841',
        items: [
          BillItem(
            id: 'item_b3',
            name: 'API Infrastructure & Database Cluster',
            hsnCode: '998315',
            quantity: 1,
            unit: 'Nos',
            rate: 15000.0,
            gstRate: 18.0,
            discount: 5.0,
            discountType: 'percentage',
          ),
        ],
        subtotal: 15000.0,
        totalDiscount: 750.0,
        totalTax: 2565.0,
        totalAmount: 16815.0,
        paidAmount: 16815.0,
        paymentMode: 'Bank Transfer',
        status: 'Paid',
        notes: 'Paid via automated bank transfer settlement.',
        internalNote: 'Quarterly subscription invoice.',
        termsAndConditions: '1. Bill is payable within the agreed credit period.\n2. Late payments will attract interest as per agreed terms.\n3. Discrepancies must be reported within 7 days of receipt.\n4. All disputes are subject to PUNE jurisdiction only.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }
}
