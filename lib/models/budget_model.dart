class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.month,
    required this.year,
    required this.amount,
    this.createdAt,
  });

  final String id;
  final int month;
  final int year;
  final double amount;
  final DateTime? createdAt;

  String get key => '$year-$month';

  Map<String, dynamic> toMap() => {
        'id': id,
        'month': month,
        'year': year,
        'amount': amount,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  factory BudgetModel.fromMap(Map<dynamic, dynamic> map) => BudgetModel(
        id: map['id'] as String,
        month: map['month'] as int,
        year: map['year'] as int,
        amount: (map['amount'] as num).toDouble(),
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : null,
      );

  BudgetModel copyWith({
    String? id,
    int? month,
    int? year,
    double? amount,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum BudgetAlertLevel {
  none,
  fiftyPercent,
  ninetyPercent,
  exceeded,
}
