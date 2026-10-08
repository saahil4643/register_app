import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import 'status_chip.dart';
import '../../../core/constants/app_colors.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final double outstandingBalance;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRecordPayment;
  final VoidCallback onDownloadPdf;
  final VoidCallback onDuplicate;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.outstandingBalance,
    required this.onTap,
    required this.onEdit,
    required this.onRecordPayment,
    required this.onDownloadPdf,
    required this.onDuplicate,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy');

    Color statusIndicatorColor;
    switch (invoice.status) {
      case InvoiceStatus.draft:
        statusIndicatorColor = Colors.grey;
        break;
      case InvoiceStatus.sent:
        statusIndicatorColor = AppColors.warning;
        break;
      case InvoiceStatus.partially_paid:
        statusIndicatorColor = Colors.amber.shade700;
        break;
      case InvoiceStatus.paid:
        statusIndicatorColor = AppColors.success;
        break;
      case InvoiceStatus.overdue:
        statusIndicatorColor = AppColors.error;
        break;
      case InvoiceStatus.cancelled:
        statusIndicatorColor = Colors.blueGrey;
        break;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      color: isDark ? theme.colorScheme.surface : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status color bar indicator
              Container(
                width: 6,
                color: statusIndicatorColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line 1: Invoice Number, Status Badge, Trailing action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                invoice.invoiceNumber,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (invoice.status == InvoiceStatus.draft) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_note_rounded, size: 16, color: Colors.grey),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              StatusChip(status: invoice.status, fontSize: 10),
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                splashRadius: 20,
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      onTap();
                                      break;
                                    case 'edit':
                                      onEdit();
                                      break;
                                    case 'pay':
                                      onRecordPayment();
                                      break;
                                    case 'pdf':
                                      onDownloadPdf();
                                      break;
                                    case 'duplicate':
                                      onDuplicate();
                                      break;
                                    case 'share':
                                      onShare();
                                      break;
                                    case 'delete':
                                      onDelete();
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'view',
                                    child: ListTile(
                                      leading: Icon(Icons.visibility_outlined, size: 18),
                                      title: Text('View Details', style: TextStyle(fontSize: 13)),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit_outlined, size: 18),
                                      title: Text('Edit Invoice', style: TextStyle(fontSize: 13)),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  if (invoice.status != InvoiceStatus.paid && invoice.status != InvoiceStatus.cancelled) ...[
                                    const PopupMenuItem<String>(
                                      value: 'pay',
                                      child: ListTile(
                                        leading: Icon(Icons.payment_rounded, size: 18),
                                        title: Text('Record Payment', style: TextStyle(fontSize: 13)),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                  const PopupMenuItem<String>(
                                    value: 'pdf',
                                    child: ListTile(
                                      leading: Icon(Icons.picture_as_pdf_outlined, size: 18),
                                      title: Text('Download PDF', style: TextStyle(fontSize: 13)),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'duplicate',
                                    child: ListTile(
                                      leading: Icon(Icons.copy_rounded, size: 18),
                                      title: Text('Duplicate', style: TextStyle(fontSize: 13)),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'share',
                                    child: ListTile(
                                      leading: Icon(Icons.share_outlined, size: 18),
                                      title: Text('Share link', style: TextStyle(fontSize: 13)),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                      title: Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.error)),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Line 2: Customer Name / Company Name
                      Text(
                        invoice.customer.company,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Contact: ${invoice.customer.name}',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      // Line 3: Financial Details & Dates (Responsive layout)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(invoice.grandTotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BALANCE DUE',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(outstandingBalance),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: outstandingBalance > 0
                                      ? (invoice.status == InvoiceStatus.overdue ? AppColors.error : AppColors.warning)
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'DUE DATE',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateFormat.format(invoice.dueDate),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: invoice.status == InvoiceStatus.overdue
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: invoice.status == InvoiceStatus.overdue
                                      ? AppColors.error
                                      : (isDark ? Colors.white70 : AppColors.lightTextPrimary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
