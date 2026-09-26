import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/settings_provider.dart';
import 'profile_business_settings_screen.dart';
import 'users_staff_settings_screen.dart';
import 'currency_settings_screen.dart';
import 'tax_settings_screen.dart';
import 'invoice_settings_screen.dart';
import 'payment_methods_settings_screen.dart';
import 'backup_sync_settings_screen.dart';
import 'app_preferences_settings_screen.dart';
import 'help_support_settings_screen.dart';
import 'about_us_settings_screen.dart';
import '../../../settings/integrate_update_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SettingsProvider>();
    final fin = provider.financialSettings;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile & Business',
                  subtitle: provider.companySettings?.companyName,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileBusinessSettingsScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.people_outline_rounded,
                  title: 'Users / Staff',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UsersStaffSettingsScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.monetization_on_outlined,
                  title: 'Currency',
                  subtitle: fin != null
                      ? '${fin.baseCurrency} (${fin.currencySymbol})'
                      : 'Configure base currency',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CurrencySettingsScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.percent_outlined,
                  title: 'Tax Settings',
                  subtitle: provider.taxSettings != null
                      ? '${provider.taxSettings!.taxName} (${provider.taxSettings!.taxPercentage}%)'
                      : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TaxSettingsScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Invoice Settings',
                  subtitle: fin != null
                      ? 'Prefix: ${fin.invoicePrefix}, Auto: ${fin.autoNumberGeneration ? 'Yes' : 'No'}'
                      : 'Configure invoice numbering & formats',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InvoiceSettingsScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.credit_card_outlined,
                  title: 'Payment Methods',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentMethodsSettingsScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.cloud_outlined,
                  title: 'Backup & Sync',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackupSyncSettingsScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'App Preferences',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppPreferencesSettingsScreen()),
                  ),
                ),
                const IntegrateUpdateButton(),
                _buildMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpSupportSettingsScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About Us',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutUsSettingsScreen()),
                  ),
                ),
              ].animate(interval: 40.ms).fade(duration: 150.ms).slideX(begin: 0.05, end: 0),
            ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          leading: Icon(icon, color: theme.colorScheme.primary, size: 24),
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: subtitle != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.disabledColor,
                      fontSize: 12,
                    ),
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: theme.disabledColor,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
