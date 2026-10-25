import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../../../core/services/api_service.dart';

class CustomerProvider extends ChangeNotifier {
  final List<Customer> _customers = [];
  bool _isLoading = false;  // for list fetch operations
  bool _isSaving = false;   // for create / update / delete operations
  String? _errorMessage;
  final Map<String, List<String>> _fieldErrors = {};
  Map<String, dynamic> _dashboardStats = {};
  
  Map<String, dynamic>? _selectedCustomerStats;
  Customer? _selectedCustomerDetails;

  String _searchQuery = '';
  String _statusFilter = 'All';
  String _sortBy = 'Alphabetical';
  
  bool _hasMore = false;
  String? _nextPageUrl;

  // Getters
  List<Customer> get customers => _customers;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  Map<String, List<String>> get fieldErrors => _fieldErrors;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  Map<String, dynamic>? get selectedCustomerStats => _selectedCustomerStats;
  Customer? get selectedCustomerDetails => _selectedCustomerDetails;
  
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get sortBy => _sortBy;

  // Setters for UI state
  void setSearchQuery(String val) {
    _searchQuery = val;
    notifyListeners();
  }

  void setStatusFilter(String val) {
    _statusFilter = val;
    notifyListeners();
  }

  void setSortBy(String val) {
    _sortBy = val;
    notifyListeners();
  }

