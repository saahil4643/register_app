import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../models/vendor.dart';

class VendorProvider extends ChangeNotifier {
  final List<Vendor> _vendors = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Vendor> get vendors => _vendors;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<Vendor> get filteredVendors {
    if (_searchQuery.trim().isEmpty) return _vendors;
    final q = _searchQuery.toLowerCase();
    return _vendors.where((v) {
      return v.displayName.toLowerCase().contains(q) ||
          v.companyName.toLowerCase().contains(q) ||
          v.firstName.toLowerCase().contains(q) ||
          v.lastName.toLowerCase().contains(q) ||
          v.email.toLowerCase().contains(q) ||
          v.primaryPhone.toLowerCase().contains(q) ||
          v.secondaryPhone.toLowerCase().contains(q) ||
          v.gstNumber.toLowerCase().contains(q);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// GET /api/v1/vendors
  Future<void> fetchVendors({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/v1/vendors');
      List<dynamic> list = [];

      final rawData = response['data'] ?? response['results'] ?? response['content'];
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map) {
        if (rawData['content'] is List) {
          list = rawData['content'] as List<dynamic>;
        } else if (rawData['results'] is List) {
          list = rawData['results'] as List<dynamic>;
        } else if (rawData['vendors'] is List) {
          list = rawData['vendors'] as List<dynamic>;
        } else if (rawData['items'] is List) {
          list = rawData['items'] as List<dynamic>;
        }
      }

      _vendors.clear();
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _vendors.add(Vendor.fromJson(item));
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// GET /api/v1/vendors/{id}
  Future<Vendor?> getVendorById(String id) async {
    try {
      final response = await ApiService().get('/api/v1/vendors/$id');
      if (response['data'] is Map<String, dynamic>) {
        return Vendor.fromJson(response['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    try {
      return _vendors.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  /// POST /api/v1/vendors
  Future<Vendor?> createVendor(Vendor vendor) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Vendor createdVendor = vendor;
      try {
        final payload = vendor.toApiJson();
        final response = await ApiService().post('/api/v1/vendors', payload);

        if (response['data'] is Map<String, dynamic>) {
          createdVendor = Vendor.fromJson(response['data'] as Map<String, dynamic>);
        } else if (response['success'] == true) {
          createdVendor = vendor.copyWith(
            id: response['id']?.toString() ?? 'v_${DateTime.now().millisecondsSinceEpoch}',
          );
        }
      } catch (err) {
        // Fallback: create locally if server is offline or errored
        debugPrint('Create vendor API failed, saving locally: $err');
        final localId = vendor.id.isNotEmpty ? vendor.id : 'v_${DateTime.now().millisecondsSinceEpoch}';
        createdVendor = vendor.copyWith(id: localId);
      }

      _vendors.insert(0, createdVendor);
      _isSaving = false;
      notifyListeners();
      return createdVendor;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }

  /// PUT or PATCH /api/v1/vendors/{id}
  Future<Vendor?> updateVendor(String id, Vendor vendor) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Vendor updatedVendor = vendor.copyWith(id: id);
      try {
        final payload = vendor.toApiJson();
        Map<String, dynamic> response;
        try {
          response = await ApiService().put('/api/v1/vendors/$id', payload);
        } catch (_) {
          // Fallback to PATCH if PUT is not allowed
          response = await ApiService().patch('/api/v1/vendors/$id', payload);
        }

        if (response['data'] is Map<String, dynamic>) {
          updatedVendor = Vendor.fromJson(response['data'] as Map<String, dynamic>);
        }
      } catch (err) {
        debugPrint('Update vendor API failed, updating locally: $err');
      }

      final index = _vendors.indexWhere((v) => v.id == id);
      if (index != -1) {
        _vendors[index] = updatedVendor;
      } else {
        _vendors.insert(0, updatedVendor);
      }

      _isSaving = false;
      notifyListeners();
      return updatedVendor;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }

  /// DELETE /api/v1/vendors/{id}
  Future<bool> deleteVendor(String id) async {
    final prevIndex = _vendors.indexWhere((v) => v.id == id);
    Vendor? removedVendor;
    if (prevIndex != -1) {
      removedVendor = _vendors.removeAt(prevIndex);
      notifyListeners();
    }

    try {
      await ApiService().delete('/api/v1/vendors/$id');
      return true;
    } catch (e) {
      // If server deletion fails, re-insert
      if (removedVendor != null && prevIndex != -1) {
        _vendors.insert(prevIndex, removedVendor);
        notifyListeners();
      }
      _errorMessage = 'Failed to delete vendor: $e';
      return false;
    }
  }

}
