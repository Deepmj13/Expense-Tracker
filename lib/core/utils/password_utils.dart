import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordUtils {
  static const String _saltPrefix = 'expense_tracker_v1_';
  static const int _saltLength = 32;

  static String hash(String password) {
    final salt = _generateSalt();
    final saltedPassword = '$_saltPrefix$salt$password';
    final bytes = utf8.encode(saltedPassword);

    var digest = sha256.convert(bytes);
    for (var i = 0; i < 10000; i++) {
      digest = sha256.convert(utf8.encode(digest.toString()));
    }

    return '$salt:${digest.toString()}';
  }

  static bool verify(String password, String storedHash) {
    if (!storedHash.contains(':')) return false;

    final parts = storedHash.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final originalHash = parts[1];

    final saltedPassword = '$_saltPrefix$salt$password';
    var digest = sha256.convert(utf8.encode(saltedPassword));

    for (var i = 0; i < 10000; i++) {
      digest = sha256.convert(utf8.encode(digest.toString()));
    }

    return digest.toString() == originalHash;
  }

  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes =
        List<int>.generate(_saltLength, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }
}
