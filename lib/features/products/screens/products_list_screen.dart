import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_states.dart';
import '../providers/product_provider.dart';
import '../models/product_hierarchy.dart';
import 'product_detail_screen.dart';
import 'create_product_screen.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  String _searchQuery = '';
  String _activeFilter = 'All'; // 'All', 'Stock Available', 'Low Stock', 'Out of Stock'
  String _selectedCompany = 'All'; // 'All', 'Wipro', 'Cadbury', 'Fena', etc.
  String _selectedCategory = 'All'; // 'All', 'Santoor', 'Dairy Milk', etc.
  String _sortBy = 'Newest'; // 'Newest', 'Price Low-High', 'Price High-Low', 'Name'
  final TextEditingController _searchController = TextEditingController();
  final ProductHierarchyService _hierarchyService = ProductHierarchyService();

  @override
  void initState() {
    super.initState();
    _hierarchyService.init().then((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productProvider = context.watch<ProductProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // 1. Filter products
    final filteredProducts = productProvider.products.where((product) {
      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = product.name.toLowerCase().contains(q);
        final skuMatch = product.sku.toLowerCase().contains(q);
        final compMatch = product.company.toLowerCase().contains(q) || product.brand.toLowerCase().contains(q);
        final catMatch = product.category.toLowerCase().contains(q);
        final subMatch = product.subcategory.toLowerCase().contains(q);
        final barcodeMatch = product.barcode.toLowerCase().contains(q);
        if (!(nameMatch || skuMatch || compMatch || catMatch || subMatch || barcodeMatch)) {
          return false;
        }
      }

      // Company Filter
      if (_selectedCompany != 'All') {
        final comp = product.company.toLowerCase();
        final brand = product.brand.toLowerCase();
        final target = _selectedCompany.toLowerCase();
        if (comp != target && brand != target) {
          return false;
        }
      }

      // Category Filter
      if (_selectedCategory != 'All') {
        if (product.category.toLowerCase() != _selectedCategory.toLowerCase()) {
          return false;
        }
      }

      // Stock Status Filter
      switch (_activeFilter) {
        case 'Stock Available':
          return product.stock > 0;
        case 'Low Stock':
          return product.stock <= product.minStock && product.stock > 0;
        case 'Out of Stock':
          return product.stock == 0;
        default:
          return true;
      }
    }).toList();

    // 2. Sort products
    filteredProducts.sort((a, b) {
      switch (_sortBy) {
        case 'Price Low-High':
          return a.sellingPrice.compareTo(b.sellingPrice);
        case 'Price High-Low':
          return b.sellingPrice.compareTo(a.sellingPrice);
        case 'Name':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'Newest':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    final companies = ['All', ..._hierarchyService.getCompanyNames()];
    final categories = _selectedCompany == 'All'
        ? ['All']
        : ['All', ..._hierarchyService.getCategoryNames(_selectedCompany)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'Add Product',
            onPressed: () => _navigateToAddProduct(context),
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Products',
            onPressed: _showSortBottomSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search product, company, category, subcategory, SKU...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Level 1: Company Filter Chips
                  SizedBox(
                    height: 34,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: companies.length,
                      itemBuilder: (context, idx) {
                        final comp = companies[idx];
                        final isSelected = _selectedCompany == comp;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            avatar: comp == 'All'
                                ? const Icon(Icons.apps_rounded, size: 14)
                                : const Icon(Icons.business_rounded, size: 14),
                            label: Text(comp),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCompany = comp;
                                _selectedCategory = 'All';
                              });
                            },
                            selectedColor: theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
                            ),
                            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: 1,
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      },
                    ),
                  ),

                  // Level 2: Category Filter Chips (if specific company chosen)
                  if (_selectedCompany != 'All' && categories.length > 1) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 30,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, idx) {
                          final cat = categories[idx];
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                }
                              },
                              selectedColor: theme.colorScheme.secondaryContainer,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.onSecondaryContainer
                                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                              backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(
                                  color: isSelected
                                      ? theme.colorScheme.secondary.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Stock Status Quick Filters
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildStockFilterChip('All Status'),
                        _buildStockFilterChip('Stock Available'),
                        _buildStockFilterChip('Low Stock'),
                        _buildStockFilterChip('Out of Stock'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List Count & Sorting Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredProducts.length} ${filteredProducts.length == 1 ? 'Product' : 'Products'} found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  InkWell(
                    onTap: _showSortBottomSheet,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.sort_rounded, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            _sortBy,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Products Catalog List
            Expanded(
              child: productProvider.isLoading && filteredProducts.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty
                      ? Center(
                          child: EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'No Products Found',
                            description: 'Try adjusting your hierarchy filter or search term.',
                            actionLabel: 'Add Product',
                            onActionPressed: () => _navigateToAddProduct(context),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => context.read<ProductProvider>().fetchProducts(refresh: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 80.0),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final isLowStock = product.stock <= product.minStock && product.stock > 0;
                              final isOutOfStock = product.stock == 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailScreen(productId: product.id),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Product Icon
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.inventory_2_rounded,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 14),

                                          // Name, Hierarchy, and SKU details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),

                                                // Hierarchy Breadcrumb Tag: [Company › Category › Subcategory]
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '${product.company} › ${product.category} › ${product.subcategory}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 5),

                                                Text(
                                                  'SKU: ${product.sku.isNotEmpty ? product.sku : "N/A"}',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    fontSize: 11,
                                                    fontFamily: 'monospace',
                                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),

                                                // Stock badge / text
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Stock: ${product.stock} ${product.unitAbbreviation}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: isOutOfStock
                                                            ? AppColors.error
                                                            : isLowStock
                                                                ? AppColors.warning
                                                                : isDark
                                                                    ? AppColors.darkTextSecondary
                                                                    : AppColors.lightTextSecondary,
                                                      ),
                                                    ),
                                                    if (isOutOfStock) ...[
                                                      const SizedBox(width: 6),
                                                      _buildBadge('OUT OF STOCK', AppColors.error),
                                                    ] else if (isLowStock) ...[
                                                      const SizedBox(width: 6),
                                                      _buildBadge('LOW STOCK', AppColors.warning),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Price
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  currencyFormat.format(product.sellingPrice),
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'GST ${product.gst}%',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    fontSize: 10,
                                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddProduct(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Product'),
      ),
    );
  }

  Widget _buildStockFilterChip(String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = (_activeFilter == 'All' && label == 'All Status') || _activeFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _activeFilter = label == 'All Status' ? 'All' : label;
          });
        },
        selectedColor: theme.colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _navigateToAddProduct(BuildContext ctx) async {
    await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (context) => const CreateProductScreen(),
      ),
    );
    if (!mounted) return;
    context.read<ProductProvider>().fetchProducts(refresh: true);
  }

  void _showSortBottomSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sort Products By',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSortOption(bottomSheetContext, 'Newest', Icons.access_time_rounded),
                _buildSortOption(bottomSheetContext, 'Name', Icons.sort_by_alpha_rounded),
                _buildSortOption(bottomSheetContext, 'Price Low-High', Icons.arrow_upward_rounded),
                _buildSortOption(bottomSheetContext, 'Price High-Low', Icons.arrow_downward_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext ctx, String label, IconData icon) {
    final isSelected = _sortBy == label;
    final theme = Theme.of(ctx);

    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_rounded, color: theme.colorScheme.primary) : null,
      onTap: () {
        setState(() {
          _sortBy = label;
        });
        Navigator.pop(ctx);
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}
