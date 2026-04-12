import 'package:flutter/foundation.dart';
import '../models/transaction_type.dart';

class DeduplicationService {
  DeduplicationService() : _seenTransactions = {};

  final Map<String, DateTime> _seenTransactions;
  static const int _cleanupIntervalMinutes = 10;

  bool isDuplicate({
    required double amount,
    required TransactionType type,
    required DateTime timestamp,
    String? packageName,
  }) {
    _cleanup();

    final roundedMinute = _roundToMinute(timestamp);

    final genericKey = _createGenericKey(amount, type, roundedMinute);
    final specificKey = packageName != null
        ? _createSpecificKey(amount, type, roundedMinute, packageName)
        : null;

    bool isGenericDuplicate =
        genericKey != null && _seenTransactions.containsKey(genericKey);
    bool isSpecificDuplicate =
        specificKey != null && _seenTransactions.containsKey(specificKey);

    if (isGenericDuplicate || isSpecificDuplicate) {
      debugPrint(
          'Duplicate detected - generic: $isGenericDuplicate, specific: $isSpecificDuplicate');
      return true;
    }

    if (genericKey != null) {
      _seenTransactions[genericKey] = DateTime.now();
    }
    if (specificKey != null) {
      _seenTransactions[specificKey] = DateTime.now();
    }

    return false;
  }

  void clear() {
    _seenTransactions.clear();
  }

  int get trackedCount => _seenTransactions.length;

  DateTime _roundToMinute(DateTime timestamp) {
    return DateTime(timestamp.year, timestamp.month, timestamp.day,
        timestamp.hour, timestamp.minute);
  }

  String? _createGenericKey(
      double amount, TransactionType type, DateTime roundedMinute) {
    final amountKey = _roundAmount(amount);
    return '${amountKey}_${type.name}_$roundedMinute';
  }

  String? _createSpecificKey(double amount, TransactionType type,
      DateTime roundedMinute, String packageName) {
    final amountKey = _roundAmount(amount);
    return '${amountKey}_${type.name}_${roundedMinute}_$packageName';
  }

  String _roundAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  void _cleanup() {
    final cutoff = DateTime.now()
        .subtract(const Duration(minutes: _cleanupIntervalMinutes));
    _seenTransactions.removeWhere((_, timestamp) => timestamp.isBefore(cutoff));
  }
}
