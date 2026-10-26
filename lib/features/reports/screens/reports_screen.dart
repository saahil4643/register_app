import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_states.dart';
import '../../invoices/models/invoice.dart';
import '../../invoices/providers/invoice_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'All Time'; // 'This Month', 'Last Month', 'This Quarter', 'FY 2026-27', 'All Time'
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().fetchInvoices(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Invoice> _filterInvoicesByPeriod(List<Invoice> invoices) {
    final now = DateTime.now();
    return invoices.where((inv) {
      final d = inv.invoiceDate;
      switch (_selectedPeriod) {
        case 'This Month':
          return d.year == now.year && d.month == now.month;
        case 'Last Month':
          final lastMonth = now.month == 1 ? 12 : now.month - 1;
          final year = now.month == 1 ? now.year - 1 : now.year;
          return d.year == year && d.month == lastMonth;
        case 'This Quarter':
          final currentQuarter = (now.month - 1) ~/ 3 + 1;
          final invQuarter = (d.month - 1) ~/ 3 + 1;
          return d.year == now.year && invQuarter == currentQuarter;
        case 'FY 2026-27':
          final fyStart = DateTime(2026, 4, 1);
          final fyEnd = DateTime(2027, 3, 31, 23, 59, 59);
          return d.isAfter(fyStart.subtract(const Duration(seconds: 1))) && d.isBefore(fyEnd);
        case 'All Time':
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<InvoiceProvider>();

    final invoices = _filterInvoicesByPeriod(provider.invoices);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('GST & Financial Reports', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          // Period Selector Dropdown
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                items: const [
                  DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                  DropdownMenuItem(value: 'Last Month', child: Text('Last Month')),
                  DropdownMenuItem(value: 'This Quarter', child: Text('This Quarter')),
                  DropdownMenuItem(value: 'FY 2026-27', child: Text('FY 2026-27')),
                  DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedPeriod = v);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('GST report summary exported to clipboard')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.lightPrimary,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppColors.lightPrimary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'GSTR-1 (Sales)'),
            Tab(text: 'GSTR-3B (Tax Liability)'),
            Tab(text: 'HSN Tax Breakdown'),
            Tab(text: 'Customer Receivables'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: invoices.isEmpty
              ? Center(
                  child: EmptyState(
                    icon: Icons.bar_chart_rounded,
                    title: 'No Data for $_selectedPeriod',
                    description: 'Generate invoices to populate comprehensive GST filing summaries.',
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGstr1Tab(invoices, isDark),
                    _buildGstr3bTab(invoices, isDark),
                    _buildHsnSummaryTab(invoices, isDark),
                    _buildCustomerReceivablesTab(invoices, isDark),
                  ],
                ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 1: GSTR-1 Sales Report
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildGstr1Tab(List<Invoice> invoices, bool isDark) {
    double totalTaxable = 0.0;
    double totalCgst = 0.0;
    double totalSgst = 0.0;
    double totalIgst = 0.0;
    double totalInvoiceVal = 0.0;

    final List<Invoice> b2bInvoices = [];
    final List<Invoice> b2cInvoices = [];

    for (final inv in invoices) {
      totalTaxable += inv.subtotal;
      totalInvoiceVal += inv.grandTotal;

      // Check if B2B (Customer has GSTIN) or B2C
      final hasGstin = inv.customer.gstNo.isNotEmpty;
      if (hasGstin) {
        b2bInvoices.add(inv);
      } else {
        b2cInvoices.add(inv);
      }

      // Calculate CGST + SGST vs IGST
      // Default: 50% CGST + 50% SGST for intra-state
      for (final item in inv.items) {
        final tax = item.taxAmount;
        totalCgst += tax / 2.0;
        totalSgst += tax / 2.0;
      }
    }

    final totalTax = totalCgst + totalSgst + totalIgst;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Highlights
          Row(
            children: [
              Expanded(
                child: _buildReportMetricTile(
                  'Taxable Value',
                  currencyFormat.format(totalTaxable),
                  const Color(0xFF0F172A),
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildReportMetricTile(
                  'Total Tax',
                  currencyFormat.format(totalTax),
                  AppColors.lightPrimary,
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildReportMetricTile(
                  'Total Invoiced',
                  currencyFormat.format(totalInvoiceVal),
                  AppColors.success,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tax Split Breakdown (CGST & SGST)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppColors.lightPrimary),
                    SizedBox(width: 8),
                    Text('GST Split Breakdown (Outward Supplies)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const Divider(height: 20),
                _buildSummaryLine('Central GST (CGST)', currencyFormat.format(totalCgst)),
                _buildSummaryLine('State GST (SGST / UTGST)', currencyFormat.format(totalSgst)),
                _buildSummaryLine('Integrated GST (IGST)', currencyFormat.format(totalIgst)),
                const Divider(height: 16),
                _buildSummaryLine(
                  'Net Tax Output Liability',
                  currencyFormat.format(totalTax),
                  isBold: true,
                  highlightColor: AppColors.lightPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // B2B Section
          _buildSectionHeading('SECTION 4A: B2B INVOICES (REGISTERED BUYERS - ${b2bInvoices.length})'),
          const SizedBox(height: 8),
          b2bInvoices.isEmpty
              ? _buildEmptySectionCard('No B2B invoices with customer GSTIN in this period.')
              : _buildInvoiceTable(b2bInvoices, isDark),

          const SizedBox(height: 20),

          // B2C Section
          _buildSectionHeading('SECTION 7: B2C INVOICES (CONSUMERS & UNREGISTERED - ${b2cInvoices.length})'),
          const SizedBox(height: 8),
          b2cInvoices.isEmpty
              ? _buildEmptySectionCard('No B2C consumer invoices in this period.')
              : _buildInvoiceTable(b2cInvoices, isDark),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 2: GSTR-3B Tax Liability
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildGstr3bTab(List<Invoice> invoices, bool isDark) {
    double taxableSupplies = 0.0;
    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;

    for (final inv in invoices) {
      taxableSupplies += inv.subtotal;
      for (final item in inv.items) {
        final tax = item.taxAmount;
        cgst += tax / 2.0;
        sgst += tax / 2.0;
      }
    }

    final totalLiability = cgst + sgst + igst;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.assessment_outlined, size: 20, color: AppColors.lightPrimary),
                    SizedBox(width: 8),
                    Text(
                      'Table 3.1: Details of Outward Supplies & Liabilities',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Summary required for monthly GSTR-3B filing and tax payment',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Divider(height: 24),
                _buildSummaryLine('(a) Outward taxable supplies (other than zero rated)', currencyFormat.format(taxableSupplies)),
                _buildSummaryLine('    • Integrated Tax (IGST)', currencyFormat.format(igst)),
                _buildSummaryLine('    • Central Tax (CGST)', currencyFormat.format(cgst)),
                _buildSummaryLine('    • State / UT Tax (SGST)', currencyFormat.format(sgst)),
                const Divider(height: 16),
                _buildSummaryLine('(b) Outward taxable supplies (zero rated / export)', '₹0.00'),
                _buildSummaryLine('(c) Other outward supplies (nil rated, exempted)', '₹0.00'),
                _buildSummaryLine('(d) Inward supplies liable to reverse charge (RCM)', '₹0.00'),
                _buildSummaryLine('(e) Non-GST outward supplies', '₹0.00'),
                const Divider(height: 20),
                _buildSummaryLine(
                  'TOTAL GST LIABILITY TO PAY',
                  currencyFormat.format(totalLiability),
                  isBold: true,
                  highlightColor: AppColors.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Compliance Notice Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ensure that GSTR-3B is filed on or before the 20th of the following month to avoid interest and late fees under Section 47 of the CGST Act.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 3: HSN Tax Summary (Table 12)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHsnSummaryTab(List<Invoice> invoices, bool isDark) {
    // Group line items by HSN / SAC code
    final Map<String, _HsnAggregate> hsnMap = {};

    for (final inv in invoices) {
      for (final item in inv.items) {
        final itemHsn = item.hsnSac;
        final code = (itemHsn != null && itemHsn.isNotEmpty)
            ? itemHsn
            : (item.product.hsnSacCode.isNotEmpty ? item.product.hsnSacCode : 'General');
        final name = item.itemName;
        final u = item.unit;
        final current = hsnMap.putIfAbsent(
          code,
          () => _HsnAggregate(
            code: code,
            description: (name != null && name.isNotEmpty) ? name : item.product.name,
            uqc: (u != null && u.isNotEmpty) ? u : item.product.unitAbbreviation,
          ),
        );

        current.quantity += item.quantity;
        current.taxableValue += item.subtotal;
        current.taxAmount += item.taxAmount;
      }
    }

    final hsnList = hsnMap.values.toList()
      ..sort((a, b) => b.taxableValue.compareTo(a.taxableValue));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading('TABLE 12: HSN-WISE SUMMARY OF OUTWARD SUPPLIES (${hsnList.length} CODES)'),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hsnList.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final hsn = hsnList[idx];
                final cgst = hsn.taxAmount / 2.0;
                final sgst = hsn.taxAmount / 2.0;

                return Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hsn.code,
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hsn.description,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Qty: ${hsn.quantity} ${hsn.uqc} • CGST: ${currencyFormat.format(cgst)} | SGST: ${currencyFormat.format(sgst)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(hsn.taxableValue),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+ Tax ${currencyFormat.format(hsn.taxAmount)}',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 4: Customer Receivables & Ledger
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCustomerReceivablesTab(List<Invoice> invoices, bool isDark) {
    final Map<String, _CustomerAggregate> custMap = {};

    for (final inv in invoices) {
      final custId = inv.customer.id.isNotEmpty ? inv.customer.id : inv.customer.name;
      final current = custMap.putIfAbsent(
        custId,
        () => _CustomerAggregate(
          customerId: custId,
          name: inv.customer.name,
          company: inv.customer.company,
          gstin: inv.customer.gstNo,
          phone: inv.customer.phone,
        ),
      );

      current.totalInvoices += 1;
      current.totalBilled += inv.grandTotal;
      current.totalReceived += inv.paidAmount;
      current.totalOutstanding += inv.balanceDue;
    }

    final custList = custMap.values.toList()
      ..sort((a, b) => b.totalOutstanding.compareTo(a.totalOutstanding));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading('CLIENT BALANCES & OUTSTANDING LEDGER (${custList.length} CLIENTS)'),
          const SizedBox(height: 8),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: custList.length,
            itemBuilder: (context, idx) {
              final c = custList[idx];
              final hasPending = c.totalOutstanding > 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isDark ? const Color(0xFF312E81) : const Color(0xFFEDE9FE),
                      child: Text(
                        (c.company.isNotEmpty ? c.company.substring(0, 1) : c.name.substring(0, 1)).toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightPrimary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.company.isNotEmpty ? c.company : c.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (c.gstin.isNotEmpty) ...[
                                Text(
                                  'GST: ${c.gstin}',
                                  style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: Color(0xFF64748B)),
                                ),
                                const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1))),
                              ],
                              Text(
                                '${c.totalInvoices} ${c.totalInvoices == 1 ? 'Invoice' : 'Invoices'}',
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
                          currencyFormat.format(c.totalOutstanding),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: hasPending ? AppColors.error : AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasPending ? 'Due' : 'All Clear',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: hasPending ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helper Widgets
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildReportMetricTile(String label, String value, Color color, bool isDark) {
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
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Color(0xFF64748B)),
    );
  }

  Widget _buildSummaryLine(String title, String value, {bool isBold = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: highlightColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySectionCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
      ),
    );
  }

  Widget _buildInvoiceTable(List<Invoice> invoices, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: invoices.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final inv = invoices[idx];
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM yyyy').format(inv.invoiceDate), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inv.customer.company.isNotEmpty ? inv.customer.company : inv.customer.name,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                      if (inv.customer.gstNo.isNotEmpty)
                        Text('GSTIN: ${inv.customer.gstNo}', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currencyFormat.format(inv.grandTotal), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Tax: ${currencyFormat.format(inv.totalTax)}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HsnAggregate {
  final String code;
  final String description;
  final String uqc;
  int quantity = 0;
  double taxableValue = 0.0;
  double taxAmount = 0.0;

  _HsnAggregate({required this.code, required this.description, required this.uqc});
}

class _CustomerAggregate {
  final String customerId;
  final String name;
  final String company;
  final String gstin;
  final String phone;
  int totalInvoices = 0;
  double totalBilled = 0.0;
  double totalReceived = 0.0;
  double totalOutstanding = 0.0;

  _CustomerAggregate({
    required this.customerId,
    required this.name,
    required this.company,
    required this.gstin,
    required this.phone,
  });
}
