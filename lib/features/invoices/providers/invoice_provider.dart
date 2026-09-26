import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/utils/file_helper.dart';
import '../../customers/models/customer.dart';
import '../../customers/models/payment.dart';
import '../../products/models/product.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../../../core/services/api_service.dart';
import '../../settings/models/settings_models.dart';

class InvoiceProvider extends ChangeNotifier {
  final List<Customer> _customers = [];
  final List<Product> _products = [];
  final List<Invoice> _invoices = [];
  final List<Payment> _payments = [];

  // API loading states
  bool _isLoading = false;
  String? _nextPageUrl;
  bool _hasMore = true;
  String? _errorMessage;
  Map<String, List<String>> _fieldErrors = {};

  // Dashboard Statistics
  Map<String, dynamic> _dashboardStats = {
    'total_invoices': 0,
    'paid': 0,
    'pending': 0,
    'overdue': 0,
    'draft': 0,
    'cancelled': 0,
    'revenue': 0.0,
    'outstanding': 0.0,
    'average_invoice': 0.0,
  };

  // Search & Filter state for Invoices
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Draft', 'Sent', 'Paid', 'Overdue', 'Cancelled'
  String _sortBy = 'date_desc'; // 'date_desc', 'date_asc', 'amount_desc', 'amount_asc'

  // Creation & Editing working state for Invoices
  Customer? _selectedCustomer;
  List<InvoiceItem> _selectedItems = [];
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _notes = '';
  String _terms = '';
  String _invoiceNumber = '';
  Invoice? _editingInvoice;
  bool _isPaid = false;

  InvoiceProvider() {
    // Dynamic endpoints are loaded when views are entered.
  }

  // Getters
  List<Customer> get customers => _customers;
  List<Product> get products => _products;
  List<Invoice> get invoices => _invoices;
  List<Payment> get payments => _payments;

  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  Map<String, List<String>> get fieldErrors => _fieldErrors;
  Map<String, dynamic> get dashboardStats => _dashboardStats;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get sortBy => _sortBy;

  Customer? get selectedCustomer => _selectedCustomer;
  List<InvoiceItem> get selectedItems => _selectedItems;
  DateTime get invoiceDate => _invoiceDate;
  DateTime get dueDate => _dueDate;
  String get notes => _notes;
  String get terms => _terms;
  String get invoiceNumber => _invoiceNumber;
  Invoice? get editingInvoice => _editingInvoice;
  bool get isPaid => _isPaid;

  // Working state calculations (Local / UI backup)
  double get subtotal => _selectedItems.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiscount => _selectedItems.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get totalTax => _selectedItems.fold(0.0, (sum, item) => sum + item.taxAmount);
  double get grandTotal => _selectedItems.fold(0.0, (sum, item) => sum + item.total);

  // Setters for search and filters
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  String getBackendSorting(String sortBy) {
    switch (sortBy) {
      case 'date_desc':
        return 'newest';
      case 'date_asc':
        return 'oldest';
      case 'amount_desc':
        return 'highest_amount';
      case 'amount_asc':
        return 'lowest_amount';
      default:
        return 'newest';
    }
  }

  // Fetch invoices from backend
  Future<void> fetchInvoices({bool refresh = false}) async {
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
        final sortingParam = getBackendSorting(_sortBy);
        url = '/api/invoices/?page=1&page_size=10&sorting=$sortingParam';
        if (_searchQuery.isNotEmpty) {
          url += '&search=${Uri.encodeComponent(_searchQuery)}';
        }
        if (_statusFilter != 'All') {
          url += '&status=${_statusFilter.toLowerCase()}';
        }
      }

