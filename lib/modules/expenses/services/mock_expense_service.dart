import '../models/expense_model.dart';
import '../data/mock_expenses.dart';

class MockExpenseService {
  // Singleton pattern
  static final MockExpenseService _instance = MockExpenseService._internal();
  factory MockExpenseService() => _instance;
  MockExpenseService._internal();

  final List<ExpenseModel> _expenses = getMockExpenses();

  Future<List<ExpenseModel>> getExpenses() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_expenses);
  }

  Future<ExpenseModel> saveExpense(ExpenseModel expense) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      _expenses[index] = expense;
    } else {
      _expenses.insert(0, expense);
    }
    return expense;
  }

  Future<bool> deleteExpense(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _expenses.removeAt(index);
      return true;
    }
    return false;
  }
}
