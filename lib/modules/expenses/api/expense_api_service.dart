import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';

class ExpenseApiService {
  late final Dio _dio;

  ExpenseApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // Logging only in debug mode
    if (!kReleaseMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ));
    }

    // Interceptor to inject JWT Access tokens and auto-refresh them when expired
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        final response = error.response;
        // Verify if unauthorized and can be refreshed
        if (response?.statusCode == 401) {
          final isRefreshed = await _refreshAccessToken();
          if (isRefreshed) {
            // Retrieve new token and retry original request
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('access_token');
            final options = error.requestOptions;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            
            try {
              final retryResponse = await _dio.fetch(options);
              return handler.resolve(retryResponse);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          } else {
            // Logout user on refresh failure
            await _logoutUser();
          }
        }
        return handler.next(error);
      },
    ));
  }

  /// Request access token refresh
  Future<bool> _refreshAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // Isolated clean Dio client to prevent recursion
      final cleanDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      final response = await cleanDio.post(
        '/api/v1/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        final success = body['success'] ?? false;
        if (success) {
          final data = body['data'] ?? {};
          final accessToken = data['access'] ?? '';
          final newRefresh = data['refresh'] ?? '';
          if (accessToken.isNotEmpty) {
            await prefs.setString('access_token', accessToken);
            if (newRefresh.isNotEmpty) {
              await prefs.setString('refresh_token', newRefresh);
            }
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Failed to refresh access token: $e');
      return false;
    }
  }

  /// Reset auth status in SharedPreferences on session expiry
  Future<void> _logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    } catch (e) {
      debugPrint('Error logging out user: $e');
    }
  }

  /// Parse backend errors to user-facing strings
  String handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Network connection timed out. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Please verify your backend server is active.';
    } else if (error.response != null) {
      final status = error.response!.statusCode;
      final data = error.response!.data;

      if (data is Map) {
        if (status == 400 && data.containsKey('errors')) {
          final errorsObj = data['errors'] as Map;
          final List<String> fieldErrors = [];
          errorsObj.forEach((key, val) {
            if (val is List) {
              fieldErrors.add('${key.toUpperCase()}: ${val.join(', ')}');
            } else {
              fieldErrors.add('${key.toUpperCase()}: $val');
            }
          });
          return fieldErrors.join('\n');
        }
        return data['message'] ?? 'Server validation error ($status).';
      }
      return 'Server error status: $status';
    }
    return 'An unexpected error occurred: ${error.message}';
  }

  // API Methods

  /// GET /api/v1/expenses/dashboard/
  Future<Response> fetchDashboard() async {
    return await _dio.get('/api/v1/expenses/dashboard/');
  }

  /// GET /api/v1/expenses/categories/
  Future<Response> fetchCategories() async {
    return await _dio.get('/api/v1/expenses/categories/');
  }

  /// GET /api/v1/expenses/vendors/
  Future<Response> fetchVendors({String? search}) async {
    return await _dio.get(
      '/api/v1/expenses/vendors/',
      queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
    );
  }

  /// GET /api/v1/expenses/recent/
  Future<Response> fetchRecentExpenses() async {
    return await _dio.get('/api/v1/expenses/recent/');
  }

  /// GET /api/v1/expenses/
  Future<Response> fetchExpenses({Map<String, dynamic>? queryParameters}) async {
    return await _dio.get('/api/v1/expenses/', queryParameters: queryParameters);
  }

  /// GET /api/v1/expenses/{id}/
  Future<Response> fetchExpenseDetails(String id) async {
    return await _dio.get('/api/v1/expenses/$id/');
  }

  /// POST /api/v1/expenses/
  Future<Response> createExpense(Map<String, dynamic> data, {File? file}) async {
    if (file != null) {
      data['attachment'] = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      );
    }
    final formData = FormData.fromMap(data);
    return await _dio.post('/api/v1/expenses/', data: formData);
  }

  /// PUT /api/v1/expenses/{id}/ (or PATCH to prevent partial reset concerns)
  Future<Response> updateExpense(String id, Map<String, dynamic> data, {File? file}) async {
    if (file != null) {
      data['attachment'] = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      );
    }
    final formData = FormData.fromMap(data);
    return await _dio.patch('/api/v1/expenses/$id/', data: formData);
  }

  /// DELETE /api/v1/expenses/{id}/
  Future<Response> deleteExpense(String id) async {
    return await _dio.delete('/api/v1/expenses/$id/');
  }
}
