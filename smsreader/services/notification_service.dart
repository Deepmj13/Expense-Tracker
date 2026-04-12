import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';
import '../constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> init() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin!.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Use a random ID to avoid overwriting previous notifications
    final int notificationId = Random().nextInt(100000);
    await _notificationsPlugin!.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
