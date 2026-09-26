import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AboutUsSettingsScreen extends StatelessWidget {
  const AboutUsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 100,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.auto_stories_rounded,
                  size: 100,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Prabhim One ERP',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0 (Build 100)',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 32),
            const Text(
              'Prabhim One ERP is a unified enterprise resource planning ecosystem designed to streamline client billing, product stock control, multi-currency ledger management, and automated tax reporting.\n\n'
              'Crafted for high-growth firms looking to operate transparent accounting models with zero administrative lag.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              '© 2026 Prabhim One Inc. All Rights Reserved.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'Made with ♥ for Modern Businesses.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ).animate().fade(duration: 200.ms),
      ),
    );
  }
}
