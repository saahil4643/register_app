import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/invoice_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../widgets/customer_autocomplete.dart';
import '../../widgets/invoice_item_card.dart';
import '../../widgets/totals_card.dart';
import '../../widgets/product_autocomplete.dart';
import '../../../customers/models/customer.dart';
import '../../../customers/providers/customer_provider.dart';

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
  late TextEditingController _notesController;
  late TextEditingController _termsController;
  late TextEditingController _referenceController;
  late TextEditingController _salespersonController;
  
  double _shipping = 0.0;
  double _adjustment = 0.0;
  String _selectedPaymentMethod = 'Bank Transfer';
  String _selectedPaymentTerms = 'Due on Receipt';
  String _selectedCurrency = 'INR (₹)';

  Timer? _autosaveTimer;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<InvoiceProvider>();

    // A create route must never reuse the invoice left in the shared provider.
    // Without this reset, returning from a sent/paid invoice can make this
    // screen issue a PUT request instead of creating a new draft.
    if (!widget.isEditing && provider.editingInvoice != null) {
      provider.startNewInvoice();
    }

    _notesController = TextEditingController(text: provider.notes);
    _termsController = TextEditingController(text: provider.terms);
    _referenceController = TextEditingController();
    _salespersonController = TextEditingController();
    
    // Set up autosave mock timer (runs every 45 seconds if form is valid)
    _autosaveTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      _triggerAutosave();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = context.read<SettingsProvider>();
      final autoNumberGen = settingsProvider.financialSettings?.autoNumberGeneration ?? true;
      if (autoNumberGen && !widget.isEditing) {
        context.read<InvoiceProvider>().loadNextInvoiceNumber();
      }
    });
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _notesController.dispose();
    _termsController.dispose();
    _referenceController.dispose();
    _salespersonController.dispose();
    super.dispose();
  }

  void _triggerAutosave() async {
    final provider = context.read<InvoiceProvider>();
    if (provider.selectedCustomer != null && provider.selectedItems.isNotEmpty && _hasUnsavedChanges) {
      final success = await provider.saveInvoice(
        shippingCharges: _shipping,
        adjustment: _adjustment,
        paymentTerms: _selectedPaymentTerms,
        referenceNumber: _referenceController.text,
        salesperson: _salespersonController.text,
        currency: _selectedCurrency,
      );
      if (success) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Draft autosaved successfully.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }

  void _selectInvoiceDate(BuildContext context, InvoiceProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.invoiceDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      provider.updateInvoiceDate(picked);
      _markChanged();
    }
  }

  void _selectDueDate(BuildContext context, InvoiceProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.dueDate,
      firstDate: provider.invoiceDate,
      lastDate: provider.invoiceDate.add(const Duration(days: 365)),
    );
    if (picked != null) {
      provider.updateDueDate(picked);
      _markChanged();
    }
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    final provider = context.read<InvoiceProvider>();
    if (_hasUnsavedChanges && (provider.selectedCustomer != null || provider.selectedItems.isNotEmpty)) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes?'),
          content: const Text('You have unsaved changes. Do you want to discard them and go back?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 36),
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<InvoiceProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final autoNumberGen = settingsProvider.financialSettings?.autoNumberGeneration ?? true;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Invoice' : 'Create Invoice'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              if (provider.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Customer Autocomplete / Details
                      if (provider.selectedCustomer != null)
                        CustomerDetailsCard(
                          customer: provider.selectedCustomer!,
                          onClear: () {
                            provider.selectCustomer(null);
                            _markChanged();
                          },
                        )
                      else
                        Card(
                          elevation: 0,
                          color: isDark ? theme.colorScheme.surface : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CUSTOMER INFORMATION',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CustomerSearchField(
                                  initialSelected: null,
                                  onSelected: (customer) {
                                    provider.selectCustomer(customer);
                                    _markChanged();
                                  },
                                  onCreateNewTap: (query) => context.push('/invoices/create/add-customer', extra: query),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (provider.fieldErrors.containsKey('customer') || provider.fieldErrors.containsKey('customer_id'))
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                          child: Text(
                            provider.fieldErrors['customer']?.toString() ?? provider.fieldErrors['customer_id']?.toString() ?? '',
                            style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Section 2: Invoice Info Card
                      _buildInvoiceInfoCard(theme, isDark, provider, autoNumberGen),
                      const SizedBox(height: 16),

                      // Section 3: Invoice Items Table Card
                      _buildItemsCard(theme, isDark, provider),
                      if (provider.fieldErrors.containsKey('items'))
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                          child: Text(
                            provider.fieldErrors['items']?.toString() ?? '',
                            style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Section 4: Totals Calculations
                      if (provider.selectedItems.isNotEmpty) ...[
                        TotalsCard(
                          subtotal: provider.subtotal,
                          discount: provider.totalDiscount,
                          tax: provider.totalTax,
                          shipping: _shipping,
                          adjustment: _adjustment,
                          isPaid: provider.isPaid,
                          onPaidChanged: (val) {
                            provider.updateIsPaid(val);
                            _markChanged();
                          },
                          onShippingChanged: (val) {
                            setState(() {
                              _shipping = val;
                              _markChanged();
                            });
                          },
                          onAdjustmentChanged: (val) {
                            setState(() {
                              _adjustment = val;
                              _markChanged();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Section 5: Payment Info Card
                      _buildPaymentInfoCard(theme, isDark),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Action Bar
              _buildStickyActionBar(theme, isDark, provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceInfoCard(ThemeData theme, bool isDark, InvoiceProvider provider, bool autoNumberGen) {
    final bool isNumberEditable = !autoNumberGen && !widget.isEditing;
    String initialVal = provider.invoiceNumber;
    if (isNumberEditable && initialVal == 'Auto-Generated') {
      initialVal = '';
    } else if (initialVal == 'Auto-Generated' && autoNumberGen) {
      final settingsProvider = context.read<SettingsProvider>();
      initialVal = provider.getNextInvoiceNumberFallback(settingsProvider.financialSettings);
    }

    return Card(
      elevation: 0,
      color: isDark ? theme.colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INVOICE DETAILS',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              initialValue: initialVal,
              key: ValueKey('${provider.invoiceNumber}_${autoNumberGen}_${widget.isEditing}'),
              readOnly: !isNumberEditable,
              decoration: InputDecoration(
                labelText: isNumberEditable
                    ? 'Invoice Number *'
                    : (autoNumberGen && !widget.isEditing
                        ? 'Invoice Number (Auto-Generated)'
                        : 'Invoice Number'),
                prefixIcon: const Icon(Icons.tag_rounded),
                hintText: isNumberEditable ? 'e.g. KC-001' : null,
                filled: !isNumberEditable,
                fillColor: !isNumberEditable
                    ? (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100])
                    : null,
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isNumberEditable
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
              onChanged: isNumberEditable
                  ? (val) {
                      provider.updateInvoiceNumber(val.trim());
                      _markChanged();
                    }
                  : null,
              validator: (val) {
                if (isNumberEditable && (val == null || val.trim().isEmpty)) {
                  return 'Invoice number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('invoice_date_${provider.invoiceDate.millisecondsSinceEpoch}'),
                    initialValue: DateFormat('dd MMM yyyy').format(provider.invoiceDate),
                    readOnly: true,
                    onTap: () => _selectInvoiceDate(context, provider),
                    decoration: const InputDecoration(
                      labelText: 'Invoice Date',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                if (!provider.isPaid) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('due_date_${provider.dueDate.millisecondsSinceEpoch}'),
                      initialValue: DateFormat('dd MMM yyyy').format(provider.dueDate),
                      readOnly: true,
                      onTap: () => _selectDueDate(context, provider),
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        prefixIcon: Icon(Icons.event_busy_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!provider.isPaid) ...[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedPaymentTerms,
                      decoration: const InputDecoration(
                        labelText: 'Payment Terms',
                        prefixIcon: Icon(Icons.schedule_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: ['Due on Receipt', 'Net 15', 'Net 30', 'Net 45', 'Net 60']
                          .map((terms) => DropdownMenuItem(value: terms, child: Text(terms, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPaymentTerms = val;
                          });
                          _markChanged();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: TextFormField(
                    controller: _referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Reference Number',
                      prefixIcon: Icon(Icons.receipt_rounded),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (val) => _markChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _salespersonController,
                    decoration: const InputDecoration(
                      labelText: 'Salesperson',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (val) => _markChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Icon(Icons.currency_exchange_rounded),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: ['INR (₹)', 'USD (\$)', 'EUR (€)', 'GBP (£)']
                        .map((curr) => DropdownMenuItem(value: curr, child: Text(curr, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCurrency = val;
                        });
                        _markChanged();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(ThemeData theme, bool isDark, InvoiceProvider provider) {
    return Card(
      elevation: 0,
      color: isDark ? theme.colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PRODUCTS & SERVICES',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    context.push('/invoices/products');
                  },
                  icon: const Icon(Icons.apps_rounded, size: 14),
                  label: const Text('Catalog Picker'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ProductSearchField(
              onSelected: (product) {
                provider.addProduct(product);
                _markChanged();
              },
            ),
            const SizedBox(height: 8),
            if (provider.selectedItems.isEmpty) ...[
              const Divider(height: 16),
              InkWell(
                onTap: () => context.push('/invoices/products'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder.withOpacity(0.3) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No Items Added',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Type above or tap here to open the catalog',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Divider(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.selectedItems.length,
                itemBuilder: (context, index) {
                  final item = provider.selectedItems[index];
                  return InvoiceItemCard(
                    item: item,
                    onQtyChanged: (newQty) {
                      provider.updateItemQty(item.product.id, newQty);
                      _markChanged();
                    },
                    onDiscountChanged: (disc) {
                      provider.updateItemDiscount(item.product.id, disc);
                      _markChanged();
                    },
                    onTaxChanged: (tax) {
                      provider.updateItemTax(item.product.id, tax);
                      _markChanged();
                    },
                    onRemove: () {
                      provider.removeProduct(item.product.id);
                      _markChanged();
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard(ThemeData theme, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? theme.colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PAYMENT INSTRUCTIONS',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Preferred Payment Method',
                prefixIcon: Icon(Icons.payment_rounded),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: ['Bank Transfer', 'UPI', 'Cheque', 'Credit Card', 'Cash']
                  .map((method) => DropdownMenuItem(value: method, child: Text(method, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedPaymentMethod = val;
                  });
                  _markChanged();
                }
              },
            ),
            if (_selectedPaymentMethod == 'UPI') ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('payment_method_upi'),
                initialValue: 'prabhimone@upi',
                decoration: const InputDecoration(
                  labelText: 'UPI ID for Payment',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                onChanged: (val) => _markChanged(),
              ),
            ] else if (_selectedPaymentMethod == 'Bank Transfer' || _selectedPaymentMethod == 'Cheque' || _selectedPaymentMethod == 'Credit Card') ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('payment_method_bank'),
                initialValue: 'HDFC Bank - A/C 5010023456789 (IFSC: HDFC0000123)',
                decoration: const InputDecoration(
                  labelText: 'Company Bank Details',
                  prefixIcon: Icon(Icons.account_balance_rounded),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (val) => _markChanged(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStickyActionBar(ThemeData theme, bool isDark, InvoiceProvider provider) {
    final isValid = provider.selectedCustomer != null && provider.selectedItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: isValid
                    ? () async {
                        // Save draft: the provider sets status to Draft by default
                        final success = await provider.saveInvoice(
                          shippingCharges: _shipping,
                          adjustment: _adjustment,
                          paymentTerms: _selectedPaymentTerms,
                          referenceNumber: _referenceController.text,
                          salesperson: _salespersonController.text,
                          currency: _selectedCurrency,
                        );
                        if (!mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Draft ${provider.invoiceNumber} saved! Opening PDF preview...'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          context.push('/invoices/preview');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(provider.errorMessage ?? 'Failed to save draft invoice'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isValid ? theme.colorScheme.primary : Colors.grey.withOpacity(0.3)),
                ),
                child: const Text('Save Draft'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: isValid
                    ? () async {
                        final success = await provider.saveInvoice(
                          shippingCharges: _shipping,
                          adjustment: _adjustment,
                          paymentTerms: _selectedPaymentTerms,
                          referenceNumber: _referenceController.text,
                          salesperson: _salespersonController.text,
                          currency: _selectedCurrency,
                        );
                        if (success) {
                          final savedId = provider.editingInvoice?.id ?? (provider.invoices.isNotEmpty ? provider.invoices.last.id : '');
                          if (savedId.isNotEmpty) {
                            await provider.markAsSent(savedId);
                          }
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Invoice ${provider.invoiceNumber} created! Opening PDF preview...'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          context.push('/invoices/preview');
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(provider.errorMessage ?? 'Failed to save invoice'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    : () {
                        String message = 'Please select a customer and add at least one product.';
                        if (provider.selectedCustomer == null && provider.selectedItems.isEmpty) {
                          message = 'Select customer and add products first.';
                        } else if (provider.selectedCustomer == null) {
                          message = 'Select a customer first.';
                        } else if (provider.selectedItems.isEmpty) {
                          message = 'Add at least one product first.';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.error,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid ? theme.colorScheme.primary : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save & Preview'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline add-customer form — no showDialog, no ModalBarrier, no overlay.
// Shown directly inside the page scroll view so there are zero unsized
// render objects; the mouse_tracker assertion is structurally impossible.
// ─────────────────────────────────────────────────────────────────────────────
class _AddCustomerInlinePanel extends StatefulWidget {
  final String prefillName;
  final ValueChanged<Customer> onSaved;
  final VoidCallback onCancel;

  const _AddCustomerInlinePanel({
    required this.prefillName,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<_AddCustomerInlinePanel> createState() =>
      _AddCustomerInlinePanelState();
}

class _AddCustomerInlinePanelState extends State<_AddCustomerInlinePanel> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _addressCtrl;
  late final FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.prefillName);
    _companyCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _gstCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _nameFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstCtrl.dispose();
    _addressCtrl.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final customerProvider =
          context.read<CustomerProvider>();
      final newCustomer = Customer(
        id: '',
        name: _nameCtrl.text.trim(),
        company: _companyCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        gstNo: _gstCtrl.text.trim(),
        creditLimit: 50000.0,
        outstanding: 0.0,
        notes: '',
        createdAt: DateTime.now(),
      );
      final created = await customerProvider.createCustomer(newCustomer);
      if (!mounted) return;
      if (created != null) {
        widget.onSaved(created);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer "${created.name}" created!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                customerProvider.errorMessage ?? 'Failed to create customer'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? theme.colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  Icon(Icons.person_add_rounded,
                      color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'NEW CUSTOMER',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Cancel',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameCtrl,
                focusNode: _nameFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Contact Name *',
                  hintText: 'Enter full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter mobile number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter email address',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter billing / shipping address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _gstCtrl,
                decoration: const InputDecoration(
                  labelText: 'GST Number',
                  hintText: 'e.g. 27AABCU9603R1ZX',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  final gst = val.trim().toUpperCase();
                  final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                  if (!gstRegex.hasMatch(gst)) {
                    return 'Invalid GSTIN (e.g. 27AABCU9603R1ZX)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  hintText: 'Enter company / business name',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(_isLoading ? 'Saving...' : 'Save Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
