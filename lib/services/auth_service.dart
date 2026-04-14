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
    required Country country,
  }) async {
    final userId = DateTime.now().microsecondsSinceEpoch.toString();

    final user = AppUser(
      id: userId,
      name: name.trim(),
      country: country.name,
      currencySymbol: country.currencySymbol,
      sessionToken: _generateSessionToken(),
    );

    await _dbService.usersBox().put(user.id, user.toMap());
    await _secureStorage.write(
        key: _sessionKey, value: jsonEncode(user.toMap()));
    return user;
  }

  Future<AppUser?> getCurrentUser() async {
    final raw = await _secureStorage.read(key: _sessionKey);
    if (raw == null) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;

    if (map.containsKey('email')) {
      await _secureStorage.delete(key: _sessionKey);
      return null;
    }

    return AppUser.fromMap(map);
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _sessionKey);
  }

  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode ^ DateTime.now().microsecond;
    return base64Encode(utf8.encode('$timestamp:$random')).substring(0, 32);
  }
}
