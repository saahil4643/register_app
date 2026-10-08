import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../customers/models/customer.dart';
import '../../customers/providers/customer_provider.dart';
import '../../customers/widgets/add_customer_dialog.dart';
import '../../invoices/providers/invoice_provider.dart';
import '../../invoices/widgets/customer_autocomplete.dart';
import '../../invoices/widgets/product_autocomplete.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/credit_note.dart';
import '../providers/credit_note_provider.dart';

class NewCreditNoteScreen extends StatefulWidget {
  final bool isEditing;
  final String? creditNoteId;

  const NewCreditNoteScreen({
    super.key,
    this.isEditing = false,
    this.creditNoteId,
  });

  @override
  State<NewCreditNoteScreen> createState() => _NewCreditNoteScreenState();
}

class _NewCreditNoteScreenState extends State<NewCreditNoteScreen> {
  final _formKey = GlobalKey<FormState>();

  // Customer options
  String _customerType = 'Customer'; // 'Customer' or 'Business' (Customer is selected in screenshot)
  late final TextEditingController _customerNameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _gstinController;
  late final TextEditingController _emailController;
  late final TextEditingController _billingAddressController;
  late final TextEditingController _shippingAddressController;
  bool _shippingSameAsBilling = false; // in screenshot it's unchecked with input below
  Customer? _selectedCustomer;
  bool _showAdditionalCustomerDetails = false;

  // Credit Note Details
  late final TextEditingController _creditNoteNumberController;
  late DateTime _creditNoteDate;
  late final TextEditingController _referenceInvoiceController;
  late final TextEditingController _salespersonController;
  late final TextEditingController _referenceController;
  late final TextEditingController _reasonController;

  // Items
  final List<_ReturnedItemRowState> _items = [];

  // Notes & Conditions
  late final TextEditingController _notesController;
  late final TextEditingController _internalNotesController;
  late final TextEditingController _termsController;

  // Summary & Status
  bool _roundOff = true;
  CreditNoteStatus _status = CreditNoteStatus.open;

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd-MM-yyyy');

  final List<String> _unitOptions = ['Nos', 'Pcs', 'Box', 'Kg', 'Mtr', 'Set', 'Unit', 'Hrs', 'Ltr'];
  final List<double> _gstOptions = [0.0, 5.0, 12.0, 18.0, 28.0];
  final List<String> _salespersonsList = [
    'General Sales',
    'Rahul Sharma',
    'Priya Patel',
    'Amit Kumar',
    'Neha Verma',
  ];

  final List<String> _commonReasons = [
    'Damaged goods return',
    'Order cancellation',
    'Defective goods',
    'Overbilling / Pricing error',
    'Discount adjustment',
    'Service dissatisfaction',
    'Other',
  ];

  static const String _defaultTerms =
      '1. Credit balance must be applied to future invoices within 180 days.\n'
      '2. Refunds on credit notes are subject to review.\n'
      '3. Original invoice details must accompany any disputes.';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _creditNoteDate = now;

    _customerNameController = TextEditingController();
    _mobileController = TextEditingController();
    _gstinController = TextEditingController();
    _emailController = TextEditingController();
    _billingAddressController = TextEditingController();
    _shippingAddressController = TextEditingController();

    _creditNoteNumberController = TextEditingController();
    _referenceInvoiceController = TextEditingController();
    _salespersonController = TextEditingController();
    _referenceController = TextEditingController();
    _reasonController = TextEditingController(text: 'Damaged goods return');

    _notesController = TextEditingController();
    _internalNotesController = TextEditingController();
    _termsController = TextEditingController(text: _defaultTerms);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final creditNoteProvider = context.read<CreditNoteProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final prefix = settingsProvider.financialSettings?.creditNotePrefix ?? 'CN';

    if (widget.isEditing && widget.creditNoteId != null) {
      final detailed = await creditNoteProvider.fetchCreditNoteDetails(widget.creditNoteId!);
      if (detailed != null && mounted) {
        _populateFromCreditNote(detailed);
        return;
      }
      final existing = creditNoteProvider.getCreditNoteById(widget.creditNoteId!);
      if (existing != null && mounted) {
        _populateFromCreditNote(existing);
        return;
      }
    }

