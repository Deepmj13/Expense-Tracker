import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'database_service.dart';
import 'sms_transaction_service.dart';
import 'sms_sync_preference_service.dart';
import 'transaction_service.dart';
import 'transaction_parser.dart';

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
    await Hive.initFlutter();

    final prefsService = SmsSyncPreferenceService();
    await prefsService.init();

    final prefs = prefsService.getPreferences();
    final userId = prefs.lastUserId;

    if (userId == null) {
      debugPrint('No user ID stored, skipping periodic sync');
      return;
    }

    await _syncSms(userId, prefsService);
  } catch (e) {
    debugPrint('Error in periodic sync: $e');
  }
}

Future<void> _performOneTimeSync(Map<String, dynamic>? inputData) async {
  debugPrint('Performing one-time SMS sync...');

  try {
    await Hive.initFlutter();

    final prefsService = SmsSyncPreferenceService();
    await prefsService.init();

    final prefs = prefsService.getPreferences();
    final userId = prefs.lastUserId;

    if (userId == null) {
      debugPrint('No user ID stored, skipping one-time sync');
      return;
    }

    DateTime? fromDate;
    DateTime? toDate;

    if (inputData != null) {
      if (inputData['fromDate'] != null) {
        fromDate = DateTime.tryParse(inputData['fromDate']);
      }
      if (inputData['toDate'] != null) {
        toDate = DateTime.tryParse(inputData['toDate']);
      }
    }

    await _syncSms(userId, prefsService, fromDate: fromDate, toDate: toDate);
  } catch (e) {
    debugPrint('Error in one-time sync: $e');
  }
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
    Duration frequency = const Duration(hours: 2),
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
    return _initialized;
  }
}
