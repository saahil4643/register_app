import 'package:flutter/services.dart';

class Env {
  static String _apiBaseUrl = 'https://backend.prabhimtechnologies.in';

  static String get apiBaseUrl {
    if (_apiBaseUrl.endsWith('/')) {
      return _apiBaseUrl.substring(0, _apiBaseUrl.length - 1);
    }
    return _apiBaseUrl;
  }

  static set apiBaseUrl(String value) {
    _apiBaseUrl = value.trim();
  }

  static Future<void> init() async {
    try {
      final content = await rootBundle.loadString('assets/env.txt');
      final lines = content.split('\n');
      for (var line in lines) {
        if (line.contains('=')) {
          final parts = line.split('=');
          final key = parts[0].trim();
          final value = parts.sublist(1).join('=').trim();
          if (key == 'API_BASE_URL' && value.isNotEmpty) {
            apiBaseUrl = value;
          }
        }
      }
    } catch (e) {
      // Fallback is already set
    }
  }
}