  // Fetch customer list (Supports both /api/v1/customers and /api/customers)
  Future<void> fetchCustomers({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _nextPageUrl = null;
      _hasMore = true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String url;
      if (_nextPageUrl != null && !refresh) {
        url = _nextPageUrl!;
      } else {
        final queryParams = <String>[];
        if (_searchQuery.isNotEmpty) {
          queryParams.add('search=${Uri.encodeComponent(_searchQuery)}');
        }
        if (_statusFilter == 'Active') {
          queryParams.add('status=active');
        } else if (_statusFilter == 'Inactive') {
          queryParams.add('status=inactive');
        }

        final qs = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
        url = '/api/v1/customers$qs';
      }

      final response = await ApiService().get(url);
      if (response['success'] == true) {
        final rawData = response['data'];
        List<dynamic> results = [];
        
        if (rawData is List) {
          results = rawData;
          _nextPageUrl = null;
          _hasMore = false;
        } else if (rawData is Map) {
          results = rawData['results'] as List<dynamic>? ?? [];
          _nextPageUrl = rawData['next'] as String?;
          _hasMore = _nextPageUrl != null;
        }

        final List<Customer> fetched = results
            .map((json) => Customer.fromJson(json as Map<String, dynamic>))
            .toList();

        if (refresh) {
          _customers.clear();
        }
        _customers.addAll(fetched);
      } else {
        _errorMessage = response['message'] ?? 'Failed to load customers';
      }
    } catch (e) {
      _errorMessage = 'Error loading customers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch dashboard stats
  Future<void> fetchDashboardStats() async {
    try {
      final response = await ApiService().get('/api/customers/dashboard/');
      if (response['success'] == true) {
        _dashboardStats = Map<String, dynamic>.from(response['data'] ?? {});
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching customer dashboard stats: $e');
    }
  }

  // Fetch single customer details: GET /api/v1/customers/{id}
  Future<Customer?> fetchCustomerDetails(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/v1/customers/$id');
      if (response['success'] == true && response['data'] != null) {
        final customer = Customer.fromJson(response['data'] as Map<String, dynamic>);
        _selectedCustomerDetails = customer;
        
        // Update customer in list if cached
        final idx = _customers.indexWhere((c) => c.id == id);
        if (idx >= 0) {
          _customers[idx] = customer;
        }
        return customer;
      } else {
        _errorMessage = response['message'] ?? 'Failed to load customer details';
      }
    } catch (e) {
      _errorMessage = 'Error loading customer details: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  // Lookup Customer by GST: GET /api/v1/customers/by-gst/{gstNumber}
  Future<Customer?> fetchCustomerByGst(String gstNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/v1/customers/by-gst/${Uri.encodeComponent(gstNumber)}');
      if (response['success'] == true && response['data'] != null) {
        final customer = Customer.fromJson(response['data'] as Map<String, dynamic>);
        return customer;
      } else {
        _errorMessage = response['message'] ?? 'Customer not found for GST: $gstNumber';
      }
    } catch (e) {
      _errorMessage = 'Error looking up customer by GST: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  // Fetch customer statistics
  Future<Map<String, dynamic>?> fetchCustomerStatistics(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/customers/$id/statistics/');
      if (response['success'] == true) {
        _selectedCustomerStats = response['data'] as Map<String, dynamic>?;
        return _selectedCustomerStats;
      } else {
        _errorMessage = response['message'] ?? 'Failed to load customer statistics';
      }
    } catch (e) {
      _errorMessage = 'Error loading customer statistics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  // Create Customer: POST /api/v1/customers
  Future<Customer?> createCustomer(Customer customer, {List<Map<String, dynamic>>? contacts, List<String>? tagNames}) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final Map<String, dynamic> payload = {
        'customer_type': customer.customerType.isNotEmpty ? customer.customerType : 'business',
        'display_name': customer.displayName.isNotEmpty ? customer.displayName : customer.name,
        if (customer.companyName.isNotEmpty)
          'company_name': customer.companyName
        else if (customer.customerType != 'individual' && (customer.displayName.isNotEmpty || customer.name.isNotEmpty))
          'company_name': customer.displayName.isNotEmpty ? customer.displayName : customer.name,
        if (customer.firstName.isNotEmpty) 'first_name': customer.firstName,
        if (customer.lastName.isNotEmpty) 'last_name': customer.lastName,
        if (customer.email.isNotEmpty) 'email': customer.email,
        'primary_phone': customer.primaryPhone.isNotEmpty ? customer.primaryPhone : customer.phone,
        if (customer.secondaryPhone.isNotEmpty) 'secondary_phone': customer.secondaryPhone,
        if (customer.website.isNotEmpty) 'website': customer.website,
        if (customer.gstNumber.isNotEmpty) 'gst_number': customer.gstNumber,
        if (customer.panNumber.isNotEmpty) 'pan_number': customer.panNumber,
        'tax_preference': customer.taxPreference,
        'currency': customer.currency,
        'payment_terms': customer.paymentTerms,
        'credit_limit': customer.creditLimit,
        'status': customer.status,
        if (customer.billingAttention.isNotEmpty) 'billing_attention': customer.billingAttention,
        if (customer.billingAddressLine1.isNotEmpty) 'billing_address_line_1': customer.billingAddressLine1,
        if (customer.billingCity.isNotEmpty) 'billing_city': customer.billingCity,
        if (customer.billingState.isNotEmpty) 'billing_state': customer.billingState,
        if (customer.billingPostalCode.isNotEmpty) 'billing_postal_code': customer.billingPostalCode,
        'billing_country': customer.billingCountry,
        'shipping_same_as_billing': customer.shippingSameAsBilling,
        if (!customer.shippingSameAsBilling && customer.shippingAddressLine1.isNotEmpty)
          'shipping_address_line_1': customer.shippingAddressLine1,
        if (!customer.shippingSameAsBilling && customer.shippingCity.isNotEmpty)
          'shipping_city': customer.shippingCity,
        if (!customer.shippingSameAsBilling && customer.shippingState.isNotEmpty)
          'shipping_state': customer.shippingState,
        if (!customer.shippingSameAsBilling && customer.shippingPostalCode.isNotEmpty)
          'shipping_postal_code': customer.shippingPostalCode,
        if (!customer.shippingSameAsBilling && customer.shippingCountry.isNotEmpty)
          'shipping_country': customer.shippingCountry,
        if (customer.notes.isNotEmpty) 'notes': customer.notes,
        if (contacts != null) 'contacts': contacts,
        if (tagNames != null) 'tag_names': tagNames,
      };

      final response = await ApiService().post('/api/v1/customers', payload);
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final newCustomer = Customer.fromJson(data);
        
        // If response only returned minimal data, fill with sent details
        final mergedCustomer = customer.copyWith(
          id: newCustomer.id.isNotEmpty ? newCustomer.id : customer.id,
          displayName: newCustomer.displayName.isNotEmpty ? newCustomer.displayName : customer.displayName,
          status: newCustomer.status.isNotEmpty ? newCustomer.status : customer.status,
        );

        _customers.insert(0, mergedCustomer);
        return mergedCustomer;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create customer';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors'] as Map<String, dynamic>);
          if (_fieldErrors.isNotEmpty) {
            final details = _fieldErrors.entries.map((e) {
              final fieldName = _friendlyFieldName(e.key);
              return '$fieldName: ${e.value.join(', ')}';
            }).join('\n');
            _errorMessage = details;
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Error creating customer: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return null;
  }

  // Full Update: PUT /api/v1/customers/{id}
  Future<Customer?> updateCustomer(String id, Customer customer, {List<Map<String, dynamic>>? contacts, List<String>? tagNames}) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final Map<String, dynamic> payload = {
        'customer_type': customer.customerType.isNotEmpty ? customer.customerType : 'business',
        'display_name': customer.displayName.isNotEmpty ? customer.displayName : customer.name,
        if (customer.companyName.isNotEmpty)
          'company_name': customer.companyName
        else if (customer.customerType != 'individual' && (customer.displayName.isNotEmpty || customer.name.isNotEmpty))
          'company_name': customer.displayName.isNotEmpty ? customer.displayName : customer.name,
        if (customer.firstName.isNotEmpty) 'first_name': customer.firstName,
        if (customer.lastName.isNotEmpty) 'last_name': customer.lastName,
        if (customer.email.isNotEmpty) 'email': customer.email,
        'primary_phone': customer.primaryPhone.isNotEmpty ? customer.primaryPhone : customer.phone,
        if (customer.secondaryPhone.isNotEmpty) 'secondary_phone': customer.secondaryPhone,
        if (customer.website.isNotEmpty) 'website': customer.website,
        if (customer.gstNumber.isNotEmpty) 'gst_number': customer.gstNumber,
        if (customer.panNumber.isNotEmpty) 'pan_number': customer.panNumber,
        'tax_preference': customer.taxPreference,
        'currency': customer.currency,
        'payment_terms': customer.paymentTerms,
        'credit_limit': customer.creditLimit,
        'status': customer.status,
        if (customer.billingAttention.isNotEmpty) 'billing_attention': customer.billingAttention,
        if (customer.billingAddressLine1.isNotEmpty) 'billing_address_line_1': customer.billingAddressLine1,
        if (customer.billingCity.isNotEmpty) 'billing_city': customer.billingCity,
        if (customer.billingState.isNotEmpty) 'billing_state': customer.billingState,
        if (customer.billingPostalCode.isNotEmpty) 'billing_postal_code': customer.billingPostalCode,
        'billing_country': customer.billingCountry,
        'shipping_same_as_billing': customer.shippingSameAsBilling,
        if (!customer.shippingSameAsBilling && customer.shippingAddressLine1.isNotEmpty)
          'shipping_address_line_1': customer.shippingAddressLine1,
        if (!customer.shippingSameAsBilling && customer.shippingCity.isNotEmpty)
          'shipping_city': customer.shippingCity,
        if (!customer.shippingSameAsBilling && customer.shippingState.isNotEmpty)
          'shipping_state': customer.shippingState,
        if (!customer.shippingSameAsBilling && customer.shippingPostalCode.isNotEmpty)
          'shipping_postal_code': customer.shippingPostalCode,
        if (!customer.shippingSameAsBilling && customer.shippingCountry.isNotEmpty)
          'shipping_country': customer.shippingCountry,
        if (customer.notes.isNotEmpty) 'notes': customer.notes,
        if (contacts != null) 'contacts': contacts,
        if (tagNames != null) 'tag_names': tagNames,
      };

      final response = await ApiService().put('/api/v1/customers/$id', payload);
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final updated = data.isNotEmpty ? Customer.fromJson(data) : customer;
        
        final idx = _customers.indexWhere((c) => c.id == id);
        if (idx >= 0) {
          _customers[idx] = updated;
        }
        if (_selectedCustomerDetails?.id == id) {
          _selectedCustomerDetails = updated;
        }
        return updated;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update customer';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
        }
      }
    } catch (e) {
      _errorMessage = 'Error updating customer: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return null;
  }

  // Partial Update: PATCH /api/v1/customers/{id}
  Future<Customer?> patchCustomer(String id, Map<String, dynamic> partialData) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await ApiService().patch('/api/v1/customers/$id', partialData);
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        if (data.isNotEmpty) {
          final updated = Customer.fromJson(data);
          final idx = _customers.indexWhere((c) => c.id == id);
          if (idx >= 0) {
            _customers[idx] = updated;
          }
          if (_selectedCustomerDetails?.id == id) {
            _selectedCustomerDetails = updated;
          }
          return updated;
        }
        await fetchCustomerDetails(id);
        return _selectedCustomerDetails;
      } else {
        _errorMessage = response['message'] ?? 'Failed to partially update customer';
      }
    } catch (e) {
      _errorMessage = 'Error partially updating customer: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return null;
  }

  // Delete Customer (Soft delete): DELETE /api/v1/customers/{id}
  Future<bool> deleteCustomer(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().delete('/api/v1/customers/$id');
      if (response['success'] == true) {
        _customers.removeWhere((c) => c.id == id);
        if (_selectedCustomerDetails?.id == id) {
          _selectedCustomerDetails = null;
        }
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete customer';
      }
    } catch (e) {
      _errorMessage = 'Error deleting customer: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return false;
  }

  // Restore Soft-Deleted Customer: POST /api/v1/customers/{id}/restore
  Future<bool> restoreCustomer(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/v1/customers/$id/restore', {});
      if (response['success'] == true) {
        await fetchCustomers(refresh: true);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to restore customer';
      }
    } catch (e) {
      _errorMessage = 'Error restoring customer: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Activate Customer
  Future<bool> activateCustomer(String id) async {
    try {
      final response = await ApiService().post('/api/v1/customers/$id/activate', {});
      if (response['success'] == true) {
        await fetchCustomerDetails(id);
        return true;
      }
    } catch (e) {
      debugPrint('Error activating customer: $e');
    }
    return false;
  }

  // Deactivate Customer
  Future<bool> deactivateCustomer(String id) async {
    try {
      final response = await ApiService().post('/api/v1/customers/$id/deactivate', {});
      if (response['success'] == true) {
        await fetchCustomerDetails(id);
        return true;
      }
    } catch (e) {
      debugPrint('Error deactivating customer: $e');
    }
    return false;
  }

  String _friendlyFieldName(String key) {
    const names = {
      'display_name': 'Contact Name',
      'primary_phone': 'Phone Number',
      'email': 'Email Address',
      'gst_number': 'GST Number',
      'company_name': 'Company Name',
      'billing_address_line_1': 'Address',
      'credit_limit': 'Credit Limit',
      'tax_preference': 'Tax Preference',
    };
    return names[key] ?? key.replaceAll('_', ' ').toUpperCase();
  }

  void _parseFieldErrors(Map<String, dynamic> errors) {
    _fieldErrors.clear();
    errors.forEach((key, value) {
      if (value is List) {
        _fieldErrors[key] = value.map((e) => e.toString()).toList();
      } else {
        _fieldErrors[key] = [value.toString()];
      }
    });
  }
}
