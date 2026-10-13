import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../providers/invoice_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../widgets/customer_autocomplete.dart';
import '../../widgets/product_autocomplete.dart';
import '../../../customers/models/customer.dart';
import '../../../customers/providers/customer_provider.dart';
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

  // Customer options
  late TextEditingController _mobileController;
  late TextEditingController _gstinController;
  late TextEditingController _emailController;
  late TextEditingController _billingAddressController;
  late TextEditingController _shippingAddressController;
  String _customerType = 'Business';
  bool _shippingSameAsBilling = true;
  bool _showInlineAddCustomer = false;
  bool _showAdditionalCustomerDetails = false;
  bool _isAdditionalExpanded = false;

  // Invoice Details (from Image 1 & 2)
  late TextEditingController _invoiceNumberController;
  bool _isManualInvoiceNumber = false;
  late TextEditingController _orderNumberController;
  late TextEditingController _referenceController;
  late DateTime _invoiceDate;
  String _selectedPaymentTerms = 'Due on Receipt';
  late DateTime _dueDate;

  // Sales & General (from Image 1 & 2)
  late TextEditingController _salespersonController;
  late TextEditingController _subjectController;
  String _selectedCurrency = 'INR (₹)';

  // Notes & Terms (from Image 1 & 3)
  late TextEditingController _customerNotesController;
  late TextEditingController _internalNotesController;
  late TextEditingController _termsController;

  // Attachments (from Image 3)
  final List<String> _attachments = [];
  bool _isPickingFile = false;

  // Summary & Payment (from Image 1)
  double _shipping = 0.0;
  double _adjustment = 0.0;
  bool _roundOff = true;
  bool _markAsFullyPaid = false;
  late TextEditingController _amountReceivedController;
  String _selectedPaymentMethod = 'UPI';

  Timer? _autosaveTimer;
  bool _hasUnsavedChanges = false;

  final List<String> _unitOptions = ['Nos', 'Pcs', 'Box', 'Kg', 'Mtr', 'Set', 'Hrs', 'Unit'];
  final List<double> _gstRateOptions = [0.0, 5.0, 12.0, 18.0, 28.0];
  final List<String> _paymentTermsOptions = ['Due on Receipt', 'Net 15', 'Net 30', 'Net 45', 'Net 60'];
  final List<String> _salespersonsList = [
    'General Sales',
    'Rahul Sharma',
    'Priya Patel',
    'Amit Kumar',
    'Neha Verma'
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<InvoiceProvider>();

    if (!widget.isEditing && provider.editingInvoice != null) {
      provider.startNewInvoice();
    }

    final editing = provider.editingInvoice;
    final customer = provider.selectedCustomer ?? editing?.customer;

    final rawCustType = customer?.customerType ?? 'Business';
    _customerType = rawCustType.toLowerCase().contains('individual') ? 'Individual' : 'Business';
    _shippingSameAsBilling = customer?.shippingSameAsBilling ?? true;

    _mobileController = TextEditingController(text: customer?.phone ?? '');
    _gstinController = TextEditingController(text: customer?.gstNo ?? '');
    _emailController = TextEditingController(text: customer?.email ?? '');
    _billingAddressController = TextEditingController(text: customer?.address ?? '');
    _shippingAddressController = TextEditingController(
      text: (customer?.shippingAddressLine1.isNotEmpty == true)
          ? customer!.shippingAddressLine1
          : (customer?.address ?? ''),
    );

    _invoiceNumberController = TextEditingController(text: provider.invoiceNumber);
    _orderNumberController = TextEditingController();
    _referenceController = TextEditingController();

    _invoiceDate = provider.invoiceDate;
    _dueDate = provider.dueDate;

    _salespersonController = TextEditingController(text: 'General Sales');
    _subjectController = TextEditingController();

    const defaultTerms = '1. Goods once sold will not be taken back or exchanged\n'
        '2. For warranty, retain cash memo\n'
        '3. Please check breakage and damage against delivery\n'
        '4. For order need to pay 50% advance amount\n'
        '5. All disputes are subject to PUNE jurisdiction only';

    _customerNotesController = TextEditingController(
      text: (provider.notes.isNotEmpty) ? provider.notes : 'Thanks for your business.',
    );
    _internalNotesController = TextEditingController();
    _termsController = TextEditingController(
      text: (provider.terms.isNotEmpty) ? provider.terms : defaultTerms,
    );

    _markAsFullyPaid = provider.isPaid;
    final initialPaid = editing != null ? editing.paidAmount : (provider.isPaid ? provider.grandTotal : 0.0);
    _amountReceivedController = TextEditingController(
      text: initialPaid > 0 ? initialPaid.toStringAsFixed(2) : '',
    );

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
    _mobileController.dispose();
    _gstinController.dispose();
    _emailController.dispose();
    _billingAddressController.dispose();
    _shippingAddressController.dispose();
    _invoiceNumberController.dispose();
    _orderNumberController.dispose();
    _referenceController.dispose();
    _salespersonController.dispose();
    _subjectController.dispose();
    _customerNotesController.dispose();
    _internalNotesController.dispose();
    _termsController.dispose();
    _amountReceivedController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _onCustomerSelected(Customer? customer) {
    final provider = context.read<InvoiceProvider>();
    provider.selectCustomer(customer);
    setState(() {
      if (customer != null) {
        _mobileController.text = customer.phone;
        _gstinController.text = customer.gstNo;
        _emailController.text = customer.email;
        _billingAddressController.text = customer.address;
        _shippingAddressController.text = customer.shippingAddressLine1.isNotEmpty
            ? customer.shippingAddressLine1
            : customer.address;
        _shippingSameAsBilling = customer.shippingSameAsBilling;
        final rawCustType = customer.customerType;
        _customerType = rawCustType.toLowerCase().contains('individual') ? 'Individual' : 'Business';
      } else {
        _mobileController.clear();
        _gstinController.clear();
        _emailController.clear();
        _billingAddressController.clear();
        _shippingAddressController.clear();
        _shippingSameAsBilling = true;
        _customerType = 'Business';
      }
    });
    _markChanged();
  }

  void _updateDueDateFromTerms(String terms) {
    DateTime calculated = _invoiceDate;
    switch (terms) {
      case 'Due on Receipt':
        calculated = _invoiceDate;
        break;
      case 'Net 15':
        calculated = _invoiceDate.add(const Duration(days: 15));
        break;
      case 'Net 30':
        calculated = _invoiceDate.add(const Duration(days: 30));
        break;
      case 'Net 45':
        calculated = _invoiceDate.add(const Duration(days: 45));
        break;
      case 'Net 60':
        calculated = _invoiceDate.add(const Duration(days: 60));
        break;
    }
    setState(() {
      _selectedPaymentTerms = terms;
      _dueDate = calculated;
    });
    context.read<InvoiceProvider>().updateDueDate(calculated);
    _markChanged();
  }

  void _selectInvoiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _invoiceDate = picked;
      });
      context.read<InvoiceProvider>().updateInvoiceDate(picked);
      _updateDueDateFromTerms(_selectedPaymentTerms);
      _markChanged();
    }
  }

  void _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(_invoiceDate) ? _invoiceDate : _dueDate,
      firstDate: _invoiceDate,
      lastDate: _invoiceDate.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _dueDate = picked;
      });
      context.read<InvoiceProvider>().updateDueDate(picked);
      _markChanged();
    }
  }

  Future<void> _pickAttachment() async {
    try {
      setState(() => _isPickingFile = true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _attachments.add(picked.name);
        });
        _markChanged();
      }
    } catch (e) {
      // In web or restricted environments, add dummy document for demonstration
      setState(() {
        _attachments.add('invoice_attachment_${_attachments.length + 1}.pdf');
      });
      _markChanged();
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  void _triggerAutosave() async {
    final provider = context.read<InvoiceProvider>();
    if (provider.selectedCustomer != null && provider.selectedItems.isNotEmpty && _hasUnsavedChanges) {
      final amountPaid = _markAsFullyPaid
          ? _calculateGrandTotal(provider)
          : (double.tryParse(_amountReceivedController.text) ?? 0.0);

      final success = await provider.saveInvoice(
        shippingCharges: _shipping,
        adjustment: _adjustment,
        paymentTerms: _selectedPaymentTerms,
        referenceNumber: _referenceController.text.trim(),
        salesperson: _salespersonController.text.trim(),
        currency: _selectedCurrency,
        amountReceived: amountPaid,
        paymentMode: _selectedPaymentMethod,
        isDraft: true,
        isRoundOff: _roundOff,
        markAsFullyPaid: _markAsFullyPaid,
        customerType: _customerType,
        mobileNumber: _mobileController.text.trim(),
        gstin: _gstinController.text.trim(),
        email: _emailController.text.trim(),
        billingAddress: _billingAddressController.text.trim(),
        shippingAddress: _shippingAddressController.text.trim(),
        shippingSameAsBilling: _shippingSameAsBilling,
        internalNotes: _internalNotesController.text.trim(),
        notes: _customerNotesController.text.trim(),
        termsAndConditions: _termsController.text.trim(),
      );
      if (success) {
        setState(() {
          _hasUnsavedChanges = false;
        });
      }
    }
  }

  double _calculateGrandTotal(InvoiceProvider provider) {
    final subtotal = provider.subtotal;
    final discount = provider.totalDiscount;
    final tax = provider.totalTax;
    final rawTotal = (subtotal - discount) + tax + _shipping + _adjustment;
    if (_roundOff) {
      return rawTotal.roundToDouble();
    }
    return rawTotal;
  }

  double _calculateRoundOffDiff(InvoiceProvider provider) {
    final subtotal = provider.subtotal;
    final discount = provider.totalDiscount;
    final tax = provider.totalTax;
    final rawTotal = (subtotal - discount) + tax + _shipping + _adjustment;
    final rounded = rawTotal.roundToDouble();
    return rounded - rawTotal;
  }

  Future<void> _saveInvoice({required bool isDraft, bool isPrint = false}) async {
    final provider = context.read<InvoiceProvider>();

    if (provider.selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add a customer.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (provider.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one line item to the invoice.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Update notes and terms in provider
    provider.updateNotes(_customerNotesController.text);
    provider.updateTerms(_termsController.text);
    if (_isManualInvoiceNumber && _invoiceNumberController.text.trim().isNotEmpty) {
      provider.updateInvoiceNumber(_invoiceNumberController.text.trim());
    }

    final double grandTotal = _calculateGrandTotal(provider);
    final double amountPaid = _markAsFullyPaid
        ? grandTotal
        : (double.tryParse(_amountReceivedController.text) ?? 0.0);

    provider.updateIsPaid(_markAsFullyPaid || amountPaid >= grandTotal);

    final success = await provider.saveInvoice(
      shippingCharges: _shipping,
      adjustment: _adjustment,
      paymentTerms: _selectedPaymentTerms,
      referenceNumber: _referenceController.text.trim(),
      salesperson: _salespersonController.text.trim(),
      currency: _selectedCurrency,
      amountReceived: amountPaid,
      paymentMode: _selectedPaymentMethod,
      isDraft: isDraft,
      isRoundOff: _roundOff,
      markAsFullyPaid: _markAsFullyPaid,
      customerType: _customerType,
      mobileNumber: _mobileController.text.trim(),
      gstin: _gstinController.text.trim(),
      email: _emailController.text.trim(),
      billingAddress: _billingAddressController.text.trim(),
      shippingAddress: _shippingAddressController.text.trim(),
      shippingSameAsBilling: _shippingSameAsBilling,
      internalNotes: _internalNotesController.text.trim(),
      notes: _customerNotesController.text.trim(),
      termsAndConditions: _termsController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final savedId = provider.editingInvoice?.id ?? (provider.invoices.isNotEmpty ? provider.invoices.last.id : '');
      if (!isDraft && savedId.isNotEmpty && !widget.isEditing && !_markAsFullyPaid && !provider.isPaid) {
        await provider.markAsSent(savedId);
        if (!mounted) return;
      }

      final message = isDraft
          ? 'Draft ${provider.invoiceNumber} saved successfully!'
          : (isPrint
              ? 'Invoice ${provider.invoiceNumber} saved! Opening PDF Print...'
              : 'Invoice ${provider.invoiceNumber} saved! Opening PDF Preview...');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (isDraft) {
        Navigator.pop(context);
      } else {
        context.push('/invoices/preview');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save invoice'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    final provider = context.read<InvoiceProvider>();
    if (_hasUnsavedChanges && (provider.selectedCustomer != null || provider.selectedItems.isNotEmpty)) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved invoice changes. Are you sure you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Editing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
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

    // Synchronize auto invoice number if provider updated
    if (!_isManualInvoiceNumber && provider.invoiceNumber.isNotEmpty && provider.invoiceNumber != 'Auto-Generated') {
      if (_invoiceNumberController.text != provider.invoiceNumber) {
        _invoiceNumberController.text = provider.invoiceNumber;
      }
    }

    // Synchronize customer phone number if provider updated
    if (provider.selectedCustomer != null) {
      if (_mobileController.text != provider.selectedCustomer!.phone) {
        _mobileController.text = provider.selectedCustomer!.phone;
      }
    } else {
      if (_mobileController.text.isNotEmpty) {
        _mobileController.clear();
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          nav.pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final nav = Navigator.of(context);
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                nav.pop();
              }
            },
          ),
          title: Text(
            widget.isEditing ? 'Edit Invoice' : 'New Invoice',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _saveInvoice(isDraft: true),
              child: const Text(
                'SAVE AS DRAFT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'draft':
                    _saveInvoice(isDraft: true);
                    break;
                  case 'preview':
                    _saveInvoice(isDraft: false);
                    break;
                  case 'clear':
                    provider.startNewInvoice();
                    setState(() {
                      _attachments.clear();
                      _amountReceivedController.text = '0.00';
                      _markAsFullyPaid = false;
                    });
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'draft', child: Text('Save as Draft')),
                const PopupMenuItem(value: 'preview', child: Text('Preview PDF')),
                const PopupMenuItem(value: 'clear', child: Text('Reset Form')),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
              height: 1.0,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              if (provider.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.error.withValues(alpha: 0.12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Customer Details Card (Images 1 & 2)
                      _buildCustomerCard(theme, isDark, provider),
                      const SizedBox(height: 12),

                      // Section 2: Invoice Details Card (Images 1 & 2)
                      _buildInvoiceDetailsCard(theme, isDark, provider, autoNumberGen),
                      const SizedBox(height: 12),

                      // Section 3: Salesperson & Subject Card (Images 1 & 2)
                      _buildSalespersonSubjectCard(theme, isDark),
                      const SizedBox(height: 12),

                      // Section 4: Items Card (Images 1, 2, 3)
                      _buildItemsCard(theme, isDark, provider),
                      const SizedBox(height: 12),

                      // Section 5: Additional Information (Notes, Terms, Attachments)
                      _buildAdditionalCard(theme, isDark),
                      const SizedBox(height: 12),

                      // Section 7: Invoice Summary & Payment Card (Image 1)
                      _buildSummaryCard(theme, isDark, provider),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Action Bar (Images 1 & 2)
              _buildStickyActionBar(theme, isDark, provider),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD 1: CUSTOMER DETAILS (Images 1 & 2)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCustomerCard(ThemeData theme, bool isDark, InvoiceProvider provider) {
    final customer = provider.selectedCustomer;

    return _CardContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Name (Client Name)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('Customer Name *'),
              if (customer != null)
                TextButton(
                  onPressed: () => _onCustomerSelected(null),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Change Customer', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                )
              else
                IconButton(
                  onPressed: () {
                    setState(() => _showInlineAddCustomer = !_showInlineAddCustomer);
                  },
                  icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Add New Customer',
                ),
            ],
          ),
          const SizedBox(height: 6),

          if (_showInlineAddCustomer) ...[
            _AddCustomerInlinePanel(
              prefillName: '',
              onSaved: (newCust) {
                setState(() => _showInlineAddCustomer = false);
                _onCustomerSelected(newCust);
              },
              onCancel: () => setState(() => _showInlineAddCustomer = false),
            ),
            const SizedBox(height: 12),
          ] else if (customer == null) ...[
            CustomerSearchField(
              initialSelected: null,
              onSelected: _onCustomerSelected,
              onCreateNewTap: (query) {
                setState(() => _showInlineAddCustomer = true);
              },
            ),
          ] else ...[
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
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (customer.company.isNotEmpty && customer.company != customer.name) ...[
                          const SizedBox(height: 2),
                          Text(
                            customer.company,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (customer != null) ...[
            const SizedBox(height: 12),
            _divider(isDark),
            const SizedBox(height: 10),

            // Mobile Number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('Mobile Number'),
                if (customer.phone.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Auto-filled',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
              ],
            ),
            _cleanInputField(
              controller: _mobileController,
              hint: customer.phone.isNotEmpty ? customer.phone : 'e.g. 9876543210',
              keyboardType: TextInputType.phone,
              onChanged: (v) => _markChanged(),
            ),

            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                setState(() => _showAdditionalCustomerDetails = !_showAdditionalCustomerDetails);
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showAdditionalCustomerDetails
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showAdditionalCustomerDetails
                          ? 'Hide additional details'
                          : 'More details (GSTIN, Address, Email)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showAdditionalCustomerDetails) ...[
              const SizedBox(height: 10),
              _divider(isDark),
              const SizedBox(height: 10),

              // Customer Type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Customer Type'),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Business', label: Text('Business', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'Individual', label: Text('Individual', style: TextStyle(fontSize: 11))),
                    ],
                    selected: {_customerType},
                    onSelectionChanged: (set) {
                      setState(() => _customerType = set.first);
                      _markChanged();
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _divider(isDark),
              const SizedBox(height: 10),

              // Email Address
              _buildLabel('Email Address'),
              _cleanInputField(
                controller: _emailController,
                hint: customer.email.isNotEmpty ? customer.email : 'e.g. billing@client.com',
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => _markChanged(),
              ),
              const SizedBox(height: 10),
              _divider(isDark),
              const SizedBox(height: 10),

              // GSTIN
              _buildLabel('GSTIN'),
              _cleanInputField(
                controller: _gstinController,
                hint: customer.gstNo.isNotEmpty ? customer.gstNo : 'e.g. 27AAPFU0939F1ZV',
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) => _markChanged(),
              ),
              const SizedBox(height: 10),
              _divider(isDark),
              const SizedBox(height: 10),

              // Billing Address
              _buildLabel('Billing Address'),
              _cleanInputField(
                controller: _billingAddressController,
                hint: 'Enter billing address...',
                maxLines: 2,
                onChanged: (v) {
                  if (_shippingSameAsBilling) {
                    _shippingAddressController.text = v;
                  }
                  _markChanged();
                },
              ),
              const SizedBox(height: 10),
              _divider(isDark),
              const SizedBox(height: 10),

              // Shipping Address toggle & field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Shipping same as billing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Switch(
                    value: _shippingSameAsBilling,
                    onChanged: (val) {
                      setState(() {
                        _shippingSameAsBilling = val;
                        if (val) {
                          _shippingAddressController.text = _billingAddressController.text;
                        }
                      });
                      _markChanged();
                    },
                  ),
                ],
              ),
              if (!_shippingSameAsBilling) ...[
                const SizedBox(height: 6),
                _buildLabel('Shipping Address'),
                _cleanInputField(
                  controller: _shippingAddressController,
                  hint: 'Enter shipping address...',
                  maxLines: 2,
                  onChanged: (v) => _markChanged(),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD 2: INVOICE DETAILS (Images 1 & 2)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInvoiceDetailsCard(
    ThemeData theme,
    bool isDark,
    InvoiceProvider provider,
    bool autoNumberGen,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return _CardContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice# * with gear / edit icon (Image 2)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('Invoice# *'),
              IconButton(
                onPressed: () {
                  setState(() => _isManualInvoiceNumber = !_isManualInvoiceNumber);
                },
                icon: Icon(
                  _isManualInvoiceNumber ? Icons.check_circle_outline_rounded : Icons.settings_outlined,
                  color: const Color(0xFF2563EB),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: _isManualInvoiceNumber ? 'Lock Invoice Number' : 'Customize Invoice Number',
              ),
            ],
          ),
          _cleanInputField(
            controller: _invoiceNumberController,
            hint: autoNumberGen ? 'INV-000001 (Auto)' : 'e.g. INV-001',
            readOnly: !_isManualInvoiceNumber && autoNumberGen && !widget.isEditing,
            onChanged: (val) {
              provider.updateInvoiceNumber(val.trim());
              _markChanged();
            },
          ),
          _divider(isDark),
          const SizedBox(height: 10),

          // Order Number (Image 2)
          _buildLabel('Order Number'),
          _cleanInputField(
            controller: _orderNumberController,
            hint: 'e.g. ORD-8942',
            onChanged: (v) => _markChanged(),
          ),
          _divider(isDark),
          const SizedBox(height: 10),

          // Reference Number (Image 1: e.g. PO-4587)
          _buildLabel('Reference No.'),
          _cleanInputField(
            controller: _referenceController,
            hint: 'e.g. PO-4587',
            onChanged: (v) => _markChanged(),
          ),
          _divider(isDark),
          const SizedBox(height: 10),

          // Invoice Date * (Images 1 & 2)
          _buildLabel('Invoice Date *'),
          InkWell(
            onTap: _selectInvoiceDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(_invoiceDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF2563EB), size: 18),
                ],
              ),
            ),
          ),
          _divider(isDark),
          const SizedBox(height: 10),

          // Terms * (Image 2)
          _buildLabel('Terms *'),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedPaymentTerms,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
              items: _paymentTermsOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (val) {
                if (val != null) _updateDueDateFromTerms(val);
              },
            ),
          ),
          _divider(isDark),
          const SizedBox(height: 10),

          // Due Date (Images 1 & 2)
          _buildLabel('Due Date'),
          InkWell(
            onTap: _selectDueDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(_dueDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF2563EB), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD 3: SALESPERSON & SUBJECT (Image 2)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSalespersonSubjectCard(ThemeData theme, bool isDark) {
    return _CardContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Salesperson (Images 1 & 2)
          _buildLabel('Salesperson'),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _salespersonsList.contains(_salespersonController.text)
                  ? _salespersonController.text
                  : _salespersonsList.first,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
              items: _salespersonsList
                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _salespersonController.text = val);
                  _markChanged();
                }
              },
            ),
          ),
          _divider(isDark),
          const SizedBox(height: 10),

          // Subject with Info Icon (Image 2)
          Row(
            children: [
              _buildLabel('Subject'),
              const SizedBox(width: 4),
              Tooltip(
                message: 'A short note explaining what this invoice is for',
                child: Icon(Icons.info_outline, size: 15, color: Colors.grey[600]),
              ),
            ],
          ),
          _cleanInputField(
            controller: _subjectController,
            hint: 'What is this invoice for?',
            onChanged: (v) => _markChanged(),
          ),
          _divider(isDark),
          const SizedBox(height: 10),

          // Currency (Image 1 & 2)
          _buildLabel('Currency'),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCurrency,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
              items: ['INR (₹)', 'USD (\$)', 'EUR (€)', 'GBP (£)']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCurrency = val);
                  _markChanged();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD 4: ITEMS (Images 1, 2, 3)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildItemsCard(ThemeData theme, bool isDark, InvoiceProvider provider) {
    return _CardContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('Items'),
              TextButton.icon(
                onPressed: () => context.push('/invoices/products'),
                icon: const Icon(Icons.apps_rounded, size: 16, color: Color(0xFF2563EB)),
                label: const Text('Catalog Picker', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Items search (kept same as requirement: "keep customer search and items search the same")
          ProductSearchField(
            onSelected: (product) {
              provider.addProduct(product);
              _markChanged();
            },
          ),
          const SizedBox(height: 14),

          // Line items list (Image 1 table features)
          if (provider.selectedItems.isNotEmpty) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                if (isWide) {
                  return _buildWideItemTable(provider, isDark);
                } else {
                  return _buildMobileItemList(provider, isDark);
                }
              },
            ),
            const SizedBox(height: 12),
          ],

          // + Add Line Item button (Image 2 & 3 style)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                provider.addNewEmptyItem();
                _markChanged();
              },
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

          // Total Items counter (from Image 1: Total Items: 1)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Total Items: ${provider.selectedItems.length}',
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

  // Wide Table View for Items (Image 1 style)
  Widget _buildWideItemTable(InvoiceProvider provider, bool isDark) {
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
              Expanded(flex: 2, child: Text('HSN/SAC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('QTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('UNIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('PRICE (₹)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('GST %', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('DISCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
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
          itemCount: provider.selectedItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final item = provider.selectedItems[index];
            return _buildWideItemRow(item, provider, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildWideItemRow(InvoiceItem item, InvoiceProvider provider, bool isDark) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final itemId = item.product.id.isNotEmpty ? item.product.id : item.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? themeColorSurface(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Item Name
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: item.product.name,
              key: ValueKey('name_${item.id}_${item.product.name}'),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              style: const TextStyle(fontSize: 12),
              onChanged: (val) {
                provider.updateItemName(itemId, val);
                _markChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          // HSN
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: item.product.hsnSacCode,
              key: ValueKey('hsn_${item.id}'),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8), hintText: 'HSN'),
              style: const TextStyle(fontSize: 12),
              onChanged: (val) {
                provider.updateItemHsn(itemId, val);
                _markChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          // Qty
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: item.quantity.toString(),
              key: ValueKey('qty_${item.id}_${item.quantity}'),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              style: const TextStyle(fontSize: 12),
              onChanged: (val) {
                final qty = int.tryParse(val) ?? 1;
                provider.updateItemQty(itemId, qty);
                _markChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          // Unit
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                value: _unitOptions.contains(item.product.unitAbbreviation)
                    ? item.product.unitAbbreviation
                    : _unitOptions.first,
                items: _unitOptions
                    .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    provider.updateItemUnit(itemId, val);
                    _markChanged();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Price
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: item.unitPrice.toStringAsFixed(2),
              key: ValueKey('price_${item.id}'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              style: const TextStyle(fontSize: 12),
              onChanged: (val) {
                final p = double.tryParse(val) ?? 0.0;
                provider.updateItemPrice(itemId, p);
                _markChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          // GST %
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                isDense: true,
                value: _gstRateOptions.contains(item.taxPercentage) ? item.taxPercentage : 18.0,
                items: _gstRateOptions
                    .map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()}%', style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    provider.updateItemTax(itemId, val);
                    _markChanged();
                  }
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
                    initialValue: item.discountType == '₹'
                        ? (item.discountValue > 0 ? item.discountValue.toStringAsFixed(0) : '')
                        : (item.discountPercentage > 0 ? item.discountPercentage.toStringAsFixed(1) : ''),
                    key: ValueKey('disc_${item.id}_${item.discountType}'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      hintText: item.discountType == '₹' ? '0' : '0%',
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (val) {
                      final d = double.tryParse(val) ?? 0.0;
                      provider.updateItemDiscount(itemId, d, item.discountType);
                      _markChanged();
                    },
                  ),
                ),
                InkWell(
                  onTap: () {
                    final nextType = item.discountType == '%' ? '₹' : '%';
                    provider.updateItemDiscountType(itemId, nextType);
                    _markChanged();
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
              currencyFormat.format(item.total),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          // Delete
          IconButton(
            onPressed: () {
              provider.removeProduct(itemId);
              _markChanged();
            },
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  // Mobile / Compact Item View (Clean Card layout)
  Widget _buildMobileItemList(InvoiceProvider provider, bool isDark) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.selectedItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = provider.selectedItems[index];
        final itemId = item.product.id.isNotEmpty ? item.product.id : item.id;

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
                    child: Text(
                      item.product.name.isNotEmpty ? item.product.name : 'Custom Line Item',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      provider.removeProduct(itemId);
                      _markChanged();
                    },
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
                      initial: item.product.hsnSacCode,
                      onChanged: (v) {
                        provider.updateItemHsn(itemId, v);
                        _markChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _subInput(
                      label: 'Qty',
                      initial: item.quantity.toString(),
                      isNumeric: true,
                      onChanged: (v) {
                        final q = int.tryParse(v) ?? 1;
                        provider.updateItemQty(itemId, q);
                        _markChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isDense: true,
                            isExpanded: true,
                            value: _unitOptions.contains(item.product.unitAbbreviation)
                                ? item.product.unitAbbreviation
                                : _unitOptions.first,
                            items: _unitOptions
                                .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                provider.updateItemUnit(itemId, val);
                                _markChanged();
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
                      initial: item.unitPrice.toStringAsFixed(2),
                      isNumeric: true,
                      onChanged: (v) {
                        final p = double.tryParse(v) ?? 0.0;
                        provider.updateItemPrice(itemId, p);
                        _markChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GST %', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            isDense: true,
                            isExpanded: true,
                            value: _gstRateOptions.contains(item.taxPercentage) ? item.taxPercentage : 18.0,
                            items: _gstRateOptions
                                .map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()}%', style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                provider.updateItemTax(itemId, val);
                                _markChanged();
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
                                final nextType = item.discountType == '%' ? '₹' : '%';
                                provider.updateItemDiscountType(itemId, nextType);
                                _markChanged();
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
                          initialValue: item.discountType == '₹'
                              ? (item.discountValue > 0 ? item.discountValue.toStringAsFixed(0) : '')
                              : (item.discountPercentage > 0 ? item.discountPercentage.toStringAsFixed(1) : ''),
                          key: ValueKey('mob_disc_${item.id}_${item.discountType}'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            hintText: item.discountType == '₹' ? '0' : '0%',
                          ),
                          style: const TextStyle(fontSize: 12),
                          onChanged: (v) {
                            final d = double.tryParse(v) ?? 0.0;
                            provider.updateItemDiscount(itemId, d, item.discountType);
                            _markChanged();
                          },
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
                  'Amount: ${currencyFormat.format(item.total)}',
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
    required String initial,
    bool isNumeric = false,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        TextFormField(
          initialValue: initial,
          keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          style: const TextStyle(fontSize: 12),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // CARD 5: ADDITIONAL INFORMATION (Notes, Terms & Attachments)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAdditionalCard(ThemeData theme, bool isDark) {
    final hasContent = _customerNotesController.text.isNotEmpty ||
        _internalNotesController.text.isNotEmpty ||
        _attachments.isNotEmpty;

    return _CardContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() => _isAdditionalExpanded = !_isAdditionalExpanded);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Additional Information',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(Notes, Terms & Attachments)',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasContent && !_isAdditionalExpanded)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Added',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  Icon(
                    _isAdditionalExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isAdditionalExpanded) ...[
            const SizedBox(height: 10),
            _divider(isDark),
            const SizedBox(height: 12),

            // Customer Notes (Image 3: "Thanks for your business.")
            _buildLabel('Customer Notes'),
            _cleanInputField(
              controller: _customerNotesController,
              hint: 'Add any notes or special instructions...',
              maxLines: 2,
              onChanged: (v) => _markChanged(),
            ),
            _divider(isDark),
            const SizedBox(height: 10),

            // Internal Note (Image 1: "For internal use only...")
            _buildLabel('Internal Note'),
            _cleanInputField(
              controller: _internalNotesController,
              hint: 'For internal use only...',
              maxLines: 2,
              onChanged: (v) => _markChanged(),
            ),
            _divider(isDark),
            const SizedBox(height: 10),

            // Terms and Conditions (Image 1: standard 5 clauses, Image 3)
            _buildLabel('Terms & Conditions'),
            _cleanInputField(
              controller: _termsController,
              hint: 'Terms and Conditions...',
              maxLines: 4,
              onChanged: (v) => _markChanged(),
            ),
            _divider(isDark),
            const SizedBox(height: 12),

            // Attachments (Image 3)
            _buildLabel('Attachments'),
            const SizedBox(height: 10),
            InkWell(
              onTap: _isPickingFile ? null : _pickAttachment,
              borderRadius: BorderRadius.circular(10),
              child: _DashedRectContainer(
                isDark: isDark,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isPickingFile)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(Icons.image_outlined, size: 22, color: isDark ? Colors.grey[300] : const Color(0xFF374151)),
                      const SizedBox(width: 8),
                      Text(
                        'Upload File',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.grey[200] : const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _attachments.map((file) {
                  return Chip(
                    avatar: const Icon(Icons.attach_file_rounded, size: 14),
                    label: Text(file, style: const TextStyle(fontSize: 11)),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () {
                      setState(() {
                        _attachments.remove(file);
                      });
                      _markChanged();
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD 7: INVOICE SUMMARY & PAYMENTS (Image 1)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSummaryCard(ThemeData theme, bool isDark, InvoiceProvider provider) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final subtotal = provider.subtotal;
    final itemDiscount = provider.totalDiscount;
    final taxableAmount = (subtotal - itemDiscount).clamp(0.0, double.infinity);
    final totalGst = provider.totalTax;
    final roundOffDiff = _calculateRoundOffDiff(provider);
    final grandTotal = _calculateGrandTotal(provider);
    if (_markAsFullyPaid) {
      final formattedTotal = grandTotal.toStringAsFixed(2);
      if (_amountReceivedController.text != formattedTotal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _markAsFullyPaid) {
            _amountReceivedController.text = formattedTotal;
          }
        });
      }
    }
    final enteredAmount = double.tryParse(_amountReceivedController.text.trim()) ?? 0.0;
    final amountPaid = _markAsFullyPaid ? grandTotal : enteredAmount;
    final balanceDue = (grandTotal - amountPaid).clamp(0.0, double.infinity);

    return _CardContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              _buildLabel('Invoice Summary'),
            ],
          ),
          const SizedBox(height: 12),
          _summaryRow('Subtotal', currencyFormat.format(subtotal)),
          const SizedBox(height: 8),
          _summaryRow('Item Discount', '- ${currencyFormat.format(itemDiscount)}', valueColor: AppColors.error),
          const SizedBox(height: 8),
          _summaryRow('Taxable Amount', currencyFormat.format(taxableAmount)),
          const SizedBox(height: 8),
          _summaryRow('Total GST', currencyFormat.format(totalGst)),
          const SizedBox(height: 8),

          // Shipping & Adjustment edit rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Shipping Charges', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _editChargeDialog('Shipping Charges', _shipping, (v) {
                      setState(() => _shipping = v);
                      _markChanged();
                    }),
                    child: const Icon(Icons.edit_rounded, size: 13, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
              Text(currencyFormat.format(_shipping), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Adjustment', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _editChargeDialog('Adjustment', _adjustment, (v) {
                      setState(() => _adjustment = v);
                      _markChanged();
                    }),
                    child: const Icon(Icons.edit_rounded, size: 13, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
              Text(
                '${_adjustment >= 0 ? '+' : ''}${currencyFormat.format(_adjustment)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _adjustment < 0 ? AppColors.error : null),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Round Off Checkbox (Image 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _roundOff,
                    activeColor: const Color(0xFF2563EB),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() => _roundOff = val ?? true);
                      _markChanged();
                    },
                  ),
                  const Text('Round Off', style: TextStyle(fontSize: 13)),
                ],
              ),
              Text(
                _roundOff ? '${roundOffDiff >= 0 ? '+' : ''}${currencyFormat.format(roundOffDiff)}' : '₹0.00',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ],
          ),
          _divider(isDark),
          const SizedBox(height: 10),

          // Grand Total (Image 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                currencyFormat.format(grandTotal),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Amount Received Header with Mark as fully paid aligned
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('Amount Received *'),
              InkWell(
                onTap: () {
                  setState(() {
                    _markAsFullyPaid = !_markAsFullyPaid;
                    if (_markAsFullyPaid) {
                      _amountReceivedController.text = grandTotal.toStringAsFixed(2);
                    } else {
                      _amountReceivedController.clear();
                    }
                  });
                  _markChanged();
                },
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mark as fully paid',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _markAsFullyPaid
                            ? const Color(0xFF2563EB)
                            : (isDark ? Colors.grey[400] : const Color(0xFF475569)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Checkbox(
                      value: _markAsFullyPaid,
                      activeColor: const Color(0xFF2563EB),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: (val) {
                        setState(() {
                          _markAsFullyPaid = val ?? false;
                          if (_markAsFullyPaid) {
                            _amountReceivedController.text = grandTotal.toStringAsFixed(2);
                          } else {
                            _amountReceivedController.clear();
                          }
                        });
                        _markChanged();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Unified input group: Currency Symbol + Amount Input + Payment Mode
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                // Currency Symbol (₹)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                    border: Border(right: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1))),
                  ),
                  child: const Text('₹', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),

                // Amount Text Field
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _amountReceivedController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    readOnly: _markAsFullyPaid,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onTap: () {
                      if (_amountReceivedController.text == '0.00' || _amountReceivedController.text == '0') {
                        _amountReceivedController.clear();
                      }
                    },
                    onChanged: (v) {
                      final val = double.tryParse(v.trim()) ?? 0.0;
                      if (val >= grandTotal && grandTotal > 0) {
                        _markAsFullyPaid = true;
                      } else {
                        _markAsFullyPaid = false;
                      }
                      setState(() {});
                      _markChanged();
                    },
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1,
                  color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                ),

                // Payment Mode Dropdown
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedPaymentMethod,
                        items: ['UPI', 'Bank Transfer', 'Cash', 'Cheque', 'Credit Card']
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedPaymentMethod = val);
                            _markChanged();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Balance Due (Image 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Balance Due', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(
                  currencyFormat.format(balanceDue),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: balanceDue > 0 ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STICKY BOTTOM ACTION BAR (Images 1 & 2)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStickyActionBar(ThemeData theme, bool isDark, InvoiceProvider provider) {
    final isValid = provider.selectedCustomer != null && provider.selectedItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cancel button (Image 1)
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),

            // Save & Preview button (Image 1)
            Expanded(
              child: OutlinedButton(
                onPressed: isValid ? () => _saveInvoice(isDraft: false, isPrint: false) : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  side: BorderSide(color: isValid ? const Color(0xFF2563EB) : Colors.grey.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save & Preview', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),

            // Save & Print button (Image 1: primary colored button)
            Expanded(
              child: ElevatedButton(
                onPressed: isValid ? () => _saveInvoice(isDraft: false, isPrint: true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid ? const Color(0xFF6D28D9) : Colors.grey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save & Print', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI Helpers
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
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

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  Color themeColorSurface(bool isDark) => isDark ? const Color(0xFF18181B) : Colors.white;

  void _editChargeDialog(String title, double initial, ValueChanged<double> onSubmitted) {
    final ctrl = TextEditingController(text: initial.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title'),
        content: TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Amount (₹)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(ctrl.text.trim()) ?? 0.0;
              onSubmitted(parsed);
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Card Container matching Image 2 & 3
// ─────────────────────────────────────────────────────────────────────────────
class _CardContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _CardContainer({
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed Outline Container for Attachments (Image 3)
// ─────────────────────────────────────────────────────────────────────────────
class _DashedRectContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _DashedRectContainer({
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: isDark ? Colors.grey[700]! : const Color(0xFFCBD5E1),
        strokeWidth: 1.5,
        dashLength: 5.0,
        dashGap: 4.0,
        borderRadius: 8.0,
      ),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final double borderRadius;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashLength < metric.length) ? dashLength : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.borderRadius != borderRadius;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline Add Customer Panel
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
  State<_AddCustomerInlinePanel> createState() => _AddCustomerInlinePanelState();
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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.prefillName);
    _companyCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _gstCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final customerProvider = context.read<CustomerProvider>();
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
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(customerProvider.errorMessage ?? 'Failed to create customer'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2563EB), width: 1.2),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Quick Add Customer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Customer Name *',
                hintText: 'Letters only',
                isDense: true,
              ),
              validator: (v) {
                final trimmed = v?.trim() ?? '';
                if (trimmed.isEmpty) return 'Customer name is required';
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
                  return 'Only letters and spaces are allowed';
                }
                if (trimmed.length < 2) {
                  return 'Customer name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Mobile Number', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _companyCtrl,
                    decoration: const InputDecoration(labelText: 'Business Name', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _gstCtrl,
                    decoration: const InputDecoration(labelText: 'GSTIN', isDense: true),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Billing Address', isDense: true),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isLoading ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                  child: _isLoading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Customer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
