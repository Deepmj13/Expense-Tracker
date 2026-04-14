import 'package:hive_flutter/hive_flutter.dart';

enum SyncPreference {
  none,
  previous,
  upcoming,
}

class SmsSyncPreferences {
  SmsSyncPreferences({
    this.preference = SyncPreference.none,
    this.previousFromDate,
    this.lastSyncTime,
    this.periodicSyncEnabled = false,
    this.syncOnAppOpen = true,
    this.previousSyncCompleted = false,
    this.reminderEnabled = true,
    this.lastAppOpenTime,
    this.lastReminderSentTime,
    this.lastManualTransactionTime,
    this.pausedReminderTime,
    this.notificationPermissionAsked = false,
  });

  SyncPreference preference;
  DateTime? previousFromDate;
  DateTime? lastSyncTime;
  bool periodicSyncEnabled;
  bool syncOnAppOpen;
  bool previousSyncCompleted;
  bool reminderEnabled;
  DateTime? lastAppOpenTime;
  DateTime? lastReminderSentTime;
  DateTime? lastManualTransactionTime;
  DateTime? pausedReminderTime;
  bool notificationPermissionAsked;

  Map<String, dynamic> toMap() => {
        'preference': preference.name,
        'previousFromDate': previousFromDate?.toIso8601String(),
        'lastSyncTime': lastSyncTime?.toIso8601String(),
        'periodicSyncEnabled': periodicSyncEnabled,
        'syncOnAppOpen': syncOnAppOpen,
        'previousSyncCompleted': previousSyncCompleted,
        'reminderEnabled': reminderEnabled,
        'lastAppOpenTime': lastAppOpenTime?.toIso8601String(),
        'lastReminderSentTime': lastReminderSentTime?.toIso8601String(),
        'lastManualTransactionTime':
            lastManualTransactionTime?.toIso8601String(),
        'pausedReminderTime': pausedReminderTime?.toIso8601String(),
        'notificationPermissionAsked': notificationPermissionAsked,
      };

  factory SmsSyncPreferences.fromMap(Map<dynamic, dynamic> map) {
    return SmsSyncPreferences(
      preference: SyncPreference.values.firstWhere(
        (e) => e.name == map['preference'],
        orElse: () => SyncPreference.none,
      ),
      previousFromDate: map['previousFromDate'] != null
          ? DateTime.parse(map['previousFromDate'])
          : null,
      lastSyncTime: map['lastSyncTime'] != null
          ? DateTime.parse(map['lastSyncTime'])
          : null,
      periodicSyncEnabled: map['periodicSyncEnabled'] ?? false,
      syncOnAppOpen: map['syncOnAppOpen'] ?? true,
      previousSyncCompleted: map['previousSyncCompleted'] ?? false,
      reminderEnabled: map['reminderEnabled'] ?? true,
      lastAppOpenTime: map['lastAppOpenTime'] != null
          ? DateTime.parse(map['lastAppOpenTime'])
          : null,
      lastReminderSentTime: map['lastReminderSentTime'] != null
          ? DateTime.parse(map['lastReminderSentTime'])
          : null,
      lastManualTransactionTime: map['lastManualTransactionTime'] != null
          ? DateTime.parse(map['lastManualTransactionTime'])
          : null,
      pausedReminderTime: map['pausedReminderTime'] != null
          ? DateTime.parse(map['pausedReminderTime'])
          : null,
      notificationPermissionAsked: map['notificationPermissionAsked'] ?? false,
    );
  }
}

class SmsSyncPreferenceService {
  static const _boxName = 'sms_sync_preferences_box';
  static const _prefsKey = 'sms_sync_prefs';

  Box<Map>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  Box<Map> _getBox() => _box ?? Hive.box<Map>(_boxName);

  SmsSyncPreferences getPreferences() {
    final box = _getBox();
    final data = box.get(_prefsKey);
    if (data == null) return SmsSyncPreferences();
    return SmsSyncPreferences.fromMap(data);
  }

  Future<void> savePreferences(SmsSyncPreferences prefs) async {
    final box = _getBox();
    await box.put(_prefsKey, prefs.toMap());
  }

  Future<void> setPreference(SyncPreference preference) async {
    final prefs = getPreferences();
    prefs.preference = preference;
    await savePreferences(prefs);
  }

  Future<void> setPreviousFromDate(DateTime date) async {
    final prefs = getPreferences();
    prefs.previousFromDate = date;
    await savePreferences(prefs);
  }

  Future<void> setLastSyncTime(DateTime time) async {
    final prefs = getPreferences();
    prefs.lastSyncTime = time;
    await savePreferences(prefs);
  }

  Future<void> setPeriodicSyncEnabled(bool enabled) async {
    final prefs = getPreferences();
    prefs.periodicSyncEnabled = enabled;
    await savePreferences(prefs);
  }

  Future<void> setSyncOnAppOpen(bool enabled) async {
    final prefs = getPreferences();
    prefs.syncOnAppOpen = enabled;
    await savePreferences(prefs);
  }

  Future<void> setPreviousSyncCompleted(bool completed) async {
    final prefs = getPreferences();
    prefs.previousSyncCompleted = completed;
    await savePreferences(prefs);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = getPreferences();
    prefs.reminderEnabled = enabled;
    await savePreferences(prefs);
  }

  Future<void> setLastAppOpenTime(DateTime time) async {
    final prefs = getPreferences();
    prefs.lastAppOpenTime = time;
    await savePreferences(prefs);
  }

  Future<void> setLastReminderSentTime(DateTime time) async {
    final prefs = getPreferences();
    prefs.lastReminderSentTime = time;
    await savePreferences(prefs);
  }

  Future<void> setLastManualTransactionTime(DateTime time) async {
    final prefs = getPreferences();
    prefs.lastManualTransactionTime = time;
    await savePreferences(prefs);
  }

  Future<void> setPausedReminderTime(DateTime? time) async {
    final prefs = getPreferences();
    prefs.pausedReminderTime = time;
    await savePreferences(prefs);
  }

  Future<void> setNotificationPermissionAsked(bool asked) async {
    final prefs = getPreferences();
    prefs.notificationPermissionAsked = asked;
    await savePreferences(prefs);
  }

  Future<void> clearPreferences() async {
    final box = _getBox();
    await box.delete(_prefsKey);
  }
}
