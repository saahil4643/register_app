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
import '../../models/invoice_item.dart';

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
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  // Customer
  Customer? _selectedCustomer;

  // Invoice Details
  late TextEditingController _invoiceNumberController;
  late DateTime _invoiceDate;
  late DateTime _dueDate;
  String _paymentTerms = 'Due on Receipt';

  // Notes & Terms
  late TextEditingController _notesController;
  late TextEditingController _termsController;

  // Payment Options
  bool _markAsPaid = false;
  String _paymentMode = 'Bank Transfer';
  final bool _roundOff = true;
  bool _isSaving = false;

  final List<String> _paymentTermsOptions = [
    'Due on Receipt',
    'Net 15',
    'Net 30',
    'Net 45',
    'Net 60',
  ];

  final List<String> _paymentModeOptions = [
    'Bank Transfer',
    'UPI',
    'Cash',
    'Cheque',
    'Card',
  ];

  @override
  void initState() {
    super.initState();
    final invoiceProvider = context.read<InvoiceProvider>();

    if (!widget.isEditing) {
      invoiceProvider.startNewInvoice();
      _invoiceDate = DateTime.now();
      _dueDate = DateTime.now();
      _invoiceNumberController = TextEditingController(
        text: invoiceProvider.invoiceNumber.isNotEmpty && invoiceProvider.invoiceNumber != 'Auto-Generated'
            ? invoiceProvider.invoiceNumber
            : 'INV-${DateFormat('yyyyMMdd').format(DateTime.now())}-01',
      );
      _notesController = TextEditingController(text: 'Thank you for your business.');
      _termsController = TextEditingController(text: 'Payment is due within agreed terms.');
    } else {
      final editing = invoiceProvider.editingInvoice;
      _invoiceDate = editing?.invoiceDate ?? invoiceProvider.invoiceDate;
      _dueDate = editing?.dueDate ?? invoiceProvider.dueDate;
      _invoiceNumberController = TextEditingController(
        text: editing?.invoiceNumber ?? invoiceProvider.invoiceNumber,
      );
      _selectedCustomer = editing?.customer ?? invoiceProvider.selectedCustomer;
      _markAsPaid = invoiceProvider.isPaid;
      _notesController = TextEditingController(text: editing?.notes ?? 'Thank you for your business.');
      _termsController = TextEditingController(text: editing?.terms ?? 'Payment is due within agreed terms.');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
      context.read<ProductProvider>().fetchProducts();
      invoiceProvider.loadNextInvoiceNumber().then((_) {
        if (!widget.isEditing && invoiceProvider.invoiceNumber.isNotEmpty && invoiceProvider.invoiceNumber != 'Auto-Generated') {
          if (mounted) {
            setState(() {
              _invoiceNumberController.text = invoiceProvider.invoiceNumber;
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _onPaymentTermsChanged(String? newTerms) {
    if (newTerms == null) return;
    setState(() {
      _paymentTerms = newTerms;
      switch (newTerms) {
        case 'Due on Receipt':
          _dueDate = _invoiceDate;
          break;
        case 'Net 15':
          _dueDate = _invoiceDate.add(const Duration(days: 15));
          break;
        case 'Net 30':
          _dueDate = _invoiceDate.add(const Duration(days: 30));
          break;
        case 'Net 45':
          _dueDate = _invoiceDate.add(const Duration(days: 45));
          break;
        case 'Net 60':
          _dueDate = _invoiceDate.add(const Duration(days: 60));
          break;
      }
    });
  }

  Future<void> _pickInvoiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.lightPrimary,
            onPrimary: Colors.white,
            onSurface: AppColors.lightTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _invoiceDate = picked;
        _onPaymentTermsChanged(_paymentTerms);
      });
      context.read<InvoiceProvider>().updateInvoiceDate(picked);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(_invoiceDate) ? _invoiceDate : _dueDate,
      firstDate: _invoiceDate,
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.lightPrimary,
            onPrimary: Colors.white,
            onSurface: AppColors.lightTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
      context.read<InvoiceProvider>().updateDueDate(picked);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Customer Selector Modal
  // ─────────────────────────────────────────────────────────────────────────
  void _showCustomerPickerSheet() {
    final customerProvider = context.read<CustomerProvider>();
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = customerProvider.customers.where((c) {
              if (query.isEmpty) return true;
              return c.name.toLowerCase().contains(query) ||
                  c.phone.toLowerCase().contains(query) ||
                  c.companyName.toLowerCase().contains(query) ||
                  c.email.toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Customer',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _showAddNewCustomerDialog();
                        },
                        icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.lightPrimary),
                        label: const Text(
                          'New Customer',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by client name, company, or phone...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quick Option: Walk-in / Cash Client
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    tileColor: const Color(0xFFF9FAFB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.lightPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: AppColors.lightPrimary, size: 20),
                    ),
                    title: const Text('Walk-in Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Direct retail or cash sale client', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    onTap: () {
                      final walkIn = Customer(
                        id: 'CUST-WALKIN',
                        displayName: 'Walk-in Customer',
                        companyName: 'Cash Sale',
                        createdAt: DateTime.now(),
                      );
                      setState(() => _selectedCustomer = walkIn);
                      context.read<InvoiceProvider>().selectCustomer(walkIn);
                      Navigator.pop(sheetCtx);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_search_outlined, size: 40, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  customerProvider.customers.isEmpty
                                      ? 'No customers added yet'
                                      : 'No matching customers found',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final cust = filtered[idx];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.lightPrimary.withValues(alpha: 0.1),
                                  child: Text(
                                    cust.displayName.isNotEmpty ? cust.displayName[0].toUpperCase() : 'C',
                                    style: const TextStyle(color: AppColors.lightPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(cust.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text(
                                  [
                                    if (cust.companyName.isNotEmpty && cust.companyName != cust.displayName) cust.companyName,
                                    if (cust.primaryPhone.isNotEmpty) cust.primaryPhone,
                                    if (cust.gstNumber.isNotEmpty) 'GST: ${cust.gstNumber}',
                                  ].join(' • '),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                                onTap: () {
                                  setState(() => _selectedCustomer = cust);
                                  context.read<InvoiceProvider>().selectCustomer(cust);
                                  Navigator.pop(sheetCtx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Add New Customer Dialog
  // ─────────────────────────────────────────────────────────────────────────
  void _showAddNewCustomerDialog() {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final gstCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Customer / Contact Name *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Company / Business Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: gstCtrl,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN (Optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Billing Address',
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
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newCust = Customer(
                  id: 'CUST-${DateTime.now().millisecondsSinceEpoch}',
                  displayName: nameCtrl.text.trim(),
                  companyName: companyCtrl.text.trim().isNotEmpty ? companyCtrl.text.trim() : nameCtrl.text.trim(),
                  primaryPhone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  gstNumber: gstCtrl.text.trim(),
                  billingAddressLine1: addressCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );

                await context.read<CustomerProvider>().createCustomer(newCust);
                if (mounted) {
                  setState(() => _selectedCustomer = newCust);
                  context.read<InvoiceProvider>().selectCustomer(newCust);
                }
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Add Line Item Modal
  // ─────────────────────────────────────────────────────────────────────────
  void _showAddLineItemSheet() {
    final productProvider = context.read<ProductProvider>();
    final invoiceProvider = context.read<InvoiceProvider>();

    int selectedTab = 0; // 0 = Catalog, 1 = Custom Item
    final searchCtrl = TextEditingController();

    // Custom Item Form
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final rateCtrl = TextEditingController();
    String unit = 'Nos';
    double taxPercentage = 18.0;

    final units = ['Nos', 'Pcs', 'Box', 'Kg', 'Mtr', 'Hours', 'Service', 'Set'];
    final taxRates = [0.0, 5.0, 12.0, 18.0, 28.0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final products = productProvider.products.where((p) {
              if (query.isEmpty) return true;
              return p.name.toLowerCase().contains(query) ||
                  p.sku.toLowerCase().contains(query) ||
                  p.category.toLowerCase().contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.80,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Line Item',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Clean Tab Switcher
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() => selectedTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedTab == 0 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: selectedTab == 0
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Product Catalog',
                                    style: TextStyle(
                                      fontWeight: selectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                                      color: selectedTab == 0 ? AppColors.lightPrimary : Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() => selectedTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedTab == 1 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: selectedTab == 1
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Custom Item / Service',
                                    style: TextStyle(
                                      fontWeight: selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                                      color: selectedTab == 1 ? AppColors.lightPrimary : Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // TAB 0: CATALOG ITEMS
                    if (selectedTab == 0) ...[
                      TextField(
                        controller: searchCtrl,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search products by name or SKU...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: products.isEmpty
                            ? Center(
                                child: Text('No products found', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              )
                            : ListView.separated(
                                itemCount: products.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final p = products[idx];
                                  final rate = p.price > 0 ? p.price : (p.sellingPrice > 0 ? p.sellingPrice : 0.0);

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    subtitle: Text(
                                      'Rate: ${_currency.format(rate)} • GST: ${p.gst.toStringAsFixed(0)}% • Stock: ${p.stock}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    trailing: OutlinedButton(
                                      onPressed: () {
                                        invoiceProvider.addOrIncrementProduct(p);
                                        Navigator.pop(sheetCtx);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.lightPrimary,
                                        side: const BorderSide(color: AppColors.lightPrimary),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ] else ...[
                      // TAB 1: CUSTOM ITEM FORM
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Item or Service Name *',
                                  hintText: 'e.g. Consulting Services or Custom Material',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: descCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Description / HSN Code',
                                  hintText: 'e.g. SAC 998311 - Technical Consulting',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: qtyCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Quantity',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: unit,
                                      decoration: const InputDecoration(
                                        labelText: 'Unit',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
                                      onChanged: (v) => setSheetState(() => unit = v ?? 'Nos'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: rateCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Unit Rate (₹) *',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<double>(
                                value: taxPercentage,
                                decoration: const InputDecoration(
                                  labelText: 'GST Tax Rate',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: taxRates.map((r) => DropdownMenuItem(value: r, child: Text('${r.toStringAsFixed(0)}% GST', style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (v) => setSheetState(() => taxPercentage = v ?? 18.0),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final name = nameCtrl.text.trim();
                                    final rate = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
                                    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;

                                    if (name.isEmpty || rate <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter valid item name and rate.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }

                                    invoiceProvider.addCustomItem(
                                      name: name,
                                      price: rate,
                                      quantity: qty > 0 ? qty : 1,
                                      taxPercentage: taxPercentage,
                                      unit: unit,
                                    );

                                    Navigator.pop(sheetCtx);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.lightPrimary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Add to Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Save Invoice
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _saveInvoice({required bool isDraft}) async {
    final invoiceProvider = context.read<InvoiceProvider>();

    if (invoiceProvider.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one line item to the invoice.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // If customer not chosen, prompt or fallback to Walk-in client
    final effectiveCustomer = _selectedCustomer ?? Customer(
      id: 'CUST-WALKIN',
      displayName: 'Walk-in Customer',
      companyName: 'Cash Sale',
      createdAt: DateTime.now(),
    );

    invoiceProvider.selectCustomer(effectiveCustomer);
    invoiceProvider.updateInvoiceDate(_invoiceDate);
    invoiceProvider.updateDueDate(_dueDate);
    invoiceProvider.updateInvoiceNumber(_invoiceNumberController.text.trim());

    final success = await invoiceProvider.saveInvoice(
      isDraft: isDraft,
      markAsFullyPaid: _markAsPaid,
      paymentMode: _paymentMode,
      paymentTerms: _paymentTerms,
      notes: _notesController.text.trim(),
      termsAndConditions: _termsController.text.trim(),
      isRoundOff: _roundOff,
      mobileNumber: effectiveCustomer.primaryPhone,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        _showInvoiceSuccessDialog(effectiveCustomer, isDraft);
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

  void _showInvoiceSuccessDialog(Customer customer, bool isDraft) {
    final invNum = _invoiceNumberController.text.trim();
    final grandTotal = context.read<InvoiceProvider>().grandTotal;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                isDraft ? 'Invoice Saved as Draft' : 'Invoice Created Successfully',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '$invNum • ${_currency.format(grandTotal)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.lightPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Billed to: ${customer.displayName}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/invoices');
            },
            child: const Text('View All Invoices'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final inv = context.read<InvoiceProvider>();
              inv.startNewInvoice();
              setState(() {
                _selectedCustomer = null;
                _invoiceDate = DateTime.now();
                _dueDate = DateTime.now();
              });
              inv.loadNextInvoiceNumber().then((_) {
                if (mounted && inv.invoiceNumber.isNotEmpty && inv.invoiceNumber != 'Auto-Generated') {
                  setState(() => _invoiceNumberController.text = inv.invoiceNumber);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('New Invoice'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final invoiceProvider = context.watch<InvoiceProvider>();

    final double taxableSubtotal = invoiceProvider.subtotal;
    final double totalTax = invoiceProvider.totalTax;
    final double rawGrandTotal = taxableSubtotal + totalTax;
    final double netAmount = _roundOff ? rawGrandTotal.roundToDouble() : rawGrandTotal;
    final double roundOffDifference = netAmount - rawGrandTotal;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.isEditing ? 'Edit Invoice' : 'New Invoice',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _saveInvoice(isDraft: true),
            child: Text(
              'Save Draft',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.grey[300] : AppColors.lightPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Reset Form',
            onPressed: () {
              invoiceProvider.startNewInvoice();
              setState(() => _selectedCustomer = null);
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE5E7EB), height: 1.0),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Customer (Bill To)
                    _buildSectionHeader('BILL TO'),
                    const SizedBox(height: 8),
                    _buildCustomerCard(theme, isDark),
                    const SizedBox(height: 20),

                    // Section 2: Invoice Metadata & Terms
                    _buildSectionHeader('INVOICE DETAILS'),
                    const SizedBox(height: 8),
                    _buildInvoiceDetailsCard(theme, isDark),
                    const SizedBox(height: 20),

                    // Section 3: Line Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('ITEMS & SERVICES'),
                        if (invoiceProvider.selectedItems.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.lightPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${invoiceProvider.selectedItems.length} ${invoiceProvider.selectedItems.length == 1 ? 'item' : 'items'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildLineItemsCard(theme, isDark, invoiceProvider),
                    const SizedBox(height: 20),

                    // Section 4: Summary & Tax Breakdown
                    _buildSectionHeader('SUMMARY & TAXES'),
                    const SizedBox(height: 8),
                    _buildSummaryCard(
                      theme,
                      isDark,
                      taxableSubtotal,
                      totalTax,
                      netAmount,
                      roundOffDifference,
                    ),
                    const SizedBox(height: 20),

                    // Section 5: Terms & Notes
                    _buildSectionHeader('NOTES & TERMS'),
                    const SizedBox(height: 8),
                    _buildNotesCard(theme, isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Checkout Bar
            _buildBottomActionBar(theme, isDark, invoiceProvider, netAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Colors.grey[600],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 1: CUSTOMER CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCustomerCard(ThemeData theme, bool isDark) {
    if (_selectedCustomer == null) {
      return InkWell(
        onTap: _showCustomerPickerSheet,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_outlined, color: AppColors.lightPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Customer',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.lightTextPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose an existing client or tap to add a new profile',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    final cust = _selectedCustomer!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.lightPrimary.withValues(alpha: 0.1),
                    child: Text(
                      cust.displayName.isNotEmpty ? cust.displayName[0].toUpperCase() : 'C',
                      style: const TextStyle(color: AppColors.lightPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cust.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.lightTextPrimary),
                      ),
                      if (cust.companyName.isNotEmpty && cust.companyName != cust.displayName)
                        Text(
                          cust.companyName,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: _showCustomerPickerSheet,
                child: const Text('Change', style: TextStyle(color: AppColors.lightPrimary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (cust.primaryPhone.isNotEmpty || cust.email.isNotEmpty || cust.gstNumber.isNotEmpty || cust.billingAddressLine1.isNotEmpty) ...[
            const Divider(height: 20),
            if (cust.primaryPhone.isNotEmpty || cust.email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    if (cust.primaryPhone.isNotEmpty) ...[
                      const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(cust.primaryPhone, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      const SizedBox(width: 12),
                    ],
                    if (cust.email.isNotEmpty) ...[
                      const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(cust.email, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ],
                  ],
                ),
              ),
            if (cust.gstNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('GSTIN: ${cust.gstNumber}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                ),
              ),
            if (cust.billingAddressLine1.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [cust.billingAddressLine1, cust.billingCity, cust.billingState].where((s) => s.isNotEmpty).join(', '),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 2: INVOICE DETAILS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInvoiceDetailsCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Invoice Number
              Expanded(
                child: TextFormField(
                  controller: _invoiceNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Invoice Number',
                    prefixIcon: Icon(Icons.tag_rounded, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    isDense: true,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              // Invoice Date
              Expanded(
                child: InkWell(
                  onTap: _pickInvoiceDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Invoice Date',
                      prefixIcon: Icon(Icons.calendar_today_rounded, size: 16),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      isDense: true,
                    ),
                    child: Text(
                      _dateFormat.format(_invoiceDate),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Payment Terms
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _paymentTerms,
                  decoration: const InputDecoration(
                    labelText: 'Payment Terms',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    isDense: true,
                  ),
                  items: _paymentTermsOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: _onPaymentTermsChanged,
                ),
              ),
              const SizedBox(width: 12),
              // Due Date
              Expanded(
                child: InkWell(
                  onTap: _pickDueDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      prefixIcon: Icon(Icons.event_available_rounded, size: 16),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      isDense: true,
                    ),
                    child: Text(
                      _dateFormat.format(_dueDate),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 3: LINE ITEMS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLineItemsCard(ThemeData theme, bool isDark, InvoiceProvider provider) {
    final items = provider.selectedItems;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No line items added yet',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap below to add products or custom services to this invoice',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (context, idx) {
                final item = items[idx];
                final displayName = (item.itemName != null && item.itemName!.isNotEmpty)
                    ? item.itemName!
                    : (item.product.name.isNotEmpty ? item.product.name : 'Line Item');

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.lightTextPrimary),
                          ),
                          if (item.description.isNotEmpty && item.description != displayName)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                item.description,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${item.quantity} ${item.unit ?? 'Nos'} × ${_currency.format(item.unitPrice)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.taxPercentage.toStringAsFixed(0)}% GST',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currency.format(item.total),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.lightTextPrimary),
                        ),
                        const SizedBox(height: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _showAddLineItemSheet,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('+ Add Line Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.lightPrimary,
                side: const BorderSide(color: AppColors.lightPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 4: SUMMARY & TAXES CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSummaryCard(
    ThemeData theme,
    bool isDark,
    double taxableSubtotal,
    double totalTax,
    double netAmount,
    double roundOffDifference,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal (Taxable)', _currency.format(taxableSubtotal)),
          const SizedBox(height: 6),
          _buildSummaryRow('Total GST Tax', _currency.format(totalTax)),
          if (roundOffDifference != 0.0) ...[
            const SizedBox(height: 6),
            _buildSummaryRow('Round Off', (roundOffDifference > 0 ? '+' : '') + _currency.format(roundOffDifference)),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount Due',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.lightTextPrimary),
              ),
              Text(
                _currency.format(netAmount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.lightPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mark as Paid', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Switch(
                      value: _markAsPaid,
                      activeColor: AppColors.lightPrimary,
                      onChanged: (v) => setState(() => _markAsPaid = v),
                    ),
                  ],
                ),
                if (_markAsPaid) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _paymentMode,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    items: _paymentModeOptions
                        .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _paymentMode = v ?? 'Bank Transfer'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 5: NOTES & TERMS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNotesCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Customer Notes',
              hintText: 'e.g. Thanks for your business.',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _termsController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Terms & Conditions',
              hintText: 'e.g. Payment is due within agreed terms.',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STICKY BOTTOM ACTION BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomActionBar(
    ThemeData theme,
    bool isDark,
    InvoiceProvider provider,
    double netAmount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Amount', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  Text(
                    _currency.format(netAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.lightPrimary),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isSaving ? null : () => _saveInvoice(isDraft: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
