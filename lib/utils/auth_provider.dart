// lib/utils/auth_provider.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/auth_service.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/permission_provider.dart';
import 'package:seaofsea/utils/role_provider.dart';
import 'package:seaofsea/utils/secure_storage.dart';

class AuthProvider with ChangeNotifier {
  // Singleton
  static final AuthProvider _singleton = AuthProvider._internal();
  factory AuthProvider() => _singleton;
  AuthProvider._internal();
  static AuthProvider get instance => _singleton;

  // State
  String? _authToken;
  Map<String, dynamic>? _userInfo;
  bool _isLoadingData = false;

  // Expose
  String? get token => _authToken;
  bool get isLoggedIn => _authToken != null && _authToken!.isNotEmpty;
  Map<String, dynamic>? get userInfo => _userInfo;
  bool get isLoading => _isLoadingData;

  // Role adı (hem role_id hem role alanlarını destekle)
  String getRole(BuildContext context) {
    final roleProvider = RoleProvider.of(context, listen: false);
    final raw = _userInfo?['role_id'] ?? _userInfo?['role'] ?? 3;
    final int roleId = int.tryParse(raw.toString()) ?? 3;
    return roleProvider.getRoleNameById(roleId);
  }

  // ======== DEVICE UUID: TEK NOKTA ========
  static const _deviceUUIDKey = 'deviceUUID';

  Future<String> getOrCreateDeviceUUID() async {
    final storage = SecureStorage();
    String? id = await storage.readSecureData(_deviceUUIDKey);
    if (id != null && id.isNotEmpty) return id;
    final newId = _generateDeviceUUIDHex();
    await storage.writeSecureData(_deviceUUIDKey, newId);
    return newId;
  }

  static String _generateDeviceUUIDHex() {
    const chars = '0123456789abcdef';
    final r = Random.secure();
    String rand(int len) =>
        String.fromCharCodes(List.generate(len, (_) => chars.codeUnitAt(r.nextInt(chars.length))));
    final timeLow = rand(8);
    final timeMid = rand(4);
    final timeHiAndVersion = '4' + rand(3); // v4
    final clkSeqHiAndReserved = (8 + r.nextInt(4)).toRadixString(16) + rand(3); // variant 10xx
    final node = rand(12);
    return '$timeLow-$timeMid-$timeHiAndVersion-$clkSeqHiAndReserved-$node';
  }

  // Opsiyonel: cihaz adı/platform
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

  static Future<String> getPlatformName() async => Platform.operatingSystem;

  // ======== LOGIN ========
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
        // Token & rememberMe & refreshToken storage'a AuthService.login içinde yazıldı.
        _authToken = (result['token'] ?? '').toString();
        _userInfo = (result['user'] as Map<String, dynamic>?) ?? {};
        await _persistUserInfo(_userInfo);

        // İzinleri çek
        try {
          await PermissionProvider.maybeOf(context)?.fetchUserPermissions();
        } catch (_) {}

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

  // ======== REGISTER ========
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
        final data = (result['data'] as Map<String, dynamic>?) ?? {};
        _authToken = data['token']?.toString();
        _userInfo = (data['user'] as Map<String, dynamic>?) ?? {};
        await _persistUserInfo(_userInfo);
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

  // ======== AUTO LOGIN ========
  Future<bool> tryAutoLogin(BuildContext context) async {
    final storage = SecureStorage();
    final token = await storage.readSecureData('authToken');
    final rememberMe = (await storage.readSecureData('rememberMe')) == 'true';
    final refreshTok = await storage.readSecureData('refreshToken');

    if (token == null || token.isEmpty) {
      debugPrint("❌ No token in storage → auto login skipped.");
      return false;
    }

    // Eğer remember=true ama refresh_token yoksa, bu bir tutarsızlık demektir.
    // Sonsuz refresh denemelerini engellemek için bayrağı düzeltelim.
    if (rememberMe && (refreshTok == null || refreshTok.isEmpty)) {
      debugPrint('⚠️ rememberMe=true ancak refresh_token yok. Bayrak sıfırlanıyor.');
      await storage.writeSecureData('rememberMe', 'false');
    }

    String workingToken = token;

    // Süresi dolmuş/bitmek üzere ise sessiz refresh dene
    if (_isJwtExpired(workingToken) || _isJwtExpiringSoon(workingToken)) {
      final remembered = (await storage.readSecureData('rememberMe')) == 'true';
      if (!remembered) {
        debugPrint("⏳ Token expired & not remembered → soft logout.");
        await v1logout(clearRemember: false); // soft
        return false;
      }

      try {
        final refreshed = await AuthService().refreshToken();
        if (refreshed == null || refreshed['token'] == null) {
          debugPrint("❌ Refresh failed.");
          await v1logout(clearRemember: false); // soft
          return false;
        }
        workingToken = refreshed['token'] as String;
        _authToken = workingToken; // storage yazımı refreshToken içinde zaten yapıldı
      } catch (e) {
        debugPrint("❌ Refresh exception: $e");
        await v1logout(clearRemember: false); // soft
        return false;
      }
    } else {
      _authToken = workingToken;
    }

    // Her durumda kullanıcı profilini backend'den çek → güncel veri
    try {
      await refreshUserInfo(context);
    } catch (e) {
      debugPrint("⚠️ refreshUserInfo failed: $e");
      // profil çekilemese bile token elimizde → true dönebiliriz
    }

    // İzinleri sessizce güncelle (varsa)
    try {
      final perm = PermissionProvider.maybeOf(context, listen: false);
      await perm?.fetchUserPermissions();
    } catch (_) {}

    notifyListeners();
    debugPrint("✅ Auto login ready.");
    return true;
  }

