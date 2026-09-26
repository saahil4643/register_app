import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../models/settings_models.dart';
import '../providers/settings_provider.dart';

class PaymentMethodsSettingsScreen extends StatefulWidget {
  const PaymentMethodsSettingsScreen({super.key});

  @override
  State<PaymentMethodsSettingsScreen> createState() => _PaymentMethodsSettingsScreenState();
}

class _PaymentMethodsSettingsScreenState extends State<PaymentMethodsSettingsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Stripe controllers
  late bool _stripeEnabled;
  late TextEditingController _stripePubKeyController;
  late TextEditingController _stripeSecretKeyController;

  // Razorpay controllers
  late bool _razorpayEnabled;
  late TextEditingController _razorpayKeyIdController;
  late TextEditingController _razorpayKeySecretController;

  // PayPal controllers
  late bool _paypalEnabled;
  late TextEditingController _paypalClientIdController;
  late TextEditingController _paypalSecretController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    final provider = context.read<SettingsProvider>();
    final integrations = provider.integrationSettings;

    _stripeEnabled = integrations?.stripeEnabled ?? false;
    _stripePubKeyController = TextEditingController(text: integrations?.stripePublishableKey ?? '');
    _stripeSecretKeyController = TextEditingController(text: integrations?.stripeSecretKey ?? '');

    _razorpayEnabled = integrations?.razorpayEnabled ?? false;
    _razorpayKeyIdController = TextEditingController(text: integrations?.razorpayKeyId ?? '');
    _razorpayKeySecretController = TextEditingController(text: integrations?.razorpayKeySecret ?? '');

    _paypalEnabled = integrations?.paypalEnabled ?? false;
    _paypalClientIdController = TextEditingController(text: integrations?.paypalClientId ?? '');
    _paypalSecretController = TextEditingController(text: integrations?.paypalClientSecret ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.fetchPaymentMethods();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stripePubKeyController.dispose();
    _stripeSecretKeyController.dispose();
    _razorpayKeyIdController.dispose();
    _razorpayKeySecretController.dispose();
    _paypalClientIdController.dispose();
    _paypalSecretController.dispose();
    super.dispose();
  }

  Future<void> _saveIntegrations() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SettingsProvider>();
    final updated = IntegrationSettings(
      stripeEnabled: _stripeEnabled,
      stripePublishableKey: _stripePubKeyController.text.trim(),
      stripeSecretKey: _stripeSecretKeyController.text.trim(),
      razorpayEnabled: _razorpayEnabled,
      razorpayKeyId: _razorpayKeyIdController.text.trim(),
      razorpayKeySecret: _razorpayKeySecretController.text.trim(),
      paypalEnabled: _paypalEnabled,
      paypalClientId: _paypalClientIdController.text.trim(),
      paypalClientSecret: _paypalSecretController.text.trim(),
    );

    final success = await provider.updateIntegration(updated);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment integrations updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final err = provider.errorMessage ?? 'Failed to update payment configurations';
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

  Future<void> _showCustomMethodDialog([PaymentMethod? method]) async {
    final methodFormKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: method?.name ?? '');
    final accNoController = TextEditingController(text: method?.accountDetails['account_number']?.toString() ?? method?.accountDetails['upi_id']?.toString() ?? '');
    final ifscController = TextEditingController(text: method?.accountDetails['ifsc']?.toString() ?? method?.accountDetails['bank_name']?.toString() ?? '');
    bool isDefault = method?.isDefault ?? false;
    String status = method?.status ?? 'active';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(method == null ? 'Add Payment Method' : 'Edit Payment Method'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Form(
            key: methodFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Method Name (e.g. Bank, UPI, Cash) *',
                      prefixIcon: Icon(Icons.payment_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: accNoController,
                    decoration: const InputDecoration(
                      labelText: 'Account Number / UPI ID *',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter account details' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ifscController,
                    decoration: const InputDecoration(
                      labelText: 'IFSC / Bank Name / Details',
                      prefixIcon: Icon(Icons.info_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.check_circle_outline_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (val) {
                      if (val != null) status = val;
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Set as Default'),
                    contentPadding: EdgeInsets.zero,
                    value: isDefault,
                    onChanged: (val) {
                      setState(() {
                        isDefault = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (methodFormKey.currentState!.validate()) {
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
      final isUpi = accNoController.text.contains('@');
      final Map<String, dynamic> accDetails = isUpi 
          ? {'upi_id': accNoController.text.trim()} 
          : {'account_number': accNoController.text.trim(), 'ifsc': ifscController.text.trim()};

      final updatedMethod = PaymentMethod(
        id: method?.id ?? '',
        name: nameController.text.trim(),
        status: status,
        isDefault: isDefault,
        accountDetails: accDetails,
      );

      final success = method == null 
          ? await provider.createPaymentMethod(updatedMethod)
          : await provider.updatePaymentMethod(updatedMethod);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(method == null ? 'Payment method added successfully' : 'Payment method updated successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final err = provider.errorMessage ?? 'Failed to save payment method';
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

  Future<void> _deleteMethod(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Payment Method'),
          content: const Text('Are you sure you want to permanently delete this payment method?'),
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
      final success = await provider.deletePaymentMethod(id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment method deleted successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final err = provider.errorMessage ?? 'Failed to delete payment method';
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
        title: const Text('Payment Methods'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.disabledColor,
          tabs: const [
            Tab(text: 'Online Gateways', icon: Icon(Icons.cloud_queue_rounded)),
            Tab(text: 'Custom Methods', icon: Icon(Icons.account_balance_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Gateways Form
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPaymentGatewayCard(
                    title: 'Stripe Gateway',
                    logoIcon: Icons.credit_card_rounded,
                    logoColor: Colors.deepPurple,
                    enabled: _stripeEnabled,
                    onToggle: (val) {
                      setState(() {
                        _stripeEnabled = val;
                      });
                    },
                    children: [
                      TextFormField(
                        controller: _stripePubKeyController,
                        decoration: const InputDecoration(
                          labelText: 'Publishable Key',
                          prefixIcon: Icon(Icons.key_rounded),
                        ),
                        validator: (val) => _stripeEnabled && (val == null || val.trim().isEmpty) ? 'Required when Stripe is enabled' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _stripeSecretKeyController,
                        decoration: const InputDecoration(
                          labelText: 'Secret Key',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        obscureText: true,
                        validator: (val) => _stripeEnabled && (val == null || val.trim().isEmpty) ? 'Required when Stripe is enabled' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentGatewayCard(
                    title: 'Razorpay Gateway',
                    logoIcon: Icons.account_balance_wallet_rounded,
                    logoColor: Colors.blue,
                    enabled: _razorpayEnabled,
                    onToggle: (val) {
                      setState(() {
                        _razorpayEnabled = val;
                      });
                    },
                    children: [
                      TextFormField(
                        controller: _razorpayKeyIdController,
                        decoration: const InputDecoration(
                          labelText: 'Key ID',
                          prefixIcon: Icon(Icons.key_rounded),
                        ),
                        validator: (val) => _razorpayEnabled && (val == null || val.trim().isEmpty) ? 'Required when Razorpay is enabled' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _razorpayKeySecretController,
                        decoration: const InputDecoration(
                          labelText: 'Key Secret',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        obscureText: true,
                        validator: (val) => _razorpayEnabled && (val == null || val.trim().isEmpty) ? 'Required when Razorpay is enabled' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentGatewayCard(
                    title: 'PayPal Gateway',
                    logoIcon: Icons.payment_rounded,
                    logoColor: Colors.blue[900]!,
                    enabled: _paypalEnabled,
                    onToggle: (val) {
                      setState(() {
                        _paypalEnabled = val;
                      });
                    },
                    children: [
                      TextFormField(
                        controller: _paypalClientIdController,
                        decoration: const InputDecoration(
                          labelText: 'Client ID',
                          prefixIcon: Icon(Icons.key_rounded),
                        ),
                        validator: (val) => _paypalEnabled && (val == null || val.trim().isEmpty) ? 'Required when PayPal is enabled' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _paypalSecretController,
                        decoration: const InputDecoration(
                          labelText: 'Client Secret',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        obscureText: true,
                        validator: (val) => _paypalEnabled && (val == null || val.trim().isEmpty) ? 'Required when PayPal is enabled' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: provider.isSaving ? null : _saveIntegrations,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: provider.isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Update Gateways'),
                  ),
                ],
              ).animate().fade(duration: 200.ms),
            ),
          ),

          // Tab 2: Custom methods List & CRUD
          provider.isLoading && provider.paymentMethods.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => provider.fetchPaymentMethods(),
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
                              Icon(Icons.payment_outlined, size: 40, color: theme.colorScheme.primary),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Custom Payment Methods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    SizedBox(height: 4),
                                    Text('Manage organization accounts for invoice transactions (e.g. Bank Account, UPI ID, Cash).', style: TextStyle(fontSize: 12)),
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
                              'Payment Accounts (${provider.paymentMethods.length})',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showCustomMethodDialog(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Account'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        provider.paymentMethods.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: const Center(
                                  child: Text('No custom payment methods configured.'),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: provider.paymentMethods.length,
                                separatorBuilder: (_, _) => const Divider(),
                                itemBuilder: (context, index) {
                                  final item = provider.paymentMethods[index];
                                  final isInactive = item.status == 'inactive';
                                  final accNo = item.accountDetails['account_number'] ?? item.accountDetails['upi_id'] ?? 'N/A';
                                  final extra = item.accountDetails['ifsc'] ?? item.accountDetails['bank_name'] ?? '';

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.15),
                                      child: Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.secondary),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                      '$accNo ${extra.isNotEmpty ? "($extra)" : ""}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isInactive ? AppColors.error.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            item.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isInactive ? AppColors.error : AppColors.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              _showCustomMethodDialog(item);
                                            } else if (val == 'delete') {
                                              _deleteMethod(item.id);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit Account'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete Account', style: TextStyle(color: AppColors.error)),
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

  Widget _buildPaymentGatewayCard({
    required String title,
    required IconData logoIcon,
    required Color logoColor,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: enabled,
        leading: Icon(logoIcon, color: logoColor, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Switch(
          value: enabled,
          onChanged: onToggle,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          )
        ],
      ),
    );
  }
}
