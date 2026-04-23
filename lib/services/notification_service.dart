import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final timezoneName = timezoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timezoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return false;
  }

  Future<bool> isPermissionGranted() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        return enabled ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final result = await iosPlugin.checkPermissions();
        return result?.isEnabled ?? false;
      }
    }
    return false;
  }

  Future<void> showTransactionAddedNotification(int count) async {
    const androidDetails = AndroidNotificationDetails(
      'transaction_sync_channel',
      'Transaction Sync',
      channelDescription: 'Notifications for auto-added transactions',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title =
        count == 1 ? 'New Transaction Added' : '$count New Transactions Added';

    final body = count == 1
        ? 'A new transaction has been automatically added from your SMS.'
        : '$count new transactions have been automatically added from your SMS.';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: 'transaction_sync',
    );
  }

  Future<void> showSyncCompleteNotification(int count) async {
    if (count == 0) return;

    const androidDetails = AndroidNotificationDetails(
      'transaction_sync_channel',
      'Transaction Sync',
      channelDescription: 'Notifications for auto-added transactions',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title =
        count == 1 ? 'Transaction Added' : '$count Transactions Added';

    final body = count == 1
        ? 'A new transaction was added from SMS'
        : '$count new transactions were added from SMS';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: 'transaction_sync',
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  bool isQuietHours() {
    final hour = DateTime.now().hour;
    return hour >= 23 || hour < 7;
  }

  Future<void> showDelayedTransactionNotification(int count) async {
    if (isQuietHours()) return;

    const androidDetails = AndroidNotificationDetails(
      'transaction_sync_channel',
      'Transaction Sync',
      channelDescription: 'Notifications for auto-added transactions',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title =
        count == 1 ? 'New Transaction Added' : '$count New Transactions Added';

    final body = count == 1
        ? 'A new transaction has been automatically added from your SMS.'
        : '$count new transactions have been automatically added from your SMS.';

    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 2));

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'transaction_sync',
    );
  }

  Future<void> showReminderNotification() async {
    if (isQuietHours()) return;

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Reminders to add manual transactions',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId =
        1001; // Constant ID for reminders to replace previous ones

    await _notifications.show(
      notificationId,
      'Time to add transactions!',
      'Don\'t forget to log your expenses manually.',
      details,
      payload: 'reminder',
    );
  }

  Future<void> showBudgetExceededNotification(
      double amount, String currencySymbol) async {
    const androidDetails = AndroidNotificationDetails(
      'budget_alert_channel',
      'Budget Alerts',
      channelDescription: 'Alerts when you exceed your budget',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notifications.show(
      notificationId,
      'Budget Exceeded!',
      'You\'ve spent $currencySymbol${amount.toStringAsFixed(2)} more than your budget.',
      details,
      payload: 'budget_exceeded',
    );
  }
}
