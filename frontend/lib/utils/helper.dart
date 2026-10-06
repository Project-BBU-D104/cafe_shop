import 'package:encrypt/encrypt.dart' as encrypt;

class Helper {
  // AES-256 => 32 characters
  final key = encrypt.Key.fromUtf8(
    '12345678901234567890123456789012',
  );

  // AES CBC => 16 characters
  final iv = encrypt.IV.fromUtf8(
    '1234567890123456',
  );

  /// AES Decrypt method
  String onDecrypted(String encrypted) {
    try {
      if (encrypted.trim().isEmpty) {
        return "";
      }

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      return encrypter.decrypt64(encrypted, iv: iv);
    } catch (e) {
      return "";
    }
  }

  /// AES Encrypt method
  String onEncrypted(String plainText) {
    try {
      if (plainText.trim().isEmpty) {
        return "";
      }

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      final encrypted = encrypter.encrypt(
        plainText,
        iv: iv,
      );

      return encrypted.base64;
    } catch (e) {
      return "";
    }
  }
}