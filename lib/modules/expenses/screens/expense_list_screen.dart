import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../../../core/widgets/custom_states.dart';
import '../../../features/authentication/providers/auth_provider.dart';
import '../../../features/invoices/widgets/statistics_card.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';
import '../../../features/navigation/navigation_shell.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().refreshAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<ExpenseProvider>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (provider.hasMore && !provider.isLoading && !provider.isMoreLoading) {
        provider.fetchExpenses();
      }
    }
  }

  Future<void> _handleRefresh() async {
    await context.read<ExpenseProvider>().refreshAll();
  }

  void _showSortSheet(BuildContext context, ExpenseProvider provider) {
    showCustomBottomSheet(
      context: context,
      title: 'Sort Expenses',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSortOption(
            context,
            title: 'Expense Date: Newest First',
            value: 'date_desc',
            selectedValue: provider.ordering,
            onTap: () {
              provider.setSortBy('date_desc');
              Navigator.pop(context);
            },
          ),
          _buildSortOption(
            context,
            title: 'Expense Date: Oldest First',
            value: 'date_asc',
            selectedValue: provider.ordering,
            onTap: () {
              provider.setSortBy('date_asc');
              Navigator.pop(context);
            },
          ),
          _buildSortOption(
            context,
            title: 'Amount: High to Low',
            value: 'amount_desc',
            selectedValue: provider.ordering,
            onTap: () {
              provider.setSortBy('amount_desc');
              Navigator.pop(context);
            },
          ),
          _buildSortOption(
            context,
            title: 'Amount: Low to High',
            value: 'amount_asc',
            selectedValue: provider.ordering,
            onTap: () {
              provider.setSortBy('amount_asc');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required String title,
    required String value,
    required String selectedValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selectedValue ||
        (value == 'date_desc' && selectedValue == 'newest') ||
        (value == 'date_asc' && selectedValue == 'oldest') ||
        (value == 'amount_desc' && selectedValue == 'highest_amount') ||
        (value == 'amount_asc' && selectedValue == 'lowest_amount');
    final theme = Theme.of(context);

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  void _showExpenseDetailsSheet(BuildContext context, ExpenseModel expense) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.displayIdentifier,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expense.category,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      currencyFormat.format(expense.totalAmount),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Details Grid
                _buildDetailRow(context, 'Vendor / Customer', expense.vendor),
                _buildDetailRow(context, 'Date', dateFormat.format(expense.expenseDate)),
                _buildDetailRow(context, 'Payment Mode', expense.paymentMode),
                _buildDetailRow(context, 'Payment Status', expense.status),
                _buildDetailRow(context, 'Billable', expense.billable ? 'Yes (Billable to client)' : 'No'),
                _buildDetailRow(context, 'Base Amount', currencyFormat.format(expense.amount)),
                if (expense.gstAmount > 0)
                  _buildDetailRow(context, 'GST Rate & Amount', '${expense.gstRate} (${currencyFormat.format(expense.gstAmount)})'),
                if (expense.billNumber != null && expense.billNumber!.isNotEmpty)
                  _buildDetailRow(context, 'Reference / Bill #', expense.billNumber!),
                if (expense.notes != null && expense.notes!.isNotEmpty)
                  _buildDetailRow(context, 'Notes / Remarks', expense.notes!),
                if (expense.invoiceFileName != null && expense.invoiceFileName!.isNotEmpty)
                  _buildDetailRow(
                    context,
                    'Attachment',
                    expense.invoiceFileName!,
                    trailingIcon: Icons.attach_file_rounded,
                  ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Expense'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/expenses/edit', extra: expense);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Delete'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteExpense(context, expense);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {IconData? trailingIcon}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingIcon != null) ...[
                  Icon(trailingIcon, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExpense(BuildContext context, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to permanently delete expense ${expense.id} (${expense.category})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final provider = context.read<ExpenseProvider>();
              final success = await provider.deleteExpense(expense.id);
              if (!mounted) return;
              if (success) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Expense ${expense.displayIdentifier} deleted.'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'UNDO',
                      textColor: Colors.white,
                      onPressed: () async {
                        await provider.restoreExpense(expense.id);
                      },
                    ),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Failed to delete expense'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final expenses = expenseProvider.filteredExpenses;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
    final initials = userName.trim().split(' ').map((l) => l.isNotEmpty ? l[0] : '').take(2).join().toUpperCase();

    final double totalExpenses = expenseProvider.calculatedTotalExpenses;
    final double thisMonth = expenseProvider.calculatedThisMonthExpenses;
    final double gstCredit = expenseProvider.calculatedGstCredit;
    final double pendingPayments = expenseProvider.calculatedPendingPayments;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search expense, vendor, or category...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (val) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    expenseProvider.setSearchQuery(val);
                  });
                },
              )
            : const Text('Expenses'),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {
            NavigationShell.openDrawer(context);
          },
        ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  expenseProvider.setSearchQuery('');
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () => _showSortSheet(context, expenseProvider),
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
          CustomAvatar(
            name: initials,
            imageUrl: authProvider.currentUserProfileImage ?? authProvider.currentUserAvatar,
            radius: 16,
            onTap: () => context.push('/profile'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/expenses/create');
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Expense', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildFilterChips(expenseProvider),

          Expanded(
            child: expenseProvider.isLoading && expenses.isEmpty
                ? _buildSkeletonLoader(theme, isDark)
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        _buildStatisticsSection(
                          currencyFormat: currencyFormat,
                          totalExpenses: totalExpenses,
                          thisMonth: thisMonth,
                          gstCredit: gstCredit,
                          pendingPayments: pendingPayments,
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ALL EXPENSES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Colors.grey,
                                ),
                              ),
                              if (expenses.isNotEmpty)
                                Text(
                                  '${expenses.length} records',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        if (expenses.isEmpty)
                          _buildEmptyState(theme, isDark, expenseProvider)
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: expenses.length,
                              itemBuilder: (context, index) {
                                final expense = expenses[index];
                                return ExpenseCard(
                                  expense: expense,
                                  onTap: () => _showExpenseDetailsSheet(context, expense),
                                  onEdit: () => context.push('/expenses/edit', extra: expense),
                                  onDelete: () => _confirmDeleteExpense(context, expense),
                                );
                              },
                            ),
                          ),

                        if (expenseProvider.isMoreLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ExpenseProvider provider) {
    final statuses = ['All', 'Paid', 'Pending', 'Cancelled'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final currentFilter = provider.statusFilter ?? 'All';
          final isSelected = currentFilter.toLowerCase() == status.toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  provider.setStatusFilter(status);
                }
              },
              selectedColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.5)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 1.2,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsSection({
    required NumberFormat currencyFormat,
    required double totalExpenses,
    required double thisMonth,
    required double gstCredit,
    required double pendingPayments,
  }) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          StatisticsCard(
            title: 'Total Expenses',
            value: currencyFormat.format(totalExpenses),
            subtitle: 'All recorded expenditures',
            icon: Icons.account_balance_wallet_rounded,
            gradientColors: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
          ),
          StatisticsCard(
            title: 'This Month',
            value: currencyFormat.format(thisMonth),
            subtitle: 'Current billing cycle',
            icon: Icons.calendar_month_rounded,
            gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
          ),
          StatisticsCard(
            title: 'GST Input Credit',
            value: currencyFormat.format(gstCredit),
            subtitle: 'Eligible tax claim',
            icon: Icons.receipt_long_rounded,
            gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B)],
          ),
          StatisticsCard(
            title: 'Pending Payments',
            value: currencyFormat.format(pendingPayments),
            subtitle: 'Unsettled vendor amounts',
            icon: Icons.pending_actions_rounded,
            gradientColors: const [Color(0xFFDC2626), Color(0xFFEF4444)],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark, ExpenseProvider expenseProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No Expenses Found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            expenseProvider.searchQuery.isNotEmpty || (expenseProvider.statusFilter != null && expenseProvider.statusFilter != 'All')
                ? 'Try clearing your filters or search query to view all expenses.'
                : 'Keep your accounts up to date. Record and track all business expenditures in one place.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              context.push('/expenses/create');
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(ThemeData theme, bool isDark) {
    final placeholderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: placeholderColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 16,
            width: 120,
            decoration: BoxDecoration(
              color: placeholderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (_, _) => Container(
                height: 76,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: placeholderColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
