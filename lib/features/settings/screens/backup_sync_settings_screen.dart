import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../models/settings_models.dart';
import '../providers/settings_provider.dart';

class BackupSyncSettingsScreen extends StatefulWidget {
  const BackupSyncSettingsScreen({super.key});

  @override
  State<BackupSyncSettingsScreen> createState() => _BackupSyncSettingsScreenState();
}

class _BackupSyncSettingsScreenState extends State<BackupSyncSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchBackupHistory();
    });
  }

  Future<void> _createNewBackup() async {
    final provider = context.read<SettingsProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.triggerBackup();
    if (mounted) Navigator.pop(context); // Dismiss loading

    if (mounted) {
      _showResultSnackbar(success, 'Database backup successfully triggered and saved');
    }
  }

  Future<void> _restoreBackupDialog(BackupHistory backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm System Restore'),
          content: Text(
            'Are you sure you want to restore the database to the state recorded in "${backup.backupName}"?\n\n'
            'WARNING: Any changes made after this backup was created will be permanently overwritten.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore State'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      final provider = context.read<SettingsProvider>();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final success = await provider.restoreBackup(backup.id);
      if (mounted) Navigator.pop(context); // Dismiss loading

      if (mounted) {
        _showResultSnackbar(success, 'System restore executed successfully.');
      }
    }
  }

  void _showResultSnackbar(bool success, String successMsg) {
    final provider = context.read<SettingsProvider>();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMsg),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = provider.errorMessage ?? 'An error occurred';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: provider.isLoading ? null : () => provider.fetchBackupHistory(),
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manual Backups Hub',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Generate or restore database JSON snapshots.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: provider.isSaving ? null : _createNewBackup,
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: const Text('Trigger Backup'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: provider.backupHistoryList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storage_rounded, size: 64, color: theme.disabledColor),
                              const SizedBox(height: 12),
                              const Text('No backups recorded yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: provider.backupHistoryList.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = provider.backupHistoryList[index];
                            final isSuccess = item.status == 'success';
                            return ListTile(
                              leading: Icon(
                                isSuccess ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                                color: isSuccess ? AppColors.success : AppColors.error,
                                size: 28,
                              ),
                              title: Text(item.backupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Size: ${_formatSize(item.fileSize)}  •  ${item.createdAt}'),
                              trailing: isSuccess
                                  ? TextButton.icon(
                                      onPressed: provider.isSaving ? null : () => _restoreBackupDialog(item),
                                      icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                                      label: const Text('Restore'),
                                    )
                                  : const Text('Failed', style: TextStyle(color: AppColors.error)),
                            );
                          },
                        ),
                ),
              ],
            ).animate().fade(duration: 200.ms),
    );
  }
}
