import 'package:flutter/material.dart';

import 'transaction_type.dart';

enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  bankTransfer,
  upi,
  other;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.wallet;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.account_balance;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_wallet;
      case PaymentMethod.upi:
        return Icons.phone_android;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethod.cash:
        return const Color(0xFF10B981);
      case PaymentMethod.creditCard:
        return const Color(0xFF3B82F6);
      case PaymentMethod.debitCard:
        return const Color(0xFF8B5CF6);
      case PaymentMethod.bankTransfer:
        return const Color(0xFFF97316);
      case PaymentMethod.upi:
        return const Color(0xFFEC4899);
      case PaymentMethod.other:
        return const Color(0xFF6B7280);
    }
  }
}

enum TransactionSource {
  manual,
  sms,
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
    this.source = TransactionSource.manual,
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
  final TransactionSource source;

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
        'source': source.name,
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
        source: TransactionSource.values.firstWhere(
          (e) => e.name == (map['source'] as String?),
          orElse: () => TransactionSource.manual,
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
    TransactionSource? source,
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
      source: source ?? this.source,
    );
  }
}
