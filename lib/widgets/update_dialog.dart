import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import '../models/app_version.dart';
import '../services/update_service.dart';

enum DownloadStatus { idle, downloading, completed, error }

class UpdateDialog extends StatefulWidget {
  final AppVersion update;
  final String currentVersion;

  const UpdateDialog({
    super.key,
    required this.update,
    required this.currentVersion,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final UpdateService _updateService = UpdateService();
  DownloadStatus _status = DownloadStatus.idle;
  double _progress = 0.0;
  String? _errorMessage;
  CancelToken? _cancelToken;
  String? _localApkPath;

  @override
  void dispose() {
    _cancelToken?.cancel('Dialog disposed');
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _status = DownloadStatus.downloading;
      _progress = 0.0;
      _errorMessage = null;
    });

    _cancelToken = CancelToken();

    try {
      final localPath = await _updateService.downloadApk(
        widget.update.apkUrl,
        (received, total) {
          if (total > 0) {
            setState(() {
              _progress = received / total;
            });
          }
        },
        _cancelToken!,
      );

      setState(() {
        _status = DownloadStatus.completed;
        _localApkPath = localPath;
      });

      // Automatically launch installation
      await _installApk(localPath);
    } catch (e) {
      if (CancelToken.isCancel(e as DioException)) {
        setState(() {
          _status = DownloadStatus.idle;
        });
      } else {
        setState(() {
          _status = DownloadStatus.error;
          _errorMessage = e.toString().contains('cancel')
              ? 'Download cancelled.'
              : 'Download failed. Please try again.';
        });
      }
    }
  }

  Future<void> _installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        setState(() {
          _status = DownloadStatus.error;
          _errorMessage = 'Unable to open installer: ${result.message}';
        });
      }
    } catch (e) {
      setState(() {
        _status = DownloadStatus.error;
        _errorMessage = 'Unable to open installer. Permission denied or package error.';
      });
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel('Cancelled by user');
    setState(() {
      _status = DownloadStatus.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build the dialog content based on download status
    return PopScope(
      canPop: !widget.update.forceUpdate && _status != DownloadStatus.downloading,
      child: Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Block
              Row(
                children: [
                  Icon(
                    Icons.system_update_rounded,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'New Update Available',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Version details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Current Version',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.currentVersion,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary, size: 20),
                    Column(
                      children: [
                        Text(
                          'Latest Version',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.update.version,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic Area
              if (_status == DownloadStatus.idle) ...[
                // Release notes list
                if (widget.update.releaseNotes.isNotEmpty) ...[
                  Text(
                    'What\'s New',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.update.releaseNotes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.update.releaseNotes[index],
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!widget.update.forceUpdate)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Later'),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _startDownload,
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ] else if (_status == DownloadStatus.downloading) ...[
                // Download state
                Text(
                  'Downloading Update...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (!widget.update.forceUpdate)
                  TextButton(
                    onPressed: _cancelDownload,
                    child: const Text('Cancel'),
                  ),
              ] else if (_status == DownloadStatus.completed) ...[
                // Completed state
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Download Finished',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please install the application package to complete the update.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!widget.update.forceUpdate)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _installApk(_localApkPath!),
                      child: const Text('Install Now'),
                    ),
                  ],
                ),
              ] else if (_status == DownloadStatus.error) ...[
                // Error state
                Icon(
                  Icons.error_outline_rounded,
                  color: theme.colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Download Failed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!widget.update.forceUpdate)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _status = DownloadStatus.idle;
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _startDownload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