  // ======== ANON LOGIN ========
  Future<bool> v1anonymousLogin(BuildContext context) async {
    try {
      _isLoadingData = true;
      notifyListeners();

      final authService = AuthService();
      final result = await authService.anonymousLogin();

      _isLoadingData = false;

      if (result['success'] == true) {
        _authToken = result['token']?.toString();
        _userInfo = (result['user'] as Map<String, dynamic>?) ?? {};
        await _persistUserInfo(_userInfo);
        notifyListeners();
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Anonymous login failed')),
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

  // Storage’tan sadece tokenı yüklemek istersen
  Future<void> loadFromStorage() async {
    final storage = SecureStorage();
    final storedToken = await storage.readSecureData('authToken');
    if (storedToken != null && storedToken.isNotEmpty) {
      _authToken = storedToken;
      notifyListeners();
    }
  }

  // ======== LOGOUT ========
  /// clearRemember:
  ///  - false → soft logout (otomatik zaman aşımı gibi durumlar). rememberMe bayrağını KORUR.
  ///  - true  → hard logout (kullanıcı menüden çıkış). rememberMe dahil her şeyi temizler.
  Future<void> v1logout({bool allDevices = false, bool clearRemember = false}) async {
    final authService = AuthService();
    await authService.logout(includeDeviceUUID: !allDevices, allDevices: allDevices);

    final s = SecureStorage();
    await s.deleteSecureData('authToken');
    await s.deleteSecureData('refreshToken');
    await s.deleteSecureData('role');
    await s.deleteSecureData('userId');
    if (clearRemember) {
      await s.deleteSecureData('rememberMe');
      await s.deleteSecureData('isAnonymous');
    }
    // deviceUUID'yi genelde tutarız.

    _authToken = null;
    _userInfo = null;
    notifyListeners();
  }

  // ======== TOKEN DOĞRULAMA / YENİLEME ========
  Future<bool> v1validateToken() async {
    try {
      final authService = AuthService();
      return await authService.validateToken();
    } catch (e) {
      debugPrint('❌ validateToken error: $e');
      return false;
    }
  }

  Future<bool> attemptTokenRefresh() async {
    try {
      final authService = AuthService();
      final refreshed = await authService.refreshToken();
      if (refreshed != null && refreshed['token'] != null && refreshed['refresh_token'] != null) {
        _authToken = refreshed['token']?.toString();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ attemptTokenRefresh error: $e');
      return false;
    }
  }

  // ======== USER INFO ========
  Map<String, dynamic>? _decodeToken(String token) {
    try {
      if (token.isEmpty) return null;
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final Map<String, dynamic> data = jsonDecode(payload);
      return data['user'] ?? data;
    } catch (e) {
      debugPrint('Error decoding token: $e');
      return null;
    }
  }

  Future<void> refreshUserInfo(BuildContext context) async {
    final v1 = Provider.of<V1ApiManager>(context, listen: false);

    // 'profile/getProfile' (id vermeden = kendi profili)
    final resp = await v1.call(
      module: 'profile',
      action: 'getProfile',
      params: {},
      requiresAuth: true,
      context: context,
    );

    if (resp['success'] == true && resp['data'] != null) {
      _userInfo = Map<String, dynamic>.from(resp['data'] as Map);
      await _persistUserInfo(_userInfo);
    } else {
      throw Exception(resp['message'] ?? 'Failed to fetch profile');
    }
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final exp = (jsonDecode(payload)['exp'] as int?);
      if (exp == null) return true;
      return DateTime.now().isAfter(DateTime.fromMillisecondsSinceEpoch(exp * 1000));
    } catch (_) {
      return true;
    }
  }

  bool _isJwtExpiringSoon(String token, {int bufferSeconds = 90}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final exp = (jsonDecode(payload)['exp'] as int?) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return (exp - now) <= bufferSeconds;
    } catch (_) {
      return true;
    }
  }

  // ======== NULL-SAFE storage persist helper ========
  Future<void> _persistUserInfo(Map<String, dynamic>? user) async {
    final s = SecureStorage();

    Future<void> w(String key, dynamic v) async {
      if (v == null) return;
      await s.writeSecureData(key, v.toString());
    }

    await w('userId', user?['id']);
    await w('email', user?['email']);
    await w('name', user?['name']);
    await w('surname', user?['surname']);
    await w('coverImage', user?['cover_image']);
    await w('user_image', user?['user_image']);
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
