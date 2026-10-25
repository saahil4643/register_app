import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../providers/invoice_provider.dart';
import '../../../customers/providers/customer_provider.dart';
import '../../../customers/models/customer.dart';
import '../../../products/providers/product_provider.dart';
import '../../../products/models/product.dart';
import '../../services/route_service.dart';
import '../../widgets/simple_product_picker_modal.dart';

class NewInvoiceScreen extends StatefulWidget {
  final bool isEditing;

  const NewInvoiceScreen({
    super.key,
    required this.isEditing,
  });

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final RouteService _routeService = RouteService();

  // Mode: Quick Bill (POS) vs Route Distribution
  bool _isQuickPosMode = true;

  // Invoice Date & Number
  late DateTime _invoiceDate;
  late TextEditingController _invoiceNumberController;

  // Quick POS Customer fields
  bool _isWalkInCustomer = true;
  final TextEditingController _walkInNameController = TextEditingController(text: 'Walk-in Customer');
  final TextEditingController _walkInPhoneController = TextEditingController();
  Customer? _selectedRegisteredCustomer;
  final TextEditingController _customerSearchController = TextEditingController();

  // Route & Outlet selection (for Distribution Mode)
  String _selectedRoute = 'Route 1 - Market Yard & Main Bazar';
  Customer? _selectedOutlet;
  final Map<String, List<Customer>> _routeOutletsMap = {};

  // Inline Product Search & Quick Custom Item
  final TextEditingController _productSearchController = TextEditingController();
  final TextEditingController _customItemNameController = TextEditingController();
  final TextEditingController _customItemPriceController = TextEditingController();
  final TextEditingController _customItemQtyController = TextEditingController(text: '1');
  bool _showCustomItemForm = false;

  // Payment Options
  String _selectedPaymentMode = 'Cash';
  bool _markAsPaid = true;
  final bool _roundOff = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final invoiceProvider = context.read<InvoiceProvider>();

    if (!widget.isEditing) {
      invoiceProvider.startNewInvoice();
      _invoiceDate = DateTime.now();
      _invoiceNumberController = TextEditingController(
        text: invoiceProvider.invoiceNumber.isNotEmpty && invoiceProvider.invoiceNumber != 'Auto-Generated'
            ? invoiceProvider.invoiceNumber
            : 'INV-${DateFormat('yyyyMMdd').format(DateTime.now())}-01',
      );
    } else {
      final editing = invoiceProvider.editingInvoice;
      _invoiceDate = editing?.invoiceDate ?? invoiceProvider.invoiceDate;
      _invoiceNumberController = TextEditingController(
        text: editing?.invoiceNumber ?? invoiceProvider.invoiceNumber,
      );
      final customer = editing?.customer ?? invoiceProvider.selectedCustomer;
      if (customer != null && customer.displayName != 'Walk-in Customer') {
        _isWalkInCustomer = false;
        _selectedRegisteredCustomer = customer;
        _selectedOutlet = customer;
      }
      _markAsPaid = invoiceProvider.isPaid;
    }

    _routeService.init().then((_) {
      if (mounted && _routeService.routes.isNotEmpty) {
        setState(() {
          _selectedRoute = _routeService.routes.first;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
      context.read<ProductProvider>().fetchProducts();
      invoiceProvider.loadNextInvoiceNumber().then((_) {
        if (invoiceProvider.invoiceNumber.isNotEmpty && invoiceProvider.invoiceNumber != 'Auto-Generated') {
          if (mounted) {
            setState(() {
              _invoiceNumberController.text = invoiceProvider.invoiceNumber;
            });
          }
        }
      });
    });

    _initSampleOutlets();
  }

  void _initSampleOutlets() {
    final now = DateTime.now();
    _routeOutletsMap['Route 1 - Market Yard & Main Bazar'] = [
      Customer(
        id: 'OUTLET-001',
        displayName: 'Shree Ganesh Traders',
        companyName: 'Shree Ganesh Retail & Wholesale',
        primaryPhone: '9822012345',
        billingAddressLine1: 'Shop No. 12, Market Yard',
        billingCity: 'Pune',
        billingState: 'Maharashtra',
        gstNumber: '27AABCU9603R1ZM',
        route: 'Route 1 - Market Yard & Main Bazar',
        createdAt: now,
      ),
      Customer(
        id: 'OUTLET-002',
        displayName: 'Mahalaxmi Super Market',
        companyName: 'Mahalaxmi Provisions',
        primaryPhone: '9822054321',
        billingAddressLine1: 'Plot 45, Main Bazar Chowk',
        billingCity: 'Pune',
        billingState: 'Maharashtra',
        gstNumber: '27AADCB2234P1Z3',
        route: 'Route 1 - Market Yard & Main Bazar',
        createdAt: now,
      ),
    ];
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _walkInNameController.dispose();
    _walkInPhoneController.dispose();
    _customerSearchController.dispose();
    _productSearchController.dispose();
    _customItemNameController.dispose();
    _customItemPriceController.dispose();
    _customItemQtyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _invoiceDate = picked);
      context.read<InvoiceProvider>().updateInvoiceDate(picked);
    }
  }

