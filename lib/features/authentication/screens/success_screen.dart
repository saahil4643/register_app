import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_buttons.dart';
import '../../../core/constants/app_colors.dart';

class SuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;

  const SuccessScreen({
    super.key,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = arguments?['title'] ?? 'Operation Successful';
    final description = arguments?['description'] ?? 'Your request has been completed successfully.';
    final buttonText = arguments?['buttonText'] ?? 'Continue';
    final routePath = arguments?['routePath'] ?? '/login';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Animated Success Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.2),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: AppColors.success,
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 36),
              
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 200.ms),
              
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fade(delay: 300.ms),
              
              const Spacer(),
              
              CustomPrimaryButton(
                text: buttonText,
                onPressed: () {
                  if (routePath == '/dashboard') {
                    context.go('/dashboard');
                  } else if (routePath == '/login') {
                    context.go('/login');
                  } else {
                    context.pushReplacement(routePath);
                  }
                },
              ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
