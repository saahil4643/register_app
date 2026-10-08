import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/purchase_order.dart';
import '../providers/purchase_order_provider.dart';

class PurchaseOrdersListScreen extends StatefulWidget {
  const PurchaseOrdersListScreen({super.key});

  @override
  State<PurchaseOrdersListScreen> createState() => _PurchaseOrdersListScreenState();
}

class _PurchaseOrdersListScreenState extends State<PurchaseOrdersListScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = [
    'All',
    'Draft',
    'Pending',
    'Approved',
    'Billed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseOrderProvider>().fetchOrders();
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Purchase Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => context.read<PurchaseOrderProvider>().fetchOrders(refresh: true),
          ),
        ],
      ),
      body: Consumer<PurchaseOrderProvider>(
        builder: (context, provider, _) {
          final orders = provider.filteredOrders;

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    provider.setSearchQuery(val);
                  },
                  onSubmitted: (_) {
                    provider.fetchOrders(refresh: true);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by PO #, vendor, reference, category...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                              provider.fetchOrders(refresh: true);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
              ),

              // Status Filter Chips
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _statusFilters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final filter = _statusFilters[i];
                    final isSelected = provider.statusFilter.toLowerCase() == filter.toLowerCase();

                    return ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          provider.setStatusFilter(filter);
                          provider.fetchOrders(refresh: true);
                        }
                      },
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                      selectedColor: const Color(0xFF6D28D9),
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // List of POs
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : orders.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 64,
                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    provider.errorMessage != null
                                        ? 'Could not load purchase orders'
                                        : (provider.searchQuery.isNotEmpty || provider.statusFilter != 'All'
                                            ? 'No purchase orders matching filters'
                                            : 'No purchase orders created yet'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    provider.errorMessage != null
                                        ? provider.errorMessage!
                                        : 'Create purchase orders to procure materials and services from suppliers.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white38 : const Color(0xFF64748B),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (provider.errorMessage != null) ...[
                                        OutlinedButton.icon(
                                          onPressed: () => provider.fetchOrders(refresh: true),
                                          icon: const Icon(Icons.refresh_rounded, size: 18),
                                          label: const Text('Retry'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      ElevatedButton.icon(
                                        onPressed: () => context.push('/purchases/purchase-orders/new'),
                                        icon: const Icon(Icons.add_rounded),
                                        label: const Text('New Purchase Order'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6D28D9),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: orders.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return _PurchaseOrderCard(order: order);
                            },
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/purchases/purchase-orders/new'),
        backgroundColor: const Color(0xFF6D28D9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New PO', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;

  const _PurchaseOrderCard({required this.order});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF10B981);
      case 'BILLED':
        return const Color(0xFF6366F1);
      case 'PENDING':
      case 'ORDERED':
        return const Color(0xFFF59E0B);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      case 'DRAFT':
      default:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _showConvertToBillDialog(BuildContext context, PurchaseOrder order) async {
    final billController = TextEditingController(
      text: 'BILL-${order.poNumber.replaceAll(RegExp(r'[^0-9]'), '')}',
    );

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convert PO to Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convert purchase order ${order.poNumber} directly into an Accounts Payable Bill.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: billController,
              decoration: const InputDecoration(
                labelText: 'Bill Number (Optional)',
                hintText: 'e.g. BILL-2026-001',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Convert to Bill'),
          ),
        ],
      ),
    );

    if (proceed == true && context.mounted) {
      final provider = context.read<PurchaseOrderProvider>();
      final billNum = billController.text.trim();
      final targetId = order.id.isNotEmpty ? order.id : order.poNumber;
      await provider.convertToBill(targetId, billNumber: billNum.isNotEmpty ? billNum : null);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${order.poNumber} converted to Bill successfully!'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'View Bills',
              textColor: Colors.white,
              onPressed: () => context.push('/purchases/bills'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateDisplay = DateFormat('dd MMM yyyy').format(order.purchaseDate);
    final statusColor = _getStatusColor(order.status);
    final targetId = order.id.isNotEmpty ? order.id : order.poNumber;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.push('/purchases/purchase-orders/edit', extra: order);
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: PO # & Status Badge & Popup Menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.poNumber,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6D28D9),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            PurchaseOrder.displayStatus(order.status).toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if (order.convertedBillId != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BILLED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        if (order.status.toUpperCase() == 'APPROVED' && order.convertedBillId == null)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.transform_rounded, size: 16),
                            label: const Text('Convert to Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _showConvertToBillDialog(context, order),
                          ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          onSelected: (val) async {
                            final provider = context.read<PurchaseOrderProvider>();
                            if (val == 'edit') {
                              context.push('/purchases/purchase-orders/edit', extra: order);
                            } else if (val == 'convert_to_bill') {
                              await _showConvertToBillDialog(context, order);
                            } else if (val == 'mark_approved') {
                              await provider.updateOrderStatus(targetId, 'APPROVED');
                            } else if (val == 'mark_draft') {
                              await provider.updateOrderStatus(targetId, 'DRAFT');
                            } else if (val == 'cancel') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Cancel Purchase Order?'),
                                  content: Text('Are you sure you want to cancel ${order.poNumber}? You can restore it later.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('No'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                      child: const Text('Cancel PO'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await provider.cancelOrder(targetId);
                              }
                            } else if (val == 'restore') {
                              await provider.restoreOrder(targetId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${order.poNumber} restored successfully!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } else if (val == 'permanent_delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Permanently Delete PO?'),
                                  content: Text('Are you sure you want to permanently delete ${order.poNumber}? This cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                      child: const Text('Delete Permanently'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await provider.permanentDeleteOrder(targetId);
                              }
                            }
                          },
                          itemBuilder: (ctx) {
                            final isCancelled = order.status.toUpperCase() == 'CANCELLED';
                            final isApproved = order.status.toUpperCase() == 'APPROVED';
                            final isBilled = order.status.toUpperCase() == 'BILLED';

                            return [
                              const PopupMenuItem(value: 'edit', child: Text('Edit Order')),
                              if (!isApproved && !isBilled && !isCancelled)
                                const PopupMenuItem(value: 'mark_approved', child: Text('Approve Order')),
                              if (order.status.toUpperCase() != 'DRAFT' && !isBilled && !isCancelled)
                                const PopupMenuItem(value: 'mark_draft', child: Text('Mark as Draft')),
                              if (!isBilled && !isCancelled)
                                const PopupMenuItem(value: 'convert_to_bill', child: Text('Convert to Bill')),
                              if (isCancelled)
                                const PopupMenuItem(
                                  value: 'restore',
                                  child: Text('Restore Order', style: TextStyle(color: Color(0xFF10B981))),
                                ),
                              if (!isCancelled)
                                const PopupMenuItem(
                                  value: 'cancel',
                                  child: Text('Cancel Order', style: TextStyle(color: Color(0xFFF59E0B))),
                                ),
                              const PopupMenuItem(
                                value: 'permanent_delete',
                                child: Text('Permanently Delete', style: TextStyle(color: Color(0xFFEF4444))),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Vendor Name & Amount
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.vendorName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Amount
                    Text(
                      currency.format(order.totalAmount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Category & Date & Items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.items.isNotEmpty
                          ? '${order.category} • ${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}'
                          : order.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : const Color(0xFF64748B),
                      ),
                    ),
                    Row(
                      children: [
                        if (order.referenceNumber.isNotEmpty) ...[
                          Text(
                            'Ref: ${order.referenceNumber} • ',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                        Text(
                          dateDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
  }
}

