import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/invoice_provider.dart';
import '../widgets/status_badge.dart';
import '../models/invoice.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
  });

  void _showDummyToast(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action is a mockup action and is not implemented in local environment.'),
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
    final dateFormat = DateFormat('dd MMM yyyy');

    // Find the invoice in the provider list
    final invoiceIndex = provider.filteredInvoices.indexWhere((inv) => inv.id == invoiceId);
    if (invoiceIndex < 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Invoice not found or has been deleted.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/invoices'),
                child: const Text('Return to Invoices'),
              ),
            ],
          ),
        ),
      );
    }

    final invoice = provider.filteredInvoices[invoiceIndex];
    final customer = invoice.customer;

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Invoice',
            onPressed: () => _showDummyToast(context, 'Share (PDF)'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Delete Invoice',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Invoice'),
                  content: Text('Are you sure you want to delete ${invoice.invoiceNumber}? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        provider.deleteInvoice(invoice.id);
                        Navigator.pop(context); // Close dialog
                        context.go('/invoices'); // Return to list
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invoice ${invoice.invoiceNumber} deleted.'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.success,
                          ),
                        );
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
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Header Banner Card
                  _buildHeaderCard(theme, isDark, invoice, dateFormat, currencyFormat),
                  const SizedBox(height: 16),

                  // Client Information Card
                  _buildClientCard(theme, isDark, customer),
                  const SizedBox(height: 16),

                  // Invoice Items Detail Card
                  _buildItemsCard(theme, isDark, invoice, currencyFormat),
                  const SizedBox(height: 16),

                  // Notes & Terms Card
                  _buildNotesTermsCard(theme, isDark, invoice),
                  const SizedBox(height: 16),

                  // ERP Activity Timeline (Dummy)
                  _buildTimelineCard(theme, isDark, invoice, dateFormat),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Action Bottom Bar
          _buildActionBottomBar(context, theme, isDark, invoice, provider),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    ThemeData theme,
    bool isDark,
    Invoice invoice,
    DateFormat dateFormat,
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL AMOUNT',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(invoice.grandTotal),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                InvoiceStatusBadge(status: invoice.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invoice Date', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(invoice.invoiceDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Due Date', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(invoice.dueDate),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: invoice.status == InvoiceStatus.overdue
                              ? const Color(0xFFEF4444)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(ThemeData theme, bool isDark, dynamic customer) {
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
              'CUSTOMER DETAILS',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    customer.company.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                        customer.name,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                      ),
                      Text(
                        customer.email,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                      Text(
                        customer.phone,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(
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
              'INVOICE ITEMS',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoice.items.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SKU: ${item.product.sku} | Qty: ${item.quantity}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                          if (item.discountPercentage > 0 || item.taxPercentage > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${item.taxPercentage > 0 ? 'GST ${item.taxPercentage}%' : ''}'
                                '${item.taxPercentage > 0 && item.discountPercentage > 0 ? ' | ' : ''}'
                                '${item.discountPercentage > 0 ? 'Disc -${item.discountPercentage}%' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: AppColors.success),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(item.total),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          '${item.quantity} × ${currencyFormat.format(item.unitPrice)}',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 32),
            // Calculations break down
            _buildDetailSummaryRow('Subtotal', currencyFormat.format(invoice.subtotal), theme),
            const SizedBox(height: 6),
            _buildDetailSummaryRow('Discount Total', '-${currencyFormat.format(invoice.totalDiscount)}', theme, color: AppColors.success),
            const SizedBox(height: 6),
            _buildDetailSummaryRow('GST Tax Total', currencyFormat.format(invoice.totalTax), theme),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  currencyFormat.format(invoice.grandTotal),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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

  Widget _buildDetailSummaryRow(String label, String value, ThemeData theme, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesTermsCard(ThemeData theme, bool isDark, Invoice invoice) {
    if ((invoice.notes?.isEmpty ?? true) && (invoice.terms?.isEmpty ?? true)) {
      return const SizedBox.shrink();
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
            Text(
              'ADDITIONAL INFORMATION',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              Text('Notes', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 2),
              Text(invoice.notes!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
              const SizedBox(height: 12),
            ],
            if (invoice.terms != null && invoice.terms!.isNotEmpty) ...[
              Text('Terms & Conditions', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 2),
              Text(invoice.terms!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(ThemeData theme, bool isDark, Invoice invoice, DateFormat dateFormat) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final createdDateStr = dateFormat.format(invoice.invoiceDate);
    final sentDateStr = dateFormat.format(invoice.invoiceDate.add(const Duration(hours: 4)));
    final paidDateStr = dateFormat.format(invoice.dueDate.subtract(const Duration(days: 3)));

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
              'INVOICE TIMELINE',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem('Invoice Created', 'Generated by Admin on $createdDateStr', Icons.create_rounded, true, theme, isDark),
            _buildTimelineItem(
              'Sent to Customer',
              invoice.status != InvoiceStatus.draft
                  ? 'Delivered to ${invoice.customer.email} on $sentDateStr'
                  : 'Pending dispatch (Draft mode)',
              Icons.send_rounded,
              invoice.status != InvoiceStatus.draft,
              theme,
              isDark,
            ),
            _buildTimelineItem(
              'Payment Status',
              invoice.status == InvoiceStatus.paid
                  ? 'Received full payment of ${currencyFormat.format(invoice.grandTotal)} on $paidDateStr'
                  : invoice.status == InvoiceStatus.overdue
                      ? 'Invoice is OVERDUE'
                      : invoice.status == InvoiceStatus.cancelled
                          ? 'Invoice cancelled'
                          : 'Awaiting payment confirmation',
              invoice.status == InvoiceStatus.paid ? Icons.check_circle_rounded : Icons.pending_rounded,
              invoice.status == InvoiceStatus.paid,
              theme,
              isDark,
              isLast: true,
              iconColor: invoice.status == InvoiceStatus.paid
                  ? AppColors.success
                  : invoice.status == InvoiceStatus.overdue
                      ? AppColors.error
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String desc,
    IconData icon,
    bool isCompleted,
    ThemeData theme,
    bool isDark, {
    bool isLast = false,
    Color? iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isCompleted
                    ? (iconColor ?? theme.colorScheme.primary).withOpacity(0.15)
                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 14,
                color: isCompleted
                    ? (iconColor ?? theme.colorScheme.primary)
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isCompleted
                    ? theme.colorScheme.primary.withOpacity(0.4)
                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                      : (isDark ? Colors.grey[500] : Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionBottomBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    Invoice invoice,
    InvoiceProvider provider,
  ) {
    final showMarkSent = invoice.status == InvoiceStatus.draft;
    final showMarkPaid = invoice.status == InvoiceStatus.sent || invoice.status == InvoiceStatus.overdue;

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
              child: OutlinedButton.icon(
                onPressed: () {
                  provider.startEditingInvoice(invoice);
                  context.push('/invoices/edit');
                },
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 8),

            // Dynamic Action Button (Mark Sent / Mark Paid)
            if (showMarkSent)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.markAsSent(invoice.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invoice ${invoice.invoiceNumber} marked as Sent!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Mark Sent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else if (showMarkPaid)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.markAsPaid(invoice.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invoice ${invoice.invoiceNumber} marked as Paid!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Mark Paid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Emerald 500
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else
              // Fallback share button if already Paid/Cancelled
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDummyToast(context, 'PDF Export'),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFECEFF1),
                    foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
