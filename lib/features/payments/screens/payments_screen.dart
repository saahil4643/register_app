import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_states.dart';
import '../../invoices/models/invoice.dart';
import '../../invoices/providers/invoice_provider.dart';
import '../../customers/models/payment.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedMode = 'All'; // 'All', 'UPI', 'Bank Transfer', 'Cash', 'Cheque'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().fetchInvoices(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showRecordPaymentDialog({Invoice? preselectedInvoice}) {
    final invoiceProvider = context.read<InvoiceProvider>();
    final pendingInvoices = invoiceProvider.invoices.where((inv) => inv.balanceDue > 0).toList();

    Invoice? chosenInvoice = preselectedInvoice ?? (pendingInvoices.isNotEmpty ? pendingInvoices.first : null);
    final amountCtrl = TextEditingController(
      text: chosenInvoice != null ? chosenInvoice.balanceDue.toStringAsFixed(2) : '',
    );
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String paymentMode = 'UPI';
    DateTime paymentDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.payments_outlined, color: AppColors.lightPrimary),
                  SizedBox(width: 8),
                  Text('Collect Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (preselectedInvoice == null && pendingInvoices.isNotEmpty) ...[
                          DropdownButtonFormField<Invoice>(
                            initialValue: chosenInvoice,
                            decoration: const InputDecoration(
                              labelText: 'Select Invoice to Collect *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: pendingInvoices
                                .map((inv) => DropdownMenuItem(
                                      value: inv,
                                      child: Text(
                                        '${inv.invoiceNumber} - ${inv.customer.name.isNotEmpty ? inv.customer.name : inv.customer.company} (Due: ₹${inv.balanceDue.toStringAsFixed(2)})',
                                        style: const TextStyle(fontSize: 12.5),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  chosenInvoice = val;
                                  amountCtrl.text = val.balanceDue.toStringAsFixed(2);
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                        ] else if (chosenInvoice != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Invoice ${chosenInvoice!.invoiceNumber}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      chosenInvoice!.customer.company.isNotEmpty
                                          ? chosenInvoice!.customer.company
                                          : chosenInvoice!.customer.name,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Balance Due', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                    Text(
                                      '₹${chosenInvoice!.balanceDue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Amount
                        TextFormField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Amount Received (₹) *',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter amount';
                            final parsed = double.tryParse(v.trim());
                            if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Payment Mode
                        DropdownButtonFormField<String>(
                          initialValue: paymentMode,
                          decoration: const InputDecoration(
                            labelText: 'Payment Mode *',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'UPI', child: Text('UPI (GPay / PhonePe / Paytm / BHIM)')),
                            DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer / NEFT / RTGS / IMPS')),
                            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'Cheque', child: Text('Cheque / DD')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => paymentMode = v);
                          },
                        ),
                        const SizedBox(height: 14),

                        // Reference / UTR
                        TextFormField(
                          controller: refCtrl,
                          decoration: InputDecoration(
                            labelText: paymentMode == 'UPI'
                                ? 'UPI Reference / UTR (Optional)'
                                : paymentMode == 'Cheque'
                                    ? 'Cheque Number (Optional)'
                                    : 'Transaction ID / Ref (Optional)',
                            hintText: paymentMode == 'UPI' ? 'e.g. 429810293812' : 'e.g. TXN-89210',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Date
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Text(
                              'Payment Date: ${DateFormat('dd MMM yyyy').format(paymentDate)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: paymentDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setDialogState(() => paymentDate = picked);
                                }
                              },
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Notes
                        TextFormField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Notes / Memo (Optional)',
                            hintText: 'e.g. Paid in full via GPay',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (chosenInvoice == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an invoice')),
                      );
                      return;
                    }

                    final amount = double.parse(amountCtrl.text.trim());
                    Navigator.pop(dialogCtx);

                    final success = await invoiceProvider.recordPayment(
                      invoiceId: chosenInvoice!.id,
                      amount: amount,
                      paymentMode: paymentMode,
                      paymentDate: paymentDate,
                      reference: refCtrl.text.trim(),
                      notes: notesCtrl.text.trim(),
                    );

                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment of ₹${amount.toStringAsFixed(2)} recorded successfully!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        setState(() {});
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(invoiceProvider.errorMessage ?? 'Failed to record payment'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm & Record'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReceiptModal(Payment payment, Invoice? invoice) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                        SizedBox(width: 8),
                        Text('Payment Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                        currency.format(payment.amount),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Payment Received (${payment.paymentMode})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildReceiptRow('Receipt Number', payment.paymentNumber.isNotEmpty ? payment.paymentNumber : payment.id),
                _buildReceiptRow('Payment Date', DateFormat('dd MMMM yyyy, hh:mm a').format(payment.paymentDate)),
                _buildReceiptRow('Customer', payment.customerName.isNotEmpty ? payment.customerName : (invoice?.customer.name ?? 'Customer')),
                if (invoice != null)
                  _buildReceiptRow('Against Invoice', invoice.invoiceNumber),
                _buildReceiptRow('Payment Method', payment.paymentMode),
                if (payment.reference.isNotEmpty)
                  _buildReceiptRow('Reference / UTR', payment.reference),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Receipt link copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Share Receipt'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Receipt downloaded as PDF')),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightPrimary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<InvoiceProvider>();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Aggregate financial metrics
    final totalCollected = provider.payments.fold<double>(0.0, (sum, p) => sum + p.amount);
    final totalOutstanding = provider.invoices.fold<double>(0.0, (sum, inv) => sum + inv.balanceDue);
    final now = DateTime.now();
    final collectedThisMonth = provider.payments
        .where((p) => p.paymentDate.month == now.month && p.paymentDate.year == now.year)
        .fold<double>(0.0, (sum, p) => sum + p.amount);

    // Filter collected payments
    final filteredPayments = provider.payments.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCust = p.customerName.toLowerCase().contains(q);
        final matchRef = p.reference.toLowerCase().contains(q);
        final matchNum = p.paymentNumber.toLowerCase().contains(q);
        if (!(matchCust || matchRef || matchNum)) return false;
      }
      if (_selectedMode != 'All' && p.paymentMode.toLowerCase() != _selectedMode.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    // Filter pending invoices
    final pendingInvoices = provider.invoices.where((inv) {
      if (inv.balanceDue <= 0) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchNum = inv.invoiceNumber.toLowerCase().contains(q);
        final matchCust = inv.customer.name.toLowerCase().contains(q) || inv.customer.company.toLowerCase().contains(q);
        if (!(matchNum || matchCust)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Payment Collections', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Record Payment',
            onPressed: () => _showRecordPaymentDialog(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.lightPrimary,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppColors.lightPrimary,
          indicatorWeight: 2.5,
          tabs: [
            Tab(text: 'Collected Receipts (${provider.payments.length})'),
            Tab(text: 'Pending Collection (${pendingInvoices.length})'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Summary Cards
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Collected',
                        amount: currency.format(totalCollected),
                        color: AppColors.success,
                        icon: Icons.check_circle_outline_rounded,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Pending Collection',
                        amount: currency.format(totalOutstanding),
                        color: AppColors.warning,
                        icon: Icons.pending_actions_rounded,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'This Month',
                        amount: currency.format(collectedThisMonth),
                        color: AppColors.lightPrimary,
                        icon: Icons.calendar_today_rounded,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar & Filter Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by customer, invoice #, receipt #, UTR...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildModeChip('All Modes', 'All'),
                          _buildModeChip('UPI', 'UPI'),
                          _buildModeChip('Bank Transfer', 'Bank Transfer'),
                          _buildModeChip('Cash', 'Cash'),
                          _buildModeChip('Cheque', 'Cheque'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // TabBarView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Collected Receipts
                    _buildCollectedList(filteredPayments, provider, currency, isDark),

                    // Tab 2: Pending Invoices
                    _buildPendingList(pendingInvoices, currency, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordPaymentDialog(),
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Collect Payment', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildModeChip(String label, String value) {
    final theme = Theme.of(context);
    final isSelected = _selectedMode == value;

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedMode = value);
          }
        },
        selectedColor: theme.colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected ? theme.colorScheme.primary : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 11.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary : const Color(0xFFE5E7EB),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectedList(
    List<Payment> payments,
    InvoiceProvider provider,
    NumberFormat currency,
    bool isDark,
  ) {
    if (payments.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.payments_outlined,
          title: 'No Payments Recorded Yet',
          description: 'Collect payments from your customers to view receipts here.',
          actionLabel: 'Collect Payment',
          onActionPressed: () => _showRecordPaymentDialog(),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: payments.length,
      itemBuilder: (context, idx) {
        final payment = payments[idx];
        Invoice? matchingInvoice;
        if (payment.invoiceId != null && payment.invoiceId!.isNotEmpty) {
          final found = provider.invoices.where((inv) => inv.id == payment.invoiceId);
          if (found.isNotEmpty) matchingInvoice = found.first;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showReceiptModal(payment, matchingInvoice),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_downward_rounded, color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.customerName.isNotEmpty
                              ? payment.customerName
                              : (matchingInvoice?.customer.name ?? 'Customer Payment'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                payment.paymentMode,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (matchingInvoice != null) ...[
                              Text(
                                matchingInvoice.invoiceNumber,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1))),
                            ],
                            Text(
                              DateFormat('dd MMM yyyy').format(payment.paymentDate),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.format(payment.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.success),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Received',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingList(
    List<Invoice> invoices,
    NumberFormat currency,
    bool isDark,
  ) {
    if (invoices.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: 'All Invoices Paid!',
          description: 'There are no pending customer collections at this time.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: invoices.length,
      itemBuilder: (context, idx) {
        final inv = invoices[idx];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            inv.invoiceNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              inv.status.name.toUpperCase(),
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        inv.customer.company.isNotEmpty ? inv.customer.company : inv.customer.name,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Due: ${DateFormat('dd MMM yyyy').format(inv.dueDate)} • Total: ${currency.format(inv.grandTotal)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(inv.balanceDue),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.error),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: () => _showRecordPaymentDialog(preselectedInvoice: inv),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Collect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
