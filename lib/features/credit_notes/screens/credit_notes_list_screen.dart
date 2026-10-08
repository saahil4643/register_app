import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../models/credit_note.dart';
import '../providers/credit_note_provider.dart';

class CreditNotesListScreen extends StatefulWidget {
  const CreditNotesListScreen({super.key});

  @override
  State<CreditNotesListScreen> createState() => _CreditNotesListScreenState();
}

class _CreditNotesListScreenState extends State<CreditNotesListScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy');

  final List<String> _statusFilters = [
    'All',
    'Open',
    'Partially Applied',
    'Refunded',
    'Closed',
    'Draft'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreditNoteProvider>().fetchCreditNotes();
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
    final provider = context.watch<CreditNoteProvider>();
    final creditNotes = provider.filteredCreditNotes;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Credit Notes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        actions: [
          IconButton(
            onPressed: () => provider.fetchCreditNotes(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/sales/credit-notes/create'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Credit Note', style: TextStyle(fontWeight: FontWeight.bold)),
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
            onRefresh: () => provider.fetchCreditNotes(refresh: true),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Filter Bar (Search + Status Chips) - No KPI cards on top as requested
                      _buildFilterBar(provider, isDark),
                      const SizedBox(height: 16),

                      // Table or List
                      if (provider.isLoading && provider.creditNotes.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (creditNotes.isEmpty)
                        _buildEmptyState(provider, isDark)
                      else if (isWide)
                        _buildWideTable(creditNotes, provider, isDark)
                      else
                        _buildMobileCardsList(creditNotes, provider, isDark),
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

  Widget _buildFilterBar(CreditNoteProvider provider, bool isDark) {
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
                    hintText: 'Search by credit note #, customer name, invoice #, reason...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('', immediate: true);
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
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final initialRange = (provider.startDate != null && provider.endDate != null)
                      ? DateTimeRange(start: provider.startDate!, end: provider.endDate!)
                      : null;
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    initialDateRange: initialRange,
                  );
                  if (picked != null) {
                    provider.setDateRange(picked.start, picked.end);
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  provider.startDate != null && provider.endDate != null
                      ? '${DateFormat('dd/MM').format(provider.startDate!)} - ${DateFormat('dd/MM').format(provider.endDate!)}'
                      : 'Date Filter',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (provider.startDate != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear Date Filter',
                  onPressed: () => provider.clearDateRange(),
                ),
              ],
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

  Widget _buildWideTable(List<CreditNote> creditNotes, CreditNoteProvider provider, bool isDark) {
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
                Expanded(flex: 15, child: Text('CREDIT NOTE #', style: _headerStyle)),
                Expanded(flex: 22, child: Text('CUSTOMER', style: _headerStyle)),
                Expanded(flex: 14, child: Text('DATE', style: _headerStyle)),
                Expanded(flex: 16, child: Text('REF INVOICE', style: _headerStyle)),
                Expanded(flex: 15, child: Text('AMOUNT', textAlign: TextAlign.right, style: _headerStyle)),
                Expanded(flex: 18, child: Text('STATUS', textAlign: TextAlign.center, style: _headerStyle)),
                SizedBox(width: 48), // Action menu
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: creditNotes.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: cardBorder),
            itemBuilder: (ctx, idx) {
              final cn = creditNotes[idx];
              return InkWell(
                onTap: () => context.push('/sales/credit-notes/edit/${cn.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 15,
                        child: Text(
                          cn.creditNoteNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED)),
                        ),
                      ),
                      Expanded(
                        flex: 22,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cn.customerName.isNotEmpty ? cn.customerName : 'Unknown Client',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            if (cn.reason.isNotEmpty)
                              Text(cn.reason, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 14,
                        child: Text(_dateFormat.format(cn.creditNoteDate), style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        flex: 16,
                        child: Text(
                          cn.referenceInvoice.isNotEmpty ? cn.referenceInvoice : '—',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        flex: 15,
                        child: Text(
                          '- ${_currencyFormat.format(cn.totalAmount)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFFDC2626), // Red amount
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 18,
                        child: Center(child: _buildStatusBadge(cn.status)),
                      ),
                      SizedBox(
                        width: 48,
                        child: _buildActionMenu(cn, provider),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Divider(height: 1, color: cardBorder),
          _buildPaginationFooter(provider, isDark),
        ],
      ),
    );
  }

  Widget _buildMobileCardsList(List<CreditNote> creditNotes, CreditNoteProvider provider, bool isDark) {
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: creditNotes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) {
            final cn = creditNotes[idx];
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
                        cn.creditNoteNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF7C3AED)),
                      ),
                      _buildStatusBadge(cn.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cn.customerName.isNotEmpty ? cn.customerName : 'Unknown Client',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${_dateFormat.format(cn.creditNoteDate)}${cn.referenceInvoice.isNotEmpty ? ' • Ref: ${cn.referenceInvoice}' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '- ${_currencyFormat.format(cn.totalAmount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => context.push('/sales/credit-notes/edit/${cn.id}'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Edit', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          _buildActionMenu(cn, provider),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder),
          ),
          child: _buildPaginationFooter(provider, isDark),
        ),
      ],
    );
  }

  Widget _buildPaginationFooter(CreditNoteProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            provider.totalCount > 0
                ? 'Showing ${provider.creditNotes.length} of ${provider.totalCount} items'
                : 'No items',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: provider.hasPreviousPage
                    ? () => provider.goToPage(provider.currentPage - 1)
                    : null,
                tooltip: 'Previous Page',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Page ${provider.currentPage} of ${provider.totalPages > 0 ? provider.totalPages : 1}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: provider.hasNextPage
                    ? () => provider.goToPage(provider.currentPage + 1)
                    : null,
                tooltip: 'Next Page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenu(CreditNote cn, CreditNoteProvider provider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (action) async {
        switch (action) {
          case 'edit':
            context.push('/sales/credit-notes/edit/${cn.id}');
            break;
          case 'open':
            final successOpen = await provider.updateStatus(cn.id, CreditNoteStatus.open);
            if (!mounted) return;
            if (!successOpen && provider.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!), backgroundColor: AppColors.error));
            }
            break;
          case 'close':
            final successClose = await provider.updateStatus(cn.id, CreditNoteStatus.closed);
            if (!mounted) return;
            if (!successClose && provider.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!), backgroundColor: AppColors.error));
            }
            break;
          case 'refund':
            final successRefund = await provider.updateStatus(cn.id, CreditNoteStatus.refunded);
            if (!mounted) return;
            if (!successRefund && provider.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!), backgroundColor: AppColors.error));
            }
            break;
          case 'restore':
            final successRestore = await provider.restoreCreditNote(cn.id);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successRestore ? 'Credit note restored successfully' : (provider.errorMessage ?? 'Failed to restore')),
                backgroundColor: successRestore ? AppColors.success : AppColors.error,
              ),
            );
            break;
          case 'delete':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Credit Note?'),
                content: Text('Are you sure you want to delete ${cn.creditNoteNumber}? This will soft-delete the record.'),
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
              final ok = await provider.deleteCreditNote(cn.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Credit note deleted successfully' : (provider.errorMessage ?? 'Failed to delete')),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ),
              );
            }
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
        if (cn.status != CreditNoteStatus.open)
          const PopupMenuItem(value: 'open', child: Row(children: [Icon(Icons.lock_open_outlined, size: 16, color: Color(0xFF2563EB)), SizedBox(width: 8), Text('Mark as Open')])),
        if (cn.status != CreditNoteStatus.closed)
          const PopupMenuItem(value: 'close', child: Row(children: [Icon(Icons.check_circle_outline, size: 16, color: AppColors.success), SizedBox(width: 8), Text('Mark as Closed')])),
        if (cn.status != CreditNoteStatus.refunded)
          const PopupMenuItem(value: 'refund', child: Row(children: [Icon(Icons.monetization_on_outlined, size: 16, color: Color(0xFF7C3AED)), SizedBox(width: 8), Text('Mark as Refunded')])),
        if (cn.isDeleted)
          const PopupMenuItem(value: 'restore', child: Row(children: [Icon(Icons.restore_from_trash_outlined, size: 16, color: AppColors.success), SizedBox(width: 8), Text('Restore Credit Note')])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
      ],
    );
  }

  Widget _buildStatusBadge(CreditNoteStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case CreditNoteStatus.open:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        break;
      case CreditNoteStatus.partiallyApplied:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        break;
      case CreditNoteStatus.refunded:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        break;
      case CreditNoteStatus.closed:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF4B5563);
        break;
      case CreditNoteStatus.draft:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF9CA3AF);
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

  Widget _buildEmptyState(CreditNoteProvider provider, bool isDark) {
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
              child: const Icon(Icons.assignment_return_rounded, size: 48, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Credit Notes Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              provider.searchQuery.isNotEmpty || provider.statusFilter != 'All'
                  ? 'No credit notes matching your search or filters.'
                  : 'Create credit notes to manage customer returns, pricing adjustments, or sales allowances.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.push('/sales/credit-notes/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create First Credit Note'),
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

