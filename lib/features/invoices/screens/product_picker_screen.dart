import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/invoice_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/models/product.dart';

import 'dart:async';

class ProductPickerScreen extends StatefulWidget {
  const ProductPickerScreen({super.key});

  @override
  State<ProductPickerScreen> createState() => _ProductPickerScreenState();
}

class _ProductPickerScreenState extends State<ProductPickerScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().searchProducts('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _showQuickAddProductDialog(String initialName) {
    final productProvider = context.read<ProductProvider>();
    final invoiceProvider = context.read<InvoiceProvider>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        final formKey = GlobalKey<FormState>();
        final nameController = TextEditingController(text: initialName);
        final priceController = TextEditingController();
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.add_shopping_cart_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Quick Add Product'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        prefixIcon: Icon(Icons.label_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter product name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹) *',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter price';
                        final parsed = double.tryParse(val);
                        if (parsed == null) return 'Invalid price';
                        if (parsed < 0) return 'Price cannot be negative';
                        final parts = val.trim().split('.');
                        if (parts[0].length > 9) {
                          return 'Price cannot exceed 9 digits';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() {
                            isSubmitting = true;
                          });

                          final price = double.tryParse(priceController.text) ?? 0.0;

                          final product = Product(
                            id: '',
                            name: nameController.text.trim(),
                            sku: '',
                            barcode: '',
                            category: _selectedCategory == 'All' ? 'Services' : _selectedCategory,
                            brand: 'Generic',
                            purchasePrice: price * 0.7,
                            sellingPrice: price,
                            stock: 10,
                            minStock: 5,
                            gst: 18.0,
                            createdAt: DateTime.now(),
                          );

                          final newProduct = await productProvider.createProduct(product);

                          if (dialogCtx.mounted) {
                            if (newProduct != null) {
                              invoiceProvider.addProduct(newProduct);
                              Navigator.pop(dialogCtx); // Close Dialog
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Product "${newProduct.name}" created and added to invoice!'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              setState(() {
                                isSubmitting = false;
                              });
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(productProvider.errorMessage ?? 'Failed to create product'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add & Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<InvoiceProvider>();
    final productProvider = context.watch<ProductProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Filter products
    final filteredProducts = productProvider.products.where((prod) {
      final matchCategory = _selectedCategory == 'All' || prod.category == _selectedCategory;
      return matchCategory;
    }).toList();

    // Map selected items by product ID for quick access
    final selectedItemsMap = {
      for (var item in provider.selectedItems) item.product.id: item
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Products & Services'),
        actions: [
          // Clear selection button if items are selected
          if (provider.selectedItems.isNotEmpty)
            TextButton(
              onPressed: () {
                for (var item in List.from(provider.selectedItems)) {
                  provider.removeProduct(item.product.id);
                }
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        context.read<ProductProvider>().searchProducts(val);
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search SKU or name...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                context.read<ProductProvider>().searchProducts('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Categories Tabs
          _buildCategoryTabs(theme, isDark),

          // Products List
          Expanded(
            child: productProvider.isLoading && filteredProducts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Products Found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try changing your category or search term.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showQuickAddProductDialog(_searchQuery),
                              icon: const Icon(Icons.add_shopping_cart_rounded),
                              label: Text('Quick Add "$_searchQuery"'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                    itemCount: filteredProducts.length + (_searchQuery.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show Quick Add Card at the top of list when searching
                      if (_searchQuery.isNotEmpty && index == 0) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showQuickAddProductDialog(_searchQuery),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                                    child: Icon(
                                      Icons.add_shopping_cart_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Add "$_searchQuery"',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Quickly create as a new product',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final productIndex = _searchQuery.isNotEmpty ? index - 1 : index;
                      final product = filteredProducts[productIndex];
                      final selectedItem = selectedItemsMap[product.id];
                      final quantity = selectedItem?.quantity ?? 0;
                      final isAdded = quantity > 0;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isDark ? theme.colorScheme.surface : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Product details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          product.sku,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                                          ),
                                        ),
                                        Text(
                                          'Stock: ${product.stock}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                            color: product.stock < 10
                                                ? AppColors.error
                                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                            fontWeight: product.stock < 10 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor(product.category).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            product.category,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: _getCategoryColor(product.category),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      currencyFormat.format(product.price),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // POS Add / Qty controls
                              AnimatedCrossFade(
                                firstChild: ElevatedButton(
                                  onPressed: () {
                                    provider.addProduct(product);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(64, 36),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    foregroundColor: theme.colorScheme.primary,
                                  ),
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                secondChild: Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkBorder : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          provider.updateItemQty(product.id, quantity - 1);
                                        },
                                        icon: const Icon(Icons.remove_rounded, size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        color: theme.colorScheme.primary,
                                      ),
                                      Text(
                                        '$quantity',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          provider.updateItemQty(product.id, quantity + 1);
                                        },
                                        icon: const Icon(Icons.add_rounded, size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        color: theme.colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                                crossFadeState: isAdded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 150),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Sticky Bottom Summary Bar
          if (provider.selectedItems.isNotEmpty)
            _buildStickyBottomBar(theme, isDark, provider, currencyFormat),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(ThemeData theme, bool isDark) {
    final categories = ['All', 'Services', 'Hardware', 'Software', 'Consulting'];
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
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
              selectedColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.5)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 1,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickyBottomBar(
    ThemeData theme,
    bool isDark,
    InvoiceProvider provider,
    NumberFormat currencyFormat,
  ) {
    final itemCount = provider.selectedItems.fold<int>(0, (sum, item) => sum + item.quantity);
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currencyFormat.format(provider.grandTotal),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Services':
        return Icons.design_services_rounded;
      case 'Hardware':
        return Icons.computer_rounded;
      case 'Software':
        return Icons.code_rounded;
      case 'Consulting':
        return Icons.people_outline_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Services':
        return const Color(0xFF6D28D9); // Purple
      case 'Hardware':
        return const Color(0xFF3B82F6); // Blue
      case 'Software':
        return const Color(0xFF10B981); // Green
      case 'Consulting':
        return const Color(0xFFF59E0B); // Orange
      default:
        return Colors.grey;
    }
  }
}
