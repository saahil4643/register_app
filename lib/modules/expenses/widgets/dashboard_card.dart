import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

class DashboardCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final double amount;
  final String subtitle;
  final Color? tintColor;
  final Color? backgroundColor;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
    required this.subtitle,
    this.tintColor,
    this.backgroundColor,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    final resolvedTextColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final resolvedSubColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Use default values if not custom colored
    final primaryColor = widget.tintColor ?? theme.colorScheme.primary;
    final defaultBgColor = isDark 
        ? primaryColor.withOpacity(0.08) 
        : primaryColor.withOpacity(0.04);
    final cardBgColor = widget.backgroundColor ?? defaultBgColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 240,
        height: 125,
        transform: _isHovered ? (Matrix4.identity()..translate(0, -4, 0)) : Matrix4.identity(),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : cardBgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: _isHovered 
                ? primaryColor.withOpacity(0.4) 
                : (isDark ? AppColors.darkBorder : primaryColor.withOpacity(0.12)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(_isHovered ? 0.08 : 0.02),
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: resolvedSubColor,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? primaryColor.withOpacity(0.2) : primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatter.format(widget.amount),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: resolvedTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: resolvedSubColor.withOpacity(0.8),
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
