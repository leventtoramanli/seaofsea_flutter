// lib/services/v1/auth_service.dart
import 'dart:math';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/secure_storage.dart';

class AuthService {
  final V1ApiManager _api = V1ApiManager();
  final SecureStorage _storage = SecureStorage();

  // --- helpers --------------------------------------------------------------

  Future<void> _ensureDeviceUUID() async {
    String? deviceUUID = await _storage.readSecureData('deviceUUID');
    if (deviceUUID == null || deviceUUID.isEmpty) {
      deviceUUID = _generateUUID();
      await _storage.writeSecureData('deviceUUID', deviceUUID);
    }
  }

  String _generateUUID() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(36, (index) {
      if (index == 8 || index == 13 || index == 18 || index == 23) return '-';
      return chars[random.nextInt(chars.length)];
    }).join();
  }

  Future<void> _persistSession({
    String? token,
    String? refreshToken,
    bool? rememberMe,
    bool? isAnonymous,
    Map<String, dynamic>? user,
  }) async {
    if (token != null && token.isNotEmpty) {
      await _storage.writeSecureData('authToken', token);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.writeSecureData('refreshToken', refreshToken);
    }
    if (rememberMe != null) {
      await _storage.writeSecureData('rememberMe', rememberMe.toString());
    }
    if (isAnonymous != null) {
      await _storage.writeSecureData('isAnonymous', isAnonymous.toString());
    }
    if (user != null) {
      await _storage.writeSecureData('userId', user['id']?.toString() ?? '');
      await _storage.writeSecureData('role', (user['role'] ?? '').toString());
    }
  }

  // --- auth flows -----------------------------------------------------------

  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    await _ensureDeviceUUID();
    final deviceParams = await _api.getDeviceParams();

    final response = await _api.call(
      module: 'auth',
      action: 'login',
      params: {
        'email': email,
        'password': password,
        'remember_me': rememberMe,
        ...deviceParams,
      },
      requiresAuth: false,
    );

    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final token = data['token']?.toString();
      final refreshToken = data['refresh_token']?.toString();
      final user = data['user'] as Map<String, dynamic>?;

      // rememberMe’i refresh_token VARSA true yap (aksi hâlde anlamsız)
      final effectiveRemember =
          rememberMe && (refreshToken != null && refreshToken.isNotEmpty);

      await _persistSession(
        token: token,
        refreshToken: refreshToken,
        rememberMe: effectiveRemember,
        isAnonymous: false,
        user: user,
      );

      return {
        'success': true,
        'token': token,
        'user': user,
        'refresh_token': refreshToken,
      };
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Login failed',
    };
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    await _ensureDeviceUUID();
    final deviceParams = await _api.getDeviceParams();

    final response = await _api.call(
      module: 'auth',
      action: 'register',
      params: {
        'name': name,
        'surname': surname,
        'email': email,
        'password': password,
        ...deviceParams,
      },
      requiresAuth: false,
    );
    return response;
  }

  Future<Map<String, dynamic>> anonymousLogin() async {
    await _ensureDeviceUUID();
    final deviceParams = await _api.getDeviceParams();

    final response = await _api.call(
      module: 'auth',
      action: 'anonymous_login',
      params: {
        ...deviceParams,
      },
      requiresAuth: false,
    );

    final data = response['data'];
    if (response['success'] == true && data != null) {
      final token = data['token']?.toString();
      final refreshToken = data['refresh_token']?.toString();
      final user = data['user'] as Map<String, dynamic>?;

      // Anon için remember = false (yeniden kimliklendirme istenmez)
      await _persistSession(
        token: token,
        refreshToken: refreshToken,
        rememberMe: false,
        isAnonymous: true,
        user: user,
      );

      return {
        'success': true,
        'token': token,
        'user': user,
        'refresh_token': refreshToken,
      };
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Anonymous login failed',
    };
  }

  /// Refresh token ile yeni token al
  Future<Map<String, dynamic>?> refreshToken() async {
    await _ensureDeviceUUID();
    final refreshToken = await _storage.readSecureData('refreshToken');
    final deviceUUID = await _storage.readSecureData('deviceUUID');

    if (refreshToken == null || refreshToken.isEmpty || deviceUUID == null) {
      return null;
    }

    final response = await _api.call(
      module: 'auth',
      action: 'refresh_token',
      params: {
        'refresh_token': refreshToken,
        'device_uuid': deviceUUID,
      },
      requiresAuth: false,
    );

    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final newToken = data['token']?.toString();
      final newRefresh = data['refresh_token']?.toString();

      // rememberMe flag’i değiştirmiyoruz; sadece tokenları güncelliyoruz
      await _persistSession(token: newToken, refreshToken: newRefresh);

      return {
        'token': newToken,
        'refresh_token': newRefresh,
      };
    }

    return null;
  }

  /// Kullanıcı bilgilerini getir
  Future<Map<String, dynamic>?> getUserInfo() async {
    final token = await _storage.readSecureData('authToken');
    if (token == null || token.isEmpty) return null;

    final response = await _api.call(
      module: 'auth',
      action: 'get_user_info', // backend’ine uygun
      params: {},
    );

    return response['success'] == true ? response['data'] : null;
  }

  /// Token geçerli mi kontrol et
  Future<bool> validateToken() async {
    final token = await _storage.readSecureData('authToken');
    if (token == null || token.isEmpty) return false;

    final response = await _api.call(
      module: 'auth',
      action: 'validate_token',
      requiresAuth: false,
      params: {'token': token},
    );

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>?;
      return data?['valid'] == true;
    }
    return false;
  }

  /// Backend logout (tek cihaz ya da tüm cihazlar)
  Future<Map<String, dynamic>> logout({
    bool includeDeviceUUID = false,
    bool allDevices = false,
  }) async {
    final refreshToken = await _storage.readSecureData('refreshToken');
    final deviceUUID = await _storage.readSecureData('deviceUUID');

    final params = <String, dynamic>{
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (allDevices) 'all_devices': true,
      if (!allDevices && includeDeviceUUID && deviceUUID != null)
        'device_uuid': deviceUUID,
    };

    final res = await _api.call(
      module: 'auth',
      action: 'logout',
      requiresAuth: false,
      params: params,
    );

    return res;
  }

  Future<void> logoutFromBackend() async {
    await logout(includeDeviceUUID: true, allDevices: false);
  }

  Future<String?> getStoredUserData(String key) async {
    return _storage.readSecureData(key);
  }
}
