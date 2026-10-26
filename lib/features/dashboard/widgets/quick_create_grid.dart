import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class QuickCreateGrid extends StatelessWidget {
  final VoidCallback onNewInvoice;
  final VoidCallback onCollectPayment;
  final VoidCallback onNewCustomer;
  final VoidCallback onGstReports;

  const QuickCreateGrid({
    super.key,
    required this.onNewInvoice,
    required this.onCollectPayment,
    required this.onNewCustomer,
    required this.onGstReports,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final itemBg = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9).withValues(alpha: 0.85);

    final iconColor = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF0F172A);

    final textColor = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1E293B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 18,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            ),
            const SizedBox(width: 6),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 4 Action Buttons in a Row
        Row(
          children: [
            _buildActionItem(
              context,
              icon: Icons.receipt_long_rounded,
              label: 'New\nInvoice',
              bgColor: itemBg,
              iconColor: AppColors.lightPrimary,
              textColor: textColor,
              onTap: onNewInvoice,
            ),
            const SizedBox(width: 10),
            _buildActionItem(
              context,
              icon: Icons.payments_outlined,
              label: 'Collect\nPayment',
              bgColor: itemBg,
              iconColor: AppColors.success,
              textColor: textColor,
              onTap: onCollectPayment,
            ),
            const SizedBox(width: 10),
            _buildActionItem(
              context,
              icon: Icons.person_add_alt_1_outlined,
              label: 'New\nCustomer',
              bgColor: itemBg,
              iconColor: iconColor,
              textColor: textColor,
              onTap: onNewCustomer,
            ),
            const SizedBox(width: 10),
            _buildActionItem(
              context,
              icon: Icons.bar_chart_rounded,
              label: 'GST\nReports',
              bgColor: itemBg,
              iconColor: const Color(0xFF0284C7),
              textColor: textColor,
              onTap: onGstReports,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: iconColor,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
