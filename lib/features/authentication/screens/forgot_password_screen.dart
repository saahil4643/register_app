import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_buttons.dart';
import '../../../core/widgets/custom_inputs.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.sendForgotPasswordOtp(_emailController.text.trim());

      if (mounted) {
        if (success) {
          final email = _emailController.text.trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset OTP sent to $email.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.push('/otp-verify', extra: {
            'isForgotPassword': true,
            'email': email,
          });
        } else {
          showDialog(
            context: context,
            builder: (context) => ErrorDialog(
              title: 'Request Failed',
              content: authProvider.errorMessage ?? 'Unable to send OTP. Please try again.',
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
                    Icons.lock_reset_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ).animate().fade().scale(duration: 400.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 32),

                Text(
                  'Forgot Password',
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
                    'Enter your email address below and we\'ll send you a 6-digit code to reset your password.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fade(delay: 100.ms),

                const SizedBox(height: 48),

                // Email field
                CustomEmailField(
                  controller: _emailController,
                  hint: 'email@example.com',
                ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 36),

                // Submit button
                CustomPrimaryButton(
                  text: 'Send Verification Code',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleSubmit,
                ).animate().fade(delay: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
