import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

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
}

Future<void> _performOneTimeSync(Map<String, dynamic>? inputData) async {
  debugPrint('Performing one-time SMS sync...');
}

class SmsBackgroundSyncService {
  SmsBackgroundSyncService._();

  static final SmsBackgroundSyncService instance = SmsBackgroundSyncService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    _initialized = true;
  }

  Future<void> schedulePeriodicSync({
    Duration frequency = const Duration(hours: 4),
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
