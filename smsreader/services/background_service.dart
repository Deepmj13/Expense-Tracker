import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'sms_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Initialize notification service for background tasks
    await NotificationService().init();

    final smsService = SmsService();
    try {
      await smsService.fetchAndStoreSms();
    } catch (e) {
      debugPrint('Error in background SMS fetch: $e');
    }
    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true if you want to see logs in debug
    );

    await Workmanager().registerPeriodicTask(
      'sms-fetch-task',
      'fetchSmsTask',
      frequency: Duration(hours: 3),
    );
  }
}
