import '../models/transaction_model.dart';
import '../models/transaction_type.dart';

class ParsedSmsResult {
  final double amount;
  final TransactionType type;
  final String description;
  final DateTime date;
  final PaymentMethod paymentMethod;

  ParsedSmsResult({
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    required this.paymentMethod,
  });
}

class SmsParserService {
  static ParsedSmsResult? parse(String smsBody) {
    final lowerBody = smsBody.toLowerCase();

    if (_isUpiTransaction(lowerBody)) {
      return _parseUpiSms(smsBody);
    }

    if (_isBankTransaction(lowerBody)) {
      return _parseBankSms(smsBody);
    }

    return null;
  }

  static bool _isUpiTransaction(String body) {
    final upiPatterns = [
      'phonepe',
      'google pay',
      'gpay',
      'paytm',
      'payu',
      'bhim',
      'upi',
      'upi collect',
      'upi sent',
      'upi received',
    ];
    return upiPatterns.any((pattern) => body.contains(pattern));
  }

  static bool _isBankTransaction(String body) {
    final bankPatterns = [
      'hdfc',
      'icici',
      'sbi',
      'axis bank',
      'kotak',
      'yes bank',
      'punjab national',
      'pnbfc',
      'bob',
      'bank of baroda',
      'canara bank',
      'idfc first',
      'indusind',
      'rbl bank',
      'federal bank',
      'south indian bank',
    ];
    return bankPatterns.any((pattern) => body.contains(pattern));
  }

  static ParsedSmsResult? _parseUpiSms(String body) {
    final lowerBody = body.toLowerCase();

    final isCredit = lowerBody.contains('credited') ||
        lowerBody.contains('received') ||
        lowerBody.contains('sent to you') ||
        lowerBody.contains('received rs') ||
        lowerBody.contains('money received');

    final isDebit = lowerBody.contains('debited') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('sent rs') ||
        lowerBody.contains('payment successful') ||
        lowerBody.contains('paid rs');

    if (!isCredit && !isDebit) return null;

    final amount = _extractAmount(body);
    if (amount == null) return null;

    final description = _extractUpiDescription(body);
    final paymentMethod = _detectUpiPaymentMethod(body);

    return ParsedSmsResult(
      amount: amount,
      type: isCredit ? TransactionType.income : TransactionType.expense,
      description: description,
      date: DateTime.now(),
      paymentMethod: paymentMethod,
    );
  }

  static ParsedSmsResult? _parseBankSms(String body) {
    final lowerBody = body.toLowerCase();

    final isCredit = lowerBody.contains('credited') ||
        lowerBody.contains('deposited') ||
        lowerBody.contains('received') ||
        lowerBody.contains('refund') ||
        lowerBody.contains('deposit');

    final isDebit = lowerBody.contains('debited') ||
        lowerBody.contains('withdrawn') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('transferred') ||
        lowerBody.contains('purchase');

    if (!isCredit && !isDebit) return null;

    final amount = _extractAmount(body);
    if (amount == null) return null;

    final description = _extractBankDescription(body);
    final paymentMethod = _detectBankPaymentMethod(body);

    return ParsedSmsResult(
      amount: amount,
      type: isCredit ? TransactionType.income : TransactionType.expense,
      description: description,
      date: _extractDate(body) ?? DateTime.now(),
      paymentMethod: paymentMethod,
    );
  }

  static double? _extractAmount(String body) {
    final patterns = [
      RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'INR\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'₹(\d+(?:,\d+)*(?:\.\d{2})?)'),
      RegExp(r'(\d+(?:,\d+)*(?:\.\d{2})?)\s*Rs', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        if (amountStr != null) {
          return double.tryParse(amountStr);
        }
      }
    }
    return null;
  }

  static String _extractUpiDescription(String body) {
    final patterns = [
      RegExp(r'to\s+([A-Za-z0-9@_-]+)', caseSensitive: false),
      RegExp(r'paid to\s+([^\.]+)', caseSensitive: false),
      RegExp(r'sent to\s+([^\.]+)', caseSensitive: false),
      RegExp(r'from\s+([A-Za-z0-9@_-]+)', caseSensitive: false),
      RegExp(r'received from\s+([^\.]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim() ?? 'UPI Transaction';
      }
    }

    final upiApps = ['phonepe', 'google pay', 'gpay', 'paytm', 'payu', 'bhim'];
    for (final app in upiApps) {
      if (body.toLowerCase().contains(app)) {
        return '$app Transaction';
      }
    }

    return 'UPI Transaction';
  }

  static String _extractBankDescription(String body) {
    final patterns = [
      RegExp(r'to\s+(?:a\/c\s*)?([A-Z0-9]+|[^\.]+)', caseSensitive: false),
      RegExp(r'transferred to\s+([^\.]+)', caseSensitive: false),
      RegExp(r'paid to\s+([^\.]+)', caseSensitive: false),
      RegExp(r'from\s+(?:a\/c\s*)?([^\.]+)', caseSensitive: false),
      RegExp(r'received from\s+([^\.]+)', caseSensitive: false),
      RegExp(r'deposited from\s+([^\.]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim() ?? 'Bank Transaction';
      }
    }

    final banks = ['hdfc', 'icici', 'sbi', 'axis', 'kotak', 'yes bank'];
    for (final bank in banks) {
      if (body.toLowerCase().contains(bank)) {
        return '$bank Transaction';
      }
    }

    return 'Bank Transaction';
  }

  static DateTime? _extractDate(String body) {
    final datePatterns = [
      RegExp(r'on\s+(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})', caseSensitive: false),
      RegExp(r'at\s+(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{1,2})\/(\d{1,2})\/(\d{2,4})\s+\d{1,2}:\d{2}',
          caseSensitive: false),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        try {
          int day = int.parse(match.group(1)!);
          int month = int.parse(match.group(2)!);
          int year = int.parse(match.group(3)!);

          if (year < 100) year += 2000;

          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    return null;
  }

  static PaymentMethod _detectUpiPaymentMethod(String body) {
    final lowerBody = body.toLowerCase();
    if (lowerBody.contains('phonepe')) return PaymentMethod.upi;
    if (lowerBody.contains('google pay') || lowerBody.contains('gpay'))
      return PaymentMethod.upi;
    if (lowerBody.contains('paytm')) return PaymentMethod.upi;
    if (lowerBody.contains('payu')) return PaymentMethod.upi;
    if (lowerBody.contains('bhim')) return PaymentMethod.upi;
    return PaymentMethod.upi;
  }

  static PaymentMethod _detectBankPaymentMethod(String body) {
    final lowerBody = body.toLowerCase();

    if (lowerBody.contains('upi') ||
        lowerBody.contains('phonepe') ||
        lowerBody.contains('google pay') ||
        lowerBody.contains('gpay') ||
        lowerBody.contains('paytm')) {
      return PaymentMethod.upi;
    }

    if (lowerBody.contains('card') ||
        lowerBody.contains('pos') ||
        lowerBody.contains('card purchase')) {
      return PaymentMethod.debitCard;
    }

    return PaymentMethod.bankTransfer;
  }
}
