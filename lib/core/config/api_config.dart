import 'env.dart';

class ApiConfig {
  /// Base API URL derived dynamically from environment configurations
  static String get baseUrl => Env.apiBaseUrl;
}
