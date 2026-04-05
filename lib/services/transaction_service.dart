import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import 'database_service.dart';

class TransactionService {
  TransactionService(this._databaseService);

  final DatabaseService _databaseService;

  List<TransactionModel> getAll(String userId) {
    final box = _databaseService.transactionsBox();
    final list = box.values
        .where((item) => item['userId'] == userId)
        .map(TransactionModel.fromMap)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> save(String userId, TransactionModel model) async {
    await _databaseService.transactionsBox().put(model.id, {
      ...model.toMap(),
      'userId': userId,
    });
  }

  Future<void> delete(String id) async {
    await _databaseService.transactionsBox().delete(id);
  }

  double incomeTotal(List<TransactionModel> items) => items
      .where((e) => e.type == TransactionType.income)
      .fold(0, (sum, item) => sum + item.amount);

  double expenseTotal(List<TransactionModel> items) => items
      .where((e) => e.type == TransactionType.expense)
      .fold(0, (sum, item) => sum + item.amount);
}
