import 'dart:io';
import '../api/expense_api_service.dart';
import '../models/expense_model.dart';

class ExpensePageResult {
  final List<ExpenseModel> expenses;
  final int count;
  final String? next;
  final String? previous;
  final int totalPages;

  ExpensePageResult({
    required this.expenses,
    required this.count,
    this.next,
    this.previous,
    required this.totalPages,
  });
}

class ExpenseRepository {
  final ExpenseApiService _apiService = ExpenseApiService();

  /// Retrieve summary stats from profit-loss report for dashboard / summary cards
  Future<Map<String, double>> getDashboardMetrics() async {
    try {
      final response = await _apiService.fetchProfitLossReport();
      dynamic data = response;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }
      if (data is Map) {
        double toDouble(dynamic val) {
          if (val == null) return 0.0;
          if (val is num) return val.toDouble();
          if (val is String) return double.tryParse(val) ?? 0.0;
          return 0.0;
        }

        return {
          'total_expenses': toDouble(data['totalExpenses'] ?? data['total_expenses'] ?? data['operatingExpenses']),
          'operating_expenses': toDouble(data['operatingExpenses'] ?? data['operating_expenses']),
          'bills_expenses': toDouble(data['billsExpenses'] ?? data['bills_expenses']),
          'purchase_expenses': toDouble(data['purchaseExpenses'] ?? data['purchase_expenses']),
        };
      }
    } catch (_) {}
    return {};
  }

  /// Retrieve category names from /api/v1/settings (expenses.expenseCategories)
  Future<List<String>> getCategories() async {
    try {
      final response = await _apiService.fetchSettings();
      dynamic data = response;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }
      if (data is Map && data.containsKey('expenses')) {
        final expensesBlock = data['expenses'];
        if (expensesBlock is Map && expensesBlock.containsKey('expenseCategories')) {
          final catString = expensesBlock['expenseCategories']?.toString() ?? '';
          if (catString.isNotEmpty) {
            final list = catString
                .split(',')
                .map((c) => c.trim())
                .where((c) => c.isNotEmpty)
                .toList();
            if (list.isNotEmpty) return list;
          }
        }
      }
    } catch (_) {}

    // Fallback standard categories if settings are unset
    return [
      'Rent & Accommodation',
      'Office Supplies',
      'Travel Expenses',
      'Utilities',
      'Advertising & Marketing',
      'Employee Salaries & Wages',
      'Food, Meals & Entertainment',
      'Freight & Delivery',
      'Fuel & Petrol',
      'Insurance',
      'Internet & Telephone',
      'Repairs & Maintenance',
      'Software & Subscriptions',
      'Taxes & Licenses',
      'Miscellaneous',
    ];
  }

  /// Retrieve vendors list from /api/v1/vendors for autocomplete
  Future<List<String>> getVendors({String? search}) async {
    try {
      final response = await _apiService.fetchVendors(search: search);
      dynamic data = response;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }
      if (data is List) {
        final names = data.map((item) {
          if (item is Map) {
            return (item['name'] ?? item['vendor_name'] ?? item['company_name'] ?? '').toString();
          }
          return item.toString();
        }).where((name) => name.isNotEmpty).toList();
        return names;
      }
    } catch (_) {}
    return [];
  }

  /// Retrieve full list of expenses (GET /api/v1/expenses)
  Future<ExpensePageResult> getExpenses({Map<String, dynamic>? queryParameters}) async {
    final response = await _apiService.fetchExpenses(queryParameters: queryParameters);
    dynamic listData = response;

    if (listData is Map && listData.containsKey('data')) {
      listData = listData['data'];
    }
    if (listData is Map && listData.containsKey('results')) {
      final results = listData['results'] as List;
      final expenses = results.map((item) => ExpenseModel.fromMap(Map<String, dynamic>.from(item as Map))).toList();
      return ExpensePageResult(
        expenses: expenses,
        count: listData['count'] ?? expenses.length,
        next: listData['next'],
        previous: listData['previous'],
        totalPages: listData['total_pages'] ?? 1,
      );
    }

    if (listData is List) {
      final expenses = listData
          .map((item) => ExpenseModel.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
      return ExpensePageResult(
        expenses: expenses,
        count: expenses.length,
        totalPages: 1,
      );
    }

    return ExpensePageResult(
      expenses: [],
      count: 0,
      totalPages: 1,
    );
  }

  /// Fetch full details of a specific expense (GET /api/v1/expenses/{id})
  Future<ExpenseModel> getExpenseDetails(String id) async {
    final response = await _apiService.fetchExpenseDetails(id);
    dynamic data = response;
    if (data is Map && data.containsKey('data') && data['data'] is Map) {
      data = data['data'];
    }
    return ExpenseModel.fromMap(Map<String, dynamic>.from(data as Map));
  }

  /// Create a new expense (POST /api/v1/expenses)
  Future<ExpenseModel> createExpense(ExpenseModel expense, {File? file}) async {
    final payload = expense.toApiJson();
    final response = await _apiService.createExpense(payload);
    dynamic data = response;
    if (data is Map && data.containsKey('data') && data['data'] is Map) {
      data = data['data'];
    }
    if (data is Map) {
      return ExpenseModel.fromMap(Map<String, dynamic>.from(data));
    }
    return expense;
  }

  /// Update an existing expense (PUT /api/v1/expenses/{id})
  Future<ExpenseModel> updateExpense(ExpenseModel expense, {File? file}) async {
    final payload = expense.toApiJson();
    final response = await _apiService.updateExpense(expense.id, payload);
    dynamic data = response;
    if (data is Map && data.containsKey('data') && data['data'] is Map) {
      data = data['data'];
    }
    if (data is Map) {
      return ExpenseModel.fromMap(Map<String, dynamic>.from(data));
    }
    return expense;
  }

  /// Delete an expense (DELETE /api/v1/expenses/{id})
  Future<bool> deleteExpense(String id) async {
    final response = await _apiService.deleteExpense(id);
    if (response is Map) {
      return response['success'] == true || response['statusCode'] == 200 || response['statusCode'] == 204;
    }
    return true;
  }

  /// Restore a soft-deleted expense (POST /api/v1/expenses/{id}/restore)
  Future<bool> restoreExpense(String id) async {
    final response = await _apiService.restoreExpense(id);
    if (response is Map) {
      return response['success'] == true;
    }
    return true;
  }
}
