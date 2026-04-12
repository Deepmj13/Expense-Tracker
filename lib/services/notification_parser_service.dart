import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/parsed_transaction.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../services/deduplication_service.dart';
import '../services/message_filter_service.dart';
import '../services/notification_channel_service.dart';
import '../services/notification_pipeline_service.dart';
import '../services/transaction_parser.dart';
import '../services/transaction_service.dart';

String _generateSecureTransactionId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final random = Random.secure().nextInt(999999);
  return '${timestamp}_$random';
}

String _generateTimerId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final random = Random().nextInt(999999);
  return '${timestamp}_$random';
}

class NotificationParserService {
  NotificationParserService({
    required DatabaseService databaseService,
    required TransactionService transactionService,
    NotificationChannelService? channelService,
  })  : _databaseService = databaseService,
        _transactionService = transactionService,
        _channelService = channelService ?? NotificationChannelService(),
        _dedupService = DeduplicationService() {
    _init();
  }

  final DatabaseService _databaseService;
  final TransactionService _transactionService;
  final NotificationChannelService _channelService;
  final DeduplicationService _dedupService;
  final String _instanceId = _generateTimerId();

  final MessageFilterService _filterService = const MessageFilterService();
  final TransactionParser _parser = const TransactionParser();

  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  final Map<String, Map<String, dynamic>> _pendingTransactions = {};
  final Map<String, Timer> _pendingTimers = {};
  static const _autoAddDelay = Duration(seconds: 5);

  Function(Map<String, dynamic>)? onTransactionParsed;
  Function(TransactionModel)? onTransactionAdded;
  Function(String)? onTransactionError;

  void _init() {
    _notificationSubscription = _channelService.notificationStream.listen(
      _handleNotification,
      onError: (error) {
        debugPrint('Notification stream error: $error');
      },
    );
  }

  void _handleNotification(Map<String, dynamic> data) {
    final packageName = data['packageName'] as String? ?? '';
    final title = data['title'] as String? ?? '';
    final text = data['text'] as String? ?? '';
    final timestamp = data['timestamp'] as int?;

    if (title.isEmpty && text.isEmpty) {
      debugPrint('Empty notification skipped');
      return;
    }

    final notification = NotificationPipelineService.processNotification(
      title: title,
      text: text,
      packageName: packageName,
      timestamp: timestamp,
    );

    if (_filterService.isOtpOrPromotional(notification.rawText)) {
      debugPrint('Filtered OTP/Promotional: ${notification.rawText}');
      return;
    }

    if (!_filterService.isValidTransaction(notification.rawText)) {
      debugPrint(
          'Invalid transaction (no amount or keyword): ${notification.rawText}');
      return;
    }

    final parsed = _parser.parse(notification);

    if (parsed == null) {
      debugPrint('Could not parse transaction: ${notification.rawText}');
      return;
    }

    final isDuplicate = _dedupService.isDuplicate(
      amount: parsed.amount,
      type: parsed.type,
      timestamp: parsed.timestamp,
      packageName: packageName,
    );

    if (isDuplicate) {
      debugPrint('Duplicate transaction ignored: ${notification.rawText}');
      return;
    }

    onTransactionParsed?.call({
      'amount': parsed.amount,
      'type': parsed.type,
      'title': parsed.title,
      'category': parsed.category,
      'source': parsed.sourceDescription,
      'rawText': parsed.rawText,
      'timestamp': parsed.timestamp,
    });

    _queueForAutoAdd(parsed);
  }

  void _queueForAutoAdd(ParsedTransaction parsed) {
    final timerId = '${_instanceId}_${parsed.timestamp.millisecondsSinceEpoch}';
    _pendingTransactions[timerId] = {
      'parsed': parsed,
      'addedAt': DateTime.now(),
    };

    _pendingTimers[timerId] = Timer(_autoAddDelay, () {
      _autoAddTransaction(parsed);
      _pendingTransactions.remove(timerId);
      _pendingTimers.remove(timerId);
    });
  }

  Future<void> _autoAddTransaction(ParsedTransaction parsed) async {
    final userId = _databaseService.appBox().get('current_user_id') as String?;
    if (userId == null) {
      debugPrint('ERROR: Cannot auto-add transaction - no user logged in');
      onTransactionError?.call('Please log in to auto-add transactions');
      return;
    }

    String sourceNote =
        parsed.source?.appName ?? parsed.source?.bankName ?? 'notification';
    if (parsed.source?.upiId != null) {
      sourceNote = parsed.source!.upiId!;
    }

    final transaction = TransactionModel(
      id: _generateSecureTransactionId(),
      title: parsed.title,
      amount: parsed.amount,
      type: parsed.type,
      category: parsed.category,
      date: parsed.timestamp,
      note: 'Auto-added from $sourceNote',
      source: TransactionSource.notification,
    );

    await _transactionService.save(userId, transaction);
    onTransactionAdded?.call(transaction);
  }

  void cancelPendingTransaction(String timerId) {
    _pendingTimers[timerId]?.cancel();
    _pendingTimers.remove(timerId);
    _pendingTransactions.remove(timerId);
  }

  void addPendingTransactionNow(String timerId) {
    final pending = _pendingTransactions[timerId];
    if (pending != null) {
      final parsed = pending['parsed'];
      if (parsed is ParsedTransaction) {
        _pendingTimers[timerId]?.cancel();
        _pendingTimers.remove(timerId);
        _pendingTransactions.remove(timerId);
        _autoAddTransaction(parsed);
      } else {
        debugPrint(
            'Error: Invalid data type for parsed transaction in pending $timerId');
      }
    } else {
      debugPrint(
          'Warning: TimerId $timerId not found in pending transactions (may have already been added or canceled)');
    }
  }

  List<String> get pendingTransactionIds => _pendingTransactions.keys.toList();

  void dispose() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    for (final timer in _pendingTimers.values) {
      timer.cancel();
    }
    _pendingTimers.clear();
    _pendingTransactions.clear();
    _dedupService.clear();
  }
}
