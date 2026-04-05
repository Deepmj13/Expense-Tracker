import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/transaction_service.dart';

final dbServiceProvider = Provider<DatabaseService>((_) => DatabaseService());
final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.read(dbServiceProvider)));
final transactionServiceProvider =
    Provider<TransactionService>((ref) => TransactionService(ref.read(dbServiceProvider)));

final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);

class AuthController extends StateNotifier<AppUser?> {
  AuthController(this._authService) : super(null);

  final AuthService _authService;

  Future<void> hydrate() async {
    state = await _authService.getCurrentUser();
  }

  Future<bool> login(String email, String password) async {
    final user = await _authService.login(email: email, password: password);
    state = user;
    return user != null;
  }

  Future<bool> signup(String name, String email, String password) async {
    final user = await _authService.signup(name: name, email: email, password: password);
    state = user;
    return user != null;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = null;
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AppUser?>((ref) {
  return AuthController(ref.read(authServiceProvider));
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

  void load(String userId) {
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
    StateNotifierProvider<TransactionsController, List<TransactionModel>>((ref) {
  return TransactionsController(ref.read(transactionServiceProvider));
});

final transactionFilterProvider = StateProvider<TransactionFilter>((_) => const TransactionFilter());

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final items = ref.watch(transactionsControllerProvider);
  final filter = ref.watch(transactionFilterProvider);

  return items.where((item) {
    final categoryMatch = filter.category == null || item.category == filter.category;
    final typeMatch = filter.type == null || item.type == filter.type;
    final startMatch = filter.start == null || !item.date.isBefore(filter.start!);
    final endMatch = filter.end == null || !item.date.isAfter(filter.end!);
    final searchMatch = filter.search.isEmpty ||
        item.title.toLowerCase().contains(filter.search.toLowerCase()) ||
        item.note.toLowerCase().contains(filter.search.toLowerCase());
    return categoryMatch && typeMatch && startMatch && endMatch && searchMatch;
  }).toList();
});
