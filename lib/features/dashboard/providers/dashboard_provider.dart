import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../invoices/models/invoice.dart';
import '../../customers/models/payment.dart';
import '../../settings/models/settings_models.dart';
import '../models/dashboard_reports.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  SalesSummaryReport? _salesSummary;
  ProfitLossReport? _profitLoss;
  ReceivablesReport? _receivables;
  List<Invoice> _recentInvoices = [];
  List<Payment> _recentPayments = [];
  CompanySettings? _organization;
  Map<String, dynamic>? _userProfile;

  bool _isLoading = false;
  String? _errorMessage;
  String _salesPeriod = 'monthly';

  // Getters
  SalesSummaryReport? get salesSummary => _salesSummary;
  ProfitLossReport? get profitLoss => _profitLoss;
  ReceivablesReport? get receivables => _receivables;
  List<Invoice> get recentInvoices => _recentInvoices;
  List<Payment> get recentPayments => _recentPayments;
  CompanySettings? get organization => _organization;
  Map<String, dynamic>? get userProfile => _userProfile;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get salesPeriod => _salesPeriod;

  void setSalesPeriod(String period) {
    if (_salesPeriod == period) return;
    _salesPeriod = period;
    notifyListeners();
    fetchSalesSummary();
  }

  // Fetch all dashboard data concurrently
  Future<void> fetchDashboardData({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchUserProfile(),
        _fetchOrganization(),
        fetchSalesSummary(),
        _fetchProfitLoss(),
        _fetchReceivables(),
        _fetchRecentInvoices(),
        _fetchRecentPayments(),
      ]);
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      _errorMessage = 'Failed to load some dashboard metrics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 1. User Profile: GET /api/v1/auth/me
  Future<void> _fetchUserProfile() async {
    try {
      final res = await _apiService.get('/api/v1/auth/me');
      if (res['success'] != false) {
        final data = res['data'] ?? res;
        if (data is Map<String, dynamic>) {
          _userProfile = data;
        }
      }
    } catch (e) {
      debugPrint('Dashboard: error fetching user profile: $e');
    }
  }

  void setOrganization(CompanySettings org) {
    _organization = org;
    notifyListeners();
  }

  // 2. Organization: GET /api/v1/organization (fallback /api/v1/settings/organization or /api/v1/settings)
  Future<void> _fetchOrganization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedCompany = prefs.getString('company_name') ?? prefs.getString('logged_in_company_name');
      if (_organization == null && cachedCompany != null && cachedCompany.trim().isNotEmpty) {
        _organization = CompanySettings(
          companyName: cachedCompany.trim(),
          legalName: cachedCompany.trim(),
          website: '',
          email: '',
          phone: '',
          gstNumber: '',
          panNumber: '',
          currency: 'INR',
          timezone: 'UTC',
          country: '',
          state: '',
          city: '',
          address: '',
          postalCode: '',
          financialYear: 'April - March',
          language: 'en',
          dateFormat: 'YYYY-MM-DD',
          timeFormat: 'HH:mm:ss',
        );
        notifyListeners();
      }

      var res = await _apiService.get('/api/v1/organization');
      if (res['success'] == false) {
        res = await _apiService.get('/api/v1/settings/organization');
      }
      if (res['success'] == false) {
        res = await _apiService.get('/api/v1/settings');
      }

      final data = res['data'] ?? res['organization'] ?? res['company'] ?? res;
      if (data is Map<String, dynamic>) {
        final parsed = CompanySettings.fromJson(data);
        if (parsed.companyName.isNotEmpty) {
          _organization = parsed;
          await prefs.setString('company_name', parsed.companyName);
          await prefs.setString('logged_in_company_name', parsed.companyName);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Dashboard: error fetching organization: $e');
    }
  }

  // 3. Sales Summary: GET /api/v1/reports/sales-summary?period=monthly
  Future<void> fetchSalesSummary() async {
    try {
      final res = await _apiService.get('/api/v1/reports/sales-summary?period=$_salesPeriod');
      if (res['success'] != false) {
        final data = res['data'] ?? res;
        if (data is Map<String, dynamic>) {
          _salesSummary = SalesSummaryReport.fromJson(data);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Dashboard: error fetching sales summary: $e');
    }
  }

  // 4. Profit & Loss: GET /api/v1/reports/profit-loss
  Future<void> _fetchProfitLoss() async {
    try {
      final res = await _apiService.get('/api/v1/reports/profit-loss');
      if (res['success'] != false) {
        final data = res['data'] ?? res;
        if (data is Map<String, dynamic>) {
          _profitLoss = ProfitLossReport.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Dashboard: error fetching profit loss: $e');
    }
  }

  // 5. Customer Receivables & Aging: GET /api/v1/reports/receivables
  Future<void> _fetchReceivables() async {
    try {
      final res = await _apiService.get('/api/v1/reports/receivables');
      if (res['success'] != false) {
        final data = res['data'] ?? res;
        if (data is Map<String, dynamic>) {
          _receivables = ReceivablesReport.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Dashboard: error fetching receivables: $e');
    }
  }

  // 6. Recent Invoices: GET /api/v1/invoices?page=1&page_size=5
  Future<void> _fetchRecentInvoices() async {
    try {
      final res = await _apiService.get('/api/v1/invoices?page=1&page_size=5');
      if (res['success'] != false) {
        final rawData = res['data'] ?? res;
        List<dynamic> list = [];
        if (rawData is Map) {
          list = rawData['results'] as List<dynamic>? ?? [];
        } else if (rawData is List) {
          list = rawData;
        }

        _recentInvoices = list
            .take(5)
            .map((item) => Invoice.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Dashboard: error fetching recent invoices: $e');
    }
  }

  // 7. Recent Payments: GET /api/v1/payments
  Future<void> _fetchRecentPayments() async {
    try {
      final res = await _apiService.get('/api/v1/payments');
      if (res['success'] != false) {
        final rawData = res['data'] ?? res;
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map) {
          list = rawData['results'] as List<dynamic>? ?? rawData['data'] as List<dynamic>? ?? [];
        }

        _recentPayments = list
            .take(5)
            .map((item) => Payment.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Dashboard: error fetching recent payments: $e');
    }
  }
}
