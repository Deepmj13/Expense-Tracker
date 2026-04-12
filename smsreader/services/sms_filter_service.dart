import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';

class SmsFilterService {
  // Whitelisted Sender IDs
  static const Set<String> _approvedSenderIds = {
    'VK-HDFCBK',
    'AX-ICICIB',
    'VM-SBIINB',
    'AD-AXISBK',
    'VK-KOTAKB',
    'JD-PAYTM',
    'VK-PAYTM',
    'AD-IDFCFB',
    'VK-YESBNK',
    'AX-INDUSB',
    'VK-CANBNK',
    'AD-BOBMSG',
  };

  // Bank codes for pattern matching in sender IDs
  static const List<String> _bankCodes = [
    'SBI',
    'HDFC',
    'ICICI',
    'AXIS',
    'KOTAK',
    'PNB',
    'BOB',
    'CANARA',
    'UBI',
    'INDIAN',
    'INDUSIND',
    'YES',
    'IDFC',
    'FEDERAL',
    'RBL',
    'BANDHAN',
    'UCO',
    'CBI',
  ];

  // Expanded patterns for credit transactions (Money IN)
  static final RegExp _creditRegex = RegExp(
    r'\b(credited|received|deposit|credited to|added to|refunded|transfer in)\b',
    caseSensitive: false,
  );

  // Expanded patterns for debit transactions (Money OUT)
  static final RegExp _debitRegex = RegExp(
    r'\b(debited|withdrawn|deducted|spent at|paid to|purchase|payment made|transfer out|charged)\b',
    caseSensitive: false,
  );

  bool isTransactionSms(SmsMessage message) {
    if (message.body == null) return false;
    final body = message.body!;
    final address = message.address?.toUpperCase() ?? '';

    // 1. Sender Verification (Whitelist Check)
    bool isApprovedSender = _approvedSenderIds.contains(address);
    if (!isApprovedSender) {
      isApprovedSender = _bankCodes.any((code) => address.contains(code));
    }

    // If sender is not a recognized bank, discard immediately
    if (!isApprovedSender) return false;

    // 2. Money-Movement Verification (Strict Transaction Check)
    // An SMS is stored ONLY if it matches a credit OR a debit pattern.
    // General banking terms (like "balance" or "account") are no longer sufficient.
    return _creditRegex.hasMatch(body) || _debitRegex.hasMatch(body);
  }

  String categorizeSms(SmsMessage message) {
    if (message.body == null) return 'unknown';
    final body = message.body!;
    if (_creditRegex.hasMatch(body)) {
      return 'credit';
    } else if (_debitRegex.hasMatch(body)) {
      return 'debit';
    }
    return 'unknown';
  }
}