      final response = await ApiService().get(url);
      if (response['success'] == true) {
        final data = response['data'] ?? {};
        final results = data['results'] as List<dynamic>? ?? [];
        
        final List<Invoice> fetchedInvoices = results
            .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
            .toList();

        if (refresh) {
          _invoices.clear();
        }
        _invoices.addAll(fetchedInvoices);
        _nextPageUrl = data['next'] as String?;
        _hasMore = _nextPageUrl != null;

        // Also gather all payments nested within these invoices for payment history compatibility
        final allPayments = <Payment>[];
        for (var invoice in fetchedInvoices) {
          allPayments.addAll(invoice.payments);
        }
        if (refresh) {
          _payments.clear();
        }
        _payments.addAll(allPayments);

        if (data.containsKey('dashboard_summary')) {
          _dashboardStats = Map<String, dynamic>.from(data['dashboard_summary']);
        }
      } else {
        _errorMessage = response['message'] ?? 'Failed to load invoices';
      }
    } catch (e) {
      _errorMessage = 'Error loading invoices: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch dashboard stats explicitly
  Future<void> fetchDashboardStats() async {
    try {
      final response = await ApiService().get('/api/invoices/dashboard/');
      if (response['success'] == true) {
        _dashboardStats = Map<String, dynamic>.from(response['data'] ?? {});
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
    }
  }

  // Fetch detailed invoice by ID (and cache it in list)
  Future<Invoice?> fetchInvoiceDetails(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiService().get('/api/invoices/$id/');
      if (response['success'] == true) {
        final invoice = Invoice.fromJson(response['data'] as Map<String, dynamic>);
        final index = _invoices.indexWhere((inv) => inv.id == id);
        if (index >= 0) {
          _invoices[index] = invoice;
        } else {
          _invoices.add(invoice);
        }
        // Cache payments
        _payments.removeWhere((p) => p.invoiceId == id);
        _payments.addAll(invoice.payments);
        
        return invoice;
      } else {
        _errorMessage = response['message'] ?? 'Failed to load invoice details';
      }
    } catch (e) {
      _errorMessage = 'Error loading invoice details: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  // Fetch customers (autocomplete / search supported)
  Future<void> fetchCustomers({String query = ''}) async {
    try {
      final String path = query.isEmpty 
          ? '/api/customers/' 
          : '/api/customers/search/?q=${Uri.encodeComponent(query)}';
      final response = await ApiService().get(path);
      if (response['success'] == true) {
        final List<dynamic> dataList = response['data'] is List 
            ? response['data'] 
            : (response['data']?['results'] ?? []);
        _customers.clear();
        _customers.addAll(dataList.map((json) => Customer.fromJson(json as Map<String, dynamic>)).toList());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching customers: $e');
    }
  }

  // Fetch products (autocomplete / search supported)
  Future<void> fetchProducts({String query = ''}) async {
    try {
      final String path = query.isEmpty 
          ? '/api/products/' 
          : '/api/products/search/?q=${Uri.encodeComponent(query)}';
      final response = await ApiService().get(path);
      if (response['success'] == true) {
        final List<dynamic> dataList = response['data'] is List 
            ? response['data'] 
            : (response['data']?['results'] ?? []);
        _products.clear();
        _products.addAll(dataList.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  // Filtered and Sorted Invoices (Local query matching current cache)
  List<Invoice> get filteredInvoices {
    return _invoices.where((invoice) {
      final query = _searchQuery.toLowerCase();
      final matchQuery = invoice.invoiceNumber.toLowerCase().contains(query) ||
          invoice.customer.name.toLowerCase().contains(query) ||
          invoice.customer.company.toLowerCase().contains(query);

      bool matchStatus = true;
      if (_statusFilter != 'All') {
        matchStatus = invoice.status.name.toLowerCase() == _statusFilter.toLowerCase();
      }

      return matchQuery && matchStatus;
    }).toList()
      ..sort((a, b) {
        switch (_sortBy) {
          case 'date_desc':
            return b.invoiceDate.compareTo(a.invoiceDate);
          case 'date_asc':
            return a.invoiceDate.compareTo(b.invoiceDate);
          case 'amount_desc':
            return b.grandTotal.compareTo(a.grandTotal);
          case 'amount_asc':
            return a.grandTotal.compareTo(b.grandTotal);
          default:
            return b.invoiceDate.compareTo(a.invoiceDate);
        }
      });
  }

  // Customer Actions (Syncing local model with potential endpoint)
  void addCustomer(Customer customer) {
    _customers.add(customer);
    notifyListeners();
  }

  void updateCustomer(Customer updatedCustomer) {
    final index = _customers.indexWhere((c) => c.id == updatedCustomer.id);
    if (index >= 0) {
      _customers[index] = updatedCustomer;
      notifyListeners();
    }
  }

  void deleteCustomer(String customerId) {
    _customers.removeWhere((c) => c.id == customerId);
    notifyListeners();
  }

  // Product Actions
  void addProductItem(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProductItem(Product updatedProduct) {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index >= 0) {
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  // Payments Actions
  void addPayment(Payment payment) {
    _payments.add(payment);
    notifyListeners();
  }

  // Dynamic Customer Calculations
  List<Invoice> getInvoicesForCustomer(String customerId) {
    return _invoices.where((inv) => inv.customer.id == customerId).toList()
      ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
  }

  List<Payment> getPaymentsForCustomer(String customerId) {
    return _payments.where((p) => p.customerId == customerId).toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  List<Product> getProductsPurchasedByCustomer(String customerId) {
    final customerInvoices = _invoices.where((inv) => inv.customer.id == customerId);
    final Set<String> productIds = {};
    final List<Product> purchased = [];
    for (final inv in customerInvoices) {
      for (final item in inv.items) {
        if (!productIds.contains(item.product.id)) {
          productIds.add(item.product.id);
          purchased.add(item.product);
        }
      }
    }
    return purchased;
  }

  double getOutstandingForCustomer(String customerId) {
    final customerInvoices = _invoices.where((inv) => 
      inv.customer.id == customerId && 
      (inv.status == InvoiceStatus.sent || inv.status == InvoiceStatus.overdue)
    );
    double totalDue = customerInvoices.fold(0.0, (sum, inv) => sum + inv.grandTotal);
    
    // Subtract payments tied to those invoices
    for (final inv in customerInvoices) {
      final invoicePayments = _payments.where((p) => p.invoiceId == inv.id).fold(0.0, (sum, p) => sum + p.amount);
      totalDue -= invoicePayments;
    }
    return max(0.0, totalDue);
  }

  double getPaidAmountForCustomer(String customerId) {
    return _payments.where((p) => p.customerId == customerId).fold(0.0, (sum, p) => sum + p.amount);
  }

  double getTotalPurchaseForCustomer(String customerId) {
    return _invoices
        .where((inv) => inv.customer.id == customerId && inv.status != InvoiceStatus.draft && inv.status != InvoiceStatus.cancelled)
        .fold(0.0, (sum, inv) => sum + inv.grandTotal);
  }

  int getTotalOrdersForCustomer(String customerId) {
    return _invoices
        .where((inv) => inv.customer.id == customerId && inv.status != InvoiceStatus.draft && inv.status != InvoiceStatus.cancelled)
        .length;
  }

  DateTime? getLastPurchaseDateForCustomer(String customerId) {
    final customerInvoices = _invoices
        .where((inv) => inv.customer.id == customerId && inv.status != InvoiceStatus.draft && inv.status != InvoiceStatus.cancelled)
        .toList();
    if (customerInvoices.isEmpty) return null;
    return customerInvoices.map((inv) => inv.invoiceDate).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // Dynamic Product Calculations
  List<Customer> getCustomersWhoBoughtProduct(String productId) {
    final productInvoices = _invoices.where((inv) => inv.items.any((item) => item.product.id == productId));
    final Set<String> customerIds = {};
    final List<Customer> buyers = [];
    for (final inv in productInvoices) {
      if (!customerIds.contains(inv.customer.id)) {
        customerIds.add(inv.customer.id);
        buyers.add(inv.customer);
      }
    }
    return buyers;
  }

  List<Invoice> getInvoicesForProduct(String productId) {
    return _invoices.where((inv) => inv.items.any((item) => item.product.id == productId)).toList()
      ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
  }

  int getQuantitySoldForProduct(String productId) {
    return _invoices
        .where((inv) => inv.status != InvoiceStatus.draft && inv.status != InvoiceStatus.cancelled)
        .expand((inv) => inv.items)
        .where((item) => item.product.id == productId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  double getRevenueForProduct(String productId) {
    return _invoices
        .where((inv) => inv.status != InvoiceStatus.draft && inv.status != InvoiceStatus.cancelled)
        .expand((inv) => inv.items)
        .where((item) => item.product.id == productId)
        .fold(0.0, (sum, item) => sum + item.total);
  }

  DateTime? getLastSaleDateForProduct(String productId) {
    final productInvoices = _invoices
        .where((inv) => inv.status != InvoiceStatus.draft && inv.status != InvoiceStatus.cancelled && inv.items.any((item) => item.product.id == productId))
        .toList();
    if (productInvoices.isEmpty) return null;
    return productInvoices.map((inv) => inv.invoiceDate).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // Invoice creation methods
  void startNewInvoice() {
    _selectedCustomer = null;
    _selectedItems = [];
    _invoiceDate = DateTime.now();
    _dueDate = DateTime.now().add(const Duration(days: 30));
    _notes = '';
    _terms = '';
    _editingInvoice = null;
    _invoiceNumber = 'Auto-Generated';
    _isPaid = false;
    notifyListeners();
    loadNextInvoiceNumber();
  }

  void startEditingInvoice(Invoice invoice) {
    _editingInvoice = invoice;
    _selectedCustomer = invoice.customer;
    _selectedItems = List.from(invoice.items);
    _invoiceDate = invoice.invoiceDate;
    _dueDate = invoice.dueDate;
    _notes = invoice.notes ?? '';
    _terms = invoice.terms ?? '';
    _invoiceNumber = invoice.invoiceNumber;
    _isPaid = invoice.status == InvoiceStatus.paid;
    notifyListeners();
  }

  void selectCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void addProduct(Product product) {
    final existingIndex = _selectedItems.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final existingItem = _selectedItems[existingIndex];
      _selectedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
    } else {
      _selectedItems.add(
        InvoiceItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(100).toString(),
          product: product,
          quantity: 1,
          unitPrice: product.price,
          discountPercentage: 0.0,
          taxPercentage: product.gst,
        ),
      );
    }
    notifyListeners();
  }

  void removeProduct(String productId) {
    _selectedItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateItemQty(String productId, int newQty) {
    final index = _selectedItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (newQty <= 0) {
        _selectedItems.removeAt(index);
      } else {
        _selectedItems[index] = _selectedItems[index].copyWith(quantity: newQty);
      }
      notifyListeners();
    }
  }

  void updateItemDiscount(String productId, double discount) {
    final index = _selectedItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _selectedItems[index] = _selectedItems[index].copyWith(discountPercentage: discount);
      notifyListeners();
    }
  }

  void updateItemTax(String productId, double tax) {
    final index = _selectedItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _selectedItems[index] = _selectedItems[index].copyWith(taxPercentage: tax);
      notifyListeners();
    }
  }

  void updateInvoiceDate(DateTime date) {
    _invoiceDate = date;
    if (_dueDate.isBefore(_invoiceDate)) {
      _dueDate = _invoiceDate.add(const Duration(days: 30));
    }
    notifyListeners();
  }

  void updateDueDate(DateTime date) {
    _dueDate = date;
    notifyListeners();
  }

  void updateNotes(String val) {
    _notes = val;
  }

  void updateTerms(String val) {
    _terms = val;
  }

  void updateInvoiceNumber(String val) {
    _invoiceNumber = val;
    notifyListeners();
  }

  Future<void> loadNextInvoiceNumber() async {
    try {
      final response = await ApiService().get('/api/invoices/next-number/');
      if (response['success'] == true) {
        final data = response['data'] ?? {};
        final nextNum = data['next_invoice_number'] as String?;
        if (nextNum != null && _invoiceNumber == 'Auto-Generated') {
          _invoiceNumber = nextNum;
          notifyListeners();
        }
      }
    } catch (e) {
      // Ignore or log
    }
  }

  String getNextInvoiceNumberFallback(FinancialSettings? settings) {
    if (settings == null) return 'INV-001';
    
    final prefix = settings.invoicePrefix.isEmpty ? 'INV' : settings.invoicePrefix;
    final startingNum = settings.invoiceStartingNumber;
    final padding = settings.invoiceNumberPadding;
    final formatType = settings.invoiceNumberFormat;
    
    // Count local invoices
    final count = _invoices.length + startingNum;
    final paddedNumber = count.toString().padLeft(padding, '0');
    final currentYear = DateTime.now().year.toString();
    
    if (formatType == 'prefix_number') {
      return '$prefix$paddedNumber';
    } else if (formatType == 'prefix_year_number') {
      return '$prefix/$currentYear/$paddedNumber';
    } else {
      return '$prefix-$paddedNumber';
    }
  }

  void updateIsPaid(bool val) {
    _isPaid = val;
    notifyListeners();
  }

  Map<String, dynamic> _getSavePayload({
    double shippingCharges = 0.0,
    double adjustment = 0.0,
    String? paymentTerms,
    String? referenceNumber,
    String? salesperson,
    String currency = 'INR',
  }) {
    final Map<String, dynamic> payload = {
      'customer': _selectedCustomer?.id,
      'invoice_date': _invoiceDate.toIso8601String().substring(0, 10),
      'due_date': _dueDate.toIso8601String().substring(0, 10),
      'notes': _notes,
      'terms_and_conditions': _terms,
      'shipping_charges': shippingCharges,
      'adjustment': adjustment,
      'payment_terms': paymentTerms ?? 'Due on Receipt',
      'reference_number': referenceNumber ?? '',
      'salesperson': salesperson ?? '',
      'currency': currency.contains('USD') ? 'USD' : (currency.contains('EUR') ? 'EUR' : (currency.contains('GBP') ? 'GBP' : 'INR')),
      'items': _selectedItems.map((item) => {
        'product': item.product.id,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'discount': item.discountPercentage,
        'discount_type': 'percentage',
        'tax_percentage': item.taxPercentage,
      }).toList(),
    };

    if (_invoiceNumber.isNotEmpty && _invoiceNumber != 'Auto-Generated') {
      payload['invoice_number'] = _invoiceNumber;
    }
    if (_isPaid) {
      payload['status'] = 'paid';
    }
    return payload;
  }

  void _parseFieldErrors(Map<String, dynamic> errors) {
    _fieldErrors.clear();
    errors.forEach((key, value) {
      if (value is List) {
        _fieldErrors[key] = value.map((e) => e.toString()).toList();
      } else if (value is Map<String, dynamic>) {
        value.forEach((subKey, subVal) {
          if (subVal is List) {
            _fieldErrors['$key.$subKey'] = subVal.map((e) => e.toString()).toList();
          } else {
            _fieldErrors['$key.$subKey'] = [subVal.toString()];
          }
        });
      } else if (value != null) {
        _fieldErrors[key] = [value.toString()];
      }
    });
  }

  // Save invoice to database (calls POST or PUT on API)
  Future<bool> saveInvoice({
    double shippingCharges = 0.0,
    double adjustment = 0.0,
    String? paymentTerms,
    String? referenceNumber,
    String? salesperson,
    String currency = 'INR',
  }) async {
    if (_selectedCustomer == null || _selectedItems.isEmpty) {
      _errorMessage = 'Please select a customer and add at least one line item.';
      notifyListeners();
      return false;
    }

    // The API only permits changes to drafts. Keep this rule on the client as
    // well so users get a clear message instead of an avoidable failed request.
    if (_editingInvoice != null && _editingInvoice!.status != InvoiceStatus.draft) {
      _fieldErrors.clear();
      _errorMessage = 'Only draft invoices can be updated. Create a new invoice instead.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _fieldErrors.clear();
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = _getSavePayload(
        shippingCharges: shippingCharges,
        adjustment: adjustment,
        paymentTerms: paymentTerms,
        referenceNumber: referenceNumber,
        salesperson: salesperson,
        currency: currency,
      );
      Map<String, dynamic> response;
      if (_editingInvoice != null) {
        response = await ApiService().put('/api/invoices/${_editingInvoice!.id}/', payload);
      } else {
        response = await ApiService().post('/api/invoices/', payload);
      }

      if (response['success'] == true) {
        final savedInvoice = Invoice.fromJson(response['data'] as Map<String, dynamic>);
        if (_editingInvoice != null) {
          final index = _invoices.indexWhere((inv) => inv.id == _editingInvoice!.id);
          if (index >= 0) {
            _invoices[index] = savedInvoice;
          }
        } else {
          _invoices.add(savedInvoice);
        }
        startEditingInvoice(savedInvoice);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to save invoice';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
          if (_fieldErrors.isNotEmpty) {
            final details = _fieldErrors.entries
                .map((e) => '${e.key}: ${e.value.join(", ")}')
                .join('; ');
            if (details.isNotEmpty) {
              _errorMessage = details;
            }
          }
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error saving invoice: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete invoice (calls DELETE on API)
  Future<bool> deleteInvoice(String invoiceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiService().delete('/api/invoices/$invoiceId/');
      if (response['success'] == true) {
        _invoices.removeWhere((inv) => inv.id == invoiceId);
        _payments.removeWhere((p) => p.invoiceId == invoiceId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete invoice';
      }
    } catch (e) {
      _errorMessage = 'Error deleting invoice: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Duplicate invoice (calls POST duplicate on API)
  Future<bool> duplicateInvoice(Invoice invoice) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiService().post('/api/invoices/${invoice.id}/duplicate/', {});
      if (response['success'] == true) {
        final newInvoice = Invoice.fromJson(response['data'] as Map<String, dynamic>);
        _invoices.add(newInvoice);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to duplicate invoice';
      }
    } catch (e) {
      _errorMessage = 'Error duplicating invoice: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Mark invoice as sent (calls POST send on API)
  Future<bool> markAsSent(String invoiceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiService().post('/api/invoices/$invoiceId/send/', {});
      if (response['success'] == true) {
        final updatedInvoice = Invoice.fromJson(response['data'] as Map<String, dynamic>);
        final index = _invoices.indexWhere((inv) => inv.id == invoiceId);
        if (index >= 0) {
          _invoices[index] = updatedInvoice;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to mark invoice as sent';
      }
    } catch (e) {
      _errorMessage = 'Error sending invoice: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Record payment (calls POST payment on API)
  Future<bool> recordPayment({
    required String invoiceId,
    required double amount,
    required String paymentMode,
    required DateTime paymentDate,
    String? reference,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final payload = {
        'amount': amount.toStringAsFixed(2),
        'payment_method': paymentMode.toLowerCase(),
        'payment_date': paymentDate.toIso8601String().substring(0, 10),
        'reference_number': reference ?? '',
        'notes': notes ?? '',
      };
      final response = await ApiService().post('/api/invoices/$invoiceId/payment/', payload);
      if (response['success'] == true) {
        await fetchInvoiceDetails(invoiceId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to record payment';
      }
    } catch (e) {
      _errorMessage = 'Error recording payment: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Download and view invoice PDF
  Future<bool> downloadInvoicePdf({
    required String invoiceId,
    required String invoiceNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final bytes = await ApiService().getBytes('/api/invoices/$invoiceId/pdf/');
      if (bytes != null) {
        await saveAndOpenFile(bytes, 'invoice_$invoiceNumber.pdf');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to download PDF from server';
      }
    } catch (e) {
      _errorMessage = 'Error downloading PDF: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  String _randomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }
}
