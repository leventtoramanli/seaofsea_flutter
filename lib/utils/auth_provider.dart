import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:seaofsea/utils/role_manager.dart';
import 'package:seaofsea/utils/secure_storage.dart';

class AuthProvider with ChangeNotifier {
  String? _authToken;
  String? _role;
  Map<String, dynamic>? _userInfo;

  String? get token => _authToken;
  bool get isLoggedIn => _authToken != null;
  String getRole() => _role ?? RoleManager.anonymous;
  Map<String, dynamic>? get userInfo => _userInfo;

  AuthProvider() {
    _loadUserFromPreferences();
  }

  Future<void> login(String token, String role) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token format.');
      }

      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    } catch (e) {
      debugPrint('Error decoding token: $e');
      throw Exception('Failed to decode token.');
    }
    _authToken = token;
    _role = role;
    _userInfo = _decodeToken(token);
    notifyListeners();

    // Token güvenli kaydetme
    final storage = SecureStorage();
    await storage.writeSecureData('authToken', token);
    await storage.writeSecureData('role', role);
  }

  Future<void> logout() async {
    _authToken = null;
    _role = null;
    _userInfo = null;
    notifyListeners();

    // Token temizleme
    final storage = SecureStorage();
    await storage.deleteSecureData('authToken');
    await storage.deleteSecureData('role');
  }

  Future<void> _loadUserFromPreferences() async {
  final storage = SecureStorage();
  _authToken = await storage.readSecureData('authToken');
  _role = await storage.readSecureData('role');
  if (_authToken != null) {
    _userInfo = _decodeToken(_authToken!); // Token'dan kullanıcı bilgilerini ayrıştır
  } else {
    _userInfo = null; // Token yoksa kullanıcı bilgilerini temizle
  }
  notifyListeners(); // Widgetları bilgilendir
}


  Map<String, dynamic>? _decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token format.');
      }
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return jsonDecode(payload)['data'];
    } catch (e) {
      debugPrint('Error decoding token: $e');
      return null;
    }
  }
}
