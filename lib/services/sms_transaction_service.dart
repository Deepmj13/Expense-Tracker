import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/transaction_message_model.dart';
import 'database_service.dart';
import 'transaction_service.dart';
import 'transaction_parser.dart';
import 'deduplication_service.dart';

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
  final DeduplicationService _deduplicationService = DeduplicationService();

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
    'YESB',
    'IDFC',
    'FEDERAL',
    'RBL',
    'BANDHAN',
    'UCO',
    'CBI',
    'UNION',
    'CENTRAL',
  ];

  bool _matchesBankCode(String address) {
    final upperAddress = address.toUpperCase();
    for (final code in _bankCodes) {
      if (upperAddress.contains(code)) {
        return true;
      }
    }
    return false;
  }

  Future<int> syncSmsTransactions(
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    int addedCount = 0;
    final messages = await _smsQuery.querySms(kinds: [SmsQueryKind.inbox]);
    final processedBox = _databaseService.processedSmsBox();

    for (var message in messages) {
      final smsId = message.id?.toString() ?? '';
      if (smsId.isEmpty || processedBox.containsKey(smsId)) continue;

      final messageDate = message.date ?? DateTime.now();
      if (fromDate != null && messageDate.isBefore(fromDate)) continue;
      if (toDate != null && messageDate.isAfter(toDate)) continue;

      if (_isTransactionSms(message)) {
        final transaction = _parseSmsToTransaction(message);
        if (transaction != null) {
          if (_deduplicationService.isDuplicate(
            amount: transaction.amount,
            type: transaction.type,
            timestamp: transaction.date,
            packageName: message.address,
          )) {
            processedBox.put(smsId, DateTime.now().toIso8601String());
            continue;
          }

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

    bool isApprovedSender =
        _approvedSenderIds.contains(address) || _matchesBankCode(address);

    if (!isApprovedSender) return false;

    // Use the parser to see if it's actually a transaction (contains amount/keywords)
    final smsModel = TransactionMessageModel(
      rawText: message.body!,
      packageName: address,
      receivedAt: message.date ?? DateTime.now(),
    );

    return _parser.parse(smsModel) != null;
  }

  TransactionModel? _parseSmsToTransaction(SmsMessage message) {
    final smsModel = TransactionMessageModel(
      rawText: message.body ?? '',
      packageName: message.address ?? 'Unknown Bank',
      receivedAt: message.date ?? DateTime.now(),
    );

    final parsed = _parser.parse(smsModel);
    if (parsed == null) return null;

    return TransactionModel(
      id: const Uuid().v4(),
      title: parsed.title,
      amount: parsed.amount,
      type: parsed.type,
      category: parsed.category,
      date: parsed.timestamp,
      note: 'Auto-added from SMS: ${smsModel.rawText}',
      paymentMethod: PaymentMethod.bankTransfer,
      source: TransactionSource.sms,
    );
  }
}
