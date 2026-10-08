import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/vendor.dart';
import '../providers/vendor_provider.dart';
import 'new_vendor_screen.dart';

class VendorsListScreen extends StatefulWidget {
  const VendorsListScreen({super.key});

  @override
  State<VendorsListScreen> createState() => _VendorsListScreenState();
}

class _VendorsListScreenState extends State<VendorsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().fetchVendors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditVendor(BuildContext context, Vendor vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewVendorScreen(vendorToEdit: vendor),
      ),
    );
  }

  void _confirmDeleteVendor(BuildContext context, Vendor vendor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${vendor.displayName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final vProvider = context.read<VendorProvider>();
              final success = await vProvider.deleteVendor(vendor.id);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Vendor "${vendor.displayName}" deleted.'
                        : 'Failed to delete vendor.',
                  ),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showVendorDetails(BuildContext context, Vendor vendor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF6D28D9).withValues(alpha: 0.15),
                    child: Text(
                      vendor.displayName.isNotEmpty ? vendor.displayName[0].toUpperCase() : 'V',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.displayName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (vendor.companyName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            vendor.companyName,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Color(0xFF6D28D9)),
                    tooltip: 'Edit Vendor',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openEditVendor(context, vendor);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Contact Information
              _buildDetailSectionTitle('Contact Details', Icons.contact_phone_outlined),
              if (vendor.firstName.isNotEmpty || vendor.lastName.isNotEmpty)
                _buildDetailRow('Contact Person', '${vendor.firstName} ${vendor.lastName}'.trim()),
              if (vendor.email.isNotEmpty)
                _buildDetailRow('Email', vendor.email),
              if (vendor.primaryPhone.isNotEmpty)
                _buildDetailRow('Primary Phone', vendor.primaryPhone),
              if (vendor.secondaryPhone.isNotEmpty)
                _buildDetailRow('Secondary Phone', vendor.secondaryPhone),
              if (vendor.website.isNotEmpty)
                _buildDetailRow('Website', vendor.website),

              const SizedBox(height: 16),

              // Tax & Terms
              _buildDetailSectionTitle('Tax & Financials', Icons.receipt_long_rounded),
              if (vendor.gstNumber.isNotEmpty)
                _buildDetailRow('GSTIN', vendor.gstNumber),
              if (vendor.panNumber.isNotEmpty)
                _buildDetailRow('PAN Number', vendor.panNumber),
              _buildDetailRow('Tax Preference', vendor.taxPreference),
              _buildDetailRow('Currency', vendor.currency),
              _buildDetailRow('Payment Terms', vendor.paymentTerms),

              const SizedBox(height: 16),

              // Billing Address
              _buildDetailSectionTitle('Billing Address', Icons.location_on_outlined),
              _buildDetailRow(
                'Address',
                [
                  if (vendor.billingAttention.isNotEmpty) 'Attn: ${vendor.billingAttention}',
                  if (vendor.billingAddressLine1.isNotEmpty) vendor.billingAddressLine1,
                  if (vendor.billingAddressLine2.isNotEmpty) vendor.billingAddressLine2,
                  if (vendor.billingCity.isNotEmpty) vendor.billingCity,
                  if (vendor.billingState.isNotEmpty) vendor.billingState,
                  if (vendor.billingPostalCode.isNotEmpty) 'PIN: ${vendor.billingPostalCode}',
                  if (vendor.billingCountry.isNotEmpty) vendor.billingCountry,
                ].join(', '),
              ),

              const SizedBox(height: 16),

              // Shipping Address
              _buildDetailSectionTitle('Shipping Address', Icons.local_shipping_outlined),
              _buildDetailRow(
                'Address',
                vendor.shippingSameAsBilling
                    ? 'Same as billing address'
                    : [
                        if (vendor.shippingAttention.isNotEmpty) 'Attn: ${vendor.shippingAttention}',
                        if (vendor.shippingAddressLine1.isNotEmpty) vendor.shippingAddressLine1,
                        if (vendor.shippingAddressLine2.isNotEmpty) vendor.shippingAddressLine2,
                        if (vendor.shippingCity.isNotEmpty) vendor.shippingCity,
                        if (vendor.shippingState.isNotEmpty) vendor.shippingState,
                        if (vendor.shippingPostalCode.isNotEmpty) 'PIN: ${vendor.shippingPostalCode}',
                        if (vendor.shippingCountry.isNotEmpty) vendor.shippingCountry,
                      ].join(', '),
              ),

              if (vendor.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDetailSectionTitle('Notes & Remarks', Icons.note_alt_outlined),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    vendor.notes,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDeleteVendor(context, vendor);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D28D9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit Vendor'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openEditVendor(context, vendor);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6D28D9)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6D28D9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Vendors', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => context.read<VendorProvider>().fetchVendors(refresh: true),
          ),
        ],
      ),
      body: Consumer<VendorProvider>(
        builder: (context, provider, _) {
          final vendors = provider.filteredVendors;

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => provider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search vendors by name, company, email, phone...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
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

              // Vendors List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () => provider.fetchVendors(refresh: true),
                        child: vendors.isEmpty
                            ? ListView(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 80.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.storefront_outlined,
                                          size: 64,
                                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          provider.searchQuery.isNotEmpty
                                              ? 'No vendors found matching "${provider.searchQuery}"'
                                              : 'No vendors added yet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Create vendor profiles to record bills, purchase orders and supplier expenses.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? Colors.white38 : const Color(0xFF64748B),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () => context.push('/purchases/vendors/new'),
                                          icon: const Icon(Icons.add_rounded),
                                          label: const Text('Add New Vendor'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF6D28D9),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: vendors.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final vendor = vendors[index];
                                  return _VendorCard(
                                    vendor: vendor,
                                    onTap: () => _showVendorDetails(context, vendor),
                                    onEdit: () => _openEditVendor(context, vendor),
                                    onDelete: () => _confirmDeleteVendor(context, vendor),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/purchases/vendors/new'),
        backgroundColor: const Color(0xFF6D28D9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VendorCard({
    required this.vendor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF6D28D9).withValues(alpha: 0.12),
                child: Text(
                  vendor.displayName.isNotEmpty
                      ? vendor.displayName[0].toUpperCase()
                      : (vendor.companyName.isNotEmpty ? vendor.companyName[0].toUpperCase() : 'V'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6D28D9),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (vendor.paymentTerms.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6D28D9).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              vendor.paymentTerms,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (vendor.companyName.isNotEmpty && vendor.companyName != vendor.displayName) ...[
                      const SizedBox(height: 2),
                      Text(
                        vendor.companyName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (vendor.primaryPhone.isNotEmpty || vendor.phone.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_outlined, size: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              const SizedBox(width: 3),
                              Text(
                                vendor.primaryPhone.isNotEmpty ? vendor.primaryPhone : vendor.phone,
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            ],
                          ),
                        if (vendor.email.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.email_outlined, size: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              const SizedBox(width: 3),
                              Text(
                                vendor.email,
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            ],
                          ),
                        if (vendor.gstNumber.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'GST: ${vendor.gstNumber}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (val) {
                  if (val == 'edit') {
                    onEdit();
                  } else if (val == 'delete') {
                    onDelete();
                  } else if (val == 'details') {
                    onTap();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18, color: Color(0xFF6D28D9)),
                        SizedBox(width: 8),
                        Text('Edit Vendor'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
