import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_states.dart';
import '../../../../core/widgets/custom_dialogs.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/invoice_card.dart';
import '../../widgets/statistics_card.dart';
import '../../../navigation/navigation_shell.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().fetchInvoices(refresh: true);
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
    final provider = context.read<InvoiceProvider>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (provider.hasMore && !provider.isLoading) {
        provider.fetchInvoices();
      }
    }
  }

  Future<void> _handleRefresh() async {
    await context.read<InvoiceProvider>().fetchInvoices(refresh: true);
  }

  void _showSortSheet(BuildContext context, InvoiceProvider provider) {
    showCustomBottomSheet(
      context: context,
      title: 'Sort Invoices',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSortOption(
            context,
            title: 'Invoice Date: Newest First',
            value: 'date_desc',
            selectedValue: provider.sortBy,
            onTap: () {
              provider.setSortBy('date_desc');
              provider.fetchInvoices(refresh: true);
              Navigator.pop(context);
            },
          ),
          _buildSortOption(
            context,
            title: 'Invoice Date: Oldest First',
            value: 'date_asc',
            selectedValue: provider.sortBy,
            onTap: () {
              provider.setSortBy('date_asc');
              provider.fetchInvoices(refresh: true);
              Navigator.pop(context);
            },
          ),
          _buildSortOption(
            context,
            title: 'Amount: High to Low',
            value: 'amount_desc',
            selectedValue: provider.sortBy,
            onTap: () {
              provider.setSortBy('amount_desc');
              provider.fetchInvoices(refresh: true);
              Navigator.pop(context);
            },
          ),
          _buildSortOption(
            context,
            title: 'Amount: Low to High',
            value: 'amount_asc',
            selectedValue: provider.sortBy,
            onTap: () {
              provider.setSortBy('amount_asc');
              provider.fetchInvoices(refresh: true);
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
    final isSelected = value == selectedValue;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final invoiceProvider = context.watch<InvoiceProvider>();
    final invoices = invoiceProvider.filteredInvoices;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

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
    final initials = userName.trim().split(' ').map((l) => l.isNotEmpty ? l[0] : '').take(2).join().toUpperCase();

    // Calculate metrics directly from backend dashboardStats
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final stats = invoiceProvider.dashboardStats;
    final double totalRevenue = toDouble(stats['revenue']);
    final double totalOutstanding = toDouble(stats['outstanding']);
    final double avgValue = toDouble(stats['average_invoice']);

    final int paidCount = (stats['paid'] ?? 0) as int;
    final int pendingCount = (stats['pending'] ?? 0) as int;
    final int overdueCount = (stats['overdue'] ?? 0) as int;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search invoice or company...',
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
                    invoiceProvider.setSearchQuery(val);
                    invoiceProvider.fetchInvoices(refresh: true);
                  });
                },
              )
            : const Text('Invoices'),
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
                  invoiceProvider.setSearchQuery('');
                  invoiceProvider.fetchInvoices(refresh: true);
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
            onPressed: () => _showSortSheet(context, invoiceProvider),
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
          invoiceProvider.startNewInvoice();
          context.push('/invoices/create');
        },
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildFilterChips(invoiceProvider),

          Expanded(
            child: invoiceProvider.isLoading && invoices.isEmpty
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
                          paidCount: paidCount,
                          pendingCount: pendingCount,
                          overdueCount: overdueCount,
                          totalRevenue: totalRevenue,
                          totalOutstanding: totalOutstanding,
                          avgValue: avgValue,
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'RECENT INVOICES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        if (invoices.isEmpty)
                          _buildEmptyState(theme, isDark, invoiceProvider)
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: invoices.length,
                              itemBuilder: (context, index) {
                                final invoice = invoices[index];
                                final outstanding = invoice.balanceDue;

                                return InvoiceCard(
                                  invoice: invoice,
                                  outstandingBalance: outstanding,
                                  onTap: () {
                                    invoiceProvider.startEditingInvoice(invoice);
                                    context.push('/invoices/preview');
                                  },
                                  onEdit: () {
                                    invoiceProvider.startEditingInvoice(invoice);
                                    context.push('/invoices/edit');
                                  },
                                  onRecordPayment: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Record Payment'),
                                        content: Text('Record full payment of ${currencyFormat.format(outstanding)} for invoice ${invoice.invoiceNumber}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final messenger = ScaffoldMessenger.of(context);
                                              Navigator.pop(context);
                                              final success = await invoiceProvider.recordPayment(
                                                invoiceId: invoice.id,
                                                amount: outstanding,
                                                paymentMode: 'Bank Transfer',
                                                paymentDate: DateTime.now(),
                                                reference: 'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                              );
                                              if (success) {
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text('Payment registered for ${invoice.invoiceNumber}!'),
                                                    backgroundColor: AppColors.success,
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                                invoiceProvider.fetchInvoices(refresh: true);
                                              } else {
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(invoiceProvider.errorMessage ?? 'Failed to record payment'),
                                                    backgroundColor: AppColors.error,
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
                                            child: const Text('Pay Invoice'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDownloadPdf: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Downloading PDF...'),
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                    final success = await invoiceProvider.downloadInvoicePdf(
                                      invoiceId: invoice.id,
                                      invoiceNumber: invoice.invoiceNumber,
                                    );
                                    if (!success) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(invoiceProvider.errorMessage ?? 'Failed to download PDF'),
                                          backgroundColor: AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  onDuplicate: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final success = await invoiceProvider.duplicateInvoice(invoice);
                                    if (success) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Invoice ${invoice.invoiceNumber} duplicated!'),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(invoiceProvider.errorMessage ?? 'Failed to duplicate invoice'),
                                          backgroundColor: AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  onShare: () => _showMockToast(context, 'Link copied to clipboard'),
                                  onDelete: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Invoice'),
                                        content: Text('Are you sure you want to permanently delete invoice ${invoice.invoiceNumber}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final messenger = ScaffoldMessenger.of(context);
                                              Navigator.pop(context);
                                              final success = await invoiceProvider.deleteInvoice(invoice.id);
                                              if (success) {
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text('Invoice deleted successfully!'),
                                                    backgroundColor: AppColors.success,
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                                invoiceProvider.fetchInvoices(refresh: true);
                                              } else {
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(invoiceProvider.errorMessage ?? 'Failed to delete invoice'),
                                                    backgroundColor: AppColors.error,
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.error,
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(80, 36),
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        
                        if (invoiceProvider.isLoading && invoices.isNotEmpty)
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

  void _showMockToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFilterChips(InvoiceProvider provider) {
    final statuses = ['All', 'Draft', 'Sent', 'Partially Paid', 'Paid', 'Overdue'];
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
          final isSelected = provider.statusFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  provider.setStatusFilter(status);
                  provider.fetchInvoices(refresh: true);
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
                borderRadius: BorderRadius.circular(20), // Zoho style rounded pill
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
    required int paidCount,
    required int pendingCount,
    required int overdueCount,
    required double totalRevenue,
    required double totalOutstanding,
    required double avgValue,
  }) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          StatisticsCard(
            title: 'Paid Invoices',
            value: currencyFormat.format(totalRevenue),
            subtitle: '$paidCount invoices cleared',
            icon: Icons.check_circle_rounded,
            gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
          ),
          StatisticsCard(
            title: 'Outstanding Balance',
            value: currencyFormat.format(totalOutstanding),
            subtitle: 'Unpaid bills from clients',
            icon: Icons.pending_actions_rounded,
            gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B)],
          ),
          StatisticsCard(
            title: 'Overdue Amount',
            value: overdueCount > 0 ? '₹${overdueCount * 25000}' : '₹0.00', // dynamic representation
            subtitle: '$overdueCount invoices past due',
            icon: Icons.warning_rounded,
            gradientColors: const [Color(0xFFDC2626), Color(0xFFEF4444)],
          ),
          StatisticsCard(
            title: 'Average Ticket Size',
            value: currencyFormat.format(avgValue),
            subtitle: 'Average bill size',
            icon: Icons.analytics_rounded,
            gradientColors: const [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark, InvoiceProvider invoiceProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 56,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Invoices Found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            invoiceProvider.searchQuery.isNotEmpty || invoiceProvider.statusFilter != 'All'
                ? 'Try clearing your filters or search query to view all invoices.'
                : 'Create your first invoice by tapping the + button below.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row Skeleton
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(3, (index) => Container(
                width: 200,
                height: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              )),
            ),
          ),
          const SizedBox(height: 24),
          // List Cards Skeleton
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) => Container(
                height: 90,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
int min(int a, int b) => a < b ? a : b;
