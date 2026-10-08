import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../models/quotation.dart';
import '../providers/quotation_provider.dart';

class QuotationsListScreen extends StatefulWidget {
  const QuotationsListScreen({super.key});

  @override
  State<QuotationsListScreen> createState() => _QuotationsListScreenState();
}

class _QuotationsListScreenState extends State<QuotationsListScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy');

  final List<String> _statusFilters = ['All', 'Draft', 'Sent', 'Accepted', 'Rejected', 'Expired', 'Converted'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuotationProvider>().fetchQuotations();
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
    final provider = context.watch<QuotationProvider>();
    final quotations = provider.filteredQuotations;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Quotations & Estimates',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        actions: [
          IconButton(
            onPressed: () => provider.fetchQuotations(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/sales/quotations/create'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Estimate', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB), height: 1.0),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return RefreshIndicator(
            onRefresh: () => provider.fetchQuotations(refresh: true),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Filter Bar (Search + Status Chips)
                      _buildFilterBar(provider, isDark),
                      const SizedBox(height: 16),

                      // Table or List
                      if (provider.isLoading && provider.quotations.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (quotations.isEmpty)
                        _buildEmptyState(provider, isDark)
                      else if (isWide)
                        _buildWideTable(quotations, provider, isDark)
                      else
                        _buildMobileCardsList(quotations, provider, isDark),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildFilterBar(QuotationProvider provider, bool isDark) {
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by estimate #, client name, ref #, salesperson...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => provider.setSearchQuery(val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((s) {
                final isSelected = provider.statusFilter.toLowerCase() == s.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(s, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFF7C3AED),
                    onSelected: (_) => provider.setStatusFilter(s),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideTable(List<Quotation> quotations, QuotationProvider provider, bool isDark) {
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Row(
              children: [
                Expanded(flex: 15, child: Text('ESTIMATE #', style: _headerStyle)),
                Expanded(flex: 25, child: Text('CLIENT / BUSINESS', style: _headerStyle)),
                Expanded(flex: 15, child: Text('DATE', style: _headerStyle)),
                Expanded(flex: 15, child: Text('VALID UNTIL', style: _headerStyle)),
                Expanded(flex: 15, child: Text('AMOUNT', textAlign: TextAlign.right, style: _headerStyle)),
                Expanded(flex: 15, child: Text('STATUS', textAlign: TextAlign.center, style: _headerStyle)),
                SizedBox(width: 48), // Action menu
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quotations.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: cardBorder),
            itemBuilder: (ctx, idx) {
              final q = quotations[idx];
              return InkWell(
                onTap: () => context.push('/sales/quotations/edit/${q.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 15,
                        child: Text(
                          q.quotationNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED)),
                        ),
                      ),
                      Expanded(
                        flex: 25,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.businessName.isNotEmpty ? q.businessName : 'Unknown Client',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            if (q.mobileNumber.isNotEmpty)
                              Text(q.mobileNumber, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 15,
                        child: Text(_dateFormat.format(q.quotationDate), style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        flex: 15,
                        child: Text(_dateFormat.format(q.expiryDate), style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        flex: 15,
                        child: Text(
                          _currencyFormat.format(q.grandTotal),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 15,
                        child: Center(child: _buildStatusBadge(q.status)),
                      ),
                      SizedBox(
                        width: 48,
                        child: _buildActionMenu(q, provider),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCardsList(List<Quotation> quotations, QuotationProvider provider, bool isDark) {
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: quotations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final q = quotations[idx];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    q.quotationNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF7C3AED)),
                  ),
                  _buildStatusBadge(q.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                q.businessName.isNotEmpty ? q.businessName : 'Unknown Client',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'Date: ${_dateFormat.format(q.quotationDate)} • Valid Until: ${_dateFormat.format(q.expiryDate)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currencyFormat.format(q.grandTotal),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => context.push('/sales/quotations/edit/${q.id}'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Edit', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      _buildActionMenu(q, provider),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionMenu(Quotation q, QuotationProvider provider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (action) async {
        switch (action) {
          case 'edit':
            context.push('/sales/quotations/edit/${q.id}');
            break;
          case 'convert':
            final res = await provider.convertToInvoice(q, context);
            if (mounted) {
              if (res['success'] == true) {
                final invNum = res['invoice_number'];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(invNum != null
                        ? 'Estimate ${q.quotationNumber} converted to Invoice $invNum!'
                        : 'Estimate ${q.quotationNumber} converted to Invoice draft!'),
                    backgroundColor: AppColors.success,
                    action: SnackBarAction(
                      label: 'View Invoices',
                      textColor: Colors.white,
                      onPressed: () => context.push('/invoices/create'),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['error'] ?? provider.errorMessage ?? 'Failed to convert'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
            break;
          case 'accept':
            await provider.updateStatus(q.id, QuotationStatus.accepted);
            break;
          case 'reject':
            await provider.updateStatus(q.id, QuotationStatus.rejected);
            break;
          case 'delete':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Estimate?'),
                content: Text('Are you sure you want to delete ${q.quotationNumber}? This action can be restored later.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await provider.deleteQuotation(q.id);
            }
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
        const PopupMenuItem(value: 'convert', child: Row(children: [Icon(Icons.transform_rounded, size: 16, color: Color(0xFF7C3AED)), SizedBox(width: 8), Text('Convert to Invoice')])),
        const PopupMenuItem(value: 'accept', child: Row(children: [Icon(Icons.check_circle_outline, size: 16, color: AppColors.success), SizedBox(width: 8), Text('Mark as Accepted')])),
        const PopupMenuItem(value: 'reject', child: Row(children: [Icon(Icons.cancel_outlined, size: 16, color: AppColors.warning), SizedBox(width: 8), Text('Mark as Rejected')])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
      ],
    );
  }

  Widget _buildStatusBadge(QuotationStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case QuotationStatus.draft:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF4B5563);
        break;
      case QuotationStatus.sent:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        break;
      case QuotationStatus.accepted:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        break;
      case QuotationStatus.rejected:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        break;
      case QuotationStatus.expired:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        break;
      case QuotationStatus.converted:
        bg = const Color(0xFFF5F3FF);
        fg = const Color(0xFF7C3AED);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(QuotationProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.request_quote_rounded, size: 48, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Quotations Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              provider.searchQuery.isNotEmpty || provider.statusFilter != 'All'
                  ? 'No quotations matching your search or filters.'
                  : 'Start sending estimates and proposals to your clients to win deals faster.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.push('/sales/quotations/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create First Estimate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



const TextStyle _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.bold,
  letterSpacing: 0.5,
  color: Color(0xFF6B7280),
);
