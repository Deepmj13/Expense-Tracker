import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationChannelService {
  NotificationChannelService._();
  static final NotificationChannelService _instance =
      NotificationChannelService._();
  factory NotificationChannelService() => _instance;

  static const _notificationChannel =
      EventChannel('com.example.expense_tracker/notifications');
  static const _methodChannel =
      MethodChannel('com.example.expense_tracker/methods');

  static const _monitoredAppsKey = 'monitored_notification_apps';
  static const _notificationEnabledKey = 'notification_auto_add_enabled';

  Stream<Map<String, dynamic>>? _notificationStream;
  StreamSubscription<Map<dynamic, dynamic>>? _subscription;

  Stream<Map<String, dynamic>> get notificationStream {
    _notificationStream ??= _notificationChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
    return _notificationStream!;
  }

  Future<bool> isNotificationAccessEnabled() async {
    try {
      final result = await _methodChannel
          .invokeMethod<bool>('isNotificationAccessEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking notification access: ${e.message}');
      return false;
    }
  }

  Future<bool> openNotificationSettings() async {
    try {
      await _methodChannel.invokeMethod('openNotificationSettings');
      return true;
    } on PlatformException catch (e) {
      debugPrint('Error opening notification settings: ${e.message}');
      return false;
    }
  }

  Future<bool> setMonitoredApps(List<String> apps) async {
    try {
      await _methodChannel.invokeMethod('setMonitoredApps', apps);
      final box = Hive.box('app_box');
      await box.put(_monitoredAppsKey, apps);
      return true;
    } on PlatformException catch (e) {
      debugPrint('Error setting monitored apps: ${e.message}');
      return false;
    }
  }

  Future<List<String>> getMonitoredApps() async {
    final box = Hive.box('app_box');
    final apps = box.get(_monitoredAppsKey, defaultValue: <String>[]);
    return List<String>.from(apps as List);
  }

  Future<bool> isAutoAddEnabled() async {
    final box = Hive.box('app_box');
    return box.get(_notificationEnabledKey, defaultValue: true) as bool;
  }

  Future<void> setAutoAddEnabled(bool enabled) async {
    final box = Hive.box('app_box');
    await box.put(_notificationEnabledKey, enabled);
  }

  Future<bool> isBatteryOptimizationDisabled() async {
    try {
      final result = await _methodChannel
          .invokeMethod<bool>('isBatteryOptimizationDisabled');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking battery optimization: ${e.message}');
      return false;
    }
  }

  Future<bool> openBatteryOptimizationSettings() async {
    try {
      await _methodChannel.invokeMethod('openBatteryOptimizationSettings');
      return true;
    } on PlatformException catch (e) {
      debugPrint('Error opening battery settings: ${e.message}');
      return false;
    }
  }

  Future<bool> requestBatteryOptimizationExemption() async {
    try {
      await _methodChannel.invokeMethod('requestBatteryOptimizationExemption');
      return true;
    } on PlatformException catch (e) {
      debugPrint('Error requesting battery exemption: ${e.message}');
      return false;
    }
  }

  Future<String> getDeviceManufacturer() async {
    try {
      final result =
          await _methodChannel.invokeMethod<String>('getDeviceManufacturer');
      return result ?? 'unknown';
    } on PlatformException catch (e) {
      debugPrint('Error getting device manufacturer: ${e.message}');
      return 'unknown';
    }
  }

  Future<bool> openAutoStartSettings() async {
    try {
      await _methodChannel.invokeMethod('openAutoStartSettings');
      return true;
    } on PlatformException catch (e) {
      debugPrint('Error opening auto-start settings: ${e.message}');
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _notificationStream = null;
  }
}
