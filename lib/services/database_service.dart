import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static const usersBoxName = 'users_box';
  static const transactionsBoxName = 'transactions_box';
  static const appBoxName = 'app_box';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(usersBoxName);
    await Hive.openBox<Map>(transactionsBoxName);
    await Hive.openBox(appBoxName);
  }

  Box<Map> usersBox() => Hive.box<Map>(usersBoxName);

  Box<Map> transactionsBox() => Hive.box<Map>(transactionsBoxName);

  Box appBox() => Hive.box(appBoxName);
}
