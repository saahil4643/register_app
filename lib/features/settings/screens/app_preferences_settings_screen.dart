import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../models/settings_models.dart';
import '../providers/settings_provider.dart';

class AppPreferencesSettingsScreen extends StatefulWidget {
  const AppPreferencesSettingsScreen({super.key});

  @override
  State<AppPreferencesSettingsScreen> createState() => _AppPreferencesSettingsScreenState();
}

class _AppPreferencesSettingsScreenState extends State<AppPreferencesSettingsScreen> {
  final _smtpFormKey = GlobalKey<FormState>();

  // SMTP controllers
  late TextEditingController _smtpHostController;
  late TextEditingController _smtpPortController;
  late TextEditingController _smtpUsernameController;
  late TextEditingController _smtpPasswordController;
  late TextEditingController _senderEmailController;
  late TextEditingController _senderNameController;
  late TextEditingController _replyEmailController;
  late String _encryptionType;

  // Pagination config
  late int _defaultPagination;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SettingsProvider>();
    final email = provider.emailSettings;
    final sys = provider.systemPreferences;

    _smtpHostController = TextEditingController(text: email?.smtpHost ?? 'smtp.gmail.com');
    _smtpPortController = TextEditingController(text: email?.smtpPort.toString() ?? '587');
    _smtpUsernameController = TextEditingController(text: email?.username ?? '');
    _smtpPasswordController = TextEditingController();
    _senderEmailController = TextEditingController(text: email?.senderEmail ?? '');
    _senderNameController = TextEditingController(text: email?.senderName ?? '');
    _replyEmailController = TextEditingController(text: email?.replyEmail ?? '');
    _encryptionType = email?.encryptionType ?? 'TLS';

    _defaultPagination = sys?.defaultPagination ?? 10;
  }

  @override
  void dispose() {
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUsernameController.dispose();
    _smtpPasswordController.dispose();
    _senderEmailController.dispose();
    _senderNameController.dispose();
    _replyEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveSmtp() async {
    if (!_smtpFormKey.currentState!.validate()) return;

    final provider = context.read<SettingsProvider>();
    final updated = EmailSettings(
      smtpHost: _smtpHostController.text.trim(),
      smtpPort: int.tryParse(_smtpPortController.text) ?? 587,
      username: _smtpUsernameController.text.trim(),
      password: _smtpPasswordController.text.trim(),
      encryptionType: _encryptionType,
      senderEmail: _senderEmailController.text.trim(),
      senderName: _senderNameController.text.trim(),
      replyEmail: _replyEmailController.text.trim(),
      passwordConfigured: provider.emailSettings?.passwordConfigured ?? false,
    );

    final success = await provider.updateEmail(updated);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMTP configuration updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final err = provider.errorMessage ?? 'Failed to update email settings';
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

  Future<void> _triggerTestEmail() async {
    final provider = context.read<SettingsProvider>();
    final emailController = TextEditingController();

    final recipientEmail = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Test SMTP Email'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter a recipient email address to send a mock test email verification.'),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Recipient Email Address',
                  hintText: 'e.g. admin@prabhim.com',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (emailController.text.trim().isNotEmpty) {
                  Navigator.pop(context, emailController.text.trim());
                }
              },
              child: const Text('Send Test'),
            ),
          ],
        );
      },
    );

    if (recipientEmail != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final msg = await provider.testEmailConnection(recipientEmail);
      if (mounted) Navigator.pop(context); // Dismiss loading

      if (mounted) {
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final err = provider.errorMessage ?? 'SMTP connection failed';
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

  Future<void> _savePagination(int value) async {
    final provider = context.read<SettingsProvider>();
    final sys = provider.systemPreferences;
    if (sys == null) return;

    final updated = SystemPreferences(
      maintenanceMode: sys.maintenanceMode,
      debugMode: sys.debugMode,
      applicationVersion: sys.applicationVersion,
      defaultPagination: value,
      timezone: sys.timezone,
      language: sys.language,
    );

    final success = await provider.updateSystemPreferences(updated);
    if (success) {
      setState(() {
        _defaultPagination = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Preferences'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Theme toggles
                  Text(
                    'Visual Theme & Layout',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Enable Dark Theme', style: TextStyle(fontWeight: FontWeight.bold)),
                          Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (val) {
                              themeProvider.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pagination Preferences
                  Text(
                    'Data & Pagination Lists',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<int>(
                          initialValue: _defaultPagination,
                          decoration: const InputDecoration(
                            labelText: 'Default Page Limit size',
                            border: InputBorder.none,
                          ),
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('5 records per page')),
                            DropdownMenuItem(value: 10, child: Text('10 records per page')),
                            DropdownMenuItem(value: 25, child: Text('25 records per page')),
                            DropdownMenuItem(value: 50, child: Text('50 records per page')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              _savePagination(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SMTP configuration Form
                  Text(
                    'SMTP Credentials & Mail Host',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _smtpFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _smtpHostController,
                                    decoration: const InputDecoration(labelText: 'SMTP Server Host *'),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Server is required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _smtpPortController,
                                    decoration: const InputDecoration(labelText: 'SMTP Port *'),
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Port is required';
                                      if (int.tryParse(val) == null) return 'Must be integer';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _smtpUsernameController,
                              decoration: const InputDecoration(labelText: 'SMTP Username / Account Email *'),
                              validator: (val) => val == null || val.trim().isEmpty ? 'User email is required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _smtpPasswordController,
                              decoration: InputDecoration(
                                labelText: 'SMTP Password',
                                hintText: provider.emailSettings?.passwordConfigured == true
                                    ? '•••••••• (Configured - Enter new to change)'
                                    : 'Enter password',
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _encryptionType,
                              decoration: const InputDecoration(labelText: 'Encryption Type'),
                              items: const [
                                DropdownMenuItem(value: 'TLS', child: Text('TLS / STARTTLS')),
                                DropdownMenuItem(value: 'SSL', child: Text('SSL')),
                                DropdownMenuItem(value: 'NONE', child: Text('No Encryption (Insecure)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _encryptionType = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _senderEmailController,
                              decoration: const InputDecoration(labelText: 'Sender Email Address'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _senderNameController,
                              decoration: const InputDecoration(labelText: 'Sender Display Name'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _replyEmailController,
                              decoration: const InputDecoration(labelText: 'Reply-To Email Address'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _triggerTestEmail,
                                    child: const Text('Test Connection'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: provider.isSaving ? null : _saveSmtp,
                                    child: provider.isSaving
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Save SMTP'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fade(duration: 200.ms),
            ),
    );
  }
}
