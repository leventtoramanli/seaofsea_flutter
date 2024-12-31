// lib/utils/auth_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:seaofsea/utils/role_manager.dart';

class AuthProvider with ChangeNotifier {
  String? _authToken;
  String? _role;

  bool get isLoggedIn => _authToken != null;
  String getRole() => _role ?? RoleManager.anonymous;

  void login(String token) {
    _authToken = token;
    final payload = parseTokenPayload(token);
    _role = payload['role'];
    notifyListeners();
  }

  void logout() {
    _authToken = null;
    _role = null;
    notifyListeners();
  }

  Map<String, dynamic> parseTokenPayload(String token) {
    final parts = token.split('.');
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    return payload;
  }
}
