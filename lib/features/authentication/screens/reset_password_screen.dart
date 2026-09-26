import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_buttons.dart';
import '../../../core/widgets/custom_inputs.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.resetPassword(_passwordController.text);

      if (mounted) {
        if (success) {
          context.push('/success', extra: {
            'title': 'Password Reset Success!',
            'description': 'Your password has been reset successfully. You can now log in with your new password.',
            'buttonText': 'Back to Login',
            'routePath': '/login',
          });
        } else {
          showDialog(
            context: context,
            builder: (context) => ErrorDialog(
              title: 'Reset Failed',
              content: authProvider.errorMessage ?? 'Unable to reset password.',
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // Illustration Icon Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_open_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ).animate().fade().scale(duration: 400.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 32),

                Text(
                  'Reset Password',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fade().slideY(begin: -0.1),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Set a secure, brand-new password to safeguard your enterprise ledger account.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fade(delay: 100.ms),

                const SizedBox(height: 48),

                // Password field
                CustomPasswordField(
                  controller: _passwordController,
                  label: 'New Password',
                  hint: 'Enter new password',
                  textInputAction: TextInputAction.next,
                ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // Confirm Password field
                CustomPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm your new password',
                  textInputAction: TextInputAction.done,
                ).animate().fade(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 36),

                // Reset button
                CustomPrimaryButton(
                  text: 'Reset & Update Password',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleReset,
                ).animate().fade(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
