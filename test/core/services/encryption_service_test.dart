import 'package:flutter_test/flutter_test.dart';
import 'package:purenote/core/services/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    const password = 'test-password-123';

    test('encrypt and decrypt roundtrip', () {
      const original = 'Hello, PureNote! This is a test message.';
      final encrypted = EncryptionService.encrypt(original, password);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(original)));

      final decrypted = EncryptionService.decrypt(encrypted, password);
      expect(decrypted, original);
    });

    test('different passwords produce different ciphertexts', () {
      final a = EncryptionService.encrypt('Message', 'password-a');
      final b = EncryptionService.encrypt('Message', 'password-b');
      expect(a, isNot(equals(b)));
    });

    test('wrong password fails decryption', () {
      final encrypted = EncryptionService.encrypt('Secret message', password);
      expect(
        () => EncryptionService.decrypt(encrypted, 'wrong-password'),
        throwsA(isA<Exception>()),
      );
    });

    test('long text roundtrip', () {
      final original = 'A' * 10000;
      final encrypted = EncryptionService.encrypt(original, password);
      final decrypted = EncryptionService.decrypt(encrypted, password);
      expect(decrypted, original);
    });

    test('unicode text roundtrip', () {
      const original = '日本語 español 中文 русский العربية';
      final encrypted = EncryptionService.encrypt(original, password);
      final decrypted = EncryptionService.decrypt(encrypted, password);
      expect(decrypted, original);
    });
  });
}
