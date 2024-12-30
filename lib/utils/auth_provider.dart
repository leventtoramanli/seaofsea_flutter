// lib/utils/auth_provider.dart
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? _authToken;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  void login(String token) {
    _authToken = token;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _authToken = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  String? get token => _authToken;
}
