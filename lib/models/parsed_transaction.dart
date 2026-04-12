import '../models/transaction_type.dart';

class ParsedSource {
  const ParsedSource({
    this.upiId,
    this.bankName,
    this.appName,
  });

  final String? upiId;
  final String? bankName;
  final String? appName;

  bool get hasSource => upiId != null || bankName != null || appName != null;

  @override
  String toString() {
    if (upiId != null) return upiId!;
    if (bankName != null) return bankName!;
    if (appName != null) return appName!;
    return '';
  }
}

class ParsedTransaction {
  const ParsedTransaction({
    required this.amount,
    required this.type,
    required this.title,
    required this.category,
    this.source,
    required this.rawText,
    required this.timestamp,
  });

  final double amount;
  final TransactionType type;
  final String title;
  final String category;
  final ParsedSource? source;
  final String rawText;
  final DateTime timestamp;

  String get sourceDescription {
    if (source == null) return '';
    if (source!.upiId != null) return source!.upiId!;
    if (source!.bankName != null) return source!.bankName!;
    if (source!.appName != null) return source!.appName!;
    return '';
  }
}
