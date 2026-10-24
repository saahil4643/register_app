import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/customers/models/customer.dart';
import '../../../features/customers/providers/customer_provider.dart';
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

  // Controllers
  late final TextEditingController _expenseIdController;
  late final TextEditingController _amountController;
  late final FocusNode _amountFocusNode;
  late final TextEditingController _gstRateController;
  late final TextEditingController _referenceController;
  late final TextEditingController _notesController;
  late final TextEditingController _customerController;

  // State variables
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Bank Fee and Charges';
  String _selectedPaymentMode = 'Bank Account';
  bool _isBillable = false;

  // Categories list
  final List<String> _categories = [
    'Bank Fee and Charges',
    'Advertising & Marketing',
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

  // Upload state
  File? _receiptFile;
  String? _receiptFileName;
  int? _receiptFileSize;
  Uint8List? _receiptBytes;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _amountFocusNode = FocusNode();
    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) {
        if (_amountController.text == '0.00' || _amountController.text == '0') {
          _amountController.clear();
        } else if (_amountController.text.isNotEmpty) {
          _amountController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _amountController.text.length,
          );
        }
      }
    });

    _expenseIdController = TextEditingController(text: '');
    _amountController = TextEditingController(text: '');
    _gstRateController = TextEditingController(text: '');
    _referenceController = TextEditingController();
    _notesController = TextEditingController();
    _customerController = TextEditingController();

    if (widget.initialExpense != null) {
      final exp = widget.initialExpense!;
      _expenseIdController.text = exp.expenseNumber ?? exp.id;
      _selectedDate = exp.expenseDate;
      _selectedCategory = exp.category;
      _selectedPaymentMode = exp.paymentMode;
      _amountController.text = exp.amount > 0 ? (exp.amount == exp.amount.roundToDouble() ? exp.amount.toInt().toString() : exp.amount.toStringAsFixed(2)) : '';
      _referenceController.text = exp.billNumber ?? '';
      _notesController.text = exp.notes ?? '';
      _receiptFileName = exp.invoiceFileName;
      _isBillable = exp.billable;
      if (exp.vendor.isNotEmpty && exp.vendor != 'General Vendor') {
        _customerController.text = exp.vendor;
      } else if (exp.customer != null && exp.customer!.isNotEmpty) {
        _customerController.text = exp.customer!;
      }

      // Extract GST rate if present
      final cleanGst = exp.gstRate.replaceAll('%', '').trim();
      final parsedGst = double.tryParse(cleanGst) ?? 0.0;
      if (parsedGst > 0) {
        _gstRateController.text = parsedGst.toStringAsFixed(0);
      }
    } else {
      // Auto-generate realistic sequence ID
      final now = DateTime.now();
      final suffix = (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
      _expenseIdController.text = 'EXP-$suffix';
    }

    _amountController.addListener(() => setState(() {}));
    _gstRateController.addListener(() => setState(() {}));

    // Silently fetch customers, vendors, and categories from backend settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers(refresh: false);
      final expenseProvider = context.read<ExpenseProvider>();
      expenseProvider.fetchVendors(silent: true);
      expenseProvider.fetchCategories(silent: true).then((_) {
        if (mounted && expenseProvider.categories.isNotEmpty) {
          setState(() {
            for (final cat in expenseProvider.categories) {
              if (!_categories.contains(cat)) {
                _categories.add(cat);
              }
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _expenseIdController.dispose();
    _amountController.dispose();
    _gstRateController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  // Financial calculations
  double get _baseAmount => double.tryParse(_amountController.text.trim()) ?? 0.0;

  double get _gstRateValue {
    final text = _gstRateController.text.trim().replaceAll('%', '');
    return double.tryParse(text) ?? 0.0;
  }

  double get _gstAmount => (_baseAmount * _gstRateValue) / 100.0;

  double get _grandTotal => _baseAmount + _gstAmount;

  // Actions
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF1D4ED8),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickReceipt() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        final length = await file.length();
        setState(() {
          _receiptFile = File(file.path);
          _receiptFileName = file.name;
          _receiptFileSize = length;
          _receiptBytes = bytes;
        });
      }
    } catch (_) {
      // File picking error handled gracefully
    }
  }

  void _removeReceipt() {
    setState(() {
      _receiptFile = null;
      _receiptFileName = null;
      _receiptFileSize = null;
      _receiptBytes = null;
    });
  }

  void _showAddExpenseTypeDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Add Expense Type',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the name of the new expense category:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Courier & Shipping',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  if (!_categories.contains(val)) {
                    _categories.insert(0, val);
                  }
                  _selectedCategory = val;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Type'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDropdown() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = _categories
                .where((c) => c.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Category Name',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) => setSheetState(() => query = v),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final cat = filtered[idx];
                        final isSelected = cat == _selectedCategory;
                        return ListTile(
                          title: Text(
                            cat,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF1D4ED8) : null,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded, color: Color(0xFF1D4ED8))
                              : null,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            Navigator.pop(ctx);
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

  Future<void> _handleSave() async {
    final amount = _baseAmount;
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
    final expenseId = widget.initialExpense?.id ??
        (_expenseIdController.text.trim().isNotEmpty
            ? _expenseIdController.text.trim()
            : 'EXP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}');

    final customerText = _customerController.text.trim();
    final notesText = _notesController.text.trim();
    final gstRateStr = _gstRateValue > 0 ? '${_gstRateValue.toStringAsFixed(0)}%' : '0%';

    final expense = ExpenseModel(
      id: expenseId,
      expenseNumber: widget.initialExpense?.expenseNumber ?? _expenseIdController.text.trim(),
      category: _selectedCategory,
      vendor: customerText.isNotEmpty
          ? customerText
          : (widget.initialExpense?.vendor ?? 'General Vendor'),
      customer: customerText.isNotEmpty ? customerText : widget.initialExpense?.customer,
      amount: amount,
      gstRate: gstRateStr,
      gstAmount: _gstAmount,
      totalAmount: _grandTotal,
      paymentMode: _selectedPaymentMode,
      expenseDate: _selectedDate,
      billNumber: _referenceController.text.trim().isNotEmpty
          ? _referenceController.text.trim()
          : null,
      notes: notesText.isNotEmpty ? notesText : null,
      billable: _isBillable,
      invoiceFileName: _receiptFileName,
      invoiceFileSize: _receiptFileSize != null
          ? '${(_receiptFileSize! / (1024 * 1024)).toStringAsFixed(2)} MB'
          : null,
      status: widget.initialExpense?.status ?? 'Paid',
      isDraft: false,
    );

    final success = await provider.saveExpense(expense, file: _receiptFile);
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
        context.go('/expenses');
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
                        'Recorded Expenses History',
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
                          final exp = list[i];
                          return ExpenseCard(
                            expense: exp,
                            onEdit: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _expenseIdController.text = exp.id;
                                _selectedCategory = exp.category;
                                _selectedDate = exp.expenseDate;
                                _amountController.text = exp.amount.toStringAsFixed(2);
                                _referenceController.text = exp.billNumber ?? '';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();

    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    final pageBg = isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/expenses');
            }
          },
        ),
        title: Text(
          'Record Expense',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Expense History',
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            onPressed: _showExpensesHistory,
          ),
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/expenses');
              }
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14.0, left: 6.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: provider.isSaving ? null : _handleSave,
              child: provider.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Save Expense',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 920;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Expense Details + Customer Details
                        Expanded(
                          flex: 62,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildExpenseDetailsCard(cardBg, cardBorder, isDark),
                              const SizedBox(height: 24),
                              _buildCustomerDetailsCard(cardBg, cardBorder, isDark),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column: Receipt + Expense Summary
                        Expanded(
                          flex: 38,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildReceiptCard(cardBg, cardBorder, isDark),
                              const SizedBox(height: 24),
                              _buildExpenseSummaryCard(cardBg, cardBorder, isDark),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Mobile / Narrow layout
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildExpenseDetailsCard(cardBg, cardBorder, isDark),
                        const SizedBox(height: 20),
                        _buildReceiptCard(cardBg, cardBorder, isDark),
                        const SizedBox(height: 20),
                        _buildExpenseSummaryCard(cardBg, cardBorder, isDark),
                        const SizedBox(height: 20),
                        _buildCustomerDetailsCard(cardBg, cardBorder, isDark),
                        const SizedBox(height: 24),
                        // Full width save button for mobile
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: provider.isSaving ? null : _handleSave,
                          child: provider.isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Expense',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 1: Expense Details
  // ---------------------------------------------------------------------------
  Widget _buildExpenseDetailsCard(Color bg, Color border, bool isDark) {
    return _buildCardContainer(
      bg: bg,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('Expense Details', isDark),
          const SizedBox(height: 22),

          // Row 1: Expense ID & Date
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 480;
              if (isSmall) {
                return Column(
                  children: [
                    _buildFieldLabel(label: 'Expense ID', isRequired: true, isDark: isDark),
                    const SizedBox(height: 6),
                    _buildExpenseIdField(isDark),
                    const SizedBox(height: 16),
                    _buildFieldLabel(label: 'Date', isRequired: true, isDark: isDark),
                    const SizedBox(height: 6),
                    _buildDateField(isDark),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(label: 'Expense ID', isRequired: true, isDark: isDark),
                        const SizedBox(height: 6),
                        _buildExpenseIdField(isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(label: 'Date', isRequired: true, isDark: isDark),
                        const SizedBox(height: 6),
                        _buildDateField(isDark),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Row 2: Category Name & Amount
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 480;
              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(label: 'Category Name', isRequired: true, isDark: isDark),
                    const SizedBox(height: 6),
                    _buildCategoryField(isDark),
                    const SizedBox(height: 8),
                    _buildAddExpenseTypeLink(),
                    const SizedBox(height: 16),
                    _buildFieldLabel(label: 'Amount', isRequired: true, isDark: isDark),
                    const SizedBox(height: 6),
                    _buildAmountField(isDark),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(label: 'Category Name', isRequired: true, isDark: isDark),
                        const SizedBox(height: 6),
                        _buildCategoryField(isDark),
                        const SizedBox(height: 8),
                        _buildAddExpenseTypeLink(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(label: 'Amount', isRequired: true, isDark: isDark),
                        const SizedBox(height: 6),
                        _buildAmountField(isDark),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Row 3: GST Rate (%)
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 480;
              final width = isSmall ? constraints.maxWidth : (constraints.maxWidth - 16) / 2;
              return SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(label: 'GST Rate (%)', isRequired: false, isDark: isDark),
                    const SizedBox(height: 6),
                    _buildGstRateField(isDark),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Row 4: Reference#
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel(label: 'Reference#', isRequired: false, isDark: isDark),
              const SizedBox(height: 6),
              _buildReferenceField(isDark),
            ],
          ),
          const SizedBox(height: 20),

          // Row 5: Notes
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel(label: 'Notes', isRequired: false, isDark: isDark),
              const SizedBox(height: 6),
              _buildNotesField(isDark),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 2: Customer Details
  // ---------------------------------------------------------------------------
  Widget _buildCustomerDetailsCard(Color bg, Color border, bool isDark) {
    return _buildCardContainer(
      bg: bg,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('Customer Details', isDark),
          const SizedBox(height: 20),

          // Customer Name
          _buildFieldLabel(label: 'Customer Name', isRequired: false, isDark: isDark),
          const SizedBox(height: 6),
          _buildCustomerSearchField(isDark),
          const SizedBox(height: 16),

          // Billable Checkbox
          InkWell(
            onTap: () => setState(() => _isBillable = !_isBillable),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _isBillable,
                      activeColor: const Color(0xFF1D4ED8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                      onChanged: (val) => setState(() => _isBillable = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Billable ',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                          ),
                        ),
                        const TextSpan(
                          text: '(Reimburse from customer)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 3: Receipt
  // ---------------------------------------------------------------------------
  Widget _buildReceiptCard(Color bg, Color border, bool isDark) {
    final hasReceipt = _receiptFileName != null || _receiptFile != null;

    return _buildCardContainer(
      bg: bg,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('Receipt', isDark),
          const SizedBox(height: 20),

          if (!hasReceipt)
            // Dashed border dropzone exactly as in screenshot
            _DottedBorderContainer(
              borderColor: const Color(0xFFCBD5E1),
              borderRadius: 8,
              dashWidth: 6,
              dashSpace: 4,
              strokeWidth: 1.2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cloud upload icon
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 40,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Drag & drop your receipt here',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'or',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                        backgroundColor: isDark ? const Color(0xFF27272A) : Colors.white,
                        side: BorderSide(
                          color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFCBD5E1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: _pickReceipt,
                      child: const Text(
                        'Browse Files',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Max 5MB (JPG, PNG, PDF)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Uploaded receipt preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _receiptBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_receiptBytes!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.receipt_long_rounded, color: Color(0xFF1D4ED8)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _receiptFileName ?? 'receipt.jpg',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_receiptFileSize != null)
                          Text(
                            '${(_receiptFileSize! / (1024 * 1024)).toStringAsFixed(2)} MB',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                    tooltip: 'Remove',
                    onPressed: _removeReceipt,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 4: Expense Summary
  // ---------------------------------------------------------------------------
  Widget _buildExpenseSummaryCard(Color bg, Color border, bool isDark) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_IN');
    final baseStr = currencyFormat.format(_baseAmount);
    final totalStr = currencyFormat.format(_grandTotal);

    final hasTax = _gstRateValue > 0;
    final taxDisplay = hasTax
        ? '₹${currencyFormat.format(_gstAmount)} (${_gstRateValue.toStringAsFixed(0)}%)'
        : '0% (Non-Taxable)';

    return _buildCardContainer(
      bg: bg,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('Expense Summary', isDark),
          const SizedBox(height: 22),

          // Base Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Base Amount',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '₹$baseStr',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // GST / Tax Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GST / Tax (${_gstRateValue.toStringAsFixed(0)}%)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                taxDisplay,
                style: TextStyle(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                  fontStyle: hasTax ? FontStyle.normal : FontStyle.italic,
                  fontWeight: hasTax ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grand Total Blue Bar Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8), // Rich Royal Blue exactly as screenshot
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '₹$totalStr',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Field Components
  // ---------------------------------------------------------------------------

  Widget _buildFieldLabel({
    required String label,
    required bool isRequired,
    required bool isDark,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF4444),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseIdField(bool isDark) {
    return TextFormField(
      controller: _expenseIdController,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: _inputDecoration(
        prefixIcon: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF94A3B8)),
        isDark: isDark,
      ),
    );
  }

  Widget _buildDateField(bool isDark) {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(8),
      child: IgnorePointer(
        child: TextFormField(
          key: ValueKey(_selectedDate),
          initialValue: DateFormat('dd - MM - yyyy').format(_selectedDate),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: _inputDecoration(
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF94A3B8)),
            suffixIcon: const Icon(Icons.calendar_month_outlined, size: 20, color: Color(0xFF64748B)),
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField(bool isDark) {
    return InkWell(
      onTap: _showCategoryDropdown,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_outlined, size: 18, color: Color(0xFF94A3B8)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedCategory,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddExpenseTypeLink() {
    return InkWell(
      onTap: _showAddExpenseTypeDialog,
      borderRadius: BorderRadius.circular(4),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 2.0),
        child: Text(
          '+ Add Expense Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField(bool isDark) {
    return TextFormField(
      controller: _amountController,
      focusNode: _amountFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onTap: () {
        if (_amountController.text == '0.00' || _amountController.text == '0') {
          _amountController.clear();
        }
      },
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: _inputDecoration(
        hintText: '0.00',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        isDark: isDark,
      ),
    );
  }

  Widget _buildGstRateField(bool isDark) {
    return TextFormField(
      controller: _gstRateController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: _inputDecoration(
        hintText: 'ex. 18',
        suffixIcon: const Padding(
          padding: EdgeInsets.only(right: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '%',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        isDark: isDark,
      ),
    );
  }

  Widget _buildReferenceField(bool isDark) {
    return TextFormField(
      controller: _referenceController,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: _inputDecoration(
        hintText: 'Receipt or Transaction ID',
        prefixIcon: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF94A3B8)),
        isDark: isDark,
      ),
    );
  }

  Widget _buildNotesField(bool isDark) {
    return Stack(
      children: [
        TextFormField(
          controller: _notesController,
          minLines: 3,
          maxLines: 5,
          style: TextStyle(
            fontSize: 13.5,
            fontFamily: 'Courier',
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: _inputDecoration(
            hintText: 'Enter expense details or notes...',
            isDark: isDark,
          ).copyWith(
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 24, 18),
          ),
        ),
        // Resize handle icon representation matching standard web textarea
        Positioned(
          bottom: 6,
          right: 6,
          child: Transform.rotate(
            angle: -0.785, // -45 deg
            child: const Icon(
              Icons.drag_handle_rounded,
              size: 13,
              color: Color(0xFFCBD5E1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSearchField(bool isDark) {
    return Consumer<CustomerProvider>(
      builder: (context, custProvider, _) {
        final customers = custProvider.customers;

        return Autocomplete<Customer>(
          displayStringForOption: (c) => c.displayName,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return customers.take(8);
            }
            return customers.where((Customer c) {
              return c.displayName.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (Customer selection) {
            setState(() {
              _customerController.text = selection.displayName;
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Sync with local customer controller if not empty
            if (_customerController.text.isNotEmpty && controller.text.isEmpty) {
              controller.text = _customerController.text;
            }
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (val) => _customerController.text = val,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: _inputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                suffixIcon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
                isDark: isDark,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: SizedBox(
                  width: 320,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final cust = options.elementAt(idx);
                        return ListTile(
                          dense: true,
                          title: Text(
                            cust.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          onTap: () => onSelected(cust),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable Styling Helpers
  // ---------------------------------------------------------------------------

  Widget _buildCardContainer({
    required Color bg,
    required Color border,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22.0),
      child: child,
    );
  }

  Widget _buildCardTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        letterSpacing: -0.2,
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 13.5,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.0),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Dashed / Dotted Rounded Border Container for Receipt Box
// -----------------------------------------------------------------------------
class _DottedBorderContainer extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderRadius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  const _DottedBorderContainer({
    required this.child,
    required this.borderColor,
    this.borderRadius = 8.0,
    this.strokeWidth = 1.2,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: borderColor,
        radius: borderRadius,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
      child: child,
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DottedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        final extract = metric.extractPath(
          distance,
          nextDistance > metric.length ? metric.length : nextDistance,
        );
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}
