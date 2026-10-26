import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_states.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../authentication/providers/auth_provider.dart';
import '../settings/providers/settings_provider.dart';

class NavigationShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  static void openDrawer([BuildContext? context]) {
    if (scaffoldKey.currentState?.hasDrawer ?? false) {
      scaffoldKey.currentState!.openDrawer();
      return;
    }
    if (context != null) {
      context.visitAncestorElements((element) {
        if (element is StatefulElement && element.state is ScaffoldState) {
          final state = element.state as ScaffoldState;
          if (state.hasDrawer) {
            state.openDrawer();
            return false;
          }
        }
        return true;
      });
    }
  }

  const NavigationShell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchSettings();
    });
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  int _calculateBottomNavIndex(String location, int branchIndex) {
    if (location.startsWith('/dashboard') || branchIndex == 0) {
      return 0; // Home
    }
    if (location.startsWith('/invoices') || location.startsWith('/sales') || branchIndex == 1) {
      return 1; // Sales
    }
    if (location.startsWith('/purchases')) {
      return 2; // Purchases
    }
    if (location.startsWith('/expenses') || branchIndex == 4) {
      return 3; // Expenses
    }
    // Customers (2), Products (3), Settings (5), Reports, Payments, Help
    return 4; // More
  }

  void _onBottomNavTap(BuildContext context, int bottomIndex) {
    switch (bottomIndex) {
      case 0:
        _onTap(context, 0); // Home (Dashboard)
        break;
      case 1:
        _onTap(context, 1); // Sales (Invoices)
        break;
      case 2:
        _showPurchasesMenu(context);
        break;
      case 3:
        _onTap(context, 4); // Expenses
        break;
      case 4:
        _showMoreMenu(context);
        break;
    }
  }

  void _showPurchasesMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.shopping_bag_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchases',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Suppliers, purchase orders & vendor bills',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildModalMenuItem(
                  context,
                  icon: Icons.storefront_rounded,
                  iconBg: const Color(0xFFEDE9FE),
                  iconColor: AppColors.lightPrimary,
                  title: 'Vendors',
                  subtitle: 'Manage supplier contacts and accounts',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/purchases/vendors');
                  },
                ),
                const SizedBox(height: 8),
                _buildModalMenuItem(
                  context,
                  icon: Icons.assignment_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: AppColors.warning,
                  title: 'Purchase Orders',
                  subtitle: 'Track and issue procurement orders',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/purchases/purchase-orders');
                  },
                ),
                const SizedBox(height: 8),
                _buildModalMenuItem(
                  context,
                  icon: Icons.receipt_rounded,
                  iconBg: const Color(0xFFD1FAE5),
                  iconColor: AppColors.success,
                  title: 'Bills',
                  subtitle: 'Vendor bills, payment terms & payables',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/purchases/bills');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMoreMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.grid_view_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'More Modules & Actions',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Operations, reports, and system settings',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Customers
                _buildModalMenuItem(
                  context,
                  icon: Icons.people_rounded,
                  iconBg: const Color(0xFFEDE9FE),
                  iconColor: AppColors.lightPrimary,
                  title: 'Customers',
                  subtitle: 'Client directory, receivables & balances',
                  onTap: () {
                    Navigator.pop(ctx);
                    _onTap(context, 2);
                  },
                ),
                const SizedBox(height: 8),

                // 2. Items / Products & Services
                _buildModalMenuItem(
                  context,
                  icon: Icons.inventory_2_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: AppColors.warning,
                  title: 'Items / Products & Services',
                  subtitle: 'Inventory catalog, pricing & stock tracking',
                  onTap: () {
                    Navigator.pop(ctx);
                    _onTap(context, 3);
                  },
                ),
                const SizedBox(height: 8),

                // 3. Payments
                _buildModalMenuItem(
                  context,
                  icon: Icons.payments_rounded,
                  iconBg: const Color(0xFFD1FAE5),
                  iconColor: AppColors.success,
                  title: 'Payments',
                  subtitle: 'Payment receipts, settlements & bank logs',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/payments');
                  },
                ),
                const SizedBox(height: 8),

                // 4. Reports
                _buildModalMenuItem(
                  context,
                  icon: Icons.bar_chart_rounded,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: AppColors.info,
                  title: 'Reports',
                  subtitle: 'Financial statements, sales analytics & tax summaries',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/reports');
                  },
                ),
                const SizedBox(height: 8),

                // 5. Settings
                _buildModalMenuItem(
                  context,
                  icon: Icons.settings_rounded,
                  iconBg: isDark ? Colors.white12 : const Color(0xFFF3F4F6),
                  iconColor: isDark ? Colors.white : AppColors.lightTextPrimary,
                  title: 'Settings',
                  subtitle: 'Company details, preferences & tax setup',
                  onTap: () {
                    Navigator.pop(ctx);
                    _onTap(context, 5);
                  },
                ),
                const SizedBox(height: 8),

                // 6. Help
                _buildModalMenuItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  iconBg: const Color(0xFFEDE9FE),
                  iconColor: AppColors.lightPrimary,
                  title: 'Help',
                  subtitle: 'Guides, user manuals & live customer support',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/help');
                  },
                ),
                const SizedBox(height: 8),

                // 7. Logout
                _buildModalMenuItem(
                  context,
                  icon: Icons.logout_rounded,
                  iconBg: const Color(0xFFFEE2E2),
                  iconColor: AppColors.error,
                  title: 'Logout',
                  subtitle: 'Sign out of Prabhim One',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (context) => ConfirmationDialog(
                        title: 'Log Out',
                        content: 'Are you sure you want to log out of Prabhim One?',
                        confirmLabel: 'Log Out',
                        onConfirm: () async {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            context.go('/welcome');
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? iconColor.withValues(alpha: 0.2) : iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDestructive
                          ? AppColors.error
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final location = GoRouterState.of(context).uri.path;
    final bottomNavIndex = _calculateBottomNavIndex(location, widget.navigationShell.currentIndex);

    final email = authProvider.currentUserEmail ?? '';
    final firstName = authProvider.currentUserFirstName ?? '';
    final lastName = authProvider.currentUserLastName ?? '';
    String userName = '$firstName $lastName'.trim();
    if (userName.isEmpty && email.isNotEmpty) {
      userName = email.split('@')[0];
      userName = userName.split('.').map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '').join(' ');
    }
    if (userName.isEmpty) {
      userName = 'User';
    }
    final companyName = settingsProvider.companySettings?.companyName.isNotEmpty == true
        ? settingsProvider.companySettings!.companyName
        : 'My Business';

    return Scaffold(
      key: NavigationShell.scaffoldKey,
      drawer: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            // Custom Premium Drawer Header
            InkWell(
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
              child: Container(
                padding: const EdgeInsets.only(top: 60, bottom: 24, left: 20, right: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surface : theme.colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    CustomAvatar(
                      name: userName,
                      imageUrl: authProvider.currentUserProfileImage ?? authProvider.currentUserAvatar,
                      radius: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            companyName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation Items (Exact structure required)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                children: [
                  // 1. Dashboard
                  ListTile(
                    leading: const Icon(Icons.dashboard_rounded),
                    title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: location.startsWith('/dashboard') || widget.navigationShell.currentIndex == 0,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      _onTap(context, 0);
                    },
                  ),
                  const SizedBox(height: 4),

                  // 2. Customers
                  ListTile(
                    leading: const Icon(Icons.people_rounded),
                    title: const Text('Customers', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: location.startsWith('/customers') || widget.navigationShell.currentIndex == 2,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      _onTap(context, 2);
                    },
                  ),
                  const SizedBox(height: 4),

                  // 3. Items / Products & Services
                  ListTile(
                    leading: const Icon(Icons.inventory_2_rounded),
                    title: const Text('Items / Products & Services', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: location.startsWith('/products') || widget.navigationShell.currentIndex == 3,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      _onTap(context, 3);
                    },
                  ),
                  const SizedBox(height: 4),

                  // 4. Sales (Expandable)
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      leading: Icon(
                        Icons.monetization_on_rounded,
                        color: (location.startsWith('/invoices') || location.startsWith('/sales') || widget.navigationShell.currentIndex == 1)
                            ? theme.colorScheme.primary
                            : theme.iconTheme.color,
                      ),
                      title: Text(
                        'Sales',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (location.startsWith('/invoices') || location.startsWith('/sales') || widget.navigationShell.currentIndex == 1)
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                      initiallyExpanded: location.startsWith('/invoices') || location.startsWith('/sales') || widget.navigationShell.currentIndex == 1,
                      childrenPadding: const EdgeInsets.only(left: 12.0),
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
                          leading: const Icon(Icons.receipt_long_rounded, size: 20),
                          title: const Text('Invoices', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          selected: location.startsWith('/invoices') || widget.navigationShell.currentIndex == 1,
                          selectedColor: theme.colorScheme.primary,
                          selectedTileColor: theme.colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onTap: () {
                            Navigator.pop(context);
                            _onTap(context, 1);
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
                          leading: const Icon(Icons.request_quote_rounded, size: 20),
                          title: const Text('Quotations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          selected: location.startsWith('/sales/quotations'),
                          selectedColor: theme.colorScheme.primary,
                          selectedTileColor: theme.colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/sales/quotations');
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
                          leading: const Icon(Icons.assignment_return_rounded, size: 20),
                          title: const Text('Credit Notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          selected: location.startsWith('/sales/credit-notes'),
                          selectedColor: theme.colorScheme.primary,
                          selectedTileColor: theme.colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/sales/credit-notes');
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
                          leading: const Icon(Icons.description_rounded, size: 20),
                          title: const Text('Proforma Invoices', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          selected: location.startsWith('/sales/proforma-invoices'),
                          selectedColor: theme.colorScheme.primary,
                          selectedTileColor: theme.colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/sales/proforma-invoices');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 5. Purchases (Expandable)
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      leading: Icon(
                        Icons.shopping_bag_rounded,
                        color: location.startsWith('/purchases')
                            ? theme.colorScheme.primary
                            : theme.iconTheme.color,
                      ),
                      title: Text(
                        'Purchases',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: location.startsWith('/purchases')
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                      initiallyExpanded: location.startsWith('/purchases'),
                      childrenPadding: const EdgeInsets.only(left: 12.0),
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
                          leading: const Icon(Icons.storefront_rounded, size: 20),
                          title: const Text('Vendors', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          selected: location.startsWith('/purchases/vendors'),
                          selectedColor: theme.colorScheme.primary,
                          selectedTileColor: theme.colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/purchases/vendors');
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
                          leading: const Icon(Icons.assignment_rounded, size: 20),
                          title: const Text('Purchase Orders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          selected: location.startsWith('/purchases/purchase-orders'),
                          selectedColor: theme.colorScheme.primary,
                          selectedTileColor: theme.colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/purchases/purchase-orders');
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
                          leading: const Icon(Icons.receipt_rounded, size: 20),
                          title: const Text('Bills', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          selected: location.startsWith('/purchases/bills'),
                          selectedColor: theme.colorScheme.primary,
                          selectedTileColor: theme.colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/purchases/bills');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 6. Expenses
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded),
                    title: const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: location.startsWith('/expenses') || widget.navigationShell.currentIndex == 4,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      _onTap(context, 4);
                    },
                  ),
                  const SizedBox(height: 4),

                  // 7. Payments
                  ListTile(
                    leading: const Icon(Icons.payments_rounded),
                    title: const Text('Payments', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: location.startsWith('/payments'),
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/payments');
                    },
                  ),
                  const SizedBox(height: 4),

                  // 8. Reports
                  ListTile(
                    leading: const Icon(Icons.bar_chart_rounded),
                    title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: location.startsWith('/reports'),
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/reports');
                    },
                  ),
                  const SizedBox(height: 4),

                  // 9. Settings
                  ListTile(
                    leading: const Icon(Icons.settings_rounded),
                    title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: location.startsWith('/settings') || widget.navigationShell.currentIndex == 5,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      _onTap(context, 5);
                    },
                  ),
                ],
              ),
            ),

            // Drawer Footer: Help & Support & Logout
            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: ListTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/help');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => ConfirmationDialog(
                      title: 'Log Out',
                      content: 'Are you sure you want to log out of Prabhim One?',
                      confirmLabel: 'Log Out',
                      onConfirm: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          context.go('/welcome');
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? theme.colorScheme.outline : Colors.grey.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: bottomNavIndex,
            onTap: (index) => _onBottomNavTap(context, index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Sales',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined),
                activeIcon: Icon(Icons.shopping_bag_rounded),
                label: 'Purchases',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Expenses',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view_rounded),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
