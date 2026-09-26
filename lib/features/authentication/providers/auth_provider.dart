import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  String? _tempPassword;
  
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
      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/login/');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final success = responseData['success'] ?? false;
        if (success) {
          final data = responseData['data'] ?? {};
          final accessToken = data['access'] ?? '';
          final refreshToken = data['refresh'] ?? '';
          final user = data['user'] ?? {};
          final userEmail = user['email'] ?? email;
          final userFirstName = user['first_name'] ?? '';
          final userLastName = user['last_name'] ?? '';
          final userProfileImage = user['profile_image'] ?? '';

          _isAuthenticated = true;
          _currentUserEmail = userEmail;
          _currentUserFirstName = userFirstName;
          _currentUserLastName = userLastName;
          _currentUserProfileImage = userProfileImage;
          _pendingVerificationEmail = null;
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
          _errorMessage = responseData['message'] ?? 'Login failed.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // Check if error is due to unverified email
        final bodyLower = response.body.toLowerCase();
        if (bodyLower.contains('email not verified') || bodyLower.contains('verify your email')) {
          _isEmailUnverified = true;
          _tempEmail = email;
          _pendingVerificationEmail = email;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('pending_verification_email', email);
          } catch (e) {
            debugPrint('Error saving pending verification email: $e');
          }
        }

        // Parse Django Rest Framework validation errors
        String errorMsg = '';
        if (responseData.containsKey('message')) {
          errorMsg = responseData['message'].toString();
        } else if (responseData.containsKey('errors')) {
          final errorsObj = responseData['errors'];
          if (errorsObj is Map) {
            final List<String> fieldErrors = [];
            errorsObj.forEach((key, val) {
              if (val is List) {
                fieldErrors.add('${_capitalize(key)}: ${val.join(', ')}');
              } else {
                fieldErrors.add('${_capitalize(key)}: $val');
              }
            });
            errorMsg = fieldErrors.join('\n');
          } else {
            errorMsg = errorsObj.toString();
          }
        } else {
          final List<String> fieldErrors = [];
          responseData.forEach((key, val) {
            if (val is List) {
              fieldErrors.add('${_capitalize(key)}: ${val.join(', ')}');
            } else {
              fieldErrors.add('${_capitalize(key)}: $val');
            }
          });
          errorMsg = fieldErrors.isNotEmpty ? fieldErrors.join('\n') : 'Server error. Status: ${response.statusCode}';
        }

        _errorMessage = errorMsg;
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
    required String businessName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/register/');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'password_confirm': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'business_name': businessName,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final success = responseData['success'] ?? false;
        if (success) {
          _tempEmail = email;
          _tempPassword = password;
          _pendingVerificationEmail = email;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('pending_verification_email', email);
          } catch (e) {
            debugPrint('Error saving pending verification email: $e');
          }
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = responseData['message'] ?? 'Registration failed.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // Parse Django Rest Framework validation errors
        String errorMsg = '';
        if (responseData.containsKey('message')) {
          errorMsg = responseData['message'].toString();
        } else if (responseData.containsKey('errors')) {
          final errorsObj = responseData['errors'];
          if (errorsObj is Map) {
            final List<String> fieldErrors = [];
            errorsObj.forEach((key, val) {
              if (val is List) {
                fieldErrors.add('${_capitalize(key)}: ${val.join(', ')}');
              } else {
                fieldErrors.add('${_capitalize(key)}: $val');
              }
            });
            errorMsg = fieldErrors.join('\n');
          } else {
            errorMsg = errorsObj.toString();
          }
        } else {
          final List<String> fieldErrors = [];
          responseData.forEach((key, val) {
            if (val is List) {
              fieldErrors.add('${_capitalize(key)}: ${val.join(', ')}');
            } else {
              fieldErrors.add('${_capitalize(key)}: $val');
            }
          });
          errorMsg = fieldErrors.isNotEmpty ? fieldErrors.join('\n') : 'Server error. Status: ${response.statusCode}';
        }
        
        _errorMessage = errorMsg;
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

  Future<bool> verifyOtp(String otp, {required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/verify-email/');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final success = responseData['success'] ?? false;
        if (success) {
          _pendingVerificationEmail = null;
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
          _errorMessage = responseData['message'] ?? 'Verification failed.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // Parse Django Rest Framework validation errors
        String errorMsg = '';
        if (responseData.containsKey('message')) {
          errorMsg = responseData['message'].toString();
        } else if (responseData.containsKey('errors')) {
          final errorsObj = responseData['errors'];
          if (errorsObj is Map) {
            final List<String> fieldErrors = [];
            errorsObj.forEach((key, val) {
              if (val is List) {
                fieldErrors.add('${_capitalize(key)}: ${val.join(', ')}');
              } else {
                fieldErrors.add('${_capitalize(key)}: $val');
              }
            });
            errorMsg = fieldErrors.join('\n');
          } else {
            errorMsg = errorsObj.toString();
          }
        } else {
          final List<String> fieldErrors = [];
          responseData.forEach((key, val) {
            if (val is List) {
              fieldErrors.add('${_capitalize(key)}: ${val.join(', ')}');
            } else {
              fieldErrors.add('${_capitalize(key)}: $val');
            }
          });
          errorMsg = fieldErrors.isNotEmpty ? fieldErrors.join('\n') : 'Server error. Status: ${response.statusCode}';
        }
        
        _errorMessage = errorMsg;
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
      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/resend-otp/');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'purpose': purpose,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final success = responseData['success'] ?? false;
        if (success) {
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to resend OTP.';
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
      _errorMessage = 'Connection error. Details: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendForgotPasswordOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (email.isEmpty || !email.contains('@')) {
      _isLoading = false;
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }

    _tempEmail = email;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> resetPassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (newPassword.length < 6) {
      _isLoading = false;
      _errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    _tempPassword = newPassword;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

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
