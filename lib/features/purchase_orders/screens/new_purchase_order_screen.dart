import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../vendors/models/vendor.dart';
import '../../vendors/providers/vendor_provider.dart';
import '../../vendors/screens/new_vendor_screen.dart';
import '../models/purchase_order.dart';
import '../providers/purchase_order_provider.dart';

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

  // Vendor Details
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
  String _status = 'Pending';

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
    'Pending',
    'Approved',
    'Ordered',
    'Received',
    'Cancelled',
    'Draft',
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
    _status = initial?.status ?? 'Pending';

    if (initial != null && initial.items.isNotEmpty) {
      for (final item in initial.items) {
        _items.add(_ItemFormEntry.fromModel(item, onChanged: () => setState(() {})));
      }
    } else {
      // Default 1 empty item
      _items.add(_ItemFormEntry(onChanged: () => setState(() {})));
    }

    // Ensure vendors are loaded for selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().fetchVendors();
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
    if (_items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one item is required in the purchase order.')),
      );
      return;
    }
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
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

  void _openVendorPicker() {
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
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (_, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Vendor',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final newVendor = await Navigator.push<Vendor>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NewVendorScreen(),
                              ),
                            );
                            if (newVendor != null) {
                              setState(() {
                                _selectedVendorId = newVendor.id;
                                _selectedVendorName = newVendor.displayName;
                                _vendorSearchController.text = newVendor.displayName;
                              });
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('+ Add New Vendor'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Consumer<VendorProvider>(
                      builder: (_, vProv, _) {
                        final list = vProv.vendors;
                        if (list.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.storefront_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text('No vendors found'),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final newVendor = await Navigator.push<Vendor>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const NewVendorScreen(),
                                      ),
                                    );
                                    if (newVendor != null) {
                                      setState(() {
                                        _selectedVendorId = newVendor.id;
                                        _selectedVendorName = newVendor.displayName;
                                        _vendorSearchController.text = newVendor.displayName;
                                      });
                                    }
                                  },
                                  child: const Text('Create First Vendor'),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final vendor = list[i];
                            final isSelected = vendor.id == _selectedVendorId ||
                                vendor.displayName == _selectedVendorName;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDark ? Colors.white10 : const Color(0xFFEDE9FE),
                                child: Text(
                                  vendor.displayName.isNotEmpty
                                      ? vendor.displayName[0].toUpperCase()
                                      : 'V',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6D28D9),
                                  ),
                                ),
                              ),
                              title: Text(
                                vendor.displayName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                vendor.companyName.isNotEmpty
                                    ? vendor.companyName
                                    : (vendor.email.isNotEmpty ? vendor.email : 'Vendor Account'),
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB))
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedVendorId = vendor.id;
                                  _selectedVendorName = vendor.displayName;
                                  _vendorSearchController.text = vendor.displayName;
                                });
                                Navigator.pop(ctx);
                              },
                            );
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
          content: Text('Please select or enter a vendor name.'),
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
      paymentMode: _paymentMode,
      status: _status,
      createdAt: widget.initialOrder?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = context.read<PurchaseOrderProvider>();
    if (widget.isEditing) {
      await provider.updateOrder(order);
    } else {
      await provider.createOrder(order);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'Purchase Order "${order.poNumber}" updated successfully!'
              : 'Purchase Order "${order.poNumber}" created successfully!',
        ),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context, order);
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

          // VENDOR NAME *
          Row(
            children: [
              const Text(
                'VENDOR NAME',
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
          const SizedBox(height: 4),
          InkWell(
            onTap: _openVendorPicker,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: underlineColor, width: 1.2),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedVendorName.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedVendorId = null;
                            _selectedVendorName = '';
                            _vendorSearchController.clear();
                          });
                        },
                      ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                  ],
                ),
              ),
              child: Text(
                _selectedVendorName.isNotEmpty ? _selectedVendorName : 'Search or select vendors...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _selectedVendorName.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: _selectedVendorName.isNotEmpty
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                ),
              ),
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
          const SizedBox(height: 16),

          // Items List
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

          // Add Item Button
          OutlinedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('+ Add Item'),
            style: OutlinedButton.styleFrom(
              foregroundColor: labelBlue,
              side: BorderSide(color: labelBlue.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: labelBlue.withValues(alpha: 0.15),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Text(
                _currencyFormat.format(item.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                tooltip: 'Remove Item',
                onPressed: () => _removeItem(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ITEM DETAILS & HSN
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ITEM DETAILS *',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    TextField(
                      controller: item.nameController,
                      decoration: InputDecoration(
                        hintText: 'Item name / description',
                        hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                        isDense: true,
                        contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: underlineColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HSN/SAC',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    TextField(
                      controller: item.hsnController,
                      decoration: InputDecoration(
                        hintText: 'HSN code',
                        hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                        isDense: true,
                        contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: underlineColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // QTY, UNIT, RATE, GST, DISCOUNT
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              // QTY
              SizedBox(
                width: 75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('QTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    TextField(
                      controller: item.qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: underlineColor)),
                      ),
                    ),
                  ],
                ),
              ),

              // UNIT
              SizedBox(
                width: 85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('UNIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: item.unit,
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF64748B)),
                        items: _units.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => item.unit = val);
                        },
                      ),
                    ),
                    Container(height: 1.2, color: underlineColor),
                  ],
                ),
              ),

              // RATE (₹)
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RATE (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    TextField(
                      controller: item.rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: underlineColor)),
                      ),
                    ),
                  ],
                ),
              ),

              // GST (%)
              SizedBox(
                width: 85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GST (%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<double>(
                        value: item.gstRate,
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF64748B)),
                        items: _gstRates.map((g) {
                          return DropdownMenuItem(
                            value: g,
                            child: Text('${g.toInt()}%', style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              item.gstRate = val;
                            });
                          }
                        },
                      ),
                    ),
                    Container(height: 1.2, color: underlineColor),
                  ],
                ),
              ),

              // DISCOUNT
              SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('DISCOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        InkWell(
                          onTap: () {
                            setState(() {
                              item.discountType = item.discountType == 'amount' ? 'percentage' : 'amount';
                            });
                          },
                          child: Text(
                            item.discountType == 'amount' ? '₹' : '%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: labelBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: item.discountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: underlineColor)),
                        suffixText: item.discountType == 'amount' ? '₹' : '%',
                        suffixStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
