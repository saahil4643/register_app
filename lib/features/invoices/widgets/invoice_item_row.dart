import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/invoice_item.dart';

class InvoiceItemRow extends StatelessWidget {
  final InvoiceItem item;
  final ValueChanged<int> onQtyChanged;
  final ValueChanged<double> onDiscountChanged;
  final ValueChanged<double> onTaxChanged;
  final VoidCallback onRemove;

  const InvoiceItemRow({
    super.key,
    required this.item,
    required this.onQtyChanged,
    required this.onDiscountChanged,
    required this.onTaxChanged,
    required this.onRemove,
  });

  void _showPercentDialog(
    BuildContext context, {
    required String title,
    required double currentValue,
    required ValueChanged<double> onChanged,
  }) {
    final controller = TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            suffixText: '%',
            hintText: 'Enter percentage',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0.0;
              onChanged(val);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: isDark ? theme.colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Title, Category Icon, Remove button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(item.product.category).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.product.category),
                    color: _getCategoryColor(item.product.category),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'SKU: ${item.product.sku}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Row 2: Price details and actions
            Row(
              children: [
                // Qty Controls
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => onQtyChanged(item.quantity - 1),
                        icon: const Icon(Icons.remove_rounded, size: 14),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        color: theme.colorScheme.primary,
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => onQtyChanged(item.quantity + 1),
                        icon: const Icon(Icons.add_rounded, size: 14),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Discount Modifier Chip
                InkWell(
                  onTap: () => _showPercentDialog(
                    context,
                    title: 'Set Item Discount',
                    currentValue: item.discountPercentage,
                    onChanged: onDiscountChanged,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          item.discountPercentage > 0 ? '-${item.discountPercentage}%' : 'Discount',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: item.discountPercentage > 0 ? FontWeight.bold : FontWeight.normal,
                            color: item.discountPercentage > 0 ? AppColors.success : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Tax Modifier Chip
                InkWell(
                  onTap: () => _showPercentDialog(
                    context,
                    title: 'Set Item GST Tax',
                    currentValue: item.taxPercentage,
                    onChanged: onTaxChanged,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'GST: ${item.taxPercentage}%',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Item Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(item.total),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
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
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Services':
        return Icons.design_services_rounded;
      case 'Hardware':
        return Icons.computer_rounded;
      case 'Software':
        return Icons.code_rounded;
      case 'Consulting':
        return Icons.people_outline_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Services':
        return const Color(0xFF6D28D9);
      case 'Hardware':
        return const Color(0xFF3B82F6);
      case 'Software':
        return const Color(0xFF10B981);
      case 'Consulting':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }
}
