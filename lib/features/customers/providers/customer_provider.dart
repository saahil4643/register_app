import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../../invoices/models/invoice.dart';
import '../models/payment.dart';
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
  
  bool _hasMore = true;
  String? _nextPageUrl;

  // Getters
  List<Customer> get customers => _customers;
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

  // Fetch paginated customer list
  Future<void> fetchCustomers({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _nextPageUrl = null;
      _hasMore = true;
    }
    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String url;
      if (_nextPageUrl != null && !refresh) {
        url = _nextPageUrl!;
      } else {
        url = '/api/customers/?page=1&page_size=15';
        if (_searchQuery.isNotEmpty) {
          url += '&search=${Uri.encodeComponent(_searchQuery)}';
        }
        if (_statusFilter == 'Active') {
          url += '&status=active';
        } else if (_statusFilter == 'Inactive') {
          url += '&status=inactive';
        }
      }

      final response = await ApiService().get(url);
      if (response['success'] == true) {
        final data = response['data'] ?? {};
        final results = data['results'] as List<dynamic>? ?? [];
        final List<Customer> fetched = results
            .map((json) => Customer.fromJson(json as Map<String, dynamic>))
            .toList();

        if (refresh) {
          _customers.clear();
        }
        _customers.addAll(fetched);
        _nextPageUrl = data['next'] as String?;
        _hasMore = _nextPageUrl != null;
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

  // Fetch single customer details
  Future<Customer?> fetchCustomerDetails(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/customers/$id/');
      if (response['success'] == true) {
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

  // Save/Create Customer
  Future<Customer?> createCustomer(Customer customer, {List<Map<String, dynamic>>? contacts, List<String>? tagNames}) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final Map<String, dynamic> payload = {
        'customer_type': 'business',
        'display_name': customer.name,
        if (customer.company.isNotEmpty) 'company_name': customer.company,
        if (customer.email.isNotEmpty) 'email': customer.email,
        if (customer.phone.isNotEmpty) 'primary_phone': customer.phone,
        if (customer.address.isNotEmpty) 'billing_address_line_1': customer.address,
        'shipping_same_as_billing': true,
        'gst_registered': customer.gstNo.isNotEmpty,
        if (customer.gstNo.isNotEmpty) 'gst_number': customer.gstNo,
        'credit_limit': customer.creditLimit,
        if (customer.notes.isNotEmpty) 'internal_notes': customer.notes,
        if (contacts != null) 'contacts': contacts,
        if (tagNames != null) 'tag_names': tagNames,
      };

      final response = await ApiService().post('/api/customers/', payload);
      if (response['success'] == true) {
        final newCustomer = Customer.fromJson(response['data'] as Map<String, dynamic>);
        _customers.add(newCustomer);
        return newCustomer;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create customer';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors'] as Map<String, dynamic>);
          // Build a readable error from field errors
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

  // Update Customer
  Future<Customer?> updateCustomer(String id, Customer customer, {List<Map<String, dynamic>>? contacts, List<String>? tagNames}) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final Map<String, dynamic> payload = {
        'display_name': customer.name,
        if (customer.company.isNotEmpty) 'company_name': customer.company,
        if (customer.email.isNotEmpty) 'email': customer.email,
        if (customer.phone.isNotEmpty) 'primary_phone': customer.phone,
        if (customer.address.isNotEmpty) 'billing_address_line_1': customer.address,
        'gst_registered': customer.gstNo.isNotEmpty,
        if (customer.gstNo.isNotEmpty) 'gst_number': customer.gstNo,
        'credit_limit': customer.creditLimit,
        if (customer.notes.isNotEmpty) 'internal_notes': customer.notes,
        if (contacts != null) 'contacts': contacts,
        if (tagNames != null) 'tag_names': tagNames,
      };

      final response = await ApiService().put('/api/customers/$id/', payload);
      if (response['success'] == true) {
        final updated = Customer.fromJson(response['data'] as Map<String, dynamic>);
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

  // Delete Customer (Soft delete)
  Future<bool> deleteCustomer(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().delete('/api/customers/$id/');
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

  // Restore Customer
  Future<bool> restoreCustomer(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/customers/$id/restore/', {});
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
      final response = await ApiService().post('/api/customers/$id/activate/', {});
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
      final response = await ApiService().post('/api/customers/$id/deactivate/', {});
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
      'gst_registered': 'GST Registered',
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
