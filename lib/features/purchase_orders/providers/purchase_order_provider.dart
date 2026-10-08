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
          PurchaseOrder.normalizeStatusForApi(order.status) ==
              PurchaseOrder.normalizeStatusForApi(_statusFilter);

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
    return 'PO-${next.toString().padLeft(3, '0')}';
  }

  /// GET /api/v1/purchase-orders?page=1&page_size=20&status=DRAFT&search=Acme
  Future<void> fetchOrders({
    bool refresh = false,
    String? status,
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    if (_isLoading && !refresh) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String>[
        'page=$page',
        'page_size=$pageSize',
      ];
      final effStatus = status ?? (_statusFilter != 'All' ? _statusFilter : null);
      if (effStatus != null && effStatus != 'All') {
        queryParams.add('status=${PurchaseOrder.normalizeStatusForApi(effStatus)}');
      }
      final effSearch = search ?? (_searchQuery.isNotEmpty ? _searchQuery : null);
      if (effSearch != null && effSearch.trim().isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(effSearch.trim())}');
      }

      final url = '/api/v1/purchase-orders?${queryParams.join('&')}';
      final response = await ApiService().get(url);

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

        _orders.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _orders.add(PurchaseOrder.fromJson(item));
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

  /// GET /api/v1/purchase-orders/{id}
  Future<PurchaseOrder?> getPurchaseOrderById(String id) async {
    try {
      final response = await ApiService().get('/api/v1/purchase-orders/$id');
      Map<String, dynamic>? data;
      if (response['data'] is Map<String, dynamic>) {
        data = response['data'] as Map<String, dynamic>;
      } else if (response.containsKey('id') || response.containsKey('po_number')) {
        data = response;
      }

      if (data != null) {
        final po = PurchaseOrder.fromJson(data);
        final index = _orders.indexWhere((o) => o.id == id || o.poNumber == id);
        if (index != -1) {
          _orders[index] = po;
        } else {
          _orders.add(po);
        }
        notifyListeners();
        return po;
      }
    } catch (_) {}

    try {
      return _orders.firstWhere((o) => o.id == id || o.poNumber == id);
    } catch (_) {
      return null;
    }
  }

  /// POST /api/v1/purchase-orders (201 Created)
  Future<PurchaseOrder?> createOrder(PurchaseOrder order) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = order.toApiJson();
      final response = await ApiService().post('/api/v1/purchase-orders', payload);

      if (response['statusCode'] != null && response['statusCode'] >= 400) {
        _errorMessage = response['message']?.toString() ?? 'Failed to create purchase order';
        return null;
      }

      PurchaseOrder created;
      Map<String, dynamic>? dataMap;
      if (response['data'] is Map<String, dynamic>) {
        dataMap = response['data'] as Map<String, dynamic>;
      } else if (response.containsKey('id') || response.containsKey('po_number')) {
        dataMap = response;
      }

      if (dataMap != null) {
        created = PurchaseOrder.fromJson(dataMap);
        if (created.items.isEmpty && order.items.isNotEmpty) {
          created = created.copyWith(
            items: order.items,
            attachments: order.attachments,
            notes: order.notes,
            internalNote: order.internalNote,
            termsAndConditions: order.termsAndConditions,
          );
        }
      } else {
        created = order;
      }
      _orders.insert(0, created);
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// PUT or PATCH /api/v1/purchase-orders/{id}
  Future<bool> updateOrder(PurchaseOrder order) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final targetId = order.id.isNotEmpty ? order.id : order.poNumber;
    try {
      final payload = order.toApiJson();
      final response = await ApiService().put('/api/v1/purchase-orders/$targetId', payload);

      if (response['statusCode'] != null && response['statusCode'] >= 400) {
        _errorMessage = response['message']?.toString() ?? 'Failed to update purchase order';
        return false;
      }

      PurchaseOrder updated = order;
      Map<String, dynamic>? dataMap;
      if (response['data'] is Map<String, dynamic>) {
        dataMap = response['data'] as Map<String, dynamic>;
      } else if (response.containsKey('id') || response.containsKey('po_number')) {
        dataMap = response;
      }

      if (dataMap != null) {
        updated = PurchaseOrder.fromJson(dataMap);
        if (updated.items.isEmpty && order.items.isNotEmpty) {
          updated = updated.copyWith(
            items: order.items,
            attachments: order.attachments,
            notes: order.notes,
            internalNote: order.internalNote,
            termsAndConditions: order.termsAndConditions,
          );
        }
      }

      final index = _orders.indexWhere((o) => o.id == order.id || o.poNumber == order.poNumber);
      if (index != -1) {
        _orders[index] = updated;
      } else {
        _orders.insert(0, updated);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// DELETE /api/v1/purchase-orders/{id} (Cancel PO)
  Future<bool> cancelOrder(String id) async {
    try {
      await ApiService().delete('/api/v1/purchase-orders/$id');
    } catch (_) {}
    final index = _orders.indexWhere((o) => o.id == id || o.poNumber == id);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: 'CANCELLED');
    }
    notifyListeners();
    return true;
  }

  /// POST /api/v1/purchase-orders/{id}/restore (Restore Cancelled PO)
  Future<bool> restoreOrder(String id) async {
    try {
      final response = await ApiService().post('/api/v1/purchase-orders/$id/restore', {});
      String restoredStatus = 'DRAFT';
      if (response['status'] != null) {
        restoredStatus = response['status'].toString();
      } else if (response['data'] is Map && response['data']['status'] != null) {
        restoredStatus = response['data']['status'].toString();
      }
      final index = _orders.indexWhere((o) => o.id == id || o.poNumber == id);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: PurchaseOrder.normalizeStatusForApi(restoredStatus),
        );
      }
    } catch (_) {
      final index = _orders.indexWhere((o) => o.id == id || o.poNumber == id);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: 'DRAFT');
      }
    }
    notifyListeners();
    return true;
  }

  /// POST /api/v1/purchase-orders/{id}/convert-to-bill (Convert PO to Bill)
  Future<Map<String, dynamic>?> convertToBill(String id, {String? billNumber}) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> body = {};
      if (billNumber != null && billNumber.trim().isNotEmpty) {
        body['bill_number'] = billNumber.trim();
      }

      final response = await ApiService().post('/api/v1/purchase-orders/$id/convert-to-bill', body);

      String? createdBillId;
      if (response['id'] != null) {
        createdBillId = response['id'].toString();
      } else if (response['bill_id'] != null) {
        createdBillId = response['bill_id'].toString();
      } else if (response['data'] is Map && response['data']['id'] != null) {
        createdBillId = response['data']['id'].toString();
      }

      final index = _orders.indexWhere((o) => o.id == id || o.poNumber == id);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: 'BILLED',
          convertedBillId: createdBillId ?? _orders[index].convertedBillId,
        );
      }
      return response;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// DELETE /api/v1/purchase-orders/{id}/permanent (Permanently Delete PO)
  Future<bool> permanentDeleteOrder(String id) async {
    try {
      await ApiService().delete('/api/v1/purchase-orders/$id/permanent');
    } catch (_) {}
    _orders.removeWhere((o) => o.id == id || o.poNumber == id);
    notifyListeners();
    return true;
  }

  /// Alias for backward compatibility
  Future<bool> deleteOrder(String id) => cancelOrder(id);

  /// PUT or PATCH /api/v1/purchase-orders/{id} for status update
  Future<void> updateOrderStatus(String id, String status) async {
    final normStatus = PurchaseOrder.normalizeStatusForApi(status);
    final index = _orders.indexWhere((o) => o.id == id || o.poNumber == id);
    if (index != -1) {
      final updated = _orders[index].copyWith(status: normStatus);
      _orders[index] = updated;
      notifyListeners();
    }
    try {
      await ApiService().patch('/api/v1/purchase-orders/$id', {'status': normStatus});
    } catch (_) {}
  }
}
