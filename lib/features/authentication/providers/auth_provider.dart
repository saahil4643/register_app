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
  static const String _userCompanyNameKey = 'logged_in_company_name';

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserCompanyName;
  String? _currentUserEmail;
  String? _currentUserFirstName;
  String? _currentUserLastName;
  String? _currentUserPhone;
  String? _currentUserRole;
  String? _currentUserDesignation;
  String? _currentUserAvatar;
  String? _currentUserProfileImage;
  String? _currentUserTimeZone;
  String? _currentUserTheme;
  String? _accountStatus;

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
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  String? get currentUserCompanyName => _currentUserCompanyName;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserFirstName => _currentUserFirstName;
  String? get currentUserLastName => _currentUserLastName;
  String? get currentUserPhone => _currentUserPhone;
  String? get currentUserRole => _currentUserRole;
  String? get currentUserDesignation => _currentUserDesignation;
  String? get currentUserAvatar => _currentUserAvatar;
  String? get currentUserProfileImage => _currentUserProfileImage;
  String? get currentUserTimeZone => _currentUserTimeZone;
  String? get currentUserTheme => _currentUserTheme;
  String? get accountStatus => _accountStatus;
  String? get tempEmail => _tempEmail;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  bool get isEmailUnverified => _isEmailUnverified;

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool(_authKey) ?? false;
      _pendingVerificationEmail = prefs.getString('pending_verification_email');
      _currentUserCompanyName = prefs.getString(_userCompanyNameKey) ?? prefs.getString('company_name');
      if (_isAuthenticated) {
        _currentUserEmail = prefs.getString(_userEmailKey) ?? '';
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

    // Small simulated delay for responsive user feedback
    await Future.delayed(const Duration(milliseconds: 300));

    final normalizedUser = email.trim().toLowerCase();
    final isUserValid = normalizedUser == 'admin' || normalizedUser == 'admin@prabhim.com';
    final isPasswordValid = password == 'Pass123';

    if (isUserValid && isPasswordValid) {
      const userEmail = 'admin@prabhim.com';
      const userFirstName = 'Admin';
      const userLastName = '';
      const accessToken = 'local_admin_token';
      const refreshToken = 'local_admin_refresh_token';

      _isAuthenticated = true;
      _currentUserId = '1';
      _currentUserName = 'admin';
      _currentUserEmail = userEmail;
      _currentUserFirstName = userFirstName;
      _currentUserLastName = userLastName;
      _currentUserRole = 'ADMIN';
      _currentUserDesignation = 'Administrator';
      _currentUserCompanyName ??= 'Prabhim Technologies';
      _pendingVerificationEmail = null;
      _isEmailUnverified = false;
      _isLoading = false;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_authKey, true);
        await prefs.setString(_userEmailKey, userEmail);
        await prefs.setString(_userFirstNameKey, userFirstName);
        await prefs.setString(_userLastNameKey, userLastName);
        await prefs.setString('logged_in_user_id', '1');
        await prefs.setString('user_role', 'ADMIN');
        if (_currentUserCompanyName != null && _currentUserCompanyName!.isNotEmpty) {
          await prefs.setString(_userCompanyNameKey, _currentUserCompanyName!);
          await prefs.setString('company_name', _currentUserCompanyName!);
        }
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        await prefs.remove('pending_verification_email');
      } catch (e) {
        debugPrint('Error saving login state: $e');
      }

      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      _errorMessage = 'Invalid username or password. Please use admin and Pass123.';
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
          if (businessName != null && businessName.trim().isNotEmpty) ...{
            'businessName': businessName.trim(),
            'business_name': businessName.trim(),
            'companyName': businessName.trim(),
            'company_name': businessName.trim(),
          },
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
            if (businessName != null && businessName.trim().isNotEmpty) {
              _currentUserCompanyName = businessName.trim();
              await prefs.setString(_userCompanyNameKey, businessName.trim());
              await prefs.setString('company_name', businessName.trim());
            }
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
      if (refreshToken == null || refreshToken.isEmpty || refreshToken.startsWith('local_')) return false;

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

      if (refreshToken != null && refreshToken.isNotEmpty && !refreshToken.startsWith('local_')) {
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
      if (token == null || token.isEmpty || token.startsWith('local_')) return null;

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

  Future<Map<String, dynamic>?> getProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      if (token.startsWith('local_')) {
        _currentUserId ??= '1';
        _currentUserName ??= 'admin';
        _currentUserFirstName ??= 'Admin';
        _currentUserLastName ??= '';
        _currentUserEmail ??= 'admin@prabhim.com';
        _currentUserRole ??= 'ADMIN';
        _currentUserDesignation ??= 'Administrator';
        _currentUserCompanyName ??= 'Prabhim Technologies';
        _isLoading = false;
        notifyListeners();
        return {
          'id': _currentUserId,
          'name': _currentUserName,
          'firstName': _currentUserFirstName,
          'lastName': _currentUserLastName,
          'email': _currentUserEmail,
          'role': _currentUserRole,
          'designation': _currentUserDesignation,
          'companyName': _currentUserCompanyName,
        };
      }

      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/profile');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final data = (responseData is Map && responseData['data'] != null)
            ? responseData['data']
            : responseData;

        if (data is Map) {
          _currentUserId = data['id']?.toString() ?? _currentUserId;
          _currentUserName = data['name']?.toString() ?? data['fullName']?.toString() ?? _currentUserName;
          _currentUserFirstName = data['firstName']?.toString() ?? data['first_name']?.toString() ?? _currentUserFirstName;
          _currentUserLastName = data['lastName']?.toString() ?? data['last_name']?.toString() ?? _currentUserLastName;
          _currentUserEmail = data['email']?.toString() ?? _currentUserEmail;
          _currentUserPhone = data['phone']?.toString() ?? data['phoneNumber']?.toString() ?? _currentUserPhone;
          _currentUserRole = data['role']?.toString() ?? _currentUserRole;
          _currentUserDesignation = data['designation']?.toString() ?? _currentUserDesignation;
          _currentUserAvatar = data['avatar']?.toString() ?? _currentUserAvatar;
          _currentUserProfileImage = data['profilePic']?.toString() ?? data['profile_pic']?.toString() ?? data['profileImage']?.toString() ?? data['avatarUrl']?.toString() ?? _currentUserProfileImage;
          _currentUserTimeZone = data['timeZone']?.toString() ?? data['time_zone']?.toString() ?? _currentUserTimeZone;
          _currentUserTheme = data['theme']?.toString() ?? _currentUserTheme;
          _accountStatus = data['accountStatus']?.toString() ?? _accountStatus;

          final userCompany = (data['companyName'] ?? data['company_name'] ?? data['businessName'] ?? data['business_name'] ?? data['organization']?['companyName'] ?? data['organization']?['name'] ?? data['company']?['companyName'] ?? data['company']?['name'])?.toString();
          if (userCompany != null && userCompany.trim().isNotEmpty) {
            _currentUserCompanyName = userCompany.trim();
          }

          if (_currentUserEmail != null) await prefs.setString(_userEmailKey, _currentUserEmail!);
          if (_currentUserFirstName != null) await prefs.setString(_userFirstNameKey, _currentUserFirstName!);
          if (_currentUserLastName != null) await prefs.setString(_userLastNameKey, _currentUserLastName!);
          if (_currentUserProfileImage != null) await prefs.setString(_userProfileImageKey, _currentUserProfileImage!);
          if (_currentUserCompanyName != null && _currentUserCompanyName!.isNotEmpty) {
            await prefs.setString(_userCompanyNameKey, _currentUserCompanyName!);
            await prefs.setString('company_name', _currentUserCompanyName!);
          }

          _isLoading = false;
          notifyListeners();
          return Map<String, dynamic>.from(data);
        }
      } else {
        _errorMessage = _extractErrorMessage(responseData, response.statusCode);
      }
    } catch (e) {
      _errorMessage = 'Error fetching profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? designation,
    String? avatar,
    String? timeZone,
    String? theme,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/profile');
      final Map<String, dynamic> body = {};
      if (name != null && name.isNotEmpty) {
        body['name'] = name;
        body['fullName'] = name;
        body['full_name'] = name;
      }
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        body['phone'] = phone;
        body['phoneNumber'] = phone;
        body['phone_number'] = phone;
      }
      if (designation != null && designation.isNotEmpty) {
        body['designation'] = designation;
      }
      if (avatar != null && avatar.isNotEmpty) {
        body['avatar'] = avatar;
        body['avatarIcon'] = avatar;
        body['avatar_icon'] = avatar;
      }
      if (timeZone != null && timeZone.isNotEmpty) {
        body['timeZone'] = timeZone;
        body['time_zone'] = timeZone;
        body['timezone'] = timeZone;
      }
      if (theme != null && theme.isNotEmpty) {
        body['theme'] = theme;
      }

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bool isSuccess = (responseData is Map && responseData['success'] == true) || response.statusCode == 200;
        if (isSuccess) {
          final data = (responseData is Map && responseData['data'] != null)
              ? responseData['data']
              : (responseData is Map && responseData['profile'] != null ? responseData['profile'] : responseData);

          if (data is Map) {
            _currentUserName = data['name']?.toString() ?? name ?? _currentUserName;
            _currentUserEmail = data['email']?.toString() ?? email ?? _currentUserEmail;
            _currentUserPhone = data['phone']?.toString() ?? phone ?? _currentUserPhone;
            _currentUserDesignation = data['designation']?.toString() ?? designation ?? _currentUserDesignation;
            _currentUserAvatar = data['avatar']?.toString() ?? avatar ?? _currentUserAvatar;
            _currentUserTheme = data['theme']?.toString() ?? theme ?? _currentUserTheme;

            if (_currentUserEmail != null) await prefs.setString(_userEmailKey, _currentUserEmail!);
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
      _errorMessage = 'Error updating profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (newPassword.length < 8) {
      _errorMessage = 'Password must be at least 8 characters long.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (newPassword != confirmPassword) {
      _errorMessage = 'New password and confirm password do not match.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/profile/change-password');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
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
      _errorMessage = 'Error changing password: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfilePicture(XFile file) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/profile/upload-picture');
      final request = http.MultipartRequest('POST', url);

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        if (bytes.lengthInBytes > 2 * 1024 * 1024) {
          _errorMessage = 'File too large. Maximum allowed size is 2MB.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        request.files.add(http.MultipartFile.fromBytes(
          'profilePic',
          bytes,
          filename: file.name,
        ));
      } else {
        final bytes = await file.readAsBytes();
        if (bytes.lengthInBytes > 2 * 1024 * 1024) {
          _errorMessage = 'File too large. Maximum allowed size is 2MB.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        request.files.add(await http.MultipartFile.fromPath(
          'profilePic',
          file.path,
          filename: file.name,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bool isSuccess = (responseData is Map && responseData['success'] == true) || response.statusCode == 200;
        if (isSuccess) {
          final String? picUrl = responseData['profilePicUrl'] ??
              (responseData['data'] != null ? responseData['data']['profilePicUrl'] : null);

          if (picUrl != null) {
            _currentUserProfileImage = picUrl;
            await prefs.setString(_userProfileImageKey, picUrl);
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
      _errorMessage = 'Error uploading picture: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProfilePicture() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final url = Uri.parse('${Env.apiBaseUrl}/api/v1/profile/picture');
      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 204) {
        _currentUserProfileImage = null;
        await prefs.remove(_userProfileImageKey);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = _extractErrorMessage(responseData, response.statusCode);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting profile picture: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Backward compatibility aliases
  Future<bool> updateUserProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final name = '$firstName $lastName'.trim();
    return updateProfile(
      name: name,
      phone: phone,
    );
  }

  Future<bool> uploadProfileImage(XFile file) async {
    return uploadProfilePicture(file);
  }

  Future<bool> deleteProfileImage() async {
    return deleteProfilePicture();
  }

  String getProfilePictureUrl([String? userId]) {
    final id = userId ?? _currentUserId ?? '';
    return '${Env.apiBaseUrl}/api/v1/profile/picture/$id';
  }

  Future<void> updateCompanyName(String newName) async {
    if (newName.trim().isEmpty) return;
    _currentUserCompanyName = newName.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userCompanyNameKey, newName.trim());
      await prefs.setString('company_name', newName.trim());
    } catch (e) {
      debugPrint('Error updating company name in auth provider: $e');
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
