import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../models/notification_model.dart';
import 'database_service.dart';
import 'transaction_service.dart';
import 'transaction_parser.dart';

class SmsTransactionService {
  SmsTransactionService(
    this._databaseService,
    this._transactionService,
    this._parser,
  );

  final DatabaseService _databaseService;
  final TransactionService _transactionService;
  final TransactionParser _parser;
  final SmsQuery _smsQuery = SmsQuery();

  // Whitelisted Sender IDs from existing smsreader logic
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

  Future<int> syncSmsTransactions(String userId) async {
    int addedCount = 0;
    final messages = await _smsQuery.querySms(kinds: [SmsQueryKind.inbox]);
    final processedBox = _databaseService.processedSmsBox();

    for (var message in messages) {
      final smsId = message.id?.toString() ?? '';
      if (smsId.isEmpty || processedBox.containsKey(smsId)) continue;

      if (_isTransactionSms(message)) {
        final transaction = _parseSmsToTransaction(message);
        if (transaction != null) {
          await _transactionService.save(userId, transaction);
          processedBox.put(smsId, DateTime.now().toIso8601String());
          addedCount++;
        }
      }
    }
    return addedCount;
  }

  bool _isTransactionSms(SmsMessage message) {
    if (message.body == null) return false;
    final address = message.address?.toUpperCase() ?? '';

    bool isApprovedSender = _approvedSenderIds.contains(address) ||
        _bankCodes.any((code) => address.contains(code));

    if (!isApprovedSender) return false;

    // Use the parser to see if it's actually a transaction (contains amount/keywords)
    final notification = NotificationModel(
      rawText: message.body!,
      packageName: address,
      receivedAt: message.date ?? DateTime.now(),
    );

    return _parser.parse(notification) != null;
  }

  TransactionModel? _parseSmsToTransaction(SmsMessage message) {
    final notification = NotificationModel(
      rawText: message.body ?? '',
      packageName: message.address ?? 'Unknown Bank',
      receivedAt: message.date ?? DateTime.now(),
    );

    final parsed = _parser.parse(notification);
    if (parsed == null) return null;

    return TransactionModel(
      id: const Uuid().v4(),
      title: parsed.title,
      amount: parsed.amount,
      type: parsed.type,
      category: parsed.category,
      date: parsed.timestamp,
      note: 'Auto-added from SMS: ${notification.rawText}',
      paymentMethod: PaymentMethod.bankTransfer,
      source: TransactionSource.notification,
    );
  }
}
