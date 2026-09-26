import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../models/settings_models.dart';
import '../providers/settings_provider.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late bool _autoNumberGeneration;
  late String _selectedFormat;
  late String _selectedTemplate;
  late TextEditingController _invoicePrefixController;
  late TextEditingController _startingNumberController;
  late TextEditingController _paddingController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SettingsProvider>();
    final fin = provider.financialSettings;

    _autoNumberGeneration = fin?.autoNumberGeneration ?? true;
    _selectedFormat = fin?.invoiceNumberFormat ?? 'prefix_dashed_number';
    _selectedTemplate = provider.invoiceTemplate;
    _invoicePrefixController = TextEditingController(text: fin?.invoicePrefix ?? 'INV');
    _startingNumberController = TextEditingController(text: (fin?.invoiceStartingNumber ?? 1).toString());
    _paddingController = TextEditingController(text: (fin?.invoiceNumberPadding ?? 3).toString());
  }

  @override
  void dispose() {
    _invoicePrefixController.dispose();
    _startingNumberController.dispose();
    _paddingController.dispose();
    super.dispose();
  }

  String _getPreviewText() {
    final prefix = _invoicePrefixController.text.trim().isEmpty
        ? 'INV'
        : _invoicePrefixController.text.trim();

    final int startingNum = int.tryParse(_startingNumberController.text) ?? 1;
    final int padding = int.tryParse(_paddingController.text) ?? 3;
    final paddedNumber = startingNum.toString().padLeft(padding, '0');
    final currentYear = DateTime.now().year.toString();

    if (_selectedFormat == 'prefix_number') {
      return '$prefix$paddedNumber';
    } else if (_selectedFormat == 'prefix_year_number') {
      return '$prefix/$currentYear/$paddedNumber';
    } else {
      return '$prefix-$paddedNumber';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SettingsProvider>();
    await provider.updateInvoiceTemplate(_selectedTemplate);

    final updated = FinancialSettings(
      baseCurrency: provider.financialSettings?.baseCurrency ?? 'INR',
      currencySymbol: provider.financialSettings?.currencySymbol ?? '₹',
      decimalPlaces: provider.financialSettings?.decimalPlaces ?? 2,
      defaultPaymentTerms: provider.financialSettings?.defaultPaymentTerms ?? 'Immediate',
      invoicePrefix: _invoicePrefixController.text.trim(),
      quotationPrefix: provider.financialSettings?.quotationPrefix ?? 'QTN',
      estimatePrefix: provider.financialSettings?.estimatePrefix ?? 'EST',
      purchasePrefix: provider.financialSettings?.purchasePrefix ?? 'PO',
      creditNotePrefix: provider.financialSettings?.creditNotePrefix ?? 'CN',
      debitNotePrefix: provider.financialSettings?.debitNotePrefix ?? 'DN',
      defaultDiscountType: provider.financialSettings?.defaultDiscountType ?? 'flat',
      taxInclusive: provider.financialSettings?.taxInclusive ?? false,
      roundOff: provider.financialSettings?.roundOff ?? true,
      autoNumberGeneration: _autoNumberGeneration,
      invoiceNumberFormat: _selectedFormat,
      invoiceStartingNumber: int.tryParse(_startingNumberController.text) ?? 1,
      invoiceNumberPadding: int.tryParse(_paddingController.text) ?? 3,
    );

    final success = await provider.updateFinancial(updated);
    if (mounted) {
      if (success) {
        await provider.fetchSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice settings updated successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final err = provider.errorMessage ?? 'Failed to update settings';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SettingsProvider>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: provider.isSaving ? null : _save,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Live Preview Card
                    Card(
                      elevation: 0,
                      color: isDark ? AppColors.darkPrimaryContainer.withValues(alpha: 0.5) : AppColors.lightPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Invoice Number Preview',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListenableBuilder(
                              listenable: Listenable.merge([
                                _invoicePrefixController,
                                _startingNumberController,
                                _paddingController,
                              ]),
                              builder: (context, _) {
                                return Text(
                                  _getPreviewText(),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Invoice Template Selection Header
                    Text(
                      'Choose Invoice Template',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the style for your invoice preview, exports, and PDF files.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Template Selector Cards
                    _buildTemplateOptionCard(
                      id: 'tax_invoice',
                      title: 'GST Tax Invoice (Prabhim)',
                      description: 'Official GST format with purple header bar, tax breakdown, and amount in words.',
                      accentColor: const Color(0xFF9181DF),
                      theme: theme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildTemplateOptionCard(
                      id: 'classic',
                      title: 'Classic Business',
                      description: 'Standard professional look with clean grey separators and centered company name.',
                      accentColor: Colors.blue,
                      theme: theme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildTemplateOptionCard(
                      id: 'modern',
                      title: 'Modern Minimal',
                      description: 'Sleek style with left accent bar, vibrant primary headings, and spacious layout.',
                      accentColor: theme.colorScheme.primary,
                      theme: theme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildTemplateOptionCard(
                      id: 'elegant',
                      title: 'Elegant Boutique',
                      description: 'Premium look with sophisticated serif heading typography and double divider lines.',
                      accentColor: Colors.deepPurple,
                      theme: theme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // Auto Number Generation Switch
                    SwitchListTile(
                      title: const Text('Auto-generate Invoice Number'),
                      subtitle: const Text('Invoices will be automatically numbered based on settings below'),
                      value: _autoNumberGeneration,
                      onChanged: (val) {
                        setState(() {
                          _autoNumberGeneration = val;
                        });
                      },
                      secondary: Icon(
                        Icons.settings_suggest_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(height: 32),

                    if (_autoNumberGeneration) ...[
                      // Prefix
                      TextFormField(
                        controller: _invoicePrefixController,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Number Prefix *',
                          hintText: 'e.g. INV, KC, BILL',
                          prefixIcon: Icon(Icons.abc_rounded),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Prefix is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Format Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedFormat,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Number Format',
                          prefixIcon: Icon(Icons.pattern_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'prefix_dashed_number',
                            child: Text('Prefix-Number (e.g. KC-001)'),
                          ),
                          DropdownMenuItem(
                            value: 'prefix_number',
                            child: Text('PrefixNumber (e.g. KC001)'),
                          ),
                          DropdownMenuItem(
                            value: 'prefix_year_number',
                            child: Text('Prefix/Year/Number (e.g. KC/2026/001)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedFormat = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Starting number and Padding
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startingNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Starting Number *',
                                hintText: '1',
                                prefixIcon: Icon(Icons.play_arrow_rounded),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                if (int.tryParse(val) == null) return 'Enter a number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _paddingController,
                              decoration: const InputDecoration(
                                labelText: 'Digits Padding *',
                                hintText: '3',
                                prefixIcon: Icon(Icons.numbers_rounded),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                final num = int.tryParse(val);
                                if (num == null) return 'Enter a number';
                                if (num < 1 || num > 10) return 'Between 1 and 10';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Manual info box
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'With auto-generation turned off, you will be able to type custom invoice numbers manually on the new invoice creation screen.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: provider.isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: provider.isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Settings'),
                    ),
                  ],
                ).animate().fade(duration: 200.ms),
              ),
            ),
    );
  }

  Widget _buildTemplateOptionCard({
    required String id,
    required String title,
    required String description,
    required Color accentColor,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = _selectedTemplate == id;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTemplate = id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? accentColor.withValues(alpha: 0.15) : accentColor.withValues(alpha: 0.08))
              : (isDark ? theme.cardColor : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection dot or icon
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? accentColor : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            
            // Description & miniature layout
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? (isDark ? Colors.white : accentColor) : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Miniature Schematic Representation of the Invoice Template style
                  _buildMiniatureTemplatePreview(id, accentColor, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniatureTemplatePreview(String id, Color accentColor, bool isDark) {
    final previewBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textCol = isDark ? Colors.white24 : Colors.black12;
    
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: previewBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderCol),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (id == 'tax_invoice') ...[
            // Tax Invoice (Prabhim) style: Purple top bar table, header divider, totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 45, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white70 : Colors.black87, borderRadius: BorderRadius.circular(1))),
                Container(width: 15, height: 10, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 1, color: isDark ? Colors.white54 : Colors.black),
            const SizedBox(height: 4),
            Container(
              height: 12,
              decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(width: 8, height: 2, color: Colors.white),
                  Container(width: 20, height: 2, color: Colors.white),
                  Container(width: 10, height: 2, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 35, height: 3, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(1))),
                Container(width: 20, height: 6, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(1))),
              ],
            ),
          ] else if (id == 'classic') ...[
            // Classic style: Centered header, Divider, Columns
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: borderCol),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 30, height: 4, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(2))),
                Container(width: 15, height: 4, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(2))),
                Container(width: 25, height: 4, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(2))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 45, height: 4, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(2))),
                Container(width: 10, height: 4, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(2))),
                Container(width: 20, height: 4, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ] else if (id == 'modern') ...[
            // Modern style: Left vertical bar, modern minimal elements
            Row(
              children: [
                Container(width: 3, height: 12, color: accentColor),
                const SizedBox(width: 6),
                Container(width: 35, height: 6, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 50, height: 4, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(2))),
                Container(width: 20, height: 4, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(2))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(2))),
                Container(width: 15, height: 4, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ] else if (id == 'elegant') ...[
            // Elegant style: Thin double dividers, italicised fonts representation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 40, height: 5, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(1))),
                Container(width: 20, height: 5, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(1))),
              ],
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: accentColor.withValues(alpha: 0.4)),
            const SizedBox(height: 2),
            Container(height: 1, color: accentColor.withValues(alpha: 0.4)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 35, height: 4, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(2))),
                Container(width: 20, height: 4, decoration: BoxDecoration(color: textCol, borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
