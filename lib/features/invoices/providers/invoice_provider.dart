import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final Map<String, List<String>> _fieldErrors = {};

  // Pagination & Filtering state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  DateTime? _startDate;
  DateTime? _endDate;

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
  String _statusFilter = 'All'; // 'All', 'Draft', 'Sent', 'Partially Paid', 'Paid', 'Overdue'
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

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

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

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
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

  // Fetch invoices from backend (Paginated & Filterable)
  Future<void> fetchInvoices({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _currentPage = 1;
      _nextPageUrl = null;
      _hasMore = true;
    } else {
      if (!_hasMore) return;
      _currentPage++;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'page': '$_currentPage',
        'page_size': '10',
      };
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }
      if (_statusFilter != 'All') {
        queryParams['status'] = _statusFilter.toLowerCase().replaceAll(' ', '_');
      }
      if (_startDate != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(_startDate!);
      }
      if (_endDate != null) {
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(_endDate!);
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = '/api/v1/invoices?$queryString';
      final response = await ApiService().get(url);
      if (response['success'] == true) {
        final data = response['data'] ?? {};
        final results = (data is Map && data['results'] is List)
            ? data['results'] as List<dynamic>
            : (data is List ? data : []);
        
        final List<Invoice> fetchedInvoices = results
            .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
            .toList();

        if (refresh) {
          _invoices.clear();
        }
        _invoices.addAll(fetchedInvoices);

        if (data is Map) {
          _totalCount = data['count'] is int ? data['count'] as int : _invoices.length;
          _totalPages = data['total_pages'] is int ? data['total_pages'] as int : 1;
          _currentPage = data['page'] is int ? data['page'] as int : _currentPage;
          _nextPageUrl = data['next'] as String?;
          _hasMore = _nextPageUrl != null || _currentPage < _totalPages;
        } else {
          _hasMore = false;
        }

        // Also gather all payments nested within these invoices for payment history compatibility
        final allPayments = <Payment>[];
        for (var invoice in fetchedInvoices) {
          allPayments.addAll(invoice.payments);
        }
        if (refresh) {
          _payments.clear();
        }
        _payments.addAll(allPayments);

        if (data is Map && data.containsKey('dashboard_summary')) {
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
      final response = await ApiService().get('/api/v1/invoices/$id');
      if (response['success'] == true) {
        final Map<String, dynamic> data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        final invoice = Invoice.fromJson(data);
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
          ? '/api/v1/customers' 
          : '/api/v1/customers?search=${Uri.encodeComponent(query)}';
      final response = await ApiService().get(path);
      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> dataList = data is List 
            ? data 
            : (data is Map && data['results'] is List ? data['results'] as List<dynamic> : []);
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
          ? '/api/v1/products' 
          : '/api/v1/products?search=${Uri.encodeComponent(query)}';
      final response = await ApiService().get(path);
      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> dataList = data is List 
            ? data 
            : (data is Map && data['results'] is List ? data['results'] as List<dynamic> : []);
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
    final existingIndex = _selectedItems.indexWhere((item) =>
      (product.id.isNotEmpty && item.product.id.isNotEmpty && item.product.id == product.id) ||
      (product.name.isNotEmpty && item.product.name.isNotEmpty && item.product.name.trim().toLowerCase() == product.name.trim().toLowerCase())
    );
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

  void addItem(InvoiceItem item) {
    _selectedItems.add(item);
    notifyListeners();
  }

  void addOrIncrementProduct(Product product, {int quantity = 1, double? price, String? unit}) {
    final effectivePrice = price ?? (product.price > 0 ? product.price : (product.sellingPrice > 0 ? product.sellingPrice : 10.0));
    final index = _selectedItems.indexWhere((item) =>
      item.product.id == product.id ||
      (product.id.isNotEmpty && item.id == product.id) ||
      item.product.name.trim().toLowerCase() == product.name.trim().toLowerCase()
    );
    if (index >= 0) {
      final current = _selectedItems[index];
      _selectedItems[index] = current.copyWith(
        quantity: current.quantity + quantity,
      );
    } else {
      final itemId = 'item_${DateTime.now().millisecondsSinceEpoch}_${_selectedItems.length + 1}';
      _selectedItems.add(
        InvoiceItem(
          id: itemId,
          product: product,
          quantity: quantity,
          unitPrice: effectivePrice,
          taxPercentage: product.gst > 0 ? product.gst : 18.0,
          unit: unit ?? (product.unitAbbreviation.isNotEmpty ? product.unitAbbreviation : 'Pcs'),
          itemName: product.name,
          description: product.name,
          hsnSac: product.hsnSacCode,
        ),
      );
    }
    notifyListeners();
  }

  void addCustomItem({
    required String name,
    required double price,
    int quantity = 1,
    double taxPercentage = 18.0,
    String unit = 'Pcs',
  }) {
    final customProduct = Product(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      sku: '',
      barcode: '',
      category: 'General',
      brand: '',
      purchasePrice: 0.0,
      sellingPrice: price,
      stock: 999,
      minStock: 0,
      gst: taxPercentage,
      unitAbbreviation: unit,
      createdAt: DateTime.now(),
    );

    addOrIncrementProduct(customProduct, quantity: quantity, price: price, unit: unit);
  }

  void removeProduct(String productId) {
    _selectedItems.removeWhere((item) =>
      item.product.id == productId ||
      item.id == productId ||
      item.product.name.trim().toLowerCase() == productId.trim().toLowerCase()
    );
    notifyListeners();
  }

  void updateItemQty(String productId, int newQty) {
    final index = _selectedItems.indexWhere((item) =>
      item.product.id == productId ||
      item.id == productId ||
      item.product.name.trim().toLowerCase() == productId.trim().toLowerCase()
    );
    if (index >= 0) {
      if (newQty <= 0) {
        _selectedItems.removeAt(index);
      } else {
        _selectedItems[index] = _selectedItems[index].copyWith(quantity: newQty);
      }
      notifyListeners();
    }
  }

  void updateItemDiscount(String productId, double discount, [String? discountType]) {
    final index = _selectedItems.indexWhere((item) =>
      item.product.id == productId ||
      item.id == productId ||
      item.product.name.trim().toLowerCase() == productId.trim().toLowerCase()
    );
    if (index >= 0) {
      final currentType = discountType ?? _selectedItems[index].discountType;
      _selectedItems[index] = _selectedItems[index].copyWith(
        discountValue: discount,
        discountPercentage: currentType == '%' ? discount : _selectedItems[index].discountPercentage,
        discountType: currentType,
      );
      notifyListeners();
    }
  }

  void updateItemDiscountType(String productId, String discountType) {
    final index = _selectedItems.indexWhere((item) =>
      item.product.id == productId ||
      item.id == productId ||
      item.product.name.trim().toLowerCase() == productId.trim().toLowerCase()
    );
    if (index >= 0) {
      _selectedItems[index] = _selectedItems[index].copyWith(
        discountType: discountType,
      );
      notifyListeners();
    }
  }

  void updateItemTax(String productId, double tax) {
    final index = _selectedItems.indexWhere((item) =>
      item.product.id == productId ||
      item.id == productId ||
      item.product.name.trim().toLowerCase() == productId.trim().toLowerCase()
    );
    if (index >= 0) {
      _selectedItems[index] = _selectedItems[index].copyWith(taxPercentage: tax);
      notifyListeners();
    }
  }

  void updateItemPrice(String itemId, double price) {
    final index = _selectedItems.indexWhere((item) =>
      item.id == itemId ||
      item.product.id == itemId ||
      item.product.name.trim().toLowerCase() == itemId.trim().toLowerCase()
    );
    if (index >= 0) {
      _selectedItems[index] = _selectedItems[index].copyWith(unitPrice: price);
      notifyListeners();
    }
  }

  void updateItemName(String itemId, String name) {
    final index = _selectedItems.indexWhere((item) =>
      item.id == itemId ||
      item.product.id == itemId ||
      item.product.name.trim().toLowerCase() == itemId.trim().toLowerCase()
    );
    if (index >= 0) {
      final oldProduct = _selectedItems[index].product;
      _selectedItems[index] = _selectedItems[index].copyWith(
        product: oldProduct.copyWith(name: name),
        itemName: name,
        description: name,
      );
      notifyListeners();
    }
  }

  void updateItemHsn(String itemId, String hsn) {
    final index = _selectedItems.indexWhere((item) =>
      item.id == itemId ||
      item.product.id == itemId ||
      item.product.name.trim().toLowerCase() == itemId.trim().toLowerCase()
    );
    if (index >= 0) {
      final oldProduct = _selectedItems[index].product;
      _selectedItems[index] = _selectedItems[index].copyWith(
        product: oldProduct.copyWith(hsnSacCode: hsn),
        hsnSac: hsn,
      );
      notifyListeners();
    }
  }

  void updateItemUnit(String itemId, String unit) {
    final index = _selectedItems.indexWhere((item) =>
      item.id == itemId ||
      item.product.id == itemId ||
      item.product.name.trim().toLowerCase() == itemId.trim().toLowerCase()
    );
    if (index >= 0) {
      final oldProduct = _selectedItems[index].product;
      _selectedItems[index] = _selectedItems[index].copyWith(
        product: oldProduct.copyWith(unitAbbreviation: unit),
        unit: unit,
      );
      notifyListeners();
    }
  }

  void addNewEmptyItem() {
    final newItemId = 'item_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100)}';
    final product = Product(
      id: '',
      name: '',
      sku: '',
      category: 'General',
      brand: 'General',
      stock: 999,
      minStock: 0,
      unitAbbreviation: 'Nos',
      unitOfMeasurement: 'Numbers',
      hsnSacCode: '',
      sellingPrice: 0.0,
      gst: 18.0,
      createdAt: DateTime.now(),
    );
    _selectedItems.add(
      InvoiceItem(
        id: newItemId,
        product: product,
        quantity: 1,
        unitPrice: 0.0,
        discountPercentage: 0.0,
        taxPercentage: 18.0,
        discountType: '%',
        discountValue: 0.0,
        unit: 'Nos',
        hsnSac: '',
        itemName: '',
      ),
    );
    notifyListeners();
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
    double amountReceived = 0.0,
    String paymentMode = 'UPI',
    bool isDraft = false,
    bool isRoundOff = true,
    bool markAsFullyPaid = false,
    String? customerType,
    String? mobileNumber,
    String? gstin,
    String? email,
    String? billingAddress,
    String? shippingAddress,
    bool shippingSameAsBilling = true,
    String? internalNotes,
    String? notes,
    String? termsAndConditions,
  }) {
    final customerVal = (_selectedCustomer?.id != null && _selectedCustomer!.id.isNotEmpty)
        ? _selectedCustomer!.id
        : ((_selectedCustomer?.phone != null && _selectedCustomer!.phone.isNotEmpty)
            ? _selectedCustomer!.phone
            : (_selectedCustomer?.name ?? ''));

    final cleanCurrency = currency.contains('USD')
        ? 'USD'
        : (currency.contains('EUR')
            ? 'EUR'
            : (currency.contains('GBP') ? 'GBP' : 'INR'));

    final custType = (customerType != null && customerType.isNotEmpty)
        ? customerType
        : (_selectedCustomer?.customerType ?? 'Business');
    final formattedCustType = custType.isNotEmpty
        ? (custType[0].toUpperCase() + custType.substring(1))
        : 'Business';

    final mobile = (mobileNumber != null && mobileNumber.isNotEmpty)
        ? mobileNumber
        : (_selectedCustomer?.phone ?? '');
    final gst = (gstin != null && gstin.isNotEmpty)
        ? gstin
        : (_selectedCustomer?.gstNo ?? '');
    final custEmail = (email != null && email.isNotEmpty)
        ? email
        : (_selectedCustomer?.email ?? '');
    final bAddress = (billingAddress != null && billingAddress.isNotEmpty)
        ? billingAddress
        : (_selectedCustomer?.address ?? '');
    final sAddress = shippingSameAsBilling
        ? bAddress
        : ((shippingAddress != null && shippingAddress.isNotEmpty)
            ? shippingAddress
            : (_selectedCustomer?.shippingAddressLine1.isNotEmpty == true
                ? _selectedCustomer!.shippingAddressLine1
                : bAddress));

    final resolvedNotes = notes ?? _notes;
    final resolvedTerms = termsAndConditions ?? _terms;

    final double calculatedSubtotal = grandTotal;
    final double rawTotal = (calculatedSubtotal + shippingCharges + adjustment);
    final double totalAmount = isRoundOff ? rawTotal.roundToDouble() : rawTotal;
    final double effectivePaid = markAsFullyPaid ? totalAmount : amountReceived;
    final double remainingBalance = (totalAmount - effectivePaid).clamp(0.0, double.infinity);

    final Map<String, dynamic> payload = {
      'customer': customerVal,
      'invoice_date': _invoiceDate.toIso8601String().substring(0, 10),
      'due_date': _dueDate.toIso8601String().substring(0, 10),
      'currency': cleanCurrency,
      'payment_mode': paymentMode,
      'sales_person': (salesperson != null && salesperson.isNotEmpty) ? salesperson : 'General Sales',
      'reference_no': referenceNumber ?? '',
      'customer_type': formattedCustType,
      'mobile_number': mobile,
      'gstin': gst,
      'email': custEmail,
      'billing_address': bAddress,
      'shipping_address': sAddress,
      'shipping_same_as_billing': shippingSameAsBilling,
      'notes': resolvedNotes,
      'terms_and_conditions': resolvedTerms,
      'internal_notes': internalNotes ?? '',
      'is_round_off': isRoundOff,
      'mark_as_fully_paid': markAsFullyPaid,
      'amount_received': effectivePaid,
      'items': _selectedItems.map((item) {
        final itemName = (item.itemName != null && item.itemName!.isNotEmpty)
            ? item.itemName!
            : (item.product.name.isNotEmpty ? item.product.name : item.description);
        final productId = item.product.id.isNotEmpty ? item.product.id : itemName;
        final hsn = (item.hsnSac != null && item.hsnSac!.isNotEmpty)
            ? item.hsnSac!
            : item.product.hsnSacCode;
        final unitStr = (item.unit != null && item.unit!.isNotEmpty)
            ? item.unit!
            : (item.product.unitAbbreviation.isNotEmpty ? item.product.unitAbbreviation : 'Nos');
        final disc = item.discountType == '₹'
            ? (item.discountValue > 0 ? item.discountValue : item.discountAmount)
            : (item.discountValue > 0 ? item.discountValue : item.discountPercentage);

        return {
          'product': productId,
          'item_name': itemName,
          'description': item.description.isNotEmpty ? item.description : itemName,
          'hsn_sac': hsn,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount': disc,
          'discount_type': item.discountType,
          'tax': item.taxPercentage,
          'unit': unitStr,
        };
      }).toList(),
    };

    if (_invoiceNumber.isNotEmpty && _invoiceNumber != 'Auto-Generated') {
      payload['invoice_number'] = _invoiceNumber;
    }
    if (referenceNumber != null && referenceNumber.isNotEmpty) {
      payload['reference_number'] = referenceNumber;
    }
    if (salesperson != null && salesperson.isNotEmpty) {
      payload['salesperson'] = salesperson;
    }
    if (paymentTerms != null && paymentTerms.isNotEmpty) {
      payload['payment_terms'] = paymentTerms;
    }
    if (shippingCharges > 0) {
      payload['shipping_charges'] = shippingCharges;
    }
    if (adjustment != 0) {
      payload['adjustment'] = adjustment;
    }
    payload['balance_due'] = remainingBalance;

    if (isDraft) {
      payload['status'] = 'draft';
    } else if (markAsFullyPaid || (effectivePaid >= totalAmount && totalAmount > 0)) {
      payload['status'] = 'paid';
    } else if (effectivePaid > 0) {
      payload['status'] = 'partially_paid';
    } else {
      payload['status'] = 'draft';
    }

    return payload;
  }

  // Generate payload for PUT /api/v1/invoices/{id} (UpdateInvoiceRequest DTO)
  Map<String, dynamic> _getUpdatePayload({
    double shippingCharges = 0.0,
    double adjustment = 0.0,
    String? referenceNumber,
    String? salesperson,
    double amountReceived = 0.0,
    String paymentMode = 'UPI',
    bool isDraft = false,
    bool isRoundOff = true,
    bool markAsFullyPaid = false,
    String? customerType,
    String? mobileNumber,
    String? gstin,
    String? email,
    String? billingAddress,
    String? shippingAddress,
    bool shippingSameAsBilling = true,
    String? internalNotes,
    String? notes,
    String? termsAndConditions,
  }) {
    final custType = (customerType != null && customerType.isNotEmpty)
        ? customerType
        : (_selectedCustomer?.customerType ?? 'Business');
    final formattedCustType = custType.isNotEmpty
        ? (custType[0].toUpperCase() + custType.substring(1))
        : 'Business';

    final mobile = (mobileNumber != null && mobileNumber.isNotEmpty)
        ? mobileNumber
        : (_selectedCustomer?.phone ?? '');
    final gst = (gstin != null && gstin.isNotEmpty)
        ? gstin
        : (_selectedCustomer?.gstNo ?? '');
    final custEmail = (email != null && email.isNotEmpty)
        ? email
        : (_selectedCustomer?.email ?? '');
    final bAddress = (billingAddress != null && billingAddress.isNotEmpty)
        ? billingAddress
        : (_selectedCustomer?.address ?? '');
    final sAddress = shippingSameAsBilling
        ? bAddress
        : ((shippingAddress != null && shippingAddress.isNotEmpty)
            ? shippingAddress
            : (_selectedCustomer?.shippingAddressLine1.isNotEmpty == true
                ? _selectedCustomer!.shippingAddressLine1
                : bAddress));

    final resolvedNotes = notes ?? _notes;
    final resolvedTerms = termsAndConditions ?? _terms;

    final double calculatedSubtotal = grandTotal;
    final double rawTotal = (calculatedSubtotal + shippingCharges + adjustment);
    final double totalAmount = isRoundOff ? rawTotal.roundToDouble() : rawTotal;
    final double effectivePaid = markAsFullyPaid ? totalAmount : amountReceived;
    final double remainingBalance = (totalAmount - effectivePaid).clamp(0.0, double.infinity);

    String statusStr = 'draft';
    if (isDraft) {
      statusStr = 'draft';
    } else if (markAsFullyPaid || (effectivePaid >= totalAmount && totalAmount > 0)) {
      statusStr = 'paid';
    } else if (effectivePaid > 0) {
      statusStr = 'partially_paid';
    } else if (_editingInvoice != null && _editingInvoice!.status == InvoiceStatus.sent) {
      statusStr = 'sent';
    } else {
      statusStr = 'sent';
    }

    final Map<String, dynamic> payload = {
      'due_date': _dueDate.toIso8601String().substring(0, 10),
      'sales_person': (salesperson != null && salesperson.isNotEmpty) ? salesperson : 'General Sales',
      'reference_no': referenceNumber ?? '',
      'customer_type': formattedCustType,
      'mobile_number': mobile,
      'gstin': gst,
      'email': custEmail,
      'billing_address': bAddress,
      'shipping_address': sAddress,
      'shipping_same_as_billing': shippingSameAsBilling,
      'payment_mode': paymentMode,
      'notes': resolvedNotes,
      'terms_and_conditions': resolvedTerms,
      'internal_notes': internalNotes ?? '',
      'is_round_off': isRoundOff,
      'status': statusStr,
      'amount_received': effectivePaid,
      'mark_as_fully_paid': markAsFullyPaid,
      'balance_due': remainingBalance,
      'items': _selectedItems.map((item) {
        final itemName = (item.itemName != null && item.itemName!.isNotEmpty)
            ? item.itemName!
            : (item.product.name.isNotEmpty ? item.product.name : item.description);
        final productId = item.product.id.isNotEmpty ? item.product.id : itemName;
        final hsn = (item.hsnSac != null && item.hsnSac!.isNotEmpty)
            ? item.hsnSac!
            : item.product.hsnSacCode;
        final unitStr = (item.unit != null && item.unit!.isNotEmpty)
            ? item.unit!
            : (item.product.unitAbbreviation.isNotEmpty ? item.product.unitAbbreviation : 'Nos');
        final disc = item.discountType == '₹'
            ? (item.discountValue > 0 ? item.discountValue : item.discountAmount)
            : (item.discountValue > 0 ? item.discountValue : item.discountPercentage);

        return {
          'product': productId,
          'item_name': itemName,
          'description': item.description.isNotEmpty ? item.description : itemName,
          'hsn_sac': hsn,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount': disc,
          'discount_type': item.discountType,
          'tax': item.taxPercentage,
          'unit': unitStr,
        };
      }).toList(),
    };

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

  // Save invoice to database (calls POST /api/v1/invoices or PUT /api/v1/invoices/{id})
  Future<bool> saveInvoice({
    double shippingCharges = 0.0,
    double adjustment = 0.0,
    String? paymentTerms,
    String? referenceNumber,
    String? salesperson,
    String currency = 'INR',
    double amountReceived = 0.0,
    String paymentMode = 'UPI',
    bool isDraft = false,
    bool isRoundOff = true,
    bool markAsFullyPaid = false,
    String? customerType,
    String? mobileNumber,
    String? gstin,
    String? email,
    String? billingAddress,
    String? shippingAddress,
    bool shippingSameAsBilling = true,
    String? internalNotes,
    String? notes,
    String? termsAndConditions,
  }) async {
    if (_selectedItems.isEmpty) {
      _errorMessage = 'Please add at least one line item to the invoice.';
      notifyListeners();
      return false;
    }

    // Default to Walk-in Customer if none explicitly selected
    _selectedCustomer ??= Customer(
      id: 'CUST-WALKIN',
      displayName: 'Walk-in Customer',
      companyName: 'Cash Sale',
      primaryPhone: mobileNumber ?? '',
      billingCity: '',
      billingState: '',
      createdAt: DateTime.now(),
    );

    _isLoading = true;
    _fieldErrors.clear();
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> response;
      if (_editingInvoice != null) {
        final payload = _getUpdatePayload(
          shippingCharges: shippingCharges,
          adjustment: adjustment,
          referenceNumber: referenceNumber,
          salesperson: salesperson,
          amountReceived: amountReceived,
          paymentMode: paymentMode,
          isDraft: isDraft,
          isRoundOff: isRoundOff,
          markAsFullyPaid: markAsFullyPaid,
          customerType: customerType,
          mobileNumber: mobileNumber,
          gstin: gstin,
          email: email,
          billingAddress: billingAddress,
          shippingAddress: shippingAddress,
          shippingSameAsBilling: shippingSameAsBilling,
          internalNotes: internalNotes,
          notes: notes,
          termsAndConditions: termsAndConditions,
        );
        response = await ApiService().put('/api/v1/invoices/${_editingInvoice!.id}', payload);
      } else {
        final payload = _getSavePayload(
          shippingCharges: shippingCharges,
          adjustment: adjustment,
          paymentTerms: paymentTerms,
          referenceNumber: referenceNumber,
          salesperson: salesperson,
          currency: currency,
          amountReceived: amountReceived,
          paymentMode: paymentMode,
          isDraft: isDraft,
          isRoundOff: isRoundOff,
          markAsFullyPaid: markAsFullyPaid,
          customerType: customerType,
          mobileNumber: mobileNumber,
          gstin: gstin,
          email: email,
          billingAddress: billingAddress,
          shippingAddress: shippingAddress,
          shippingSameAsBilling: shippingSameAsBilling,
          internalNotes: internalNotes,
          notes: notes,
          termsAndConditions: termsAndConditions,
        );
        response = await ApiService().post('/api/v1/invoices', payload);
      }

      if (response['success'] == true) {
        final Map<String, dynamic> data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        final parsedInvoice = Invoice.fromJson(data);
        final savedInvoice = Invoice(
          id: parsedInvoice.id,
          invoiceNumber: parsedInvoice.invoiceNumber.isNotEmpty ? parsedInvoice.invoiceNumber : _invoiceNumber,
          customer: (parsedInvoice.customer.phone.isNotEmpty || parsedInvoice.customer.email.isNotEmpty)
              ? parsedInvoice.customer
              : (_selectedCustomer ?? parsedInvoice.customer),
          invoiceDate: parsedInvoice.invoiceDate,
          dueDate: parsedInvoice.dueDate,
          items: parsedInvoice.items.isNotEmpty ? parsedInvoice.items : List.from(_selectedItems),
          notes: parsedInvoice.notes ?? _notes,
          terms: parsedInvoice.terms ?? _terms,
          status: parsedInvoice.status,
          payments: parsedInvoice.payments,
          currency: parsedInvoice.currency,
          subtotalField: parsedInvoice.subtotalField ?? subtotal,
          totalDiscountField: parsedInvoice.totalDiscountField ?? totalDiscount,
          totalTaxField: parsedInvoice.totalTaxField ?? totalTax,
          grandTotalField: parsedInvoice.grandTotalField ?? grandTotal,
          balanceDueField: parsedInvoice.balanceDueField,
          paidAmountField: parsedInvoice.paidAmountField,
        );

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
    } catch (_) {
      // Offline fallback: save invoice locally
      final effectiveInvNum = _invoiceNumber.isNotEmpty && _invoiceNumber != 'Auto-Generated'
          ? _invoiceNumber
          : 'INV-${DateFormat('yyyyMMdd').format(_invoiceDate)}-${(_invoices.length + 1).toString().padLeft(2, '0')}';

      final savedInvoice = Invoice(
        id: _editingInvoice?.id ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: effectiveInvNum,
        customer: _selectedCustomer ?? Customer(
          id: 'CUST-WALKIN',
          displayName: 'Walk-in Customer',
          companyName: 'Cash Sale',
          createdAt: DateTime.now(),
        ),
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        items: List.from(_selectedItems),
        notes: notes ?? _notes,
        terms: termsAndConditions ?? _terms,
        status: isDraft ? InvoiceStatus.draft : (markAsFullyPaid ? InvoiceStatus.paid : InvoiceStatus.sent),
        payments: markAsFullyPaid
            ? [
                Payment(
                  id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
                  paymentNumber: 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  invoiceId: _editingInvoice?.id ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
                  amount: grandTotal,
                  paymentMode: paymentMode,
                  paymentDate: DateTime.now(),
                ),
              ]
            : [],
        currency: currency,
        subtotalField: subtotal,
        totalDiscountField: totalDiscount,
        totalTaxField: totalTax,
        grandTotalField: grandTotal,
        paidAmountField: markAsFullyPaid ? grandTotal : 0.0,
        balanceDueField: markAsFullyPaid ? 0.0 : grandTotal,
      );

      if (_editingInvoice != null) {
        final index = _invoices.indexWhere((inv) => inv.id == _editingInvoice!.id);
        if (index >= 0) {
          _invoices[index] = savedInvoice;
        } else {
          _invoices.insert(0, savedInvoice);
        }
      } else {
        _invoices.insert(0, savedInvoice);
      }
      startEditingInvoice(savedInvoice);
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  // Update invoice (calls PUT / PATCH /api/v1/invoices/{id})
  Future<bool> updateInvoice(String id, Map<String, dynamic> updateData, {bool usePut = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = usePut
          ? await ApiService().put('/api/v1/invoices/$id', updateData)
          : await ApiService().patch('/api/v1/invoices/$id', updateData);

      if (response['success'] == true) {
        if (response['data'] is Map<String, dynamic>) {
          final updated = Invoice.fromJson(response['data'] as Map<String, dynamic>);
          final idx = _invoices.indexWhere((inv) => inv.id == id);
          if (idx >= 0) {
            _invoices[idx] = updated;
          }
          if (_editingInvoice?.id == id) {
            _editingInvoice = updated;
          }
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update invoice';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
        }
      }
    } catch (e) {
      _errorMessage = 'Error updating invoice: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Option 2 partial update: Mark invoice as fully paid
  Future<bool> markAsPaid(String invoiceId) async {
    return updateInvoice(invoiceId, {
      'mark_as_fully_paid': true,
      'status': 'paid',
    });
  }

  // Option 2 partial update: Record payment or update amount received
  Future<bool> updateInvoicePayment({
    required String invoiceId,
    required double amountReceived,
    required String paymentMode,
    String? notes,
  }) async {
    return updateInvoice(invoiceId, {
      'status': 'paid',
      'amount_received': amountReceived,
      'payment_mode': paymentMode,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  // Option 2 partial update: Update status
  Future<bool> updateInvoiceStatus(String invoiceId, String status) async {
    return updateInvoice(invoiceId, {
      'status': status,
    });
  }

  // Delete invoice (calls DELETE /api/v1/invoices/{id})
  Future<bool> deleteInvoice(String invoiceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiService().delete('/api/v1/invoices/$invoiceId');
      if (response['success'] == true) {
        _invoices.removeWhere((inv) => inv.id == invoiceId);
        _payments.removeWhere((p) => p.invoiceId == invoiceId);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Local fallback for offline / web preview
      _invoices.removeWhere((inv) => inv.id == invoiceId);
      _payments.removeWhere((p) => p.invoiceId == invoiceId);
      _isLoading = false;
      notifyListeners();
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Duplicate invoice
  Future<bool> duplicateInvoice(Invoice invoice) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiService().post('/api/v1/invoices', {
        'customer': invoice.customer.id.isNotEmpty ? invoice.customer.id : invoice.customer.name,
        'invoice_date': DateTime.now().toIso8601String().substring(0, 10),
        'due_date': DateTime.now().add(const Duration(days: 15)).toIso8601String().substring(0, 10),
        'currency': invoice.currency,
        'notes': invoice.notes ?? '',
        'terms_and_conditions': invoice.terms ?? '',
        'items': invoice.items.map((item) => item.toJson()).toList(),
      });
      if (response['success'] == true) {
        final Map<String, dynamic> data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        final newInvoice = Invoice.fromJson(data);
        _invoices.insert(0, newInvoice);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Offline fallback: duplicate locally
      final newInvoice = invoice.copyWith(
        id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: 'INV-${DateFormat('yyyyMMdd').format(DateTime.now())}-${(_invoices.length + 1).toString().padLeft(2, '0')}',
        invoiceDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 15)),
        status: InvoiceStatus.draft,
        paidAmountField: 0.0,
        balanceDueField: invoice.grandTotal,
        payments: [],
      );
      _invoices.insert(0, newInvoice);
      _isLoading = false;
      notifyListeners();
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Mark invoice as sent (calls POST /api/v1/invoices/{id}/mark-sent)
  Future<bool> markAsSent(String invoiceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiService().post('/api/v1/invoices/$invoiceId/mark-sent', {});
      if (response['success'] == true) {
        final index = _invoices.indexWhere((inv) => inv.id == invoiceId);
        if (index >= 0) {
          if (response['data'] is Map<String, dynamic>) {
            _invoices[index] = Invoice.fromJson(response['data'] as Map<String, dynamic>);
          } else {
            _invoices[index] = _invoices[index].copyWith(status: InvoiceStatus.sent);
          }
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Local fallback
      final index = _invoices.indexWhere((inv) => inv.id == invoiceId);
      if (index >= 0) {
        _invoices[index] = _invoices[index].copyWith(status: InvoiceStatus.sent);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Record payment (calls POST payment on API with local fallback)
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

    final newPayment = Payment(
      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      paymentNumber: 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      invoiceId: invoiceId,
      amount: amount,
      paymentMode: paymentMode,
      paymentDate: paymentDate,
      reference: reference ?? '',
    );

    // Apply immediate local state update so web demo and offline use work seamlessly
    final invIdx = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (invIdx >= 0) {
      final inv = _invoices[invIdx];
      final newReceived = inv.paidAmount + amount;
      final newStatus = newReceived >= (inv.grandTotal - 0.01)
          ? InvoiceStatus.paid
          : InvoiceStatus.partially_paid;

      final updatedPayment = newPayment.copyWith(
        customerId: inv.customer.id,
        customerName: inv.customer.name.isNotEmpty ? inv.customer.name : inv.customer.company,
      );

      _invoices[invIdx] = inv.copyWith(
        paidAmountField: newReceived,
        balanceDueField: (inv.grandTotal - newReceived).clamp(0.0, double.infinity),
        status: newStatus,
        payments: [...inv.payments, updatedPayment],
      );
      _payments.removeWhere((p) => p.id == updatedPayment.id);
      _payments.insert(0, updatedPayment);
    } else {
      _payments.insert(0, newPayment);
    }

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
      }
    } catch (_) {
      // Local state is already updated
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return true;
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
      if (bytes != null && bytes.isNotEmpty) {
        await saveAndOpenFile(bytes, 'invoice_$invoiceNumber.pdf');
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Offline fallback: generate clean PDF locally
    }

    try {
      final fallbackBytes = _generateInvoicePdfBytes(invoiceId, invoiceNumber);
      await saveAndOpenFile(fallbackBytes, 'invoice_$invoiceNumber.pdf');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error downloading PDF: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Uint8List _generateInvoicePdfBytes(String invoiceId, String invoiceNumber) {
    Invoice? inv;
    for (final i in _invoices) {
      if (i.id == invoiceId) {
        inv = i;
        break;
      }
    }
    final invNum = inv?.invoiceNumber ?? invoiceNumber;
    final custName = inv?.customer.name.isNotEmpty == true ? inv!.customer.name : 'Valued Customer';
    final totalStr = inv != null ? inv.grandTotal.toStringAsFixed(2) : '0.00';
    final statusStr = inv?.status.displayName ?? 'Issued';

    final streamContent = 'BT /F1 16 Tf 50 720 Td (GST TAX INVOICE) Tj ET\n'
        'BT /F1 12 Tf 50 690 Td (Invoice Number: $invNum) Tj ET\n'
        'BT /F1 12 Tf 50 670 Td (Customer: $custName) Tj ET\n'
        'BT /F1 12 Tf 50 650 Td (Grand Total: INR $totalStr) Tj ET\n'
        'BT /F1 12 Tf 50 630 Td (Status: $statusStr) Tj ET\n';

    final pdf = '%PDF-1.4\n'
        '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n'
        '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n'
        '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj\n'
        '4 0 obj << /Length ${streamContent.length} >>\nstream\n$streamContent\nendstream\nendobj\n'
        '5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n'
        'xref\n0 6\n0000000000 65535 f \n'
        '0000000009 00000 n \n'
        '0000000058 00000 n \n'
        '0000000115 00000 n \n'
        '0000000244 00000 n \n'
        '0000000350 00000 n \n'
        'trailer << /Size 6 /Root 1 0 R >>\nstartxref\n434\n%%EOF';
    return Uint8List.fromList(pdf.codeUnits);
  }
}
