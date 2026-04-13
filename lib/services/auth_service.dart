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
  static const _passwordPrefix = 'pwd_hash_';

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
    final userId = DateTime.now().microsecondsSinceEpoch.toString();

    await _secureStorage.write(
      key: '$_passwordPrefix$userId',
      value: hashedPassword,
    );

    final user = AppUser(
      id: userId,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      country: country.name,
      currencySymbol: country.currencySymbol,
      sessionToken: _generateSessionToken(),
    );

    await users.put(user.id, user.toMap());
    await _secureStorage.write(
        key: _sessionKey, value: jsonEncode(user.toMap()));
    return user;
  }

  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    final users = _dbService.usersBox();

    for (final userData in users.values) {
      if (userData['email'] == email.trim().toLowerCase()) {
        final userId = userData['id'] as String;
        final storedHash = await _secureStorage.read(
          key: '$_passwordPrefix$userId',
        );

        if (storedHash == null) return null;

        if (PasswordUtils.verify(password, storedHash)) {
          final user = AppUser.fromMap(userData).copyWith(
            sessionToken: _generateSessionToken(),
          );
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

  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode ^ DateTime.now().microsecond;
    return base64Encode(utf8.encode('$timestamp:$random')).substring(0, 32);
  }
}
