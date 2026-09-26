import 'package:flutter/material.dart';
import '../models/product.dart';
import '../../../core/services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [];
  bool _isLoading = false;  // for list fetch operations
  bool _isSaving = false;   // for create / update / delete operations
  bool _isLoadingDetails = false; // for single product detail fetch
  String? _errorMessage;
  final Map<String, List<String>> _fieldErrors = {};
  Map<String, dynamic> _dashboardStats = {};
  
  Product? _selectedProductDetails;

  String _searchQuery = '';
  String _activeFilter = 'All';
  String _sortBy = 'Newest';
  
  bool _hasMore = true;
  String? _nextPageUrl;

  // Getters
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get errorMessage => _errorMessage;
  Map<String, List<String>> get fieldErrors => _fieldErrors;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  Product? get selectedProductDetails => _selectedProductDetails;
  
  String get searchQuery => _searchQuery;
  String get activeFilter => _activeFilter;
  String get sortBy => _sortBy;

  // Setters for UI state
  void setSearchQuery(String val) {
    _searchQuery = val;
    notifyListeners();
  }

  void setActiveFilter(String val) {
    _activeFilter = val;
    notifyListeners();
  }

  void setSortBy(String val) {
    _sortBy = val;
    notifyListeners();
  }

  // Fetch paginated products
  Future<void> fetchProducts({bool refresh = false}) async {
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
        url = '/api/products/?page=1&page_size=15';
        if (_searchQuery.isNotEmpty) {
          url += '&search=${Uri.encodeComponent(_searchQuery)}';
        }
      }

      final response = await ApiService().get(url);
      if (response['success'] == true) {
        final data = response['data'] ?? {};
        final results = data['results'] as List<dynamic>? ?? [];
        final List<Product> fetched = results
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();

        if (refresh) {
          _products.clear();
        }
        _products.addAll(fetched);
        _nextPageUrl = data['next'] as String?;
        _hasMore = _nextPageUrl != null;
      } else {
        _errorMessage = response['message'] ?? 'Failed to load products';
      }
    } catch (e) {
      _errorMessage = 'Error loading products: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search products for autocomplete
  Future<void> searchProducts(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
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
        _hasMore = false;
      } else {
        _errorMessage = response['message'] ?? 'Failed to search products';
      }
    } catch (e) {
      _errorMessage = 'Error searching products: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch dashboard stats
  Future<void> fetchDashboardStats() async {
    try {
      final response = await ApiService().get('/api/products/dashboard/');
      if (response['success'] == true) {
        _dashboardStats = Map<String, dynamic>.from(response['data'] ?? {});
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching product dashboard stats: $e');
    }
  }

  // Fetch single product details
  Future<Product?> fetchProductDetails(String id) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/products/$id/');
      if (response['success'] == true) {
        final product = Product.fromJson(response['data'] as Map<String, dynamic>);
        _selectedProductDetails = product;
        
        final idx = _products.indexWhere((p) => p.id == id);
        if (idx >= 0) {
          _products[idx] = product;
        }
        return product;
      } else {
        _errorMessage = response['message'] ?? 'Failed to load product details';
      }
    } catch (e) {
      _errorMessage = 'Error loading product details: $e';
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
    return null;
  }

  // Create Product
  Future<Product?> createProduct(Product product) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final Map<String, dynamic> payload = {
        'name': product.name,
        'sku': product.sku,
        'barcode': product.barcode,
        'product_type': product.category == 'Services' || product.category == 'Consulting' ? 'service' : 'goods',
        'category_name': product.category,
        'selling_price': double.parse(product.sellingPrice.toStringAsFixed(2)),
        'purchase_price': double.parse(product.purchasePrice.toStringAsFixed(2)),
        'mrp': double.parse((product.sellingPrice * 1.1).toStringAsFixed(2)),
        'track_inventory': product.stock > 0,
        'opening_stock': product.stock,
        'reorder_level': product.minStock,
        'minimum_stock': product.minStock,
        'maximum_stock': 1000.0,
        'gst_tax_rate': product.gst,
      };

      final response = await ApiService().post('/api/products/', payload);
      if (response['success'] == true) {
        final newProduct = Product.fromJson(response['data'] as Map<String, dynamic>);
        _products.add(newProduct);
        return newProduct;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create product';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
          if (_fieldErrors.isNotEmpty) {
            final details = _fieldErrors.values.expand((element) => element).join(', ');
            if (details.isNotEmpty) {
              _errorMessage = details;
            }
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Error creating product: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return null;
  }

  // Update Product
  Future<Product?> updateProduct(String id, Product product) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final Map<String, dynamic> payload = {
        'name': product.name,
        'sku': product.sku,
        'barcode': product.barcode,
        'product_type': product.category == 'Services' || product.category == 'Consulting' ? 'service' : 'goods',
        'category_name': product.category,
        'selling_price': product.sellingPrice,
        'purchase_price': product.purchasePrice,
        'gst_tax_rate': product.gst,
        'track_inventory': product.stock > 0,
        'current_stock': product.stock,
        'reorder_level': product.minStock,
        'minimum_stock': product.minStock,
      };

      final response = await ApiService().put('/api/products/$id/', payload);
      if (response['success'] == true) {
        final updated = Product.fromJson(response['data'] as Map<String, dynamic>);
        final idx = _products.indexWhere((p) => p.id == id);
        if (idx >= 0) {
          _products[idx] = updated;
        }
        if (_selectedProductDetails?.id == id) {
          _selectedProductDetails = updated;
        }
        return updated;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update product';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
          if (_fieldErrors.isNotEmpty) {
            final details = _fieldErrors.values.expand((element) => element).join(', ');
            if (details.isNotEmpty) {
              _errorMessage = details;
            }
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Error updating product: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return null;
  }

  // Delete Product
  Future<bool> deleteProduct(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().delete('/api/products/$id/');
      if (response['success'] == true) {
        _products.removeWhere((p) => p.id == id);
        if (_selectedProductDetails?.id == id) {
          _selectedProductDetails = null;
        }
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete product';
      }
    } catch (e) {
      _errorMessage = 'Error deleting product: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return false;
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
