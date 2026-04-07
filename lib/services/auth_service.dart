import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/utils/password_utils.dart';
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

    final hashedPassword = PasswordUtils.hash(password);

    final user = AppUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password: hashedPassword,
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

    for (final userData in users.values) {
      if (userData['email'] == email.trim().toLowerCase()) {
        final storedHash = userData['password'] as String;
        if (PasswordUtils.verify(password, storedHash)) {
          final user = AppUser.fromMap(userData);
          await _secureStorage.write(
              key: _sessionKey, value: jsonEncode(user.toMap()));
          return user;
        }
        return null;
      }
    }
    return null;
  }

  Future<AppUser?> getCurrentUser() async {
    final raw = await _secureStorage.read(key: _sessionKey);
    if (raw == null) return null;
    return AppUser.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> logout() => _secureStorage.delete(key: _sessionKey);
}