    _creditNoteNumberController.text = creditNoteProvider.getNextCreditNoteNumber(prefix: prefix);
    if (mounted) setState(() {});
  }

  void _populateFromCreditNote(CreditNote cn) {
    _customerType = cn.customerType;
    _selectedCustomer = cn.customer;
    if (_selectedCustomer == null && cn.customerId != null && cn.customerId!.isNotEmpty) {
      final customerProvider = context.read<CustomerProvider>();
      try {
        _selectedCustomer = customerProvider.customers.firstWhere((c) => c.id == cn.customerId);
      } catch (_) {
        _selectedCustomer = Customer(
          id: cn.customerId!,
          name: cn.customerName,
          email: cn.email,
          phone: cn.mobileNumber,
          address: cn.billingAddress,
          gstNumber: cn.gstin,
          createdAt: DateTime.now(),
        );
      }
    }
    _customerNameController.text = cn.customerName;
    _mobileController.text = cn.mobileNumber;
    _gstinController.text = cn.gstin;
    _emailController.text = cn.email;
    _billingAddressController.text = cn.billingAddress;
    _shippingAddressController.text = cn.shippingAddress;
    _shippingSameAsBilling = cn.shippingSameAsBilling;
    _showAdditionalCustomerDetails = cn.email.isNotEmpty || cn.gstin.isNotEmpty || cn.billingAddress.isNotEmpty;

    _creditNoteNumberController.text = cn.creditNoteNumber;
    _creditNoteDate = cn.creditNoteDate;
    _referenceInvoiceController.text = cn.referenceInvoice;
    _salespersonController.text = cn.salesperson;
    _referenceController.text = cn.referenceNumber;
    _reasonController.text = cn.reason.isNotEmpty ? cn.reason : 'Damaged goods return';

    _notesController.text = cn.notes;
    _internalNotesController.text = cn.internalNotes;
    _termsController.text = cn.termsAndConditions.isNotEmpty ? cn.termsAndConditions : _defaultTerms;

    _status = cn.status;
    _roundOff = cn.isRoundOff;

    if (cn.items.isNotEmpty) {
      _items.clear();
      for (final item in cn.items) {
        _items.add(_ReturnedItemRowState.fromCreditNoteItem(item, onChanged: () => setState(() {})));
      }
    }
    setState(() {});
  }

  void _addNewItem() {
    setState(() {
      _items.add(_ReturnedItemRowState(
        onChanged: () => setState(() {}),
      ));
    });
  }

  void _removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      setState(() {
        final removed = _items.removeAt(index);
        removed.dispose();
      });
    }
  }

  void _onCustomerSelected(Customer? customer) {
    setState(() {
      _selectedCustomer = customer;
      if (customer != null) {
        final custName = customer.name.isNotEmpty ? customer.name : customer.companyName;
        _customerNameController.text = custName;
        _mobileController.text = customer.phone;
        _emailController.text = customer.email;
        _gstinController.text = customer.gstNumber;
        _billingAddressController.text = customer.address;
        _shippingAddressController.text = customer.shippingAddressLine1.isNotEmpty
            ? customer.shippingAddressLine1
            : customer.address;
        _shippingSameAsBilling = customer.shippingSameAsBilling;
        _customerType = customer.customerType.toLowerCase() == 'business' ? 'Business' : 'Customer';
      } else {
        _customerNameController.clear();
        _mobileController.clear();
        _emailController.clear();
        _gstinController.clear();
        _billingAddressController.clear();
        _shippingAddressController.clear();
        _showAdditionalCustomerDetails = false;
      }
    });
  }

  Future<void> _openAddCustomerDialog({String? initialName}) async {
    final newCustomer = await showDialog<Customer>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => AddCustomerDialog(initialName: initialName),
    );

    if (newCustomer != null && mounted) {
      _onCustomerSelected(newCustomer);
    }
  }

  // Calculations
  double get _subtotal => _items.fold(0.0, (sum, i) => sum + i.subtotal);
  double get _taxableAmount => _items.fold(0.0, (sum, i) => sum + i.taxableAmount);
  double get _totalGst => _items.fold(0.0, (sum, i) => sum + i.taxAmount);

  double get _rawGrandTotal => _taxableAmount + _totalGst;
  double get _grandTotal => _roundOff ? _rawGrandTotal.roundToDouble() : _rawGrandTotal;
  double get _roundOffDiff => _roundOff ? (_rawGrandTotal.roundToDouble() - _rawGrandTotal) : 0.0;

  Future<void> _pickCreditNoteDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _creditNoteDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _creditNoteDate = picked;
      });
    }
  }

  Future<void> _saveCreditNote({CreditNoteStatus? overrideStatus}) async {
    Customer? selectedCustomer = _selectedCustomer;
    if (selectedCustomer == null && _customerNameController.text.trim().isNotEmpty) {
      final customerProvider = context.read<CustomerProvider>();
      try {
        selectedCustomer = customerProvider.customers.firstWhere(
          (c) => c.name.toLowerCase() == _customerNameController.text.trim().toLowerCase() ||
                 c.companyName.toLowerCase() == _customerNameController.text.trim().toLowerCase(),
        );
      } catch (_) {}
    }

    if (_customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or select a customer / business name.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an existing customer or create a new customer.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_items.isEmpty || _items.every((i) => i.nameController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least one valid returned item.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final creditNoteProvider = context.read<CreditNoteProvider>();
    final creditNoteId = widget.creditNoteId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final creditNoteItems = _items
        .where((i) => i.nameController.text.trim().isNotEmpty || i.descController.text.trim().isNotEmpty)
        .map((i) => i.toCreditNoteItem())
        .toList();

    final creditNote = CreditNote(
      id: creditNoteId,
      creditNoteNumber: _creditNoteNumberController.text.trim().isNotEmpty
          ? _creditNoteNumberController.text.trim()
          : creditNoteProvider.getNextCreditNoteNumber(),
      customer: selectedCustomer,
      customerId: selectedCustomer.id,
      customerType: _customerType,
      customerName: _customerNameController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      gstin: _gstinController.text.trim(),
      email: _emailController.text.trim(),
      billingAddress: _billingAddressController.text.trim(),
      shippingAddress: _shippingSameAsBilling
          ? _billingAddressController.text.trim()
          : _shippingAddressController.text.trim(),
      shippingSameAsBilling: _shippingSameAsBilling,
      creditNoteDate: _creditNoteDate,
      referenceInvoice: _referenceInvoiceController.text.trim(),
      salesperson: _salespersonController.text.trim(),
      referenceNumber: _referenceController.text.trim(),
      reason: _reasonController.text.trim(),
      items: creditNoteItems,
      notes: _notesController.text.trim(),
      internalNotes: _internalNotesController.text.trim(),
      termsAndConditions: _termsController.text.trim(),
      status: overrideStatus ?? _status,
      isRoundOff: _roundOff,
      roundOff: _roundOffDiff,
      totalAmount: _grandTotal,
      currency: 'INR',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await creditNoteProvider.saveCreditNote(creditNote);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Credit Note ${creditNote.creditNoteNumber} saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(creditNoteProvider.errorMessage ?? 'Failed to save credit note.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showCustomizeNumberDialog() {
    final controller = TextEditingController(text: _creditNoteNumberController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customize Credit Note Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a custom credit note number or prefix format.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Credit Note Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _creditNoteNumberController.text = controller.text.trim();
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _openProductPicker({int? targetIndex}) {
    final productProvider = context.read<ProductProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = productProvider.products.where((p) {
              final q = query.toLowerCase().trim();
              return q.isEmpty ||
                  p.name.toLowerCase().contains(q) ||
                  p.sku.toLowerCase().contains(q) ||
                  p.hsnSacCode.toLowerCase().contains(q);
            }).toList();

            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Product to Return',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products by name, SKU or HSN...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      onChanged: (val) => setModalState(() => query = val),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('No products found', style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final product = filtered[idx];
                                return ListTile(
                                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    'HSN: ${product.hsnSacCode.isNotEmpty ? product.hsnSacCode : 'N/A'} • Unit: ${product.unitAbbreviation}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    _currencyFormat.format(product.sellingPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      if (targetIndex != null && targetIndex < _items.length) {
                                        _items[targetIndex].populateFromProduct(product);
                                      } else {
                                        final emptyIndex = _items.indexWhere(
                                          (i) => i.nameController.text.trim().isEmpty && i.price <= 0,
                                        );
                                        if (emptyIndex != -1) {
                                          _items[emptyIndex].populateFromProduct(product);
                                        } else {
                                          final newRow = _ReturnedItemRowState(
                                            onChanged: () => setState(() {}),
                                          )..populateFromProduct(product);
                                          _items.add(newRow);
                                        }
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _mobileController.dispose();
    _gstinController.dispose();
    _emailController.dispose();
    _billingAddressController.dispose();
    _shippingAddressController.dispose();

    _creditNoteNumberController.dispose();
    _referenceInvoiceController.dispose();
    _salespersonController.dispose();
    _referenceController.dispose();
    _reasonController.dispose();

    _notesController.dispose();
    _internalNotesController.dispose();
    _termsController.dispose();

    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardBg,
        title: Text(
          widget.isEditing ? 'Edit Credit Note' : 'New Credit Note',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _saveCreditNote(overrideStatus: CreditNoteStatus.draft),
            child: const Text(
              'SAVE AS DRAFT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'reset') {
                setState(() {
                  _customerNameController.clear();
                  _mobileController.clear();
                  _gstinController.clear();
                  _emailController.clear();
                  _billingAddressController.clear();
                  _shippingAddressController.clear();
                  _referenceInvoiceController.clear();
                  _items.clear();
                  _addNewItem();
                });
              } else if (val == 'draft') {
                _saveCreditNote(overrideStatus: CreditNoteStatus.draft);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'draft', child: Text('Save as Draft')),
              const PopupMenuItem(value: 'reset', child: Text('Reset Form')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: cardBorder, height: 1.0),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 950;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TOP SECTION: Customer Details + Credit Note Details
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 65,
                              child: _buildCustomerCard(cardBg, cardBorder, isDark),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 35,
                              child: _buildCreditNoteDetailsCard(cardBg, cardBorder, isDark),
                            ),
                          ],
                        )
                      else ...[
                        _buildCustomerCard(cardBg, cardBorder, isDark),
                        const SizedBox(height: 16),
                        _buildCreditNoteDetailsCard(cardBg, cardBorder, isDark),
                      ],

                      const SizedBox(height: 20),

                      // MIDDLE SECTION: Returned Items (Full Width)
                      _buildReturnedItemsCard(cardBg, cardBorder, isDark),

                      const SizedBox(height: 20),

                      // BOTTOM SECTION: Notes & Conditions + Credit Note Summary & Status
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 65,
                              child: _buildNotesAndConditionsCard(cardBg, cardBorder, isDark),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 35,
                              child: _buildSummaryAndStatusCard(cardBg, cardBorder, isDark),
                            ),
                          ],
                        )
                      else ...[
                        _buildNotesAndConditionsCard(cardBg, cardBorder, isDark),
                        const SizedBox(height: 16),
                        _buildSummaryAndStatusCard(cardBg, cardBorder, isDark),
                      ],
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

  // ─────────────────────────────────────────────────────────────────────────
  // CARD 1: CUSTOMER DETAILS (Image Match)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCustomerCard(Color cardBg, Color cardBorder, bool isDark) {
    final customer = _selectedCustomer;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title and action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('Customer Name *'),
              if (customer == null)
                IconButton(
                  onPressed: () => _openAddCustomerDialog(),
                  icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 20),
                  tooltip: 'Add New Customer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                TextButton(
                  onPressed: () => _onCustomerSelected(null),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Change Customer',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Search Field or Selected Box
          if (customer == null)
            CustomerSearchField(
              controller: _customerNameController,
              initialSelected: customer,
              onSelected: _onCustomerSelected,
              hintText: 'Customer Name',
              labelText: null,
              onCreateNewTap: (query) {
                _openAddCustomerDialog(initialName: query);
              },
              onChanged: (val) {
                setState(() {});
              },
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF2563EB), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      customer.displayName.isNotEmpty
                          ? customer.displayName
                          : (_customerNameController.text.isNotEmpty
                              ? _customerNameController.text
                              : customer.name),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _divider(isDark),
            const SizedBox(height: 12),

            // Mobile Number with Auto-filled badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('Mobile Number'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Auto-filled',
                    style: TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            _cleanInputField(
              controller: _mobileController,
              hint: 'Enter mobile number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),

            // Collapsible Additional Details
            InkWell(
              onTap: () {
                setState(() {
                  _showAdditionalCustomerDetails = !_showAdditionalCustomerDetails;
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _showAdditionalCustomerDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'More details (GSTIN, Address, Email)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showAdditionalCustomerDetails) ...[
              const SizedBox(height: 8),
              _divider(isDark),
              const SizedBox(height: 8),

              // Customer Type
              _buildLabel('Customer Type'),
              const SizedBox(height: 4),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Business', style: TextStyle(fontSize: 12)),
                    selected: _customerType == 'Business',
                    selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                    onSelected: (val) {
                      if (val) setState(() => _customerType = 'Business');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Individual / Consumer', style: TextStyle(fontSize: 12)),
                    selected: _customerType != 'Business',
                    selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                    onSelected: (val) {
                      if (val) setState(() => _customerType = 'Customer');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Email Address
              _buildLabel('Email Address'),
              _cleanInputField(
                controller: _emailController,
                hint: 'name@business.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),

              // GSTIN
              _buildLabel('GSTIN'),
              _cleanInputField(
                controller: _gstinController,
                hint: '27AAAAA0000A1Z5',
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 10),

              // Billing Address
              _buildLabel('Billing Address'),
              _cleanInputField(
                controller: _billingAddressController,
                hint: 'Enter full billing address',
                maxLines: 2,
              ),
              const SizedBox(height: 10),

              // Shipping Address
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Shipping same as billing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Switch(
                    value: _shippingSameAsBilling,
                    activeThumbColor: const Color(0xFF2563EB),
                    onChanged: (val) {
                      setState(() {
                        _shippingSameAsBilling = val;
                        if (val) {
                          _shippingAddressController.text = _billingAddressController.text;
                        }
                      });
                    },
                  ),
                ],
              ),
              if (!_shippingSameAsBilling) ...[
                const SizedBox(height: 6),
                _buildLabel('Shipping Address'),
                _cleanInputField(
                  controller: _shippingAddressController,
                  hint: 'Enter shipping address',
                  maxLines: 2,
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2563EB),
      ),
    );
  }

  Widget _cleanInputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD 2: CREDIT NOTE DETAILS CARD (Right Side)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCreditNoteDetailsCard(Color cardBg, Color cardBorder, bool isDark) {
    final invoiceProvider = context.watch<InvoiceProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Credit Note Details
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.assignment_return_rounded, color: Color(0xFF7C3AED), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Credit Note Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Credit Note Number with Gear Icon
          _buildFieldLabel('CREDIT NOTE NUMBER *'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _creditNoteNumberController,
                  hintText: 'CN-001',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showCustomizeNumberDialog,
                icon: const Icon(Icons.settings_outlined, size: 20, color: Color(0xFF6B7280)),
                tooltip: 'Customize number format',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Credit Note Date
          _buildFieldLabel('CREDIT NOTE DATE *'),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickCreditNoteDate,
            borderRadius: BorderRadius.circular(6),
            child: _buildDateDisplayBox(_dateFormat.format(_creditNoteDate), Icons.calendar_today_outlined, isDark),
          ),
          const SizedBox(height: 14),

          // Reference Invoice
          _buildFieldLabel('REFERENCE INVOICE'),
          const SizedBox(height: 6),
          _buildReferenceInvoiceField(invoiceProvider, isDark),
          const SizedBox(height: 14),

          // Sales Person
          _buildFieldLabel('SALES PERSON'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _salespersonsList.contains(_salespersonController.text)
                ? _salespersonController.text
                : null,
            hint: Text(
              'Enter sales person name',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF)),
            ),
            isDense: true,
            decoration: _inputDecoration(isDark),
            dropdownColor: isDark ? const Color(0xFF18181B) : Colors.white,
            items: _salespersonsList
                .map((name) => DropdownMenuItem(
                      value: name,
                      child: Text(name, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _salespersonController.text = val);
              }
            },
          ),
          const SizedBox(height: 14),

          // Reference No
          _buildFieldLabel('REFERENCE NO.'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _referenceController,
            hintText: 'e.g. REF-4587',
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // Reason
          _buildFieldLabel('REASON'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _commonReasons.contains(_reasonController.text)
                ? _reasonController.text
                : _commonReasons.first,
            isDense: true,
            decoration: _inputDecoration(isDark),
            dropdownColor: isDark ? const Color(0xFF18181B) : Colors.white,
            items: _commonReasons
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _reasonController.text = val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceInvoiceField(InvoiceProvider provider, bool isDark) {
    final invoiceNumbers = provider.invoices.map((inv) => inv.invoiceNumber).toList();

    if (invoiceNumbers.isNotEmpty) {
      return DropdownButtonFormField<String>(
        initialValue: invoiceNumbers.contains(_referenceInvoiceController.text)
            ? _referenceInvoiceController.text
            : null,
        hint: Text(
          'Select an invoice...',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF)),
        ),
        isDense: true,
        decoration: _inputDecoration(isDark),
        dropdownColor: isDark ? const Color(0xFF18181B) : Colors.white,
        items: [
          ...invoiceNumbers.map((invNo) => DropdownMenuItem(
                value: invNo,
                child: Text(invNo, style: const TextStyle(fontSize: 13)),
              )),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _referenceInvoiceController.text = val;
              // If an invoice is picked, optionally pre-fill customer
              try {
                final matchedInvoice = provider.invoices.firstWhere((i) => i.invoiceNumber == val);
                _onCustomerSelected(matchedInvoice.customer);
              } catch (_) {}
            });
          }
        },
      );
    }

    return _buildTextField(
      controller: _referenceInvoiceController,
      hintText: 'Select an invoice...',
      isDark: isDark,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD 3: RETURNED ITEMS TABLE (Full Width)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildReturnedItemsCard(Color cardBg, Color cardBorder, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('Returned Items'),
              TextButton.icon(
                onPressed: () => _openProductPicker(),
                icon: const Icon(Icons.apps_rounded, size: 16, color: Color(0xFF2563EB)),
                label: const Text(
                  'Catalog Picker',
                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Items search with ProductSearchField
          ProductSearchField(
            onSelected: (product) {
              setState(() {
                final emptyIndex = _items.indexWhere(
                  (i) => i.nameController.text.trim().isEmpty && i.price <= 0,
                );
                if (emptyIndex != -1) {
                  _items[emptyIndex].populateFromProduct(product);
                } else {
                  final newRow = _ReturnedItemRowState(
                    onChanged: () => setState(() {}),
                  )..populateFromProduct(product);
                  _items.add(newRow);
                }
              });
            },
          ),
          const SizedBox(height: 14),

          // Line items list (Image 1 table features)
          if (_items.isNotEmpty) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                if (isWide) {
                  return _buildWideItemTable(isDark);
                } else {
                  return _buildMobileItemList(isDark);
                }
              },
            ),
            const SizedBox(height: 12),
          ],

          // + Add Line Item button (Image 2 & 3 style)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addNewItem,
              icon: const Icon(Icons.add_circle, color: Color(0xFF1E88E5), size: 20),
              label: const Text(
                'Add Line Item',
                style: TextStyle(
                  color: Color(0xFF1E88E5),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF90CAF9), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: isDark ? Colors.blue.withValues(alpha: 0.05) : const Color(0xFFF0F7FF),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Total Items counter (from Image 1: Total Items: 0 / 1)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Total Items: ${_items.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Wide Table View for Items
  Widget _buildWideItemTable(bool isDark) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('ITEM NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              SizedBox(width: 6),
              Expanded(flex: 2, child: Text('HSN/SAC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              SizedBox(width: 6),
              Expanded(flex: 1, child: Text('QTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              SizedBox(width: 6),
              Expanded(flex: 2, child: Text('UNIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              SizedBox(width: 6),
              Expanded(flex: 2, child: Text('PRICE (₹)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              SizedBox(width: 6),
              Expanded(flex: 2, child: Text('GST %', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              SizedBox(width: 6),
              Expanded(flex: 2, child: Text('DISCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              SizedBox(width: 6),
              Expanded(flex: 2, child: Text('AMOUNT (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              SizedBox(width: 32),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Item Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final item = _items[index];
            return _buildWideItemRow(item, index, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildWideItemRow(_ReturnedItemRowState item, int index, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Item Name
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: item.nameController,
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8), hintText: 'Item name'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          // HSN
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: item.hsnController,
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8), hintText: 'HSN'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          // Qty
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: item.qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          // Unit
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                value: _unitOptions.contains(item.unit) ? item.unit : _unitOptions.first,
                items: _unitOptions
                    .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => item.unit = val);
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Price
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: item.priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          // GST %
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                isDense: true,
                value: _gstOptions.contains(item.gstRate) ? item.gstRate : 0.0,
                items: _gstOptions
                    .map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()}%', style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => item.gstRate = val);
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Discount
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      hintText: item.discountType == '₹' ? '0' : '0%',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      item.discountType = item.discountType == '%' ? '₹' : '%';
                    });
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    margin: const EdgeInsets.only(left: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item.discountType,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              _currencyFormat.format(item.total),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
            ),
          ),
          // Delete
          IconButton(
            onPressed: () => _removeItem(index),
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  // Mobile / Compact Item View (Matching Image 3)
  Widget _buildMobileItemList(bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: item.nameController.text.isNotEmpty
                        ? Text(
                            item.nameController.text,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          )
                        : TextFormField(
                            controller: item.nameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter item name...',
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                  IconButton(
                    onPressed: () => _removeItem(index),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _subInput(
                      label: 'HSN/SAC',
                      controller: item.hsnController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _subInput(
                      label: 'Qty',
                      controller: item.qtyController,
                      isNumeric: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isDense: true,
                            isExpanded: true,
                            value: _unitOptions.contains(item.unit) ? item.unit : _unitOptions.first,
                            items: _unitOptions
                                .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => item.unit = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _subInput(
                      label: 'Price (₹)',
                      controller: item.priceController,
                      isNumeric: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GST %', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            isDense: true,
                            isExpanded: true,
                            value: _gstOptions.contains(item.gstRate) ? item.gstRate : 0.0,
                            items: _gstOptions
                                .map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()}%', style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => item.gstRate = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Discount (${item.discountType})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  item.discountType = item.discountType == '%' ? '₹' : '%';
                                });
                              },
                              child: Text(
                                item.discountType == '%' ? 'Switch (₹)' : 'Switch (%)',
                                style: const TextStyle(fontSize: 9, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        TextFormField(
                          controller: item.discountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            hintText: item.discountType == '₹' ? '0' : '0%',
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Amount: ${_currencyFormat.format(item.total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _subInput({
    required String label,
    required TextEditingController controller,
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        TextFormField(
          controller: controller,
          keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD 4: NOTES & CONDITIONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNotesAndConditionsCard(Color cardBg, Color cardBorder, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.edit_note_rounded, color: Color(0xFF7C3AED), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Notes & Conditions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // NOTES & INTERNAL NOTE
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isSubWide = constraints.maxWidth >= 500;
              if (isSubWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('NOTES'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _notesController,
                            hintText: 'Add any notes or credit references...',
                            maxLines: 4,
                            minLines: 3,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('INTERNAL NOTE'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _internalNotesController,
                            hintText: 'For administrative logging...',
                            maxLines: 4,
                            minLines: 3,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('NOTES'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _notesController,
                      hintText: 'Add any notes or credit references...',
                      maxLines: 3,
                      minLines: 2,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildFieldLabel('INTERNAL NOTE'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _internalNotesController,
                      hintText: 'For administrative logging...',
                      maxLines: 3,
                      minLines: 2,
                      isDark: isDark,
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // TERMS AND CONDITIONS
          _buildFieldLabel('TERMS AND CONDITIONS'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _termsController,
            hintText: 'Enter credit note terms and conditions...',
            maxLines: 6,
            minLines: 4,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD 5: CREDIT NOTE SUMMARY & STATUS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSummaryAndStatusCard(Color cardBg, Color cardBorder, bool isDark) {
    return Column(
      children: [
        // Credit Note Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.calculate_outlined, color: Color(0xFF7C3AED), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Credit Note Summary',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSummaryRow('Subtotal', _currencyFormat.format(_subtotal)),
              const SizedBox(height: 8),
              _buildSummaryRow('Taxable Amount', _currencyFormat.format(_taxableAmount)),
              const SizedBox(height: 8),
              _buildSummaryRow('Total GST (18%)', _currencyFormat.format(_totalGst)),
              const SizedBox(height: 8),

              // Round Off Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _roundOff,
                        activeColor: const Color(0xFF7C3AED),
                        onChanged: (val) {
                          setState(() {
                            _roundOff = val ?? true;
                          });
                        },
                      ),
                      const Text(
                        'Round Off',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    '${_roundOffDiff >= 0 ? '+' : '-'} ${_currencyFormat.format(_roundOffDiff.abs())}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Credit Note Amount (Formatted as RED with negative sign - ₹... as in screenshot!)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Credit Note Amount',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '- ${_currencyFormat.format(_grandTotal)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626), // RED negative color
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Credit Note Status Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.rule_folder_outlined, color: Color(0xFF7C3AED), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Credit Note Status',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('STATUS *'),
              const SizedBox(height: 6),
              DropdownButtonFormField<CreditNoteStatus>(
                initialValue: _status,
                isDense: true,
                decoration: _inputDecoration(isDark),
                dropdownColor: isDark ? const Color(0xFF18181B) : Colors.white,
                items: CreditNoteStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.displayName, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 20),

              // Save Credit Note Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveCreditNote(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Save Credit Note →',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper UI Widgets
  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: Color(0xFF4B5563),
      ),
    );
  }

  Widget _buildDateDisplayBox(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(fontSize: 13)),
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isDark = false,
    bool enabled = true,
    int maxLines = 1,
    int minLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 13),
      decoration: _inputDecoration(isDark, hintText: hintText),
    );
  }

  InputDecoration _inputDecoration(bool isDark, {String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      filled: true,
      fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF7C3AED)),
      ),
    );
  }
}

class _ReturnedItemRowState {
  final TextEditingController nameController;
  final TextEditingController descController;
  final TextEditingController hsnController;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  final TextEditingController discountController;

  String unit;
  double gstRate;
  String discountType;
  String? productId;
  final VoidCallback onChanged;

  _ReturnedItemRowState({
    required this.onChanged,
    String name = '',
    String desc = '',
    String hsn = '',
    String qty = '1',
    String price = '0',
    String discount = '0',
    this.unit = 'Nos',
    this.gstRate = 0.0,
    this.discountType = '%',
    this.productId,
  })  : nameController = TextEditingController(text: name),
        descController = TextEditingController(text: desc),
        hsnController = TextEditingController(text: hsn),
        qtyController = TextEditingController(text: qty),
        priceController = TextEditingController(text: price),
        discountController = TextEditingController(text: discount) {
    nameController.addListener(onChanged);
    descController.addListener(onChanged);
    hsnController.addListener(onChanged);
    qtyController.addListener(onChanged);
    priceController.addListener(onChanged);
    discountController.addListener(onChanged);
  }

  factory _ReturnedItemRowState.fromCreditNoteItem(CreditNoteItem item, {required VoidCallback onChanged}) {
    return _ReturnedItemRowState(
      onChanged: onChanged,
      name: item.name,
      desc: item.description,
      hsn: item.hsnSac,
      qty: item.quantity == item.quantity.roundToDouble()
          ? item.quantity.toInt().toString()
          : item.quantity.toString(),
      price: item.unitPrice == item.unitPrice.roundToDouble()
          ? item.unitPrice.toInt().toString()
          : item.unitPrice.toString(),
      discount: item.discount > 0 ? item.discount.toString() : '0',
      unit: item.unit,
      gstRate: item.gstRate,
      discountType: item.discountType,
      productId: item.productId,
    );
  }

  void populateFromProduct(Product p) {
    nameController.text = p.name;
    descController.text = p.description;
    hsnController.text = p.hsnSacCode;
    priceController.text = p.sellingPrice > 0 ? p.sellingPrice.toString() : '0';
    unit = p.unitAbbreviation.isNotEmpty ? p.unitAbbreviation : 'Nos';
    gstRate = p.gst > 0 ? p.gst : 0.0;
    productId = p.id;
  }

  double get quantity => double.tryParse(qtyController.text) ?? 0.0;
  double get price => double.tryParse(priceController.text) ?? 0.0;
  double get discountVal => double.tryParse(discountController.text) ?? 0.0;

  double get subtotal => quantity * price;

  double get discountAmount {
    if (discountVal <= 0) return 0.0;
    if (discountType == '₹') {
      return discountVal.clamp(0.0, subtotal);
    }
    return (subtotal * (discountVal / 100)).clamp(0.0, subtotal);
  }

  double get taxableAmount => (subtotal - discountAmount).clamp(0.0, double.infinity);
  double get taxAmount => taxableAmount * (gstRate / 100);
  double get total => taxableAmount + taxAmount;

  CreditNoteItem toCreditNoteItem() {
    return CreditNoteItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      productId: productId,
      name: nameController.text.trim(),
      description: descController.text.trim(),
      hsnSac: hsnController.text.trim(),
      quantity: quantity > 0 ? quantity : 1.0,
      unit: unit,
      unitPrice: price,
      gstRate: gstRate,
      discount: discountVal,
      discountType: discountType,
    );
  }

  void dispose() {
    nameController.dispose();
    descController.dispose();
    hsnController.dispose();
    qtyController.dispose();
    priceController.dispose();
    discountController.dispose();
  }
}
