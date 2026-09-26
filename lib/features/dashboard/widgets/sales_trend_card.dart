import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/dashboard_reports.dart';

class SalesTrendCard extends StatelessWidget {
  final SalesSummaryReport? salesSummary;
  final ProfitLossReport? profitLoss;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const SalesTrendCard({
    super.key,
    required this.salesSummary,
    required this.profitLoss,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final periods = salesSummary?.salesByPeriod ?? [];
    final monthlyTrends = profitLoss?.monthlyTrends ?? [];

    // Compute max for scaling bars
    double maxSale = 1.0;
    for (final p in periods) {
      if (p.totalSales > maxSale) maxSale = p.totalSales;
    }
    for (final t in monthlyTrends) {
      if (t.revenue > maxSale) maxSale = t.revenue;
      if (t.expenses > maxSale) maxSale = t.expenses;
    }

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
            // Title & Period Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales & Revenue Trend',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Revenue vs Expenses performance',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPeriodTab('Monthly', selectedPeriod == 'monthly', () => onPeriodChanged('monthly')),
                      _buildPeriodTab('Daily', selectedPeriod == 'daily', () => onPeriodChanged('daily')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Legend Row
            Row(
              children: [
                _buildLegendItem('Sales / Inflow', AppColors.success),
                const SizedBox(width: 14),
                _buildLegendItem('Expenses', AppColors.error),
                const SizedBox(width: 14),
                _buildLegendItem('Net Profit', theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 20),

            // Bar Chart Visual
            if (monthlyTrends.isNotEmpty || periods.isNotEmpty) ...[
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthlyTrends.isNotEmpty
                      ? monthlyTrends.map((trend) {
                          final revHeight = (trend.revenue / maxSale * 110).clamp(6.0, 110.0);
                          final expHeight = (trend.expenses / maxSale * 110).clamp(6.0, 110.0);
                          final label = trend.period.length > 5 ? trend.period.substring(5) : trend.period;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Revenue Bar
                                      Container(
                                        width: 12,
                                        height: revHeight,
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      // Expense Bar
                                      Container(
                                        width: 12,
                                        height: expHeight,
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.75),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList()
                      : periods.map((period) {
                          final height = (period.totalSales / maxSale * 110).clamp(6.0, 110.0);
                          final label = period.periodLabel.length > 5 ? period.periodLabel.substring(5) : period.periodLabel;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 16,
                                    height: height,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                ),
              ),
            ] else ...[
              Container(
                height: 120,
                alignment: Alignment.center,
                child: Text(
                  'No sales recorded for this period yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.black87 : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
