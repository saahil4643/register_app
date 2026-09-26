import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_form.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_states.dart';
import '../../../features/authentication/providers/auth_provider.dart';
import '../../../features/settings/providers/settings_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Filtering and Searching State
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  // State for form focus
  ExpenseModel? _editingExpense;
  final GlobalKey _formCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ExpenseProvider>();
      if (provider.hasMore && !provider.isMoreLoading && !provider.isLoading) {
        provider.fetchExpenses(reset: false);
      }
    }
  }

  void _scrollToForm() {
    Scrollable.ensureVisible(
      _formCardKey.currentContext ?? context,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _startEditing(ExpenseModel expense) {
    setState(() {
      _editingExpense = expense;
    });
    // On mobile, show the bottom sheet. On desktop, scroll to the form.
    final width = MediaQuery.of(context).size.width;
    if (width < AppDimensions.tabletBreakpoint) {
      _showFormBottomSheet(expense: expense);
    } else {
      _scrollToForm();
    }
  }

  void _showFormBottomSheet({ExpenseModel? expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: ExpenseForm(
              initialExpense: expense,
              onCancel: () => Navigator.pop(context),
              onSaveSuccess: () {
                Navigator.pop(context);
                setState(() {
                  _editingExpense = null;
                });
              },
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AppDimensions.tabletBreakpoint;

    // User details for Drawer
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
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      // Left Hamburger Drawer Menu
      drawer: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
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
                  CustomAvatar(name: userName, radius: 28),
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard_rounded),
                    title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/dashboard');
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_rounded),
                    title: const Text('Invoices', style: TextStyle(fontWeight: FontWeight.bold)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/invoices');
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.lightPrimary),
                    title: const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightPrimary)),
                    tileColor: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.people_rounded),
                    title: const Text('Customers', style: TextStyle(fontWeight: FontWeight.bold)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/customers');
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_rounded),
                    title: const Text('Products & Services', style: TextStyle(fontWeight: FontWeight.bold)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/products');
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
                    leading: const Icon(Icons.settings_rounded),
                    title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/settings');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // AppBar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            // Company Logo Placeholder
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business_rounded, color: Colors.white, size: 18),
            ),
            AppSpacing.widthS,
            Text(
              'PrabhimOne',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showSearchFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Refresh List'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'refresh') {
                provider.fetchExpenses();
              } else if (value == 'export') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV Export started (mock)')),
                );
              }
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.refreshAll,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Header Title
                    Text(
                      'Expense Management',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor, track, and record business expenses in real time.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ).animate().fadeIn(duration: 450.ms).slideX(begin: -0.1),
                    AppSpacing.heightL,

                    // Dashboard Summary Cards
                    _buildDashboardSection(provider, isDark),
                    AppSpacing.heightXl,

                    // Responsive columns split
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side Form
                          Expanded(
                            key: _formCardKey,
                            flex: 6,
                            child: ExpenseForm(
                              initialExpense: _editingExpense,
                              onCancel: () {
                                setState(() {
                                  _editingExpense = null;
                                });
                              },
                              onSaveSuccess: () {
                                setState(() {
                                  _editingExpense = null;
                                });
                              },
                            ),
                          ),
                          AppSpacing.widthXl,
                          // Right side List
                          Expanded(
                            flex: 4,
                            child: _buildRecentExpensesSection(provider),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms)
                    else ...[
                      // Stacked Mobile View
                      _buildRecentExpensesSection(provider).animate().fadeIn(duration: 500.ms),
                      AppSpacing.heightXl,
                      Container(
                        key: _formCardKey,
                        child: ExpenseForm(
                          initialExpense: _editingExpense,
                          onCancel: () {
                            setState(() {
                              _editingExpense = null;
                            });
                          },
                          onSaveSuccess: () {
                            setState(() {
                              _editingExpense = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      // Floating Action Button
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (isDesktop) {
              _scrollToForm();
            } else {
              _showFormBottomSheet();
            }
          },
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'Add Expense',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
    );
  }

  // Dashboard Row (scrollable on smaller devices, grids on large)
  Widget _buildDashboardSection(ExpenseProvider provider, bool isDark) {
    final List<Widget> cards = [
      DashboardCard(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Total Expenses',
        amount: provider.totalExpenses,
        subtitle: 'All completed bookings',
        tintColor: AppColors.lightPrimary,
      ),
      DashboardCard(
        icon: Icons.receipt_long_rounded,
        title: 'GST Input Credit',
        amount: provider.gstInputCredit,
        subtitle: 'Accumulated tax refund',
        tintColor: AppColors.success,
        backgroundColor: isDark ? null : const Color(0xFFD1FAE5),
      ),
      DashboardCard(
        icon: Icons.today_rounded,
        title: 'This Month',
        amount: provider.thisMonthExpenses,
        subtitle: 'Current billing cycle',
        tintColor: AppColors.info,
        backgroundColor: isDark ? null : const Color(0xFFEFF6FF),
      ),
      DashboardCard(
        icon: Icons.hourglass_empty_rounded,
        title: 'Pending Payments',
        amount: provider.pendingPayments,
        subtitle: 'Unpaid vendor invoices',
        tintColor: AppColors.warning,
        backgroundColor: isDark ? null : const Color(0xFFFEF3C7),
      ),
    ];

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (context, index) => AppSpacing.widthL,
        itemBuilder: (context, index) => cards[index]
            .animate()
            .fadeIn(delay: (index * 100).ms, duration: 400.ms)
            .scale(begin: const Offset(0.9, 0.9)),
      ),
    );
  }

  // Recent Expenses Section
  Widget _buildRecentExpensesSection(ExpenseProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Expenses',
          actionLabel: 'View All',
          onActionPressed: () => _showFilterOptionsBottomSheet(),
        ),
        // Active Filter Chips indicator if filters are active
        if (_searchQuery.isNotEmpty || _selectedStatusFilter != 'All')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text('Search: "$_searchQuery"', style: const TextStyle(fontSize: 11)),
                      onDeleted: () {
                        setState(() => _searchQuery = '');
                        provider.setFilters(search: '');
                      },
                    ),
                  ),
                if (_selectedStatusFilter != 'All')
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text('Status: $_selectedStatusFilter', style: const TextStyle(fontSize: 11)),
                      onDeleted: () {
                        setState(() => _selectedStatusFilter = 'All');
                        provider.setFilters(status: '');
                      },
                    ),
                  ),
              ],
            ),
          ),
        
        // List Card Items
        provider.expenses.isEmpty
            ? EmptyState(
                title: 'No Expenses Found',
                description: 'Record an expense or change filter preferences.',
                icon: Icons.receipt_long_rounded,
                actionLabel: 'Reset Filters',
                onActionPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedStatusFilter = 'All';
                  });
                  provider.clearFilters();
                },
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.expenses.length + (provider.isMoreLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == provider.expenses.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final expense = provider.expenses[index];
                  return ExpenseCard(
                    expense: expense,
                    onTap: () => _startEditing(expense),
                    onEdit: () => _startEditing(expense),
                    onDelete: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Expense'),
                          content: Text('Are you sure you want to delete this expense for ${expense.vendor}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: AppColors.error),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final success = await provider.deleteExpense(expense.id);
                        if (success) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Expense deleted successfully.')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
      ],
    );
  }

  // Filter Bottom Sheet
  void _showFilterOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          final provider = context.read<ExpenseProvider>();
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                AppSpacing.heightM,
                const Text('Status Filter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                AppSpacing.heightS,
                Wrap(
                  spacing: 10,
                  children: ['All', 'Paid', 'Pending', 'Cancelled'].map((status) {
                    final selected = _selectedStatusFilter == status;
                    return ChoiceChip(
                      label: Text(status),
                      selected: selected,
                      onSelected: (val) {
                        if (val) {
                          setSheetState(() => _selectedStatusFilter = status);
                          setState(() => _selectedStatusFilter = status);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatusFilter = 'All';
                        });
                        provider.setFilters(status: '');
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        provider.setFilters(
                          status: _selectedStatusFilter == 'All' ? '' : _selectedStatusFilter,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // Search dialog
  void _showSearchFilterDialog() {
    final controller = TextEditingController(text: _searchQuery);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Expenses'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by category, vendor, bill #...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final query = controller.text.trim();
                setState(() {
                  _searchQuery = query;
                });
                context.read<ExpenseProvider>().setFilters(search: query);
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
}
