import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../../../core/constants/app_colors.dart';

class ActionButtons extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onRecordPayment;
  final VoidCallback onEdit;
  final VoidCallback onDownloadPdf;
  final VoidCallback onPrint;
  final VoidCallback onDuplicate;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onSend;

  const ActionButtons({
    super.key,
    required this.invoice,
    required this.onRecordPayment,
    required this.onEdit,
    required this.onDownloadPdf,
    required this.onPrint,
    required this.onDuplicate,
    required this.onShare,
    required this.onDelete,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isDraft = invoice.status == InvoiceStatus.draft;
    final isPaid = invoice.status == InvoiceStatus.paid;
    final isCancelled = invoice.status == InvoiceStatus.cancelled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (isDraft) ...[
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Send Invoice', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else if (!isPaid && !isCancelled) ...[
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: onRecordPayment,
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: const Text('Record Payment', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildIconButton(context, Icons.picture_as_pdf_rounded, 'PDF', onDownloadPdf),
                const SizedBox(width: 8),
                _buildIconButton(context, Icons.print_rounded, 'Print', onPrint),
                const SizedBox(width: 8),
                _buildIconButton(context, Icons.copy_rounded, 'Duplicate', onDuplicate),
                const SizedBox(width: 8),
                _buildIconButton(context, Icons.share_rounded, 'Share', onShare),
                if (isDraft) ...[
                  const SizedBox(width: 8),
                  _buildIconButton(context, Icons.delete_outline_rounded, 'Delete', onDelete, isDestructive: true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDestructive 
        ? AppColors.error 
        : (isDark ? Colors.white70 : AppColors.lightTextPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
