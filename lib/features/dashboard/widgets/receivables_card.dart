import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/dashboard_reports.dart';

class ReceivablesCard extends StatelessWidget {
  final ReceivablesReport? report;

  const ReceivablesCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final total = report?.totalReceivables ?? 0.0;
    final overdue = report?.totalOverdue ?? 0.0;
    final current = report?.currentAmount ?? 0.0;

    final days1To30 = report?.days1To30 ?? 0.0;
    final days31To60 = report?.days31To60 ?? 0.0;
    final days61To90 = report?.days61To90 ?? 0.0;
    final days90Plus = report?.days90Plus ?? 0.0;

    double safeRatio(double part) => total > 0 ? (part / total).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.schedule_rounded, color: AppColors.warning, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receivables & Aging',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Overdue and bucketed collections',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  currency.format(total),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Overdue vs Current split chips
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overdue Amount',
                          style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currency.format(overdue),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current (Not Due)',
                          style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currency.format(current),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Segmented Aging Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (days1To30 > 0)
                      Expanded(
                        flex: (safeRatio(days1To30) * 100).toInt().clamp(1, 100),
                        child: Container(color: Colors.amber),
                      ),
                    if (days31To60 > 0)
                      Expanded(
                        flex: (safeRatio(days31To60) * 100).toInt().clamp(1, 100),
                        child: Container(color: Colors.orange),
                      ),
                    if (days61To90 > 0)
                      Expanded(
                        flex: (safeRatio(days61To90) * 100).toInt().clamp(1, 100),
                        child: Container(color: Colors.deepOrange),
                      ),
                    if (days90Plus > 0)
                      Expanded(
                        flex: (safeRatio(days90Plus) * 100).toInt().clamp(1, 100),
                        child: Container(color: Colors.red),
                      ),
                    if (total == 0)
                      Expanded(
                        child: Container(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Aging Buckets Legend Grid
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildBucketItem('1-30 Days', currency.format(days1To30), Colors.amber),
                _buildBucketItem('31-60 Days', currency.format(days31To60), Colors.orange),
                _buildBucketItem('61-90 Days', currency.format(days61To90), Colors.deepOrange),
                _buildBucketItem('90+ Days', currency.format(days90Plus), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBucketItem(String label, String amount, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        Text(
          amount,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
