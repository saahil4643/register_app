import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class QuickCreateGrid extends StatelessWidget {
  final VoidCallback onNewCustomer;
  final VoidCallback onNewInvoice;
  final VoidCallback onNewBill;
  final VoidCallback onNewExpense;

  const QuickCreateGrid({
    super.key,
    required this.onNewCustomer,
    required this.onNewInvoice,
    required this.onNewBill,
    required this.onNewExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        // Section Header: Lightning Icon + Quick Create
        Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            ),
            const SizedBox(width: 6),
            Text(
              'Quick Create',
              style: TextStyle(
                fontSize: 15,
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
              icon: Icons.person_outline_rounded,
              label: 'New\nCustomer',
              bgColor: itemBg,
              iconColor: iconColor,
              textColor: textColor,
              onTap: onNewCustomer,
            ),
            const SizedBox(width: 10),
            _buildActionItem(
              context,
              icon: Icons.flash_on_rounded,
              label: '⚡ Quick\nBill',
              bgColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
              iconColor: const Color(0xFF2563EB),
              textColor: const Color(0xFF2563EB),
              onTap: onNewInvoice,
            ),
            const SizedBox(width: 10),
            _buildActionItem(
              context,
              icon: Icons.receipt_long_outlined,
              label: 'New\nBill',
              bgColor: itemBg,
              iconColor: iconColor,
              textColor: textColor,
              onTap: onNewBill,
            ),
            const SizedBox(width: 10),
            _buildActionItem(
              context,
              icon: Icons.rate_review_outlined,
              label: 'New\nExpense',
              bgColor: itemBg,
              iconColor: iconColor,
              textColor: textColor,
              onTap: onNewExpense,
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
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
