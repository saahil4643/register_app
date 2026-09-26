import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../features/settings/providers/settings_provider.dart';
import '../widgets/update_dialog.dart';

class IntegrateUpdateButton extends StatefulWidget {
  const IntegrateUpdateButton({super.key});

  @override
  State<IntegrateUpdateButton> createState() => _IntegrateUpdateButtonState();
}

class _IntegrateUpdateButtonState extends State<IntegrateUpdateButton> {
  String _versionString = 'Loading...';
  String _rawVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _rawVersion = packageInfo.version;
          _versionString = 'v${packageInfo.version} (Build ${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rawVersion = '1.0.0';
          _versionString = 'v1.0.0 (Build 1)';
        });
      }
    }
  }

  Future<void> _handleCheckForUpdates() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<SettingsProvider>();

    try {
      final update = await provider.checkForAppUpdates();
      if (!mounted) return;

      if (update == null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("You're using the latest version.\nVersion $_rawVersion"),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: !update.forceUpdate,
          builder: (_) => UpdateDialog(
            update: update,
            currentVersion: _rawVersion,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Unable to check for updates.\nPlease try again later."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SettingsProvider>();
    final isChecking = provider.isCheckingForUpdates;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Version',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _versionString,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.disabledColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(),
              ),
              InkWell(
                onTap: isChecking ? null : _handleCheckForUpdates,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Check for Updates',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isChecking ? theme.disabledColor : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      if (isChecking)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
