import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_states.dart';
import '../providers/product_provider.dart';
import 'product_detail_screen.dart';
import 'create_product_screen.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  String _searchQuery = '';
  String _activeFilter = 'All'; // 'All', 'Stock Available', 'Low Stock', 'Out of Stock', 'Services', 'Hardware', 'Software', 'Consulting'
  String _sortBy = 'Newest'; // 'Newest', 'Price Low-High', 'Price High-Low', 'Name'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      final nameMatch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final skuMatch = product.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      final brandMatch = product.brand.toLowerCase().contains(_searchQuery.toLowerCase());
      final searchMatch = nameMatch || skuMatch || brandMatch;

      if (!searchMatch) return false;

      // Filter types
      switch (_activeFilter) {
        case 'Stock Available':
          return product.stock > 0;
        case 'Low Stock':
          return product.stock <= product.minStock && product.stock > 0;
        case 'Out of Stock':
          return product.stock == 0;
        case 'Services':
        case 'Hardware':
        case 'Software':
        case 'Consulting':
          return product.category.toLowerCase() == _activeFilter.toLowerCase();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            onPressed: () => _navigateToAddProduct(context),
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
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
                      hintText: 'Search products, SKU code, brand...',
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
                  const SizedBox(height: 12),
                  // Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('All'),
                        _buildFilterChip('Stock Available'),
                        _buildFilterChip('Low Stock'),
                        _buildFilterChip('Out of Stock'),
                        _buildFilterChip('Services'),
                        _buildFilterChip('Hardware'),
                        _buildFilterChip('Software'),
                        _buildFilterChip('Consulting'),
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
                    'Showing ${filteredProducts.length} items',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Sorted: $_sortBy',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Products List
            Expanded(
              child: productProvider.isLoading && productProvider.products.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => productProvider.fetchProducts(refresh: true),
                      child: filteredProducts.isEmpty
                          ? EmptyState(
                              title: 'No Products Found',
                              description: 'Try adjusting your filters or register a new item in the catalog.',
                              icon: Icons.inventory_2_outlined,
                              actionLabel: 'Add Product',
                              onActionPressed: () => _navigateToAddProduct(context),
                            )
                          : ListView.builder(
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
                                  children: [
                                    // Image Category icon
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        product.category == 'Services' || product.category == 'Consulting'
                                            ? Icons.computer_rounded
                                            : Icons.inventory_2_rounded,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Name and SKU details
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
                                          const SizedBox(height: 2),
                                          Text(
                                            'SKU: ${product.sku} • Category: ${product.category}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontSize: 12,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          // Stock badge / text
                                          Row(
                                            children: [
                                              Text(
                                                'Stock: ${product.stock} Pcs',
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
                                                _buildStatusBadge('Out of Stock', AppColors.error),
                                              ] else if (isLowStock) ...[
                                                const SizedBox(width: 6),
                                                _buildStatusBadge('Low Stock', AppColors.warning),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Pricing
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          currencyFormat.format(product.sellingPrice),
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'GST: ${product.gst}%',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().fade(duration: 150.ms).slideY(begin: 0.05);
                      },
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final theme = Theme.of(context);
    final isSelected = _activeFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _activeFilter = label;
          });
        },
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        checkmarkColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
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

  Future<void> _navigateToAddProduct(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateProductScreen(),
      ),
    );
    // Refresh after returning from create/edit screen
    if (mounted) {
      context.read<ProductProvider>().fetchProducts(refresh: true);
    }
  }

  void _showSortBottomSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort Products By',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildSortOption('Newest', Icons.calendar_today_rounded),
              _buildSortOption('Price Low-High', Icons.arrow_upward_rounded),
              _buildSortOption('Price High-Low', Icons.arrow_downward_rounded),
              _buildSortOption('Name', Icons.sort_by_alpha_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String val, IconData icon) {
    final isSelected = _sortBy == val;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey),
      title: Text(
        val,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
      onTap: () {
        setState(() {
          _sortBy = val;
        });
        Navigator.pop(context);
      },
    );
  }
}
