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
  final double amountReceived;
  final ValueChanged<double>? onAmountReceivedChanged;

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
    this.amountReceived = 0.0,
    this.onAmountReceivedChanged,
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
            const SizedBox(height: 14),
            // Payment and Automatic Balance Left calculation panel
            Builder(
              builder: (context) {
                final double effectivePaid = isPaid ? grandTotal : amountReceived;
                final double balanceDue = (grandTotal - effectivePaid).clamp(0.0, double.infinity);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground.withOpacity(0.5) : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PAYMENT & BALANCE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (onPaidChanged != null)
                            InkWell(
                              onTap: () {
                                final next = !isPaid;
                                onPaidChanged!(next);
                                if (onAmountReceivedChanged != null) {
                                  onAmountReceivedChanged!(next ? grandTotal : 0.0);
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Mark Fully Paid',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isPaid ? AppColors.success : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Checkbox(
                                      value: isPaid,
                                      activeColor: AppColors.success,
                                      onChanged: (val) {
                                        if (val != null) {
                                          onPaidChanged!(val);
                                          if (onAmountReceivedChanged != null) {
                                            onAmountReceivedChanged!(val ? grandTotal : 0.0);
                                          }
                                        }
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // If Mark Fully Paid is unchecked: show inline amount paid input box
                      if (!isPaid) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Amount Paid',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                if (effectivePaid > 0)
                                  Text(
                                    currencyFormat.format(effectivePaid),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _PaidAmountInputField(
                              amount: amountReceived,
                              maxAmount: grandTotal,
                              onChanged: (val) {
                                final clamped = val.clamp(0.0, grandTotal);
                                onAmountReceivedChanged?.call(clamped);
                                if (clamped >= grandTotal && grandTotal > 0) {
                                  onPaidChanged?.call(true);
                                }
                              },
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                                const SizedBox(width: 6),
                                const Text(
                                  'Amount Paid (Full)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              currencyFormat.format(grandTotal),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Divider(height: 14),
                      // Balance Due / Left Row (automatic)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Balance Left',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                balanceDue == 0
                                    ? 'Fully Paid (No Dues)'
                                    : (effectivePaid > 0
                                        ? 'Partially Paid (${currencyFormat.format(balanceDue)} left)'
                                        : 'Unpaid (Full Amount Pending)'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: balanceDue == 0
                                      ? AppColors.success
                                      : (effectivePaid > 0 ? AppColors.warning : (isDark ? Colors.grey[400] : Colors.grey[600])),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            currencyFormat.format(balanceDue),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: balanceDue == 0
                                  ? AppColors.success
                                  : (effectivePaid > 0 ? AppColors.warning : AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
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

class _PaidAmountInputField extends StatefulWidget {
  final double amount;
  final double maxAmount;
  final ValueChanged<double> onChanged;

  const _PaidAmountInputField({
    required this.amount,
    required this.maxAmount,
    required this.onChanged,
  });

  @override
  State<_PaidAmountInputField> createState() => _PaidAmountInputFieldState();
}

class _PaidAmountInputFieldState extends State<_PaidAmountInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.amount > 0
          ? (widget.amount % 1 == 0 ? widget.amount.toInt().toString() : widget.amount.toStringAsFixed(2))
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant _PaidAmountInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      final currentVal = double.tryParse(_controller.text.trim()) ?? 0.0;
      if ((currentVal - widget.amount).abs() > 0.001) {
        _controller.text = widget.amount > 0
            ? (widget.amount % 1 == 0 ? widget.amount.toInt().toString() : widget.amount.toStringAsFixed(2))
            : '';
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(
              '₹',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          hintText: 'Enter paid amount (e.g. 1000)',
          hintStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
              width: 1.2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.8,
            ),
          ),
        ),
        onChanged: (val) {
          final parsed = double.tryParse(val.trim()) ?? 0.0;
          widget.onChanged(parsed);
        },
      ),
    );
  }
}
