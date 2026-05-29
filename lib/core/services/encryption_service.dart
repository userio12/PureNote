import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  static enc.IV _generateIV() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    return enc.IV(Uint8List.fromList(bytes));
  }

  static String encrypt(String plaintext, String password) {
    final salt = List.generate(32, (_) => Random.secure().nextInt(256));
    final key = enc.Key.fromUtf8(password.padRight(32, '\x00').substring(0, 32));
    final iv = _generateIV();
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    final result = {
      'salt': base64Encode(salt),
      'iv': iv.base64,
      'data': encrypted.base64,
    };

    return base64Encode(utf8.encode(jsonEncode(result)));
  }

  static String decrypt(String ciphertext, String password) {
    try {
      final payload = jsonDecode(utf8.decode(base64Decode(ciphertext))) as Map<String, dynamic>;
      final iv = enc.IV.fromBase64(payload['iv'] as String);
      final key = enc.Key.fromUtf8(password.padRight(32, '\x00').substring(0, 32));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(payload['data'] as String, iv: iv);
    } catch (_) {
      throw Exception('Decryption failed');
    }
  }
}
