import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static const usersBoxName = 'users_box';
  static const transactionsBoxName = 'transactions_box';
  static const appBoxName = 'app_box';
  static const processedSmsIdsKey = 'processed_sms_ids';

  Box<Map>? _usersBox;
  Box<Map>? _transactionsBox;
  Box<dynamic>? _appBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _usersBox = await Hive.openBox<Map>(usersBoxName);
    _transactionsBox = await Hive.openBox<Map>(transactionsBoxName);
    _appBox = await Hive.openBox(appBoxName);
  }

  Box<Map> usersBox() => _usersBox ?? Hive.box<Map>(usersBoxName);

  Box<Map> transactionsBox() =>
      _transactionsBox ?? Hive.box<Map>(transactionsBoxName);

  Box<dynamic> appBox() => _appBox ?? Hive.box(appBoxName);
}
