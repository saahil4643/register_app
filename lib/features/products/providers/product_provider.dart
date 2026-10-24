import 'package:flutter/material.dart';
import '../models/product.dart';
import '../../../core/services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [];
  bool _isLoading = false;        // for list fetch operations
  bool _isSaving = false;         // for create / update / delete operations
  bool _isLoadingDetails = false; // for single product detail fetch
  String? _errorMessage;
  final Map<String, List<String>> _fieldErrors = {};
  Map<String, dynamic> _dashboardStats = {};
  
  Product? _selectedProductDetails;

  String _searchQuery = '';
  String _activeFilter = 'All';
  String _sortBy = 'Newest';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  
  bool _hasMore = false;
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
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _hasMore;

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

  // Fetch paginated products: GET /api/v1/products
  Future<void> fetchProducts({
    bool refresh = false,
    String? search,
    String? productType,
    String? categoryId,
    String? brandId,
    String? company,
    String? subcategory,
    String? status,
    bool? trackInventory,
    String? stockAvailability,
    String? ordering,
  }) async {
    if (_isLoading) return;
    if (refresh) {
      _nextPageUrl = null;
      _hasMore = true;
      _currentPage = 1;
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
        final queryParams = <String>['page=$_currentPage', 'page_size=15'];
        
        final effectiveSearch = search ?? _searchQuery;
        if (effectiveSearch.isNotEmpty) {
          queryParams.add('search=${Uri.encodeComponent(effectiveSearch)}');
        }

        if (productType != null && productType.isNotEmpty) {
          queryParams.add('product_type=$productType');
        }
        if (company != null && company.isNotEmpty) {
          queryParams.add('company=${Uri.encodeComponent(company)}');
        }
        if (categoryId != null && categoryId.isNotEmpty) {
          queryParams.add('category=$categoryId');
        }
        if (subcategory != null && subcategory.isNotEmpty) {
          queryParams.add('subcategory=${Uri.encodeComponent(subcategory)}');
        }
        if (brandId != null && brandId.isNotEmpty) {
          queryParams.add('brand=$brandId');
        }

        final effectiveStatus = status ?? (_activeFilter == 'Active' ? 'active' : (_activeFilter == 'Inactive' ? 'inactive' : null));
        if (effectiveStatus != null) {
          queryParams.add('status=$effectiveStatus');
        }

        if (trackInventory != null) {
          queryParams.add('track_inventory=$trackInventory');
        }

        final effectiveStock = stockAvailability ?? (
          _activeFilter == 'Stock Available' ? 'in_stock' :
          _activeFilter == 'Low Stock' ? 'low_stock' :
          _activeFilter == 'Out of Stock' ? 'out_of_stock' : null
        );
        if (effectiveStock != null) {
          queryParams.add('stock_availability=$effectiveStock');
        }

        final effectiveOrdering = ordering ?? (
          _sortBy == 'Price Low-High' ? 'selling_price' :
          _sortBy == 'Price High-Low' ? '-selling_price' :
          _sortBy == 'Name' ? 'name' : '-created_at'
        );
        queryParams.add('ordering=$effectiveOrdering');

        url = '/api/v1/products?${queryParams.join('&')}';
      }

      final response = await ApiService().get(url);
      if (response['success'] == true) {
        final rawData = response['data'];
        List<dynamic> results = [];

        if (rawData is Map) {
          results = rawData['results'] as List<dynamic>? ?? [];
          _nextPageUrl = rawData['next'] as String?;
          _hasMore = _nextPageUrl != null;
          _currentPage = rawData['page'] as int? ?? _currentPage;
          _totalPages = rawData['total_pages'] as int? ?? 1;
          _totalCount = rawData['count'] as int? ?? results.length;
        } else if (rawData is List) {
          results = rawData;
          _nextPageUrl = null;
          _hasMore = false;
          _totalCount = results.length;
        }

        final List<Product> fetched = results
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();

        if (refresh) {
          _products.clear();
        }
        _products.addAll(fetched);
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

  // Fast search products for autocomplete: GET /api/v1/products?search=...
  Future<void> searchProducts(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
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

  // Fetch single product details: GET /api/v1/products/{id}
  Future<Product?> fetchProductDetails(String id) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/v1/products/$id');
      if (response['success'] == true && response['data'] != null) {
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

  // Create Product: POST /api/v1/products
  Future<Product?> createProduct(Product product) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final Map<String, dynamic> payload = {
        'name': product.name,
        if (product.sku.isNotEmpty) 'sku': product.sku,
        if (product.barcode.isNotEmpty) 'barcode': product.barcode,
        'product_type': product.productType.isNotEmpty ? product.productType : 'goods',
        if (product.company.isNotEmpty) 'company': product.company,
        if (product.company.isNotEmpty) 'company_name': product.company,
        if (product.category.isNotEmpty) 'category': product.category,
        if (product.category.isNotEmpty) 'category_name': product.category,
        if (product.subcategory.isNotEmpty) 'subcategory': product.subcategory,
        if (product.subcategory.isNotEmpty) 'subcategory_name': product.subcategory,
        if (product.brand.isNotEmpty) 'brand': product.brand,
        'unit_of_measurement': product.unitOfMeasurement.isNotEmpty ? product.unitOfMeasurement : 'Pieces',
        'warehouse': product.warehouse.isNotEmpty ? product.warehouse : 'Main Warehouse',
        if (product.hsnSacCode.isNotEmpty) 'hsn_sac_code': product.hsnSacCode,
        'gst_tax_rate': product.gst,
        'selling_price': product.sellingPrice,
        'purchase_price': product.purchasePrice,
        'track_inventory': product.trackInventory,
        'opening_stock': product.openingStock > 0 ? product.openingStock : product.stock.toDouble(),
        'reorder_level': product.minStock,
        if (product.description.isNotEmpty) 'description': product.description,
      };

      final response = await ApiService().post('/api/v1/products', payload);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final newProduct = Product.fromJson(data);
        
        // Merge in any client fields if server returned partial
        final merged = product.copyWith(
          id: newProduct.id.isNotEmpty ? newProduct.id : product.id,
          sku: newProduct.sku.isNotEmpty ? newProduct.sku : product.sku,
          status: newProduct.status.isNotEmpty ? newProduct.status : product.status,
          company: newProduct.company.isNotEmpty ? newProduct.company : product.company,
          subcategory: newProduct.subcategory.isNotEmpty ? newProduct.subcategory : product.subcategory,
        );

        _products.insert(0, merged);
        return merged;
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

  // Update Product: PUT /api/v1/products/{id} or PATCH /api/v1/products/{id}
  Future<Product?> updateProduct(String id, Product product, {bool partial = false}) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final Map<String, dynamic> payload = {
        'name': product.name,
        if (product.sku.isNotEmpty) 'sku': product.sku,
        if (product.barcode.isNotEmpty) 'barcode': product.barcode,
        'product_type': product.productType,
        if (product.company.isNotEmpty) 'company': product.company,
        if (product.company.isNotEmpty) 'company_name': product.company,
        if (product.category.isNotEmpty) 'category': product.category,
        if (product.category.isNotEmpty) 'category_name': product.category,
        if (product.subcategory.isNotEmpty) 'subcategory': product.subcategory,
        if (product.subcategory.isNotEmpty) 'subcategory_name': product.subcategory,
        if (product.brand.isNotEmpty) 'brand': product.brand,
        'unit_of_measurement': product.unitOfMeasurement,
        'warehouse': product.warehouse,
        if (product.hsnSacCode.isNotEmpty) 'hsn_sac_code': product.hsnSacCode,
        'gst_tax_rate': product.gst,
        'selling_price': product.sellingPrice,
        'purchase_price': product.purchasePrice,
        'track_inventory': product.trackInventory,
        'current_stock': product.stock,
        'reorder_level': product.minStock,
        'status': product.status,
        if (product.description.isNotEmpty) 'description': product.description,
      };

      final response = partial
          ? await ApiService().patch('/api/v1/products/$id', payload)
          : await ApiService().put('/api/v1/products/$id', payload);

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final updated = data.isNotEmpty ? Product.fromJson(data) : product;
        
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

  // Delete Product (Soft delete): DELETE /api/v1/products/{id}
  Future<bool> deleteProduct(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().delete('/api/v1/products/$id');
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

  // Restore Soft-Deleted Product: POST /api/v1/products/{id}/restore
  Future<bool> restoreProduct(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/v1/products/$id/restore', {});
      if (response['success'] == true) {
        await fetchProducts(refresh: true);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to restore product';
      }
    } catch (e) {
      _errorMessage = 'Error restoring product: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Activate Single Product: POST /api/v1/products/{id}/activate
  Future<bool> activateProduct(String id) async {
    try {
      final response = await ApiService().post('/api/v1/products/$id/activate', {});
      if (response['success'] == true) {
        await fetchProductDetails(id);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to activate product';
      }
    } catch (e) {
      _errorMessage = 'Error activating product: $e';
    }
    notifyListeners();
    return false;
  }

  // Deactivate Single Product: POST /api/v1/products/{id}/deactivate
  Future<bool> deactivateProduct(String id) async {
    try {
      final response = await ApiService().post('/api/v1/products/$id/deactivate', {});
      if (response['success'] == true) {
        await fetchProductDetails(id);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to deactivate product';
      }
    } catch (e) {
      _errorMessage = 'Error deactivating product: $e';
    }
    notifyListeners();
    return false;
  }

  // Bulk Delete: POST /api/v1/products/bulk-delete
  Future<bool> bulkDelete(List<String> ids) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/v1/products/bulk-delete', {'ids': ids});
      if (response['success'] == true) {
        _products.removeWhere((p) => ids.contains(p.id));
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to perform bulk delete';
      }
    } catch (e) {
      _errorMessage = 'Error performing bulk delete: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return false;
  }

  // Bulk Activate: POST /api/v1/products/bulk-activate
  Future<bool> bulkActivate(List<String> ids) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/v1/products/bulk-activate', {'ids': ids});
      if (response['success'] == true) {
        await fetchProducts(refresh: true);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to perform bulk activate';
      }
    } catch (e) {
      _errorMessage = 'Error performing bulk activate: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return false;
  }

  // Bulk Deactivate: POST /api/v1/products/bulk-deactivate
  Future<bool> bulkDeactivate(List<String> ids) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/v1/products/bulk-deactivate', {'ids': ids});
      if (response['success'] == true) {
        await fetchProducts(refresh: true);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to perform bulk deactivate';
      }
    } catch (e) {
      _errorMessage = 'Error performing bulk deactivate: $e';
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
