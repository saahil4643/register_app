class AppVersion {
  final bool success;
  final String version;
  final int buildNumber;
  final bool forceUpdate;
  final List<String> releaseNotes;
  final String apkUrl;
  final String? message;

  AppVersion({
    required this.success,
    required this.version,
    required this.buildNumber,
    required this.forceUpdate,
    required this.releaseNotes,
    required this.apkUrl,
    this.message,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      success: json['success'] ?? false,
      version: json['version'] ?? '',
      buildNumber: json['build_number'] ?? 0,
      forceUpdate: json['force_update'] ?? false,
      releaseNotes: List<String>.from(json['release_notes'] ?? []),
      apkUrl: json['apk_url'] ?? '',
      message: json['message'],
    );
  }
}
