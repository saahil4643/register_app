import 'dart:io';
import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../repository/expense_repository.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _recentExpenses = [];
  List<String> _categories = [];
  List<String> _vendors = [];

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isMoreLoading = false;
  String? _errorMessage;

  // Pagination states
  int _currentPage = 1;
  bool _hasMore = true;

  // Cached Dashboard totals from API (never calculate client-side)
  double _totalExpenses = 0.0;
  double _gstInputCredit = 0.0;
  double _thisMonthExpenses = 0.0;
  double _pendingPayments = 0.0;

  // Filters
  String _searchQuery = '';
  String? _categoryFilter;
  String? _vendorFilter;
  String? _statusFilter;
  String? _paymentModeFilter;
  String? _gstRateFilter;
  String? _startDateFilter;
  String? _endDateFilter;
  String _ordering = 'newest';

  // Getters
  List<ExpenseModel> get expenses => _expenses;
  List<ExpenseModel> get recentExpenses => _recentExpenses;
  List<String> get categories => _categories;
  List<String> get vendors => _vendors;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isMoreLoading => _isMoreLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;

  double get totalExpenses => _totalExpenses;
  double get gstInputCredit => _gstInputCredit;
  double get thisMonthExpenses => _thisMonthExpenses;
  double get pendingPayments => _pendingPayments;

  String get searchQuery => _searchQuery;
  String? get categoryFilter => _categoryFilter;
  String? get vendorFilter => _vendorFilter;
  String? get statusFilter => _statusFilter;
  String? get paymentModeFilter => _paymentModeFilter;
  String? get gstRateFilter => _gstRateFilter;
  String? get startDateFilter => _startDateFilter;
  String? get endDateFilter => _endDateFilter;
  String get ordering => _ordering;

  ExpenseProvider() {
    refreshAll();
  }

  /// Sets active filter parameters and updates the expense list
  void setFilters({
    String? search,
    String? category,
    String? vendor,
    String? status,
    String? paymentMode,
    String? gstRate,
    String? startDate,
    String? endDate,
    String? ordering,
  }) {
    if (search != null) _searchQuery = search;
    if (category != null) _categoryFilter = category.isEmpty ? null : category;
    if (vendor != null) _vendorFilter = vendor.isEmpty ? null : vendor;
    if (status != null) _statusFilter = status.isEmpty ? null : status;
    if (paymentMode != null) _paymentModeFilter = paymentMode.isEmpty ? null : paymentMode;
    if (gstRate != null) _gstRateFilter = gstRate.isEmpty ? null : gstRate;
    if (startDate != null) _startDateFilter = startDate.isEmpty ? null : startDate;
    if (endDate != null) _endDateFilter = endDate.isEmpty ? null : endDate;
    if (ordering != null) _ordering = ordering;
    fetchExpenses(reset: true);
  }

  /// Resets all search and filter conditions
  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = null;
    _vendorFilter = null;
    _statusFilter = null;
    _paymentModeFilter = null;
    _gstRateFilter = null;
    _startDateFilter = null;
    _endDateFilter = null;
    _ordering = 'newest';
    fetchExpenses(reset: true);
  }

  /// Reloads all dashboard numbers, list records, categories, and vendors
  Future<void> refreshAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchDashboardMetrics(silent: true),
        fetchCategories(silent: true),
        fetchVendors(silent: true),
        fetchRecentExpenses(silent: true),
        fetchExpenses(reset: true, silent: true),
      ]);
    } catch (e) {
      _errorMessage = 'Failed to fetch expense records: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh dashboard card metrics
  Future<void> fetchDashboardMetrics({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final metrics = await _repository.getDashboardMetrics();
      _totalExpenses = metrics['total_expenses'] ?? 0.0;
      _gstInputCredit = metrics['gst_input_credit'] ?? 0.0;
      _thisMonthExpenses = metrics['this_month'] ?? 0.0;
      _pendingPayments = metrics['pending_payments'] ?? 0.0;
      if (!silent) notifyListeners();
    } catch (e) {
      if (!silent) {
        _errorMessage = 'Failed to load metrics: $e';
        notifyListeners();
      }
      rethrow;
    }
  }

  /// Load category dropdown items
  Future<void> fetchCategories({bool silent = false}) async {
    try {
      _categories = await _repository.getCategories();
      if (!silent) notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Load vendor autocomplete items
  Future<void> fetchVendors({String? search, bool silent = false}) async {
    try {
      _vendors = await _repository.getVendors(search: search);
      if (!silent) notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Load horizontal cards list
  Future<void> fetchRecentExpenses({bool silent = false}) async {
    try {
      _recentExpenses = await _repository.getRecentExpenses();
      if (!silent) notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Helper to convert active filter filters to API parameters
  Map<String, dynamic> _buildFilterParams() {
    final Map<String, dynamic> params = {
      'page': _currentPage,
      'ordering': _ordering,
    };
    if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;
    if (_categoryFilter != null) params['category'] = _categoryFilter;
    if (_vendorFilter != null) params['vendor'] = _vendorFilter;
    if (_statusFilter != null) params['payment_status'] = _statusFilter;
    if (_paymentModeFilter != null) params['payment_mode'] = _paymentModeFilter;
    if (_gstRateFilter != null) params['gst_rate'] = _gstRateFilter;
    if (_startDateFilter != null) params['start_date'] = _startDateFilter;
    if (_endDateFilter != null) params['end_date'] = _endDateFilter;
    return params;
  }

  /// Lists paginated expenses with search filters applied
  Future<void> fetchExpenses({bool reset = false, bool silent = false}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore) return;

    if (!silent) {
      if (reset) {
        _isLoading = true;
      } else {
        _isMoreLoading = true;
      }
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final params = _buildFilterParams();
      final result = await _repository.getExpenses(queryParameters: params);

      if (reset) {
        _expenses = result.expenses;
      } else {
        _expenses.addAll(result.expenses);
      }

      _hasMore = result.next != null;
      if (_hasMore) {
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = 'Failed to load expense list: $e';
    } finally {
      _isLoading = false;
      _isMoreLoading = false;
      notifyListeners();
    }
  }

  /// POST/PATCH expense changes along with file attachments
  Future<bool> saveExpense(ExpenseModel expense, {File? file}) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isNew = expense.id.isEmpty || expense.id.startsWith('EXP-') || expense.id.startsWith('temp_');
      ExpenseModel saved;
      if (isNew) {
        saved = await _repository.createExpense(expense, file: file);
        _expenses.insert(0, saved);
      } else {
        saved = await _repository.updateExpense(expense, file: file);
        final index = _expenses.indexWhere((e) => e.id == saved.id);
        if (index >= 0) {
          _expenses[index] = saved;
        }
      }

      // Update recent collections and metrics in background
      await fetchDashboardMetrics(silent: true);
      await fetchRecentExpenses(silent: true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// DELETE an expense
  Future<bool> deleteExpense(String id) async {
    _errorMessage = null;
    try {
      final success = await _repository.deleteExpense(id);
      if (success) {
        _expenses.removeWhere((e) => e.id == id);
        _recentExpenses.removeWhere((e) => e.id == id);
        await fetchDashboardMetrics(silent: true);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete expense: $e';
      notifyListeners();
      return false;
    }
  }
}
