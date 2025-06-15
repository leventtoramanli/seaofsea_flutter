// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/auth_service.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/role_provider.dart';
import 'package:seaofsea/utils/secure_storage.dart';

class AuthProvider with ChangeNotifier {
  String? _authToken;
  // ignore: unused_field
  String? _role;
  Map<String, dynamic>? _userInfo;
  // ignore: unused_field
  bool _isLoadingData = false;

  String? get token => _authToken;
  bool get isLoggedIn => _authToken != null;
  //bool get isLoadingData => _isLoadinData;
  Map<String, dynamic>? get userInfo => _userInfo;

  AuthProvider() {
    //_loadUserFromPreferences(); // LoadFromStorage() olarak değiştir.
    _loadUserFromStorage();
  }

  String getRole(BuildContext context) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    final int roleId =
        int.tryParse(_userInfo?['role_id']?.toString() ?? '3') ?? 3;
    return roleProvider.getRoleNameById(roleId);
  }

  Future<String> v1saveDeviceUUID() async {
    final storage = SecureStorage();
    String? deviceUUID = await storage.readSecureData('deviceUUID');

    if (deviceUUID == null || deviceUUID.isEmpty) {
      deviceUUID = _generateUUID();
      await storage.writeSecureData('deviceUUID', deviceUUID);
    }
    return deviceUUID;
  }

  String _generateUUID() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(36, (index) {
      if ([8, 13, 18, 23].contains(index)) return '-';
      return chars[random.nextInt(chars.length)];
    }).join();
  }

  static String generateUUID() {
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

  static Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return '${info.manufacturer} ${info.model}';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return '${info.name} ${info.systemVersion}';
    } else {
      return 'Unknown Device';
    }
  }

  // Platform (android, ios, windows, macos, web)
  static Future<String> getPlatformName() async {
    return Platform.operatingSystem; // 'android', 'ios', 'windows' vs.
  }

  Future<bool> v1login(
    BuildContext context,
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      _isLoadingData = true;
      notifyListeners();

      final authService = AuthService();
      final result = await authService.login(
        email,
        password,
        rememberMe: rememberMe,
      );

      _isLoadingData = false;

      if (result['success'] == true) {
        _authToken = result['token'];
        _userInfo = result['user'];
        notifyListeners();
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Login failed.')),
          );
        }
        return false;
      }
    } catch (e) {
      _isLoadingData = false;
      notifyListeners();

      debugPrint('❌ AuthProvider.v1login() error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: $e')),
        );
      }
      return false;
    }
  }

  Future<bool> v1Register({
    required BuildContext context,
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    try {
      _isLoadingData = true;
      notifyListeners();

      final authService = AuthService();
      final result = await authService.register(
        name: name,
        surname: surname,
        email: email,
        password: password,
      );

      _isLoadingData = false;

      if (result['success'] == true) {
        _authToken = result['token'];
        _userInfo = result['user'];
        notifyListeners();
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Registration failed')),
          );
        }
        return false;
      }
    } catch (e) {
      _isLoadingData = false;
      notifyListeners();
      debugPrint('❌ AuthProvider.v1Register error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: $e')),
        );
      }
      return false;
    }
  }

  Future<bool> tryAutoLogin(BuildContext context) async {
    final storage = SecureStorage();
    final token = await storage.readSecureData('authToken');
    final isAnonymous =
        await storage.readSecureData('isAnonymous'); // eklenen satır

    if (token != null && token.isNotEmpty) {
      final isValid = await v1validateToken(context);

      if (isValid) {
        _authToken = token;
        _userInfo = _decodeToken(token);
        notifyListeners();

        if (isAnonymous == 'true') {
          debugPrint('🔐 Anonymous auto login success');
        } else {
          debugPrint('🔐 Regular auto login success');
        }

        return true;
      }
    }

    return false;
  }

  Future<bool> v1anonymousLogin(BuildContext context) async {
    try {
      _isLoadingData = true;
      notifyListeners();

      final authService = AuthService();
      final result = await authService.anonymousLogin();

      _isLoadingData = false;

      if (result['success'] == true) {
        _authToken = result['token'];
        _userInfo = result['user'];
        notifyListeners();
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Anonymous login failed'),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      _isLoadingData = false;
      notifyListeners();

      debugPrint('❌ AuthProvider.v1anonymousLogin() error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _loadUserFromStorage() async {
    final storage = SecureStorage();
    final storedToken = await storage.readSecureData('authToken');

    if (storedToken != null) {
      _authToken = storedToken;
      // opsiyonel: userInfo fetch edilebilir
    }

    notifyListeners();
  }

  Future<void> v1logout({bool allDevices = false}) async {
    final authService = AuthService();
    await authService.logout(
        includeDeviceUUID: allDevices, allDevices: allDevices);
    _authToken = null;
    _userInfo = null;
    notifyListeners();
  }

  Future<void> validateToken(BuildContext context) async {
    final storage = SecureStorage();
    final refreshToken = await storage.readSecureData('refreshToken');
    if (refreshToken == null) {
      await v1logout();
      return;
    }
    try {
      final apiManager = Provider.of<V1ApiManager>(context, listen: false);
      final isValid = await apiManager.call(
        module: 'auth',
        action: 'validate_token',
        params: {'token': token}, // veya refresh_token değil token
      );

      if (!isValid['success']) {
        await v1logout();
      } else {
        debugPrint('Token is valid.');
      }
    } catch (e) {
      debugPrint('Error during token validation: $e');
      if (context.mounted) {
        if (ScaffoldMessenger.maybeOf(context) != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token validation failed')),
          );
        }
        await v1logout(); // Herhangi bir hata durumunda logout yap
      }
    }
  }

  Future<bool> v1validateToken(BuildContext context) async {
    final storage = SecureStorage();
    final refreshToken = await storage.readSecureData('refreshToken');

    if (refreshToken == null) return false;
    try {
      final apiManager = Provider.of<V1ApiManager>(context, listen: false);
      final response = await apiManager.call(
        module: 'auth',
        action: 'validate',
        params: {'refresh_token': refreshToken},
      );

      return response['success'] == true;
    } catch (e) {
      debugPrint('❌ validateToken error: $e');
      return false;
    }
  }

  Map<String, dynamic>? _decodeToken(String token) {
    try {
      final payload = utf8
          .decode(base64Url.decode(base64Url.normalize(token.split('.')[1])));
      final Map<String, dynamic> data = jsonDecode(payload);
      debugPrint("✅ Token decode edildi: $data");
      // Burada doğrudan 'data' değil 'user' olabilir.
      return data['user'] ?? data;
    } catch (e) {
      debugPrint('Error decoding token: $e');
      return null;
    }
  }

  Future<void> refreshUserInfo(BuildContext context) async {
    final apiManager = Provider.of<V1ApiManager>(context, listen: false);
    try {
      final response = await apiManager.call(
        module: 'auth',
        action: 'get_user_info',
        params: {},
      );
      if (response['success'] == true) {
        _userInfo = response['data'];
        final secureStorage = SecureStorage();
        await secureStorage.writeSecureData('userId', _userInfo?['id']);
        await secureStorage.writeSecureData('email', _userInfo?['email']);
        await secureStorage.writeSecureData('name', _userInfo?['name']);
        await secureStorage.writeSecureData('surname', _userInfo?['surname']);
        await secureStorage.writeSecureData(
            'coverImage', _userInfo?['cover_image']);
        await secureStorage.writeSecureData(
            'user_image', _userInfo?['user_image']);
        notifyListeners();

        debugPrint('✅ User info refreshed successfully: $_userInfo');
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      debugPrint('⚠️ Error refreshing user info: $e');
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
