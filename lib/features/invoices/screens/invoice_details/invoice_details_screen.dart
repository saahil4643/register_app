import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/invoice_header.dart';
import '../../widgets/payment_history.dart';
import '../../widgets/customer_card.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoadingDetails = true;
    });
    try {
      await context.read<InvoiceProvider>().fetchInvoiceDetails(widget.invoiceId);
    } catch (e) {
      // Handled by provider error
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<InvoiceProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (_isLoadingDetails && provider.invoices.indexWhere((inv) => inv.id == widget.invoiceId) < 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Invoice...')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final invoiceIndex = provider.invoices.indexWhere((inv) => inv.id == widget.invoiceId);
    if (invoiceIndex < 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(provider.errorMessage ?? 'Invoice not found or has been deleted.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/invoices'),
                child: const Text('Return to Invoices'),
              ),
            ],
          ),
        ),
      );
    }

    final invoice = provider.invoices[invoiceIndex];
    final customer = invoice.customer;

    // Use API provided fields for outstanding and payments
    final double outstanding = invoice.balanceDue;
    final invoicePayments = invoice.payments;

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/invoices'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Panel 1: Invoice Header Dashboard
              InvoiceHeader(invoice: invoice, outstandingBalance: outstanding),
              const SizedBox(height: 16),
  
              // Panel 2: Interactive Action Controls
              ActionButtons(
                invoice: invoice,
                onRecordPayment: () {
                  if (outstanding <= 0) {
                    _showSnackBar(context, 'This invoice is already fully paid.');
                    return;
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Record Payment'),
                      content: Text('Record full payment of ${currencyFormat.format(outstanding)} for invoice ${invoice.invoiceNumber}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogCtx);
                            final success = await provider.recordPayment(
                              invoiceId: invoice.id,
                              amount: outstanding,
                              paymentMode: 'Bank Transfer',
                              paymentDate: DateTime.now(),
                              reference: 'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                            );
                            if (success) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Payment registered successfully!'), behavior: SnackBarBehavior.floating),
                              );
                              _fetchDetails();
                            } else {
                              messenger.showSnackBar(
                                SnackBar(content: Text(provider.errorMessage ?? 'Failed to record payment'), behavior: SnackBarBehavior.floating),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
                          child: const Text('Record Payment'),
                        ),
                      ],
                    ),
                  );
                },
                onEdit: () {
                  provider.startEditingInvoice(invoice);
                  context.push('/invoices/edit');
                },
                onDownloadPdf: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(const SnackBar(content: Text('Downloading PDF...'), behavior: SnackBarBehavior.floating));
                  final success = await provider.downloadInvoicePdf(
                    invoiceId: invoice.id,
                    invoiceNumber: invoice.invoiceNumber,
                  );
                  if (!success) {
                    messenger.showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to download PDF'), behavior: SnackBarBehavior.floating));
                  }
                },
                onPrint: () => _showSnackBar(context, 'Connecting to print service...'),
                onDuplicate: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final router = GoRouter.of(context);
                  final success = await provider.duplicateInvoice(invoice);
                  if (success) {
                    messenger.showSnackBar(const SnackBar(content: Text('Invoice duplicated successfully!'), behavior: SnackBarBehavior.floating));
                    router.go('/invoices');
                  } else {
                    messenger.showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to duplicate invoice'), behavior: SnackBarBehavior.floating));
                  }
                },
                onShare: () => _showSnackBar(context, 'Share invoice link copied to clipboard!'),
                onDelete: () {
                  final messenger = ScaffoldMessenger.of(context);
                  final router = GoRouter.of(context);
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Delete Invoice'),
                      content: Text('Are you sure you want to delete ${invoice.invoiceNumber}? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogCtx);
                            final success = await provider.deleteInvoice(invoice.id);
                            if (success) {
                              router.go('/invoices');
                              messenger.showSnackBar(SnackBar(content: Text('Invoice ${invoice.invoiceNumber} deleted.'), behavior: SnackBarBehavior.floating));
                            } else {
                              messenger.showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to delete invoice'), behavior: SnackBarBehavior.floating));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(80, 36),
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onSend: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await provider.markAsSent(invoice.id);
                  if (success) {
                    messenger.showSnackBar(const SnackBar(content: Text('Invoice sent successfully!'), behavior: SnackBarBehavior.floating));
                    _fetchDetails();
                  } else {
                    messenger.showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to send invoice'), behavior: SnackBarBehavior.floating));
                  }
                },
              ),
              const SizedBox(height: 16),
  
              // Panel 3: Client Details Card
              CustomerCard(
                customer: customer,
                onSelectTap: () {},
              ),
              const SizedBox(height: 16),
  
              // Panel 4: Itemized Products Table
              _buildItemsPreviewCard(theme, isDark, invoice, currencyFormat),
              const SizedBox(height: 16),
  
              // Panel 5: Payment logs Timeline
              PaymentHistory(payments: invoicePayments, invoice: invoice),
              const SizedBox(height: 16),
  
              // Panel 6: Terms & Notes
              _buildTermsNotesPreviewCard(theme, isDark, invoice),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsPreviewCard(
    ThemeData theme,
    bool isDark,
    Invoice invoice,
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
            Text(
              'ITEM DETAILS',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoice.items.length,
              separatorBuilder: (context, index) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final item = invoice.items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SKU: ${item.product.sku} | Qty: ${item.quantity} x ${currencyFormat.format(item.unitPrice)}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                          if (item.discountPercentage > 0 || item.taxPercentage > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Discount: ${item.discountPercentage}% | GST: ${item.taxPercentage}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.primary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(item.total),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 24),
            // Financial calculations details
            _buildFinancialRow('Subtotal', currencyFormat.format(invoice.subtotal), theme, isBold: false),
            if (invoice.totalDiscount > 0)
              _buildFinancialRow('Total Discount', '- ${currencyFormat.format(invoice.totalDiscount)}', theme, isBold: false, isDiscount: true),
            _buildFinancialRow('GST / Tax Total', currencyFormat.format(invoice.totalTax), theme, isBold: false),
            const Divider(height: 16),
            _buildFinancialRow(
              'Grand Total',
              currencyFormat.format(invoice.grandTotal),
              theme,
              isBold: true,
              color: theme.colorScheme.primary,
              fontSize: 15,
            ),
            const SizedBox(height: 4),
            _buildFinancialRow(
              'Amount Paid',
              currencyFormat.format(invoice.paidAmount),
              theme,
              isBold: true,
              color: invoice.paidAmount > 0 ? AppColors.success : null,
              fontSize: 13,
            ),
            _buildFinancialRow(
              'Balance Due',
              currencyFormat.format(invoice.balanceDue),
              theme,
              isBold: true,
              color: invoice.balanceDue <= 0
                  ? AppColors.success
                  : (invoice.status == InvoiceStatus.overdue ? AppColors.error : AppColors.warning),
              fontSize: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value,
    ThemeData theme, {
    required bool isBold,
    Color? color,
    double fontSize = 12,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: theme.brightness == Brightness.dark ? Colors.white70 : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isDiscount ? AppColors.success : (theme.brightness == Brightness.dark ? Colors.white : AppColors.lightTextPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsNotesPreviewCard(ThemeData theme, bool isDark, Invoice invoice) {
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
              'TERMS & REMARKS',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              Text(
                'Customer Notes',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                invoice.notes!,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 12),
            ],
            if (invoice.terms != null && invoice.terms!.isNotEmpty) ...[
              Text(
                'Terms & Conditions',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                invoice.terms!,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
