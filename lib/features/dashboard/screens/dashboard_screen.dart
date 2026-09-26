import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_cards.dart';
import '../../../core/widgets/custom_states.dart';
import '../../settings/providers/settings_provider.dart';
import '../../authentication/providers/auth_provider.dart';

import '../../invoices/providers/invoice_provider.dart';
import '../../customers/providers/customer_provider.dart';

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
      context.read<InvoiceProvider>().fetchDashboardStats();
      context.read<CustomerProvider>().fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsProvider = context.watch<SettingsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final invoiceProvider = context.watch<InvoiceProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    
    final companyName = settingsProvider.companySettings?.companyName ?? 'Prabhim One';
    final email = authProvider.currentUserEmail ?? 'admin@prabhim.com';
    final firstName = authProvider.currentUserFirstName ?? '';
    final lastName = authProvider.currentUserLastName ?? '';
    String userName = '$firstName $lastName'.trim();
    if (userName.isEmpty) {
      userName = email.split('@')[0];
      userName = userName.split('.').map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '').join(' ');
    }
    if (userName.isEmpty) {
      userName = 'Prabhim One Admin';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<SettingsProvider>().fetchSettings(),
              context.read<InvoiceProvider>().fetchDashboardStats(),
              context.read<CustomerProvider>().fetchDashboardStats(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting, Business Name, Avatar & Action Icons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: CustomAvatar(
                            name: userName,
                            radius: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good morning,',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              companyName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.search_rounded, color: theme.colorScheme.onBackground),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Search - Phase 2'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: Icon(Icons.notifications_outlined, color: theme.colorScheme.onBackground),
                              onPressed: () => context.push('/notifications'),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    )
                  ],
                ).animate().fade().slideY(begin: -0.1),
                const SizedBox(height: 24),

                // Cash Flow Chart Card
                _buildCashFlowChartCard(context),
                const SizedBox(height: 24),

                // Stats Grid
                const SectionHeader(title: 'Financial Overview'),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.28,
                  children: [
                    StatisticCard(
                      title: 'Net Revenue',
                      value: '\$${(invoiceProvider.dashboardStats['revenue'] ?? 0.0).toStringAsFixed(2)}',
                      changePercentage: '0.0%',
                      isPositiveTrend: true,
                      icon: Icons.trending_up_rounded,
                    ),
                    StatisticCard(
                      title: 'Outstanding',
                      value: '\$${(invoiceProvider.dashboardStats['outstanding'] ?? 0.0).toStringAsFixed(2)}',
                      changePercentage: '0.0%',
                      isPositiveTrend: false,
                      icon: Icons.hourglass_empty_rounded,
                      iconColor: AppColors.warning,
                      iconBackgroundColor: const Color(0xFFFEF3C7),
                    ),
                    StatisticCard(
                      title: 'Total Expenses',
                      value: '\$0.00',
                      changePercentage: '0.0%',
                      isPositiveTrend: false,
                      icon: Icons.shopping_bag_outlined,
                      iconColor: AppColors.error,
                      iconBackgroundColor: const Color(0xFFFEE2E2).withOpacity(0.8),
                    ),
                    StatisticCard(
                      title: 'Active Clients',
                      value: '${customerProvider.dashboardStats['active_customers'] ?? 0}',
                      changePercentage: '0.0%',
                      isPositiveTrend: true,
                      icon: Icons.people_outline_rounded,
                      iconColor: AppColors.info,
                      iconBackgroundColor: const Color(0xFFEFF6FF),
                    ),
                  ],
                ).animate().fade(delay: 150.ms),
                const SizedBox(height: 24),

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
                        onTap: () => context.push('/invoices'),
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
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Log Expense - Coming Soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fade(delay: 200.ms),
                const SizedBox(height: 24),

                // Recent Transactions List
                SectionHeader(
                  title: 'Recent Invoices',
                  actionLabel: 'View All',
                  onActionPressed: () => context.go('/invoices'),
                ),
                const SizedBox(height: 8),
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ListCard(
                      title: 'Zenith Enterprises Inc.',
                      subtitle: 'INV-2026-001 • July 05, 2026',
                      amount: '\$12,450.00',
                      statusWidget: StatusChip.paid(),
                      leadingIcon: Icons.receipt_long_outlined,
                      onTap: () => context.push('/invoices'),
                    ),
                    const SizedBox(height: 10),
                    ListCard(
                      title: 'TechStart Solutions',
                      subtitle: 'INV-2026-002 • July 04, 2026',
                      amount: '\$4,820.00',
                      statusWidget: StatusChip.pending(),
                      leadingIcon: Icons.receipt_long_outlined,
                      onTap: () => context.push('/invoices'),
                    ),
                    const SizedBox(height: 10),
                    ListCard(
                      title: 'Globex Consulting Ltd.',
                      subtitle: 'INV-2026-003 • June 28, 2026',
                      amount: '\$7,580.00',
                      statusWidget: StatusChip.overdue(),
                      leadingIcon: Icons.receipt_long_outlined,
                      onTap: () => context.push('/invoices'),
                    ),
                  ],
                ).animate().fade(delay: 250.ms),
                const SizedBox(height: 24),
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
              color: isDark ? theme.colorScheme.outline : Colors.grey.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
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

  Widget _buildCashFlowChartCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash Flow',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Income vs Expenses (Last 6 Months)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surface : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('Inflow', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('Outflow', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(
                painter: _CashFlowPainter(
                  inflowData: [40, 55, 45, 70, 60, 85],
                  outflowData: [25, 30, 20, 45, 35, 50],
                  months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                  lineColorIn: AppColors.success,
                  lineColorOut: AppColors.error,
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashFlowPainter extends CustomPainter {
  final List<double> inflowData;
  final List<double> outflowData;
  final List<String> months;
  final Color lineColorIn;
  final Color lineColorOut;
  final bool isDark;

  _CashFlowPainter({
    required this.inflowData,
    required this.outflowData,
    required this.months,
    required this.lineColorIn,
    required this.lineColorOut,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final widthStep = size.width / (inflowData.length - 1);
    const maxVal = 100.0;

    final paintIn = Paint()
      ..color = lineColorIn
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintOut = Paint()
      ..color = lineColorOut
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pathIn = Path();
    final pathOut = Path();

    for (int i = 0; i < inflowData.length; i++) {
      final x = i * widthStep;
      final yIn = size.height - (inflowData[i] / maxVal * size.height * 0.85);
      final yOut = size.height - (outflowData[i] / maxVal * size.height * 0.85);

      if (i == 0) {
        pathIn.moveTo(x, yIn);
        pathOut.moveTo(x, yOut);
      } else {
        pathIn.lineTo(x, yIn);
        pathOut.lineTo(x, yOut);
      }

      final dotPaintIn = Paint()
        ..color = lineColorIn
        ..style = PaintingStyle.fill;
      final dotPaintOut = Paint()
        ..color = lineColorOut
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, yIn), 4, dotPaintIn);
      canvas.drawCircle(Offset(x, yOut), 4, dotPaintOut);

      textPainter.text = TextSpan(
        text: months[i],
        style: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[600],
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height + 6));
    }

    canvas.drawPath(pathIn, paintIn);
    canvas.drawPath(pathOut, paintOut);
  }

  @override
  bool shouldRepaint(covariant _CashFlowPainter oldDelegate) => false;
}
