import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../models/proforma_invoice.dart';
import '../providers/proforma_invoice_provider.dart';

class ProformaInvoicesListScreen extends StatefulWidget {
  const ProformaInvoicesListScreen({super.key});

  @override
  State<ProformaInvoicesListScreen> createState() => _ProformaInvoicesListScreenState();
}

class _ProformaInvoicesListScreenState extends State<ProformaInvoicesListScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy');

  final List<String> _statusFilters = ['All', 'Draft', 'Sent', 'Invoiced', 'Expired', 'Approved', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProformaInvoiceProvider>().fetchProformaInvoices();
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
    final provider = context.watch<ProformaInvoiceProvider>();
    final proformas = provider.filteredProformaInvoices;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Proforma Invoices',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        actions: [
          IconButton(
            onPressed: () => provider.fetchProformaInvoices(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/sales/proforma-invoices/create'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Proforma', style: TextStyle(fontWeight: FontWeight.bold)),
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
            onRefresh: () => provider.fetchProformaInvoices(refresh: true),
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
                      if (provider.isLoading && provider.proformaInvoices.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (proformas.isEmpty)
                        _buildEmptyState(provider, isDark)
                      else if (isWide)
                        _buildWideTable(proformas, provider, isDark)
                      else
                        _buildMobileCardsList(proformas, provider, isDark),
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

  Widget _buildFilterBar(ProformaInvoiceProvider provider, bool isDark) {
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
                    hintText: 'Search by proforma #, client name, ref #, salesperson...',
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

  Widget _buildWideTable(List<ProformaInvoice> proformas, ProformaInvoiceProvider provider, bool isDark) {
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
                Expanded(flex: 15, child: Text('PROFORMA #', style: _headerStyle)),
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
            itemCount: proformas.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: cardBorder),
            itemBuilder: (ctx, idx) {
              final p = proformas[idx];
              return InkWell(
                onTap: () => context.push('/sales/proforma-invoices/edit/${p.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 15,
                        child: Text(
                          p.proformaNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED)),
                        ),
                      ),
                      Expanded(
                        flex: 25,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.businessName.isNotEmpty ? p.businessName : 'Unknown Client',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            if (p.mobileNumber.isNotEmpty)
                              Text(p.mobileNumber, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 15,
                        child: Text(_dateFormat.format(p.proformaDate), style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        flex: 15,
                        child: Text(_dateFormat.format(p.dueDate), style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        flex: 15,
                        child: Text(
                          _currencyFormat.format(p.grandTotal),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 15,
                        child: Center(child: _buildStatusBadge(p.status)),
                      ),
                      SizedBox(
                        width: 48,
                        child: _buildActionMenu(p, provider),
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

  Widget _buildMobileCardsList(List<ProformaInvoice> proformas, ProformaInvoiceProvider provider, bool isDark) {
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: proformas.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) {
            final p = proformas[idx];
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
                        p.proformaNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF7C3AED)),
                      ),
                      _buildStatusBadge(p.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.businessName.isNotEmpty ? p.businessName : 'Unknown Client',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${_dateFormat.format(p.proformaDate)} • Valid Until: ${_dateFormat.format(p.dueDate)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currencyFormat.format(p.grandTotal),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => context.push('/sales/proforma-invoices/edit/${p.id}'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Edit', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          _buildActionMenu(p, provider),
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

  Widget _buildPaginationFooter(ProformaInvoiceProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            provider.totalCount > 0
                ? 'Showing ${provider.proformaInvoices.length} of ${provider.totalCount} items'
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

  Widget _buildActionMenu(ProformaInvoice p, ProformaInvoiceProvider provider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (action) async {
        switch (action) {
          case 'edit':
            context.push('/sales/proforma-invoices/edit/${p.id}');
            break;
          case 'convert':
            final result = await provider.convertToInvoice(p.id);
            if (!mounted) return;
            if (result != null) {
              final invNum = result['invoice_number'] ?? 'Invoice';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Proforma ${p.proformaNumber} converted to Final Sales Invoice $invNum!'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage ?? 'Failed to convert to invoice'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            break;
          case 'sent':
            final okSent = await provider.updateStatus(p.id, ProformaStatus.sent);
            if (!mounted) return;
            if (!okSent && provider.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!), backgroundColor: AppColors.error));
            }
            break;
          case 'approve':
            final okApprove = await provider.updateStatus(p.id, ProformaStatus.approved);
            if (!mounted) return;
            if (!okApprove && provider.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!), backgroundColor: AppColors.error));
            }
            break;
          case 'cancel':
            final okCancel = await provider.updateStatus(p.id, ProformaStatus.cancelled);
            if (!mounted) return;
            if (!okCancel && provider.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!), backgroundColor: AppColors.error));
            }
            break;
          case 'restore':
            final okRestore = await provider.restoreProformaInvoice(p.id);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(okRestore ? 'Proforma invoice restored successfully' : (provider.errorMessage ?? 'Failed to restore')),
                backgroundColor: okRestore ? AppColors.success : AppColors.error,
              ),
            );
            break;
          case 'delete':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Proforma Invoice?'),
                content: Text('Are you sure you want to delete ${p.proformaNumber}? This will soft-delete the record.'),
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
              final ok = await provider.deleteProformaInvoice(p.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Proforma invoice deleted successfully' : (provider.errorMessage ?? 'Failed to delete')),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ),
              );
            }
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
        if (p.status != ProformaStatus.invoiced)
          const PopupMenuItem(value: 'convert', child: Row(children: [Icon(Icons.transform_rounded, size: 16, color: Color(0xFF7C3AED)), SizedBox(width: 8), Text('Convert to Final Invoice')])),
        if (p.status != ProformaStatus.sent)
          const PopupMenuItem(value: 'sent', child: Row(children: [Icon(Icons.send_outlined, size: 16, color: Color(0xFF2563EB)), SizedBox(width: 8), Text('Mark as Sent')])),
        if (p.status != ProformaStatus.approved)
          const PopupMenuItem(value: 'approve', child: Row(children: [Icon(Icons.check_circle_outline, size: 16, color: AppColors.success), SizedBox(width: 8), Text('Mark as Approved')])),
        if (p.status != ProformaStatus.cancelled)
          const PopupMenuItem(value: 'cancel', child: Row(children: [Icon(Icons.cancel_outlined, size: 16, color: AppColors.warning), SizedBox(width: 8), Text('Mark as Cancelled')])),
        if (p.isDeleted)
          const PopupMenuItem(value: 'restore', child: Row(children: [Icon(Icons.restore_from_trash_outlined, size: 16, color: AppColors.success), SizedBox(width: 8), Text('Restore Proforma')])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
      ],
    );
  }

  Widget _buildStatusBadge(ProformaStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case ProformaStatus.draft:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF4B5563);
        break;
      case ProformaStatus.sent:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        break;
      case ProformaStatus.invoiced:
        bg = const Color(0xFFF5F3FF);
        fg = const Color(0xFF7C3AED);
        break;
      case ProformaStatus.expired:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        break;
      case ProformaStatus.approved:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        break;
      case ProformaStatus.cancelled:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
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

  Widget _buildEmptyState(ProformaInvoiceProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            provider.searchQuery.isNotEmpty || provider.statusFilter != 'All'
                ? 'No matching proforma invoices found'
                : 'No Proforma Invoices Yet',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            provider.searchQuery.isNotEmpty || provider.statusFilter != 'All'
                ? 'Try adjusting your search criteria or filters.'
                : 'Create preliminary proforma invoices to send clients before product delivery or formal invoicing.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/sales/proforma-invoices/create'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Proforma Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Color(0xFF6B7280),
    letterSpacing: 0.5,
  );
}
