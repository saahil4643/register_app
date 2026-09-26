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

  /// Retrieve aggregate stats for the metrics cards
  Future<Map<String, double>> getDashboardMetrics() async {
    final response = await _apiService.fetchDashboard();
    final data = response.data['data'] as Map<String, dynamic>;
    return {
      'total_expenses': (data['total_expenses'] ?? 0.0).toDouble(),
      'gst_input_credit': (data['gst_input_credit'] ?? 0.0).toDouble(),
      'this_month': (data['this_month'] ?? 0.0).toDouble(),
      'pending_payments': (data['pending_payments'] ?? 0.0).toDouble(),
    };
  }

  /// Retrieve standard category names
  Future<List<String>> getCategories() async {
    final response = await _apiService.fetchCategories();
    final list = response.data['data'] as List;
    return list.map((item) => item['name'] as String).toList();
  }

  /// Retrieve standard vendor names (supporting live search queries)
  Future<List<String>> getVendors({String? search}) async {
    final response = await _apiService.fetchVendors(search: search);
    final list = response.data['data'] as List;
    return list.map((item) => item['vendor_name'] as String).toList();
  }

  /// Retrieve recent expenses list (latest 10)
  Future<List<ExpenseModel>> getRecentExpenses() async {
    final response = await _apiService.fetchRecentExpenses();
    final list = response.data['data'] as List;
    return list.map((item) => ExpenseModel.fromMap(item)).toList();
  }

  /// Retrieve full list of expenses (paginated and filtered)
  Future<ExpensePageResult> getExpenses({Map<String, dynamic>? queryParameters}) async {
    final response = await _apiService.fetchExpenses(queryParameters: queryParameters);
    final data = response.data['data'] as Map<String, dynamic>;
    final results = data['results'] as List;
    final expenses = results.map((item) => ExpenseModel.fromMap(item)).toList();
    
    return ExpensePageResult(
      expenses: expenses,
      count: data['count'] ?? 0,
      next: data['next'],
      previous: data['previous'],
      totalPages: data['total_pages'] ?? 1,
    );
  }

  /// Fetch full details of a specific expense
  Future<ExpenseModel> getExpenseDetails(String id) async {
    final response = await _apiService.fetchExpenseDetails(id);
    final data = response.data['data'] as Map<String, dynamic>;
    return ExpenseModel.fromMap(data);
  }

  /// POST a new expense with calculation fields excluded
  Future<ExpenseModel> createExpense(ExpenseModel expense, {File? file}) async {
    final map = expense.toMap();
    // Calculations performed server-side (do not trust frontend)
    map.remove('gstAmount');
    map.remove('totalAmount');
    
    // Remove local mock template IDs
    if (expense.id.isEmpty || expense.id.startsWith('EXP-') || expense.id.startsWith('temp_')) {
      map.remove('id');
    }

    // Convert date times to clean YYYY-MM-DD formats for DateFields
    if (map['expenseDate'] != null) {
      map['expenseDate'] = map['expenseDate'].toString().split('T').first;
    }
    if (map['dueDate'] != null) {
      map['dueDate'] = map['dueDate'].toString().split('T').first;
    }

    // Map keys to match python snake_case
    final payload = _convertToSnakeCase(map);
    
    final response = await _apiService.createExpense(payload, file: file);
    final responseData = response.data['data'] as Map<String, dynamic>;
    return ExpenseModel.fromMap(responseData);
  }

  /// PUT (PATCH) updates on an existing expense
  Future<ExpenseModel> updateExpense(ExpenseModel expense, {File? file}) async {
    final map = expense.toMap();
    map.remove('gstAmount');
    map.remove('totalAmount');
    
    if (map['expenseDate'] != null) {
      map['expenseDate'] = map['expenseDate'].toString().split('T').first;
    }
    if (map['dueDate'] != null) {
      map['dueDate'] = map['dueDate'].toString().split('T').first;
    }

    final payload = _convertToSnakeCase(map);

    final response = await _apiService.updateExpense(expense.id, payload, file: file);
    final responseData = response.data['data'] as Map<String, dynamic>;
    return ExpenseModel.fromMap(responseData);
  }

  /// DELETE an expense
  Future<bool> deleteExpense(String id) async {
    final response = await _apiService.deleteExpense(id);
    return response.data['success'] ?? false;
  }

  /// Map camelCase fields to snake_case backend parameters
  Map<String, dynamic> _convertToSnakeCase(Map<String, dynamic> camelMap) {
    final Map<String, dynamic> snakeMap = {};
    camelMap.forEach((key, value) {
      String snakeKey = key;
      if (key == 'gstRate') {
        snakeKey = 'gst_rate';
      } else if (key == 'paymentMode') {
        snakeKey = 'payment_mode';
      } else if (key == 'expenseDate') {
        snakeKey = 'expense_date';
      } else if (key == 'dueDate') {
        snakeKey = 'due_date';
      } else if (key == 'billNumber') {
        snakeKey = 'bill_number';
      } else if (key == 'status') {
        snakeKey = 'payment_status';
      } else if (key == 'isDraft') {
        snakeKey = 'is_draft';
      }
      snakeMap[snakeKey] = value;
    });
    return snakeMap;
  }
}
