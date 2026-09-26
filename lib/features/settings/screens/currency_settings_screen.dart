import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../models/settings_models.dart';
import '../providers/settings_provider.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _baseCurrencyController;
  late TextEditingController _currencySymbolController;
  late TextEditingController _decimalPlacesController;
  late TextEditingController _invoicePrefixController;
  late TextEditingController _quotationPrefixController;
  late TextEditingController _estimatePrefixController;
  late TextEditingController _purchasePrefixController;
  late TextEditingController _creditNotePrefixController;
  late TextEditingController _debitNotePrefixController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SettingsProvider>();
    final fin = provider.financialSettings;

    _baseCurrencyController = TextEditingController(text: fin?.baseCurrency ?? 'INR');
    _currencySymbolController = TextEditingController(text: fin?.currencySymbol ?? '₹');
    _decimalPlacesController = TextEditingController(text: fin?.decimalPlaces.toString() ?? '2');
    _invoicePrefixController = TextEditingController(text: fin?.invoicePrefix ?? 'INV');
    _quotationPrefixController = TextEditingController(text: fin?.quotationPrefix ?? 'QTN');
    _estimatePrefixController = TextEditingController(text: fin?.estimatePrefix ?? 'EST');
    _purchasePrefixController = TextEditingController(text: fin?.purchasePrefix ?? 'PO');
    _creditNotePrefixController = TextEditingController(text: fin?.creditNotePrefix ?? 'CN');
    _debitNotePrefixController = TextEditingController(text: fin?.debitNotePrefix ?? 'DN');
  }

  @override
  void dispose() {
    _baseCurrencyController.dispose();
    _currencySymbolController.dispose();
    _decimalPlacesController.dispose();
    _invoicePrefixController.dispose();
    _quotationPrefixController.dispose();
    _estimatePrefixController.dispose();
    _purchasePrefixController.dispose();
    _creditNotePrefixController.dispose();
    _debitNotePrefixController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SettingsProvider>();
    final updated = FinancialSettings(
      baseCurrency: _baseCurrencyController.text.trim(),
      currencySymbol: _currencySymbolController.text.trim(),
      decimalPlaces: int.tryParse(_decimalPlacesController.text) ?? 2,
      defaultPaymentTerms: provider.financialSettings?.defaultPaymentTerms ?? 'Immediate',
      invoicePrefix: _invoicePrefixController.text.trim(),
      quotationPrefix: _quotationPrefixController.text.trim(),
      estimatePrefix: _estimatePrefixController.text.trim(),
      purchasePrefix: _purchasePrefixController.text.trim(),
      creditNotePrefix: _creditNotePrefixController.text.trim(),
      debitNotePrefix: _debitNotePrefixController.text.trim(),
      defaultDiscountType: provider.financialSettings?.defaultDiscountType ?? 'flat',
      taxInclusive: provider.financialSettings?.taxInclusive ?? false,
      roundOff: provider.financialSettings?.roundOff ?? true,
      autoNumberGeneration: provider.financialSettings?.autoNumberGeneration ?? true,
      invoiceNumberFormat: provider.financialSettings?.invoiceNumberFormat ?? 'prefix_dashed_number',
      invoiceStartingNumber: provider.financialSettings?.invoiceStartingNumber ?? 1,
      invoiceNumberPadding: provider.financialSettings?.invoiceNumberPadding ?? 3,
    );

    final success = await provider.updateFinancial(updated);
    if (mounted) {
      if (success) {
        // Also refresh company settings to show the updated currency code on the main settings list
        await provider.fetchSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Financial & Currency settings updated successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final err = provider.errorMessage ?? 'Failed to update financial settings';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency & Financials'),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _baseCurrencyController,
                            decoration: const InputDecoration(
                              labelText: 'Base Currency Code *',
                              hintText: 'e.g. INR, USD, EUR',
                              prefixIcon: Icon(Icons.currency_exchange_rounded),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Base currency code is required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _currencySymbolController,
                            decoration: const InputDecoration(
                              labelText: 'Currency Symbol *',
                              hintText: 'e.g. ₹, \$, €',
                              prefixIcon: Icon(Icons.monetization_on_rounded),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Currency symbol is required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _decimalPlacesController,
                      decoration: const InputDecoration(
                        labelText: 'Decimal Precision (Places) *',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Precision is required';
                        if (int.tryParse(val) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Document Number Prefixes',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _invoicePrefixController,
                            decoration: const InputDecoration(labelText: 'Invoice Prefix'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _quotationPrefixController,
                            decoration: const InputDecoration(labelText: 'Quotation Prefix'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _estimatePrefixController,
                            decoration: const InputDecoration(labelText: 'Estimate Prefix'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _purchasePrefixController,
                            decoration: const InputDecoration(labelText: 'Purchase Order Prefix'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _creditNotePrefixController,
                            decoration: const InputDecoration(labelText: 'Credit Note Prefix'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _debitNotePrefixController,
                            decoration: const InputDecoration(labelText: 'Debit Note Prefix'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: provider.isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: provider.isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Financial Configurations'),
                    ),
                  ],
                ).animate().fade(duration: 200.ms),
              ),
            ),
    );
  }
}
