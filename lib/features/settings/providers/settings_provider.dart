import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/config/env.dart';
import '../../../core/services/api_service.dart';
import '../models/settings_models.dart';
import '../../../services/update_service.dart';
import '../../../models/app_version.dart';

class SettingsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _invoiceTemplate = 'tax_invoice';
  CompanySettings? _companySettings;
  FinancialSettings? _financialSettings;
  TaxSettings? _taxSettings;
  EmailSettings? _emailSettings;
  IntegrationSettings? _integrationSettings;
  SystemPreferences? _systemPreferences;
  final List<BackupHistory> _backupHistoryList = [];
  final List<StaffUser> _staffList = [];
  final List<PaymentMethod> _paymentMethods = [];
  final List<TaxRate> _taxRates = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  final Map<String, List<String>> _fieldErrors = {};

  String _logoShape = 'circle';
  String _logoFit = 'cover';
  Matrix4 _logoMatrix = Matrix4.identity();

  // Getters
  String get logoShape => _logoShape;
  String get logoFit => _logoFit;
  Matrix4 get logoMatrix => _logoMatrix;
  String get invoiceTemplate => _invoiceTemplate;
  CompanySettings? get companySettings => _companySettings;
  FinancialSettings? get financialSettings => _financialSettings;
  TaxSettings? get taxSettings => _taxSettings;
  EmailSettings? get emailSettings => _emailSettings;
  IntegrationSettings? get integrationSettings => _integrationSettings;
  SystemPreferences? get systemPreferences => _systemPreferences;
  List<BackupHistory> get backupHistoryList => _backupHistoryList;
  List<StaffUser> get staffList => _staffList;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  List<TaxRate> get taxRates => _taxRates;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  // Clear errors
  void clearErrors() {
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();
  }

  // Update selected invoice template (stored locally)
  Future<void> updateInvoiceTemplate(String template) async {
    _invoiceTemplate = template;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('invoice_template', template);
    notifyListeners();
  }

  // Scale the translation matrix proportionally to the target container size
  Matrix4 getScaledLogoMatrix(double targetHeight) {
    final matrix = Matrix4.copy(_logoMatrix);
    final ratio = targetHeight / 100.0; // 100.0 is the editor preview container height
    matrix.storage[12] *= ratio; // Scale X offset
    matrix.storage[13] *= ratio; // Scale Y offset
    return matrix;
  }

  // Update logo shape, fit and matrix settings (stored locally)
  Future<void> updateLogoSettings({required String shape, required String fit, required Matrix4 matrix}) async {
    _logoShape = shape;
    _logoFit = fit;
    _logoMatrix = matrix;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_logo_shape', shape);
    await prefs.setString('company_logo_fit', fit);
    await prefs.setString('company_logo_matrix', jsonEncode(matrix.storage.toList()));
    notifyListeners();
  }

  // Fetch all settings consolidated
  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _invoiceTemplate = prefs.getString('invoice_template') ?? 'tax_invoice';
      _logoShape = prefs.getString('company_logo_shape') ?? 'circle';
      _logoFit = prefs.getString('company_logo_fit') ?? 'cover';
      
      final String? matrixStr = prefs.getString('company_logo_matrix');
      if (matrixStr != null) {
        try {
          final List<dynamic> list = jsonDecode(matrixStr);
          _logoMatrix = Matrix4.fromList(list.map((e) => (e as num).toDouble()).toList());
        } catch (_) {
          _logoMatrix = Matrix4.identity();
        }
      } else {
        _logoMatrix = Matrix4.identity();
      }
      
      final response = await _apiService.get('/api/settings/');
      if (response['success'] != false) {
        if (response.containsKey('company')) {
          _companySettings = CompanySettings.fromJson(response['company'] as Map<String, dynamic>);
        }
        if (response.containsKey('financial')) {
          _financialSettings = FinancialSettings.fromJson(response['financial'] as Map<String, dynamic>);
        }
        if (response.containsKey('tax')) {
          _taxSettings = TaxSettings.fromJson(response['tax'] as Map<String, dynamic>);
        }
        if (response.containsKey('email')) {
          _emailSettings = EmailSettings.fromJson(response['email'] as Map<String, dynamic>);
        }
        if (response.containsKey('integrations')) {
          _integrationSettings = IntegrationSettings.fromJson(response['integrations'] as Map<String, dynamic>);
        }
        if (response.containsKey('system')) {
          _systemPreferences = SystemPreferences.fromJson(response['system'] as Map<String, dynamic>);
        }
      } else {
        _errorMessage = response['message'] ?? 'Failed to load settings';
      }
    } catch (e) {
      _errorMessage = 'Error loading settings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Company Settings
  Future<bool> updateCompany(CompanySettings settings) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await _apiService.put('/api/settings/company/', settings.toJson());
      if (response['success'] != false) {
        final Map<String, dynamic> data = response.containsKey('data') ? response['data'] : response;
        _companySettings = CompanySettings.fromJson(data);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update company settings';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating company settings: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Update Financial Settings
  Future<bool> updateFinancial(FinancialSettings settings) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await _apiService.put('/api/settings/financial/', settings.toJson());
      if (response['success'] != false) {
        final Map<String, dynamic> data = response.containsKey('data') ? response['data'] : response;
        _financialSettings = FinancialSettings.fromJson(data);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update financial settings';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating financial settings: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Update Tax Settings
  Future<bool> updateTax(TaxSettings settings) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await _apiService.put('/api/settings/tax/', settings.toJson());
      if (response['success'] != false) {
        final Map<String, dynamic> data = response.containsKey('data') ? response['data'] : response;
        _taxSettings = TaxSettings.fromJson(data);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update tax settings';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating tax settings: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Update Email Settings
  Future<bool> updateEmail(EmailSettings settings) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await _apiService.put('/api/settings/email/', settings.toJson());
      if (response['success'] != false) {
        final Map<String, dynamic> data = response.containsKey('data') ? response['data'] : response;
        _emailSettings = EmailSettings.fromJson(data);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update email settings';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating email settings: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Update Integration Settings
  Future<bool> updateIntegration(IntegrationSettings settings) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await _apiService.put('/api/settings/integrations/', settings.toJson());
      if (response['success'] != false) {
        final Map<String, dynamic> data = response.containsKey('data') ? response['data'] : response;
        _integrationSettings = IntegrationSettings.fromJson(data);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update payment integration settings';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating payment integration settings: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Update System Preferences
  Future<bool> updateSystemPreferences(SystemPreferences settings) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await _apiService.put('/api/settings/system/', settings.toJson());
      if (response['success'] != false) {
        final Map<String, dynamic> data = response.containsKey('data') ? response['data'] : response;
        _systemPreferences = SystemPreferences.fromJson(data);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update system preferences';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating system preferences: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Test SMTP connection
  Future<String?> testEmailConnection(String recipientEmail) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/api/settings/email/test/', {
        'recipient_email': recipientEmail,
      });
      if (response['success'] != false) {
        return response['message'] ?? 'SMTP connection test succeeded.';
      } else {
        _errorMessage = response['message'] ?? 'SMTP connection test failed.';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error testing SMTP connection: $e';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Fetch backup history logs
  Future<void> fetchBackupHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/api/settings/backup/');
      if (response['success'] != false) {
        final List<dynamic> list = response['data'] as List<dynamic>? ?? [];
        _backupHistoryList.clear();
        _backupHistoryList.addAll(list.map((item) => BackupHistory.fromJson(item as Map<String, dynamic>)));
      } else {
        _errorMessage = response['message'] ?? 'Failed to load backup history';
      }
    } catch (e) {
      _errorMessage = 'Error loading backup history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Trigger new database backup
  Future<bool> triggerBackup() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/api/settings/backup/', {});
      if (response['success'] != false) {
        await fetchBackupHistory();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Backup creation failed';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error triggering backup: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Restore database state from a backup
  Future<bool> restoreBackup(String backupId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/api/settings/restore/', {
        'backup_id': backupId,
      });
      if (response['success'] != false) {
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Restore failed';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error restoring database backup: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // --- Mobile Redesigned Settings Endpoints API Integration ---

  // Profile - using redesigned Profile endpoint
  Future<bool> updateProfile(CompanySettings settings) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await _apiService.put('/api/settings/profile/', settings.toJson());
      if (response['success'] != false) {
        final Map<String, dynamic> data = response.containsKey('data') ? response['data'] : response;
        _companySettings = CompanySettings.fromJson(data);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update company profile';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating company profile: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> uploadCompanyLogo(XFile file) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token');
      
      final Uri url = Uri.parse('${Env.apiBaseUrl}/api/v1/settings/profile/');
      final request = http.MultipartRequest('PUT', url);
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'logo',
          await file.readAsBytes(),
          filename: file.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'logo',
          file.path,
        ));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final success = responseData['success'] ?? true;
        if (success != false) {
          final data = responseData.containsKey('data') ? responseData['data'] : responseData;
          _companySettings = CompanySettings.fromJson(data);
          notifyListeners();
          return true;
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to upload logo.';
          return false;
        }
      } else {
        _errorMessage = responseData['message'] ?? 'Server error. Status: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCompanyLogo() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/api/settings/profile/', {
        'logo': null,
      });
      if (response['success'] != false) {
        final Map<String, dynamic> data = response.containsKey('data') ? response['data'] : response;
        _companySettings = CompanySettings.fromJson(data);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete company logo';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting company logo: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Users & Staff CRUD
  Future<void> fetchStaff() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/api/settings/users/');
      if (response['success'] != false) {
        final List<dynamic> list = response.containsKey('data') ? response['data'] : response;
        _staffList.clear();
        _staffList.addAll(list.map((item) => StaffUser.fromJson(item as Map<String, dynamic>)));
      } else {
        _errorMessage = response['message'] ?? 'Failed to load staff directory';
      }
    } catch (e) {
      _errorMessage = 'Error loading staff directory: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> inviteStaff(String name, String email, String role, {String phone = ''}) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await _apiService.post('/api/settings/users/', {
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
      });
      if (response['success'] != false) {
        await fetchStaff();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to invite staff member';
        if (response['errors'] is Map<String, dynamic>) {
          _parseFieldErrors(response['errors']);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inviting staff member: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateStaff(String id, {String? name, String? role, String? status}) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final Map<String, dynamic> payload = {};
      if (name != null) payload['name'] = name;
      if (role != null) payload['role'] = role;
      if (status != null) payload['status'] = status;

      final response = await _apiService.patch('/api/settings/users/$id/', payload);
      if (response['success'] != false) {
        await fetchStaff();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update staff member';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating staff member: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteStaff(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('/api/settings/users/$id/');
      if (response['success'] != false) {
        await fetchStaff();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete staff member';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting staff member: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Payment Methods CRUD
  Future<void> fetchPaymentMethods() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/api/settings/payment-methods/');
      if (response['success'] != false) {
        final List<dynamic> list = response.containsKey('data') ? response['data'] : response;
        _paymentMethods.clear();
        _paymentMethods.addAll(list.map((item) => PaymentMethod.fromJson(item as Map<String, dynamic>)));
      } else {
        _errorMessage = response['message'] ?? 'Failed to load payment methods';
      }
    } catch (e) {
      _errorMessage = 'Error loading payment methods: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPaymentMethod(PaymentMethod method) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await _apiService.post('/api/settings/payment-methods/', method.toJson());
      if (response['success'] != false) {
        await fetchPaymentMethods();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create payment method';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error creating payment method: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updatePaymentMethod(PaymentMethod method) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await _apiService.put('/api/settings/payment-methods/${method.id}/', method.toJson());
      if (response['success'] != false) {
        await fetchPaymentMethods();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update payment method';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating payment method: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deletePaymentMethod(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('/api/settings/payment-methods/$id/');
      if (response['success'] != false) {
        await fetchPaymentMethods();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete payment method';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting payment method: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Tax Rates CRUD
  Future<void> fetchTaxRates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/api/settings/taxes/');
      if (response['success'] != false) {
        final List<dynamic> list = response.containsKey('data') ? response['data'] : response;
        _taxRates.clear();
        _taxRates.addAll(list.map((item) => TaxRate.fromJson(item as Map<String, dynamic>)));
      } else {
        _errorMessage = response['message'] ?? 'Failed to load tax rates';
      }
    } catch (e) {
      _errorMessage = 'Error loading tax rates: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTaxRate(TaxRate rate) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await _apiService.post('/api/settings/taxes/', rate.toJson());
      if (response['success'] != false) {
        await fetchTaxRates();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create tax rate';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error creating tax rate: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateTaxRate(TaxRate rate) async {
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      final response = await _apiService.put('/api/settings/taxes/${rate.id}/', rate.toJson());
      if (response['success'] != false) {
        await fetchTaxRates();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update tax rate';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating tax rate: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTaxRate(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('/api/settings/taxes/$id/');
      if (response['success'] != false) {
        await fetchTaxRates();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete tax rate';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting tax rate: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _parseFieldErrors(Map<String, dynamic> errors) {
    _fieldErrors.clear();
    errors.forEach((key, value) {
      if (value is List) {
        _fieldErrors[key] = value.map((e) => e.toString()).toList();
      } else {
        _fieldErrors[key] = [value.toString()];
      }
    });
  }

  // App Update States and Methods
  bool _isCheckingForUpdates = false;
  bool get isCheckingForUpdates => _isCheckingForUpdates;

  Future<AppVersion?> checkForAppUpdates() async {
    if (_isCheckingForUpdates) return null;
    _isCheckingForUpdates = true;
    notifyListeners();

    try {
      final updateService = UpdateService();
      final latestUpdate = await updateService.checkForUpdate();
      return latestUpdate;
    } catch (e) {
      debugPrint('SettingsProvider checkForAppUpdates error: $e');
      rethrow;
    } finally {
      _isCheckingForUpdates = false;
      notifyListeners();
    }
  }
}
