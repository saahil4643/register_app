import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import 'gst_dropdown.dart';
import 'payment_dropdown.dart';
import 'upload_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_buttons.dart';
import '../../../core/widgets/custom_inputs.dart';

class ExpenseForm extends StatefulWidget {
  final ExpenseModel? initialExpense;
  final VoidCallback onCancel;
  final VoidCallback onSaveSuccess;

  const ExpenseForm({
    super.key,
    this.initialExpense,
    required this.onCancel,
    required this.onSaveSuccess,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();

  // Predefined Categories
  final List<String> _categories = [
    'Rent',
    'Electricity',
    'Travel',
    'Office Supplies',
    'Fuel',
    'Marketing',
    'Software',
    'Internet',
    'Food',
    'Salary',
    'Other'
  ];

  // Predefined Vendors
  final List<String> _vendors = [
    'Phoenix Properties',
    'Amazon',
    'Flipkart',
    'Reliance',
    'HP',
    'Dell',
    'Local Vendor'
  ];

  // Form Fields State
  String? _selectedCategory;
  String? _selectedVendor;
  String? _selectedPaymentMode;
  DateTime _selectedExpenseDate = DateTime.now();
  DateTime? _selectedDueDate;
  String _gstRate = '18%';
  double _gstPercentage = 0.18;

  // Uploaded file metadata
  String? _invoiceFileName;
  String? _invoiceFileSize;
  File? _selectedFile;

  // Controllers
  late final TextEditingController _amountController;
  late final TextEditingController _gstAmountController;
  late final TextEditingController _totalAmountController;
  late final TextEditingController _billNumberController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _gstAmountController = TextEditingController(text: '0.00');
    _totalAmountController = TextEditingController(text: '0.00');
    _billNumberController = TextEditingController();
    _notesController = TextEditingController();

    _amountController.addListener(_recalculateAmounts);
    _notesController.addListener(() => setState(() {}));

    _prepopulateFields();
  }

  void _prepopulateFields() {
    final exp = widget.initialExpense;
    if (exp != null) {
      _selectedCategory = exp.category;
      _selectedVendor = exp.vendor;
      _selectedPaymentMode = exp.paymentMode;
      _selectedExpenseDate = exp.expenseDate;
      _selectedDueDate = exp.dueDate;
      _gstRate = exp.gstRate;
      _invoiceFileName = exp.invoiceFileName;
      _invoiceFileSize = exp.invoiceFileSize;
      _amountController.text = exp.amount.toString();
      _billNumberController.text = exp.billNumber ?? '';
      _notesController.text = exp.notes ?? '';

      // Initialize GST percentage
      if (exp.gstRate.contains('%')) {
        if (exp.gstRate.startsWith('Custom')) {
          final regExp = RegExp(r'\d+');
          final match = regExp.firstMatch(exp.gstRate);
          if (match != null) {
            final rate = double.tryParse(match.group(0) ?? '0') ?? 0.0;
            _gstPercentage = rate / 100;
          }
        } else {
          final rate = double.tryParse(exp.gstRate.replaceAll('%', '')) ?? 0.0;
          _gstPercentage = rate / 100;
        }
      }
      _recalculateAmounts();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _gstAmountController.dispose();
    _totalAmountController.dispose();
    _billNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculateAmounts() {
    final amt = double.tryParse(_amountController.text) ?? 0.0;
    final gstAmt = amt * _gstPercentage;
    final totalAmt = amt + gstAmt;

    _gstAmountController.text = gstAmt.toStringAsFixed(2);
    _totalAmountController.text = totalAmt.toStringAsFixed(2);
  }

  void _handleGstChanged(String rate, double percentageValue) {
    setState(() {
      _gstRate = rate;
      _gstPercentage = percentageValue;
    });
    _recalculateAmounts();
  }

  // Open Searchable Picker (Bottom Sheet)
  void _showSearchablePicker({
    required String title,
    required List<String> items,
    required String? currentValue,
    required bool allowCustomCreation,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SearchablePickerSheet(
          title: title,
          items: items,
          currentValue: currentValue,
          allowCustomCreation: allowCustomCreation,
          onSelected: onSelected,
        );
      },
    );
  }

  Future<void> _submitForm({required bool isDraft}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ExpenseProvider>();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final gstAmt = double.tryParse(_gstAmountController.text) ?? 0.0;
    final totalAmt = double.tryParse(_totalAmountController.text) ?? 0.0;

    final expense = ExpenseModel(
      id: widget.initialExpense?.id ?? 'EXP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      category: _selectedCategory!,
      vendor: _selectedVendor!,
      amount: amount,
      gstRate: _gstRate,
      gstAmount: gstAmt,
      totalAmount: totalAmt,
      paymentMode: _selectedPaymentMode!,
      expenseDate: _selectedExpenseDate,
      dueDate: _selectedDueDate,
      billNumber: _billNumberController.text.trim().isEmpty ? null : _billNumberController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      invoiceFileName: _invoiceFileName,
      invoiceFileSize: _invoiceFileSize,
      status: isDraft ? 'Draft' : (widget.initialExpense?.status == 'Draft' ? 'Paid' : widget.initialExpense?.status ?? 'Paid'),
      isDraft: isDraft,
    );

    final success = await provider.saveExpense(expense, file: _selectedFile);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDraft ? 'Draft saved successfully.' : 'Expense saved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onSaveSuccess();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'An error occurred while saving.'),
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
    final isEditing = widget.initialExpense != null;

    final actionText = isEditing ? 'Save Changes' : 'Save Expense';

    return Card(
      elevation: AppDimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(builder: (context, headerConstraints) {
                final isHeaderNarrow = headerConstraints.maxWidth < 450;
                return Flex(
                  direction: isHeaderNarrow ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: isHeaderNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Expense' : 'Add Expense',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record your business expenses',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (isHeaderNarrow) const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: provider.isSaving ? null : () => _submitForm(isDraft: true),
                          child: const Text('Save Draft'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: provider.isSaving ? null : () => _submitForm(isDraft: false),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(60, 40),
                          ),
                          child: provider.isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                )
                              : Text(actionText, style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
            const Divider(height: 1),

            // Form Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Category & Vendor Picker
                  LayoutBuilder(builder: (context, constraints) {
                    final useHorizontal = constraints.maxWidth > 500;
                    return Flex(
                      direction: useHorizontal ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: useHorizontal ? 1 : 0,
                          child: _buildPickerField(
                            label: 'Expense Category *',
                            hint: 'Select Category',
                            value: _selectedCategory,
                            icon: Icons.category_outlined,
                            onTap: () => _showSearchablePicker(
                              title: 'Select Expense Category',
                              items: provider.categories.isEmpty ? _categories : provider.categories,
                              currentValue: _selectedCategory,
                              allowCustomCreation: false,
                              onSelected: (val) => setState(() => _selectedCategory = val),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Category is required' : null,
                          ),
                        ),
                        if (useHorizontal) AppSpacing.widthL else AppSpacing.heightM,
                        Expanded(
                          flex: useHorizontal ? 1 : 0,
                          child: _buildPickerField(
                            label: 'Vendor / Supplier *',
                            hint: 'Select Vendor',
                            value: _selectedVendor,
                            icon: Icons.storefront_outlined,
                            onTap: () => _showSearchablePicker(
                              title: 'Select Vendor',
                              items: provider.vendors.isEmpty ? _vendors : provider.vendors,
                              currentValue: _selectedVendor,
                              allowCustomCreation: true,
                              onSelected: (val) => setState(() => _selectedVendor = val),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Vendor is required' : null,
                          ),
                        ),
                      ],
                    );
                  }),
                  AppSpacing.heightM,

                  // Row 2: Amount & GST Rate
                  LayoutBuilder(builder: (context, constraints) {
                    final useHorizontal = constraints.maxWidth > 500;
                    return Flex(
                      direction: useHorizontal ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: useHorizontal ? 1 : 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 6),
                                child: Text(
                                  'Amount (₹) *',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Enter expense amount',
                                  prefixIcon: Icon(
                                    Icons.currency_rupee_rounded,
                                    size: 20,
                                    color: theme.colorScheme.primary.withOpacity(0.7),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Amount is required';
                                  }
                                  final numValue = double.tryParse(value);
                                  if (numValue == null || numValue <= 0) {
                                    return 'Amount must be greater than zero';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        if (useHorizontal) AppSpacing.widthL else AppSpacing.heightM,
                        Expanded(
                          flex: useHorizontal ? 1 : 0,
                          child: GstDropdown(
                            initialValue: _gstRate,
                            onGstChanged: _handleGstChanged,
                            validator: (val) => val == null ? 'GST Rate is required' : null,
                          ),
                        ),
                      ],
                    );
                  }),
                  AppSpacing.heightM,

                  // Row 3: Read-Only GST Amount & Read-Only Total Amount
                  LayoutBuilder(builder: (context, constraints) {
                    final useHorizontal = constraints.maxWidth > 500;
                    return Flex(
                      direction: useHorizontal ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: useHorizontal ? 1 : 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 6),
                                child: Text(
                                  'GST Amount (Read Only)',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: _gstAmountController,
                                readOnly: true,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  fillColor: isDark ? theme.colorScheme.surface.withOpacity(0.4) : const Color(0xFFF3F4F6),
                                  prefixIcon: const Icon(Icons.calculate_outlined, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (useHorizontal) AppSpacing.widthL else AppSpacing.heightM,
                        Expanded(
                          flex: useHorizontal ? 1 : 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 6),
                                child: Text(
                                  'Total Amount (Read Only)',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: _totalAmountController,
                                readOnly: true,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  fillColor: isDark ? theme.colorScheme.surface.withOpacity(0.4) : const Color(0xFFF3F4F6),
                                  prefixIcon: const Icon(Icons.summarize_outlined, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  AppSpacing.heightM,

                  // Row 4: Payment Mode & Bill Number
                  LayoutBuilder(builder: (context, constraints) {
                    final useHorizontal = constraints.maxWidth > 500;
                    return Flex(
                      direction: useHorizontal ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: useHorizontal ? 1 : 0,
                          child: PaymentDropdown(
                            initialValue: _selectedPaymentMode,
                            onChanged: (val) => setState(() => _selectedPaymentMode = val),
                            validator: (val) => val == null || val.isEmpty ? 'Payment Mode is required' : null,
                          ),
                        ),
                        if (useHorizontal) AppSpacing.widthL else AppSpacing.heightM,
                        Expanded(
                          flex: useHorizontal ? 1 : 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 6),
                                child: Text(
                                  'Bill Number (Optional)',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: _billNumberController,
                                style: const TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'e.g. REN/25-26/001',
                                  prefixIcon: Icon(
                                    Icons.receipt_rounded,
                                    size: 20,
                                    color: theme.colorScheme.primary.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  AppSpacing.heightM,

                  // Row 5: Expense Date & Due Date Picker
                  LayoutBuilder(builder: (context, constraints) {
                    final useHorizontal = constraints.maxWidth > 500;
                    return Flex(
                      direction: useHorizontal ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: useHorizontal ? 1 : 0,
                          child: CustomDatePicker(
                            label: 'Expense Date *',
                            selectedDate: _selectedExpenseDate,
                            lastDate: DateTime.now(), // Future dates disallowed
                            onDateSelected: (date) => setState(() => _selectedExpenseDate = date),
                          ),
                        ),
                        if (useHorizontal) AppSpacing.widthL else AppSpacing.heightM,
                        Expanded(
                          flex: useHorizontal ? 1 : 0,
                          child: CustomDatePicker(
                            label: 'Due Date (Optional)',
                            selectedDate: _selectedDueDate,
                            firstDate: _selectedExpenseDate, // Due date cannot precede expense date
                            onDateSelected: (date) => setState(() => _selectedDueDate = date),
                          ),
                        ),
                      ],
                    );
                  }),
                  AppSpacing.heightM,

                  // Notes Textarea (Min 3 lines, Max 6 lines, Counter)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Text(
                          'Notes / Description (Optional)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _notesController,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 300,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Describe details of this transaction...',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 50),
                            child: Icon(Icons.description_outlined, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.heightM,

                  // Invoice File Upload Box
                  UploadWidget(
                    initialFileName: _invoiceFileName,
                    initialFileSize: _invoiceFileSize,
                    onFileSelected: (name, size, file) {
                      _invoiceFileName = name;
                      _invoiceFileSize = size;
                      _selectedFile = file;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Bottom Action Buttons
                  LayoutBuilder(builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 430;
                    if (isNarrow) {
                      return Column(
                        children: [
                          CustomPrimaryButton(
                            text: actionText,
                            isLoading: provider.isSaving,
                            onPressed: () => _submitForm(isDraft: false),
                          ),
                          AppSpacing.heightS,
                          CustomSecondaryButton(
                            text: 'Save Draft',
                            isLoading: provider.isSaving,
                            onPressed: () => _submitForm(isDraft: true),
                          ),
                          AppSpacing.heightS,
                          CustomOutlinedButton(
                            text: 'Cancel',
                            onPressed: widget.onCancel,
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomOutlinedButton(
                          text: 'Cancel',
                          width: 110,
                          onPressed: widget.onCancel,
                        ),
                        const SizedBox(width: 12),
                        CustomSecondaryButton(
                          text: 'Save Draft',
                          width: 130,
                          isLoading: provider.isSaving,
                          onPressed: () => _submitForm(isDraft: true),
                        ),
                        const SizedBox(width: 12),
                        CustomPrimaryButton(
                          text: actionText,
                          width: 160,
                          isLoading: provider.isSaving,
                          onPressed: () => _submitForm(isDraft: false),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for custom searchable category/vendor buttons
  Widget _buildPickerField({
    required String label,
    required String hint,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    required FormFieldValidator<String>? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: state.hasError
                        ? AppColors.error
                        : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                    width: state.hasError ? 1.5 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: theme.colorScheme.primary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value ?? hint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          color: value == null ? theme.hintColor : (isDark ? Colors.white : Colors.black),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  state.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Inner sheet search widget
class _SearchablePickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? currentValue;
  final bool allowCustomCreation;
  final ValueChanged<String> onSelected;

  const _SearchablePickerSheet({
    required this.title,
    required this.items,
    required this.currentValue,
    required this.allowCustomCreation,
    required this.onSelected,
  });

  @override
  State<_SearchablePickerSheet> createState() => _SearchablePickerSheetState();
}

class _SearchablePickerSheetState extends State<_SearchablePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_SearchablePickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      setState(() {
        _filteredItems = List.from(widget.items);
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (widget.title == 'Select Vendor') {
      context.read<ExpenseProvider>().fetchVendors(search: query);
    } else {
      final queryLower = query.toLowerCase();
      setState(() {
        if (queryLower.isEmpty) {
          _filteredItems = List.from(widget.items);
        } else {
          _filteredItems = widget.items
              .where((item) => item.toLowerCase().contains(queryLower))
              .toList();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final query = _searchController.text.trim();
    
    // Check if custom creation should be shown
    final showCustomCreation = widget.allowCustomCreation && 
        query.isNotEmpty && 
        !widget.items.any((item) => item.toLowerCase() == query.toLowerCase());

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sheet Header Indicator
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomSearchField(
                controller: _searchController,
                hint: 'Search...',
                onClear: () => setState(() => _filteredItems = List.from(widget.items)),
              ),
            ),
            const SizedBox(height: 8),

            // Items List
            Flexible(
              child: _filteredItems.isEmpty && !showCustomCreation
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No results found',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      itemCount: _filteredItems.length + (showCustomCreation ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredItems.length && showCustomCreation) {
                          // Show "Add New Vendor" row
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD1FAE5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded, color: AppColors.success, size: 18),
                            ),
                            title: Text(
                              'Add New Vendor: "$query"',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text('Add custom vendor (simulated)'),
                            onTap: () {
                              widget.onSelected(query);
                              Navigator.pop(context);
                            },
                          );
                        }

                        final item = _filteredItems[index];
                        final isSelected = widget.currentValue == item;
                        return ListTile(
                          title: Text(
                            item,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : null,
                              color: isSelected ? theme.colorScheme.primary : null,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                              : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: () {
                            widget.onSelected(item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
