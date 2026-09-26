import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_states.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../authentication/providers/auth_provider.dart';
import '../invoices/providers/invoice_provider.dart';
import '../customers/screens/create_customer_screen.dart';
import '../products/screens/create_product_screen.dart';
import '../settings/providers/settings_provider.dart';

class NavigationShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

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

  void _showQuickCreate(BuildContext context) {
    showCustomBottomSheet(
      context: context,
      title: 'Quick Actions',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
              child: const Icon(Icons.add_chart_rounded, color: AppColors.success, size: 20),
            ),
            title: const Text('Create Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Generate a new invoice'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              Navigator.pop(context);
              context.read<InvoiceProvider>().startNewInvoice();
              context.push('/invoices/create');
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
              child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.info, size: 20),
            ),
            title: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Register a new client'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateCustomerScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
              child: const Icon(Icons.add_box_rounded, color: AppColors.warning, size: 20),
            ),
            title: const Text('Add Product & Service', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Insert an item in inventory'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateProductScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFF5F3FF), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.lightPrimary, size: 20),
            ),
            title: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Record business transaction expenses'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              Navigator.pop(context);
              context.push('/expenses');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    
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
    final companyName = settingsProvider.companySettings?.companyName ?? 'Prabhim One';

    return Scaffold(
      drawer: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            // Custom Premium Drawer Header
            Container(
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
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard_rounded),
                    title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: widget.navigationShell.currentIndex == 0,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      _onTap(context, 0);
                    },
                  ),
                  const SizedBox(height: 4),
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Icon(
                        Icons.monetization_on_rounded,
                        color: widget.navigationShell.currentIndex == 1
                            ? theme.colorScheme.primary
                            : theme.iconTheme.color,
                      ),
                      title: Text(
                        'Sales',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.navigationShell.currentIndex == 1
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                      initiallyExpanded: widget.navigationShell.currentIndex == 1,
                      childrenPadding: const EdgeInsets.only(left: 12.0),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.receipt_long_rounded),
                          title: const Text('Invoices', style: TextStyle(fontWeight: FontWeight.bold)),
                          selected: widget.navigationShell.currentIndex == 1,
                          selectedColor: theme.colorScheme.primary,
                          selectedTileColor: theme.colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: () {
                            Navigator.pop(context);
                            _onTap(context, 1);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.people_rounded),
                    title: const Text('Customers', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: widget.navigationShell.currentIndex == 2,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      _onTap(context, 2);
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_rounded),
                    title: const Text('Products & Services', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: widget.navigationShell.currentIndex == 3,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      _onTap(context, 3);
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded),
                    title: const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: widget.navigationShell.currentIndex == 4,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      _onTap(context, 4);
                    },
                  ),
                  const SizedBox(height: 8),
                  Divider(color: theme.colorScheme.outline.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.bar_chart_rounded),
                    title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/reports');
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded),
                    title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/help');
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.settings_rounded),
                    title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: widget.navigationShell.currentIndex == 5,
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

            // Logout Footer
            Divider(color: theme.colorScheme.outline.withOpacity(0.5)),
            Padding(
              padding: const EdgeInsets.all(12.0),
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
            const SizedBox(height: 12),
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
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? theme.colorScheme.outline : Colors.grey.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: widget.navigationShell.currentIndex,
            onTap: (index) => _onTap(context, index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Invoices',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline_rounded),
                activeIcon: Icon(Icons.people_rounded),
                label: 'Clients',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                activeIcon: Icon(Icons.inventory_2_rounded),
                label: 'Inventory',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Expenses',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: (widget.navigationShell.currentIndex == 1 || widget.navigationShell.currentIndex == 4)
          ? null
          : Container(
              height: 56,
              width: 56,
              margin: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton(
                onPressed: () => _showQuickCreate(context),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            ),
    );
  }
}
