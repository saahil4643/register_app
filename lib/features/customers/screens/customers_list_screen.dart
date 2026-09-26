import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_cards.dart';
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
      final searchMatch = nameMatch || companyMatch || phoneMatch;

      if (!searchMatch) return false;

      // Filter types
      final outstanding = provider.getOutstandingForCustomer(customer.id);
      final totalOrders = provider.getTotalOrdersForCustomer(customer.id);

      switch (_activeFilter) {
        case 'Active':
          // Active if has at least 1 order
          return totalOrders > 0;
        case 'Inactive':
          return totalOrders == 0;
        case 'Outstanding Due':
          return outstanding > 0;
        case 'Recently Added':
          // Within last 90 days
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
          return a.company.toLowerCase().compareTo(b.company.toLowerCase());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _navigateToAddCustomer(context),
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: _showSortBottomSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      hintText: 'Search customer name, company, phone...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
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
                    height: 38,
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
            
            // List Count & Sorting Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${filteredCustomers.length} clients',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Sorted: $_sortBy',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Customers List
            Expanded(
              child: customerProvider.isLoading && customerProvider.customers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => customerProvider.fetchCustomers(refresh: true),
                      child: filteredCustomers.isEmpty
                          ? EmptyState(
                              title: 'No Customers Found',
                              description: 'Try adjusting your filters or add a new client to get started.',
                              icon: Icons.people_outline_rounded,
                              actionLabel: 'Add Customer',
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 1.5,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
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
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Text(
                                        (customer.company.isNotEmpty
                                                ? customer.company.substring(0, 1)
                                                : (customer.name.isNotEmpty
                                                    ? customer.name.substring(0, 1)
                                                    : 'C'))
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
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
                                                  customer.company,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Status Chip
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: hasOrders 
                                                      ? const Color(0xFFD1FAE5) // light green
                                                      : const Color(0xFFF3F4F6), // light gray
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  hasOrders ? 'Active' : 'Inactive',
                                                  style: TextStyle(
                                                    color: hasOrders ? AppColors.success : Colors.grey[600],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Contact: ${customer.name} • ${customer.phone}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontSize: 12,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            lastPurchase != null 
                                                ? 'Last Buy: ${DateFormat('dd MMM yyyy').format(lastPurchase)}'
                                                : 'No purchases yet',
                                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
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
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: outstanding > 0 ? AppColors.error : AppColors.success,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Outstanding',
                                          style: TextStyle(fontSize: 9, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().fade(duration: 150.ms).slideY(begin: 0.05);
                      },
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final theme = Theme.of(context);
    final isSelected = _activeFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _activeFilter = label;
          });
        },
        selectedColor: theme.colorScheme.primary.withOpacity(0.15),
        checkmarkColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Future<void> _navigateToAddCustomer(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCustomerScreen(),
      ),
    );
    // Refresh after returning from create/edit screen
    if (mounted) {
      context.read<CustomerProvider>().fetchCustomers(refresh: true);
    }
  }

  void _showSortBottomSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort Customers By',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildSortOption('Alphabetical', Icons.sort_by_alpha_rounded),
              _buildSortOption('Outstanding', Icons.account_balance_wallet_rounded),
              _buildSortOption('Recently Added', Icons.calendar_today_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String val, IconData icon) {
    final isSelected = _sortBy == val;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey),
      title: Text(
        val,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
      onTap: () {
        setState(() {
          _sortBy = val;
        });
        Navigator.pop(context);
      },
    );
  }
}
