import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_version.dart';
import '../repositories/update_repository.dart';

class UpdateService {
  final UpdateRepository _repository;
  final Dio _dio;

  UpdateService({UpdateRepository? repository, Dio? dio})
      : _repository = repository ?? UpdateRepository(),
        _dio = dio ?? Dio();

  /// Gets the currently installed app version and build number.
  Future<Map<String, dynamic>> getCurrentVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'version': packageInfo.version,
      'buildNumber': int.tryParse(packageInfo.buildNumber) ?? 0,
    };
  }

  /// Checks if an update is available by querying the backend and comparing semantic versions.
  /// Returns the AppVersion if a newer build exists, otherwise returns null.
  Future<AppVersion?> checkForUpdate() async {
    final latestAppVersion = await _repository.fetchLatestVersion();
    if (!latestAppVersion.success) {
      return null;
    }

    final currentInfo = await getCurrentVersionInfo();
    final currentVersion = currentInfo['version'] as String;

    if (_isNewerVersion(latestAppVersion.version, currentVersion)) {
      return latestAppVersion;
    }
    return null;
  }

  /// Compares two version strings semantically (e.g. "1.1.0" vs "1.0.0").
  /// Returns true if the latest version is greater than the current version.
  bool _isNewerVersion(String latestVersion, String currentVersion) {
    try {
      final latestParts = latestVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      final maxLength = latestParts.length > currentParts.length 
          ? latestParts.length 
          : currentParts.length;

      for (var i = 0; i < maxLength; i++) {
        final latestPart = i < latestParts.length ? latestParts[i] : 0;
        final currentPart = i < currentParts.length ? currentParts[i] : 0;

        if (latestPart > currentPart) {
          return true;
        } else if (latestPart < currentPart) {
          return false;
        }
      }
      return false;
    } catch (e) {
      // Fallback comparison
      return latestVersion != currentVersion && latestVersion.compareTo(currentVersion) > 0;
    }
  }

  /// Downloads the APK and returns the local file path.
  Future<String> downloadApk(
    String url,
    Function(int received, int total) onProgress,
    CancelToken cancelToken,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/app-update.apk';

    // Delete any existing file at that path first to prevent conflicts
    final file = File(savePath);
    if (await file.exists()) {
      await file.delete();
    }

    final response = await _dio.download(
      url,
      savePath,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
    );

    if (response.statusCode == 200) {
      return savePath;
    } else {
      throw Exception('Failed to download file. Code: ${response.statusCode}');
    }
  }
}
