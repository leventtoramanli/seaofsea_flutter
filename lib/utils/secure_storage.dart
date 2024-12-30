import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class SecureStorage {
  static const String _key = '75Vf99JZ8Zh3YPc1R0PfANoy1r04AV7GWoFrL7VJn+Q='; // AES için 16 byte anahtar 16byteslongkey!
  static const String _iv = '4jzx4LducWl9ppr7Bvgrii4/RU6bUlq1wYWDTNHSJ3w='; // AES için 16 byte IV 16byteslongiv!!!

  // ignore: unused_field
  final encrypt.Key _encryptionKey = encrypt.Key.fromUtf8(_key);
  final encrypt.IV _encryptionIV = encrypt.IV.fromUtf8(_iv);
  final encrypt.Encrypter _encrypter;

  SecureStorage() : _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(_key)));

  Future<void> writeSecureData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedValue = _encrypter.encrypt(value, iv: _encryptionIV).base64;
    await prefs.setString(key, encryptedValue);
  }

  Future<String?> readSecureData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedValue = prefs.getString(key);
    if (encryptedValue == null) return null;

    try {
      final decryptedValue =
          _encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedValue), iv: _encryptionIV);
      return decryptedValue;
    } catch (e) {
      print('Decryption error: $e');
      return null;
    }
  }

  Future<void> deleteSecureData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
