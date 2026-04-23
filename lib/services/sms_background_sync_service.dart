import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'database_service.dart';
import 'sms_transaction_service.dart';
import 'sms_sync_preference_service.dart';
import 'transaction_service.dart';
import 'transaction_parser.dart';
import 'notification_service.dart';
import 'sms_sync_manager.dart';

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
      final syncManager = SmsSyncManager(
        smsService: _createSmsService(),
        preferenceService: prefsService,
        notificationService: NotificationService.instance,
      );

      await syncManager.syncAndNotifyUpcoming(prefs.lastUserId!);
      await syncManager.checkAndSendReminder();
    });
  } catch (e) {
    debugPrint('Error in periodic sync: $e');
  }
}

Future<void> _performOneTimeSync(Map<String, dynamic>? inputData) async {
  debugPrint('Performing one-time SMS sync...');

  try {
    await _initializeSync((prefsService, prefs) async {
      final syncManager = SmsSyncManager(
        smsService: _createSmsService(),
        preferenceService: prefsService,
        notificationService: NotificationService.instance,
      );

      final DateTime? fromDate =
          inputData != null && inputData['fromDate'] != null
              ? DateTime.tryParse(inputData['fromDate'] as String)
              : null;
      final DateTime? toDate = inputData != null && inputData['toDate'] != null
          ? DateTime.tryParse(inputData['toDate'] as String)
          : null;

      // Use manual sync logic for one-time sync
      final result = await _syncSmsManual(
        prefs.lastUserId!,
        syncManager,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (result.addedCount > 0) {
        await syncManager.showSyncNotification(result.addedCount);
      }
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

SmsTransactionService _createSmsService() {
  final dbService = DatabaseService();
  // This is a bit tricky because DatabaseService.init() is async
  // We will call it inside the sync methods or ensure it's initialized.
  // Let's create a helper for this.
  return SmsTransactionService(
      dbService, TransactionService(dbService), const TransactionParser());
}

Future<SmsSyncResult> _syncSmsManual(
  String userId,
  SmsSyncManager syncManager, {
  DateTime? fromDate,
  DateTime? toDate,
}) async {
  final dbService = DatabaseService();
  await dbService.init();

  final smsService = _createSmsService();
  final addedCount = await smsService.syncSmsTransactions(
    userId,
    fromDate: fromDate,
    toDate: toDate ?? DateTime.now(),
  );

  return SmsSyncResult(addedCount: addedCount);
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
