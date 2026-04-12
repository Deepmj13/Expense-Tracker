import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'transaction_service.dart';
import 'sms_transaction_service.dart';
import 'auth_service.dart';
import 'transaction_parser.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final dbService = DatabaseService();
    await dbService.init();

    final authService = AuthService(dbService);
    final user = await authService.getCurrentUser();

    if (user == null) return Future.value(true);

    final transactionService = TransactionService(dbService);
    final parser = TransactionParser();
    final smsService =
        SmsTransactionService(dbService, transactionService, parser);

    try {
      await smsService.syncSmsTransactions(user.id);
    } catch (e) {
      debugPrint('Error in SMS background sync: $e');
    }
    return Future.value(true);
  });
}

class SmsBackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    await Workmanager().registerPeriodicTask(
      'sms-sync-task',
      'syncSmsTransactions',
      frequency: Duration(hours: 3),
      constraints: Constraints(),
    );
  }
}
