import 'package:flutter/material.dart';
import '../../customers/models/customer.dart';
import '../../../core/constants/app_colors.dart';

class CustomerCard extends StatelessWidget {
  final Customer? customer;
  final VoidCallback onSelectTap;
  final VoidCallback? onAddCustomerTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onSelectTap,
    this.onAddCustomerTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? theme.colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CUSTOMER INFORMATION',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Row(
                  children: [
                    if (customer == null && onAddCustomerTap != null) ...[
                      TextButton.icon(
                        onPressed: onAddCustomerTap,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                        label: const Text('Add Customer'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    TextButton(
                      onPressed: onSelectTap,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      child: Text(customer != null ? 'Change Client' : 'Select Client'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (customer != null) ...[
              const Divider(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      customer!.company.isNotEmpty ? customer!.company.substring(0, 1).toUpperCase() : 'C',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer!.company,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Primary Contact: ${customer!.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        _buildInfoLabel('Email', customer!.email, Icons.email_outlined, theme),
                        _buildInfoLabel('Phone', customer!.phone, Icons.phone_outlined, theme),
                        _buildInfoLabel(
                          'GSTIN',
                          customer!.gstNo.isNotEmpty ? customer!.gstNo : 'Not Registered',
                          Icons.receipt_outlined,
                          theme,
                          isMonospace: true,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Billing Address',
                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    customer!.address,
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Shipping Address',
                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    customer!.address, // using billing address as shipping address as well
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: onSelectTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder.withOpacity(0.3) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 28,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No Customer Selected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap here to choose a customer from the registry',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLabel(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontFamily: isMonospace ? 'monospace' : null,
                color: theme.brightness == Brightness.dark ? Colors.white70 : AppColors.lightTextPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
