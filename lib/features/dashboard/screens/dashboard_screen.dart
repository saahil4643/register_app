import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_states.dart' hide StatusChip;
import '../../invoices/widgets/status_chip.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/kpi_summary_grid.dart';
import '../widgets/receivables_card.dart';
import '../widgets/sales_trend_card.dart';
import '../widgets/expense_breakdown_card.dart';
import '../widgets/top_customers_widget.dart';
import '../widgets/recent_payments_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dashboardProvider = context.watch<DashboardProvider>();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => dashboardProvider.fetchDashboardData(refresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header & Welcome Banner (GET /api/v1/auth/me & /api/v1/organization)
                DashboardHeader(
                  userProfile: dashboardProvider.userProfile,
                  organization: dashboardProvider.organization,
                  onOpenDrawer: () => Scaffold.of(context).openDrawer(),
                ).animate().fade().slideY(begin: -0.05),

                const SizedBox(height: 20),

                // 2. KPI Summary Cards (GET /api/v1/reports/sales-summary & /api/v1/reports/profit-loss)
                const SectionHeader(title: 'Financial Overview'),
                const SizedBox(height: 10),
                KpiSummaryGrid(
                  salesSummary: dashboardProvider.salesSummary,
                  profitLoss: dashboardProvider.profitLoss,
                ).animate().fade(delay: 100.ms),

                const SizedBox(height: 20),

                // 3. Receivables & Aging Card (GET /api/v1/reports/receivables)
                ReceivablesCard(
                  report: dashboardProvider.receivables,
                ).animate().fade(delay: 150.ms),

                const SizedBox(height: 20),

                // 4. Sales & Profit Charts (GET /api/v1/reports/sales-summary?period=monthly & profit-loss)
                SalesTrendCard(
                  salesSummary: dashboardProvider.salesSummary,
                  profitLoss: dashboardProvider.profitLoss,
                  selectedPeriod: dashboardProvider.salesPeriod,
                  onPeriodChanged: (period) => dashboardProvider.setSalesPeriod(period),
                ).animate().fade(delay: 200.ms),

                const SizedBox(height: 20),

                // 5. Expense Breakdown Chart (GET /api/v1/reports/profit-loss)
                ExpenseBreakdownCard(
                  profitLoss: dashboardProvider.profitLoss,
                ).animate().fade(delay: 250.ms),

                const SizedBox(height: 20),

                // Quick Actions Horizontal Carousel
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 94,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildQuickActionItem(
                        context,
                        label: 'New Invoice',
                        icon: Icons.add_chart_outlined,
                        onTap: () => context.push('/invoices/new'),
                      ),
                      _buildQuickActionItem(
                        context,
                        label: 'Add Customer',
                        icon: Icons.person_add_alt_1_outlined,
                        onTap: () => context.push('/customers'),
                      ),
                      _buildQuickActionItem(
                        context,
                        label: 'Add Product',
                        icon: Icons.add_box_outlined,
                        onTap: () => context.push('/products'),
                      ),
                      _buildQuickActionItem(
                        context,
                        label: 'Log Expense',
                        icon: Icons.receipt_long_outlined,
                        onTap: () => context.push('/expenses'),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 300.ms),

                const SizedBox(height: 24),

                // 6. Recent Invoices Table (GET /api/v1/invoices?page=1&page_size=5)
                SectionHeader(
                  title: 'Recent Invoices',
                  actionLabel: 'View All',
                  onActionPressed: () => context.go('/invoices'),
                ),
                const SizedBox(height: 10),
                if (dashboardProvider.recentInvoices.isNotEmpty) ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dashboardProvider.recentInvoices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final inv = dashboardProvider.recentInvoices[index];
                      final dateFormatted = DateFormat('dd MMM yyyy').format(inv.invoiceDate);

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
                          ),
                        ),
                        child: InkWell(
                          onTap: () => context.push('/invoices/${inv.id}'),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.receipt_outlined, color: theme.colorScheme.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inv.customer.name.isNotEmpty ? inv.customer.name : 'Customer',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${inv.invoiceNumber} • $dateFormatted',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currency.format(inv.grandTotal),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    StatusChip(status: inv.status),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ).animate().fade(delay: 350.ms),
                ] else ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            const Text('No invoices yet', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () => context.push('/invoices/new'),
                              child: const Text('Create your first invoice'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // 7. Top Customers Widget (GET /api/v1/reports/sales-summary)
                TopCustomersWidget(
                  topCustomers: dashboardProvider.salesSummary?.topCustomers ?? [],
                ).animate().fade(delay: 400.ms),

                const SizedBox(height: 20),

                // 8. Recent Payments Received Widget (GET /api/v1/payments)
                RecentPaymentsWidget(
                  payments: dashboardProvider.recentPayments,
                ).animate().fade(delay: 450.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? theme.colorScheme.outline : Colors.grey.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
