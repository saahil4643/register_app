import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Callback triggered when a token refresh fails and the user is unauthorized.
  VoidCallback? onUnauthorized;

  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  Future<Map<String, dynamic>> get(String path) async {
    return _sendWithRetry('GET', path);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    return _sendWithRetry('POST', path, body: body);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    return _sendWithRetry('PUT', path, body: body);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    return _sendWithRetry('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _sendWithRetry('DELETE', path);
  }

  String _resolvePath(String path) {
    var p = path;
    if (p.startsWith('/api/') && !p.startsWith('/api/v1/')) {
      p = p.replaceFirst('/api/', '/api/v1/');
    }
    if (p.length > 1 && p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p;
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fileFieldName,
    required dynamic file,
    Map<String, String>? fields,
  }) async {
    final resolvedPath = _resolvePath(path);
    final url = resolvedPath.startsWith('http') ? Uri.parse(resolvedPath) : Uri.parse('${Env.apiBaseUrl}$resolvedPath');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final request = http.MultipartRequest('POST', url);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final String filename = file.name ?? 'upload.jpg';
      request.files.add(http.MultipartFile.fromBytes(
        fileFieldName,
        bytes,
        filename: filename,
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        fileFieldName,
        file.path,
        filename: file.name,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> _sendWithRetry(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final resolvedPath = _resolvePath(path);
    final url = resolvedPath.startsWith('http') ? Uri.parse(resolvedPath) : Uri.parse('${Env.apiBaseUrl}$resolvedPath');
    var headers = await _getHeaders();

    debugPrint('ApiService $method: $url');
    http.Response response;
    
    if (method == 'GET') {
      response = await http.get(url, headers: headers);
    } else if (method == 'POST') {
      response = await http.post(url, headers: headers, body: body != null ? jsonEncode(body) : null);
    } else if (method == 'PUT') {
      response = await http.put(url, headers: headers, body: body != null ? jsonEncode(body) : null);
    } else if (method == 'PATCH') {
      response = await http.patch(url, headers: headers, body: body != null ? jsonEncode(body) : null);
    } else if (method == 'DELETE') {
      response = await http.delete(url, headers: headers);
    } else {
      throw UnsupportedError('Method $method not supported');
    }

    if (response.statusCode == 401) {
      debugPrint('ApiService received 401. Attempting token refresh...');
      final refreshSuccess = await _attemptTokenRefresh();
      if (refreshSuccess) {
        debugPrint('Token refresh succeeded. Retrying request $method to $path...');
        headers = await _getHeaders();
        if (method == 'GET') {
          response = await http.get(url, headers: headers);
        } else if (method == 'POST') {
          response = await http.post(url, headers: headers, body: body != null ? jsonEncode(body) : null);
        } else if (method == 'PUT') {
          response = await http.put(url, headers: headers, body: body != null ? jsonEncode(body) : null);
        } else if (method == 'PATCH') {
          response = await http.patch(url, headers: headers, body: body != null ? jsonEncode(body) : null);
        } else if (method == 'DELETE') {
          response = await http.delete(url, headers: headers);
        }
      } else {
        debugPrint('Token refresh failed. Triggering onUnauthorized callback...');
        onUnauthorized?.call();
      }
    }

    return _processResponse(response);
  }

  Future<Uint8List?> getBytes(String path) async {
    final resolvedPath = _resolvePath(path);
    final url = resolvedPath.startsWith('http') ? Uri.parse(resolvedPath) : Uri.parse('${Env.apiBaseUrl}$resolvedPath');
    var headers = await _getHeaders();
    
    debugPrint('ApiService GET Bytes: $url');
    var response = await http.get(url, headers: headers);
    
    if (response.statusCode == 401) {
      debugPrint('ApiService GET Bytes received 401. Attempting token refresh...');
      final refreshSuccess = await _attemptTokenRefresh();
      if (refreshSuccess) {
        debugPrint('Token refresh succeeded. Retrying GET Bytes...');
        headers = await _getHeaders();
        response = await http.get(url, headers: headers);
      } else {
        onUnauthorized?.call();
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    return null;
  }

  Future<bool> _attemptTokenRefresh() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('No refresh token available.');
        _refreshCompleter!.complete(false);
        _isRefreshing = false;
        return false;
      }

      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/token/refresh');
      debugPrint('POST token refresh: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'] ?? {};
          final newAccessToken = data['access'] ?? '';
          
          if (newAccessToken.isNotEmpty) {
            await prefs.setString('access_token', newAccessToken);
            if (data['refresh'] != null && data['refresh'].toString().isNotEmpty) {
              await prefs.setString('refresh_token', data['refresh']);
            }
            debugPrint('Access token refreshed successfully.');
            _refreshCompleter!.complete(true);
            _isRefreshing = false;
            return true;
          }
        }
      }

      debugPrint('Token refresh endpoint returned non-success code: ${response.statusCode}');
      _refreshCompleter!.complete(false);
      _isRefreshing = false;
      return false;
    } catch (e) {
      debugPrint('Exception during token refresh: $e');
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }
      _isRefreshing = false;
      return false;
    }
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    final int statusCode = response.statusCode;
    final String bodyString = response.body;
    
    dynamic decoded;
    try {
      decoded = jsonDecode(bodyString);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse response body. Code: $statusCode',
      };
    }

    if (decoded is List) {
      if (statusCode >= 200 && statusCode < 300) {
        return {
          'success': true,
          'data': decoded,
          'statusCode': statusCode,
        };
      } else {
        return {
          'success': false,
          'statusCode': statusCode,
          'message': 'HTTP Error $statusCode',
          'data': decoded,
        };
      }
    }

    final Map<String, dynamic> json = decoded is Map<String, dynamic>
        ? decoded
        : (decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{});

    if (statusCode >= 200 && statusCode < 300) {
      return json;
    } else {
      return {
        'success': false,
        'statusCode': statusCode,
        'message': json['message'] ?? _parseFieldErrors(json) ?? 'HTTP Error $statusCode',
        'errors': json['errors'] ?? json,
      };
    }
  }

  String? _parseFieldErrors(Map<String, dynamic> json) {
    if (json.containsKey('errors')) {
      final err = json['errors'];
      if (err is Map) {
        final List<String> msgs = [];
        err.forEach((key, value) {
          if (value is List) {
            msgs.add('$key: ${value.join(', ')}');
          } else {
            msgs.add('$key: $value');
          }
        });
        return msgs.join('\n');
      }
    }
    final List<String> msgs = [];
    json.forEach((key, value) {
      if (key != 'success' && key != 'message' && key != 'code') {
        if (value is List) {
          msgs.add('$key: ${value.join(', ')}');
        } else if (value is String) {
          msgs.add('$key: $value');
        }
      }
    });
    return msgs.isNotEmpty ? msgs.join('\n') : null;
  }
}
