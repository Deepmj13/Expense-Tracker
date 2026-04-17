import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static const usersBoxName = 'users_box';
  static const transactionsBoxName = 'transactions_box';
  static const appBoxName = 'app_box';
  static const processedSmsBoxName = 'processed_sms_box';

  Box<Map>? _usersBox;
  Box<Map>? _transactionsBox;
  Box<dynamic>? _appBox;
  Box<String>? _processedSmsBox;

  Future<void> init() async {
    _usersBox = await Hive.openBox<Map>(usersBoxName);
    _transactionsBox = await Hive.openBox<Map>(transactionsBoxName);
    _appBox = await Hive.openBox(appBoxName);
    _processedSmsBox = await Hive.openBox<String>(processedSmsBoxName);
  }

  Box<Map> usersBox() => _usersBox ?? Hive.box<Map>(usersBoxName);

  Box<Map> transactionsBox() =>
      _transactionsBox ?? Hive.box<Map>(transactionsBoxName);

  Box<dynamic> appBox() => _appBox ?? Hive.box(appBoxName);

  Box<String> processedSmsBox() =>
      _processedSmsBox ?? Hive.box<String>(processedSmsBoxName);
}
