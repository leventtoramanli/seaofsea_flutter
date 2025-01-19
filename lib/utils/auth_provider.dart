import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/role_provider.dart';
import 'package:seaofsea/utils/secure_storage.dart';

class AuthProvider with ChangeNotifier {
  String? _authToken;
  String? _role;
  Map<String, dynamic>? _userInfo;
  final bool _isLoadinData = false;

  String? get token => _authToken;
  bool get isLoggedIn => _authToken != null;
  bool get isLoadingData => _isLoadinData;
  Map<String, dynamic>? get userInfo => _userInfo;

  AuthProvider() {
    _loadUserFromPreferences();
  }
  String getRole(BuildContext context) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);

    // Rol geçerli mi kontrol et
    if (_role != null && int.tryParse(_role!) != null) {
      final int roleId = int.parse(_role!);
      return roleProvider.getRoleNameById(roleId);
    }

    // Varsayılan olarak "Guest" döndür
    return roleProvider.getRoleNameById(3); // ID'si 3 olan "Guest" rolü
  }

  String generateUUID() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(36, (index) {
      if (index == 8 || index == 13 || index == 18 || index == 23) {
        return '-'; // UUID formatına uygun tireler
      }
      return chars[random.nextInt(chars.length)];
    }).join();
  }

  Future<String> saveDeviceUUID() async {
    final storage = SecureStorage();
    String? deviceUUID = await storage.readSecureData('deviceUUID');

    if (deviceUUID == null || deviceUUID.isEmpty) {
      deviceUUID = generateUUID();
      await storage.writeSecureData('deviceUUID', deviceUUID);
    }
    return deviceUUID;
  }

  Future<void> login(String token, String role) async {
    _authToken = token;
    _role = role;
    _userInfo = _decodeToken(token);
    notifyListeners();
    final storage = SecureStorage();
    await storage.writeSecureData('userId', _userInfo!['id'].toString());
    await storage.writeSecureData('authToken', token);
    await storage.writeSecureData('role', role);
    if (_userInfo != null && _userInfo!['refresh_token'] != null) {
      await storage.writeSecureData(
          'refreshToken', _userInfo!['refresh_token']);
    }
  }

  Future<void> logout(BuildContext context, {bool allDevices = false}) async {
    try {
      final storage = SecureStorage();
      final refreshToken = await storage.readSecureData('refreshToken');
      final deviceUUID = await storage.readSecureData('deviceUUID');

      if (refreshToken != null && deviceUUID != null) {
        // ignore: use_build_context_synchronously
        final apiManager = Provider.of<ApiManager>(context, listen: false);
        await apiManager
            // ignore: use_build_context_synchronously
            .request(context, endpoint: 'logout', method: 'POST', body: {
          'refresh_token': refreshToken,
          'device_uuid': deviceUUID,
          'all_devices': allDevices
        });
      } else {
        debugPrint('No refreshToken or deviceUUID found');
      }

      await storage.deleteSecureData('authToken');
      await storage.deleteSecureData('refreshToken');
      await storage.deleteSecureData('role');

      _authToken = null;
      _role = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  Future<void> validateToken(BuildContext context) async {
    final storage = SecureStorage();
    final refreshToken = await storage.readSecureData('refreshToken');
    try {
      if (refreshToken == null) {
        // ignore: use_build_context_synchronously
        await logout(context);
        return;
      }

      // ignore: use_build_context_synchronously
      final apiManager = Provider.of<ApiManager>(context, listen: false);
      // ignore: use_build_context_synchronously
      final isValid = await apiManager.request(context,
          endpoint: 'check_token',
          method: 'POST',
          body: {'refresh_token': refreshToken});

      if (!isValid['success']) {
        // ignore: use_build_context_synchronously
        await logout(context);
      } else {
        debugPrint('Token is valid.');
      }
    } catch (e) {
      debugPrint('Error during token validation: $e');
      // ignore: use_build_context_synchronously
      if (ScaffoldMessenger.maybeOf(context) != null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token validation failed')),
        );
      } else {
        debugPrint('Scaffold is not available');
      }

      // ignore: use_build_context_synchronously
      await logout(context); // Herhangi bir hata durumunda logout yap
    }
  }

  Future<void> _loadUserFromPreferences() async {
    final storage = SecureStorage();
    _authToken = await storage.readSecureData('authToken');
    _role = await storage.readSecureData('role');
    await saveDeviceUUID();

    if (_authToken != null) {
      _userInfo = _decodeToken(_authToken!);
    } else {
      _userInfo = null;
    }

    // Notify listeners after loading user data
    notifyListeners();
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

class LoadingProvider with ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
