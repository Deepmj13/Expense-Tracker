import 'transaction_type.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.note,
    this.isRecurring = false,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String note;
  final bool isRecurring;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
        'isRecurring': isRecurring,
      };

  factory TransactionModel.fromMap(Map<dynamic, dynamic> map) => TransactionModel(
        id: map['id'] as String,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: (map['type'] == 'income')
            ? TransactionType.income
            : TransactionType.expense,
        category: map['category'] as String,
        date: DateTime.parse(map['date'] as String),
        note: (map['note'] as String?) ?? '',
        isRecurring: (map['isRecurring'] as bool?) ?? false,
      );
}
