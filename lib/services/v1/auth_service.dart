// lib/services/v1/auth_service.dart
import 'dart:math';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/secure_storage.dart';

class AuthService {
  final _api = V1ApiManager();
  final _storage = SecureStorage();

  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    final response = await _api.call(
      module: 'auth',
      action: 'login',
      params: {
        'email': email,
        'password': password,
        'remember_me': rememberMe,
      },
      requiresAuth: false,
    );

    if (response['success'] == true && response['data'] != null) {
      final token = response['data']['token'];
      final user = response['data']['user'];
      final role = user?['role']?.toString() ?? 'viewer';

      await _storage.writeSecureData('authToken', token);
      await _storage.writeSecureData('userId', user?['id']?.toString() ?? '');
      await _storage.writeSecureData('role', role);

      if (response['data']['refresh_token'] != null) {
        await _storage.writeSecureData(
            'refreshToken', response['data']['refresh_token']);
      }

      return {
        'success': true,
        'token': token,
        'role': role,
        'user': user,
        'refresh_token': response['data']['refresh_token'],
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
    final response = await _api.call(
      module: 'auth',
      action: 'register',
      params: {
        'name': name,
        'surname': surname,
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );
    return response;
  }

  Future<Map<String, dynamic>> anonymousLogin() async {
    final response = await _api.call(
      module: 'auth',
      action: 'anonymous_login',
      params: {}, // cihaz bilgisi V1ApiManager içinde otomatik
      requiresAuth: false,
    );

    final data = response['data'];
    if (response['success'] == true && data != null) {
      final token = data['token'];
      final user = data['user'];

      if (token != null && user != null) {
        await _storage.writeSecureData('authToken', token.toString());
        await _storage.writeSecureData('userId', user['id'].toString());
        await _storage.writeSecureData('role', user['role_id'].toString());

        return {
          'success': true,
          'token': token,
          'user': user,
          'refresh_token': data['refresh_token'],
        };
      }
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Anonymous login failed',
    };
  }

  /// Refresh token ile yeni token al
  Future<Map<String, dynamic>?> refreshToken() async {
    final refreshToken = await _storage.readSecureData('refreshToken');
    if (refreshToken == null) return null;

    final response = await _api.call(
      module: 'auth',
      action: 'refresh_token',
      params: {
        'refresh_token': refreshToken,
      },
      requiresAuth: false,
    );

    if (response['success'] == true && response['data'] != null) {
      await _storage.writeSecureData('authToken', response['data']['token']);
      await _storage.writeSecureData(
          'refreshToken', response['data']['refresh_token']);
      return {
        'token': response['data']['token'],
        'refresh_token': response['data']['refresh_token'],
      };
    }

    return null;
  }

  /// Kullanıcı bilgilerini getir (token ile)
  Future<Map<String, dynamic>?> getUserInfo() async {
    final token = await _storage.readSecureData('authToken');
    if (token == null) return null;

    final response = await _api.call(
      module: 'auth',
      action: 'me',
      params: {'token': token},
    );

    return response['success'] == true ? response['data'] : null;
  }

  /// Token geçerli mi kontrol et
  Future<bool> validateToken() async {
    final token = await _storage.readSecureData('authToken');
    if (token == null) return false;

    final response = await _api.call(
      module: 'auth',
      action: 'validate_token',
      params: {'token': token},
    );

    return response['valid'] == true;
  }

  /// UUID oluştur veya storage’tan getir
  Future<String> _getOrGenerateUUID() async {
    String? deviceUUID = await _storage.readSecureData('deviceUUID');
    if (deviceUUID == null || deviceUUID.isEmpty) {
      deviceUUID = _generateUUID();
      await _storage.writeSecureData('deviceUUID', deviceUUID);
    }
    return deviceUUID;
  }

  Future<String> getOrCreateUUID() async {
    return await _getOrGenerateUUID();
  }

  String _generateUUID() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(36, (index) {
      if ([8, 13, 18, 23].contains(index)) return '-';
      return chars[random.nextInt(chars.length)];
    }).join();
  }

  Future<void> logoutFromBackend() async {
    final refreshToken = await _storage.readSecureData('refreshToken');
    final deviceUUID = await _storage.readSecureData('deviceUUID');

    if (refreshToken != null && deviceUUID != null) {
      await _api.call(
        module: 'auth',
        action: 'logout',
        requiresAuth: false,
        params: {
          'refresh_token': refreshToken,
          'device_uuid': deviceUUID,
        },
      );
    }
  }

  /// Oturum verilerini temizle
  Future<void> logout(
      {bool includeDeviceUUID = false, bool allDevices = false}) async {
    final refreshToken = await _storage.readSecureData('refreshToken');
    final deviceUUID = await _storage.readSecureData('deviceUUID');

    // Uzak logout çağrısı
    if (refreshToken != null && deviceUUID != null) {
      await _api.call(
        module: 'auth',
        action: 'logout',
        requiresAuth: false,
        params: {
          'refresh_token': refreshToken,
          'device_uuid': deviceUUID,
          'all_devices': allDevices,
        },
      );
    }

    // Yerel temizleme
    await _storage.deleteSecureData('authToken');
    await _storage.deleteSecureData('refreshToken');
    await _storage.deleteSecureData('role');
    await _storage.deleteSecureData('userId');

    if (includeDeviceUUID) {
      await _storage.deleteSecureData('deviceUUID');
    }
  }

  Future<String?> getStoredUserData(String key) async {
    return await _storage.readSecureData(key);
  }
}
