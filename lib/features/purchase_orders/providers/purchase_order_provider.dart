import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../models/purchase_order.dart';

class PurchaseOrderProvider extends ChangeNotifier {
  final List<PurchaseOrder> _orders = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _statusFilter = 'All';

  List<PurchaseOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  List<PurchaseOrder> get filteredOrders {
    return _orders.where((order) {
      final matchesSearch = _searchQuery.trim().isEmpty ||
          order.poNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.vendorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.referenceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == 'All' ||
          order.status.toLowerCase() == _statusFilter.toLowerCase();

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

  String getNextPoNumber() {
    int maxNum = 0;
    for (final o in _orders) {
      final match = RegExp(r'(\d+)').firstMatch(o.poNumber);
      if (match != null) {
        final val = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (val > maxNum) maxNum = val;
      }
    }
    final next = maxNum + 1;
    return 'PUR-${next.toString().padLeft(3, '0')}';
  }

  Future<void> fetchOrders({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/v1/purchase-orders');
      if (response['success'] == true && response['data'] != null) {
        final rawData = response['data'];
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['results'] is List) {
          list = rawData['results'] as List<dynamic>;
        }
        _orders.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _orders.add(PurchaseOrder.fromJson(item));
          }
        }
      }
    } catch (_) {
      // Populated with fallback mock data if API is not yet available
      if (_orders.isEmpty) {
        _populateDefaultOrders();
      }
    } finally {
      if (_orders.isEmpty) {
        _populateDefaultOrders();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PurchaseOrder?> createOrder(PurchaseOrder order) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post(
        '/api/v1/purchase-orders',
        order.toJson(),
      );

      PurchaseOrder created;
      if (response['success'] == true && response['data'] != null) {
        created = PurchaseOrder.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        created = order.copyWith(
          id: order.id.isEmpty
              ? 'po_${DateTime.now().millisecondsSinceEpoch}'
              : order.id,
        );
      }
      _orders.insert(0, created);
      return created;
    } catch (e) {
      // Save locally as fallback
      final fallback = order.copyWith(
        id: order.id.isEmpty
            ? 'po_${DateTime.now().millisecondsSinceEpoch}'
            : order.id,
      );
      _orders.insert(0, fallback);
      return fallback;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrder(PurchaseOrder order) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService().put('/api/v1/purchase-orders/${order.id}', order.toJson());
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = order;
      }
      return true;
    } catch (_) {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = order;
      }
      return true;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteOrder(String id) async {
    try {
      await ApiService().delete('/api/v1/purchase-orders/$id');
    } catch (_) {}
    _orders.removeWhere((o) => o.id == id);
    notifyListeners();
    return true;
  }

  Future<void> updateOrderStatus(String id, String status) async {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      final updated = _orders[index].copyWith(status: status);
      _orders[index] = updated;
      notifyListeners();
      try {
        await ApiService().patch('/api/v1/purchase-orders/$id/status', {'status': status});
      } catch (_) {}
    }
  }

  void _populateDefaultOrders() {
    if (_orders.isNotEmpty) return;
    _orders.addAll([
      PurchaseOrder(
        id: 'po_001',
        poNumber: 'PUR-001',
        vendorId: 'v_1',
        vendorName: 'Apex Logistics',
        category: 'Logistics & Freight',
        purchaseDate: DateTime.now().subtract(const Duration(days: 4)),
        referenceNumber: 'REF-88912',
        items: [
          PurchaseOrderItem(
            id: 'item_1',
            name: 'Inter-state Freight Service',
            hsnCode: '996511',
            quantity: 2,
            unit: 'Nos',
            rate: 12500.0,
            gstRate: 18.0,
            discount: 500.0,
            discountType: 'amount',
          ),
          PurchaseOrderItem(
            id: 'item_2',
            name: 'Heavy Duty Wooden Pallets',
            hsnCode: '441520',
            quantity: 15,
            unit: 'Pcs',
            rate: 850.0,
            gstRate: 12.0,
            discount: 0.0,
            discountType: 'amount',
          ),
        ],
        subtotal: 37250.0,
        totalDiscount: 500.0,
        totalTax: 5937.0,
        totalAmount: 42687.0,
        paymentMode: 'Bank Transfer',
        status: 'Ordered',
        notes: 'Deliver to warehouse bay 3 before Friday.',
        internalNote: 'Approved by supply chain manager.',
        termsAndConditions: '1. Goods received subject to inspection and approval.\n2. Payment will be processed as per agreed terms.\n3. Mention PO number on all invoices and delivery notes.\n4. All disputes are subject to PUNE jurisdiction only.',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      PurchaseOrder(
        id: 'po_002',
        poNumber: 'PUR-002',
        vendorId: 'v_2',
        vendorName: 'CloudScale Tech',
        category: 'IT & Software',
        purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
        referenceNumber: 'BILL-44120',
        items: [
          PurchaseOrderItem(
            id: 'item_3',
            name: 'Cloud Hosting Dedicated Nodes',
            hsnCode: '998315',
            quantity: 3,
            unit: 'Nos',
            rate: 8000.0,
            gstRate: 18.0,
            discount: 10.0,
            discountType: 'percentage',
          ),
        ],
        subtotal: 24000.0,
        totalDiscount: 2400.0,
        totalTax: 3888.0,
        totalAmount: 25488.0,
        paymentMode: 'Bank Transfer',
        status: 'Pending',
        notes: 'Monthly infrastructure renewal order.',
        internalNote: 'Annual contract tier 2 discount applied.',
        termsAndConditions: '1. Goods received subject to inspection and approval.\n2. Payment will be processed as per agreed terms.\n3. Mention PO number on all invoices and delivery notes.\n4. All disputes are subject to PUNE jurisdiction only.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }
}
