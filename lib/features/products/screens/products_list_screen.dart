import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_states.dart';
import '../models/product.dart';
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
  String _activeTypeFilter = 'All'; // 'All', 'Goods', 'Services', 'Low Stock'
  String _selectedCategory = 'All';
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

    // Extract unique categories from actual products
    final allCategories = <String>{'All'};
    for (final p in productProvider.products) {
      if (p.category.isNotEmpty && p.category != 'General') {
        allCategories.add(p.category);
      }
    }
    final categoryList = allCategories.toList();

    // 1. Filter products
    final filteredProducts = productProvider.products.where((product) {
      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = product.name.toLowerCase().contains(q);
        final skuMatch = product.sku.toLowerCase().contains(q);
        final catMatch = product.category.toLowerCase().contains(q);
        final hsnMatch = product.hsnSacCode.toLowerCase().contains(q);
        final descMatch = product.description.toLowerCase().contains(q);
        if (!(nameMatch || skuMatch || catMatch || hsnMatch || descMatch)) {
          return false;
        }
      }

      // Type Filter
      final isService = product.productType.toLowerCase() == 'service';
      switch (_activeTypeFilter) {
        case 'Goods':
          if (isService) return false;
          break;
        case 'Services':
          if (!isService) return false;
          break;
        case 'Low Stock':
          if (isService) return false;
          if (product.stock > product.minStock) return false;
          break;
        default:
          break;
      }

      // Category Filter
      if (_selectedCategory != 'All') {
        if (product.category.toLowerCase() != _selectedCategory.toLowerCase()) {
          return false;
        }
      }

      return true;
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
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Items & Inventory',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Items',
            onPressed: _showSortBottomSheet,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE5E7EB), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Search & Filter header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by item name, SKU, HSN, category...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
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

                      // Filter Row: Status Chips & Category Filter
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildTypeFilterChip('All Items', 'All'),
                                  _buildTypeFilterChip('Goods', 'Goods'),
                                  _buildTypeFilterChip('Services', 'Services'),
                                  _buildTypeFilterChip('Low Stock', 'Low Stock'),
                                ],
                              ),
                            ),
                          ),
                          if (categoryList.length > 2) ...[
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              initialValue: _selectedCategory,
                              onSelected: (cat) {
                                setState(() => _selectedCategory = cat);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedCategory == 'All' ? 'Category' : _selectedCategory,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                              itemBuilder: (ctx) => categoryList
                                  .map((c) => PopupMenuItem(value: c, child: Text(c)))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Count & Sorting Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredProducts.length} ${filteredProducts.length == 1 ? 'item' : 'items'} found',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                      InkWell(
                        onTap: _showSortBottomSheet,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          child: Row(
                            children: [
                              Icon(Icons.sort_rounded, size: 14, color: AppColors.lightPrimary),
                              const SizedBox(width: 4),
                              Text(
                                'Sort: $_sortBy',
                                style: TextStyle(
                                  color: AppColors.lightPrimary,
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
                const SizedBox(height: 6),

                // Products List
                Expanded(
                  child: productProvider.isLoading && productProvider.products.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => context.read<ProductProvider>().fetchProducts(refresh: true),
                          child: filteredProducts.isEmpty
                              ? EmptyState(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'No Items Found',
                                  description: 'Try adjusting your search filters or add a new item to get started.',
                                  actionLabel: 'Add New Item',
                                  onActionPressed: () => _navigateToAddProduct(context),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 80.0),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = filteredProducts[index];
                                    return _buildProductCard(context, product, currencyFormat, isDark);
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: filteredProducts.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _navigateToAddProduct(context),
              backgroundColor: AppColors.lightPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Item', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _buildTypeFilterChip(String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _activeTypeFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _activeTypeFilter = value);
          }
        },
        selectedColor: theme.colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
            width: 1,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    final isService = product.productType.toLowerCase() == 'service';
    final isLowStock = !isService && product.stock <= product.minStock && product.stock > 0;
    final isOutOfStock = !isService && product.stock == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
              // Icon Indicator
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isService
                      ? const Color(0xFFF3E8FF) // soft purple
                      : const Color(0xFFEEF2FF), // soft indigo
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isService ? Icons.design_services_outlined : Icons.inventory_2_outlined,
                  color: isService ? const Color(0xFF7C3AED) : const Color(0xFF4F46E5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Badges: SKU & Category
                    Row(
                      children: [
                        if (product.sku.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.sku,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (product.category.isNotEmpty && product.category != 'General') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.category,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (product.hsnSacCode.isNotEmpty) ...[
                          Text(
                            'HSN: ${product.hsnSacCode}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Stock or Service status tag
                    if (isService)
                      const Text(
                        'Service • No inventory required',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      )
                    else
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
                                      : const Color(0xFF475569),
                            ),
                          ),
                          if (isOutOfStock) ...[
                            const SizedBox(width: 6),
                            _buildStatusTag('OUT OF STOCK', AppColors.error),
                          ] else if (isLowStock) ...[
                            const SizedBox(width: 6),
                            _buildStatusTag('LOW STOCK', AppColors.warning),
                          ],
                        ],
                      ),
                  ],
                ),
              ),

              // Price & Tax
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(product.sellingPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.gst > 0 ? '+ ${product.gst}% GST' : 'Exempt',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
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
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sort Items By',
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
