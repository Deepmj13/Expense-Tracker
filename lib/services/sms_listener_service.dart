import 'dart:async';
import 'package:android_sms_reader/android_sms_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../providers/app_providers.dart';
import '../services/sms_parser_service.dart';
import '../services/transaction_service.dart';
import '../services/database_service.dart';

final _notificationsPlugin = FlutterLocalNotificationsPlugin();

class SmsListenerService {
  SmsListenerService(this._transactionService, this._ref);

  final TransactionService _transactionService;
  final Ref _ref;
  Timer? _pollingTimer;
  Set<String> _processedMessageIds = {};
  List<AndroidSMSMessage> _lastFetchedMessages = [];
  final DatabaseService _dbService = DatabaseService();

  String? _currentUserId;

  bool _isListening = false;
  bool get isListening => _isListening;

  Future<void> initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<bool> requestPermission() async {
    debugPrint('[SMS] Requesting SMS permission...');
    final granted = await AndroidSMSReader.requestPermissions();
    debugPrint('[SMS] Permission result: $granted');
    return granted;
  }

  Future<bool> checkPermission() async {
    final status = await Permission.sms.status;
    debugPrint('[SMS] Current permission status: ${status.name}');
    return status.isGranted;
  }

  void _loadProcessedIds() {
    final storedIds =
        _dbService.appBox().get(DatabaseService.processedSmsIdsKey);
    if (storedIds != null) {
      _processedMessageIds = Set<String>.from(List<String>.from(storedIds));
      debugPrint('[SMS] Loaded ${_processedMessageIds.length} processed IDs');
    }
  }

  void _saveProcessedIds() {
    _dbService.appBox().put(
          DatabaseService.processedSmsIdsKey,
          _processedMessageIds.toList(),
        );
  }

  Future<void> startListening(String userId) async {
    if (_isListening) {
      debugPrint('[SMS] Already listening, skipping...');
      return;
    }

    _currentUserId = userId;
    debugPrint('[SMS] Starting SMS listener for user: $userId');

    await initNotifications();

    final hasPermission = await checkPermission();
    debugPrint('[SMS] Has permission: $hasPermission');

    if (!hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        debugPrint('[SMS] Permission denied, cannot start');
        return;
      }
    }

    _loadProcessedIds();

    try {
      debugPrint('[SMS] Testing message fetch...');
      final testMessages = await AndroidSMSReader.fetchMessages(
        type: AndroidSMSType.inbox,
        start: 0,
        count: 5,
      );
      debugPrint('[SMS] Test fetch got ${testMessages.length} messages');

      if (testMessages.isNotEmpty) {
        debugPrint(
            '[SMS] Latest message: ${testMessages.first.body?.substring(0, testMessages.first.body!.length > 50 ? 50 : testMessages.first.body!.length)}');
      }

      await _pollNewMessages();

      _pollingTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _pollNewMessages(),
      );

