import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'database_helper.dart';
import 'notification_service.dart';
import 'sms_filter_service.dart';
import '../constants.dart';

class SmsService {
  final SmsQuery _smsQuery = SmsQuery();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  final SmsFilterService _filterService = SmsFilterService();

  Future<int> fetchAndStoreSms() async {
    int newMessagesCount = 0;
    final messages = await _smsQuery.querySms(kinds: [SmsQueryKind.inbox]);
    final existingIds = await _dbHelper.getAllMessageIds();
    List<Map<String, dynamic>> messagesToInsert = [];

    for (var message in messages) {
      if (message.id != null && _filterService.isTransactionSms(message)) {
        if (!existingIds.contains(message.id!)) {
          messagesToInsert.add({
            AppConstants.colId: message.id,
            AppConstants.colAddress: message.address,
            AppConstants.colBody: message.body,
            AppConstants.colDate: message.date?.millisecondsSinceEpoch ?? 0,
            AppConstants.colCategory: _filterService.categorizeSms(message),
          });
          newMessagesCount++;
        }
      }
    }

    if (messagesToInsert.isNotEmpty) {
      await _dbHelper.batchInsertMessages(messagesToInsert);
    }

    if (newMessagesCount > 0) {
      await _notificationService.showNotification(
        'New SMS Added',
        '$newMessagesCount new messages have been added to local storage.',
      );
    }

    return newMessagesCount;
  }

  Future<List<Map<String, dynamic>>> getStoredMessages() async {
    return await _dbHelper.getMessages();
  }
}
