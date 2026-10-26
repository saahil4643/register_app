import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_states.dart';
import '../../invoices/providers/invoice_provider.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import 'customer_detail_screen.dart';
import 'create_customer_screen.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  String _searchQuery = '';
  String _activeFilter = 'All'; // 'All', 'Active', 'Inactive', 'Outstanding Due', 'Recently Added'
  String _sortBy = 'Alphabetical'; // 'Alphabetical', 'Outstanding', 'Recently Added'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<InvoiceProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // 1. Filter customers
    final filteredCustomers = customerProvider.customers.where((customer) {
      // Search
      final nameMatch = customer.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final companyMatch = customer.company.toLowerCase().contains(_searchQuery.toLowerCase());
      final phoneMatch = customer.phone.contains(_searchQuery);
      final emailMatch = customer.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final gstMatch = customer.gstNo.toLowerCase().contains(_searchQuery.toLowerCase());
      final searchMatch = nameMatch || companyMatch || phoneMatch || emailMatch || gstMatch;

      if (!searchMatch) return false;

      // Filter types
      final outstanding = provider.getOutstandingForCustomer(customer.id);
      final totalOrders = provider.getTotalOrdersForCustomer(customer.id);

      switch (_activeFilter) {
        case 'Active':
          return totalOrders > 0;
        case 'Inactive':
          return totalOrders == 0;
        case 'Outstanding Due':
          return outstanding > 0;
        case 'Recently Added':
          return customer.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 90)));
        default:
          return true;
      }
    }).toList();

    // 2. Sort customers
    filteredCustomers.sort((a, b) {
      switch (_sortBy) {
        case 'Outstanding':
          final outA = provider.getOutstandingForCustomer(a.id);
          final outB = provider.getOutstandingForCustomer(b.id);
          return outB.compareTo(outA);
        case 'Recently Added':
          return b.createdAt.compareTo(a.createdAt);
        case 'Alphabetical':
        default:
          final nameA = a.company.isNotEmpty ? a.company : a.name;
          final nameB = b.company.isNotEmpty ? b.company : b.name;
          return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Customer Directory',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Customers',
            onPressed: _showSortBottomSheet,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE5E7EB), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Search & Filter header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search customer, company, phone, GSTIN...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filter Chips
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip('All'),
                            _buildFilterChip('Active'),
                            _buildFilterChip('Inactive'),
                            _buildFilterChip('Outstanding Due'),
                            _buildFilterChip('Recently Added'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Count & Sorting Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredCustomers.length} ${filteredCustomers.length == 1 ? 'client' : 'clients'} found',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                      InkWell(
                        onTap: _showSortBottomSheet,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          child: Row(
                            children: [
                              Icon(Icons.sort_rounded, size: 14, color: AppColors.lightPrimary),
                              const SizedBox(width: 4),
                              Text(
                                'Sort: $_sortBy',
                                style: TextStyle(
                                  color: AppColors.lightPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Customers List
                Expanded(
                  child: customerProvider.isLoading && customerProvider.customers.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => customerProvider.fetchCustomers(refresh: true),
                          child: filteredCustomers.isEmpty
                              ? EmptyState(
                                  title: 'No Customers Found',
                                  description: 'Try adjusting your search filters or add a new customer to get started.',
                                  icon: Icons.people_outline_rounded,
                                  actionLabel: 'Add New Customer',
                                  onActionPressed: () => _navigateToAddCustomer(context),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 80.0),
                                  itemCount: filteredCustomers.length,
                                  itemBuilder: (context, index) {
                                    final customer = filteredCustomers[index];
                                    final outstanding = provider.getOutstandingForCustomer(customer.id);
                                    final lastPurchase = provider.getLastPurchaseDateForCustomer(customer.id);
                                    final hasOrders = provider.getTotalOrdersForCustomer(customer.id) > 0;

                                    return _buildCustomerCard(
                                      context,
                                      customer,
                                      outstanding,
                                      lastPurchase,
                                      hasOrders,
                                      currencyFormat,
                                      isDark,
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: filteredCustomers.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _navigateToAddCustomer(context),
              backgroundColor: AppColors.lightPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('New Customer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    Customer customer,
    double outstanding,
    DateTime? lastPurchase,
    bool hasOrders,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    final displayName = customer.company.isNotEmpty ? customer.company : customer.name;
    final initials = (customer.company.isNotEmpty
            ? customer.company.substring(0, 1)
            : (customer.name.isNotEmpty ? customer.name.substring(0, 1) : 'C'))
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailScreen(customerId: customer.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: isDark ? const Color(0xFF312E81) : const Color(0xFFEDE9FE),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: AppColors.lightPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Customer Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: hasOrders
                                ? const Color(0xFFD1FAE5) // light green
                                : const Color(0xFFF1F5F9), // light gray
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hasOrders ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: hasOrders ? AppColors.success : const Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      customer.company.isNotEmpty && customer.name.isNotEmpty && customer.name != customer.company
                          ? '${customer.name} • ${customer.phone}'
                          : customer.phone.isNotEmpty
                              ? customer.phone
                              : (customer.email.isNotEmpty ? customer.email : 'No contact info'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (customer.gstNo.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'GST: ${customer.gstNo}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          lastPurchase != null
                              ? 'Last: ${DateFormat('dd MMM yyyy').format(lastPurchase)}'
                              : 'No invoices yet',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Outstanding Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(outstanding),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: outstanding > 0 ? AppColors.error : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Outstanding',
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _activeFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _activeFilter = label);
          }
        },
        selectedColor: theme.colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
            width: 1,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Future<void> _navigateToAddCustomer(BuildContext parentContext) async {
    final navigator = Navigator.of(parentContext);
    await navigator.push(
      MaterialPageRoute(
        builder: (context) => const CreateCustomerScreen(),
      ),
    );
    if (!mounted) return;
    context.read<CustomerProvider>().fetchCustomers(refresh: true);
  }

  void _showSortBottomSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sort Customers By',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSortOption(bottomSheetContext, 'Alphabetical', Icons.sort_by_alpha_rounded),
                _buildSortOption(bottomSheetContext, 'Outstanding', Icons.account_balance_wallet_rounded),
                _buildSortOption(bottomSheetContext, 'Recently Added', Icons.access_time_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext ctx, String label, IconData icon) {
    final isSelected = _sortBy == label;
    final theme = Theme.of(ctx);

    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_rounded, color: theme.colorScheme.primary) : null,
      onTap: () {
        setState(() {
          _sortBy = label;
        });
        Navigator.pop(ctx);
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}