      _isListening = true;
      debugPrint('[SMS] Listening started successfully');
    } catch (e) {
      debugPrint('[SMS] Error starting listener: $e');
    }
  }

  Future<void> stopListening() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isListening = false;
    debugPrint('[SMS] Listening stopped');
  }

  Future<void> _pollNewMessages() async {
    if (_currentUserId == null) {
      debugPrint('[SMS] No user ID, skipping poll');
      return;
    }

    try {
      debugPrint('[SMS] Polling for new messages...');
      final messages = await AndroidSMSReader.fetchMessages(
        type: AndroidSMSType.inbox,
        start: 0,
        count: 20,
      );

      debugPrint('[SMS] Fetched ${messages.length} messages');

      if (messages.isEmpty) return;

      _lastFetchedMessages = messages;

      final now = DateTime.now();
      final recentThreshold = now.subtract(const Duration(minutes: 5));

      for (final message in messages) {
        final messageDate = DateTime.fromMillisecondsSinceEpoch(message.date);

        debugPrint(
            '[SMS] Message date: $messageDate, threshold: $recentThreshold');

        if (messageDate.isBefore(recentThreshold)) {
          debugPrint('[SMS] Message too old, skipping');
          continue;
        }

        final messageId = _generateMessageId(message);
        debugPrint('[SMS] Message ID: $messageId');

        if (_processedMessageIds.contains(messageId)) {
          debugPrint('[SMS] Already processed, skipping');
          continue;
        }

        final body = message.body;
        debugPrint(
            '[SMS] Message body: ${body?.substring(0, body!.length > 30 ? 30 : body.length)}');

        if (body == null || body.isEmpty) {
          debugPrint('[SMS] Empty body, skipping');
          continue;
        }

        debugPrint('[SMS] Parsing SMS...');
        final parsed = SmsParserService.parse(body);
        if (parsed == null) {
          debugPrint('[SMS] Not a transaction SMS, skipping');
          continue;
        }

        debugPrint(
            '[SMS] Parsed: ${parsed.type} - ${parsed.amount} - ${parsed.description}');

        await _processTransaction(messageId, parsed, messageDate);
      }
    } catch (e) {
      debugPrint('[SMS] Polling error: $e');
    }
  }

  String _generateMessageId(AndroidSMSMessage message) {
    final timestamp = message.date;
    final address = message.address ?? '';
    final body = message.body ?? '';
    return '${timestamp}_${address.hashCode}_${body.hashCode}';
  }

  Future<void> _processTransaction(
    String messageId,
    ParsedSmsResult parsed,
    DateTime messageDate,
  ) async {
    if (_currentUserId == null) return;

    final userId = _currentUserId!;

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: parsed.description,
      amount: parsed.amount,
      type: parsed.type,
      category: parsed.type == TransactionType.income
          ? 'Auto Income'
          : 'Auto Expense',
      date: messageDate,
      note: 'Auto-imported from SMS',
      paymentMethod: parsed.paymentMethod,
      source: TransactionSource.smsAutoImport,
    );

    debugPrint(
        '[SMS] Saving transaction: ${transaction.title} - ${transaction.amount}');

    await _transactionService.save(userId, transaction);
    _processedMessageIds.add(messageId);
    _saveProcessedIds();

    _ref.read(transactionsControllerProvider.notifier).load(userId);

    _showNotification(transaction);

    debugPrint('[SMS] Transaction saved successfully!');
  }

  Future<void> _showNotification(TransactionModel transaction) async {
    final androidDetails = AndroidNotificationDetails(
      'sms_auto_import',
      'SMS Auto Import',
      channelDescription: 'Notifications for auto-imported transactions',
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    final typeLabel =
        transaction.type == TransactionType.income ? 'Income' : 'Expense';
    await _notificationsPlugin.show(
      transaction.id.hashCode,
      '$typeLabel Added',
      '₹${transaction.amount.toStringAsFixed(2)} - ${transaction.title}',
      details,
    );
  }

  bool isDuplicate(String messageContent) {
    final hash = messageContent.hashCode.toString();
    return _processedMessageIds.contains(hash);
  }

  void markAsProcessed(String messageContent) {
    final hash = messageContent.hashCode.toString();
    _processedMessageIds.add(hash);
    _saveProcessedIds();
  }

  Future<void> testFetch() async {
    debugPrint('[TEST] Starting test fetch...');

    final hasPermission = await checkPermission();
    debugPrint('[TEST] Has permission: $hasPermission');

    if (!hasPermission) {
      final granted = await requestPermission();
      debugPrint('[TEST] Permission request result: $granted');
      if (!granted) {
        debugPrint('[TEST] Permission denied');
        return;
      }
    }

    try {
      final messages = await AndroidSMSReader.fetchMessages(
        type: AndroidSMSType.inbox,
        start: 0,
        count: 10,
      );

      debugPrint('[TEST] Fetched ${messages.length} messages');

      for (var i = 0; i < messages.length; i++) {
        final msg = messages[i];
        debugPrint('[TEST] Message $i:');
        debugPrint('[TEST]   Address: ${msg.address}');
        debugPrint('[TEST]   Body: ${msg.body}');
        debugPrint(
            '[TEST]   Date: ${DateTime.fromMillisecondsSinceEpoch(msg.date)}');

        final parsed = SmsParserService.parse(msg.body ?? '');
        if (parsed != null) {
          debugPrint(
              '[TEST]   PARSED: ${parsed.type} - ${parsed.amount} - ${parsed.description}');
        }
      }
    } catch (e) {
      debugPrint('[TEST] Error: $e');
    }
  }
}
