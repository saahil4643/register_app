import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/invoice_provider.dart';
import '../widgets/customer_picker_sheet.dart';
import '../widgets/invoice_item_row.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final bool isEditing;

  const CreateInvoiceScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TextEditingController _termsController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<InvoiceProvider>();
    _notesController = TextEditingController(text: provider.notes);
    _termsController = TextEditingController(text: provider.terms);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
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
    }
  }

  void _showCustomerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomerPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<InvoiceProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Invoice' : 'Create Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            // Confirm discard if changes are made
            if (provider.selectedCustomer != null || provider.selectedItems.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Discard Changes?'),
                  content: const Text('Are you sure you want to go back? All unsaved data will be lost.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back
                      },
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
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: Customer Card
                    _buildCustomerSection(theme, isDark, provider),
                    const SizedBox(height: 16),

                    // SECTION 2: Invoice Metadata (Number, Dates)
                    _buildInvoiceMetadataSection(theme, isDark, provider),
                    const SizedBox(height: 16),

                    // SECTION 3: Product List (Invoice Items)
                    _buildProductsSection(theme, isDark, provider, currencyFormat),
                    const SizedBox(height: 16),

                    // SECTION 4: Calculations Summary
                    if (provider.selectedItems.isNotEmpty) ...[
                      _buildSummarySection(theme, isDark, provider, currencyFormat),
                      const SizedBox(height: 16),
                    ],

                    // SECTION 5: Notes & Terms
                    _buildNotesTermsSection(theme, isDark, provider),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Preview Button
            _buildStickyBottomBar(theme, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection(ThemeData theme, bool isDark, InvoiceProvider provider) {
    final customer = provider.selectedCustomer;

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
                  'Customer Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () => _showCustomerPicker(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(customer != null ? 'Change' : 'Select'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (customer != null) ...[
              const Divider(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      customer.company.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.company,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Contact: ${customer.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Address: ${customer.address}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showCustomerPicker(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder.withOpacity(0.3) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                      style: BorderStyle.solid,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select Customer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search from client base or list',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
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
  }

  Widget _buildInvoiceMetadataSection(ThemeData theme, bool isDark, InvoiceProvider provider) {
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
              'Invoice Info',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            
            // Invoice Number (Disabled Input)
            TextFormField(
              initialValue: provider.invoiceNumber,
              key: ValueKey(provider.invoiceNumber),
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Invoice Number (Auto)',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),

            // Invoice Date & Due Date Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectInvoiceDate(context, provider),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Invoice Date',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(provider.invoiceDate),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDueDate(context, provider),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        prefixIcon: Icon(Icons.event_busy_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(provider.dueDate),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(
    ThemeData theme,
    bool isDark,
    InvoiceProvider provider,
    NumberFormat currencyFormat,
  ) {
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
                  'Products & Services',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (provider.selectedItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => context.push('/invoices/products'),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Items'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (provider.selectedItems.isEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => context.push('/invoices/products'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
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
                        Icons.shopping_cart_outlined,
                        size: 36,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No Items Added Yet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap here to add products & services catalog',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.selectedItems.length,
                itemBuilder: (context, index) {
                  final item = provider.selectedItems[index];
                  return InvoiceItemRow(
                    item: item,
                    onQtyChanged: (newQty) {
                      provider.updateItemQty(item.product.id, newQty);
                    },
                    onDiscountChanged: (disc) {
                      provider.updateItemDiscount(item.product.id, disc);
                    },
                    onTaxChanged: (tax) {
                      provider.updateItemTax(item.product.id, tax);
                    },
                    onRemove: () {
                      provider.removeProduct(item.product.id);
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

  Widget _buildSummarySection(
    ThemeData theme,
    bool isDark,
    InvoiceProvider provider,
    NumberFormat currencyFormat,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(isDark ? 0.2 : 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow('Subtotal', currencyFormat.format(provider.subtotal), theme),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Discount',
              '-${currencyFormat.format(provider.totalDiscount)}',
              theme,
              valueColor: AppColors.success,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow('Tax (GST)', currencyFormat.format(provider.totalTax), theme),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grand Total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  currencyFormat.format(provider.grandTotal),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesTermsSection(ThemeData theme, bool isDark, InvoiceProvider provider) {
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
              'Additional Info',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes to Customer',
                hintText: 'e.g. Hope to work with you again!',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
              maxLines: 2,
              onChanged: (val) => provider.updateNotes(val),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _termsController,
              decoration: const InputDecoration(
                labelText: 'Terms & Conditions',
                hintText: 'e.g. Pay via bank transfer to account...',
                prefixIcon: Icon(Icons.gavel_outlined),
              ),
              maxLines: 2,
              onChanged: (val) => provider.updateTerms(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyBottomBar(ThemeData theme, InvoiceProvider provider) {
    final isValid = provider.selectedCustomer != null && provider.selectedItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: isValid
              ? () {
                  context.push('/invoices/preview');
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
          child: const Text('Preview Invoice'),
        ),
      ),
    );
  }
}
