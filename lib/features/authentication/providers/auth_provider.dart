import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/config/env.dart';

class AuthProvider extends ChangeNotifier {
  static const String _authKey = 'is_logged_in';
  static const String _userEmailKey = 'logged_in_email';
  static const String _userFirstNameKey = 'logged_in_first_name';
  static const String _userLastNameKey = 'logged_in_last_name';
  static const String _userProfileImageKey = 'logged_in_profile_image';

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserEmail;
  String? _currentUserFirstName;
  String? _currentUserLastName;
  String? _currentUserProfileImage;

  // Temp storage during signup/recovery flows
  String? _tempEmail;
  
  // Pending verification state persistence
  String? _pendingVerificationEmail;
  bool _isEmailUnverified = false;

  AuthProvider() {
    _checkLoginStatus();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserFirstName => _currentUserFirstName;
  String? get currentUserLastName => _currentUserLastName;
  String? get currentUserProfileImage => _currentUserProfileImage;
  String? get tempEmail => _tempEmail;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  bool get isEmailUnverified => _isEmailUnverified;

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool(_authKey) ?? false;
      _pendingVerificationEmail = prefs.getString('pending_verification_email');
      if (_isAuthenticated) {
        _currentUserEmail = prefs.getString(_userEmailKey) ?? 'admin@prabhim.com';
        _currentUserFirstName = prefs.getString(_userFirstNameKey);
        _currentUserLastName = prefs.getString(_userLastNameKey);
        _currentUserProfileImage = prefs.getString(_userProfileImageKey);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking login status: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _isEmailUnverified = false;
    notifyListeners();

    try {
      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/login');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bool isSuccess = (responseData is Map && responseData['success'] == true) || response.statusCode == 200;
        if (isSuccess) {
          final data = (responseData is Map) ? (responseData['data'] ?? {}) : {};
          final accessToken = data['access'] ?? '';
          final refreshToken = data['refresh'] ?? '';
          final user = data['user'] ?? {};
          final userEmail = user['email'] ?? email.trim();
          final userFirstName = user['firstName'] ?? user['first_name'] ?? '';
          final userLastName = user['lastName'] ?? user['last_name'] ?? '';
          final userProfileImage = user['profile_image'] ?? user['profileImage'] ?? user['profilePic'] ?? '';

          _isAuthenticated = true;
          _currentUserEmail = userEmail;
          _currentUserFirstName = userFirstName;
          _currentUserLastName = userLastName;
          _currentUserProfileImage = userProfileImage;
          _pendingVerificationEmail = null;
          _isEmailUnverified = false;
          _isLoading = false;

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_authKey, true);
            await prefs.setString(_userEmailKey, userEmail);
            await prefs.setString(_userFirstNameKey, userFirstName);
            await prefs.setString(_userLastNameKey, userLastName);
            await prefs.setString(_userProfileImageKey, userProfileImage);
            await prefs.setString('access_token', accessToken);
            await prefs.setString('refresh_token', refreshToken);
            await prefs.remove('pending_verification_email');
          } catch (e) {
            debugPrint('Error saving login state: $e');
          }

          notifyListeners();
          return true;
        } else {
          _errorMessage = _extractErrorMessage(responseData, response.statusCode);
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final bodyLower = response.body.toLowerCase();
        if (bodyLower.contains('email not verified') || bodyLower.contains('verify your email')) {
          _isEmailUnverified = true;
          _tempEmail = email.trim();
          _pendingVerificationEmail = email.trim();
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('pending_verification_email', email.trim());
          } catch (e) {
            debugPrint('Error saving pending verification email: $e');
          }
        }

        _errorMessage = _extractErrorMessage(responseData, response.statusCode);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error. Please check your backend connection. Details: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    String? businessName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/register');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'phone': phone.trim(),
        }),
      );

      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bool isSuccess = (responseData is Map && responseData['success'] == true) || response.statusCode == 200 || response.statusCode == 201;
        if (isSuccess) {
          _tempEmail = email.trim();
          _pendingVerificationEmail = email.trim();
          _isEmailUnverified = true;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('pending_verification_email', email.trim());
          } catch (e) {
            debugPrint('Error saving pending verification email: $e');
          }
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = _extractErrorMessage(responseData, response.statusCode);
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = _extractErrorMessage(responseData, response.statusCode);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error. Please check your backend connection. Details: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }

  String _extractErrorMessage(dynamic responseData, int statusCode) {
    if (responseData is Map) {
      if (responseData.containsKey('errors')) {
        final errorsObj = responseData['errors'];
        if (errorsObj is Map) {
          final List<String> fieldErrors = [];
          errorsObj.forEach((key, val) {
            if (val is List) {
              fieldErrors.add('${_capitalize(key.toString())}: ${val.join(', ')}');
            } else {
              fieldErrors.add('${_capitalize(key.toString())}: $val');
            }
          });
          if (fieldErrors.isNotEmpty) {
            return fieldErrors.join('\n');
          }
        } else if (errorsObj is List) {
          return errorsObj.join('\n');
        } else if (errorsObj != null) {
          return errorsObj.toString();
        }
      }

      if (responseData.containsKey('message') && responseData['message'] != null) {
        final msg = responseData['message'].toString().trim();
        if (msg.isNotEmpty) return msg;
      }

      if (responseData.containsKey('error') && responseData['error'] != null) {
        final err = responseData['error'].toString().trim();
        if (err.isNotEmpty) return err;
      }
    }
    return 'Server error (Status $statusCode). Please try again.';
  }

  Future<bool> verifyOtp(String otp, {required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/verify-email');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'otp': otp.trim(),
        }),
      );

      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bool isSuccess = (responseData is Map && responseData['success'] == true) || response.statusCode == 200;
        if (isSuccess) {
          _pendingVerificationEmail = null;
          _isEmailUnverified = false;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('pending_verification_email');
          } catch (e) {
            debugPrint('Error clearing pending verification email: $e');
          }
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = _extractErrorMessage(responseData, response.statusCode);
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = _extractErrorMessage(responseData, response.statusCode);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error. Details: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOtp({required String email, required String purpose}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/resend-otp');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'purpose': purpose.trim(),
        }),
      );

      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bool isSuccess = (responseData is Map && responseData['success'] == true) || response.statusCode == 200;
        if (isSuccess) {
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = _extractErrorMessage(responseData, response.statusCode);
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = _extractErrorMessage(responseData, response.statusCode);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error. Details: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendForgotPasswordOtp(String email) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }

    _tempEmail = email.trim();
    return await resendOtp(email: email.trim(), purpose: 'password_reset');
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (newPassword.length < 6) {
      _isLoading = false;
      _errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    if (newPassword != confirmPassword) {
      _isLoading = false;
      _errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }

    try {
      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/reset-password');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'otp': otp.trim(),
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bool isSuccess = (responseData is Map && responseData['success'] == true) || response.statusCode == 200;
        if (isSuccess) {
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = _extractErrorMessage(responseData, response.statusCode);
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = _extractErrorMessage(responseData, response.statusCode);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error. Details: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/token/refresh');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = jsonDecode(response.body);
        final newAccess = data['access'] ?? (data['data'] != null ? data['data']['access'] : null);
        final newRefresh = data['refresh'] ?? (data['data'] != null ? data['data']['refresh'] : null);

        if (newAccess != null) {
          await prefs.setString('access_token', newAccess.toString());
        }
        if (newRefresh != null) {
          await prefs.setString('refresh_token', newRefresh.toString());
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
    }
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      final accessToken = prefs.getString('access_token');

      if (refreshToken != null && refreshToken.isNotEmpty) {
        final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/logout');
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({'refresh': refreshToken}),
        );
      }
    } catch (e) {
      debugPrint('Error calling logout API: $e');
    }

    _isAuthenticated = false;
    _currentUserEmail = null;
    _currentUserFirstName = null;
    _currentUserLastName = null;
    _currentUserProfileImage = null;
    _isLoading = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_authKey, false);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userFirstNameKey);
      await prefs.remove(_userLastNameKey);
      await prefs.remove(_userProfileImageKey);
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    } catch (e) {
      debugPrint('Error clearing login state: $e');
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) return null;

      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/me');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        final data = (responseData is Map && responseData['data'] != null)
            ? responseData['data']
            : responseData;
        if (data is Map) {
          _currentUserEmail = data['email'] ?? _currentUserEmail;
          _currentUserFirstName = data['firstName'] ?? data['first_name'] ?? _currentUserFirstName;
          _currentUserLastName = data['lastName'] ?? data['last_name'] ?? _currentUserLastName;
          _currentUserProfileImage = data['profile_image'] ?? data['profileImage'] ?? _currentUserProfileImage;

          if (_currentUserEmail != null) await prefs.setString(_userEmailKey, _currentUserEmail!);
          if (_currentUserFirstName != null) await prefs.setString(_userFirstNameKey, _currentUserFirstName!);
          if (_currentUserLastName != null) await prefs.setString(_userLastNameKey, _currentUserLastName!);
          if (_currentUserProfileImage != null) await prefs.setString(_userProfileImageKey, _currentUserProfileImage!);

          notifyListeners();
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Error fetching current user profile: $e');
    }
    return null;
  }

  Future<bool> updateUserProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/profile/');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final success = responseData['success'] ?? false;
        if (success) {
          final data = responseData['data'] ?? {};
          final userFirstName = data['first_name'] ?? firstName;
          final userLastName = data['last_name'] ?? lastName;
          final userProfileImage = data['profile_image'] ?? '';

          _currentUserFirstName = userFirstName;
          _currentUserLastName = userLastName;
          _currentUserProfileImage = userProfileImage;
          
          await prefs.setString(_userFirstNameKey, userFirstName);
          await prefs.setString(_userLastNameKey, userLastName);
          await prefs.setString(_userProfileImageKey, userProfileImage);
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to update profile.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = responseData['message'] ?? 'Server error. Status: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfileImage(XFile file) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/profile/image/');
      final request = http.MultipartRequest('POST', url);
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'profile_image',
          await file.readAsBytes(),
          filename: file.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          file.path,
        ));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final success = responseData['success'] ?? false;
        if (success) {
          final data = responseData['data'] ?? {};
          final userProfileImage = data['profile_image'] ?? '';

          _currentUserProfileImage = userProfileImage;
          await prefs.setString(_userProfileImageKey, userProfileImage);
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to upload profile image.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = responseData['message'] ?? 'Server error. Status: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProfileImage() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/profile/image/');
      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final success = responseData['success'] ?? false;
        if (success) {
          _currentUserProfileImage = null;
          await prefs.remove(_userProfileImageKey);
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to delete profile image.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = responseData['message'] ?? 'Server error. Status: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