  void _showQuickAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final gstCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Quick Add Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Customer / Business Name *',
                hintText: 'e.g. Ramesh Kumar',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
                hintText: 'e.g. 9876543210',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gstCtrl,
              decoration: const InputDecoration(
                labelText: 'GSTIN (Optional)',
                hintText: 'e.g. 27AAAAA0000A1Z5',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final newCust = Customer(
                id: 'CUST-${DateTime.now().millisecondsSinceEpoch}',
                displayName: name,
                companyName: name,
                primaryPhone: phoneCtrl.text.trim(),
                gstNumber: gstCtrl.text.trim(),
                createdAt: DateTime.now(),
              );

              final customerProvider = context.read<CustomerProvider>();
              await customerProvider.createCustomer(newCust);

              if (mounted) {
                setState(() {
                  _isWalkInCustomer = false;
                  _selectedRegisteredCustomer = newCust;
                });
                context.read<InvoiceProvider>().selectCustomer(newCust);
              }
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }

  void _addCustomItemDirectly() {
    final name = _customItemNameController.text.trim();
    final price = double.tryParse(_customItemPriceController.text.trim()) ?? 0.0;
    final qty = int.tryParse(_customItemQtyController.text.trim()) ?? 1;

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid item name and price.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<InvoiceProvider>().addCustomItem(
      name: name,
      price: price,
      quantity: qty > 0 ? qty : 1,
    );

    _customItemNameController.clear();
    _customItemPriceController.clear();
    _customItemQtyController.text = '1';
    setState(() => _showCustomItemForm = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Added "$name" to bill!'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Customer> _getOutletsForRoute(CustomerProvider customerProvider) {
    final List<Customer> results = [];
    final seenIds = <String>{};

    for (var cust in customerProvider.customers) {
      if (cust.route.isNotEmpty && cust.route.trim().toLowerCase() == _selectedRoute.trim().toLowerCase()) {
        results.add(cust);
        seenIds.add(cust.id);
      }
    }

    final preseeded = _routeOutletsMap[_selectedRoute] ?? [];
    for (var cust in preseeded) {
      if (!seenIds.contains(cust.id)) {
        results.add(cust);
        seenIds.add(cust.id);
      }
    }

    if (results.isEmpty && customerProvider.customers.isNotEmpty) {
      for (var cust in customerProvider.customers) {
        if (!seenIds.contains(cust.id)) {
          results.add(cust);
          seenIds.add(cust.id);
        }
      }
    }

    return results;
  }

  Future<void> _saveInvoice({required bool isDraft}) async {
    final invoiceProvider = context.read<InvoiceProvider>();

    if (invoiceProvider.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product to the bill.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Resolve Customer
    Customer effectiveCustomer;
    if (_isQuickPosMode) {
      if (_isWalkInCustomer || _selectedRegisteredCustomer == null) {
        final walkInName = _walkInNameController.text.trim().isNotEmpty
            ? _walkInNameController.text.trim()
            : 'Walk-in Customer';
        effectiveCustomer = Customer(
          id: 'CUST-WALKIN',
          displayName: walkInName,
          companyName: 'Cash Sale',
          primaryPhone: _walkInPhoneController.text.trim(),
          createdAt: DateTime.now(),
        );
      } else {
        effectiveCustomer = _selectedRegisteredCustomer!;
      }
    } else {
      if (_selectedOutlet == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an outlet from the route.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      effectiveCustomer = _selectedOutlet!;
    }

    setState(() => _isSaving = true);

    invoiceProvider.selectCustomer(effectiveCustomer);
    invoiceProvider.updateInvoiceDate(_invoiceDate);
    invoiceProvider.updateInvoiceNumber(_invoiceNumberController.text.trim());

    final success = await invoiceProvider.saveInvoice(
      isDraft: isDraft,
      markAsFullyPaid: _markAsPaid,
      paymentMode: _selectedPaymentMode,
      isRoundOff: _roundOff,
      mobileNumber: effectiveCustomer.primaryPhone,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        _showSuccessBillSheet(effectiveCustomer, isDraft);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(invoiceProvider.errorMessage ?? 'Failed to save bill'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessBillSheet(Customer customer, bool isDraft) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final invoiceNumber = _invoiceNumberController.text.trim();
    final grandTotal = context.read<InvoiceProvider>().grandTotal;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  isDraft ? 'Draft Saved!' : 'Bill Completed Successfully!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Invoice #$invoiceNumber • ${_currency.format(grandTotal)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
                Text(
                  'Customer: ${customer.displayName}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Start Next Bill Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          final inv = context.read<InvoiceProvider>();
                          inv.startNewInvoice();
                          setState(() {
                            _isWalkInCustomer = true;
                            _selectedRegisteredCustomer = null;
                            _selectedOutlet = null;
                            _walkInPhoneController.clear();
                            _walkInNameController.text = 'Walk-in Customer';
                            _invoiceDate = DateTime.now();
                          });
                          inv.loadNextInvoiceNumber().then((_) {
                            if (mounted && inv.invoiceNumber.isNotEmpty && inv.invoiceNumber != 'Auto-Generated') {
                              setState(() => _invoiceNumberController.text = inv.invoiceNumber);
                            }
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('New Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // View Invoices List Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (mounted) context.go('/invoices');
                        },
                        icon: const Icon(Icons.receipt_long_rounded, size: 20),
                        label: const Text('View Invoices', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final invoiceProvider = context.watch<InvoiceProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final productProvider = context.watch<ProductProvider>();

    final double taxableSubtotal = invoiceProvider.subtotal;
    final double totalTax = invoiceProvider.totalTax;
    final double rawGrandTotal = taxableSubtotal + totalTax;
    final double netAmount = _roundOff ? rawGrandTotal.roundToDouble() : rawGrandTotal;
    final double roundOffDifference = netAmount - rawGrandTotal;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEditing ? 'Edit Bill / Invoice' : 'Quick Register & Bill',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'Simple 1-Touch Checkout',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : () => _saveInvoice(isDraft: true),
            icon: const Icon(Icons.drafts_outlined, size: 16),
            label: const Text('Draft', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Clear & Reset',
            onPressed: () {
              invoiceProvider.startNewInvoice();
              setState(() {
                _isWalkInCustomer = true;
                _selectedRegisteredCustomer = null;
                _selectedOutlet = null;
                _walkInPhoneController.clear();
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.withValues(alpha: 0.2), height: 1.0),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode Switcher: Quick Bill (POS) vs Route Distribution
                    _buildModeSwitcher(theme, isDark),
                    const SizedBox(height: 10),

                    // Bill Details Bar: Date & Invoice Number
                    _buildInvoiceMetadataBar(theme, isDark),
                    const SizedBox(height: 12),

                    // Customer Section
                    if (_isQuickPosMode)
                      _buildQuickCustomerSection(theme, isDark, customerProvider)
                    else
                      _buildRouteDistributionCustomerSection(theme, isDark, customerProvider),
                    const SizedBox(height: 12),

                    // Products & Item Adding Section
                    _buildProductSelectionSection(theme, isDark, invoiceProvider, productProvider),
                    const SizedBox(height: 12),

                    // Items Cart List
                    _buildItemsCartSection(theme, isDark, invoiceProvider),
                    const SizedBox(height: 12),

                    // Billing Summary & Payment Section
                    _buildBillingSummarySection(
                      theme,
                      isDark,
                      taxableSubtotal,
                      totalTax,
                      rawGrandTotal,
                      netAmount,
                      roundOffDifference,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Checkout Bar
            _buildStickyCheckoutBar(theme, isDark, invoiceProvider, netAmount),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. MODE SWITCHER: QUICK BILL (POS) vs ROUTE DISTRIBUTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildModeSwitcher(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isQuickPosMode = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isQuickPosMode
                      ? (isDark ? Colors.grey[800] : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isQuickPosMode
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: _isQuickPosMode ? const Color(0xFF2563EB) : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '⚡ Quick Bill (POS)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _isQuickPosMode ? FontWeight.bold : FontWeight.w600,
                        color: _isQuickPosMode
                            ? (_isQuickPosMode ? const Color(0xFF2563EB) : (isDark ? Colors.white : Colors.black87))
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isQuickPosMode = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isQuickPosMode
                      ? (isDark ? Colors.grey[800] : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isQuickPosMode
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alt_route_rounded,
                      size: 16,
                      color: !_isQuickPosMode ? const Color(0xFF2563EB) : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '🚚 Route Distribution',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: !_isQuickPosMode ? FontWeight.bold : FontWeight.w600,
                        color: !_isQuickPosMode
                            ? (const Color(0xFF2563EB))
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. INVOICE METADATA: DATE & NUMBER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInvoiceMetadataBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date Chip
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM yyyy').format(_invoiceDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
              ],
            ),
          ),

          // Bill # Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_rounded, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  _invoiceNumberController.text.isNotEmpty ? _invoiceNumberController.text : 'Auto-Gen',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. QUICK POS CUSTOMER SECTION (WALK-IN DEFAULT + QUICK SEARCH)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickCustomerSection(ThemeData theme, bool isDark, CustomerProvider customerProvider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isWalkInCustomer ? Icons.person_pin_circle_rounded : Icons.person_rounded,
                    size: 18,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  const Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Walk-in (Cash)'),
                    selected: _isWalkInCustomer,
                    onSelected: (val) {
                      setState(() {
                        _isWalkInCustomer = true;
                        _selectedRegisteredCustomer = null;
                      });
                    },
                    selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: _isWalkInCustomer ? FontWeight.bold : FontWeight.normal,
                      color: _isWalkInCustomer ? const Color(0xFF2563EB) : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Registered'),
                    selected: !_isWalkInCustomer,
                    onSelected: (val) {
                      setState(() {
                        _isWalkInCustomer = false;
                      });
                    },
                    selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: !_isWalkInCustomer ? FontWeight.bold : FontWeight.normal,
                      color: !_isWalkInCustomer ? const Color(0xFF2563EB) : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Walk-in form: Simple optional phone number
          if (_isWalkInCustomer) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Default: Walk-in Cash Customer (Ready to Bill)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _walkInPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Customer Phone (Optional for SMS receipt)',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.phone_android_rounded, size: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ] else ...[
            // Registered customer selector
            if (_selectedRegisteredCustomer != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedRegisteredCustomer!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          if (_selectedRegisteredCustomer!.phone.isNotEmpty)
                            Text(
                              _selectedRegisteredCustomer!.phone,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedRegisteredCustomer = null),
                      child: const Text('Change', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customerSearchController,
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search customer by name or phone...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        prefixIcon: const Icon(Icons.search, size: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showQuickAddCustomerDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              // Search Results Dropdown
              if (_customerSearchController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: customerProvider.customers
                        .where((c) {
                          final q = _customerSearchController.text.trim().toLowerCase();
                          return c.name.toLowerCase().contains(q) ||
                              c.phone.toLowerCase().contains(q) ||
                              c.companyName.toLowerCase().contains(q);
                        })
                        .take(6)
                        .map((c) => ListTile(
                              dense: true,
                              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: Text(c.phone.isNotEmpty ? c.phone : 'No phone', style: const TextStyle(fontSize: 11)),
                              trailing: const Icon(Icons.chevron_right, size: 18),
                              onTap: () {
                                setState(() {
                                  _selectedRegisteredCustomer = c;
                                  _customerSearchController.clear();
                                });
                                context.read<InvoiceProvider>().selectCustomer(c);
                              },
                            ))
                        .toList(),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ROUTE DISTRIBUTION CUSTOMER SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRouteDistributionCustomerSection(ThemeData theme, bool isDark, CustomerProvider customerProvider) {
    final routes = _routeService.routes;
    final outlets = _getOutletsForRoute(customerProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alt_route_rounded, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text('Route Distribution Selection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          // Route Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: routes.contains(_selectedRoute) ? _selectedRoute : (routes.isNotEmpty ? routes.first : null),
                isExpanded: true,
                items: routes.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedRoute = val;
                      _selectedOutlet = null;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Outlet Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Customer>(
                value: outlets.contains(_selectedOutlet) ? _selectedOutlet : null,
                hint: Text('Select Outlet from Route (${outlets.length} available)', style: const TextStyle(fontSize: 13)),
                isExpanded: true,
                items: outlets.map((o) => DropdownMenuItem(value: o, child: Text(o.name, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedOutlet = val);
                    context.read<InvoiceProvider>().selectCustomer(val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. PRODUCT SELECTION & ADDING (INSTANT SEARCH + QUICK CUSTOM ITEM + CATALOG)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProductSelectionSection(
    ThemeData theme,
    bool isDark,
    InvoiceProvider invoiceProvider,
    ProductProvider productProvider,
  ) {
    final searchQuery = _productSearchController.text.trim().toLowerCase();
    final matchingProducts = searchQuery.isNotEmpty
        ? productProvider.products
            .where((p) => p.name.toLowerCase().contains(searchQuery) || p.sku.toLowerCase().contains(searchQuery))
            .take(6)
            .toList()
        : <Product>[];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.inventory_2_rounded, size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Text('Add Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _showCustomItemForm = !_showCustomItemForm),
                    icon: Icon(_showCustomItemForm ? Icons.remove : Icons.add_box_outlined, size: 16),
                    label: Text(_showCustomItemForm ? 'Close Custom' : '+ Quick Custom Item', style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () => SimpleProductPickerModal.show(context),
                    icon: const Icon(Icons.grid_view_rounded, size: 14),
                    label: const Text('Catalog', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Instant Search Bar
          TextField(
            controller: _productSearchController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: '🔍 Type product name to add to bill...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: _productSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => setState(() => _productSearchController.clear()),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),

          // Search Results Dropdown List
          if (matchingProducts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matchingProducts.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final p = matchingProducts[idx];
                  final price = p.price > 0 ? p.price : (p.sellingPrice > 0 ? p.sellingPrice : 10.0);
                  return ListTile(
                    dense: true,
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(
                      '${_currency.format(price)} | GST: ${p.gst.toStringAsFixed(0)}% | ${p.unitAbbreviation}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    trailing: ElevatedButton.icon(
                      onPressed: () {
                        invoiceProvider.addOrIncrementProduct(p);
                        setState(() => _productSearchController.clear());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ Added "${p.name}" to bill!'),
                            duration: const Duration(milliseconds: 800),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Quick Custom Item Form
          if (_showCustomItemForm) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Custom Item (No database required)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _customItemNameController,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Item Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _customItemPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Price (₹)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _customItemQtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Qty',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: _addCustomItemDirectly,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. ITEMS CART SECTION WITH LIVE STEPPER CONTROLS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildItemsCartSection(ThemeData theme, bool isDark, InvoiceProvider provider) {
    final items = provider.selectedItems;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_checkout_rounded, size: 18, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  const Text('Items in Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${items.length} items',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF047857)),
                    ),
                  ),
                ],
              ),
              if (items.isNotEmpty)
                TextButton(
                  onPressed: () => provider.startNewInvoice(),
                  child: const Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_shopping_cart_rounded, size: 36, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  const Text(
                    'No items in bill yet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search product above or tap + Quick Custom Item to begin billing',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (ctx, i) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final item = items[idx];
                final displayName = item.itemName != null && item.itemName!.isNotEmpty
                    ? item.itemName!
                    : (item.product.name.isNotEmpty ? item.product.name : 'Item');

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Item details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_currency.format(item.unitPrice)} each | GST: ${item.taxPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),

                    // Live Interactive Quantity Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: () => provider.updateItemQty(item.product.id, item.quantity - 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: () => provider.updateItemQty(item.product.id, item.quantity + 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Item Total & Delete button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currency.format(item.total),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => provider.removeProduct(item.product.id),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. BILLING SUMMARY & PAYMENT METHOD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBillingSummarySection(
    ThemeData theme,
    bool isDark,
    double taxableSubtotal,
    double totalTax,
    double rawGrandTotal,
    double netAmount,
    double roundOffDifference,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Billing & Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),

          _buildSummaryLine('Subtotal (Taxable)', _currency.format(taxableSubtotal)),
          const SizedBox(height: 4),
          _buildSummaryLine('GST Amount', _currency.format(totalTax)),
          if (roundOffDifference != 0.0) ...[
            const SizedBox(height: 4),
            _buildSummaryLine('Round Off', (roundOffDifference > 0 ? '+' : '') + _currency.format(roundOffDifference)),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL PAYABLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                _currency.format(netAmount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Payment Mode Selector Pills
          const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ['Cash', 'UPI', 'Card', 'Credit / Due'].map((mode) {
              final isSelected = _selectedPaymentMode == mode;
              return ChoiceChip(
                label: Text(mode),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedPaymentMode = mode;
                    _markAsPaid = mode != 'Credit / Due';
                  });
                },
                selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF2563EB) : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),

          CheckboxListTile(
            title: const Text('Mark invoice as Fully Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            value: _markAsPaid,
            onChanged: (val) => setState(() => _markAsPaid = val ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. STICKY BOTTOM CHECKOUT ACTION BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStickyCheckoutBar(
    ThemeData theme,
    bool isDark,
    InvoiceProvider provider,
    double netAmount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${provider.selectedItems.length} items in cart',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    _currency.format(netAmount),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveInvoice(isDraft: false),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.flash_on_rounded, size: 20),
                label: Text(
                  _isSaving ? 'Processing...' : 'Complete Bill',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
