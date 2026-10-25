import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/invoice_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/models/product.dart';
import '../../products/models/product_hierarchy.dart';
import '../models/invoice_item.dart';

class SimpleProductPickerModal extends StatefulWidget {
  const SimpleProductPickerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SimpleProductPickerModal(),
    );
  }

  @override
  State<SimpleProductPickerModal> createState() => _SimpleProductPickerModalState();
}

class _SimpleProductPickerModalState extends State<SimpleProductPickerModal> {
  final ProductHierarchyService _hierarchyService = ProductHierarchyService();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  String _searchQuery = '';
  String _selectedCompany = '';
  String _selectedCategory = '';
  String _selectedSubcategory = '';

  // Currently selected product being configured
  Product? _selectedProduct;
  int _quantity = 1;
  String _selectedUnit = 'Pcs'; // 'Pcs', 'Box', 'Outer'
  double _unitPrice = 0.0;
  final int _pcsPerBox = 12;
  final int _boxesPerOuter = 6;
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController();

  String? _successBanner;

  @override
  void initState() {
    super.initState();
    _hierarchyService.init().then((_) {
      if (mounted) {
        setState(() {
          _selectedCompany = 'All';
          _selectedCategory = 'All';
          _selectedSubcategory = 'All';
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      if (productProvider.products.isEmpty) {
        productProvider.fetchProducts(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onCompanyChanged(String company) {
    setState(() {
      _selectedCompany = company;
      final cats = _hierarchyService.getCategoryNames(company);
      _selectedCategory = cats.isNotEmpty ? cats.first : 'All';
      final subs = _selectedCategory != 'All'
          ? _hierarchyService.getSubcategoryNames(company, _selectedCategory)
          : <String>[];
      _selectedSubcategory = subs.isNotEmpty ? subs.first : 'All';
      _selectedProduct = null;
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      final subs = category != 'All'
          ? _hierarchyService.getSubcategoryNames(_selectedCompany, category)
          : <String>[];
      _selectedSubcategory = subs.isNotEmpty ? subs.first : 'All';
      _selectedProduct = null;
    });
  }

  void _onSubcategoryChanged(String subcategory) {
    setState(() {
      _selectedSubcategory = subcategory;
      _selectedProduct = null;
    });
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
      _quantity = 1;
      _selectedUnit = 'Pcs';
      _unitPrice = product.price > 0 ? product.price : 10.0;
      _qtyController.text = '1';
      _priceController.text = _unitPrice.toStringAsFixed(2);
      _successBanner = null;
    });
  }

  void _onUnitChanged(String unit) {
    if (_selectedProduct == null) return;
    setState(() {
      _selectedUnit = unit;
      final basePiecePrice = _selectedProduct!.price > 0 ? _selectedProduct!.price : 10.0;

      if (unit == 'Pcs') {
        _unitPrice = basePiecePrice;
      } else if (unit == 'Box') {
        _unitPrice = basePiecePrice * _pcsPerBox;
      } else if (unit == 'Outer') {
        _unitPrice = basePiecePrice * _pcsPerBox * _boxesPerOuter;
      }
      _priceController.text = _unitPrice.toStringAsFixed(2);
    });
  }

  void _updateQuantity(int newQty) {
    if (newQty < 1) return;
    setState(() {
      _quantity = newQty;
      _qtyController.text = newQty.toString();
    });
  }

  bool _saveCurrentProductToInvoice() {
    if (_selectedProduct == null) return false;

    final parsedQty = int.tryParse(_qtyController.text) ?? _quantity;
    final parsedPrice = double.tryParse(_priceController.text) ?? _unitPrice;

    if (parsedQty <= 0) return false;

    final invoiceProvider = context.read<InvoiceProvider>();
    final itemId = 'item_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';

    final invoiceItem = InvoiceItem(
      id: itemId,
      product: _selectedProduct!,
      quantity: parsedQty,
      unitPrice: parsedPrice,
      unit: _selectedUnit,
      taxPercentage: _selectedProduct!.gst > 0 ? _selectedProduct!.gst : 18.0,
      itemName: '${_selectedProduct!.name} ($_selectedUnit)',
      description: '${_selectedProduct!.name} ($_selectedUnit)',
      hsnSac: _selectedProduct!.hsnSacCode,
    );

    invoiceProvider.addItem(invoiceItem);
    return true;
  }

  void _handleSaveAndAddNext() {
    if (_selectedProduct == null) return;
    final productName = _selectedProduct!.name;
    final qty = _quantity;
    final unit = _selectedUnit;

    if (_saveCurrentProductToInvoice()) {
      setState(() {
        _successBanner = '✓ Added $qty $unit of "$productName" to invoice!';
        _selectedProduct = null;
        _quantity = 1;
        _selectedUnit = 'Pcs';
        _qtyController.text = '1';
      });
    }
  }

  void _handleSaveAndDone() {
    if (_selectedProduct != null) {
      _saveCurrentProductToInvoice();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productProvider = context.watch<ProductProvider>();

    final rawCompanies = _hierarchyService.getCompanyNames();
    final companies = ['All', ...rawCompanies];
    final categories = (_selectedCompany.isNotEmpty && _selectedCompany != 'All')
        ? ['All', ..._hierarchyService.getCategoryNames(_selectedCompany)]
        : <String>['All'];
    final subcategories = (_selectedCompany.isNotEmpty && _selectedCategory.isNotEmpty && _selectedCategory != 'All')
        ? ['All', ..._hierarchyService.getSubcategoryNames(_selectedCompany, _selectedCategory)]
        : <String>['All'];

    // Filter products
    final allProducts = productProvider.products;
    final filteredProducts = allProducts.where((p) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = p.name.toLowerCase().contains(q) ||
            p.company.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.subcategory.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q);
        if (!matches) return false;
      }

      // 2. Company match
      if (_selectedCompany.isNotEmpty && _selectedCompany != 'All') {
        final c = p.company.toLowerCase();
        final b = p.brand.toLowerCase();
        final target = _selectedCompany.toLowerCase();
        if (!c.contains(target) && !b.contains(target) && !target.contains(c)) {
          return false;
        }
      }

      // 3. Category match
      if (_selectedCategory.isNotEmpty && _selectedCategory != 'All') {
        final cat = p.category.toLowerCase();
        final target = _selectedCategory.toLowerCase();
        if (!cat.contains(target) && !target.contains(cat)) {
          return false;
        }
      }

      // 4. Subcategory match
      if (_selectedSubcategory.isNotEmpty && _selectedSubcategory != 'All') {
        final sub = p.subcategory.toLowerCase();
        final target = _selectedSubcategory.toLowerCase();
        if (!sub.contains(target) && !target.contains(sub)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Calculate real-time item amounts if product selected
    final double taxableAmount = _quantity * _unitPrice;
    final double gstRate = _selectedProduct != null ? (_selectedProduct!.gst > 0 ? _selectedProduct!.gst : 18.0) : 18.0;
    final double taxAmount = taxableAmount * (gstRate / 100);
    final double netAmount = taxableAmount + taxAmount;

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.60,
      maxChildSize: 0.96,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top drag pill
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Modal Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Product',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Select Company › Category › Subcategory › Product',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Success Notification Banner
              if (_successBanner != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successBanner!,
                          style: const TextStyle(
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Color(0xFF047857)),
                        onPressed: () => setState(() => _successBanner = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search product by name or SKU...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),

              // Hierarchy Steps & Product List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  children: [
                    // Step 1: Company Selection
                    _buildStepHeader('1. Select Company', Icons.business_rounded),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All Companies',
                            isSelected: _selectedCompany == 'All' || _selectedCompany.isEmpty,
                            onTap: () => _onCompanyChanged('All'),
                          ),
                          ...companies.map((comp) {
                            return _buildFilterChip(
                              label: comp,
                              isSelected: _selectedCompany == comp,
                              onTap: () => _onCompanyChanged(comp),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Step 2: Category Selection
                    if (categories.isNotEmpty) ...[
                      _buildStepHeader('2. Select Category', Icons.category_rounded),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'All Categories',
                              isSelected: _selectedCategory == 'All',
                              onTap: () => _onCategoryChanged('All'),
                            ),
                            ...categories.map((cat) {
                              return _buildFilterChip(
                                label: cat,
                                isSelected: _selectedCategory == cat,
                                onTap: () => _onCategoryChanged(cat),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Step 3: Subcategory Selection
                    if (subcategories.isNotEmpty) ...[
                      _buildStepHeader('3. Select Sub Category', Icons.subdirectory_arrow_right_rounded),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'All Subcategories',
                              isSelected: _selectedSubcategory == 'All',
                              onTap: () => _onSubcategoryChanged('All'),
                            ),
                            ...subcategories.map((sub) {
                              return _buildFilterChip(
                                label: sub,
                                isSelected: _selectedSubcategory == sub,
                                onTap: () => _onSubcategoryChanged(sub),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Step 4: Product Selection Header & List
                    _buildStepHeader('4. Select Product (Tap to configure)', Icons.inventory_2_rounded),
                    const SizedBox(height: 8),

                    if (filteredProducts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            const Text(
                              'No products found matching filters',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try selecting "All" or searching for a different keyword.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    else
                      ...filteredProducts.map((prod) {
                        final isSelected = _selectedProduct?.id == prod.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                                : (isDark ? Colors.grey[850] : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _selectProduct(prod),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : (isDark ? Colors.grey[800] : const Color(0xFFEFF6FF)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.local_offer_rounded,
                                      color: isSelected ? Colors.white : const Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prod.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isSelected ? const Color(0xFF2563EB) : null,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${prod.company} › ${prod.category} › ${prod.subcategory}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _currency.format(prod.price),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        'GST: ${prod.gst.toStringAsFixed(0)}%',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: isSelected ? const Color(0xFF2563EB) : Colors.grey[400],
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                    // Step 5: Product Configuration Panel (Qty, Unit, Price, GST, Calculations)
                    if (_selectedProduct != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Title & Badge
                            Row(
                              children: [
                                const Icon(Icons.tune_rounded, color: Color(0xFF10B981), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Configure: ${_selectedProduct!.name}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),

                            // Units Selector: Pcs, Box, Outer
                            const Text(
                              'Select Unit (Changes price automatically):',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildUnitOption(
                                    unitName: 'Pcs',
                                    description: '1 Piece',
                                    multiplier: '1x',
                                    isSelected: _selectedUnit == 'Pcs',
                                    onTap: () => _onUnitChanged('Pcs'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildUnitOption(
                                    unitName: 'Box',
                                    description: '$_pcsPerBox Pcs',
                                    multiplier: '${_pcsPerBox}x',
                                    isSelected: _selectedUnit == 'Box',
                                    onTap: () => _onUnitChanged('Box'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildUnitOption(
                                    unitName: 'Outer',
                                    description: '${_pcsPerBox * _boxesPerOuter} Pcs',
                                    multiplier: '${_pcsPerBox * _boxesPerOuter}x',
                                    isSelected: _selectedUnit == 'Outer',
                                    onTap: () => _onUnitChanged('Outer'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Quantity and Price inputs row
                            Row(
                              children: [
                                // Quantity Stepper
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Quantity:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.grey[850] : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove, size: 18),
                                              onPressed: _quantity > 1 ? () => _updateQuantity(_quantity - 1) : null,
                                            ),
                                            Expanded(
                                              child: TextField(
                                                controller: _qtyController,
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                  contentPadding: EdgeInsets.zero,
                                                ),
                                                onChanged: (val) {
                                                  final q = int.tryParse(val) ?? 1;
                                                  setState(() => _quantity = q);
                                                },
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add, size: 18),
                                              onPressed: () => _updateQuantity(_quantity + 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Unit Price input
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Price per $_selectedUnit (₹):',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.grey[850] : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                        ),
                                        child: TextField(
                                          controller: _priceController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          decoration: const InputDecoration(
                                            prefixText: '₹ ',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                          ),
                                          onChanged: (val) {
                                            final p = double.tryParse(val) ?? _unitPrice;
                                            setState(() => _unitPrice = p);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Calculation Summary Box (Subtotal, GST, Net Amount)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[900] : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Subtotal ($_quantity × ${_currency.format(_unitPrice)}):',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      Text(_currency.format(taxableAmount),
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('GST (${gstRate.toStringAsFixed(0)}%):',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      Text(_currency.format(taxAmount),
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFD97706))),
                                    ],
                                  ),
                                  const Divider(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Net Amount (After GST):',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _currency.format(netAmount),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Save and Add Next / Done Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _handleSaveAndAddNext,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text(
                                      'Save & Add Next',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2563EB),
                                      side: const BorderSide(color: Color(0xFF2563EB)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _handleSaveAndDone,
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text(
                                      'Save & Done',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
        checkmarkColor: const Color(0xFF2563EB),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF2563EB) : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitOption({
    required String unitName,
    required String description,
    required String multiplier,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              unitName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
