import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_buttons.dart';
import '../../../core/widgets/custom_inputs.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ResetPasswordScreen({
    super.key,
    this.arguments,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _otpController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final initialEmail = widget.arguments?['email'] ?? authProvider.tempEmail ?? '';
    final initialOtp = widget.arguments?['otp'] ?? '';
    _emailController = TextEditingController(text: initialEmail);
    _otpController = TextEditingController(text: initialOtp);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
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
      final email = _emailController.text.trim();
      final otp = _otpController.text.trim();

      final success = await authProvider.resetPassword(
        email: email,
        otp: otp,
        newPassword: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully! Please log in with your new password.'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/login');
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

                const SizedBox(height: 36),

                // Email field (read-only if pre-filled, editable if needed)
                CustomEmailField(
                  controller: _emailController,
                  hint: 'email@example.com',
                ).animate().fade(delay: 150.ms).slideY(begin: 0.1),

                const SizedBox(height: 18),

                // OTP field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        '6-Digit OTP Code',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 15, letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: 'e.g. 123456',
                        prefixIcon: Icon(
                          Icons.pin_outlined,
                          size: 20,
                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the 6-digit OTP';
                        }
                        if (value.trim().length != 6) {
                          return 'OTP must be exactly 6 digits';
                        }
                        return null;
                      },
                    ),
                  ],
                ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 18),

                // Password field
                CustomPasswordField(
                  controller: _passwordController,
                  label: 'New Password',
                  hint: 'At least 6 characters',
                  textInputAction: TextInputAction.next,
                ).animate().fade(delay: 250.ms).slideY(begin: 0.1),

                const SizedBox(height: 18),

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
