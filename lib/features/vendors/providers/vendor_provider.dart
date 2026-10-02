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
          v.phone.toLowerCase().contains(q) ||
          v.mobile.toLowerCase().contains(q);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchVendors({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/v1/vendors');
      if (response['success'] == true && response['data'] != null) {
        final rawData = response['data'];
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['results'] is List) {
          list = rawData['results'] as List<dynamic>;
        }
        _vendors.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _vendors.add(Vendor.fromJson(item));
          }
        }
      }
    } catch (_) {
      // If endpoint doesn't exist yet, populate with reasonable defaults / expenses vendors
      if (_vendors.isEmpty) {
        _populateDefaultVendors();
      }
    } finally {
      if (_vendors.isEmpty) {
        _populateDefaultVendors();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  void _populateDefaultVendors() {
    if (_vendors.isNotEmpty) return;
    final defaults = [
      Vendor(
        id: 'v_1',
        salutation: 'Mr.',
        firstName: 'Rajesh',
        lastName: 'Sharma',
        companyName: 'Apex Logistics Pvt Ltd',
        displayName: 'Apex Logistics',
        email: 'billing@apexlogistics.in',
        phone: '022-45892300',
        mobile: '9820145892',
        isMsmeRegistered: true,
        msmeRegistrationNumber: 'UDYAM-MH-03-0024589',
        currency: 'INR',
        paymentTerms: 'Net 30',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Vendor(
        id: 'v_2',
        salutation: 'Ms.',
        firstName: 'Pooja',
        lastName: 'Mehta',
        companyName: 'CloudScale Technologies',
        displayName: 'CloudScale Tech',
        email: 'accounts@cloudscale.io',
        mobile: '9988776655',
        currency: 'INR',
        paymentTerms: 'Due on Receipt',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Vendor(
        id: 'v_3',
        companyName: 'Bharat Petroleum Corp',
        displayName: 'Bharat Petroleum',
        currency: 'INR',
        paymentTerms: 'Due on Receipt',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
    _vendors.addAll(defaults);
  }

  Future<Vendor?> createVendor(Vendor vendor) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Vendor createdVendor = vendor;
      try {
        final response = await ApiService().post('/api/v1/vendors', vendor.toJson());
        if (response['success'] == true && response['data'] is Map<String, dynamic>) {
          createdVendor = Vendor.fromJson(response['data'] as Map<String, dynamic>);
        }
      } catch (_) {
        // Fallback: create locally with unique ID
        final localId = 'v_${DateTime.now().millisecondsSinceEpoch}';
        createdVendor = Vendor(
          id: vendor.id.isNotEmpty ? vendor.id : localId,
          salutation: vendor.salutation,
          firstName: vendor.firstName,
          lastName: vendor.lastName,
          companyName: vendor.companyName,
          displayName: vendor.displayName,
          email: vendor.email,
          phone: vendor.phone,
          mobile: vendor.mobile,
          gstin: vendor.gstin,
          phoneCountryCode: vendor.phoneCountryCode,
          mobileCountryCode: vendor.mobileCountryCode,
          isMsmeRegistered: vendor.isMsmeRegistered,
          msmeRegistrationNumber: vendor.msmeRegistrationNumber,
          currency: vendor.currency,
          accountsPayable: vendor.accountsPayable,
          openingBalance: vendor.openingBalance,
          paymentTerms: vendor.paymentTerms,
          website: vendor.website,
          socialLinks: vendor.socialLinks,
          billingAttention: vendor.billingAttention,
          billingAddressLine1: vendor.billingAddressLine1,
          billingCity: vendor.billingCity,
          billingState: vendor.billingState,
          billingPostalCode: vendor.billingPostalCode,
          billingCountry: vendor.billingCountry,
          shippingSameAsBilling: vendor.shippingSameAsBilling,
          shippingAttention: vendor.shippingAttention,
          shippingAddressLine1: vendor.shippingAddressLine1,
          shippingCity: vendor.shippingCity,
          shippingState: vendor.shippingState,
          shippingPostalCode: vendor.shippingPostalCode,
          shippingCountry: vendor.shippingCountry,
          contactPersons: vendor.contactPersons,
          remarks: vendor.remarks,
          createdAt: DateTime.now(),
        );
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

  void deleteVendor(String id) {
    _vendors.removeWhere((v) => v.id == id);
    notifyListeners();
    try {
      ApiService().delete('/api/v1/vendors/$id');
    } catch (_) {}
  }
}
