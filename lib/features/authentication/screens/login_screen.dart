import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_buttons.dart';
import '../../../core/widgets/custom_inputs.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      if (_usernameController.text.isEmpty && authProvider.tempEmail != null && authProvider.tempEmail!.isNotEmpty) {
        setState(() {
          _usernameController.text = authProvider.tempEmail!;
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (success) {
          context.go('/dashboard');
        } else {
          showDialog(
            context: context,
            builder: (context) => ErrorDialog(
              title: 'Login Failed',
              content: authProvider.errorMessage ?? 'Invalid username or password. Please use admin and Pass123.',
            ),
          );
        }
      }
    }
  }

  void _showSocialMock(String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sign in with $platform is currently disabled (Phase 2).'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Welcome Back',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ).animate().fade().slideX(begin: -0.1),
                const SizedBox(height: 8),
                Text(
                  'Sign in to manage your corporate operations and ledger.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ).animate().fade(delay: 100.ms),
                const SizedBox(height: 36),

                // Username field
                CustomTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'admin',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter username';
                    }
                    return null;
                  },
                ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),

                // Password field
                CustomPasswordField(
                  controller: _passwordController,
                  hint: 'Pass123',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    return null;
                  },
                ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                const SizedBox(height: 12),

                // Remember me & forgot password row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        Text(
                          'Remember me',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    CustomTextButton(
                      text: 'Forgot Password?',
                      onPressed: () => context.push('/forgot-password'),
                    ),
                  ],
                ).animate().fade(delay: 350.ms),
                const SizedBox(height: 24),

                // Login button
                CustomPrimaryButton(
                  text: 'Sign In',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleLogin,
                ).animate().fade(delay: 400.ms),
                const SizedBox(height: 28),

                // "Continue With" Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: theme.colorScheme.outline.withOpacity(0.5), thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'or continue with',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: theme.colorScheme.outline.withOpacity(0.5), thickness: 1),
                    ),
                  ],
                ).animate().fade(delay: 450.ms),
                const SizedBox(height: 24),

                // Google & Apple Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text(
                          'Google',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _showSocialMock('Google'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.apple, size: 22),
                        label: const Text(
                          'Apple',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _showSocialMock('Apple'),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 500.ms),
                const SizedBox(height: 36),

                // Sign up prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    CustomTextButton(
                      text: 'Create Account',
                      onPressed: () => context.push('/signup'),
                    ),
                  ],
                ).animate().fade(delay: 550.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
