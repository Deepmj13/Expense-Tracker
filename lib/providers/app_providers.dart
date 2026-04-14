import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/sms_sync_manager.dart';
import '../services/sms_sync_preference_service.dart';
import '../services/sms_transaction_service.dart';
import '../services/transaction_parser.dart';
import '../services/transaction_service.dart';

final dbServiceProvider = Provider<DatabaseService>((_) => DatabaseService());
final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.read(dbServiceProvider)));
final transactionServiceProvider = Provider<TransactionService>(
    (ref) => TransactionService(ref.read(dbServiceProvider)));
final budgetServiceProvider = Provider<BudgetService>(
    (ref) => BudgetService(ref.read(dbServiceProvider)));
final transactionParserProvider =
    Provider<TransactionParser>((_) => const TransactionParser());
final smsSyncPreferenceServiceProvider =
    FutureProvider<SmsSyncPreferenceService>((_) async {
  final service = SmsSyncPreferenceService();
  await service.init();
  return service;
});
final smsTransactionServiceProvider = Provider<SmsTransactionService>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  final transactionService = ref.watch(transactionServiceProvider);
  final parser = ref.watch(transactionParserProvider);
  return SmsTransactionService(dbService, transactionService, parser);
});
final smsSyncManagerProvider = FutureProvider<SmsSyncManager>((ref) async {
  final smsService = ref.watch(smsTransactionServiceProvider);
  final prefService = await ref.watch(smsSyncPreferenceServiceProvider.future);
  final notifService = NotificationService.instance;
  return SmsSyncManager(
    smsService: smsService,
    preferenceService: prefService,
    notificationService: notifService,
  );
});
const _secureStorage = FlutterSecureStorage();

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  ref.watch(authControllerProvider);
  return ThemeModeNotifier();
});

final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, Color>((ref) {
  ref.watch(authControllerProvider);
  ref.watch(dbServiceProvider);
  return AccentColorNotifier();
});

