import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../vendors/providers/vendor_provider.dart';
import '../models/purchase_order.dart';
import '../providers/purchase_order_provider.dart';
import '../../invoices/widgets/product_autocomplete.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_provider.dart';
import '../../invoices/widgets/customer_autocomplete.dart';
import '../../customers/models/customer.dart';
import '../../customers/providers/customer_provider.dart';
import '../../customers/widgets/add_customer_dialog.dart';

class NewPurchaseOrderScreen extends StatefulWidget {
  final PurchaseOrder? initialOrder;
  final bool isEditing;

  const NewPurchaseOrderScreen({
    super.key,
    this.initialOrder,
    this.isEditing = false,
  });

  @override
  State<NewPurchaseOrderScreen> createState() => _NewPurchaseOrderScreenState();
}

class _NewPurchaseOrderScreenState extends State<NewPurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Customer Details (Exactly like Invoice)
  Customer? _selectedCustomer;
  String? _selectedVendorId;
  String _selectedVendorName = '';
  late final TextEditingController _vendorSearchController;
  String _selectedCategory = 'Raw Materials';

  // Purchase Order Details
  late final TextEditingController _poNumberController;
  DateTime _purchaseDate = DateTime.now();
  late final TextEditingController _referenceController;

  // Items
  final List<_ItemFormEntry> _items = [];

  // Terms & Conditions & Notes
  late final TextEditingController _notesController;
  late final TextEditingController _internalNoteController;
  late final TextEditingController _termsController;

  // Attachments
  final List<String> _attachedFiles = [];

  // Summary & Meta
  String _paymentMode = 'Bank Transfer';
  String _status = 'Draft';

  final List<String> _categories = [
    'Raw Materials',
    'Equipment & Machinery',
    'IT & Software',
    'Office Supplies',
    'Logistics & Freight',
    'Subcontractor & Services',
    'Maintenance',
    'Packaging & Consumables',
    'Advertising & Marketing',
    'General',
  ];

  final List<String> _paymentModes = [
    'Bank Transfer',
    'Cash',
    'UPI',
    'Cheque',
    'Credit Card',
    'Net Banking',
  ];

  final List<String> _statusOptions = [
    'Draft',
    'Pending',
    'Approved',
    'Billed',
    'Cancelled',
  ];

  final List<String> _units = [
    'Nos',
    'Pcs',
    'Kg',
    'Box',
    'Mtr',
    'Set',
    'Units',
    'Ltr',
    'Hours',
  ];

  final List<double> _gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    final poProvider = context.read<PurchaseOrderProvider>();
    final initial = widget.initialOrder;

    _vendorSearchController = TextEditingController(text: initial?.vendorName ?? '');
    _selectedVendorId = initial?.vendorId;
    _selectedVendorName = initial?.vendorName ?? '';
    _selectedCategory = initial?.category ?? 'Raw Materials';

    _poNumberController = TextEditingController(
      text: initial?.poNumber ?? poProvider.getNextPoNumber(),
    );
    _purchaseDate = initial?.purchaseDate ?? DateTime.now();
    _referenceController = TextEditingController(text: initial?.referenceNumber ?? '');

    _notesController = TextEditingController(text: initial?.notes ?? '');
    _internalNoteController = TextEditingController(text: initial?.internalNote ?? '');
    _termsController = TextEditingController(
      text: initial?.termsAndConditions ??
          '1. Goods received subject to inspection and approval.\n'
              '2. Payment will be processed as per agreed terms.\n'
              '3. Mention PO number on all invoices and delivery notes.\n'
              '4. All disputes are subject to PUNE jurisdiction only.',
    );

    if (initial != null && initial.attachments.isNotEmpty) {
      _attachedFiles.addAll(initial.attachments);
    }

    _paymentMode = initial?.paymentMode ?? 'Bank Transfer';
    _status = initial?.status != null ? PurchaseOrder.displayStatus(initial!.status) : 'Draft';

    if (initial != null && initial.items.isNotEmpty) {
      for (final item in initial.items) {
        _items.add(_ItemFormEntry.fromModel(item, onChanged: () => setState(() {})));
      }
    }

    // Ensure vendors, customers, and products are loaded for selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().fetchVendors();
      context.read<CustomerProvider>().fetchCustomers();
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _vendorSearchController.dispose();
    _poNumberController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _internalNoteController.dispose();
    _termsController.dispose();
    for (final it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  double get _subtotal {
    double sum = 0.0;
    for (final it in _items) {
      sum += it.baseAmount;
    }
    return sum;
  }

  double get _totalDiscount {
    double sum = 0.0;
    for (final it in _items) {
      sum += it.discountAmount;
    }
    return sum;
  }

  double get _totalTax {
    double sum = 0.0;
    for (final it in _items) {
      sum += it.taxAmount;
    }
    return sum;
  }

  double get _grandTotal => (_subtotal - _totalDiscount + _totalTax).clamp(0.0, double.infinity);

  void _addItem() {
    setState(() {
      _items.add(_ItemFormEntry(onChanged: () => setState(() {})));
    });
  }

  void _removeItem(int index) {
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  void _addProductItem(Product product) {
    setState(() {
      final double defaultRate = product.purchasePrice > 0 ? product.purchasePrice : product.sellingPrice;
      String unitVal = 'Nos';
      for (final u in _units) {
        if (u.toLowerCase() == product.unitAbbreviation.toLowerCase() ||
            u.toLowerCase() == product.unitOfMeasurement.toLowerCase()) {
          unitVal = u;
          break;
        }
      }
      double gstVal = _gstRates.firstWhere(
        (g) => (g - product.gst).abs() < 0.1,
        orElse: () => 18.0,
      );

      final newEntry = _ItemFormEntry(
        name: product.name,
        hsn: product.hsnSacCode,
        qty: 1.0,
        unit: unitVal,
        rate: defaultRate,
        gstRate: gstVal,
        onChanged: () => setState(() {}),
      );
      _items.add(newEntry);
    });
  }

  void _populateProductAtIndex(int index, Product product) {
    setState(() {
      final double defaultRate = product.purchasePrice > 0 ? product.purchasePrice : product.sellingPrice;
      String unitVal = 'Nos';
      for (final u in _units) {
        if (u.toLowerCase() == product.unitAbbreviation.toLowerCase() ||
            u.toLowerCase() == product.unitOfMeasurement.toLowerCase()) {
          unitVal = u;
          break;
        }
      }
      double gstVal = _gstRates.firstWhere(
        (g) => (g - product.gst).abs() < 0.1,
        orElse: () => 18.0,
      );

      final entry = _items[index];
      entry.nameController.text = product.name;
      entry.hsnController.text = product.hsnSacCode;
      entry.rateController.text = defaultRate > 0
          ? (defaultRate == defaultRate.roundToDouble() ? defaultRate.toInt().toString() : defaultRate.toString())
          : '0';
      entry.unit = unitVal;
      entry.gstRate = gstVal;
    });
  }

  void _openCatalogPicker({int? targetItemIndex}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        String selectedCategory = 'All';
        final searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            final productProvider = context.watch<ProductProvider>();
            final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

            final filteredProducts = productProvider.products.where((p) {
              final matchesCategory = selectedCategory == 'All' || p.category == selectedCategory;
              final q = searchQuery.toLowerCase().trim();
              final matchesQuery = q.isEmpty ||
                  p.name.toLowerCase().contains(q) ||
                  p.sku.toLowerCase().contains(q) ||
                  p.hsnSacCode.toLowerCase().contains(q);
              return matchesCategory && matchesQuery;
            }).toList();

            final categories = [
              'All',
              ...productProvider.products
                  .map((p) => p.category)
                  .where((c) => c.isNotEmpty)
                  .toSet()
            ];

            return SafeArea(
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.75,
                minChildSize: 0.4,
                maxChildSize: 0.95,
                builder: (_, scrollController) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              targetItemIndex != null
                                  ? 'Select Item for Line #${targetItemIndex + 1}'
                                  : 'Select Item from Catalog',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by item name, SKU, or HSN...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            isDense: true,
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      searchController.clear();
                                      setModalState(() => searchQuery = '');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (val) {
                            setModalState(() => searchQuery = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (categories.length > 1)
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: categories.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (_, idx) {
                              final cat = categories[idx];
                              final isSelected = cat == selectedCategory;
                              return ChoiceChip(
                                label: Text(cat, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                selected: isSelected,
                                onSelected: (_) {
                                  setModalState(() => selectedCategory = cat);
                                },
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      Expanded(
                        child: productProvider.isLoading && productProvider.products.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : filteredProducts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                                        const SizedBox(height: 12),
                                        Text(
                                          searchQuery.isEmpty ? 'No products available' : 'No products matching "$searchQuery"',
                                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    itemCount: filteredProducts.length,
                                    separatorBuilder: (_, _) => const Divider(height: 1),
                                    itemBuilder: (_, idx) {
                                      final product = filteredProducts[idx];
                                      final double displayPrice = product.purchasePrice > 0 ? product.purchasePrice : product.sellingPrice;
                                      return ListTile(
                                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        subtitle: Text(
                                          'SKU: ${product.sku.isNotEmpty ? product.sku : 'N/A'}${product.hsnSacCode.isNotEmpty ? ' • HSN: ${product.hsnSacCode}' : ''} • Stock: ${product.stock} ${product.unitAbbreviation}',
                                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currencyFormat.format(displayPrice),
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.primary),
                                            ),
                                            Text(
                                              'GST: ${product.gst.toInt()}%',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          if (targetItemIndex != null && targetItemIndex < _items.length) {
                                            _populateProductAtIndex(targetItemIndex, product);
                                          } else {
                                            _addProductItem(product);
                                          }
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _openAddPartyDialog({String? initialName}) async {
    final newCustomer = await showDialog<Customer>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => AddCustomerDialog(initialName: initialName),
    );

    if (newCustomer != null && mounted) {
      setState(() {
        _selectedCustomer = newCustomer;
        _selectedVendorId = newCustomer.id;
        _selectedVendorName = newCustomer.name.isNotEmpty ? newCustomer.name : newCustomer.company;
        _vendorSearchController.text = _selectedVendorName;
      });
    }
  }


  void _simulateAddAttachment() {
    final fileName = 'Attachment_${_attachedFiles.length + 1}_spec.pdf';
    setState(() {
      _attachedFiles.add(fileName);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attached "$fileName"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_selectedVendorName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a customer name.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_poNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase order number cannot be empty.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the purchase order.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate item names
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item #${i + 1} must have a name/description.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final parsedItems = _items.map((it) => it.toModel()).toList();

    final order = PurchaseOrder(
      id: widget.initialOrder?.id ?? '',
      poNumber: _poNumberController.text.trim(),
      vendorId: _selectedVendorId ?? '',
      vendorName: _selectedVendorName.trim(),
      category: _selectedCategory,
      purchaseDate: _purchaseDate,
      referenceNumber: _referenceController.text.trim(),
      items: parsedItems,
      notes: _notesController.text.trim(),
      internalNote: _internalNoteController.text.trim(),
      termsAndConditions: _termsController.text.trim(),
      attachments: _attachedFiles,
      subtotal: _subtotal,
      totalDiscount: _totalDiscount,
      totalTax: _totalTax,
      totalAmount: _grandTotal,
      gstRate: _items.isNotEmpty ? _items.first.gstRate : 0.0,
      paymentMode: _paymentMode,
      status: _status,
      createdAt: widget.initialOrder?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = context.read<PurchaseOrderProvider>();
    PurchaseOrder? savedOrder;
    if (widget.isEditing) {
      final ok = await provider.updateOrder(order);
      if (ok) savedOrder = order;
    } else {
      savedOrder = await provider.createOrder(order);
    }

    if (!mounted) return;

    if (savedOrder == null && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${provider.errorMessage}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final displayPoNumber =
        savedOrder?.poNumber.isNotEmpty == true ? savedOrder!.poNumber : order.poNumber;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'Purchase Order "$displayPoNumber" updated successfully!'
              : 'Purchase Order "$displayPoNumber" created successfully!',
        ),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context, savedOrder ?? order);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Design tokens matching NewVendorScreen
    const labelBlue = Color(0xFF2563EB);
    const requiredRed = Color(0xFFEF4444);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final underlineColor = isDark ? Colors.white24 : const Color(0xFFCBD5E1);
    final appBarBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditing ? 'Edit Purchase Order' : 'New Purchase Order',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          Consumer<PurchaseOrderProvider>(
            builder: (context, poProv, _) {
              return TextButton(
                onPressed: poProv.isSaving ? null : _handleSave,
                child: poProv.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'SAVE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark ? AppColors.lightPrimary : const Color(0xFF1E293B),
                        ),
                      ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Forms & Items & Notes)
                            Expanded(
                              flex: 65,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildVendorDetailsCard(
                                          cardBg,
                                          cardBorder,
                                          underlineColor,
                                          labelBlue,
                                          requiredRed,
                                          isDark,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildPurchaseOrderDetailsCard(
                                          cardBg,
                                          cardBorder,
                                          underlineColor,
                                          labelBlue,
                                          requiredRed,
                                          isDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildItemsCard(
                                    cardBg,
                                    cardBorder,
                                    underlineColor,
                                    labelBlue,
                                    requiredRed,
                                    isDark,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTermsAndNotesCard(
                                    cardBg,
                                    cardBorder,
                                    underlineColor,
                                    labelBlue,
                                    isDark,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildAttachmentsCard(
                                    cardBg,
                                    cardBorder,
                                    labelBlue,
                                    isDark,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Right Column (Purchase Summary & Actions)
                            Expanded(
                              flex: 35,
                              child: _buildSummaryAndActionCard(
                                cardBg,
                                cardBorder,
                                underlineColor,
                                labelBlue,
                                requiredRed,
                                isDark,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildVendorDetailsCard(
                              cardBg,
                              cardBorder,
                              underlineColor,
                              labelBlue,
                              requiredRed,
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildPurchaseOrderDetailsCard(
                              cardBg,
                              cardBorder,
                              underlineColor,
                              labelBlue,
                              requiredRed,
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildItemsCard(
                              cardBg,
                              cardBorder,
                              underlineColor,
                              labelBlue,
                              requiredRed,
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildTermsAndNotesCard(
                              cardBg,
                              cardBorder,
                              underlineColor,
                              labelBlue,
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildAttachmentsCard(
                              cardBg,
                              cardBorder,
                              labelBlue,
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryAndActionCard(
                              cardBg,
                              cardBorder,
                              underlineColor,
                              labelBlue,
                              requiredRed,
                              isDark,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // CARD 1: Vendor Details
  // -------------------------------------------------------------
  Widget _buildVendorDetailsCard(
    Color cardBg,
    Color cardBorder,
    Color underlineColor,
    Color labelBlue,
    Color requiredRed,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded, color: labelBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Vendor Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CUSTOMER NAME * (Dynamic Autocomplete exactly like Invoice)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Customer Name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: labelBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('*', style: TextStyle(color: requiredRed, fontWeight: FontWeight.bold)),
                ],
              ),
              if (_selectedCustomer != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCustomer = null;
                      _selectedVendorId = null;
                      _selectedVendorName = '';
                      _vendorSearchController.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Change Customer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: () => _openAddPartyDialog(initialName: _vendorSearchController.text.trim()),
                  icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Add New Customer',
                ),
            ],
          ),
          const SizedBox(height: 6),

          if (_selectedCustomer == null)
            CustomerSearchField(
              controller: _vendorSearchController,
              initialSelected: null,
              onSelected: (customer) {
                setState(() {
                  _selectedCustomer = customer;
                  _selectedVendorId = customer?.id;
                  _selectedVendorName = customer?.name ?? '';
                  if (customer != null) {
                    _vendorSearchController.text = customer.name;
                  }
                });
              },
              onChanged: (text) {
                setState(() {
                  _selectedVendorName = text;
                  if (_selectedCustomer != null && _selectedCustomer!.name != text) {
                    _selectedCustomer = null;
                    _selectedVendorId = null;
                  }
                });
              },
              onCreateNewTap: (query) {
                _openAddPartyDialog(initialName: query);
              },
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCustomer!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_selectedCustomer!.company.isNotEmpty && _selectedCustomer!.company != _selectedCustomer!.name) ...[
                          const SizedBox(height: 2),
                          Text(
                            _selectedCustomer!.company,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (_selectedCustomer!.phone.isNotEmpty || _selectedCustomer!.gstNo.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _selectedCustomer!.phone.isNotEmpty
                                ? '📞 ${_selectedCustomer!.phone}'
                                : 'GSTIN: ${_selectedCustomer!.gstNo}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 18),

          // CATEGORY *
          Row(
            children: [
              const Text(
                'CATEGORY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 4),
              Text('*', style: TextStyle(color: requiredRed, fontWeight: FontWeight.bold)),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            isDense: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: underlineColor, width: 1.2),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: labelBlue, width: 1.5),
              ),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 20),
            items: _categories.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text(c, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CARD 2: Purchase Order Details
  // -------------------------------------------------------------
  Widget _buildPurchaseOrderDetailsCard(
    Color cardBg,
    Color cardBorder,
    Color underlineColor,
    Color labelBlue,
    Color requiredRed,
    bool isDark,
  ) {
    final dateDisplay = DateFormat('dd-MM-yyyy').format(_purchaseDate);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: labelBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Purchase Order Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // PURCHASE ORDER # *
          Row(
            children: [
              const Text(
                'PURCHASE ORDER #',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 4),
              Text('*', style: TextStyle(color: requiredRed, fontWeight: FontWeight.bold)),
            ],
          ),
          TextField(
            controller: _poNumberController,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: underlineColor, width: 1.2),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: labelBlue, width: 1.5),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.autorenew_rounded, size: 20, color: Color(0xFF64748B)),
                tooltip: 'Regenerate PO Number',
                onPressed: () {
                  final next = context.read<PurchaseOrderProvider>().getNextPoNumber();
                  _poNumberController.text = next;
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // PURCHASE DATE *
          Row(
            children: [
              const Text(
                'PURCHASE DATE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 4),
              Text('*', style: TextStyle(color: requiredRed, fontWeight: FontWeight.bold)),
            ],
          ),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: underlineColor, width: 1.2),
                ),
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF64748B)),
              ),
              child: Text(
                dateDisplay,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // REFERENCE #
          const Text(
            'REFERENCE #',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
          ),
          TextField(
            controller: _referenceController,
            decoration: InputDecoration(
              hintText: 'Reference or bill number',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: underlineColor, width: 1.2),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: labelBlue, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CARD 3: Items Purchased
  // -------------------------------------------------------------
  Widget _buildItemsCard(
    Color cardBg,
    Color cardBorder,
    Color underlineColor,
    Color labelBlue,
    Color requiredRed,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: labelBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Items Purchased',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _openCatalogPicker(),
                    icon: const Icon(Icons.apps_rounded, size: 16, color: Color(0xFF2563EB)),
                    label: const Text('Browse Catalog', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Text(
                      'Total Items: ${_items.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items search from catalog (matching Invoices)
          ProductSearchField(
            onSelected: (product) => _addProductItem(product),
          ),
          const SizedBox(height: 16),

          // Items List & Actions
          if (_items.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                return _buildItemRow(
                  index,
                  _items[index],
                  cardBorder,
                  underlineColor,
                  labelBlue,
                  isDark,
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: const Text('Add Another Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: labelBlue,
                  side: BorderSide(color: labelBlue.withValues(alpha: 0.4), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: isDark ? labelBlue.withValues(alpha: 0.08) : const Color(0xFFEFF6FF),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 36, color: labelBlue.withValues(alpha: 0.4)),
                  const SizedBox(height: 10),
                  Text(
                    'No items added yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search for a product above or browse the catalog to add items',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Custom Item Manually', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(foregroundColor: labelBlue),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(
    int index,
    _ItemFormEntry item,
    Color cardBorder,
    Color underlineColor,
    Color labelBlue,
    bool isDark,
  ) {
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final fieldBorder = isDark ? Colors.white12 : const Color(0xFFCBD5E1);

    InputDecoration buildInputDecoration({
      String? hintText,
      Widget? prefixIcon,
      Widget? suffixIcon,
      EdgeInsetsGeometry? contentPadding,
    }) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
        isDense: true,
        filled: true,
        fillColor: inputBg,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: labelBlue, width: 1.5),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D31) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Index Badge, Item Title, Amount Pill & Delete Button
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: labelBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: labelBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Item #${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _currencyFormat.format(item.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                    tooltip: 'Remove Item',
                    onPressed: () => _removeItem(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Row 1: Item Details & HSN/SAC
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text(
                              'ITEM DETAILS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(width: 4),
                            Text('*', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: item.nameController,
                          style: const TextStyle(fontSize: 13),
                          decoration: buildInputDecoration(
                            hintText: 'Item name or description',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                              tooltip: 'Pick from product catalog',
                              onPressed: () => _openCatalogPicker(targetItemIndex: index),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HSN/SAC',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: item.hsnController,
                          style: const TextStyle(fontSize: 13),
                          decoration: buildInputDecoration(
                            hintText: 'HSN code',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Quantities, Rates, GST & Discount
              if (isCompact) ...[
                // Row A: QTY, UNIT, RATE
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QTY',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: item.qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 13),
                            decoration: buildInputDecoration(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UNIT',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: item.unit,
                            isDense: true,
                            decoration: buildInputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            icon: const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF64748B)),
                            items: _units.map((u) {
                              return DropdownMenuItem(
                                value: u,
                                child: Text(u, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => item.unit = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RATE (₹)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: item.rateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 13),
                            decoration: buildInputDecoration(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Row B: GST RATE & DISCOUNT
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GST (%)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<double>(
                            initialValue: item.gstRate,
                            isDense: true,
                            decoration: buildInputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            icon: const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF64748B)),
                            items: _gstRates.map((g) {
                              return DropdownMenuItem(
                                value: g,
                                child: Text('${g.toInt()}%', style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => item.gstRate = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DISCOUNT',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: item.discountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 13),
                            decoration: buildInputDecoration(
                              contentPadding: const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 4),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      item.discountType = item.discountType == 'amount' ? 'percentage' : 'amount';
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: labelBlue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: labelBlue.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      item.discountType == 'amount' ? '₹' : '%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: labelBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Wide: All 5 in 1 balanced row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QTY
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QTY',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: item.qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 13),
                            decoration: buildInputDecoration(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // UNIT
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UNIT',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: item.unit,
                            isDense: true,
                            decoration: buildInputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            icon: const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF64748B)),
                            items: _units.map((u) {
                              return DropdownMenuItem(
                                value: u,
                                child: Text(u, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => item.unit = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // RATE
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RATE (₹)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: item.rateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 13),
                            decoration: buildInputDecoration(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // GST
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GST (%)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<double>(
                            initialValue: item.gstRate,
                            isDense: true,
                            decoration: buildInputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            icon: const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF64748B)),
                            items: _gstRates.map((g) {
                              return DropdownMenuItem(
                                value: g,
                                child: Text('${g.toInt()}%', style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => item.gstRate = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // DISCOUNT
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DISCOUNT',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: item.discountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 13),
                            decoration: buildInputDecoration(
                              contentPadding: const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 4),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      item.discountType = item.discountType == 'amount' ? 'percentage' : 'amount';
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: labelBlue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: labelBlue.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      item.discountType == 'amount' ? '₹' : '%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: labelBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Bottom Calculation Breakdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Base: ${_currencyFormat.format(item.baseAmount)}${item.discountAmount > 0 ? ' • Disc: -${_currencyFormat.format(item.discountAmount)}' : ''} • Tax: +${_currencyFormat.format(item.taxAmount)}',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                    ),
                    Text(
                      'Total: ${_currencyFormat.format(item.totalAmount)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // CARD 4: Terms & Conditions & Notes
  // -------------------------------------------------------------
  Widget _buildTermsAndNotesCard(
    Color cardBg,
    Color cardBorder,
    Color underlineColor,
    Color labelBlue,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: labelBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // NOTES & INTERNAL NOTE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NOTES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add any notes or special instructions...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INTERNAL NOTE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _internalNoteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'For internal use only...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // TERMS AND CONDITIONS
          const Text(
            'TERMS AND CONDITIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _termsController,
            maxLines: 5,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cardBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CARD 5: Attach File(s)
  // -------------------------------------------------------------
  Widget _buildAttachmentsCard(
    Color cardBg,
    Color cardBorder,
    Color labelBlue,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file_rounded, color: labelBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Attach File(s)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Upload Box
          InkWell(
            onTap: _simulateAddAttachment,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 36,
                    color: labelBlue,
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Click or drag file(s) here to upload\n',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                      children: const [
                        TextSpan(
                          text: 'Maximum file size: 5MB',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _simulateAddAttachment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Browse Files'),
                  ),
                ],
              ),
            ),
          ),

          if (_attachedFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attachedFiles.map((f) {
                return Chip(
                  avatar: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFFEF4444)),
                  label: Text(f, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  onDeleted: () {
                    setState(() => _attachedFiles.remove(f));
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CARD 6: Purchase Summary & Action
  // -------------------------------------------------------------
  Widget _buildSummaryAndActionCard(
    Color cardBg,
    Color cardBorder,
    Color underlineColor,
    Color labelBlue,
    Color requiredRed,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: labelBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Purchase Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Subtotal
          _buildSummaryRow('Subtotal', _currencyFormat.format(_subtotal), isDark: isDark),
          const SizedBox(height: 10),

          // Discount
          _buildSummaryRow(
            'Total Discount',
            '-${_currencyFormat.format(_totalDiscount)}',
            valueColor: const Color(0xFFEF4444),
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // Tax
          _buildSummaryRow('Total Tax (GST)', _currencyFormat.format(_totalTax), isDark: isDark),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14.0),
            child: Divider(height: 1),
          ),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                _currencyFormat.format(_grandTotal),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6D28D9),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // PAYMENT MODE *
          Row(
            children: [
              const Text(
                'Payment Mode',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 4),
              Text('*', style: TextStyle(color: requiredRed, fontWeight: FontWeight.bold)),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            isDense: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: underlineColor, width: 1.2),
              ),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 20),
            items: _paymentModes.map((m) {
              return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _paymentMode = val);
            },
          ),

          const SizedBox(height: 16),

          // STATUS *
          Row(
            children: [
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 4),
              Text('*', style: TextStyle(color: requiredRed, fontWeight: FontWeight.bold)),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: _status,
            isDense: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: underlineColor, width: 1.2),
              ),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 20),
            items: _statusOptions.map((s) {
              return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _status = val);
            },
          ),

          const SizedBox(height: 28),

          // Action Buttons: Cancel and Save Purchase Order
          Row(
            children: [
              Expanded(
                flex: 4,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Consumer<PurchaseOrderProvider>(
                  builder: (context, poProv, _) {
                    return ElevatedButton(
                      onPressed: poProv.isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D28D9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 1,
                      ),
                      child: poProv.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Save Purchase Order',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}

class _ItemFormEntry {
  final TextEditingController nameController;
  final TextEditingController hsnController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final TextEditingController discountController;
  String unit;
  double gstRate;
  String discountType;
  final VoidCallback onChanged;

  _ItemFormEntry({
    String name = '',
    String hsn = '',
    double qty = 1.0,
    this.unit = 'Nos',
    double rate = 0.0,
    this.gstRate = 0.0,
    double discount = 0.0,
    this.discountType = 'amount',
    required this.onChanged,
  })  : nameController = TextEditingController(text: name),
        hsnController = TextEditingController(text: hsn),
        qtyController = TextEditingController(text: qty > 0 ? (qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString()) : '1'),
        rateController = TextEditingController(text: rate > 0 ? (rate == rate.roundToDouble() ? rate.toInt().toString() : rate.toString()) : '0'),
        discountController = TextEditingController(text: discount > 0 ? discount.toString() : '0') {
    nameController.addListener(onChanged);
    hsnController.addListener(onChanged);
    qtyController.addListener(onChanged);
    rateController.addListener(onChanged);
    discountController.addListener(onChanged);
  }

  factory _ItemFormEntry.fromModel(PurchaseOrderItem item, {required VoidCallback onChanged}) {
    return _ItemFormEntry(
      name: item.name,
      hsn: item.hsnCode,
      qty: item.quantity,
      unit: item.unit,
      rate: item.rate,
      gstRate: item.gstRate,
      discount: item.discount,
      discountType: item.discountType,
      onChanged: onChanged,
    );
  }

  double get quantity => double.tryParse(qtyController.text.trim()) ?? 1.0;
  double get rate => double.tryParse(rateController.text.trim()) ?? 0.0;
  double get discount => double.tryParse(discountController.text.trim()) ?? 0.0;

  double get baseAmount => quantity * rate;

  double get discountAmount {
    if (discount <= 0) return 0.0;
    if (discountType == 'percentage') {
      return (baseAmount * (discount / 100)).clamp(0.0, baseAmount);
    }
    return discount.clamp(0.0, baseAmount);
  }

  double get taxableAmount => (baseAmount - discountAmount).clamp(0.0, double.infinity);
  double get taxAmount => taxableAmount * (gstRate / 100);
  double get totalAmount => taxableAmount + taxAmount;

  PurchaseOrderItem toModel() {
    return PurchaseOrderItem(
      id: 'item_${DateTime.now().microsecondsSinceEpoch}',
      name: nameController.text.trim(),
      hsnCode: hsnController.text.trim(),
      quantity: quantity,
      unit: unit,
      rate: rate,
      gstRate: gstRate,
      discount: discount,
      discountType: discountType,
    );
  }

  void dispose() {
    nameController.dispose();
    hsnController.dispose();
    qtyController.dispose();
    rateController.dispose();
    discountController.dispose();
  }
}
