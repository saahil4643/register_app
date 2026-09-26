import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../models/settings_models.dart';
import '../providers/settings_provider.dart';

class TaxSettingsScreen extends StatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  State<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends State<TaxSettingsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Preferences Controllers
  late TextEditingController _taxNameController;
  late TextEditingController _taxPercentageController;
  late String _taxType;
  late bool _hsnEnabled;
  late bool _sacEnabled;
  late bool _reverseCharge;
  late bool _defaultTax;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final provider = context.read<SettingsProvider>();
    final tax = provider.taxSettings;

    _taxNameController = TextEditingController(text: tax?.taxName ?? 'GST');
    _taxPercentageController = TextEditingController(text: tax?.taxPercentage.toString() ?? '18.0');
    _taxType = tax?.taxType ?? 'GST';
    _hsnEnabled = tax?.hsnEnabled ?? true;
    _sacEnabled = tax?.sacEnabled ?? true;
    _reverseCharge = tax?.reverseCharge ?? false;
    _defaultTax = tax?.defaultTax ?? true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.fetchTaxRates();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taxNameController.dispose();
    _taxPercentageController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SettingsProvider>();
    final updated = TaxSettings(
      taxName: _taxNameController.text.trim(),
      taxType: _taxType,
      taxPercentage: double.tryParse(_taxPercentageController.text) ?? 18.0,
      hsnEnabled: _hsnEnabled,
      sacEnabled: _sacEnabled,
      reverseCharge: _reverseCharge,
      defaultTax: _defaultTax,
    );

    final success = await provider.updateTax(updated);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tax settings preferences updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final err = provider.errorMessage ?? 'Failed to update tax settings';
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

  Future<void> _showTaxRateDialog([TaxRate? rate]) async {
    final rateFormKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: rate?.taxName ?? '');
    final percentageController = TextEditingController(text: rate?.percentage.toString() ?? '');
    bool isDefault = rate?.isDefault ?? false;
    bool isActive = rate?.isActive ?? true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(rate == null ? 'Add Tax Rate' : 'Edit Tax Rate'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Form(
            key: rateFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tax Name (e.g. GST 18%, VAT 5%) *',
                    prefixIcon: Icon(Icons.label_rounded),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter tax label' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: percentageController,
                  decoration: const InputDecoration(
                    labelText: 'Tax Rate (%) *',
                    prefixIcon: Icon(Icons.percent_rounded),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter rate';
                    if (double.tryParse(val) == null) return 'Must be a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Pre-select as Default'),
                  contentPadding: EdgeInsets.zero,
                  value: isDefault,
                  onChanged: (val) {
                    setState(() {
                      isDefault = val;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Is Active'),
                  contentPadding: EdgeInsets.zero,
                  value: isActive,
                  onChanged: (val) {
                    setState(() {
                      isActive = val;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (rateFormKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      final provider = context.read<SettingsProvider>();
      final updatedRate = TaxRate(
        id: rate?.id ?? '',
        taxName: nameController.text.trim(),
        percentage: double.tryParse(percentageController.text) ?? 0.0,
        isDefault: isDefault,
        isActive: isActive,
      );

      final success = rate == null
          ? await provider.createTaxRate(updatedRate)
          : await provider.updateTaxRate(updatedRate);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(rate == null ? 'Tax rate added successfully' : 'Tax rate updated successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final err = provider.errorMessage ?? 'Failed to save tax rate';
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
  }

  Future<void> _deleteTaxRate(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Tax Rate'),
          content: const Text('Are you sure you want to permanently delete this tax rate?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      final provider = context.read<SettingsProvider>();
      final success = await provider.deleteTaxRate(id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tax rate deleted successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final err = provider.errorMessage ?? 'Failed to delete tax rate';
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Settings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.disabledColor,
          tabs: const [
            Tab(text: 'General Preferences', icon: Icon(Icons.tune_rounded)),
            Tab(text: 'Tax Rates List', icon: Icon(Icons.percent_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: General Preferences Form
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _taxType,
                    decoration: const InputDecoration(
                      labelText: 'Tax Category / Type *',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'GST', child: Text('GST (Goods & Services Tax)')),
                      DropdownMenuItem(value: 'VAT', child: Text('VAT (Value Added Tax)')),
                      DropdownMenuItem(value: 'Sales_Tax', child: Text('Sales Tax')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _taxType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taxNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tax Name / Label *',
                      prefixIcon: Icon(Icons.label_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Tax label is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taxPercentageController,
                    decoration: const InputDecoration(
                      labelText: 'Default Tax Rate (%) *',
                      prefixIcon: Icon(Icons.percent_rounded),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Tax rate is required';
                      if (double.tryParse(val) == null) return 'Enter a valid rate';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Enable HSN Code Search'),
                    subtitle: const Text('For product goods classifications'),
                    value: _hsnEnabled,
                    onChanged: (val) {
                      setState(() {
                        _hsnEnabled = val;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Enable SAC Code Search'),
                    subtitle: const Text('For service classifications'),
                    value: _sacEnabled,
                    onChanged: (val) {
                      setState(() {
                        _sacEnabled = val;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Apply Default Tax'),
                    subtitle: const Text('Pre-select this tax in product and invoice creation'),
                    value: _defaultTax,
                    onChanged: (val) {
                      setState(() {
                        _defaultTax = val;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Enable Reverse Charge (RCM)'),
                    subtitle: const Text('Declare liability shift on purchase bills'),
                    value: _reverseCharge,
                    onChanged: (val) {
                      setState(() {
                        _reverseCharge = val;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: provider.isSaving ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: provider.isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Preferences'),
                  ),
                ],
              ).animate().fade(duration: 200.ms),
            ),
          ),

          // Tab 2: Tax Rates List & CRUD
          provider.isLoading && provider.taxRates.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => provider.fetchTaxRates(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.percent_rounded, size: 40, color: theme.colorScheme.primary),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Organization Tax Slab Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    SizedBox(height: 4),
                                    Text('Define tax slabs applicable during sales billing and invoicing operations.', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tax Rates (${provider.taxRates.length})',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showTaxRateDialog(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Slab'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        provider.taxRates.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: const Center(
                                  child: Text('No tax rates defined yet.'),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: provider.taxRates.length,
                                separatorBuilder: (_, _) => const Divider(),
                                itemBuilder: (context, index) {
                                  final item = provider.taxRates[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.15),
                                      child: Text(
                                        '${item.percentage.toStringAsFixed(0)}%',
                                        style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(item.taxName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        if (item.isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Default',
                                              style: TextStyle(fontSize: 9, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(
                                      'Rate: ${item.percentage}%',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: !item.isActive ? AppColors.error.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            item.isActive ? 'ACTIVE' : 'INACTIVE',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: !item.isActive ? AppColors.error : AppColors.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              _showTaxRateDialog(item);
                                            } else if (val == 'delete') {
                                              _deleteTaxRate(item.id);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit Rate'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete Rate', style: TextStyle(color: AppColors.error)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ).animate().fade(duration: 200.ms),
                  ),
                ),
        ],
      ),
    );
  }
}
