import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/invoice_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/models/product.dart';
import '../../products/models/product_hierarchy.dart';

class ProductPickerScreen extends StatefulWidget {
  const ProductPickerScreen({super.key});

  @override
  State<ProductPickerScreen> createState() => _ProductPickerScreenState();
}

class _ProductPickerScreenState extends State<ProductPickerScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Hierarchy filter states
  final ProductHierarchyService _hierarchyService = ProductHierarchyService();
  String _selectedCompany = 'All';
  String _selectedCategory = 'All';
  String _selectedSubcategory = 'All';

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
    _debounce?.cancel();
    super.dispose();
  }

  void _resetHierarchyFilter() {
    setState(() {
      _selectedCompany = 'All';
      _selectedCategory = 'All';
      _selectedSubcategory = 'All';
    });
  }

  void _showQuickAddProductDialog(String initialName) {
    final productProvider = context.read<ProductProvider>();
    final invoiceProvider = context.read<InvoiceProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final companies = _hierarchyService.getCompanyNames();
    String dialogCompany = _selectedCompany != 'All' ? _selectedCompany : (companies.isNotEmpty ? companies.first : 'Wipro');
    var categories = _hierarchyService.getCategoryNames(dialogCompany);
    String dialogCategory = (_selectedCategory != 'All' && categories.contains(_selectedCategory))
        ? _selectedCategory
        : (categories.isNotEmpty ? categories.first : 'General');
    var subcategories = _hierarchyService.getSubcategoryNames(dialogCompany, dialogCategory);
    String dialogSubcategory = (_selectedSubcategory != 'All' && subcategories.contains(_selectedSubcategory))
        ? _selectedSubcategory
        : (subcategories.isNotEmpty ? subcategories.first : 'General');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        final formKey = GlobalKey<FormState>();
        final nameController = TextEditingController(text: initialName);
        final priceController = TextEditingController();
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hierarchy Selectors
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Company / Brand *',
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                        value: dialogCompany,
                        items: companies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              dialogCompany = val;
                              categories = _hierarchyService.getCategoryNames(dialogCompany);
                              dialogCategory = categories.isNotEmpty ? categories.first : 'General';
                              subcategories = _hierarchyService.getSubcategoryNames(dialogCompany, dialogCategory);
                              dialogSubcategory = subcategories.isNotEmpty ? subcategories.first : 'General';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        value: categories.contains(dialogCategory) ? dialogCategory : (categories.isNotEmpty ? categories.first : null),
                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              dialogCategory = val;
                              subcategories = _hierarchyService.getSubcategoryNames(dialogCompany, dialogCategory);
                              dialogSubcategory = subcategories.isNotEmpty ? subcategories.first : 'General';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Subcategory *',
                          prefixIcon: Icon(Icons.subdirectory_arrow_right_rounded),
                        ),
                        value: subcategories.contains(dialogSubcategory) ? dialogSubcategory : (subcategories.isNotEmpty ? subcategories.first : null),
                        items: subcategories.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              dialogSubcategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          prefixIcon: Icon(Icons.label_rounded),
                          hintText: 'e.g. Santoor Soap 100g',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter product name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price (₹) *',
                          prefixIcon: Icon(Icons.sell_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter price';
                          final parsed = double.tryParse(val);
                          if (parsed == null) return 'Invalid price';
                          if (parsed < 0) return 'Price cannot be negative';
                          return null;
                        },
                      ),
                    ],
                  ),
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
                          setDialogState(() {
                            isSubmitting = true;
                          });

                          final price = double.tryParse(priceController.text) ?? 0.0;

                          final product = Product(
                            id: '',
                            name: nameController.text.trim(),
                            sku: '',
                            barcode: '',
                            company: dialogCompany,
                            category: dialogCategory,
                            subcategory: dialogSubcategory,
                            brand: dialogCompany,
                            purchasePrice: price * 0.75,
                            sellingPrice: price,
                            stock: 50,
                            minStock: 5,
                            gst: 18.0,
                            createdAt: DateTime.now(),
                          );

                          final newProduct = await productProvider.createProduct(product);

                          if (dialogCtx.mounted) {
                            if (newProduct != null) {
                              invoiceProvider.addProduct(newProduct);
                              Navigator.pop(dialogCtx);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Product "${newProduct.name}" created and added to invoice!'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              setDialogState(() {
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

  void _showHierarchyBrowserSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final companies = _hierarchyService.companies;

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Browse Product Hierarchy',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            _resetHierarchyFilter();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Reset All'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: companies.length,
                      itemBuilder: (context, cIdx) {
                        final comp = companies[cIdx];
                        return ExpansionTile(
                          leading: const CircleAvatar(
                            radius: 16,
                            child: Icon(Icons.business_rounded, size: 16),
                          ),
                          title: Text(
                            comp.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${comp.categories.length} categories'),
                          trailing: TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCompany = comp.name;
                                _selectedCategory = 'All';
                                _selectedSubcategory = 'All';
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text('Select Company', style: TextStyle(fontSize: 12)),
                          ),
                          children: comp.categories.map((cat) {
                            return ExpansionTile(
                              tilePadding: const EdgeInsets.only(left: 36, right: 16),
                              leading: const Icon(Icons.category_rounded, size: 18),
                              title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${cat.subcategories.length} subcategories'),
                              trailing: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedCompany = comp.name;
                                    _selectedCategory = cat.name;
                                    _selectedSubcategory = 'All';
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Select', style: TextStyle(fontSize: 12)),
                              ),
                              children: cat.subcategories.map((sub) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.only(left: 64, right: 16),
                                  leading: const Icon(Icons.subdirectory_arrow_right_rounded, size: 16),
                                  title: Text(sub.name),
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                                  onTap: () {
                                    setState(() {
                                      _selectedCompany = comp.name;
                                      _selectedCategory = cat.name;
                                      _selectedSubcategory = sub.name;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                );
                              }).toList(),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
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

    // Filter products matching hierarchical selection and search query
    final filteredProducts = productProvider.products.where((prod) {
      // 1. Search Query Match
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = prod.name.toLowerCase().contains(q);
        final skuMatch = prod.sku.toLowerCase().contains(q);
        final compMatch = prod.company.toLowerCase().contains(q) || prod.brand.toLowerCase().contains(q);
        final catMatch = prod.category.toLowerCase().contains(q);
        final subMatch = prod.subcategory.toLowerCase().contains(q);
        final barcodeMatch = prod.barcode.toLowerCase().contains(q);
        if (!(nameMatch || skuMatch || compMatch || catMatch || subMatch || barcodeMatch)) {
          return false;
        }
      }

      // 2. Company Match
      if (_selectedCompany != 'All') {
        final comp = prod.company.toLowerCase();
        final brand = prod.brand.toLowerCase();
        final targetComp = _selectedCompany.toLowerCase();
        if (comp != targetComp && brand != targetComp) {
          return false;
        }
      }

      // 3. Category Match
      if (_selectedCategory != 'All') {
        if (prod.category.toLowerCase() != _selectedCategory.toLowerCase()) {
          return false;
        }
      }

      // 4. Subcategory Match
      if (_selectedSubcategory != 'All') {
        if (prod.subcategory.toLowerCase() != _selectedSubcategory.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();

    // Map selected items by product ID for instant quantity lookup
    final selectedItemsMap = {
      for (var item in provider.selectedItems) item.product.id: item
    };

    final hasActiveFilter = _selectedCompany != 'All' || _selectedCategory != 'All' || _selectedSubcategory != 'All';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: 'Browse Hierarchy Tree',
            onPressed: _showHierarchyBrowserSheet,
          ),
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
      bottomNavigationBar: provider.selectedItems.isNotEmpty
          ? _buildStickyBottomBar(theme, isDark, provider, currencyFormat)
          : null,
      body: Column(
        children: [
          // Search Field + Hierarchy browser button
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
                                context.read<ProductProvider>().searchProducts('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.account_tree_rounded),
                  tooltip: 'Hierarchy Tree Browser',
                  onPressed: _showHierarchyBrowserSheet,
                ),
              ],
            ),
          ),

          // Active Breadcrumb / Filter Trail
          if (hasActiveFilter)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtered: ${_selectedCompany != "All" ? _selectedCompany : "All Companies"} '
                      '${_selectedCategory != "All" ? "› $_selectedCategory" : ""} '
                      '${_selectedSubcategory != "All" ? "› $_selectedSubcategory" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _resetHierarchyFilter,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Level 1: Companies Chip Row
          _buildCompanyChips(theme, isDark),

          // Level 2: Categories Chip Row (cascades from selected company)
          _buildCategoryChips(theme, isDark),

          // Level 3: Subcategories Chip Row (cascades from selected category)
          if (_selectedCategory != 'All')
            _buildSubcategoryChips(theme, isDark),

          const SizedBox(height: 4),

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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasActiveFilter
                                    ? 'No products match the selected hierarchy filter.'
                                    : 'Try changing your search term or add a new product.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showQuickAddProductDialog(_searchQuery),
                                icon: const Icon(Icons.add_shopping_cart_rounded),
                                label: Text(_searchQuery.isNotEmpty
                                    ? 'Quick Add "$_searchQuery"'
                                    : 'Quick Add Product Here'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                        itemCount: filteredProducts.length + (_searchQuery.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_searchQuery.isNotEmpty && index == 0) {
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showQuickAddProductDialog(_searchQuery),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
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
                                              'Quickly create as a new product in hierarchy',
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
                            margin: const EdgeInsets.only(bottom: 10),
                            color: isDark ? theme.colorScheme.surface : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isAdded
                                    ? theme.colorScheme.primary
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: isAdded ? 1.8 : 1.2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Product Name
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
                                        const SizedBox(height: 5),

                                        // Hierarchy Tag: [Company › Category › Subcategory]
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
                                        const SizedBox(height: 6),

                                        // SKU + Stock Info
                                        Row(
                                          children: [
                                            if (product.sku.isNotEmpty) ...[
                                              Text(
                                                product.sku,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  fontFamily: 'monospace',
                                                  fontSize: 11,
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '•',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            Text(
                                              'Stock: ${product.stock} ${product.unitAbbreviation}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontSize: 11,
                                                color: product.stock <= product.minStock
                                                    ? AppColors.error
                                                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                                fontWeight: product.stock <= product.minStock
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),

                                        // Selling Price
                                        Text(
                                          currencyFormat.format(product.sellingPrice),
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Add / Qty controls
                                  AnimatedCrossFade(
                                    duration: const Duration(milliseconds: 200),
                                    crossFadeState: isAdded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                    firstChild: ElevatedButton.icon(
                                      onPressed: () {
                                        provider.addProduct(product);
                                      },
                                      icon: const Icon(Icons.add_rounded, size: 16),
                                      label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(72, 38),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        backgroundColor: theme.colorScheme.primaryContainer,
                                        foregroundColor: theme.colorScheme.primary,
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
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: theme.colorScheme.primary,
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
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Level 1: Companies Chip Row
  Widget _buildCompanyChips(ThemeData theme, bool isDark) {
    final companies = ['All', ..._hierarchyService.getCompanyNames()];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: companies.length,
        itemBuilder: (context, index) {
          final comp = companies[index];
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
                  _selectedSubcategory = 'All';
                });
              },
              selectedColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
    );
  }

  // Level 2: Categories Chip Row
  Widget _buildCategoryChips(ThemeData theme, bool isDark) {
    List<String> categories;
    if (_selectedCompany == 'All') {
      final allCats = <String>{};
      for (final comp in _hierarchyService.companies) {
        for (final cat in comp.categories) {
          allCats.add(cat.name);
        }
      }
      categories = ['All', ...allCats];
    } else {
      categories = ['All', ..._hierarchyService.getCategoryNames(_selectedCompany)];
    }

    return Container(
      height: 34,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
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
                    _selectedSubcategory = 'All';
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
                borderRadius: BorderRadius.circular(8),
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
    );
  }

  // Level 3: Subcategories Chip Row
  Widget _buildSubcategoryChips(ThemeData theme, bool isDark) {
    List<String> subcategories;
    if (_selectedCompany != 'All') {
      subcategories = ['All', ..._hierarchyService.getSubcategoryNames(_selectedCompany, _selectedCategory)];
    } else {
      final allSubs = <String>{};
      for (final comp in _hierarchyService.companies) {
        for (final cat in comp.categories) {
          if (cat.name.toLowerCase() == _selectedCategory.toLowerCase()) {
            for (final sub in cat.subcategories) {
              allSubs.add(sub.name);
            }
          }
        }
      }
      subcategories = ['All', ...allSubs];
    }

    if (subcategories.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final sub = subcategories[index];
          final isSelected = _selectedSubcategory == sub;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(sub),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedSubcategory = sub;
                  });
                }
              },
              selectedColor: theme.colorScheme.tertiaryContainer,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onTertiaryContainer
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.tertiary.withValues(alpha: 0.5)
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
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
}
