import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class SecureStorage {
  static const String _key = '0123456789abcdef'; // 16 byte (AES-128)
  static const String _iv = 'abcdef9876543210'; // 16 byte (AES-128)

  //final encrypt.Key _encryptionKey = encrypt.Key.fromUtf8(_key);
  final encrypt.IV _encryptionIV = encrypt.IV.fromUtf8(_iv);
  final encrypt.Encrypter _encrypter;

  SecureStorage()
      : _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(_key)));

  Future<void> writeSecureData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final encryptedValue =
          _encrypter.encrypt(value, iv: _encryptionIV).base64;
      await prefs.setString(key, encryptedValue);
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  Future<String?> readSecureData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedValue = prefs.getString(key);
    if (encryptedValue == null) return null;

    try {
      final decryptedValue = _encrypter.decrypt(
          encrypt.Encrypted.fromBase64(encryptedValue),
          iv: _encryptionIV);
      return decryptedValue;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteSecureData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_info';

  Future<void> saveAuthData(String token, Map<String, dynamic> user) async {
    await writeSecureData(tokenKey, token);
    await writeSecureData(
        userKey, user.toString()); // istersen jsonEncode(user) yap
  }

  Future<String?> getToken() async {
    return await readSecureData(tokenKey);
  }

  Future<String?> getUserInfoRaw() async {
    return await readSecureData(userKey);
  }

  Future<void> clearAll() async {
    await deleteSecureData(tokenKey);
    await deleteSecureData(userKey);
  }
}
