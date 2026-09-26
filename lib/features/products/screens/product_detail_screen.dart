import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_cards.dart';
import '../../../core/widgets/custom_states.dart';
import '../../invoices/providers/invoice_provider.dart';
import '../../invoices/models/invoice.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../../customers/screens/customer_detail_screen.dart';
import 'create_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProductDetails(widget.productId);
    });
  }

  void _confirmDeleteProduct(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}? This will archive the record.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<ProductProvider>().deleteProduct(product.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted successfully')),
                );
                Navigator.pop(context);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.read<ProductProvider>().errorMessage ?? 'Failed to delete product')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<InvoiceProvider>();
    final productProvider = context.watch<ProductProvider>();

    // Find the product
    final product = productProvider.selectedProductDetails ?? provider.products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => Product(
        id: '',
        name: '',
        sku: '',
        barcode: '',
        category: '',
        brand: '',
        purchasePrice: 0.0,
        sellingPrice: 0.0,
        stock: 0,
        minStock: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (product.id.isEmpty && productProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (product.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const ErrorState(message: 'Product not found in inventory catalog.'),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Calculate Product Statistics
    final unitsSold = provider.getQuantitySoldForProduct(product.id);
    final revenue = provider.getRevenueForProduct(product.id);
    final customersCount = provider.getCustomersWhoBoughtProduct(product.id).length;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280.0,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? AppColors.darkSurface : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _confirmDeleteProduct(context, product),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () async {
                    final updated = await Navigator.push<Product>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateProductScreen(product: product),
                      ),
                    );
                    if (updated != null) {
                      setState(() {});
                    }
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (val) async {
                    final provider = context.read<ProductProvider>();
                    if (val == 'activate') {
                      final ok = await provider.activateProduct(product.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Product activated' : (provider.errorMessage ?? 'Failed to activate'))),
                        );
                      }
                    } else if (val == 'deactivate') {
                      final ok = await provider.deactivateProduct(product.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Product deactivated' : (provider.errorMessage ?? 'Failed to deactivate'))),
                        );
                      }
                    } else if (val == 'restore') {
                      final ok = await provider.restoreProduct(product.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Product restored' : (provider.errorMessage ?? 'Failed to restore'))),
                        );
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!product.isActive)
                      const PopupMenuItem(value: 'activate', child: Text('Activate Product'))
                    else
                      const PopupMenuItem(value: 'deactivate', child: Text('Deactivate Product')),
                    const PopupMenuItem(value: 'restore', child: Text('Restore Product')),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      // Product Image Mock
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          product.category == 'Services' || product.category == 'Consulting'
                              ? Icons.computer_rounded
                              : Icons.inventory_2_rounded,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        product.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'SKU: ${product.sku} • Brand: ${product.brand.isNotEmpty ? product.brand : "Generic"}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stock & Selling Price Headers
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${product.stock} Pcs',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: product.stock <= product.minStock ? AppColors.error : AppColors.success,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Available Stock',
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
                                  currencyFormat.format(product.sellingPrice),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Selling Price',
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
                    Tab(text: 'Stock History'),
                    Tab(text: 'Sales History'),
                    Tab(text: 'Buyers'),
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
            _buildOverviewTab(context, product, unitsSold, revenue, customersCount, currencyFormat),
            _buildStockHistoryTab(context, provider, product),
            _buildSalesTab(context, provider, product, currencyFormat),
            _buildBuyersTab(context, provider, product),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    Product product,
    int unitsSold,
    double revenue,
    int customersCount,
    NumberFormat currencyFormat,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics section
          Text(
            'Performance Statistics',
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
              _buildStatTile(context, 'Units Sold', unitsSold.toString(), Icons.shopping_basket_rounded),
              _buildStatTile(context, 'Revenue Generated', currencyFormat.format(revenue), Icons.monetization_on_outlined, color: AppColors.success),
              _buildStatTile(context, 'Unique Buyers', customersCount.toString(), Icons.people_outline_rounded),
              _buildStatTile(context, 'Margin Rate', product.sellingPrice > 0 ? '${((product.sellingPrice - product.purchasePrice) / product.sellingPrice * 100).toStringAsFixed(1)}%' : '0%', Icons.trending_up_rounded, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 20),

          // Product Details Card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Catalog Properties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Divider(height: 20),
                  _buildDetailRow('Category', product.category),
                  const SizedBox(height: 8),
                  _buildDetailRow('Brand', product.brand.isNotEmpty ? product.brand : 'Generic'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Barcode', product.barcode.isNotEmpty ? product.barcode : 'N/A'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Purchase Price', currencyFormat.format(product.purchasePrice)),
                  const SizedBox(height: 8),
                  _buildDetailRow('Selling Price', currencyFormat.format(product.sellingPrice)),
                  const SizedBox(height: 8),
                  _buildDetailRow('GST Rate', '${product.gst}%'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Min Stock Warning', '${product.minStock} Pcs'),
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
          width: 120,
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

  Widget _buildStockHistoryTab(BuildContext context, InvoiceProvider provider, Product product) {
    // Generate chronological stock movements based on invoices
    final productInvoices = provider.invoices
        .where((inv) => inv.status != InvoiceStatus.draft && inv.status != InvoiceStatus.cancelled && inv.items.any((item) => item.product.id == product.id))
        .toList()
      ..sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate)); // Chronological order (oldest first)

    final List<Map<String, dynamic>> stockHistory = [];

    // Working variables to reconstruct historical stock levels
    int runningBalance = product.stock;

    // Build history backwards since we know the current stock level
    for (final inv in productInvoices.reversed) {
      final qtySold = inv.items.firstWhere((item) => item.product.id == product.id).quantity;
      stockHistory.add({
        'date': inv.invoiceDate,
        'action': 'Removed',
        'qty': qtySold,
        'balance': runningBalance,
        'reason': 'Invoice Sold (${inv.invoiceNumber})',
      });
      runningBalance += qtySold; // Historical balance before sale
    }

    // Add initial setup stock
    stockHistory.add({
      'date': product.createdAt,
      'action': 'Added',
      'qty': runningBalance,
      'balance': runningBalance,
      'reason': 'Initial Stock Config',
    });

    // Reverse list back to show newest first
    final displayedHistory = stockHistory.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: displayedHistory.length,
      itemBuilder: (context, index) {
        final movement = displayedHistory[index];
        final isAdded = movement['action'] == 'Added';
        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(movement['date'] as DateTime);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAdded ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
              child: Icon(
                isAdded ? Icons.add_rounded : Icons.remove_rounded,
                color: isAdded ? AppColors.success : AppColors.error,
              ),
            ),
            title: Text(
              movement['reason'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isAdded ? "+" : "-"}${movement['qty']} Pcs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAdded ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  'Bal: ${movement['balance']} Pcs',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalesTab(BuildContext context, InvoiceProvider provider, Product product, NumberFormat currencyFormat) {
    final invoices = provider.getInvoicesForProduct(product.id);

    if (invoices.isEmpty) {
      return const EmptyState(
        title: 'No Sales History',
        description: 'Sales for this product from completed invoices will appear here.',
        icon: Icons.monetization_on_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final inv = invoices[index];
        final item = inv.items.firstWhere((i) => i.product.id == product.id);

        return ListCard(
          title: inv.invoiceNumber,
          subtitle: 'Client: ${inv.customer.company} • Qty: ${item.quantity}',
          amount: currencyFormat.format(item.total),
          statusWidget: StatusChip(
            label: inv.status.displayName,
            color: inv.status == InvoiceStatus.paid ? AppColors.success : AppColors.warning,
            backgroundColor: inv.status == InvoiceStatus.paid ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
          ),
          leadingIcon: Icons.receipt_long_outlined,
          onTap: () => context.push('/invoices/details/${inv.id}'),
        );
      },
    );
  }

  Widget _buildBuyersTab(BuildContext context, InvoiceProvider provider, Product product) {
    final buyers = provider.getCustomersWhoBoughtProduct(product.id);

    if (buyers.isEmpty) {
      return const EmptyState(
        title: 'No Customers Found',
        description: 'Buyers who purchase this product will show up in this directory.',
        icon: Icons.people_outline_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: buyers.length,
      itemBuilder: (context, index) {
        final customer = buyers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                customer.company.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            title: Text(customer.company, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(customer.name),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerDetailScreen(customerId: customer.id),
                ),
              );
            },
          ),
        );
      },
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
