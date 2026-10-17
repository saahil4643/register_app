import '../../../core/services/api_service.dart';

class ExpenseApiService {
  final ApiService _apiService = ApiService();

  /// GET /api/v1/expenses - List all expenses (returns JSON array or wrapped object)
  Future<dynamic> fetchExpenses({Map<String, dynamic>? queryParameters}) async {
    String path = '/api/v1/expenses';
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final query = queryParameters.entries
          .where((e) => e.value != null && e.value.toString().isNotEmpty)
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      if (query.isNotEmpty) {
        path = '$path?$query';
      }
    }
    return await _apiService.get(path);
  }

  /// GET /api/v1/expenses/{id} - Get single expense by UUID or ID
  Future<dynamic> fetchExpenseDetails(String id) async {
    return await _apiService.get('/api/v1/expenses/$id');
  }

  /// POST /api/v1/expenses - Create new expense with JSON payload
  Future<dynamic> createExpense(Map<String, dynamic> payload) async {
    return await _apiService.post('/api/v1/expenses', payload);
  }

  /// PUT /api/v1/expenses/{id} - Update existing expense
  Future<dynamic> updateExpense(String id, Map<String, dynamic> payload) async {
    return await _apiService.put('/api/v1/expenses/$id', payload);
  }

  /// DELETE /api/v1/expenses/{id} - Soft delete expense
  Future<dynamic> deleteExpense(String id) async {
    return await _apiService.delete('/api/v1/expenses/$id');
  }

  /// POST /api/v1/expenses/{id}/restore - Restore soft-deleted expense
  Future<dynamic> restoreExpense(String id) async {
    return await _apiService.post('/api/v1/expenses/$id/restore', {});
  }

  /// GET /api/v1/settings - Get settings (including expenseCategories and defaults)
  Future<dynamic> fetchSettings() async {
    return await _apiService.get('/api/v1/settings');
  }

  /// GET /api/v1/vendors - List vendors for autocomplete
  Future<dynamic> fetchVendors({String? search}) async {
    String path = '/api/v1/vendors';
    if (search != null && search.isNotEmpty) {
      path = '$path?search=${Uri.encodeComponent(search)}';
    }
    return await _apiService.get(path);
  }

  /// GET /api/v1/reports/profit-loss - Expense analytics and summary metrics
  Future<dynamic> fetchProfitLossReport({String? startDate, String? endDate}) async {
    String path = '/api/v1/reports/profit-loss';
    final List<String> params = [];
    if (startDate != null && startDate.isNotEmpty) params.add('start_date=$startDate');
    if (endDate != null && endDate.isNotEmpty) params.add('end_date=$endDate');
    if (params.isNotEmpty) {
      path = '$path?${params.join('&')}';
    }
    return await _apiService.get(path);
  }

  /// GET /api/v1/bills - Vendor bills
  Future<dynamic> fetchBills({int page = 1, int pageSize = 50}) async {
    return await _apiService.get('/api/v1/bills?page=$page&page_size=$pageSize');
  }
}