class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier() : super(const Color(0xFF6750A4)) {
    _loadColor();
  }

  Future<void> _loadColor() async {
    state = Color(AppConstants.getAccentColor());
  }

  Future<void> setAccentColor(Color color) async {
    state = color;
    await AppConstants.setAccentColor(color.toARGB32());
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  static const _key = 'theme_mode';

  Future<void> _loadThemeMode() async {
    try {
      final saved = await _secureStorage.read(key: _key);
      if (saved != null) {
        state = ThemeMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      await _secureStorage.write(key: _key, value: mode.name);
    } catch (_) {}
  }
}

final currencySymbolProvider = Provider<String>((ref) {
  final user = ref.watch(authControllerProvider);
  return user?.currencySymbol ?? '₹';
});

class AuthController extends StateNotifier<AppUser?> {
  AuthController(this._authService, this._hydrationNotifier) : super(null);

  final AuthService _authService;
  final HydrationNotifier _hydrationNotifier;

  Future<void> hydrate() async {
    state = await _authService.getCurrentUser();
    _hydrationNotifier.setHydrated();
  }

  Future<bool> login(String email, String password) async {
    final user = await _authService.login(email: email, password: password);
    state = user;
    return user != null;
  }

  Future<bool> signup(
      String name, String email, String password, Country country) async {
    final user = await _authService.signup(
        name: name, email: email, password: password, country: country);
    state = user;
    return user != null;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = null;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AppUser?>((ref) {
  return AuthController(
    ref.read(authServiceProvider),
    ref.read(isAuthHydratedProvider.notifier),
  );
});

class HydrationNotifier extends StateNotifier<bool> {
  HydrationNotifier() : super(false);

  void setHydrated() => state = true;
}

final isAuthHydratedProvider =
    StateNotifierProvider<HydrationNotifier, bool>((ref) {
  return HydrationNotifier();
});

class TransactionFilter {
  const TransactionFilter({
    this.category,
    this.type,
    this.start,
    this.end,
    this.search = '',
  });

  final String? category;
  final TransactionType? type;
  final DateTime? start;
  final DateTime? end;
  final String search;

  TransactionFilter copyWith({
    String? category,
    TransactionType? type,
    DateTime? start,
    DateTime? end,
    String? search,
    bool clearCategory = false,
    bool clearType = false,
  }) {
    return TransactionFilter(
      category: clearCategory ? null : (category ?? this.category),
      type: clearType ? null : (type ?? this.type),
      start: start ?? this.start,
      end: end ?? this.end,
      search: search ?? this.search,
    );
  }
}

class TransactionsController extends StateNotifier<List<TransactionModel>> {
  TransactionsController(this._service) : super(const []);

  final TransactionService _service;
  String? _userId;

  Future<void> load(String userId) async {
    _userId = userId;
    state = _service.getAll(userId);
  }

  Future<void> upsert(TransactionModel model) async {
    if (_userId == null) return;
    await _service.save(_userId!, model);
    load(_userId!);
  }

  Future<void> remove(String id) async {
    await _service.delete(id);
    if (_userId != null) load(_userId!);
  }
}

final transactionsControllerProvider =
    StateNotifierProvider<TransactionsController, List<TransactionModel>>(
        (ref) {
  return TransactionsController(ref.read(transactionServiceProvider));
});

final transactionFilterProvider =
    StateProvider<TransactionFilter>((_) => const TransactionFilter());

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final items = ref.watch(transactionsControllerProvider);
  final filter = ref.watch(transactionFilterProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  return items.where((item) {
    final monthMatch = item.date.year == selectedMonth.year &&
        item.date.month == selectedMonth.month;
    final categoryMatch =
        filter.category == null || item.category == filter.category;
    final typeMatch = filter.type == null || item.type == filter.type;
    final startMatch =
        filter.start == null || !item.date.isBefore(filter.start!);
    final endMatch = filter.end == null || !item.date.isAfter(filter.end!);
    final searchMatch = filter.search.isEmpty ||
        item.title.toLowerCase().contains(filter.search.toLowerCase()) ||
        item.note.toLowerCase().contains(filter.search.toLowerCase());
    return monthMatch &&
        categoryMatch &&
        typeMatch &&
        startMatch &&
        endMatch &&
        searchMatch;
  }).toList();
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final selectedYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});

final currentBudgetProvider = Provider<BudgetModel?>((ref) {
  final budget = ref.watch(budgetControllerProvider);
  ref.watch(selectedMonthProvider);
  return budget;
});

final monthlyExpensesProvider = Provider<double>((ref) {
  final items = ref.watch(transactionsControllerProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  return items
      .where((t) =>
          t.type == TransactionType.expense &&
          t.date.year == selectedMonth.year &&
          t.date.month == selectedMonth.month)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final monthlyIncomeProvider = Provider<double>((ref) {
  final items = ref.watch(transactionsControllerProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  return items
      .where((t) =>
          t.type == TransactionType.income &&
          t.date.year == selectedMonth.year &&
          t.date.month == selectedMonth.month)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final monthlyBalanceProvider = Provider<double>((ref) {
  final income = ref.watch(monthlyIncomeProvider);
  final expense = ref.watch(monthlyExpensesProvider);
  return income - expense;
});

final budgetProgressProvider = Provider<double>((ref) {
  final budget = ref.watch(currentBudgetProvider);
  final expenses = ref.watch(monthlyExpensesProvider);
  if (budget == null || budget.amount == 0) return 0;
  return (expenses / budget.amount).clamp(0.0, 2.0);
});

final budgetAlertProvider = Provider<BudgetAlertLevel>((ref) {
  final progress = ref.watch(budgetProgressProvider);
  if (progress >= 1.0) return BudgetAlertLevel.exceeded;
  if (progress >= 0.9) return BudgetAlertLevel.ninetyPercent;
  if (progress >= 0.5) return BudgetAlertLevel.fiftyPercent;
  return BudgetAlertLevel.none;
});

final budgetRemainingProvider = Provider<double>((ref) {
  final budget = ref.watch(currentBudgetProvider);
  final expenses = ref.watch(monthlyExpensesProvider);
  if (budget == null) return 0;
  return budget.amount - expenses;
});

class BudgetController extends StateNotifier<BudgetModel?> {
  BudgetController(this._service, this._month)
      : super(_service.getBudget(_month.month, _month.year));

  final BudgetService _service;
  final DateTime _month;

  Future<void> save(double amount) async {
    final budget = BudgetModel(
      id: '${_month.year}-${_month.month}-${DateTime.now().millisecondsSinceEpoch}',
      month: _month.month,
      year: _month.year,
      amount: amount,
      createdAt: DateTime.now(),
    );
    await _service.saveBudget(budget);
    state = budget;
  }

  Future<void> delete() async {
    await _service.deleteBudget('${_month.year}-${_month.month}');
    state = null;
  }

  void refresh() {
    state = _service.getBudget(_month.month, _month.year);
  }
}

final budgetControllerProvider =
    StateNotifierProvider<BudgetController, BudgetModel?>((ref) {
  final service = ref.watch(budgetServiceProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  return BudgetController(service, selectedMonth);
});

class BudgetAlertController extends StateNotifier<BudgetAlertLevel> {
  BudgetAlertController() : super(BudgetAlertLevel.none);

  BudgetAlertLevel? _lastAlert;

  void checkAndUpdateAlert(BudgetAlertLevel newLevel) {
    if (newLevel != _lastAlert && newLevel != BudgetAlertLevel.none) {
      _lastAlert = newLevel;
      state = newLevel;
    }
  }

  void dismissAlert() {
    _lastAlert = BudgetAlertLevel.none;
    state = BudgetAlertLevel.none;
  }

  void resetForNewMonth() {
    _lastAlert = BudgetAlertLevel.none;
    state = BudgetAlertLevel.none;
  }
}

final budgetAlertControllerProvider =
    StateNotifierProvider<BudgetAlertController, BudgetAlertLevel>((ref) {
  return BudgetAlertController();
});
