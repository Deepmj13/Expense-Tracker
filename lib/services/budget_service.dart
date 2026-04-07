import '../models/budget_model.dart';
import 'database_service.dart';

class BudgetService {
  BudgetService(this._databaseService);

  final DatabaseService _databaseService;

  BudgetModel? getBudget(int month, int year) {
    final key = '$year-$month';
    final box = _databaseService.appBox();
    final data = box.get(key);
    if (data == null) return null;
    return BudgetModel.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<void> saveBudget(BudgetModel budget) async {
    final box = _databaseService.appBox();
    await box.put(budget.key, budget.toMap());
  }

  Future<void> deleteBudget(String key) async {
    final box = _databaseService.appBox();
    await box.delete(key);
  }

  List<BudgetModel> getAllBudgets() {
    final box = _databaseService.appBox();
    final budgets = <BudgetModel>[];
    for (final key in box.keys) {
      if (key is String && RegExp(r'^\d{4}-\d{1,2}$').hasMatch(key)) {
        final data = box.get(key);
        if (data != null) {
          budgets
              .add(BudgetModel.fromMap(Map<String, dynamic>.from(data as Map)));
        }
      }
    }
    budgets.sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) return yearCompare;
      return b.month.compareTo(a.month);
    });
    return budgets;
  }
}
