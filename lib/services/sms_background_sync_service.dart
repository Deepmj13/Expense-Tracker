import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'database_service.dart';
import 'sms_transaction_service.dart';
import 'sms_sync_preference_service.dart';
import 'transaction_service.dart';
import 'transaction_parser.dart';
import 'notification_service.dart';

const String periodicSmsSyncTask = 'periodicSmsSyncTask';
const String smsSyncTaskName = 'smsSyncTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Workmanager task started: $task');

    try {
      switch (task) {
        case periodicSmsSyncTask:
          await _performPeriodicSync();
          break;
        case smsSyncTaskName:
          await _performOneTimeSync(inputData);
          break;
        default:
          debugPrint('Unknown task: $task');
      }
    } catch (e) {
      debugPrint('Workmanager task error: $e');
      return false;
    }

    return true;
  });
}

Future<void> _performPeriodicSync() async {
  debugPrint('Performing periodic SMS sync...');

  try {
    await _initializeSync((prefsService, prefs) async {
      await _syncSms(prefs.lastUserId!, prefsService);
      await _checkAndSendReminder(prefsService, prefs);
    });
  } catch (e) {
    debugPrint('Error in periodic sync: $e');
  }
}

Future<void> _checkAndSendReminder(
    SmsSyncPreferenceService prefsService, SmsSyncPreferences prefs) async {
  if (!prefs.reminderEnabled) return;

  if (NotificationService.instance.isQuietHours()) return;

  final now = DateTime.now();
  DateTime? lastActivity = prefs.lastAppOpenTime;
  final lastTransaction = prefs.lastManualTransactionTime;
  if (lastTransaction != null) {
    if (lastActivity == null || lastTransaction.isAfter(lastActivity)) {
      lastActivity = lastTransaction;
    }
  }

  if (lastActivity != null) {
    final hoursSinceActivity = now.difference(lastActivity).inHours;
    if (hoursSinceActivity < 3) return;
  }

  final scheduledTime = _getNextScheduledReminderTime(now);
  final reminderHour = scheduledTime.hour;
  if (now.hour < reminderHour) return;

  await prefsService.setLastReminderSentTime(now);
  await prefsService.setPausedReminderTime(null);
  await NotificationService.instance.showReminderNotification();
}

DateTime _getNextScheduledReminderTime(DateTime now) {
  final today2PM = DateTime(now.year, now.month, now.day, 14);
  final today6PM = DateTime(now.year, now.month, now.day, 18);
  final today10PM = DateTime(now.year, now.month, now.day, 22);

  if (now.isBefore(today2PM)) return today2PM;
  if (now.isBefore(today6PM)) return today6PM;
  if (now.isBefore(today10PM)) return today10PM;
  return today2PM.add(const Duration(days: 1));
}

Future<void> _performOneTimeSync(Map<String, dynamic>? inputData) async {
  debugPrint('Performing one-time SMS sync...');

  try {
    await _initializeSync((prefsService, prefs) async {
      final DateTime? fromDate =
          inputData != null && inputData['fromDate'] != null
              ? DateTime.tryParse(inputData['fromDate'] as String)
              : null;
      final DateTime? toDate = inputData != null && inputData['toDate'] != null
          ? DateTime.tryParse(inputData['toDate'] as String)
          : null;

      await _syncSms(prefs.lastUserId!, prefsService,
          fromDate: fromDate, toDate: toDate);
    });
  } catch (e) {
    debugPrint('Error in one-time sync: $e');
  }
}

Future<void> _initializeSync(
    Future<void> Function(
            SmsSyncPreferenceService prefsService, SmsSyncPreferences prefs)
        operation) async {
  final prefsService = SmsSyncPreferenceService();
  await prefsService.init();
  await NotificationService.instance.init();

  final prefs = prefsService.getPreferences();
  final userId = prefs.lastUserId;

  if (userId == null) {
    debugPrint('No user ID stored, skipping sync');
    return;
  }

  await operation(prefsService, prefs);
}

Future<void> _syncSms(
  String userId,
  SmsSyncPreferenceService prefsService, {
  DateTime? fromDate,
  DateTime? toDate,
}) async {
  try {
    debugPrint('Starting SMS sync for user: $userId');

    final dbService = DatabaseService();
    await dbService.init();

    final transactionService = TransactionService(dbService);
    const parser = TransactionParser();
    final smsService =
        SmsTransactionService(dbService, transactionService, parser);

    final syncFromDate = fromDate ??
        prefsService.getPreferences().lastSyncTime ??
        DateTime.now().subtract(const Duration(hours: 2));

    final addedCount = await smsService.syncSmsTransactions(
      userId,
      fromDate: syncFromDate,
      toDate: toDate ?? DateTime.now(),
    );

    await prefsService.setLastSyncTime(DateTime.now());

    debugPrint('SMS sync completed. Added: $addedCount transactions');
  } catch (e) {
    debugPrint('Error syncing SMS: $e');
  }
}

class SmsBackgroundSyncService {
  SmsBackgroundSyncService._();

  static final SmsBackgroundSyncService instance = SmsBackgroundSyncService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await Workmanager().initialize(
      callbackDispatcher,
    );

    _initialized = true;
  }

  Future<void> schedulePeriodicSync({
    Duration frequency = const Duration(hours: 3),
  }) async {
    await Workmanager().registerPeriodicTask(
      periodicSmsSyncTask,
      periodicSmsSyncTask,
      frequency: frequency,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    debugPrint('Periodic SMS sync scheduled with frequency: $frequency');
  }

  Future<void> cancelPeriodicSync() async {
    await Workmanager().cancelByUniqueName(periodicSmsSyncTask);
    debugPrint('Periodic SMS sync cancelled');
  }

  Future<void> triggerImmediateSync({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    await Workmanager().registerOneOffTask(
      smsSyncTaskName,
      smsSyncTaskName,
      inputData: {
        'fromDate': fromDate?.toIso8601String(),
        'toDate': toDate?.toIso8601String(),
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    debugPrint('Immediate SMS sync triggered');
  }

  bool get isPeriodicSyncScheduled {
    // TODO: Implement proper checking using Workmanager API when available
    // For now, we'll return _initialized as a proxy, but ideally we should
    // check if the periodic task is actually registered
    return _initialized;
  }
}
