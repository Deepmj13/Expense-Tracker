import 'package:flutter/material.dart';
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

  Future<SmsSyncResult> syncNow(String userId) async {
    try {
      final addedCount = await _smsService.syncSmsTransactions(
        userId,
        fromDate: null,
        toDate: DateTime.now(),
      );

      await _preferenceService.setLastSyncTime(DateTime.now());

      return SmsSyncResult(addedCount: addedCount);
    } catch (e) {
      return SmsSyncResult(errorMessage: e.toString());
    }
  }

  Future<void> showSyncNotification(BuildContext context, int count) async {
    if (count > 0) {
      await _notificationService.showTransactionAddedNotification(
        context,
        count,
      );
    }
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
