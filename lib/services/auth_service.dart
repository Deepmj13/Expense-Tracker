import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_user.dart';
import 'database_service.dart';

class AuthService {
  AuthService(this._dbService);

  final DatabaseService _dbService;
  final _secureStorage = const FlutterSecureStorage();
  static const _sessionKey = 'current_user';

  Future<AppUser?> signup({
    required String name,
    required String email,
    required String password,
    required Country country,
  }) async {
    final users = _dbService.usersBox();
    final exists =
        users.values.any((u) => u['email'] == email.trim().toLowerCase());
    if (exists) return null;

    final user = AppUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password: password,
      country: country.name,
      currencySymbol: country.currencySymbol,
    );

    await users.put(user.id, user.toMap());
    await _secureStorage.write(
        key: _sessionKey, value: jsonEncode(user.toMap()));
    return user;
  }

  Future<AppUser?> login(
      {required String email, required String password}) async {
    final users = _dbService.usersBox();
    final match = users.values.where((u) {
      return u['email'] == email.trim().toLowerCase() &&
          u['password'] == password;
    });

    if (match.isEmpty) return null;
    final user = AppUser.fromMap(match.first);
    await _secureStorage.write(
        key: _sessionKey, value: jsonEncode(user.toMap()));
    return user;
  }

  Future<AppUser?> getCurrentUser() async {
    final raw = await _secureStorage.read(key: _sessionKey);
    if (raw == null) return null;
    return AppUser.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> logout() => _secureStorage.delete(key: _sessionKey);
}
