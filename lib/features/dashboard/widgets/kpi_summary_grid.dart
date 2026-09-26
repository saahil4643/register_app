import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/dashboard_reports.dart';

class KpiSummaryGrid extends StatelessWidget {
  final SalesSummaryReport? salesSummary;
  final ProfitLossReport? profitLoss;

  const KpiSummaryGrid({
    super.key,
    required this.salesSummary,
    required this.profitLoss,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final totalRevenue = (salesSummary?.totalInvoicedAmount != null && salesSummary!.totalInvoicedAmount > 0)
        ? salesSummary!.totalInvoicedAmount
        : (profitLoss?.totalSales ?? 0.0);
    final amountReceived = salesSummary?.totalPaidAmount ?? 0.0;
    final outstandingDue = salesSummary?.totalOutstandingAmount ?? 0.0;
    final netProfit = profitLoss?.netProfit ?? 0.0;
    final netProfitMargin = profitLoss?.netProfitMargin ?? 0.0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: [
        _buildKpiCard(
          context,
          title: 'Total Revenue',
          value: currency.format(totalRevenue),
          subtitle: '${salesSummary?.totalInvoices ?? 0} Invoices',
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF3B82F6),
          iconBgColor: const Color(0xFFEFF6FF),
        ),
        _buildKpiCard(
          context,
          title: 'Amount Received',
          value: currency.format(amountReceived),
          subtitle: 'Collected cash',
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.success,
          iconBgColor: const Color(0xFFECFDF5),
        ),
        _buildKpiCard(
          context,
          title: 'Outstanding Due',
          value: currency.format(outstandingDue),
          subtitle: 'Pending collections',
          icon: Icons.hourglass_empty_rounded,
          iconColor: AppColors.warning,
          iconBgColor: const Color(0xFFFEF3C7),
        ),
        _buildKpiCard(
          context,
          title: 'Net Profit',
          value: currency.format(netProfit),
          subtitle: netProfitMargin > 0 ? '${netProfitMargin.toStringAsFixed(1)}% margin' : 'Net margin',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: netProfit >= 0 ? AppColors.success : AppColors.error,
          iconBgColor: netProfit >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? iconColor.withValues(alpha: 0.2) : iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
