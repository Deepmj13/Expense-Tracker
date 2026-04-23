import 'sms_sync_preference_service.dart';
import 'sms_transaction_service.dart';
import 'notification_service.dart';

class SmsSyncResult {
  SmsSyncResult({
    this.addedCount = 0,
    this.skippedCount = 0,
    this.errorMessage,
  });

  final int addedCount;
  final int skippedCount;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  SmsSyncResult copyWith({
    int? addedCount,
    int? skippedCount,
    String? errorMessage,
  }) {
    return SmsSyncResult(
      addedCount: addedCount ?? this.addedCount,
      skippedCount: skippedCount ?? this.skippedCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SmsSyncManager {
  SmsSyncManager({
    required SmsTransactionService smsService,
    required SmsSyncPreferenceService preferenceService,
    required NotificationService notificationService,
  })  : _smsService = smsService,
        _preferenceService = preferenceService,
        _notificationService = notificationService;

  final SmsTransactionService _smsService;
  final SmsSyncPreferenceService _preferenceService;
  final NotificationService _notificationService;

  Future<void> init() async {
    await _preferenceService.init();
  }

  SmsSyncPreferences getPreferences() {
    return _preferenceService.getPreferences();
  }

  bool get isSyncEnabled {
    final prefs = getPreferences();
    return prefs.preference != SyncPreference.none;
  }

  Future<SmsSyncResult> syncAll(String userId) async {
    SmsSyncResult result = SmsSyncResult();
    final prefs = getPreferences();

    try {
      if (prefs.preference == SyncPreference.upcoming) {
        final syncResult = await _syncUpcoming(userId);
        result = result.copyWith(
          addedCount: result.addedCount + syncResult.addedCount,
        );
      } else if (prefs.preference == SyncPreference.previous) {
        if (!prefs.previousSyncCompleted) {
          final syncResult =
              await _syncPrevious(userId, prefs.previousFromDate!);
          result = result.copyWith(
            addedCount: result.addedCount + syncResult.addedCount,
          );

          if (syncResult.addedCount > 0) {
            await _preferenceService.setPreviousSyncCompleted(true);
          }
        }

        if (prefs.periodicSyncEnabled || prefs.syncOnAppOpen) {
          final syncResult = await _syncUpcoming(userId);
          result = result.copyWith(
            addedCount: result.addedCount + syncResult.addedCount,
          );
        }
      }

      await _preferenceService.setLastSyncTime(DateTime.now());
    } catch (e) {
      return SmsSyncResult(errorMessage: e.toString());
    }

    return result;
  }

  Future<SmsSyncResult> syncPrevious(String userId, DateTime fromDate) async {
    try {
      final addedCount = await _smsService.syncSmsTransactions(
        userId,
        fromDate: fromDate,
        toDate: DateTime.now(),
      );

      await _preferenceService.setPreviousSyncCompleted(true);
      await _preferenceService.setLastSyncTime(DateTime.now());

      return SmsSyncResult(addedCount: addedCount);
    } catch (e) {
      return SmsSyncResult(errorMessage: e.toString());
    }
  }

  Future<SmsSyncResult> _syncPrevious(String userId, DateTime fromDate) async {
    try {
      final addedCount = await _smsService.syncSmsTransactions(
        userId,
        fromDate: fromDate,
        toDate: DateTime.now(),
      );

      return SmsSyncResult(addedCount: addedCount);
    } catch (e) {
      return SmsSyncResult(errorMessage: e.toString());
    }
  }

  Future<SmsSyncResult> syncUpcoming(String userId) async {
    return await _syncUpcoming(userId);
  }

  Future<SmsSyncResult> _syncUpcoming(String userId) async {
    final prefs = getPreferences();

    try {
      DateTime? fromDate = prefs.lastSyncTime;
      if (fromDate == null) {
        fromDate = DateTime.now().subtract(const Duration(hours: 4));
      }

      final addedCount = await _smsService.syncSmsTransactions(
        userId,
        fromDate: fromDate,
        toDate: DateTime.now(),
      );

      await _preferenceService.setLastSyncTime(DateTime.now());

      return SmsSyncResult(addedCount: addedCount);
    } catch (e) {
      return SmsSyncResult(errorMessage: e.toString());
    }
  }

  Future<void> syncAndNotifyUpcoming(String userId) async {
    final result = await syncUpcoming(userId);
    await showSyncNotification(result.addedCount);
  }

  Future<void> showSyncNotification(int count) async {
    if (count > 0) {
      await _notificationService.showTransactionAddedNotification(count);
    }
  }

  DateTime getNextScheduledReminderTime(DateTime now) {
    final today2PM = DateTime(now.year, now.month, now.day, 14);
    final today6PM = DateTime(now.year, now.month, now.day, 18);
    final today10PM = DateTime(now.year, now.month, now.day, 22);

    if (now.isBefore(today2PM)) return today2PM;
    if (now.isBefore(today6PM)) return today6PM;
    if (now.isBefore(today10PM)) return today10PM;
    return today2PM.add(const Duration(days: 1));
  }

  DateTime? _getLastActivityTime(SmsSyncPreferences prefs) {
    DateTime? lastActivity = prefs.lastAppOpenTime;
    final lastTransaction = prefs.lastManualTransactionTime;
    if (lastTransaction != null) {
      if (lastActivity == null || lastTransaction.isAfter(lastActivity)) {
        lastActivity = lastTransaction;
      }
    }
    return lastActivity;
  }

  Future<void> checkAndSendReminder() async {
    final prefs = getPreferences();
    if (!prefs.reminderEnabled) return;
    if (_notificationService.isQuietHours()) return;

    final now = DateTime.now();
    final scheduledTime = getNextScheduledReminderTime(now);

    final reminderHour = scheduledTime.hour;
    if (now.hour < reminderHour) return;

    final lastActivity = _getLastActivityTime(prefs);
    if (lastActivity != null) {
      final hoursSinceActivity = now.difference(lastActivity).inHours;
      if (hoursSinceActivity < 3) return;
    }

    await _preferenceService.setLastReminderSentTime(now);
    await _preferenceService.setPausedReminderTime(null);
    await _notificationService.showReminderNotification();
  }

  Future<void> onAppOpen() async {
    final prefs = getPreferences();
    final now = DateTime.now();

    if (!_notificationService.isQuietHours() &&
        prefs.pausedReminderTime != null) {
      final pausedAt = prefs.pausedReminderTime!;
      final pauseDuration = now.difference(pausedAt);

      if (pauseDuration.inHours >= 4) {
        await _preferenceService.setLastReminderSentTime(now);
        await _preferenceService.setPausedReminderTime(null);
        await _notificationService.showReminderNotification();
      } else {
        await _preferenceService.setPausedReminderTime(null);
      }
    }
  }

  Future<void> setLastManualTransactionTime(DateTime time) async {
    await _preferenceService.setLastManualTransactionTime(time);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    await _preferenceService.setReminderEnabled(enabled);
  }

  bool get isReminderEnabled {
    return getPreferences().reminderEnabled;
  }

  Future<void> setLastAppOpenTime(DateTime time) async {
    await _preferenceService.setLastAppOpenTime(time);
  }

  Future<void> setNotificationPermissionAsked(bool asked) async {
    await _preferenceService.setNotificationPermissionAsked(asked);
  }

  Future<void> savePreference(SyncPreference preference,
      {DateTime? fromDate}) async {
    final prefs = getPreferences();
    prefs.preference = preference;
    if (fromDate != null) {
      prefs.previousFromDate = fromDate;
    }
    if (preference == SyncPreference.none) {
      prefs.previousSyncCompleted = false;
    }
    await _preferenceService.savePreferences(prefs);
  }

  Future<void> updatePeriodicSync(bool enabled) async {
    await _preferenceService.setPeriodicSyncEnabled(enabled);
  }

  Future<void> updateSyncOnAppOpen(bool enabled) async {
    await _preferenceService.setSyncOnAppOpen(enabled);
  }
}
