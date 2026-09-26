import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_cards.dart';
import '../../../core/widgets/custom_states.dart';
import '../../invoices/providers/invoice_provider.dart';
import '../../invoices/models/invoice.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../providers/customer_provider.dart';
import '../../products/models/product.dart';
import 'create_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomerDetails(widget.customerId);
      context.read<CustomerProvider>().fetchCustomerStatistics(widget.customerId);
    });
  }

  void _confirmDeleteCustomer(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}? This will archive the record.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<CustomerProvider>().deleteCustomer(customer.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer deleted successfully')),
                );
                Navigator.pop(context);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.read<CustomerProvider>().errorMessage ?? 'Failed to delete customer')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showReceivePaymentDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => _ReceivePaymentDialog(customer: customer),
    );
  }

  void _mockLaunch(BuildContext context, String action, String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              action == 'WhatsApp' ? Icons.chat_bubble_outline_rounded : Icons.phone_callback_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text('$action launcher: $value'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: action == 'WhatsApp' ? AppColors.success : themeColor(context),
      ),
    );
  }

  Color themeColor(BuildContext context) => Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<InvoiceProvider>();
    final customerProvider = context.watch<CustomerProvider>();

    // Find the customer
    final customer = customerProvider.selectedCustomerDetails ?? provider.customers.firstWhere(
      (c) => c.id == widget.customerId,
      orElse: () => Customer(
        id: '',
        name: '',
        email: '',
        phone: '',
        address: '',
        company: '',
        gstNo: '',
        createdAt: DateTime.now(),
      ),
    );

    if (customer.id.isEmpty && customerProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (customer.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const ErrorState(message: 'Customer not found in data ledger.'),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final stats = customerProvider.selectedCustomerStats;
    final outstanding = stats != null
        ? double.tryParse(stats['outstanding_balance']?.toString() ?? '0.0') ?? 0.0
        : customer.outstanding;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280.0,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightPrimaryContainer,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _confirmDeleteCustomer(context, customer),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () async {
                    final updated = await Navigator.push<Customer>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateCustomerScreen(customer: customer),
                      ),
                    );
                    if (updated != null) {
                      setState(() {});
                    }
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      // Large Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          customer.company.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Name & Company
                      Text(
                        customer.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        customer.company,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Outstanding & Credit Limit Metrics
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  currencyFormat.format(outstanding),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: outstanding > 0 ? AppColors.error : AppColors.success,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Outstanding Due',
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                            Container(
                              height: 30,
                              width: 1,
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            Column(
                              children: [
                                Text(
                                  currencyFormat.format(customer.creditLimit),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Credit Limit',
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Transactions'),
                    Tab(text: 'Invoices'),
                    Tab(text: 'Payments'),
                    Tab(text: 'Products'),
                    Tab(text: 'Notes'),
                  ],
                ),
                isDark ? AppColors.darkSurface : theme.scaffoldBackgroundColor,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(context, provider, customer, currencyFormat),
            _buildTransactionsTab(context, provider, customer, currencyFormat),
            _buildInvoicesTab(context, provider, customer, currencyFormat),
            _buildPaymentsTab(context, provider, customer, currencyFormat),
            _buildProductsTab(context, provider, customer, currencyFormat),
            _buildNotesTab(context, customer),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    InvoiceProvider provider,
    Customer customer,
    NumberFormat currencyFormat,
  ) {
    final theme = Theme.of(context);
    final customerProvider = context.watch<CustomerProvider>();
    final stats = customerProvider.selectedCustomerStats;

    final totalOrders = stats != null
        ? (stats['invoice_history'] as List?)?.length ?? 0
        : provider.getTotalOrdersForCustomer(customer.id);
    final totalPurchase = stats != null
        ? double.tryParse(stats['total_revenue']?.toString() ?? '0.0') ?? 0.0
        : provider.getTotalPurchaseForCustomer(customer.id);
    final outstanding = stats != null
        ? double.tryParse(stats['outstanding_balance']?.toString() ?? '0.0') ?? 0.0
        : customer.outstanding;
    final paidAmount = stats != null
        ? (stats['recent_payments'] as List?)?.fold<double>(
              0.0,
              (sum, item) =>
                  sum + (double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0)) ??
            0.0
        : provider.getPaidAmountForCustomer(customer.id);

    DateTime? lastPurchase;
    if (stats != null) {
      final history = stats['invoice_history'] as List?;
      if (history != null && history.isNotEmpty) {
        final firstInv = history.first;
        if (firstInv['invoice_date'] != null) {
          lastPurchase = DateTime.tryParse(firstInv['invoice_date'].toString());
        }
      }
    }
    lastPurchase ??= provider.getLastPurchaseDateForCustomer(customer.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _mockLaunch(context, 'Call', customer.phone),
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _mockLaunch(context, 'WhatsApp', customer.phone),
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD1FAE5),
                    foregroundColor: AppColors.success,
                    elevation: 0,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.startNewInvoice();
                    provider.selectCustomer(customer);
                    context.push('/invoices/create');
                  },
                  icon: const Icon(Icons.add_chart_rounded, size: 16),
                  label: const Text('Create Invoice'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showReceivePaymentDialog(context, customer),
                  icon: const Icon(Icons.payment_rounded, size: 16),
                  label: const Text('Receive Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Overview statistics grid
          Text(
            'Financial Stats',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.45,
            children: [
              _buildStatTile(context, 'Total Orders', totalOrders.toString(), Icons.shopping_basket_outlined),
              _buildStatTile(context, 'Total Sales', currencyFormat.format(totalPurchase), Icons.monetization_on_outlined),
              _buildStatTile(context, 'Outstanding', currencyFormat.format(outstanding), Icons.hourglass_empty_rounded, color: outstanding > 0 ? AppColors.error : AppColors.success),
              _buildStatTile(context, 'Total Paid', currencyFormat.format(paidAmount), Icons.check_circle_outline_rounded, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Last Purchase Date', style: TextStyle(fontSize: 13)),
              trailing: Text(
                lastPurchase != null ? DateFormat('dd MMM yyyy').format(lastPurchase) : 'No purchases yet',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Divider(height: 20),
                  _buildDetailRow('Email', customer.email.isNotEmpty ? customer.email : 'N/A'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Phone', customer.phone),
                  const SizedBox(height: 8),
                  _buildDetailRow('GST Number', customer.gstNo.isNotEmpty ? customer.gstNo : 'N/A'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Billing Address', customer.address),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab(
    BuildContext context,
    InvoiceProvider provider,
    Customer customer,
    NumberFormat currencyFormat,
  ) {
    final customerProvider = context.watch<CustomerProvider>();
    final stats = customerProvider.selectedCustomerStats;

    // Merge transactions chronologically
    final List<Map<String, dynamic>> ledger = [];

    if (stats != null) {
      final List<dynamic> invoiceHistory = stats['invoice_history'] ?? [];
      final List<dynamic> recentPayments = stats['recent_payments'] ?? [];

      for (final inv in invoiceHistory) {
        ledger.add({
          'type': 'invoice',
          'date': DateTime.tryParse(inv['invoice_date'] ?? inv['created_at'] ?? '') ?? DateTime.now(),
          'title': inv['invoice_number'] ?? '',
          'amount': double.tryParse(inv['grand_total']?.toString() ?? '0.0') ?? 0.0,
          'status': InvoiceStatus.values.firstWhere(
              (e) => e.name.toLowerCase() == (inv['status']?.toString().toLowerCase() ?? 'draft'),
              orElse: () => InvoiceStatus.draft),
          'obj': inv,
        });
      }
      for (final pay in recentPayments) {
        ledger.add({
          'type': 'payment',
          'date': DateTime.tryParse(pay['payment_date'] ?? '') ?? DateTime.now(),
          'title': 'Payment Recv (${pay['payment_method']?.toString().toUpperCase() ?? ''})',
          'amount': double.tryParse(pay['amount']?.toString() ?? '0.0') ?? 0.0,
          'ref': pay['reference_number'] ?? '',
          'obj': pay,
        });
      }
    } else {
      final invoices = provider.getInvoicesForCustomer(customer.id);
      final payments = provider.getPaymentsForCustomer(customer.id);

      for (final inv in invoices) {
        ledger.add({
          'type': 'invoice',
          'date': inv.invoiceDate,
          'title': inv.invoiceNumber,
          'amount': inv.grandTotal,
          'status': inv.status,
          'obj': inv,
        });
      }
      for (final pay in payments) {
        ledger.add({
          'type': 'payment',
          'date': pay.paymentDate,
          'title': 'Payment Recv (${pay.paymentMode})',
          'amount': pay.amount,
          'ref': pay.reference,
          'obj': pay,
        });
      }
    }

    ledger.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (ledger.isEmpty) {
      return const EmptyState(
        title: 'No Transaction History',
        description: 'Invoices created and payments received will appear here chronologically.',
        icon: Icons.history_rounded,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: ledger.length,
      itemBuilder: (context, index) {
        final tx = ledger[index];
        final bool isInvoice = tx['type'] == 'invoice';
        final double amount = tx['amount'];
        final dateStr = DateFormat('dd MMM yyyy').format(tx['date'] as DateTime);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
            ),
          ),
          child: ListTile(
            onTap: isInvoice
                ? () {
                    final invId = tx['obj'] is Invoice
                        ? (tx['obj'] as Invoice).id
                        : (tx['obj'] as Map<String, dynamic>)['id']?.toString() ?? '';
                    if (invId.isNotEmpty) {
                      context.push('/invoices/details/$invId');
                    }
                  }
                : null,
            leading: CircleAvatar(
              backgroundColor: isInvoice 
                  ? (isDark ? Colors.purple.withOpacity(0.2) : const Color(0xFFF3E8FF))
                  : (isDark ? Colors.teal.withOpacity(0.2) : const Color(0xFFE6FFFA)),
              child: Icon(
                isInvoice ? Icons.receipt_long_outlined : Icons.account_balance_wallet_outlined,
                color: isInvoice ? Colors.purple : Colors.teal,
                size: 20,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tx['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  isInvoice ? currencyFormat.format(amount) : '-${currencyFormat.format(amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isInvoice ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (isInvoice)
                    _getStatusChip(tx['status'] as InvoiceStatus)
                  else
                    Text('Ref: ${tx['ref']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getStatusChip(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return StatusChip.paid();
      case InvoiceStatus.sent:
        return StatusChip.pending(label: 'Sent');
      case InvoiceStatus.overdue:
        return StatusChip.overdue();
      case InvoiceStatus.draft:
        return StatusChip.draft();
      case InvoiceStatus.cancelled:
        return StatusChip.draft(label: 'Cancelled');
    }
  }

  Widget _buildInvoicesTab(
    BuildContext context,
    InvoiceProvider provider,
    Customer customer,
    NumberFormat currencyFormat,
  ) {
    final customerProvider = context.watch<CustomerProvider>();
    final stats = customerProvider.selectedCustomerStats;

    if (stats != null) {
      final List<dynamic> invoiceHistory = stats['invoice_history'] ?? [];

      if (invoiceHistory.isEmpty) {
        return const EmptyState(
          title: 'No Invoices Found',
          description: 'Start by creating a new invoice for this customer.',
          icon: Icons.receipt_long_outlined,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: invoiceHistory.length,
        itemBuilder: (context, index) {
          final inv = invoiceHistory[index];
          final dateStr = inv['due_date'] != null
              ? DateFormat('dd MMM yyyy').format(DateTime.parse(inv['due_date'].toString()))
              : 'N/A';
          final statusVal = InvoiceStatus.values.firstWhere(
              (e) => e.name.toLowerCase() == (inv['status']?.toString().toLowerCase() ?? 'draft'),
              orElse: () => InvoiceStatus.draft);
          final grandTotal = double.tryParse(inv['grand_total']?.toString() ?? '0.0') ?? 0.0;

          return ListCard(
            title: inv['invoice_number'] ?? '',
            subtitle: 'Due: $dateStr',
            amount: currencyFormat.format(grandTotal),
            statusWidget: _getStatusChip(statusVal),
            leadingIcon: Icons.receipt_long_outlined,
            onTap: () => context.push('/invoices/details/${inv['id']}'),
          );
        },
      );
    }

    final invoices = provider.getInvoicesForCustomer(customer.id);

    if (invoices.isEmpty) {
      return const EmptyState(
        title: 'No Invoices Found',
        description: 'Start by creating a new invoice for this customer.',
        icon: Icons.receipt_long_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final inv = invoices[index];
        return ListCard(
          title: inv.invoiceNumber,
          subtitle: 'Due: ${DateFormat('dd MMM yyyy').format(inv.dueDate)}',
          amount: currencyFormat.format(inv.grandTotal),
          statusWidget: _getStatusChip(inv.status),
          leadingIcon: Icons.receipt_long_outlined,
          onTap: () => context.push('/invoices/details/${inv.id}'),
        );
      },
    );
  }

  Widget _buildPaymentsTab(
    BuildContext context,
    InvoiceProvider provider,
    Customer customer,
    NumberFormat currencyFormat,
  ) {
    final customerProvider = context.watch<CustomerProvider>();
    final stats = customerProvider.selectedCustomerStats;

    if (stats != null) {
      final List<dynamic> recentPayments = stats['recent_payments'] ?? [];

      if (recentPayments.isEmpty) {
        return const EmptyState(
          title: 'No Payments Received',
          description: 'Log a payment using the Receive Payment action on the overview tab.',
          icon: Icons.payments_outlined,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: recentPayments.length,
        itemBuilder: (context, index) {
          final pay = recentPayments[index];
          final invoiceNum = pay['invoice_number'] ?? 'General Account';
          final payDate = pay['payment_date'] != null ? DateTime.parse(pay['payment_date'].toString()) : DateTime.now();
          final amount = double.tryParse(pay['amount']?.toString() ?? '0.0') ?? 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(payDate),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        currencyFormat.format(amount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildInfoRow('Payment Mode', pay['payment_method']?.toString().toUpperCase() ?? ''),
                  const SizedBox(height: 6),
                  _buildInfoRow('Reference Num', pay['reference_number'] ?? ''),
                  const SizedBox(height: 6),
                  _buildInfoRow('Allocated To', invoiceNum),
                ],
              ),
            ),
          );
        },
      );
    }

    final payments = provider.getPaymentsForCustomer(customer.id);

    if (payments.isEmpty) {
      return const EmptyState(
        title: 'No Payments Received',
        description: 'Log a payment using the Receive Payment action on the overview tab.',
        icon: Icons.payments_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final pay = payments[index];
        final invoiceNum = pay.invoiceId != null
            ? provider.invoices.firstWhere((i) => i.id == pay.invoiceId, orElse: () => Invoice(id: '', invoiceNumber: 'General Account', customer: customer, invoiceDate: DateTime.now(), dueDate: DateTime.now(), items: [], status: InvoiceStatus.draft)).invoiceNumber
            : 'General Account';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(pay.paymentDate),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      currencyFormat.format(pay.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _buildInfoRow('Payment Mode', pay.paymentMode),
                const SizedBox(height: 6),
                _buildInfoRow('Reference Num', pay.reference),
                const SizedBox(height: 6),
                _buildInfoRow('Allocated To', invoiceNum),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProductsTab(
    BuildContext context,
    InvoiceProvider provider,
    Customer customer,
    NumberFormat currencyFormat,
  ) {
    final products = provider.getProductsPurchasedByCustomer(customer.id);

    if (products.isEmpty) {
      return const EmptyState(
        title: 'No Products Purchased',
        description: 'Products purchased by this customer via invoices will appear here.',
        icon: Icons.inventory_2_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final prod = products[index];

        // Calculate item purchases
        int qtySold = 0;
        double revenue = 0;
        final customerInvoices = provider.invoices.where((i) => i.customer.id == customer.id);
        for (final inv in customerInvoices) {
          for (final item in inv.items) {
            if (item.product.id == prod.id) {
              qtySold += item.quantity;
              revenue += item.total;
            }
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.inventory_2_rounded, color: Colors.blue),
            ),
            title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('SKU: ${prod.sku} • Purchased Qty: $qtySold'),
            trailing: Text(
              currencyFormat.format(revenue),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesTab(BuildContext context, Customer customer) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Ledger Notes',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  customer.notes.isNotEmpty 
                      ? customer.notes 
                      : 'No notes entered for this customer. Tap edit at the top right to log billing cycles or special discount agreements.',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Slivers Persistent Header Delegate for Pinned TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// Receive Payment Interactive Dialog
class _ReceivePaymentDialog extends StatefulWidget {
  final Customer customer;

  const _ReceivePaymentDialog({required this.customer});

  @override
  State<_ReceivePaymentDialog> createState() => _ReceivePaymentDialogState();
}

class _ReceivePaymentDialogState extends State<_ReceivePaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _referenceController;
  String _paymentMode = 'UPI';
  Invoice? _selectedInvoice;

  @override
  void initState() {
    super.initState();
    final provider = context.read<InvoiceProvider>();
    final outstanding = provider.getOutstandingForCustomer(widget.customer.id);
    _amountController = TextEditingController(text: outstanding > 0 ? outstanding.toString() : '');
    _referenceController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final outstanding = provider.getOutstandingForCustomer(widget.customer.id);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Filter sent/overdue invoices for this customer
    final customerInvoices = provider.invoices.where((inv) => 
      inv.customer.id == widget.customer.id && 
      (inv.status == InvoiceStatus.sent || inv.status == InvoiceStatus.overdue)
    ).toList();

    return AlertDialog(
      title: const Text('Receive Payment', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer: ${widget.customer.company}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                'Total Outstanding: ${currencyFormat.format(outstanding)}',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: outstanding > 0 ? AppColors.error : AppColors.success),
              ),
              const SizedBox(height: 16),
              
              // Invoice allocation dropdown
              if (customerInvoices.isNotEmpty) ...[
                DropdownButtonFormField<Invoice>(
                  decoration: const InputDecoration(
                    labelText: 'Allocate to Invoice',
                    prefixIcon: Icon(Icons.receipt_rounded),
                  ),
                  value: _selectedInvoice,
                  items: [
                    const DropdownMenuItem<Invoice>(
                      value: null,
                      child: Text('General (On Account)'),
                    ),
                    ...customerInvoices.map((inv) {
                      final invPayments = provider.payments.where((p) => p.invoiceId == inv.id).fold(0.0, (sum, p) => sum + p.amount);
                      final remaining = inv.grandTotal - invPayments;
                      return DropdownMenuItem<Invoice>(
                        value: inv,
                        child: Text('${inv.invoiceNumber} (${currencyFormat.format(remaining)})'),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedInvoice = val;
                      if (val != null) {
                        final invPayments = provider.payments.where((p) => p.invoiceId == val.id).fold(0.0, (sum, p) => sum + p.amount);
                        final remaining = val.grandTotal - invPayments;
                        _amountController.text = remaining.toString();
                      } else {
                        _amountController.text = outstanding.toString();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount Received (₹) *',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter amount';
                  final num = double.tryParse(val);
                  if (num == null || num <= 0) return 'Enter a positive amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Payment Mode field
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Payment Mode *',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
                value: _paymentMode,
                items: ['UPI', 'Bank Transfer', 'Cash', 'Cheque'].map((mode) {
                  return DropdownMenuItem(value: mode, child: Text(mode));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _paymentMode = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Reference field
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference / Txn ID *',
                  prefixIcon: Icon(Icons.bookmark_outline_rounded),
                  hintText: 'e.g. UPI Transaction ID or Bank Ref',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter reference number' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            final amt = double.parse(_amountController.text);
            final payment = Payment(
              id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
              customerId: widget.customer.id,
              invoiceId: _selectedInvoice?.id,
              amount: amt,
              paymentMode: _paymentMode,
              paymentDate: DateTime.now(),
              reference: _referenceController.text.trim(),
            );

            provider.addPayment(payment);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment of ${currencyFormat.format(amt)} logged successfully'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );

            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Payment'),
        ),
      ],
    );
  }
}
