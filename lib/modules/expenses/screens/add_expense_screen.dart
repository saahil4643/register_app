import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../features/customers/models/customer.dart';
import '../../../features/customers/providers/customer_provider.dart';
import '../../../features/products/models/product.dart';
import '../../../features/products/providers/product_provider.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/vendors/models/vendor.dart';
import '../../../features/vendors/screens/new_vendor_screen.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? initialExpense;

  const AddExpenseScreen({
    super.key,
    this.initialExpense,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Core Form State
  DateTime _selectedDate = DateTime.now();
  String? _selectedExpenseAccount;
  String? _selectedPaidThrough;
  bool _isItemized = false;
  File? _receiptFile;
  String? _receiptFileName;

  // Controllers
  late final TextEditingController _amountController;
  late final TextEditingController _vendorController;
  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _notesController;
  late final TextEditingController _customerController;

  // Reporting tags
  final List<String> _selectedTags = [];

  // Itemized line items
  final List<_ItemizedEntry> _itemizedEntries = [];

  // Standard accounting accounts
  final List<String> _expenseAccounts = [
    'Advertising & Marketing',
    'Bank Fees & Charges',
    'Consultant & Professional Fees',
    'Electricity & Utilities',
    'Employee Salaries & Wages',
    'Food, Meals & Entertainment',
    'Freight & Delivery',
    'Fuel & Petrol',
    'Insurance',
    'Internet & Telephone',
    'Office Supplies & Stationery',
    'Printing & Stationery',
    'Rent Expense',
    'Repairs & Maintenance',
    'Software & Subscriptions',
    'Travel & Conveyance',
    'Taxes & Licenses',
    'Other Expenses',
  ];

  final List<String> _paidThroughAccounts = [
    'Cash in Hand',
    'Petty Cash',
    'Primary Bank Account',
    'HDFC Current A/c',
    'SBI Current A/c',
    'ICICI Bank A/c',
    'Corporate Credit Card',
    'Debit Card',
    'UPI / Net Banking',
    'Cheque',
    'Director / Partner Loan',
  ];

  final List<String> _availableTags = [
    'Tax Deductible',
    'Reimbursable',
    'Project Alpha',
    'Client Meeting',
    'Marketing Campaign',
    'Office Overhead',
    'Capital Expense',
    'Non-GST',
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _vendorController = TextEditingController();
    _invoiceNumberController = TextEditingController();
    _notesController = TextEditingController();
    _customerController = TextEditingController();

    if (widget.initialExpense != null) {
      final exp = widget.initialExpense!;
      _selectedDate = exp.expenseDate;
      _selectedExpenseAccount = exp.category;
      _selectedPaidThrough = exp.paymentMode;
      _amountController.text = exp.amount > 0 ? exp.amount.toStringAsFixed(2) : '';
      _vendorController.text = exp.vendor;
      _invoiceNumberController.text = exp.billNumber ?? '';
      _notesController.text = exp.notes ?? '';
      _receiptFileName = exp.invoiceFileName;
    }

    // Load initial vendors & products silently
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().fetchVendors(silent: true);
      context.read<CustomerProvider>().fetchCustomers(refresh: false);
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  void _recalculateItemizedTotal() {
    if (!_isItemized) return;
    double total = 0.0;
    for (final item in _itemizedEntries) {
      total += item.total;
    }
    _amountController.text = total > 0 ? total.toStringAsFixed(2) : '';
    setState(() {});
  }

  Future<void> _pickReceipt() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                  if (photo != null) {
                    setState(() {
                      _receiptFile = File(photo.path);
                      _receiptFileName = photo.name;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (image != null) {
                    setState(() {
                      _receiptFile = File(image.path);
                      _receiptFileName = image.name;
                    });
                  }
                },
              ),
              if (_receiptFile != null || _receiptFileName != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: const Text('Remove Attachment', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _receiptFile = null;
                      _receiptFileName = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showAccountPicker({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = options
                .where((opt) => opt.toLowerCase().contains(filter.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search or type new...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (val) => setSheetState(() => filter = val),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length + (filter.isNotEmpty && !filtered.contains(filter) ? 1 : 0),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        if (idx < filtered.length) {
                          final item = filtered[idx];
                          final isCurrent = item == selected;
                          return ListTile(
                            title: Text(
                              item,
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                              ),
                            ),
                            trailing: isCurrent
                                ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
                                : null,
                            onTap: () {
                              onSelected(item);
                              Navigator.pop(ctx);
                            },
                          );
                        } else {
                          return ListTile(
                            leading: const Icon(Icons.add_rounded),
                            title: Text('Use "$filter"'),
                            onTap: () {
                              onSelected(filter);
                              Navigator.pop(ctx);
                            },
                          );
                        }
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

  Future<void> _showAddVendorDialog({String? initialQuery}) async {
    final result = await Navigator.push<Vendor>(
      context,
      MaterialPageRoute(
        builder: (_) => NewVendorScreen(initialName: initialQuery),
      ),
    );
    if (result != null && mounted) {
      setState(() => _vendorController.text = result.displayName);
    }
  }

  void _showAddCustomerDialog({String? initialQuery}) {
    final controller = TextEditingController(text: initialQuery ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Customer'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Customer / Client name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() => _customerController.text = name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showTagsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final customTagController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Associate Reporting Tags',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                          setSheetState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customTagController,
                          decoration: InputDecoration(
                            hintText: 'Add custom tag...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = customTagController.text.trim();
                          if (text.isNotEmpty) {
                            if (!_availableTags.contains(text)) {
                              _availableTags.add(text);
                            }
                            setState(() {
                              if (!_selectedTags.contains(text)) {
                                _selectedTags.add(text);
                              }
                            });
                            customTagController.clear();
                            setSheetState(() {});
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Done'),
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

  void _showExpensesHistory() {
    final provider = context.read<ExpenseProvider>();
    provider.fetchExpenses(reset: true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<ExpenseProvider>(
          builder: (context, expProvider, _) {
            final list = expProvider.expenses;
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Expenses History',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (expProvider.isLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (list.isEmpty)
                    const Expanded(
                      child: Center(child: Text('No recorded expenses yet.')),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          return ExpenseCard(
                            expense: list[i],
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                final exp = list[i];
                                _selectedDate = exp.expenseDate;
                                _selectedExpenseAccount = exp.category;
                                _selectedPaidThrough = exp.paymentMode;
                                _amountController.text = exp.amount.toStringAsFixed(2);
                                _vendorController.text = exp.vendor;
                                _invoiceNumberController.text = exp.billNumber ?? '';
                                _notesController.text = exp.notes ?? '';
                              });
                            },
                            onEdit: () {
                              Navigator.pop(ctx);
                              setState(() {
                                final exp = list[i];
                                _selectedDate = exp.expenseDate;
                                _selectedExpenseAccount = exp.category;
                                _selectedPaidThrough = exp.paymentMode;
                                _amountController.text = exp.amount.toStringAsFixed(2);
                                _vendorController.text = exp.vendor;
                                _invoiceNumberController.text = exp.billNumber ?? '';
                                _notesController.text = exp.notes ?? '';
                              });
                            },
                            onDelete: () => expProvider.deleteExpense(list[i].id),
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

  Future<void> _handleSave() async {
    // Validate required fields
    if (_selectedExpenseAccount == null || _selectedExpenseAccount!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Expense Account.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedPaidThrough == null || _selectedPaidThrough!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Paid Through account.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid expense Amount.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final provider = context.read<ExpenseProvider>();
    final vendorName = _vendorController.text.trim().isNotEmpty
        ? _vendorController.text.trim()
        : 'General Vendor';

    // Combine notes with tags & customer if applicable
    String fullNotes = _notesController.text.trim();
    if (_customerController.text.trim().isNotEmpty) {
      fullNotes += '\n[Customer: ${_customerController.text.trim()}]';
    }
    if (_selectedTags.isNotEmpty) {
      fullNotes += '\n[Tags: ${_selectedTags.join(", ")}]';
    }

    final newExpense = ExpenseModel(
      id: widget.initialExpense?.id ?? 'EXP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      category: _selectedExpenseAccount!,
      vendor: vendorName,
      amount: amount,
      gstRate: '0%',
      gstAmount: 0.0,
      totalAmount: amount,
      paymentMode: _selectedPaidThrough!,
      expenseDate: _selectedDate,
      billNumber: _invoiceNumberController.text.trim().isEmpty ? null : _invoiceNumberController.text.trim(),
      notes: fullNotes.isEmpty ? null : fullNotes,
      invoiceFileName: _receiptFileName,
      status: 'Paid',
      isDraft: false,
    );

    final success = await provider.saveExpense(newExpense, file: _receiptFile);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense recorded successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // Reset fields for new entry
        setState(() {
          _amountController.clear();
          _invoiceNumberController.clear();
          _notesController.clear();
          _customerController.clear();
          _vendorController.clear();
          _receiptFile = null;
          _receiptFileName = null;
          _selectedTags.clear();
          _itemizedEntries.clear();
          _isItemized = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to record expense.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final currencyCode = (settingsProvider.companySettings?.currency.isNotEmpty == true)
        ? settingsProvider.companySettings!.currency
        : 'INR';

    // Theme aligned colors
    final primaryAccent = theme.colorScheme.primary; // Purple branding
    const requiredRed = Color(0xFFEF4444); // Red indicator matching screenshot
    final labelBlue = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5); // Indigo/Purple tint for blue labels

    final cardBg = theme.colorScheme.surface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final underlineColor = isDark ? Colors.white24 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? theme.colorScheme.surface
            : const Color(0xFFF5F3FF), // Light purple tint matching app header
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'Record Expense',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          // View History action
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Expense History',
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            onPressed: _showExpensesHistory,
          ),
          // SAVE button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: provider.isSaving ? null : _handleSave,
              child: provider.isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryAccent),
                    )
                  : Text(
                      'SAVE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFA78BFA) : primaryAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------------
              // CARD 1: Core Transaction Info (Date, Attach Receipt, Accounts)
              // -------------------------------------------------------------
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder, width: 1.2),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date & Attach Receipt Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date picker section
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: labelBlue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: underlineColor, width: 1.2)),
                                  ),
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Attach Receipt Ribbon Badge
                        InkWell(
                          onTap: _pickReceipt,
                          borderRadius: BorderRadius.circular(8),
                          child: ClipPath(
                            clipper: const _ReceiptTicketClipper(),
                            child: Container(
                              width: 76,
                              height: 82,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFF1F5F9),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.attach_file_rounded,
                                          size: 20,
                                          color: (_receiptFile != null || _receiptFileName != null)
                                              ? AppColors.success
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (_receiptFile != null || _receiptFileName != null)
                                              ? 'Attached'
                                              : 'Attach\nReceipt',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            height: 1.15,
                                            fontWeight: FontWeight.w500,
                                            color: (_receiptFile != null || _receiptFileName != null)
                                                ? AppColors.success
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_receiptFile != null || _receiptFileName != null)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: AppColors.success,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Expense Account
                    InkWell(
                      onTap: () {
                        _showAccountPicker(
                          title: 'Select Expense Account',
                          options: _expenseAccounts,
                          selected: _selectedExpenseAccount,
                          onSelected: (val) => setState(() => _selectedExpenseAccount = val),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expense Account',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: requiredRed,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: underlineColor, width: 1.2)),
                            ),
                            child: Text(
                              _selectedExpenseAccount ?? 'Select Expense Account',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedExpenseAccount != null
                                    ? (isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A))
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Paid Through
                    InkWell(
                      onTap: () {
                        _showAccountPicker(
                          title: 'Select Paid Through Account',
                          options: _paidThroughAccounts,
                          selected: _selectedPaidThrough,
                          onSelected: (val) => setState(() => _selectedPaidThrough = val),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paid Through',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: requiredRed,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: underlineColor, width: 1.2)),
                            ),
                            child: Text(
                              _selectedPaidThrough ?? 'Select account',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedPaidThrough != null
                                    ? (isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A))
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Itemize Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Itemize',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: labelBlue,
                          ),
                        ),
                        Switch(
                          value: _isItemized,
                          activeThumbColor: primaryAccent,
                          onChanged: (val) {
                            setState(() {
                              _isItemized = val;
                              if (val && _itemizedEntries.isEmpty) {
                                _itemizedEntries.add(_ItemizedEntry(name: '', amount: 0.0));
                              }
                            });
                          },
                        ),
                      ],
                    ),

                    // Dynamic Itemized Line Entries (Search products dynamically like invoice!)
                    if (_isItemized) ...[
                      const Divider(height: 20),
                      Text(
                        'Items & Services',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._itemizedEntries.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _DynamicItemRow(
                            entry: item,
                            underlineColor: underlineColor,
                            primaryColor: primaryAccent,
                            isDark: isDark,
                            onRemove: () {
                              setState(() {
                                _itemizedEntries.removeAt(idx);
                                _recalculateItemizedTotal();
                              });
                            },
                            onChanged: _recalculateItemizedTotal,
                          ),
                        );
                      }),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Line Item'),
                        onPressed: () {
                          setState(() {
                            _itemizedEntries.add(_ItemizedEntry(name: '', amount: 0.0));
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ).animate().fade().slideY(begin: -0.02),

              const SizedBox(height: 12),

              // -------------------------------------------------------------
              // CARD 2: Amount Card (INR & Underlined Amount Input)
              // -------------------------------------------------------------
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder, width: 1.2),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: requiredRed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Currency Prefix
                        Container(
                          width: 52,
                          padding: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: underlineColor, width: 1.2)),
                          ),
                          child: Text(
                            currencyCode,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Amount field
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            readOnly: _isItemized,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                              isDense: true,
                              contentPadding: const EdgeInsets.only(bottom: 6),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: underlineColor, width: 1.2),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: primaryAccent, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fade(delay: 50.ms),

              const SizedBox(height: 12),

              // -------------------------------------------------------------
              // CARD 3: Vendor, Invoice#, Notes, Customer & Reporting Tags
              // -------------------------------------------------------------
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder, width: 1.2),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Vendor Field (Only searches when typing!)
                    Text(
                      'Vendor',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: labelBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _DynamicVendorSearchField(
                      controller: _vendorController,
                      underlineColor: underlineColor,
                      primaryColor: primaryAccent,
                      isDark: isDark,
                      onAddVendorTap: () => _showAddVendorDialog(initialQuery: _vendorController.text.trim()),
                    ),

                    const SizedBox(height: 20),

                    // Invoice# Field
                    Text(
                      'Invoice#',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: labelBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _invoiceNumberController,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: underlineColor, width: 1.2),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryAccent, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Notes Field
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: labelBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: underlineColor, width: 1.2),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryAccent, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dynamic Customer Field (Only searches when typing like in invoice!)
                    Text(
                      'Customer',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: labelBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _DynamicCustomerSearchField(
                      controller: _customerController,
                      underlineColor: underlineColor,
                      primaryColor: primaryAccent,
                      isDark: isDark,
                      onAddCustomerTap: () => _showAddCustomerDialog(initialQuery: _customerController.text.trim()),
                    ),

                    const SizedBox(height: 20),

                    // Reporting Tags Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reporting Tags',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: labelBlue,
                          ),
                        ),
                        InkWell(
                          onTap: _showTagsDialog,
                          child: Text(
                            'Associate Tags',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: labelBlue,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Selected Tags Chips
                    if (_selectedTags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _selectedTags.map((tag) {
                          return Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14),
                            onDeleted: () => setState(() => _selectedTags.remove(tag)),
                            backgroundColor: isDark
                                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                : const Color(0xFFEDE9FE),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ).animate().fade(delay: 100.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DYNAMIC CUSTOMER SEARCH FIELD (Like Invoice One: debounced, dynamic, not all shown!)
// =============================================================================
class _DynamicCustomerSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Color underlineColor;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onAddCustomerTap;

  const _DynamicCustomerSearchField({
    required this.controller,
    required this.underlineColor,
    required this.primaryColor,
    required this.isDark,
    required this.onAddCustomerTap,
  });

  @override
  State<_DynamicCustomerSearchField> createState() => _DynamicCustomerSearchFieldState();
}

class _DynamicCustomerSearchFieldState extends State<_DynamicCustomerSearchField> {
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<Customer> _suggestions = [];
  bool _isLoading = false;
  bool _showDropdown = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() => _showDropdown = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final query = text.trim();
    _lastQuery = query;

    // IMPORTANT: Do NOT show all customers directly if query is empty!
    if (query.isEmpty) {
      _debounce?.cancel();
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _showDropdown = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted || query.isEmpty) return;

    List<Customer> results = [];
    try {
      final response = await ApiService().get('/api/v1/customers?search=${Uri.encodeComponent(query)}');
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final List<dynamic> list = data is List
            ? data
            : (data is Map && data['results'] is List ? data['results'] as List<dynamic> : []);
        final q = query.trim().toLowerCase();
        results = list
            .map((json) => Customer.fromJson(json as Map<String, dynamic>))
            .where((c) {
              return c.name.toLowerCase().contains(q) ||
                  c.companyName.toLowerCase().contains(q) ||
                  c.primaryPhone.toLowerCase().contains(q) ||
                  c.email.toLowerCase().contains(q) ||
                  c.gstNumber.toLowerCase().contains(q);
            })
            .toList();
      }
    } catch (_) {}

    // Fallback to local CustomerProvider if API is silent or offline
    if (results.isEmpty && mounted) {
      final localCustomers = context.read<CustomerProvider>().customers;
      results = localCustomers.where((c) {
        final q = query.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            c.companyName.toLowerCase().contains(q) ||
            c.primaryPhone.toLowerCase().contains(q);
      }).toList();
    }

    if (mounted && _lastQuery == query) {
      setState(() {
        _suggestions = results;
        _isLoading = false;
        _showDropdown = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Start typing to select a Customer',
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
                  suffixIcon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : null,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.underlineColor, width: 1.2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_rounded, color: widget.primaryColor, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: widget.onAddCustomerTap,
            ),
          ],
        ),

        // Dynamic Suggestions Dropdown (Only appears when typing!)
        if (_showDropdown && _lastQuery.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                if (_suggestions.isEmpty && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'No customers matching "$_lastQuery"',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  )
                else
                  ..._suggestions.map((customer) {
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: widget.primaryColor.withValues(alpha: 0.15),
                        child: Text(
                          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.primaryColor),
                        ),
                      ),
                      title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: (customer.companyName.isNotEmpty || customer.primaryPhone.isNotEmpty)
                          ? Text(
                              customer.companyName.isNotEmpty ? customer.companyName : customer.primaryPhone,
                              style: const TextStyle(fontSize: 11),
                            )
                          : null,
                      onTap: () {
                        widget.controller.text = customer.name;
                        setState(() => _showDropdown = false);
                        _focusNode.unfocus();
                      },
                    );
                  }),
                Divider(height: 1, color: widget.isDark ? Colors.white10 : Colors.grey[200]),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.add_circle_outline_rounded, color: widget.primaryColor, size: 18),
                  title: Text(
                    'Add "$_lastQuery" as new customer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.primaryColor,
                    ),
                  ),
                  onTap: () {
                    setState(() => _showDropdown = false);
                    _focusNode.unfocus();
                    widget.onAddCustomerTap();
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// DYNAMIC VENDOR SEARCH FIELD (Only searches when typing!)
// =============================================================================
class _DynamicVendorSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Color underlineColor;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onAddVendorTap;

  const _DynamicVendorSearchField({
    required this.controller,
    required this.underlineColor,
    required this.primaryColor,
    required this.isDark,
    required this.onAddVendorTap,
  });

  @override
  State<_DynamicVendorSearchField> createState() => _DynamicVendorSearchFieldState();
}

class _DynamicVendorSearchFieldState extends State<_DynamicVendorSearchField> {
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showDropdown = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() => _showDropdown = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final query = text.trim();
    _lastQuery = query;

    // Do NOT show all vendors directly when empty!
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showDropdown = false;
      });
      return;
    }

    final vendors = context.read<ExpenseProvider>().vendors;
    final matched = vendors.where((v) => v.toLowerCase().contains(query.toLowerCase())).toList();

    setState(() {
      _suggestions = matched;
      _showDropdown = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Start typing to select a Vendor',
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 6, top: 4),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.underlineColor, width: 1.2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_rounded, color: widget.primaryColor, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: widget.onAddVendorTap,
            ),
          ],
        ),

        // Dynamic Suggestions Dropdown (Only appears when typing!)
        if (_showDropdown && _lastQuery.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                ..._suggestions.map((vendor) {
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.storefront_rounded, color: widget.primaryColor, size: 18),
                    title: Text(vendor, style: const TextStyle(fontSize: 13)),
                    onTap: () {
                      widget.controller.text = vendor;
                      setState(() => _showDropdown = false);
                      _focusNode.unfocus();
                    },
                  );
                }),
                Divider(height: 1, color: widget.isDark ? Colors.white10 : Colors.grey[200]),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.add_circle_outline_rounded, color: widget.primaryColor, size: 18),
                  title: Text(
                    'Add "$_lastQuery" as new vendor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.primaryColor,
                    ),
                  ),
                  onTap: () {
                    setState(() => _showDropdown = false);
                    _focusNode.unfocus();
                    widget.onAddVendorTap();
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// DYNAMIC ITEM ROW IN ITEMIZE (Like Invoice One: debounced, dynamic, not all shown!)
// =============================================================================
class _DynamicItemRow extends StatefulWidget {
  final _ItemizedEntry entry;
  final Color underlineColor;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _DynamicItemRow({
    required this.entry,
    required this.underlineColor,
    required this.primaryColor,
    required this.isDark,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_DynamicItemRow> createState() => _DynamicItemRowState();
}

class _DynamicItemRowState extends State<_DynamicItemRow> {
  late final TextEditingController _nameController;
  late final TextEditingController _rateController;
  late final TextEditingController _qtyController;
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  List<Product> _suggestions = [];
  bool _isLoading = false;
  bool _showDropdown = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entry.name);
    _qtyController = TextEditingController(text: widget.entry.quantity.toString());
    _rateController = TextEditingController(
        text: widget.entry.rate > 0 ? widget.entry.rate.toStringAsFixed(2) : '');

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() => _showDropdown = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _nameController.dispose();
    _rateController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _onNameChanged(String text) {
    final query = text.trim();
    _lastQuery = query;
    widget.entry.name = query;

    // Do NOT show all items directly if empty!
    if (query.isEmpty) {
      _debounce?.cancel();
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _showDropdown = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _searchProducts(query);
    });
  }

  Future<void> _searchProducts(String query) async {
    if (!mounted || query.isEmpty) return;

    List<Product> results = [];
    try {
      final response = await ApiService().get('/api/v1/products?search=${Uri.encodeComponent(query)}');
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final List<dynamic> list = data is List
            ? data
            : (data is Map && data['results'] is List ? data['results'] as List<dynamic> : []);
        results = list.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    // Fallback to local ProductProvider
    if (results.isEmpty && mounted) {
      final localProducts = context.read<ProductProvider>().products;
      results = localProducts.where((p) {
        final q = query.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
      }).toList();
    }

    if (mounted && _lastQuery == query) {
      setState(() {
        _suggestions = results;
        _isLoading = false;
        _showDropdown = true;
      });
    }
  }

  void _selectProduct(Product product) {
    _nameController.text = product.name;
    widget.entry.name = product.name;

    final price = product.sellingPrice > 0 ? product.sellingPrice : product.purchasePrice;
    if (price > 0) {
      widget.entry.rate = price;
      _rateController.text = price.toStringAsFixed(2);
      widget.entry.amount = widget.entry.quantity * price;
      widget.onChanged();
    }

    setState(() => _showDropdown = false);
    _focusNode.unfocus();
  }

  void _recalculate() {
    final qty = int.tryParse(_qtyController.text) ?? 1;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    widget.entry.quantity = qty > 0 ? qty : 1;
    widget.entry.rate = rate;
    widget.entry.amount = widget.entry.quantity * rate;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Item Search Field (dynamic, like invoice!)
            Expanded(
              flex: 5,
              child: TextField(
                controller: _nameController,
                focusNode: _focusNode,
                onChanged: _onNameChanged,
                decoration: InputDecoration(
                  hintText: 'Start typing to search an item...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  isDense: true,
                  suffixIcon: _isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            ),
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.only(bottom: 6),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.underlineColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Qty
            SizedBox(
              width: 44,
              child: TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (_) => _recalculate(),
                decoration: InputDecoration(
                  labelText: 'Qty',
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 6),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.underlineColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Rate / Amount
            Expanded(
              flex: 3,
              child: TextField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _recalculate(),
                decoration: InputDecoration(
                  hintText: 'Rate',
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 6),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.underlineColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),

            // Delete item button
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.error),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: widget.onRemove,
            ),
          ],
        ),

        // Dynamic Product Suggestions Dropdown (Only appears when typing!)
        if (_showDropdown && _lastQuery.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                if (_suggestions.isEmpty && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'No catalog items matching "$_lastQuery"',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  )
                else
                  ..._suggestions.map((prod) {
                    final price = prod.sellingPrice > 0 ? prod.sellingPrice : prod.purchasePrice;
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.inventory_2_outlined, color: widget.primaryColor, size: 18),
                      title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: prod.sku.isNotEmpty
                          ? Text('SKU: ${prod.sku}', style: const TextStyle(fontSize: 11))
                          : null,
                      trailing: Text(
                        '₹${price.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: widget.primaryColor),
                      ),
                      onTap: () => _selectProduct(prod),
                    );
                  }),
                Divider(height: 1, color: widget.isDark ? Colors.white10 : Colors.grey[200]),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.add_circle_outline_rounded, color: widget.primaryColor, size: 18),
                  title: Text(
                    'Use "$_lastQuery" as custom item',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.primaryColor,
                    ),
                  ),
                  onTap: () {
                    widget.entry.name = _lastQuery;
                    setState(() => _showDropdown = false);
                    _focusNode.unfocus();
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Helper model for Itemize entries
class _ItemizedEntry {
  String name;
  int quantity = 1;
  double rate = 0.0;
  double amount;

  _ItemizedEntry({
    required this.name,
    required this.amount,
  });

  double get total => quantity * (rate > 0 ? rate : amount);
}

/// Custom Clipper for receipt ticket cutout shape
class _ReceiptTicketClipper extends CustomClipper<Path> {
  const _ReceiptTicketClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 6);

    // Zigzag serrated edge at bottom
    const int teeth = 4;
    final double toothWidth = size.width / teeth;
    final double halfTooth = toothWidth / 2;

    for (int i = 0; i < teeth; i++) {
      path.lineTo(i * toothWidth + halfTooth, size.height);
      path.lineTo((i + 1) * toothWidth, size.height - 6);
    }

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
