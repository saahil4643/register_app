import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../invoices/models/invoice.dart';
import '../../invoices/providers/invoice_provider.dart';
import '../../invoices/widgets/status_chip.dart';
import '../../customers/screens/create_customer_screen.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../bills/providers/bill_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_sub_tabs.dart';
import '../widgets/financial_overview_cards.dart';
import '../widgets/quick_create_grid.dart';
import '../widgets/cash_flow_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedSubTab = 0;
  bool _showNotificationBanner = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboardData();
      context.read<SettingsProvider>().fetchSettings();
      context.read<BillProvider>().fetchBills();
      context.read<InvoiceProvider>().fetchInvoices();
    });
  }

  void _showReceivablesBreakdown(BuildContext context, DashboardProvider provider) {
    final report = provider.receivables;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Receivables Aging Breakdown',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                _buildAgingRow('1 - 30 Days', currency.format(report?.days1To30 ?? 0.0)),
                _buildAgingRow('31 - 60 Days', currency.format(report?.days31To60 ?? 0.0)),
                _buildAgingRow('61 - 90 Days', currency.format(report?.days61To90 ?? 0.0)),
                _buildAgingRow('90+ Days (Overdue)', currency.format(report?.days90Plus ?? 0.0), isAlert: true),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/invoices');
                    },
                    child: const Text('View All Invoices'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPayablesBreakdown(BuildContext context, DashboardProvider provider) {
    final report = provider.profitLoss;
    final billProvider = context.read<BillProvider>();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final theme = Theme.of(context);

    final billsTotal = billProvider.bills.fold<double>(0.0, (sum, b) => sum + b.balanceDue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payables Breakdown',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                _buildAgingRow('Bills Due (Payables)', currency.format(billsTotal > 0 ? billsTotal : (report?.billsExpenses ?? 0.0))),
                _buildAgingRow('Operating Expenses', currency.format(report?.operatingExpenses ?? 0.0)),
                _buildAgingRow('Purchase Expenses', currency.format(report?.purchaseExpenses ?? 0.0)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/purchases/bills');
                    },
                    child: const Text('View All Bills'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgingRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isAlert ? AppColors.error : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dashboardProvider = context.watch<DashboardProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    String companyName = '';
    if (dashboardProvider.organization?.companyName.trim().isNotEmpty == true) {
      companyName = dashboardProvider.organization!.companyName.trim();
    } else if (settingsProvider.companySettings?.companyName.trim().isNotEmpty == true) {
      companyName = settingsProvider.companySettings!.companyName.trim();
    } else if (authProvider.currentUserCompanyName?.trim().isNotEmpty == true) {
      companyName = authProvider.currentUserCompanyName!.trim();
    }
    if (companyName.isEmpty) {
      companyName = 'My Business';
    }

    final billProvider = context.watch<BillProvider>();
    final invoiceProvider = context.watch<InvoiceProvider>();

    final backendReceivables = dashboardProvider.receivables?.totalReceivables ?? 0.0;
    final invoicesReceivable = invoiceProvider.invoices
        .where((inv) => inv.status != InvoiceStatus.paid && inv.status != InvoiceStatus.cancelled)
        .fold<double>(0.0, (sum, inv) => sum + inv.balanceDue);
    final totalReceivables = backendReceivables > 0 ? backendReceivables : invoicesReceivable;
    
    // Total payables starts at 0.0 and increases as bills / expenses are added
    final totalBillsPayable = billProvider.bills.fold<double>(
      0.0,
      (sum, b) => sum + b.balanceDue,
    );
    final totalPayables = totalBillsPayable > 0
        ? totalBillsPayable
        : (dashboardProvider.profitLoss?.totalExpenses ?? 0.0);

    final overdueInvoicesCount = invoiceProvider.invoices.isNotEmpty
        ? invoiceProvider.invoices.where((inv) => inv.status == InvoiceStatus.overdue).length
        : dashboardProvider.recentInvoices.where((inv) => inv.status == InvoiceStatus.overdue).length;

    // Overdue bills starts at 0 and increases if bills have overdue status or passed due date
    final overdueBillsCount = billProvider.bills.where((b) {
      final isStatusOverdue = b.status.toLowerCase() == 'overdue';
      final isPastDue = b.dueDate != null &&
          b.dueDate!.isBefore(DateTime.now()) &&
          b.balanceDue > 0;
      return isStatusOverdue || isPastDue;
    }).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar: Hamburger Menu | Company Title | Notification Bell
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      size: 26,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      companyName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No new unread notifications'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // 2. Sub Tabs: Dashboard | Announcements | Help
            DashboardSubTabs(
              selectedIndex: _selectedSubTab,
              onTabSelected: (index) {
                setState(() => _selectedSubTab = index);
              },
            ),

            // 3. Tab Body
            Expanded(
              child: IndexedStack(
                index: _selectedSubTab,
                children: [
                  // Tab 0: Dashboard Content
                  RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([
                        dashboardProvider.fetchDashboardData(refresh: true),
                        context.read<InvoiceProvider>().fetchInvoices(refresh: true),
                        context.read<BillProvider>().fetchBills(),
                      ]);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Notification Reminder Banner
                          if (_showNotificationBanner) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : const Color(0xFFCBD5E1),
                                    width: 1.1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.notifications_none_rounded,
                                      size: 20,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Don't miss your Notifications",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: isDark
                                              ? const Color(0xFFCBD5E1)
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() => _showNotificationBanner = false);
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Dismiss',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () {
                                        setState(() => _showNotificationBanner = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Notifications enabled successfully!'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Enable',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E88E5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fade().slideY(begin: -0.05),
                            const SizedBox(height: 16),
                          ],

                          // Financial Overview Cards (Receivables & Payables | Overdue Invoices & Bills)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: FinancialOverviewCards(
                              totalReceivables: totalReceivables,
                              totalPayables: totalPayables,
                              overdueInvoicesCount: overdueInvoicesCount,
                              overdueBillsCount: overdueBillsCount,
                              onReceivablesTap: () => _showReceivablesBreakdown(context, dashboardProvider),
                              onPayablesTap: () => _showPayablesBreakdown(context, dashboardProvider),
                              onOverdueInvoicesTap: () => context.go('/invoices'),
                              onOverdueBillsTap: () => context.push('/purchases/bills'),
                            ),
                          ).animate().fade(delay: 50.ms),

                          const SizedBox(height: 20),

                          // Quick Create Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: QuickCreateGrid(
                              onNewCustomer: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CreateCustomerScreen()),
                                );
                              },
                              onNewInvoice: () {
                                context.read<InvoiceProvider>().startNewInvoice();
                                context.push('/invoices/create');
                              },
                              onNewBill: () {
                                context.push('/purchases/bills/new');
                              },
                              onNewExpense: () {
                                context.push('/expenses');
                              },
                            ),
                          ).animate().fade(delay: 100.ms),

                          const SizedBox(height: 20),

                          // Divider Band Strip
                          Container(
                            height: 8,
                            width: double.infinity,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF1F5F9),
                          ),

                          const SizedBox(height: 18),

                          // Cash Flow Card Section
                          CashFlowCard(
                            profitLoss: dashboardProvider.profitLoss,
                            salesSummary: dashboardProvider.salesSummary,
                            invoices: invoiceProvider.invoices.isNotEmpty
                                ? invoiceProvider.invoices
                                : dashboardProvider.recentInvoices,
                            bills: billProvider.bills,
                          ).animate().fade(delay: 150.ms),

                          const SizedBox(height: 24),

                          // Recent Invoices Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Invoices',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/invoices'),
                                  child: const Text('View All'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          if ((invoiceProvider.invoices.isNotEmpty ? invoiceProvider.invoices : dashboardProvider.recentInvoices).isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: (invoiceProvider.invoices.isNotEmpty ? invoiceProvider.invoices : dashboardProvider.recentInvoices).take(5).length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final displayList = invoiceProvider.invoices.isNotEmpty ? invoiceProvider.invoices : dashboardProvider.recentInvoices;
                                  final inv = displayList[index];
                                  final dateFormatted = DateFormat('dd MMM yyyy').format(inv.invoiceDate);

                                  return Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.grey.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () => context.push('/invoices/details/${inv.id}'),
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
                                              child: Icon(Icons.receipt_outlined,
                                                  color: theme.colorScheme.primary, size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    inv.customer.name.isNotEmpty
                                                        ? inv.customer.name
                                                        : 'Customer',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 14),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '${inv.invoiceNumber} • $dateFormatted',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isDark
                                                          ? AppColors.darkTextSecondary
                                                          : AppColors.lightTextSecondary,
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
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold, fontSize: 14),
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
                              ),
                            ),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.grey.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey[400]),
                                        const SizedBox(height: 8),
                                        const Text('No invoices yet',
                                            style: TextStyle(fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        TextButton(
                                          onPressed: () {
                                            context.read<InvoiceProvider>().startNewInvoice();
                                            context.push('/invoices/create');
                                          },
                                          child: const Text('Create your first invoice'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Tab 1: Announcements Content
                  _buildAnnouncementsView(context, isDark),

                  // Tab 2: Help Content
                  _buildHelpView(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsView(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_outlined,
                size: 48,
                color: Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No New Announcements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're all caught up! Important company updates, tax alerts, and system notices will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpView(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        _buildHelpCard(
          icon: Icons.menu_book_outlined,
          title: 'User Guide & Documentation',
          subtitle: 'Learn how to create invoices, track expenses, and manage GST.',
          onTap: () => context.push('/help'),
        ),
        const SizedBox(height: 10),
        _buildHelpCard(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Live Support Chat',
          subtitle: 'Talk directly with customer support team for any queries.',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Connecting to Support Chat...')),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildHelpCard(
          icon: Icons.mail_outline_rounded,
          title: 'Email Support',
          subtitle: 'support@prapti.com / prabhim.one@gmail.com',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Support email copied to clipboard')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }
}
