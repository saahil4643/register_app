import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class CreateProductScreen extends StatefulWidget {
  final Product? product;

  const CreateProductScreen({super.key, this.product});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Item Type: 'goods' or 'service'
  String _productType = 'goods';

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _categoryController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _hsnSacController;
  late TextEditingController _currentStockController;
  late TextEditingController _minStockController;
  late TextEditingController _descriptionController;

  // Selections
  String _unit = 'Pieces';
  double _gstRate = 18.0;
  bool _trackInventory = true;
  bool _isSaving = false;

  final List<String> _unitOptions = [
    'Pieces',
    'Numbers',
    'Hours',
    'Days',
    'Boxes',
    'Kilograms',
    'Meters',
    'Sets',
    'Units',
  ];

  final List<double> _gstOptions = [0.0, 5.0, 12.0, 18.0, 28.0];

  final List<String> _categorySuggestions = [
    'General',
    'Services',
    'Consulting',
    'Software',
    'Hardware',
    'Electronics',
    'Office Supplies',
    'Professional Fees',
    'Maintenance',
    'Subscription',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _productType = (p?.productType.toLowerCase() == 'service') ? 'service' : 'goods';
    _trackInventory = p?.trackInventory ?? (_productType == 'goods');

    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _categoryController = TextEditingController(text: p?.category.isNotEmpty == true ? p!.category : 'General');
    _sellingPriceController = TextEditingController(
      text: (p != null && p.sellingPrice > 0) ? p.sellingPrice.toStringAsFixed(2) : '',
    );
    _purchasePriceController = TextEditingController(
      text: (p != null && p.purchasePrice > 0) ? p.purchasePrice.toStringAsFixed(2) : '',
    );
    _hsnSacController = TextEditingController(text: p?.hsnSacCode ?? '');
    _currentStockController = TextEditingController(
      text: p != null ? p.stock.toString() : '10',
    );
    _minStockController = TextEditingController(
      text: p != null ? p.minStock.toString() : '5',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');

    if (p != null) {
      if (_unitOptions.contains(p.unitOfMeasurement)) {
        _unit = p.unitOfMeasurement;
      }
      if (_gstOptions.contains(p.gst)) {
        _gstRate = p.gst;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _hsnSacController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _getUnitAbbreviation(String unit) {
    switch (unit.toLowerCase()) {
      case 'pieces':
        return 'pcs';
      case 'numbers':
        return 'nos';
      case 'hours':
        return 'hrs';
      case 'days':
        return 'days';
      case 'boxes':
        return 'box';
      case 'kilograms':
        return 'kg';
      case 'meters':
        return 'm';
      case 'sets':
        return 'set';
      default:
        return 'units';
    }
  }

  void _generateSku() {
    final prefix = _productType == 'service' ? 'SRV' : 'ITEM';
    final randomSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    _skuController.text = '$prefix-$randomSuffix';
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final productProvider = context.read<ProductProvider>();
    final isEdit = widget.product != null;

    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final stock = _trackInventory ? (int.tryParse(_currentStockController.text.trim()) ?? 0) : 0;
    final minStock = _trackInventory ? (int.tryParse(_minStockController.text.trim()) ?? 5) : 0;

    String finalSku = _skuController.text.trim();
    if (finalSku.isEmpty) {
      final prefix = _productType == 'service' ? 'SRV' : 'ITM';
      finalSku = '$prefix-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }

    final product = Product(
      id: widget.product?.id ?? 'PROD-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      sku: finalSku,
      barcode: _barcodeController.text.trim(),
      productType: _productType,
      category: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : 'General',
      company: 'General',
      subcategory: 'General',
      brand: 'General',
      unitOfMeasurement: _unit,
      unitAbbreviation: _getUnitAbbreviation(_unit),
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      stock: stock,
      openingStock: stock.toDouble(),
      minStock: minStock,
      trackInventory: _trackInventory && _productType == 'goods',
      status: 'active',
      description: _descriptionController.text.trim(),
      gst: _gstRate,
      hsnSacCode: _hsnSacController.text.trim(),
      createdAt: widget.product?.createdAt ?? DateTime.now(),
    );

    Product? result;
    try {
      if (isEdit) {
        result = await productProvider.updateProduct(product.id, product);
      } else {
        result = await productProvider.createProduct(product);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Item updated successfully' : 'Item created successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(result);
    } else {
      final err = productProvider.errorMessage ?? 'Failed to save item';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.product != null ? 'Edit Item' : 'Add New Item',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProduct,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.grey[200] : AppColors.lightPrimary,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE5E7EB), height: 1.0),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Type Selector: Goods vs Service
                  _buildTypeSelector(isDark),
                  const SizedBox(height: 16),

                  // Section 1: Basic Information
                  _buildSectionHeader('BASIC INFORMATION', Icons.inventory_2_outlined),
                  const SizedBox(height: 8),
                  _buildBasicInfoCard(isDark),
                  const SizedBox(height: 18),

                  // Section 2: Pricing & Tax
                  _buildSectionHeader('PRICING & TAXATION', Icons.payments_outlined),
                  const SizedBox(height: 8),
                  _buildPricingCard(isDark),
                  const SizedBox(height: 18),

                  // Section 3: Inventory (Goods only)
                  if (_productType == 'goods') ...[
                    _buildSectionHeader('INVENTORY & STOCK', Icons.warehouse_outlined),
                    const SizedBox(height: 8),
                    _buildInventoryCard(isDark),
                    const SizedBox(height: 18),
                  ],

                  // Section 4: Description
                  _buildSectionHeader('DESCRIPTION & INVOICE NOTES', Icons.notes_outlined),
                  const SizedBox(height: 8),
                  _buildDescriptionCard(isDark),
                  const SizedBox(height: 24),

                  // Bottom Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              widget.product != null ? 'Update Item' : 'Save Item',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              label: 'Goods / Product',
              icon: Icons.inventory_2_outlined,
              isSelected: _productType == 'goods',
              isDark: isDark,
              onTap: () {
                setState(() {
                  _productType = 'goods';
                  _trackInventory = true;
                  if (_unit == 'Hours' || _unit == 'Days') {
                    _unit = 'Pieces';
                  }
                });
              },
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              label: 'Service / Consulting',
              icon: Icons.design_services_outlined,
              isSelected: _productType == 'service',
              isDark: isDark,
              onTap: () {
                setState(() {
                  _productType = 'service';
                  _trackInventory = false;
                  if (_unit == 'Pieces') {
                    _unit = 'Hours';
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.lightPrimary
                  : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContainer(bool isDark, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildBasicInfoCard(bool isDark) {
    return _buildCardContainer(
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Name (Mandatory)
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: _productType == 'service' ? 'Service Name *' : 'Item Name *',
              hintText: _productType == 'service' ? 'e.g. Website Consulting, Legal Audit' : 'e.g. Wireless Ergonomic Mouse',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Item name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // SKU & Barcode Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _skuController,
                  decoration: InputDecoration(
                    labelText: 'Item Code / SKU',
                    hintText: 'e.g. ITM-1020',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: TextButton(
                      onPressed: _generateSku,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text(
                        'Auto',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode / UPC',
                    hintText: 'Optional',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Category & Unit Row
          Row(
            children: [
              // Category
              Expanded(
                child: TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g. Services, Hardware',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      onSelected: (cat) {
                        setState(() {
                          _categoryController.text = cat;
                        });
                      },
                      itemBuilder: (ctx) => _categorySuggestions
                          .map((c) => PopupMenuItem(value: c, child: Text(c)))
                          .toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Unit
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _unitOptions
                      .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _unit = v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(bool isDark) {
    return _buildCardContainer(
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Selling Price
              Expanded(
                child: TextFormField(
                  controller: _sellingPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Selling Price *',
                    hintText: '0.00',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Selling price is required';
                    }
                    if (double.tryParse(v.trim()) == null) {
                      return 'Invalid amount';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Cost / Purchase Price
              Expanded(
                child: TextFormField(
                  controller: _purchasePriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cost Price',
                    hintText: '0.00',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // GST Tax Rate
              Expanded(
                child: DropdownButtonFormField<double>(
                  initialValue: _gstRate,
                  decoration: const InputDecoration(
                    labelText: 'GST Tax Rate',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _gstOptions
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r == 0 ? '0% (Exempt)' : '$r% GST',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _gstRate = v);
                  },
                ),
              ),
              const SizedBox(width: 12),

              // HSN / SAC Code
              Expanded(
                child: TextFormField(
                  controller: _hsnSacController,
                  decoration: InputDecoration(
                    labelText: _productType == 'service' ? 'SAC Code' : 'HSN Code',
                    hintText: _productType == 'service' ? 'e.g. 998314' : 'e.g. 847130',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(bool isDark) {
    return _buildCardContainer(
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track Inventory for this item',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Automatically deduct stock when invoices are generated',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _trackInventory,
                activeThumbColor: AppColors.lightPrimary,
                onChanged: (val) {
                  setState(() => _trackInventory = val);
                },
              ),
            ],
          ),
          if (_trackInventory) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _currentStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Opening Stock',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Low Stock Alert Threshold',
                      hintText: '5',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(bool isDark) {
    return _buildCardContainer(
      isDark,
      TextFormField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Enter item or service description as it should appear on customer invoices...',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
