import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_buttons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      body: Stack(
        children: [
          // Subtle top-right premium background purple radial glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                    theme.colorScheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // App Logo Container (Purple rounded square with document icon)
                  Center(
                    child: Container(
                      height: 96,
                      width: 96,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  )
                      .animate()
                      .fade(duration: 600.ms)
                      .scale(duration: 500.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 20),

                  // Prabhim Title
                  Text(
                    'Prabhim',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fade(delay: 150.ms),

                  // INVOICE Sub-Text
                  Text(
                    'I N V O I C E',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.5,
                      color: isDark ? Colors.grey[400] : Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fade(delay: 250.ms),

                  const Spacer(flex: 2),

                  // Slogan "Smart Invoicing. Stronger Business."
                  Column(
                    children: [
                      Text(
                        'Smart Invoicing.',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            fontFamily: theme.textTheme.titleLarge?.fontFamily,
                          ),
                          children: [
                            TextSpan(
                              text: 'Stronger ',
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            ),
                            TextSpan(
                              text: 'Business.',
                              style: TextStyle(color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 350.ms).slideY(begin: 0.1),

                  const SizedBox(height: 14),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Complete billing, inventory & accounting solution for small businesses.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fade(delay: 450.ms),

                  const Spacer(flex: 3),

                  // Login and Create Account Buttons
                  Column(
                    children: [
                      CustomPrimaryButton(
                        text: 'Login',
                        onPressed: () => context.push('/login'),
                      ).animate().fade(delay: 550.ms).slideY(begin: 0.1),
                      
                      const SizedBox(height: 12),
                      
                      // Secondary Create Account Button (customized to match layout reference)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => context.push('/signup'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isDark 
                                ? theme.colorScheme.primary.withValues(alpha: 0.08) 
                                : const Color(0xFFF5F3FF),
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(
                              color: isDark 
                                  ? theme.colorScheme.primary.withValues(alpha: 0.2) 
                                  : theme.colorScheme.primary.withValues(alpha: 0.12),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 650.ms).slideY(begin: 0.1),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Footer: Made with ❤️ in India
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Made with ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        '❤️',
                        style: TextStyle(fontSize: 10),
                      ),
                      Text(
                        ' in India',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 750.ms),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
