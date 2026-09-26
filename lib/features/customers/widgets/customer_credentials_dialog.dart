import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/customer.dart';

class CustomerCredentialsDialog extends StatefulWidget {
  final Customer customer;

  const CustomerCredentialsDialog({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerCredentialsDialog> createState() => _CustomerCredentialsDialogState();
}

class _CustomerCredentialsDialogState extends State<CustomerCredentialsDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _enablePortal = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  final List<String> _permissions = [
    'View Invoices',
    'Pay Invoices',
    'Download Statements',
    'View Quotations',
  ];
  final Set<String> _selectedPermissions = {
    'View Invoices',
    'Pay Invoices',
    'Download Statements',
  };

  @override
  void initState() {
    super.initState();
    // Prefill username with customer's email or a default generated format
    _usernameController = TextEditingController(
      text: widget.customer.email.isNotEmpty 
          ? widget.customer.email 
          : '${widget.customer.name.toLowerCase().replaceAll(RegExp(r'\s+'), '')}@portal.com'
    );
    _passwordController = TextEditingController();
    _generatePassword();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    final rand = Random();
    final password = List.generate(12, (index) => chars[rand.nextInt(chars.length)]).join();
    setState(() {
      _passwordController.text = password;
    });
  }

  Future<void> _submit() async {
    if (_enablePortal && !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API request to save credentials
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _enablePortal 
              ? 'Portal credentials configured for "${widget.customer.name}"' 
              : 'Credentials setup skipped'
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    
    final dialogWidth = mediaQuery.size.width > 600 ? 500.0 : mediaQuery.size.width * 0.95;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surface : Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.vpn_key_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Portal Credentials',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Configure client login details',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.grey[850] : Colors.grey[200],
                          foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enable Portal Access Toggle
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Enable Customer Portal Access',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Allows this customer to log in to see invoice status & pay bills.',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: _enablePortal,
                            activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                            activeThumbColor: theme.colorScheme.primary,
                            onChanged: (val) {
                              setState(() {
                                _enablePortal = val;
                              });
                            },
                          ),
                          const Divider(height: 24),
                          
                          if (_enablePortal) ...[
                            // Username/Email Field
                            Text(
                              'PORTAL USERNAME / EMAIL',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Email/Username *',
                                prefixIcon: Icon(Icons.email_outlined),
                                hintText: 'customer@example.com',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter username or email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            Text(
                              'PORTAL PASSWORD',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password *',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _obscurePassword 
                                            ? Icons.visibility_outlined 
                                            : Icons.visibility_off_outlined
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Generate Random Password',
                                      icon: const Icon(Icons.autorenew_rounded),
                                      onPressed: _generatePassword,
                                    ),
                                  ],
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter password';
                                }
                                if (val.trim().length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Permissions
                            Text(
                              'PORTAL PRIVILEGES',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _permissions.map((perm) {
                                final isSelected = _selectedPermissions.contains(perm);
                                return FilterChip(
                                  label: Text(perm, style: const TextStyle(fontSize: 12)),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedPermissions.add(perm);
                                      } else {
                                        _selectedPermissions.remove(perm);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[900] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'You can enable portal access later at any time in the Customer Details screen.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surface : Colors.grey[50],
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_enablePortal ? 'Skip Setup' : 'Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_enablePortal ? 'Enable & Save' : 'Skip & Finish'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Loading Overlay
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
