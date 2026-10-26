import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/invoice_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/models/product.dart';

class ProductPickerScreen extends StatefulWidget {
  const ProductPickerScreen({super.key});

  @override
  State<ProductPickerScreen> createState() => _ProductPickerScreenState();
}

class _ProductPickerScreenState extends State<ProductPickerScreen> {
  String _searchQuery = '';
  String _filterType = 'All'; // 'All', 'Goods', 'Services', 'In Stock'
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

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
    _debounce?.cancel();
    super.dispose();
  }

  void _showQuickAddItemDialog(String initialName) {
    final productProvider = context.read<ProductProvider>();
    final invoiceProvider = context.read<InvoiceProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: initialName);
    final priceCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    String itemType = 'goods';
    double gstRate = 18.0;
    String unit = 'Pcs';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.add_box_outlined, color: AppColors.lightPrimary),
                  SizedBox(width: 8),
                  Text('Quick Add Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Type selector
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Goods'),
                                selected: itemType == 'goods',
                                onSelected: (sel) {
                                  if (sel) setDialogState(() => itemType = 'goods');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Service'),
                                selected: itemType == 'service',
                                onSelected: (sel) {
                                  if (sel) setDialogState(() => itemType = 'service');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Item / Service Name *',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: priceCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Selling Price *',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Enter price';
                                  if (double.tryParse(val) == null) return 'Invalid price';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<double>(
                                initialValue: gstRate,
                                decoration: const InputDecoration(
                                  labelText: 'GST %',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(value: 0.0, child: Text('0%')),
                                  DropdownMenuItem(value: 5.0, child: Text('5%')),
                                  DropdownMenuItem(value: 12.0, child: Text('12%')),
                                  DropdownMenuItem(value: 18.0, child: Text('18%')),
                                  DropdownMenuItem(value: 28.0, child: Text('28%')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setDialogState(() => gstRate = v);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: skuCtrl,
                          decoration: const InputDecoration(
                            labelText: 'SKU / Code (Optional)',
                            hintText: 'e.g. ITM-001',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
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
                          setDialogState(() => isSubmitting = true);

                          final price = double.tryParse(priceCtrl.text) ?? 0.0;
                          final sku = skuCtrl.text.trim().isNotEmpty
                              ? skuCtrl.text.trim()
                              : 'ITM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

                          final product = Product(
                            id: 'PROD-${DateTime.now().millisecondsSinceEpoch}',
                            name: nameCtrl.text.trim(),
                            sku: sku,
                            barcode: '',
                            productType: itemType,
                            company: 'General',
                            category: itemType == 'service' ? 'Services' : 'General',
                            subcategory: 'General',
                            brand: 'General',
                            unitOfMeasurement: unit,
                            purchasePrice: price * 0.70,
                            sellingPrice: price,
                            stock: itemType == 'goods' ? 25 : 0,
                            minStock: 5,
                            gst: gstRate,
                            trackInventory: itemType == 'goods',
                            createdAt: DateTime.now(),
                          );

                          final newProduct = await productProvider.createProduct(product);

                          if (dialogCtx.mounted) {
                            if (newProduct != null) {
                              invoiceProvider.addProduct(newProduct);
                              Navigator.pop(dialogCtx);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Item "${newProduct.name}" added to invoice'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              setDialogState(() => isSubmitting = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(productProvider.errorMessage ?? 'Failed to create item'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save & Select'),
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
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = prod.name.toLowerCase().contains(q);
        final skuMatch = prod.sku.toLowerCase().contains(q);
        final catMatch = prod.category.toLowerCase().contains(q);
        final hsnMatch = prod.hsnSacCode.toLowerCase().contains(q);
        if (!(nameMatch || skuMatch || catMatch || hsnMatch)) {
          return false;
        }
      }

      final isService = prod.productType.toLowerCase() == 'service';
      switch (_filterType) {
        case 'Goods':
          if (isService) return false;
          break;
        case 'Services':
          if (!isService) return false;
          break;
        case 'In Stock':
          if (isService) return true;
          if (prod.stock <= 0) return false;
          break;
        default:
          break;
      }

      return true;
    }).toList();

    // Map selected items by product ID
    final selectedItemsMap = {
      for (var item in provider.selectedItems) item.product.id: item
    };

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Select Items',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showQuickAddItemDialog(_searchQuery),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Item', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE5E7EB), height: 1.0),
        ),
      ),
      bottomNavigationBar: provider.selectedItems.isNotEmpty
          ? _buildStickyBottomBar(theme, isDark, provider, currencyFormat)
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // Search Bar & Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 300), () {
                          context.read<ProductProvider>().searchProducts(val);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search items by name, SKU, category...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  context.read<ProductProvider>().searchProducts('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Quick Filter Chips
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('All Items', 'All'),
                          _buildFilterChip('Goods', 'Goods'),
                          _buildFilterChip('Services', 'Services'),
                          _buildFilterChip('In Stock', 'In Stock'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Items List
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
                                    size: 44,
                                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No Items Found',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No matching item for "$_searchQuery".'
                                        : 'No items available in this category.',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _showQuickAddItemDialog(_searchQuery),
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Add This Item'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.lightPrimary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final selectedItem = selectedItemsMap[product.id];
                              return _buildProductRow(
                                context,
                                product,
                                selectedItem?.quantity ?? 0,
                                currencyFormat,
                                isDark,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _filterType == value;

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _filterType = value);
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

  Widget _buildProductRow(
    BuildContext context,
    Product product,
    int selectedQty,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    final provider = context.read<InvoiceProvider>();
    final isService = product.productType.toLowerCase() == 'service';
    final isSelected = selectedQty > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? AppColors.lightPrimary
              : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isService ? const Color(0xFFF3E8FF) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isService ? Icons.design_services_outlined : Icons.inventory_2_outlined,
              size: 20,
              color: isService ? const Color(0xFF7C3AED) : const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (product.sku.isNotEmpty) ...[
                      Text(
                        product.sku,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1))),
                    ],
                    Text(
                      currencyFormat.format(product.sellingPrice),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (product.gst > 0)
                      Text(
                        ' +${product.gst}%',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Add / Quantity Stepper
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: () => provider.updateItemQty(product.id, selectedQty - 1),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  Text(
                    '$selectedQty',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => provider.addProduct(product),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            )
          else
            OutlinedButton(
              onPressed: () => provider.addProduct(product),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.lightPrimary,
                side: const BorderSide(color: AppColors.lightPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(
    ThemeData theme,
    bool isDark,
    InvoiceProvider provider,
    NumberFormat currencyFormat,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.selectedItems.fold<int>(0, (sum, i) => sum + i.quantity)} items selected',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                Text(
                  currencyFormat.format(provider.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
