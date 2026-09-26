import '../core/services/api_service.dart';
import '../models/app_version.dart';

class UpdateRepository {
  final ApiService _apiService = ApiService();

  /// Fetches the latest version metadata from the backend.
  Future<AppVersion> fetchLatestVersion() async {
    final response = await _apiService.get('/api/app/version/');
    return AppVersion.fromJson(response);
  }
}
