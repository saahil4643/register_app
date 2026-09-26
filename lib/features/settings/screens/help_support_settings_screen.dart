import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HelpSupportSettingsScreen extends StatelessWidget {
  const HelpSupportSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.headset_mic_rounded, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('How can we help you?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Our dedicated support team is available 24/7 to resolve any technical issues or billing inquiries.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Frequently Asked Questions',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFaqTile(
              question: 'How do I trigger a database backup?',
              answer: 'Go to Settings > Backup & Sync and click the "Trigger Backup" button. This will create a fresh JSON snapshot of your data.',
            ),
            _buildFaqTile(
              question: 'Where can I update my invoice prefix details?',
              answer: 'Open Settings > Currency and adjust any document prefix templates to change how your next invoice serial numbers are generated.',
            ),
            _buildFaqTile(
              question: 'Can I add multiple warehouse branches?',
              answer: 'Multi-branch support and warehouse management options are located in Organization Settings under the main Profile page.',
            ),
            const SizedBox(height: 32),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                title: const Text('Email Support Desk', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('support@prabhim.com'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support ticket system opening...')),
                  );
                },
              ),
            ),
          ],
        ).animate().fade(duration: 200.ms),
      ),
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Text(answer, style: const TextStyle(fontSize: 12, height: 1.4)),
          )
        ],
      ),
    );
  }
}
