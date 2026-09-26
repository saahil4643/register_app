import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_states.dart';

class ExpenseCard extends StatefulWidget {
  final ExpenseModel expense;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onDelete,
    this.onEdit,
    this.onTap,
  });

  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard> {
  bool _isHovered = false;

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'rent':
        return Icons.home_work_rounded;
      case 'electricity':
        return Icons.electric_bolt_rounded;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'office supplies':
        return Icons.inventory_2_rounded;
      case 'fuel':
        return Icons.local_gas_station_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      case 'software':
        return Icons.code_rounded;
      case 'internet':
        return Icons.wifi_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'salary':
        return Icons.payments_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category, ThemeData theme) {
    switch (category.toLowerCase()) {
      case 'rent':
        return Colors.blue;
      case 'electricity':
        return Colors.orange;
      case 'travel':
        return Colors.teal;
      case 'office supplies':
        return Colors.indigo;
      case 'fuel':
        return Colors.amber;
      case 'marketing':
        return Colors.pink;
      case 'software':
        return theme.colorScheme.primary;
      case 'internet':
        return Colors.deepPurple;
      case 'food':
        return Colors.green;
      case 'salary':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  Widget _getStatusChip(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return StatusChip.paid(label: 'Paid');
      case 'pending':
        return StatusChip.pending(label: 'Pending');
      case 'cancelled':
        return const StatusChip(
          label: 'Cancelled',
          color: AppColors.error,
          backgroundColor: Color(0xFFFEE2E2),
        );
      default:
        return StatusChip.draft(label: status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy');

    final catIcon = _getCategoryIcon(widget.expense.category);
    final catColor = _getCategoryColor(widget.expense.category, theme);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withOpacity(0.4)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.05 : 0.01),
              blurRadius: _isHovered ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    catIcon,
                    color: catColor,
                    size: 22,
                  ),
                ),
                AppSpacing.widthM,
                // Category and Vendor Name / Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.expense.category,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.expense.isDraft) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'DRAFT',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.expense.vendor} • ${dateFormatter.format(widget.expense.expenseDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppSpacing.widthM,
                // Amount and Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormatter.format(widget.expense.totalAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _getStatusChip(widget.expense.status),
                  ],
                ),
                // Context Actions Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (action) {
                    if (action == 'edit' && widget.onEdit != null) {
                      widget.onEdit!();
                    } else if (action == 'delete' && widget.onDelete != null) {
                      widget.onDelete!();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Edit Details'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                          const SizedBox(width: 8),
                          const Text('Delete Expense', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
