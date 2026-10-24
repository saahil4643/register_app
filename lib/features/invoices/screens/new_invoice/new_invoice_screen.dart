import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../providers/invoice_provider.dart';
import '../../../customers/providers/customer_provider.dart';
import '../../../customers/models/customer.dart';
import '../../../products/providers/product_provider.dart';
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

  // Step 1: Date (Auto-selected to Today)
  late DateTime _invoiceDate;

  // Step 2: Invoice No (Auto-generated)
  late TextEditingController _invoiceNumberController;
  final bool _isManualInvoiceNo = false;

  // Step 3: Route Selection
  String _selectedRoute = 'Route 1 - Market Yard & Main Bazar';

  // Step 4: Outlet Selection
  Customer? _selectedOutlet;

  // Step 6: Calculations & Payment Options
  String _selectedPaymentMode = 'Cash';
  bool _markAsPaid = false;
  final bool _roundOff = true;
  bool _isSaving = false;

  // Pre-seeded standard distribution outlets per route (ensures outlets are available immediately)
  final Map<String, List<Customer>> _routeOutletsMap = {};

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
      _selectedOutlet = editing?.customer ?? invoiceProvider.selectedCustomer;
      _markAsPaid = invoiceProvider.isPaid;
    }

    _routeService.init().then((_) {
      if (mounted) {
        if (_routeService.routes.isNotEmpty) {
          setState(() {
            _selectedRoute = _routeService.routes.first;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
      context.read<ProductProvider>().fetchProducts();
      invoiceProvider.loadNextInvoiceNumber().then((_) {
        if (!_isManualInvoiceNo && invoiceProvider.invoiceNumber.isNotEmpty && invoiceProvider.invoiceNumber != 'Auto-Generated') {
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
      Customer(
        id: 'OUTLET-003',
        displayName: 'Om Sai Provision Store',
        companyName: 'Om Sai Retail',
        primaryPhone: '9423123456',
        billingAddressLine1: 'Station Road, Near Bus Stand',
        billingCity: 'Pune',
        billingState: 'Maharashtra',
        route: 'Route 1 - Market Yard & Main Bazar',
        createdAt: now,
      ),
    ];

    _routeOutletsMap['Route 2 - Station Road & Commercial Zone'] = [
      Customer(
        id: 'OUTLET-004',
        displayName: 'Station Kirana & General Stores',
        companyName: 'Station Kirana',
        primaryPhone: '9890123456',
        billingAddressLine1: 'Commercial Complex, Station Road',
        billingCity: 'Pune',
        billingState: 'Maharashtra',
        route: 'Route 2 - Station Road & Commercial Zone',
        createdAt: now,
      ),
      Customer(
        id: 'OUTLET-005',
        displayName: 'Balaji Mart',
        companyName: 'Balaji Retailers Pvt Ltd',
        primaryPhone: '9881234567',
        billingAddressLine1: 'Near Railway Platform 1',
        billingCity: 'Pune',
        billingState: 'Maharashtra',
        gstNumber: '27AAECB1122Q1Z5',
        route: 'Route 2 - Station Road & Commercial Zone',
        createdAt: now,
      ),
    ];

    _routeOutletsMap['Route 3 - Highway & Industrial Estate'] = [
      Customer(
        id: 'OUTLET-006',
        displayName: 'Highway Super Mart',
        companyName: 'Highway Retail Hub',
        primaryPhone: '9765432109',
        billingAddressLine1: 'NH-48 Bypass Junction',
        billingCity: 'Pune',
        billingState: 'Maharashtra',
        route: 'Route 3 - Highway & Industrial Estate',
        createdAt: now,
      ),
      Customer(
        id: 'OUTLET-007',
        displayName: 'Apex Canteen & Stores',
        companyName: 'Apex Enterprise',
        primaryPhone: '9765001122',
        billingAddressLine1: 'MIDC Industrial Area, Phase 2',
        billingCity: 'Pune',
        billingState: 'Maharashtra',
        gstNumber: '27AAGCB5544R1Z7',
        route: 'Route 3 - Highway & Industrial Estate',
        createdAt: now,
      ),
    ];
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    super.dispose();
  }

  // Pick Date Modal
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
    if (picked != null) {
      if (mounted) {
        setState(() {
          _invoiceDate = picked;
        });
        context.read<InvoiceProvider>().updateInvoiceDate(picked);
      }
    }
  }

  // Quick dialog to add a new route
  void _showAddNewRouteDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.alt_route_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Add New Route'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Route Name *',
            hintText: 'e.g. Route 6 - West End Market',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await _routeService.addRoute(name);
                setState(() {
                  _selectedRoute = name;
                });
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text('Add Route'),
          ),
        ],
      ),
    );
  }

  // Quick dialog to add a new outlet to current route
  void _showAddNewOutletDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final gstCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add Outlet to $_selectedRoute',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Outlet / Shop Name *',
                  hintText: 'e.g. Krishna Kirana Store',
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  hintText: 'e.g. 9876543210',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Shop Address',
                  hintText: 'e.g. Main Chowk, Bazar Road',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 10),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isEmpty) return;

              final newCust = Customer(
                id: 'CUST-${DateTime.now().millisecondsSinceEpoch}',
                displayName: name,
                companyName: name,
                primaryPhone: phone,
                billingAddressLine1: addressCtrl.text.trim(),
                gstNumber: gstCtrl.text.trim(),
                route: _selectedRoute,
                createdAt: DateTime.now(),
              );

              // Add to customer provider and local route map
              final customerProvider = context.read<CustomerProvider>();
              await customerProvider.createCustomer(newCust);

              if (_routeOutletsMap[_selectedRoute] == null) {
                _routeOutletsMap[_selectedRoute] = [];
              }
              _routeOutletsMap[_selectedRoute]!.insert(0, newCust);

              if (mounted) {
                setState(() {
                  _selectedOutlet = newCust;
                });
                context.read<InvoiceProvider>().selectCustomer(newCust);
              }

              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Outlet'),
          ),
        ],
      ),
    );
  }

  // Get outlets for the currently selected route
  List<Customer> _getOutletsForRoute(CustomerProvider customerProvider) {
    final List<Customer> results = [];
    final seenIds = <String>{};

    // 1. From CustomerProvider customers
    for (var cust in customerProvider.customers) {
      if (cust.route.isNotEmpty) {
        if (cust.route.trim().toLowerCase() == _selectedRoute.trim().toLowerCase()) {
          results.add(cust);
          seenIds.add(cust.id);
        }
      }
    }

    // 2. From pre-seeded route outlets map
    final preseeded = _routeOutletsMap[_selectedRoute] ?? [];
    for (var cust in preseeded) {
      if (!seenIds.contains(cust.id)) {
        results.add(cust);
        seenIds.add(cust.id);
      }
    }

    // 3. Fallback: if route has no outlets yet, include general customers
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

  // Save Invoice method
  Future<void> _saveInvoice({required bool isDraft}) async {
    final invoiceProvider = context.read<InvoiceProvider>();

    if (_selectedOutlet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Outlet from the chosen Route.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (invoiceProvider.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one Product to the invoice.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    invoiceProvider.selectCustomer(_selectedOutlet);
    invoiceProvider.updateInvoiceDate(_invoiceDate);
    invoiceProvider.updateInvoiceNumber(_invoiceNumberController.text.trim());

    final success = await invoiceProvider.saveInvoice(
      isDraft: isDraft,
      markAsFullyPaid: _markAsPaid,
      paymentMode: _selectedPaymentMode,
      isRoundOff: _roundOff,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDraft
                  ? 'Invoice saved as Draft!'
                  : 'Invoice #${_invoiceNumberController.text} saved successfully!',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(invoiceProvider.errorMessage ?? 'Failed to save invoice'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final invoiceProvider = context.watch<InvoiceProvider>();
    final customerProvider = context.watch<CustomerProvider>();

    final routes = _routeService.routes;
    final outlets = _getOutletsForRoute(customerProvider);

    // Exact GST & Net Amount calculation
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
        title: Text(
          widget.isEditing ? 'Edit Invoice' : 'New Invoice',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : () => _saveInvoice(isDraft: true),
            icon: const Icon(Icons.drafts_outlined, size: 18),
            label: const Text('Draft', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Items',
            onPressed: () {
              invoiceProvider.startNewInvoice();
              setState(() {
                _selectedOutlet = null;
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─────────────────────────────────────────────────────────
                    // STEP 1 & 2: DATE & INVOICE NO (Auto-selected & Auto-generated)
                    // ─────────────────────────────────────────────────────────
                    _buildHeaderCard(theme, isDark),
                    const SizedBox(height: 12),

                    // ─────────────────────────────────────────────────────────
                    // STEP 3 & 4: SELECT ROUTE & SELECT OUTLET
                    // ─────────────────────────────────────────────────────────
                    _buildRouteAndOutletCard(theme, isDark, routes, outlets),
                    const SizedBox(height: 12),

                    // ─────────────────────────────────────────────────────────
                    // STEP 5: ADD PRODUCT & ITEMS LIST
                    // ─────────────────────────────────────────────────────────
                    _buildProductsCard(theme, isDark, invoiceProvider),
                    const SizedBox(height: 12),

                    // ─────────────────────────────────────────────────────────
                    // STEP 6: NET AMOUNT CALCULATION (Correct GST Breakdown)
                    // ─────────────────────────────────────────────────────────
                    _buildCalculationCard(
                      theme,
                      isDark,
                      taxableSubtotal,
                      totalTax,
                      rawGrandTotal,
                      netAmount,
                      roundOffDifference,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Action Bar
            _buildStickyBottomBar(theme, isDark, invoiceProvider, netAmount),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 & 2 WIDGET: DATE & INVOICE NO
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Date (Auto Selected)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          '1. Invoice Date (Auto)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(_invoiceDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Invoice No (Auto Generated)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        '2. Invoice No (Auto)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _invoiceNumberController.text.isNotEmpty ? _invoiceNumberController.text : 'Auto-Gen',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF065F46)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3 & 4 WIDGET: SELECT ROUTE & SELECT OUTLET
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRouteAndOutletCard(
    ThemeData theme,
    bool isDark,
    List<String> routes,
    List<Customer> outlets,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 3 Header & Route Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.alt_route_rounded, size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Text(
                    '3. Select Route',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _showAddNewRouteDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Route', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              ),
            ],
          ),
          const SizedBox(height: 6),

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
                icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF2563EB)),
                items: routes.map((route) {
                  return DropdownMenuItem<String>(
                    value: route,
                    child: Text(
                      route,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedRoute = val;
                      _selectedOutlet = null; // reset outlet when route changes
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Step 4 Header & Outlet Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    '4. Select Outlet (From Route)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _showAddNewOutletDialog,
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF10B981)),
                label: const Text(
                  'Add Outlet',
                  style: TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Outlet Dropdown / Selected Tile
          if (_selectedOutlet != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.store_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedOutlet!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (_selectedOutlet!.phone.isNotEmpty)
                          Text(
                            '📞 ${_selectedOutlet!.phone}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        if (_selectedOutlet!.address.isNotEmpty)
                          Text(
                            '📍 ${_selectedOutlet!.address}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedOutlet = null;
                      });
                    },
                    child: const Text('Change', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Customer>(
                  hint: Text(
                    outlets.isNotEmpty
                        ? 'Select Outlet from $_selectedRoute (${outlets.length} available)'
                        : 'No outlets on this route yet. Click + Add Outlet',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF10B981)),
                  items: outlets.map((outlet) {
                    return DropdownMenuItem<Customer>(
                      value: outlet,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              outlet.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (outlet.phone.isNotEmpty)
                            Text(
                              outlet.phone,
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedOutlet = val;
                      });
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
  // STEP 5 WIDGET: ADD PRODUCT & ITEMS LIST
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProductsCard(ThemeData theme, bool isDark, InvoiceProvider provider) {
    final items = provider.selectedItems;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Add Product button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2_rounded, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  const Text(
                    '5. Products',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length} items',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => SimpleProductPickerModal.show(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('+ Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items List
          if (items.isEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => SimpleProductPickerModal.show(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_shopping_cart_rounded, size: 36, color: Color(0xFF2563EB)),
                    const SizedBox(height: 8),
                    const Text(
                      'No products added yet',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click "+ Add Product" to select Company › Category › Subcategory › Unit (Pcs, Box, Outer)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (ctx, index) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final item = items[idx];
                final unitLabel = item.unit != null && item.unit!.isNotEmpty ? item.unit! : 'Pcs';

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unit Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: unitLabel == 'Outer'
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                            : (unitLabel == 'Box'
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                : const Color(0xFF2563EB).withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        unitLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: unitLabel == 'Outer'
                              ? const Color(0xFF7C3AED)
                              : (unitLabel == 'Box' ? const Color(0xFFD97706) : const Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name.isNotEmpty ? item.product.name : (item.itemName ?? 'Product'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.quantity} × ${_currency.format(item.unitPrice)} | GST: ${item.taxPercentage.toStringAsFixed(0)}% (${_currency.format(item.taxAmount)})',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),

                    // Total for this item (Net amount after GST)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currency.format(item.total),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Taxable: ${_currency.format(item.subtotal)}',
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),

                    // Remove button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      onPressed: () {
                        provider.removeProduct(item.id);
                      },
                      padding: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove',
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
  // STEP 6 WIDGET: NET AMOUNT CALCULATION (Exact GST Handling)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCalculationCard(
    ThemeData theme,
    bool isDark,
    double taxableSubtotal,
    double totalTax,
    double rawGrandTotal,
    double netAmount,
    double roundOffDifference,
  ) {
    final halfGst = totalTax / 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_rounded, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                '6. Calculation & Net Amount',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 18),

          // Subtotal
          _buildCalculationRow(
            label: 'Taxable Subtotal:',
            value: _currency.format(taxableSubtotal),
            isBold: false,
          ),
          const SizedBox(height: 6),

          // CGST & SGST (Half each)
          _buildCalculationRow(
            label: 'CGST (Central GST):',
            value: _currency.format(halfGst),
            valueColor: const Color(0xFFD97706),
            isBold: false,
          ),
          const SizedBox(height: 6),
          _buildCalculationRow(
            label: 'SGST (State GST):',
            value: _currency.format(halfGst),
            valueColor: const Color(0xFFD97706),
            isBold: false,
          ),
          const SizedBox(height: 6),

          // Total GST
          _buildCalculationRow(
            label: 'Total GST Amount:',
            value: _currency.format(totalTax),
            valueColor: const Color(0xFFD97706),
            isBold: true,
          ),
          const SizedBox(height: 6),

          // Round Off
          if (_roundOff && roundOffDifference.abs() > 0.001) ...[
            _buildCalculationRow(
              label: 'Round Off:',
              value: '${roundOffDifference >= 0 ? '+' : ''}${_currency.format(roundOffDifference)}',
              isBold: false,
            ),
            const SizedBox(height: 6),
          ],

          const Divider(height: 18),

          // NET AMOUNT (Highlight)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NET AMOUNT',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                    ),
                    Text(
                      '(Total Payable after GST)',
                      style: TextStyle(fontSize: 10, color: Color(0xFF047857)),
                    ),
                  ],
                ),
                Text(
                  _currency.format(netAmount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment Mode Options
          const Text('Payment Mode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ['Cash', 'UPI', 'Cheque', 'Credit / Due'].map((mode) {
              final isSelected = _selectedPaymentMode == mode;
              return ChoiceChip(
                label: Text(mode),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedPaymentMode = mode),
                selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF2563EB) : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Mark as Paid Checkbox
          CheckboxListTile(
            title: const Text('Mark invoice as Fully Paid', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

  Widget _buildCalculationRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STICKY BOTTOM BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStickyBottomBar(
    ThemeData theme,
    bool isDark,
    InvoiceProvider provider,
    double netAmount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            // Net Amount Summary
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Amount (${provider.selectedItems.length} items):',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    _currency.format(netAmount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Save Invoice Button
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
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Invoice',
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
