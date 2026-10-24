import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/product.dart';
import '../models/product_hierarchy.dart';
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

  // Hierarchy selections
  final ProductHierarchyService _hierarchyService = ProductHierarchyService();
  String _selectedCompany = 'Wipro';
  String _selectedCategory = 'Santoor';
  String _selectedSubcategory = 'Soap';

  // Fields - General
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
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
    _unitController = TextEditingController(text: p?.unitOfMeasurement.isNotEmpty == true ? p!.unitOfMeasurement : 'Pieces');
    _descriptionController = TextEditingController(text: p?.description ?? '');

    _purchasePriceController = TextEditingController(text: p?.purchasePrice.toString() ?? '0.0');
    _sellingPriceController = TextEditingController(text: p?.sellingPrice.toString() ?? '0.0');
    _gstController = TextEditingController(text: p?.gst.toString() ?? '18.0');
    _currentStockController = TextEditingController(text: p?.stock.toString() ?? '10');
    _minStockController = TextEditingController(text: p?.minStock.toString() ?? '5');

    if (p != null) {
      if (p.company.isNotEmpty) _selectedCompany = p.company;
      if (p.category.isNotEmpty) _selectedCategory = p.category;
      if (p.subcategory.isNotEmpty) _selectedSubcategory = p.subcategory;
    }

    if (p?.image != null) {
      _mockImages.add(p!.image!);
    }

    _hierarchyService.init().then((_) {
      if (mounted) {
        _syncHierarchySelections();
        setState(() {});
      }
    });
  }

  void _syncHierarchySelections() {
    final companies = _hierarchyService.getCompanyNames();
    if (!companies.contains(_selectedCompany)) {
      _selectedCompany = companies.isNotEmpty ? companies.first : 'Wipro';
    }

    final categories = _hierarchyService.getCategoryNames(_selectedCompany);
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.isNotEmpty ? categories.first : 'General';
    }

    final subcategories = _hierarchyService.getSubcategoryNames(_selectedCompany, _selectedCategory);
    if (!subcategories.contains(_selectedSubcategory)) {
      _selectedSubcategory = subcategories.isNotEmpty ? subcategories.first : 'General';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _gstController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _showAddCompanyDialog() async {
    final controller = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.business_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Add Company'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Company / Manufacturer Name',
            hintText: 'e.g. Dabur, Britannia, Nestle',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      await _hierarchyService.addCompany(res);
      setState(() {
        _selectedCompany = res;
        _syncHierarchySelections();
      });
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.category_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text('Add Category for $_selectedCompany'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category / Brand Line',
            hintText: 'e.g. Santoor, Oreo, Real Juice',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      await _hierarchyService.addCategory(_selectedCompany, res);
      setState(() {
        _selectedCategory = res;
        _syncHierarchySelections();
      });
    }
  }

  Future<void> _showAddSubcategoryDialog() async {
    final controller = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.subdirectory_arrow_right_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text('Add Subcategory for $_selectedCategory'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subcategory Name',
            hintText: 'e.g. Soap, Handwash, Powder',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      await _hierarchyService.addSubcategory(_selectedCompany, _selectedCategory, res);
      setState(() {
        _selectedSubcategory = res;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    final productProvider = context.read<ProductProvider>();
    final isEdit = widget.product != null;

    final navigator = Navigator.of(context, rootNavigator: false);
    final messenger = ScaffoldMessenger.of(context);

    final isService = _selectedCategory.toLowerCase() == 'services' || _selectedSubcategory.toLowerCase() == 'consulting';

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      sku: _skuController.text.trim().isEmpty
          ? 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
          : _skuController.text.trim(),
      barcode: _barcodeController.text.trim(),
      productType: isService ? 'service' : 'goods',
      company: _selectedCompany,
      category: _selectedCategory,
      subcategory: _selectedSubcategory,
      brand: _selectedCompany,
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
    final productProvider = context.watch<ProductProvider>();

    // Query products currently matching this subcategory hierarchy
    final matchingSubcategoryProducts = productProvider.products.where((p) {
      final compMatch = p.company.toLowerCase() == _selectedCompany.toLowerCase() ||
          p.brand.toLowerCase() == _selectedCompany.toLowerCase();
      final catMatch = p.category.toLowerCase() == _selectedCategory.toLowerCase();
      final subMatch = p.subcategory.toLowerCase() == _selectedSubcategory.toLowerCase();
      return compMatch && catMatch && subMatch;
    }).toList();

    final companies = _hierarchyService.getCompanyNames();
    final categories = _hierarchyService.getCategoryNames(_selectedCompany);
    final subcategories = _hierarchyService.getSubcategoryNames(_selectedCompany, _selectedCategory);

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
            Tab(icon: Icon(Icons.account_tree_outlined), text: 'Hierarchy & Info'),
            Tab(icon: Icon(Icons.monetization_on_outlined), text: 'Pricing & Stock'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Hierarchy & Info
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hierarchy Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.layers_rounded, color: theme.colorScheme.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Product Hierarchy Selection',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select Company → Category → Subcategory to categorize your inventory.',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSectionHeader(theme, '1. Hierarchy Structure'),
                  const SizedBox(height: 12),

                  // Company Selector
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Company / Manufacturer *',
                            prefixIcon: const Icon(Icons.business_rounded),
                            helperText: 'e.g. Wipro, Cadbury, Fena, HUL',
                            suffixIcon: Tooltip(
                              message: 'Add custom company',
                              child: IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                onPressed: _showAddCompanyDialog,
                              ),
                            ),
                          ),
                          value: companies.contains(_selectedCompany) ? _selectedCompany : (companies.isNotEmpty ? companies.first : null),
                          items: companies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCompany = val;
                                _syncHierarchySelections();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Category Selector (Dependent on Company)
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Category (under $_selectedCompany) *',
                            prefixIcon: const Icon(Icons.category_rounded),
                            helperText: 'e.g. Santoor, Dairy Milk, Nip',
                            suffixIcon: Tooltip(
                              message: 'Add category under $_selectedCompany',
                              child: IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                onPressed: _showAddCategoryDialog,
                              ),
                            ),
                          ),
                          value: categories.contains(_selectedCategory) ? _selectedCategory : (categories.isNotEmpty ? categories.first : null),
                          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                                _syncHierarchySelections();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Subcategory Selector (Dependent on Category)
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Subcategory (under $_selectedCategory) *',
                            prefixIcon: const Icon(Icons.subdirectory_arrow_right_rounded),
                            helperText: 'e.g. Handwash, Soap, Powder',
                            suffixIcon: Tooltip(
                              message: 'Add subcategory under $_selectedCategory',
                              child: IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                onPressed: _showAddSubcategoryDialog,
                              ),
                            ),
                          ),
                          value: subcategories.contains(_selectedSubcategory) ? _selectedSubcategory : (subcategories.isNotEmpty ? subcategories.first : null),
                          items: subcategories.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSubcategory = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Display Existing Products in Selected Subcategory
                  _buildSubcategoryProductsCard(theme, isDark, matchingSubcategoryProducts),
                  const SizedBox(height: 20),

                  _buildSectionHeader(theme, '2. Product Identification'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name *',
                      prefixIcon: const Icon(Icons.label_rounded),
                      hintText: 'e.g. Santoor Sandal & Turmeric Soap 100g',
                      helperText: 'Full descriptive name including variant and size',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter product name' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _skuController,
                          decoration: const InputDecoration(
                            labelText: 'SKU Code',
                            prefixIcon: Icon(Icons.tag_rounded),
                            hintText: 'e.g. WIP-SAN-100',
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
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Measurement Unit (e.g. Pieces, Pack, Box, Kg)',
                      prefixIcon: Icon(Icons.scale_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description / Notes',
                      prefixIcon: Icon(Icons.notes_rounded),
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
                              color: theme.colorScheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: theme.colorScheme.primary, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Image',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab 2: Pricing & Stock
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(theme, 'Pricing & Taxes'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Selling Price (₹) *',
                            prefixIcon: Icon(Icons.sell_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter price';
                            if (double.tryParse(val) == null) return 'Invalid price';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Purchase Price (₹)',
                            prefixIcon: Icon(Icons.shopping_bag_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _gstController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'GST Tax Rate (%)',
                      prefixIcon: Icon(Icons.percent_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(theme, 'Inventory Management'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _currentStockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Current Stock',
                            prefixIcon: Icon(Icons.inventory_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minStockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Reorder Level / Min Stock',
                            prefixIcon: Icon(Icons.warning_amber_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
      ),
    );
  }

  Widget _buildSubcategoryProductsCard(
    ThemeData theme,
    bool isDark,
    List<Product> products,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: products.isNotEmpty
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1.2,
        ),
      ),
      color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.view_list_rounded,
                  size: 20,
                  color: products.isNotEmpty ? theme.colorScheme.primary : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                      children: [
                        const TextSpan(
                          text: 'Existing Products in ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: '$_selectedCompany > $_selectedCategory > $_selectedSubcategory',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: products.isNotEmpty
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${products.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: products.isNotEmpty ? theme.colorScheme.primary : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No products currently registered in this subcategory. You are creating the first product here!',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: products.map((prod) {
                  return Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                          child: Icon(Icons.inventory_2_outlined, size: 14, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prod.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'SKU: ${prod.sku.isNotEmpty ? prod.sku : "N/A"} • Stock: ${prod.stock} ${prod.unitAbbreviation}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(prod.sellingPrice),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
