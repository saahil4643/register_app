import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/invoice_provider.dart';
import '../widgets/status_badge.dart';
import '../models/invoice.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../customers/models/customer.dart';
import '../../../core/utils/number_to_words.dart';

class InvoicePreviewScreen extends StatefulWidget {
  const InvoicePreviewScreen({super.key});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  void _showDummyToast(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action is a mockup action and is not implemented in local environment.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<InvoiceProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    final companyName = settingsProvider.companySettings?.companyName ?? 'Prabhim One';
    final email = authProvider.currentUserEmail ?? 'admin@prabhim.com';
    
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy');

    final customer = provider.selectedCustomer ?? provider.editingInvoice?.customer;
    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preview')),
        body: const Center(child: Text('No Customer Selected')),
      );
    }

    final template = settingsProvider.invoiceTemplate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GST Invoice PDF Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Download PDF',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              if (provider.editingInvoice == null) {
                final saved = await provider.saveInvoice();
                if (!saved) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Please save invoice to download PDF'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
              }
              if (provider.editingInvoice != null) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Downloading PDF document...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                final success = await provider.downloadInvoicePdf(
                  invoiceId: provider.editingInvoice!.id,
                  invoiceNumber: provider.editingInvoice!.invoiceNumber,
                );
                if (!success && mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Failed to download PDF'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: () => _showDummyToast(context, 'Share (PDF)'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                color: isDark ? theme.colorScheme.surface : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildTemplateContent(
                    template: template,
                    theme: theme,
                    isDark: isDark,
                    provider: provider,
                    companyName: companyName,
                    email: email,
                    customer: customer,
                    currencyFormat: currencyFormat,
                    dateFormat: dateFormat,
                  ),
                ),
              ),
            ),
          ),

          // Action bottom bar (Edit / Save Draft)
          _buildActionBottomBar(context, theme, isDark, provider),
        ],
      ),
    );
  }

  Widget _buildTemplateContent({
    required String template,
    required ThemeData theme,
    required bool isDark,
    required InvoiceProvider provider,
    required String companyName,
    required String email,
    required Customer customer,
    required NumberFormat currencyFormat,
    required DateFormat dateFormat,
  }) {
    switch (template) {
      case 'tax_invoice':
      case 'prabhim':
        return _buildTaxInvoiceTemplateContent(
          theme: theme,
          isDark: isDark,
          provider: provider,
          companyName: companyName,
          email: email,
          customer: customer,
          currencyFormat: currencyFormat,
          dateFormat: dateFormat,
        );
      case 'modern':
        return _buildModernTemplateContent(
          theme: theme,
          isDark: isDark,
          provider: provider,
          companyName: companyName,
          email: email,
          customer: customer,
          currencyFormat: currencyFormat,
          dateFormat: dateFormat,
        );
      case 'elegant':
        return _buildElegantTemplateContent(
          theme: theme,
          isDark: isDark,
          provider: provider,
          companyName: companyName,
          email: email,
          customer: customer,
          currencyFormat: currencyFormat,
          dateFormat: dateFormat,
        );
      case 'classic':
      default:
        return _buildClassicTemplateContent(
          theme: theme,
          isDark: isDark,
          provider: provider,
          companyName: companyName,
          email: email,
          customer: customer,
          currencyFormat: currencyFormat,
          dateFormat: dateFormat,
        );
    }
  }

  // ==================== 0. TAX INVOICE (PRABHIM FORMAT) ====================
  Widget _buildTaxInvoiceTemplateContent({
    required ThemeData theme,
    required bool isDark,
    required InvoiceProvider provider,
    required String companyName,
    required String email,
    required Customer customer,
    required NumberFormat currencyFormat,
    required DateFormat dateFormat,
  }) {
    const headerPurple = Color(0xFF9181DF);
    final company = context.read<SettingsProvider>().companySettings;

    final displayCompanyName = (company?.companyName.isNotEmpty ?? false)
        ? company!.companyName
        : 'Prabhim Technologies (OPC) Pvt. Ltd.';
    final displayAddress = (company?.address.isNotEmpty ?? false)
        ? '${company!.address}, ${company.city.isNotEmpty ? "${company.city}, " : ""}${company.postalCode.isNotEmpty ? "${company.postalCode}, " : ""}${company.country.isNotEmpty ? company.country : "India"}'
        : 'FL-1002 A, Utsav Residency Phase 1, Awhalwadi Road,\nWagholi, Pune, 412202, India';
    final displayPhone = (company?.phone.isNotEmpty ?? false) ? company!.phone : '+91-9403301412';
    final displayEmail = (company?.email.isNotEmpty ?? false) ? company!.email : email;
    final displayGstn = (company?.gstNumber.isNotEmpty ?? false) ? company!.gstNumber : '27AAPCP6019G1Z5';
    final displayState = (company?.state.isNotEmpty ?? false) ? company!.state : 'Maharashtra';

    final int totalQty = provider.selectedItems.fold(0, (sum, item) => sum + item.quantity);
    final double sgst = provider.totalTax / 2;
    final double cgst = provider.totalTax / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Company Header and Logo Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Company Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayCompanyName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayAddress,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Phone : $displayPhone',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  Text(
                    'e-mail : $displayEmail',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  Text(
                    'GSTN: $displayGstn',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  Text(
                    'State: $displayState',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right: Company Logo Branding
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildCompanyLogo(company?.companyLogo, height: 48, width: 140),
              ],
            ),
          ],
        ),

        // 2. Full Width Horizontal Divider Line
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Container(
            height: 2,
            color: isDark ? Colors.white54 : Colors.black,
          ),
        ),

        // 3. Centered "Tax Invoice" Header
        Center(
          child: Text(
            'Tax Invoice',
            style: theme.textTheme.titleLarge?.copyWith(
              color: headerPurple,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Metadata: Bill To vs Invoice Details
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill To Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bill To',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.company.isNotEmpty ? customer.company : 'ABC India Corporation Pvt Ltd',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    customer.address.isNotEmpty ? customer.address : 'Office No 122\nXXXXXXX city, Pune – 412207',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    'Contact No ${customer.phone}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    'GSTN: ${customer.taxNumber.isNotEmpty ? customer.taxNumber : "XXXXXXXX"}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const Text(
                    'State : Maharashtra',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Invoice Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invoice Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(width: 100, child: Text('Invoice No.:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text(provider.invoiceNumber, style: const TextStyle(fontSize: 11))),
                    ],
                  ),
                  Row(
                    children: const [
                      SizedBox(width: 100, child: Text('PO No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('', style: TextStyle(fontSize: 11))),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 100, child: Text('Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text(dateFormat.format(provider.invoiceDate), style: const TextStyle(fontSize: 11))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 5. Items Table
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: const BoxDecoration(
            color: headerPurple,
          ),
          child: Row(
            children: const [
              SizedBox(width: 28, child: Text('#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(child: Text('Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              SizedBox(width: 48, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              SizedBox(width: 70, child: Text('Rate', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              SizedBox(width: 80, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
            ],
          ),
        ),

        // Table Rows
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.selectedItems.length,
          itemBuilder: (context, index) {
            final item = provider.selectedItems[index];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: 28, child: Text('${index + 1}', style: const TextStyle(fontSize: 11))),
                  Expanded(
                    child: Text(
                      item.product.name,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      item.unitPrice.toStringAsFixed(0),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      item.total.toStringAsFixed(0),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Total Row with thick black borders
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: isDark ? Colors.white : Colors.black, width: 2),
              bottom: BorderSide(color: isDark ? Colors.white : Colors.black, width: 2),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 28),
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$totalQty',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 70),
              SizedBox(
                width: 80,
                child: Text(
                  provider.grandTotal.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 6. Subtotals & Amount in Words Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Description & Amount in Words
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  if (provider.notes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(provider.notes, style: const TextStyle(fontSize: 11)),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Invoice Amount In Words',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    NumberToWords.convert(provider.grandTotal),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right side: Sub Total, SGST, CGST, Total
            SizedBox(
              width: 180,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sub Total', style: TextStyle(fontSize: 11)),
                        Text(provider.subtotal.toStringAsFixed(0), style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SGST@9%', style: TextStyle(fontSize: 11)),
                        Text(sgst.toStringAsFixed(0), style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('CGST@9%', style: TextStyle(fontSize: 11)),
                        Text(cgst.toStringAsFixed(0), style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),

                  // Total Highlight Bar
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    color: headerPurple,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          provider.grandTotal.toStringAsFixed(0),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),

        // 7. Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Text(
              'Thanks for doing business with us!',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
            Text(
              'Authorized Signatory',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== 1. CLASSIC TEMPLATE ====================
  Widget _buildClassicTemplateContent({
    required ThemeData theme,
    required bool isDark,
    required InvoiceProvider provider,
    required String companyName,
    required String email,
    required Customer customer,
    required NumberFormat currencyFormat,
    required DateFormat dateFormat,
  }) {
    final company = context.read<SettingsProvider>().companySettings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildCompanyLogo(company?.companyLogo, height: 44, width: 120),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'INVOICE',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                InvoiceStatusBadge(status: provider.editingInvoice?.status ?? InvoiceStatus.draft),
              ],
            ),
          ],
        ),
        const Divider(height: 32),

        // Metadata and Client Info Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BILL TO',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.company,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    customer.name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.address,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (customer.taxNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'GSTIN: ${customer.taxNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMetaLabelValue('Invoice No.', provider.invoiceNumber, theme),
                  _buildMetaLabelValue('Invoice Date', dateFormat.format(provider.invoiceDate), theme),
                  _buildMetaLabelValue('Due Date', dateFormat.format(provider.dueDate), theme),
                  _buildMetaLabelValue('Currency', 'INR (₹)', theme),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Items Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBorder : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              Expanded(child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              SizedBox(width: 48, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              SizedBox(width: 80, child: Text('Rate', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              SizedBox(width: 80, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Items Table Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.selectedItems.length,
          separatorBuilder: (context, index) => Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 16),
          itemBuilder: (context, index) {
            final item = provider.selectedItems[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (item.discountPercentage > 0 || item.taxPercentage > 0)
                          Text(
                            '${item.taxPercentage > 0 ? 'GST ${item.taxPercentage}%' : ''}'
                            '${item.taxPercentage > 0 && item.discountPercentage > 0 ? ' | ' : ''}'
                            '${item.discountPercentage > 0 ? 'Disc -${item.discountPercentage}%' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: AppColors.success),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      currencyFormat.format(item.unitPrice),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      currencyFormat.format(item.total),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 32),

        // Totals Calculations
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.notes.isNotEmpty) ...[
                    Text(
                      'NOTES',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.notes,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (provider.terms.isNotEmpty) ...[
                    Text(
                      'TERMS & CONDITIONS',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.terms,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 180,
              child: Column(
                children: [
                  _buildPreviewTotalRow('Subtotal', currencyFormat.format(provider.subtotal), theme),
                  const SizedBox(height: 6),
                  _buildPreviewTotalRow(
                    'Discount',
                    '-${currencyFormat.format(provider.totalDiscount)}',
                    theme,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 6),
                  _buildPreviewTotalRow('GST Tax', currencyFormat.format(provider.totalTax), theme),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        currencyFormat.format(provider.grandTotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== 2. MODERN TEMPLATE ====================
  Widget _buildModernTemplateContent({
    required ThemeData theme,
    required bool isDark,
    required InvoiceProvider provider,
    required String companyName,
    required String email,
    required Customer customer,
    required NumberFormat currencyFormat,
    required DateFormat dateFormat,
  }) {
    final accentColor = theme.colorScheme.primary;
    final company = context.read<SettingsProvider>().companySettings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Header with Vertical Accent Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildCompanyLogo(company?.companyLogo, height: 48, width: 120),
                const SizedBox(width: 12),
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.disabledColor),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'INVOICE',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                InvoiceStatusBadge(status: provider.editingInvoice?.status ?? InvoiceStatus.draft),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Modern Info Layout
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : accentColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'BILL TO',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      customer.company,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      customer.name,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.address,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (customer.taxNumber.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'GSTIN: ${customer.taxNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildModernMetaItem('Invoice Number', provider.invoiceNumber, theme),
                  _buildModernMetaItem('Date Issued', dateFormat.format(provider.invoiceDate), theme),
                  _buildModernMetaItem('Due Date', dateFormat.format(provider.dueDate), theme),
                  _buildModernMetaItem('Payment Details', 'UPI / Cash', theme),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Modern Items Table Header (No block, just nice layout)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            children: [
              Expanded(child: Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: accentColor, letterSpacing: 0.5))),
              SizedBox(width: 48, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: accentColor, letterSpacing: 0.5))),
              SizedBox(width: 80, child: Text('RATE', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: accentColor, letterSpacing: 0.5))),
              SizedBox(width: 80, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: accentColor, letterSpacing: 0.5))),
            ],
          ),
        ),
        Container(height: 2, color: accentColor.withValues(alpha: 0.2)),
        const SizedBox(height: 8),

        // Modern Items rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.selectedItems.length,
          separatorBuilder: (context, index) => Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 12),
          itemBuilder: (context, index) {
            final item = provider.selectedItems[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (item.discountPercentage > 0 || item.taxPercentage > 0)
                          const SizedBox(height: 2),
                        if (item.discountPercentage > 0 || item.taxPercentage > 0)
                          Row(
                            children: [
                              if (item.taxPercentage > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text('GST ${item.taxPercentage}%', style: TextStyle(fontSize: 9, color: accentColor, fontWeight: FontWeight.bold)),
                                ),
                              if (item.taxPercentage > 0 && item.discountPercentage > 0)
                                const SizedBox(width: 6),
                              if (item.discountPercentage > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text('Disc -${item.discountPercentage}%', style: const TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      currencyFormat.format(item.unitPrice),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      currencyFormat.format(item.total),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        const SizedBox(height: 20),

        // Modern totals and terms notes
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.notes.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Memo / Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(provider.notes, style: const TextStyle(fontSize: 11, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 24),
            Container(
              width: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : accentColor.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  _buildModernTotalRow('Subtotal', currencyFormat.format(provider.subtotal), theme),
                  const SizedBox(height: 6),
                  _buildModernTotalRow('Discount', '-${currencyFormat.format(provider.totalDiscount)}', theme, isDiscount: true),
                  const SizedBox(height: 6),
                  _buildModernTotalRow('Tax (GST)', currencyFormat.format(provider.totalTax), theme),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total due', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(
                        currencyFormat.format(provider.grandTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernMetaItem(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, color: theme.disabledColor, letterSpacing: 0.5)),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildModernTotalRow(String label, String value, ThemeData theme, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.disabledColor)),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: isDiscount ? AppColors.success : null,
          ),
        ),
      ],
    );
  }

  // ==================== 3. ELEGANT TEMPLATE ====================
  Widget _buildElegantTemplateContent({
    required ThemeData theme,
    required bool isDark,
    required InvoiceProvider provider,
    required String companyName,
    required String email,
    required Customer customer,
    required NumberFormat currencyFormat,
    required DateFormat dateFormat,
  }) {
    const elegantColor = Colors.deepPurple;
    final company = context.read<SettingsProvider>().companySettings;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Elegant Serif Title Header
        Center(
          child: Column(
            children: [
              Text(
                'INVOICE',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: elegantColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(height: 1, width: 80, color: elegantColor),
              const SizedBox(height: 2),
              Container(height: 1, width: 40, color: elegantColor),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Company Details and Status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildCompanyLogo(company?.companyLogo, height: 44, width: 120),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.bold,
                        color: elegantColor,
                      ),
                    ),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.disabledColor),
                    ),
                  ],
                ),
              ],
            ),
            InvoiceStatusBadge(status: provider.editingInvoice?.status ?? InvoiceStatus.draft),
          ],
        ),
        const SizedBox(height: 12),
        Container(height: 1, color: elegantColor.withValues(alpha: 0.3)),
        const SizedBox(height: 16),

        // Elegant Columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVOICED TO:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.bold,
                      color: elegantColor,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    customer.company,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'Georgia',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    customer.name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.address,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                  if (customer.taxNumber.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'GSTIN: ${customer.taxNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildElegantMetaItem('Invoice Credentials', provider.invoiceNumber, theme),
                  _buildElegantMetaItem('Date Registered', dateFormat.format(provider.invoiceDate), theme),
                  _buildElegantMetaItem('Fulfill Date', dateFormat.format(provider.dueDate), theme),
                  _buildElegantMetaItem('Base Currency', 'INR (₹)', theme),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Elegant items table double header line
        Container(height: 1, color: elegantColor),
        const SizedBox(height: 2),
        Container(height: 1, color: elegantColor),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Row(
            children: const [
              Expanded(child: Text('Item Description', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 11, color: elegantColor))),
              SizedBox(width: 48, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 11, color: elegantColor))),
              SizedBox(width: 80, child: Text('Unit Cost', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 11, color: elegantColor))),
              SizedBox(width: 80, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 11, color: elegantColor))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: elegantColor.withValues(alpha: 0.3)),
        const SizedBox(height: 8),

        // Items List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.selectedItems.length,
          separatorBuilder: (context, index) => Divider(color: elegantColor.withValues(alpha: 0.1), height: 16),
          itemBuilder: (context, index) {
            final item = provider.selectedItems[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (item.discountPercentage > 0 || item.taxPercentage > 0)
                          Text(
                            '${item.taxPercentage > 0 ? 'GST ${item.taxPercentage}%' : ''}'
                            '${item.taxPercentage > 0 && item.discountPercentage > 0 ? ' | ' : ''}'
                            '${item.discountPercentage > 0 ? 'Discount -${item.discountPercentage}%' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontStyle: FontStyle.italic, color: elegantColor),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      currencyFormat.format(item.unitPrice),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      currencyFormat.format(item.total),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(height: 1, color: elegantColor),
        const SizedBox(height: 24),

        // Calculations & note
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.notes.isNotEmpty) ...[
                    Text(
                      'DOCUMENT NOTES',
                      style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 10, color: elegantColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.notes,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 180,
              child: Column(
                children: [
                  _buildElegantTotalRow('Subtotal', currencyFormat.format(provider.subtotal), theme),
                  const SizedBox(height: 6),
                  _buildElegantTotalRow('Discount Deductions', '-${currencyFormat.format(provider.totalDiscount)}', theme, color: AppColors.success),
                  const SizedBox(height: 6),
                  _buildElegantTotalRow('GST Taxes', currencyFormat.format(provider.totalTax), theme),
                  const SizedBox(height: 8),
                  Container(height: 1, color: elegantColor),
                  const SizedBox(height: 2),
                  Container(height: 1, color: elegantColor),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Value', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 12, color: elegantColor)),
                      Text(
                        currencyFormat.format(provider.grandTotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: elegantColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildElegantMetaItem(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$label:  ',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantTotalRow(String label, String value, ThemeData theme, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontStyle: FontStyle.italic)),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==================== METADATA & HELPER CARD ROWS ====================
  Widget _buildMetaLabelValue(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$label:  ',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: theme.brightness == Brightness.dark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTotalRow(String label, String value, ThemeData theme, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBottomBar(BuildContext context, ThemeData theme, bool isDark, InvoiceProvider provider) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.go('/invoices');
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Invoices'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (provider.editingInvoice == null) {
                    final saved = await provider.saveInvoice();
                    if (!saved) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(provider.errorMessage ?? 'Please save invoice first'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                  }
                  if (provider.editingInvoice != null) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Downloading PDF document...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    final success = await provider.downloadInvoicePdf(
                      invoiceId: provider.editingInvoice!.id,
                      invoiceNumber: provider.editingInvoice!.invoiceNumber,
                    );
                    if (!success && mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(provider.errorMessage ?? 'Failed to download PDF'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyLogo(String? logoUrl, {double height = 48, double width = 140}) {
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      final settingsProvider = context.read<SettingsProvider>();
      final shape = settingsProvider.logoShape;
      final fitStr = settingsProvider.logoFit;
      final fit = fitStr == 'contain' ? BoxFit.contain : BoxFit.cover;

      final double logoWidth = shape == 'rectangle' ? width : height;
      final double logoHeight = height;

      Widget image;
      if (logoUrl.startsWith('data:image')) {
        try {
          final base64Str = logoUrl.split(',').last;
          final bytes = base64Decode(base64Str);
          image = Image.memory(
            bytes,
            height: logoHeight,
            width: logoWidth,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildDefaultBranding(height: height),
          );
        } catch (_) {
          return _buildDefaultBranding(height: height);
        }
      } else {
        final String fullUrl = (logoUrl.startsWith('http://') || logoUrl.startsWith('https://'))
            ? logoUrl
            : '${Env.apiBaseUrl}${logoUrl.startsWith('/') ? '' : '/'}$logoUrl';

        image = Image.network(
          fullUrl,
          height: logoHeight,
          width: logoWidth,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildDefaultBranding(height: height),
        );
      }

      return Container(
        height: logoHeight,
        width: logoWidth,
        decoration: BoxDecoration(
          borderRadius: shape == 'circle' ? null : BorderRadius.circular(8),
          shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: shape == 'circle'
            ? ClipOval(
                child: Transform(
                  transform: settingsProvider.getScaledLogoMatrix(logoHeight),
                  alignment: Alignment.topLeft,
                  child: image,
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Transform(
                  transform: settingsProvider.getScaledLogoMatrix(logoHeight),
                  alignment: Alignment.topLeft,
                  child: image,
                ),
              ),
      );
    }

    return _buildDefaultBranding(height: height);
  }

  Widget _buildDefaultBranding({double height = 40}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.amber,
            size: 24,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'PRABHIM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              'TECHNOLOGIES',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
                color: Color(0xFFEAB308),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
