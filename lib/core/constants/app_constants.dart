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
    'Utilities',
    'Transport',
    'Other',
  ];

  static List<String> get allCategories {
    final box = Hive.box('app_box');
    final custom =
        (box.get('custom_categories', defaultValue: <String>[]) as List)
            .cast<String>()
            .toList();
    return [...defaultCategories, ...custom];
  }

  static List<String> get customCategories {
    final box = Hive.box('app_box');
    return (box.get('custom_categories', defaultValue: <String>[]) as List)
        .cast<String>()
        .toList();
  }

  static Future<void> addCustomCategory(String category) async {
    final box = Hive.box('app_box');
    final custom = customCategories;
    final normalizedCategory = category.trim();
    if (!custom.contains(normalizedCategory) &&
        !defaultCategories.contains(normalizedCategory)) {
      custom.add(normalizedCategory);
      await box.put('custom_categories', custom);
    }
  }

  static Future<void> removeCustomCategory(String category) async {
    final box = Hive.box('app_box');
    final custom = customCategories;
    custom.remove(category);
    await box.put('custom_categories', custom);
  }

  static const paymentMethods = <String>[
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'UPI',
    'Other',
  ];

  static const accentColors = <String, int>{
    'Teal': 0xFF0D9488,
    'Blue': 0xFF3B82F6,
    'Purple': 0xFF8B5CF6,
    'Green': 0xFF10B981,
    'Orange': 0xFFF97316,
    'Pink': 0xFFEC4899,
    'Red': 0xFFEF4444,
    'Indigo': 0xFF6366F1,
  };

  static int get defaultAccentColor => 0xFF0D9488;

  static int getAccentColor() {
    try {
      if (!Hive.isBoxOpen('app_box')) {
        return defaultAccentColor;
      }
      final box = Hive.box('app_box');
      return box.get('accent_color', defaultValue: defaultAccentColor) as int;
    } catch (e) {
      return defaultAccentColor;
    }
  }

  static Future<void> setAccentColor(int color) async {
    try {
      if (!Hive.isBoxOpen('app_box')) {
        return;
      }
      final box = Hive.box('app_box');
      await box.put('accent_color', color);
    } catch (e) {
      // Silently fail if box not ready
    }
  }
}
