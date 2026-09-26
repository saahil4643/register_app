import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_buttons.dart';
import '../../../core/widgets/custom_inputs.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must agree to the Terms of Service & Privacy Policy.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();

      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final success = await authProvider.signup(
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        businessName: _businessNameController.text.trim(),
      );

      if (mounted) {
        if (success) {
          context.push('/success', extra: {
            'title': 'Account Created Successfully!',
            'description': 'Your Prabhim One account has been created. Let\'s verify your identity next.',
            'buttonText': 'Proceed to Verification',
            'routePath': '/otp-verify',
          });
        } else {
          showDialog(
            context: context,
            builder: (context) => ErrorDialog(
              title: 'Registration Failed',
              content: authProvider.errorMessage ?? 'Unable to create account.',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Free Account',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ).animate().fade().slideX(begin: -0.1),
                const SizedBox(height: 8),
                Text(
                  'Start managing your invoicing and accounts in minutes.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ).animate().fade(delay: 100.ms),
                const SizedBox(height: 28),

                // Name field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'Full Name',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                  ],
                ).animate().fade(delay: 150.ms).slideY(begin: 0.1),
                const SizedBox(height: 18),

                // Business Name field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'Business Name',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _businessNameController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'e.g. Prabhim One',
                        prefixIcon: Icon(
                          Icons.business_outlined,
                          size: 20,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your business name';
                        }
                        return null;
                      },
                    ),
                  ],
                ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 18),

                // Phone field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'Phone Number',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'e.g. +1234567890',
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          size: 20,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                        if (digitsOnly.length > 10) {
                          return 'Phone number cannot be greater than 10 digits';
                        }
                        return null;
                      },
                    ),
                  ],
                ).animate().fade(delay: 220.ms).slideY(begin: 0.1),
                const SizedBox(height: 18),

                // Email field
                CustomEmailField(
                  controller: _emailController,
                  hint: 'email@example.com',
                ).animate().fade(delay: 250.ms).slideY(begin: 0.1),
                const SizedBox(height: 18),

                // Password field
                CustomPasswordField(
                  controller: _passwordController,
                  hint: 'At least 6 characters',
                  textInputAction: TextInputAction.done,
                ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                const SizedBox(height: 18),

                // Terms and Conditions checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      activeColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _agreeTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          'I agree to the Prabhim One Terms of Service and Privacy Policy.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 350.ms),
                const SizedBox(height: 28),

                // Sign up button
                CustomPrimaryButton(
                  text: 'Create Account',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleSignup,
                ).animate().fade(delay: 400.ms),
                const SizedBox(height: 24),

                // Sign in prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    CustomTextButton(
                      text: 'Sign In',
                      onPressed: () => context.push('/login'),
                    ),
                  ],
                ).animate().fade(delay: 450.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
