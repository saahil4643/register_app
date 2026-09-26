import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../../customers/models/customer.dart';
import '../../customers/widgets/add_customer_dialog.dart';
import '../../customers/widgets/customer_credentials_dialog.dart';
import 'dart:async';

class CustomerPickerSheet extends StatefulWidget {
  const CustomerPickerSheet({super.key});

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().fetchCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _openAddCustomerDialog(BuildContext context, {String? initialName}) async {
    // Use useRootNavigator: true so the dialog is shown via the root navigator,
    // above the bottom sheet's overlay layer. Without this, the dialog tries to
    // attach to the bottom sheet's own overlay which hasn't finished layout yet,
    // causing the '_owner != null' and 'render box with no size' assertions.
    final newCustomer = await showDialog<Customer>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => AddCustomerDialog(initialName: initialName),
    );

    if (newCustomer != null && context.mounted) {
      await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) => CustomerCredentialsDialog(customer: newCustomer),
      );
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close CustomerPickerSheet
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<InvoiceProvider>();
    
    // Filter customers based on search query
    final filteredCustomers = provider.customers;

    return Container(
      padding: const EdgeInsets.only(top: 8),
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Drag handle indicator
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Select Customer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  tooltip: 'Add New Customer',
                  onPressed: () => _openAddCustomerDialog(context),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  context.read<InvoiceProvider>().fetchCustomers(query: val);
                });
              },
              decoration: InputDecoration(
                hintText: 'Search customer or company name...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          context.read<InvoiceProvider>().fetchCustomers();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Customers List
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Customers Found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different name or search term.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _openAddCustomerDialog(context, initialName: _searchQuery),
                              icon: const Icon(Icons.person_add_rounded),
                              label: Text('Add "$_searchQuery"'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                    itemCount: filteredCustomers.length + (_searchQuery.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show Quick Add Card at the top of list when searching
                      if (_searchQuery.isNotEmpty && index == 0) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openAddCustomerDialog(context, initialName: _searchQuery),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                                    child: Icon(
                                      Icons.person_add_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Add "$_searchQuery"',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Create a new customer profile',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final customerIndex = _searchQuery.isNotEmpty ? index - 1 : index;
                      final customer = filteredCustomers[customerIndex];
                      final isSelected = provider.selectedCustomer?.id == customer.id;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark ? Colors.transparent : Colors.grey.withOpacity(0.08)),
                            width: 1.5,
                          ),
                        ),
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                            : (isDark ? theme.colorScheme.surface : Colors.white),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            provider.selectCustomer(customer);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                // Avatar with initials
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isSelected
                                      ? theme.colorScheme.primary
                                      : (isDark ? Colors.grey[800] : Colors.grey[100]),
                                  child: Text(
                                    customer.company.isNotEmpty 
                                        ? customer.company.substring(0, 1).toUpperCase()
                                        : customer.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Customer Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.company,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        customer.name,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        customer.email,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
