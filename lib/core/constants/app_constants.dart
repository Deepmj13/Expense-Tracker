import 'package:hive_flutter/hive_flutter.dart';

class AppConstants {
  static const defaultCategories = <String>[
    'Food',
    'Travel',
    'Bills',
    'Shopping',
    'Health',
    'Salary',
    'Investment',
    'Entertainment',
    'Education',
    'Other',
  ];

  static List<String> get categories {
    final box = Hive.box('app_box');
    final custom =
        box.get('custom_categories', defaultValue: <String>[]) as List;
    return [...defaultCategories, ...custom.cast<String>()];
  }

  static Future<void> addCustomCategory(String category) async {
    final box = Hive.box('app_box');
    final custom =
        (box.get('custom_categories', defaultValue: <String>[]) as List)
            .cast<String>()
            .toList();
    if (!custom.contains(category) && !defaultCategories.contains(category)) {
      custom.add(category);
      await box.put('custom_categories', custom);
    }
  }

  static const paymentMethods = <String>[
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'UPI',
    'Other',
  ];
}
