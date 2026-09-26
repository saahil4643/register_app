import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_buttons.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const OtpVerificationScreen({
    super.key,
    this.arguments,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  int _timerSeconds = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _timerSeconds = 59;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onKeyPress(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
  }

  String _getOtpCode() {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _handleVerify() async {
    final otpCode = _getOtpCode();
    if (otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final email = widget.arguments?['email'] ?? authProvider.tempEmail ?? authProvider.pendingVerificationEmail ?? '';
    final success = await authProvider.verifyOtp(otpCode, email: email);

    if (mounted) {
      if (success) {
        final isForgotPassword = widget.arguments?['isForgotPassword'] ?? false;
        if (isForgotPassword) {
          context.push('/reset-password');
        } else {
          context.push('/success', extra: {
            'title': 'Verification Successful!',
            'description': 'Welcome to Prabhim One. Your account has been verified. Please log in to continue.',
            'buttonText': 'Go to Login',
            'routePath': '/login',
          });
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            title: 'Verification Failed',
            content: authProvider.errorMessage ?? 'Invalid OTP code. Please try again.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final email = widget.arguments?['email'] ?? authProvider.tempEmail ?? authProvider.pendingVerificationEmail ?? 'your email';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              
              // Animated Icon Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ).animate().fade().scale(duration: 400.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 32),
              
              Text(
                'Verify Account',
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
                  'We sent a 6-digit verification code to $email. Enter it below to proceed.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fade(delay: 100.ms),
              
              const SizedBox(height: 48),

              // OTP Inputs Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 48,
                    height: 58,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _onKeyPress(index, value),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        counterText: '',
                        fillColor: isDark ? theme.colorScheme.surface : Colors.grey[100],
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? theme.colorScheme.outline : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 36),

              // Resend OTP & Live Timer
              Column(
                children: [
                  if (_timerSeconds > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: theme.colorScheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'Resend code in ${_timerSeconds}s',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        CustomTextButton(
                          text: 'Resend Code',
                          onPressed: () async {
                            final isForgotPassword = widget.arguments?['isForgotPassword'] ?? false;
                            final success = await authProvider.resendOtp(
                              email: email,
                              purpose: isForgotPassword ? 'password_reset' : 'registration',
                            );
                            if (success) {
                              _startTimer();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('A new OTP has been sent to $email.'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } else {
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => ErrorDialog(
                                    title: 'Resend Failed',
                                    content: authProvider.errorMessage ?? 'Unable to resend OTP.',
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ).animate().fade(delay: 300.ms),
              
              const SizedBox(height: 48),

              // Verify button
              CustomPrimaryButton(
                text: 'Verify & Proceed',
                isLoading: authProvider.isLoading,
                onPressed: _handleVerify,
              ).animate().fade(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
