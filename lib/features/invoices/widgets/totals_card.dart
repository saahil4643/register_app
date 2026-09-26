import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

class TotalsCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double shipping;
  final double adjustment;
  final ValueChanged<double>? onShippingChanged;
  final ValueChanged<double>? onAdjustmentChanged;
  final bool isPaid;
  final ValueChanged<bool>? onPaidChanged;

  const TotalsCard({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.tax,
    this.shipping = 0.0,
    this.adjustment = 0.0,
    this.onShippingChanged,
    this.onAdjustmentChanged,
    this.isPaid = false,
    this.onPaidChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final double rawTotal = subtotal - discount + tax + shipping + adjustment;
    final double grandTotal = rawTotal.roundToDouble();
    final double roundOff = grandTotal - rawTotal;

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(isDark ? 0.15 : 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SUMMARY & TOTALS',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildTotalRow('Subtotal', currencyFormat.format(subtotal), theme),
            const SizedBox(height: 8),
            _buildTotalRow(
              'Discount Total',
              '-${currencyFormat.format(discount)}',
              theme,
              valueColor: AppColors.success,
            ),
            const SizedBox(height: 8),
            _buildTotalRow('Tax (GST) Total', currencyFormat.format(tax), theme),
            const SizedBox(height: 8),
            
            // Shipping charges row (with inline edit)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Shipping Charges',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _showEditDialog(
                        context,
                        title: 'Shipping Charges',
                        initialValue: shipping,
                        onSubmitted: onShippingChanged,
                      ),
                      child: Icon(Icons.edit_rounded, size: 12, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                Text(
                  currencyFormat.format(shipping),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Adjustment charges row (with inline edit)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Adjustment',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _showEditDialog(
                        context,
                        title: 'Adjustment',
                        initialValue: adjustment,
                        onSubmitted: onAdjustmentChanged,
                      ),
                      child: Icon(Icons.edit_rounded, size: 12, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                Text(
                  (adjustment >= 0 ? '+' : '') + currencyFormat.format(adjustment),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: adjustment < 0 ? AppColors.error : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Round Off row
            _buildTotalRow(
              'Round Off',
              (roundOff >= 0 ? '+' : '') + currencyFormat.format(roundOff),
              theme,
              valueColor: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grand Total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  currencyFormat.format(grandTotal),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (onPaidChanged != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Mark as fully paid',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: isPaid,
                      onChanged: (val) {
                        if (val != null) {
                          onPaidChanged!(val);
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, ThemeData theme, {Color? valueColor}) {
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

  void _showEditDialog(
    BuildContext context, {
    required String title,
    required double initialValue,
    required ValueChanged<double>? onSubmitted,
  }) {
    if (onSubmitted == null) return;
    final controller = TextEditingController(text: initialValue.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: const InputDecoration(
            prefixText: '₹ ',
            labelText: 'Amount',
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
              final double? val = double.tryParse(controller.text);
              if (val != null) {
                onSubmitted(val);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 36),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
