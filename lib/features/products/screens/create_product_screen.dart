import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class CreateProductScreen extends StatefulWidget {
  final Product? product; // If not null, we are editing.

  const CreateProductScreen({super.key, this.product});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Fields - General
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _categoryController;
  late TextEditingController _brandController;
  late TextEditingController _unitController;
  late TextEditingController _descriptionController;

  // Fields - Financial & Inventory
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _gstController;
  late TextEditingController _currentStockController;
  late TextEditingController _minStockController;

  // Mock list of attached images
  final List<String> _mockImages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _categoryController = TextEditingController(text: p?.category ?? 'Services');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _unitController = TextEditingController(text: 'Pcs');
    _descriptionController = TextEditingController(text: '');

    _purchasePriceController = TextEditingController(text: p?.purchasePrice.toString() ?? '0.0');
    _sellingPriceController = TextEditingController(text: p?.sellingPrice.toString() ?? '0.0');
    _gstController = TextEditingController(text: p?.gst.toString() ?? '18.0');
    _currentStockController = TextEditingController(text: p?.stock.toString() ?? '10');
    _minStockController = TextEditingController(text: p?.minStock.toString() ?? '5');

    if (p?.image != null) {
      _mockImages.add(p!.image!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _gstController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    final productProvider = context.read<ProductProvider>();
    final isEdit = widget.product != null;

    // Capture before await — must match useRootNavigator: false used in showDialog
    final navigator = Navigator.of(context, rootNavigator: false);
    final messenger = ScaffoldMessenger.of(context);

    final categoryVal = _categoryController.text.trim();
    final isService = categoryVal.toLowerCase() == 'services' || categoryVal.toLowerCase() == 'consulting';

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      sku: _skuController.text.trim().isEmpty 
          ? 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}' 
          : _skuController.text.trim(),
      barcode: _barcodeController.text.trim(),
      productType: isService ? 'service' : 'goods',
      category: categoryVal,
      brand: _brandController.text.trim().isEmpty ? 'Generic' : _brandController.text.trim(),
      unitOfMeasurement: _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'Pieces',
      purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
      sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
      stock: int.tryParse(_currentStockController.text) ?? 0,
      minStock: int.tryParse(_minStockController.text) ?? 5,
      trackInventory: !isService,
      description: _descriptionController.text.trim(),
      gst: double.tryParse(_gstController.text) ?? 18.0,
      image: _mockImages.isNotEmpty ? _mockImages.first : null,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
    );

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    Product? result;
    try {
      if (isEdit) {
        result = await productProvider.updateProduct(product.id, product);
      } else {
        result = await productProvider.createProduct(product);
      }
    } finally {
      // Always dismiss the loading dialog — use captured navigator
      if (mounted) navigator.pop();
    }

    if (!mounted) return;

    if (result != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Product updated successfully' : 'Product added successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      navigator.pop(result);
    } else {
      final err = productProvider.errorMessage ?? 'Failed to save product';
      messenger.showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addMockImage() {
    setState(() {
      _mockImages.add('assets/images/placeholder_product.png');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveProduct,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'General Info'),
            Tab(icon: Icon(Icons.monetization_on_outlined), text: 'Pricing & Stock'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: General Info
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(theme, 'Product Identification'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      prefixIcon: Icon(Icons.label_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter product name' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _skuController,
                          decoration: const InputDecoration(
                            labelText: 'SKU Code',
                            prefixIcon: Icon(Icons.tag_rounded),
                            hintText: 'e.g. HDW-9092',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Barcode',
                            prefixIcon: Icon(Icons.qr_code_scanner_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                          value: _categoryController.text,
                          items: ['Services', 'Hardware', 'Software', 'Consulting'].map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _categoryController.text = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: 'Brand / Manufacturer',
                            prefixIcon: Icon(Icons.copyright_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Measurement Unit (e.g. Pcs, Box, Hrs)',
                      prefixIcon: Icon(Icons.scale_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader(theme, 'Product Images'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._mockImages.asMap().entries.map((entry) {
                          final idx = entry.key;
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBorder : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.image_outlined, color: Colors.grey, size: 28),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _mockImages.removeAt(idx);
                                      });
                                    },
                                    child: const CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.red,
                                      child: Icon(Icons.close, color: Colors.white, size: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: _addMockImage,
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                style: BorderStyle.solid,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: theme.colorScheme.primary, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Image',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Product Description',
                      prefixIcon: Icon(Icons.description_rounded),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ).animate().fade(duration: 200.ms),
            ),

            // Tab 2: Pricing & Stock
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(theme, 'Financial Details'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Purchase Price (₹) *',
                            prefixIcon: Icon(Icons.shopping_bag_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter purchase price';
                            final parsed = double.tryParse(val);
                            if (parsed == null) return 'Enter valid amount';
                            if (parsed < 0) return 'Price cannot be negative';
                            final parts = val.trim().split('.');
                            if (parts[0].length > 9) {
                              return 'Price cannot exceed 9 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Selling Price (₹) *',
                            prefixIcon: Icon(Icons.sell_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter selling price';
                            final parsed = double.tryParse(val);
                            if (parsed == null) return 'Enter valid amount';
                            if (parsed < 0) return 'Price cannot be negative';
                            final parts = val.trim().split('.');
                            if (parts[0].length > 9) {
                              return 'Price cannot exceed 9 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gstController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'GST Tax Percentage (%)',
                      prefixIcon: Icon(Icons.percent_rounded),
                      hintText: 'e.g. 18.0',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return null;
                      if (double.tryParse(val) == null) return 'Enter valid percentage';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader(theme, 'Stock Control'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _currentStockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Current Stock *',
                            prefixIcon: Icon(Icons.inventory_2_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter current stock';
                            if (int.tryParse(val) == null) return 'Enter integer value';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minStockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minimum Low Stock *',
                            prefixIcon: Icon(Icons.warning_amber_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter min stock';
                            if (int.tryParse(val) == null) return 'Enter integer value';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 50),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveProduct,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 50),
                          ),
                          child: const Text('Save Product'),
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fade(duration: 200.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
        fontSize: 14,
        letterSpacing: 0.5,
      ),
    );
  }
}
