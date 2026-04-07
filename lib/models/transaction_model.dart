import 'transaction_type.dart';

enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  bankTransfer,
  upi,
  other,
}

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
    this.paymentMethod = PaymentMethod.cash,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String note;
  final bool isRecurring;
  final PaymentMethod paymentMethod;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
        'isRecurring': isRecurring,
        'paymentMethod': paymentMethod.name,
      };

  factory TransactionModel.fromMap(Map<dynamic, dynamic> map) =>
      TransactionModel(
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
        paymentMethod: PaymentMethod.values.firstWhere(
          (e) => e.name == (map['paymentMethod'] as String?),
          orElse: () => PaymentMethod.cash,
        ),
      );

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? note,
    bool? isRecurring,
    PaymentMethod? paymentMethod,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      isRecurring: isRecurring ?? this.isRecurring,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
