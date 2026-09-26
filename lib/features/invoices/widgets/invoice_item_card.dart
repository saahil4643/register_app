import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice_item.dart';
import '../../../core/constants/app_colors.dart';

class InvoiceItemCard extends StatelessWidget {
  final InvoiceItem item;
  final ValueChanged<int> onQtyChanged;
  final ValueChanged<double> onDiscountChanged;
  final ValueChanged<double> onTaxChanged;
  final VoidCallback onRemove;

  const InvoiceItemCard({
    super.key,
    required this.item,
    required this.onQtyChanged,
    required this.onDiscountChanged,
    required this.onTaxChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? theme.colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon, Title, Subtitle, Delete Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(isDark ? 0.2 : 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.product.category == 'Services'
                        ? Icons.design_services_rounded
                        : Icons.computer_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SKU: ${item.product.sku} | Price: ${currencyFormat.format(item.unitPrice)}',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                  tooltip: 'Remove Item',
                ),
              ],
            ),
            const Divider(height: 20),
            // Row 2: Live Inputs & Total
            Row(
              children: [
                // Qty Controller
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QTY',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                              onTap: () => onQtyChanged(item.quantity - 1),
                              child: Container(
                                height: 36,
                                width: 22,
                                alignment: Alignment.center,
                                child: const Icon(Icons.remove_rounded, size: 14),
                              ),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            InkWell(
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                              onTap: () => onQtyChanged(item.quantity + 1),
                              child: Container(
                                height: 36,
                                width: 22,
                                alignment: Alignment.center,
                                child: const Icon(Icons.add_rounded, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Discount Input
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DISC (%)',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            value: item.discountPercentage,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, size: 16),
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                            onChanged: (val) {
                              if (val != null) onDiscountChanged(val);
                            },
                            items: [0.0, 5.0, 10.0, 15.0, 20.0].map((double val) {
                              return DropdownMenuItem<double>(
                                value: val,
                                child: Text('${val.toStringAsFixed(0)}%'),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Tax (GST) Input
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TAX (GST)',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            value: item.taxPercentage,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, size: 16),
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                            onChanged: (val) {
                              if (val != null) onTaxChanged(val);
                            },
                            items: [0.0, 5.0, 12.0, 18.0, 28.0].map((double val) {
                              return DropdownMenuItem<double>(
                                value: val,
                                child: Text('${val.toStringAsFixed(0)}%'),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Total display
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'AMOUNT',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          currencyFormat.format(item.total),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.colorScheme.primary,
                          ),
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
}
