import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/secure_storage.dart';
import 'v1_config.dart';

class V1ApiManager {
  final String baseUrl;
  final SecureStorage _storage = SecureStorage();
  int _retryCount = 0;

  V1ApiManager({this.baseUrl = V1Config.baseUrl});

  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return 'Windows ${windowsInfo.computerName}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return 'Mac ${macInfo.model}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return 'Linux ${linuxInfo.prettyName}';
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ _getDeviceName error: $e');
    }
    return 'Unknown Device';
  }

  String _getPlatformName() {
    return Platform.operatingSystem;
  }

  String _getOSVersion() {
    return Platform.operatingSystemVersion;
  }

  Future<String> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<Map<String, dynamic>> call({
    required String module,
    required String action,
    Map<String, dynamic>? params,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/index.php');
    String? deviceUUID = await _storage.readSecureData('deviceUUID');
    if (deviceUUID == null || deviceUUID.isEmpty) {
      final deviceUUID = AuthProvider.generateUUID();
      await _storage.writeSecureData('deviceUUID', deviceUUID);
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final token = await _storage.readSecureData('authToken');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    final deviceName = await _getDeviceName();
    final platform = _getPlatformName();
    final osVersion = _getOSVersion();
    final appVersion = await _getAppVersion();
    final fullParams = {
      ...?params,
      'device_uuid': deviceUUID,
      'device_name': deviceName,
      'platform': platform,
      'os_version': osVersion,
      'app_version': appVersion,
    };
    final body = jsonEncode({
      'module': module,
      'action': action,
      'params': fullParams,
    });

    if (kDebugMode) {
      print('📤 Sending to $uri');
      print('📨 Headers: $headers');
      print('📨 Body: $body');
    }

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final statusCode = response.statusCode;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (statusCode == 200 && decoded['success'] == true) {
        _retryCount = 0;
        return decoded;
      }

      if (statusCode == 401 ||
          decoded['message']?.toString().toLowerCase().contains('token') ==
              true) {
        debugPrint('Returned message: ${decoded['message']}');
        if (_retryCount < 1) {
          _retryCount++;
          final refreshed = await _refreshToken();
          if (refreshed) {
            return await call(
                module: module,
                action: action,
                params: params,
                requiresAuth: requiresAuth);
          }
        } else {
          debugPrint('Returned message: ${decoded['message']}');
          return {
            'success': false,
            'message': decoded['message'] ?? 'API error',
            'data': decoded['data'],
            'code': 401,
          };
        }
      }
      debugPrint('Returned message: ${decoded['message']}');
      return {
        'success': false,
        'message': decoded['message'] ?? 'API error',
        'data': decoded['data'],
        'code': statusCode,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ V1ApiManager Error: $e');
      }
      return {
        'success': false,
        'message': 'Connection error',
        'data': null,
      };
    }
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.readSecureData('refreshToken');
    final deviceUuid = await _storage.readSecureData('deviceUUID');
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final uri = Uri.parse('$baseUrl/v1/index.php');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final body = jsonEncode({
        'module': 'auth',
        'action': 'refresh_token',
        'params': {
          'refresh_token': refreshToken,
          'device_uuid': deviceUuid,
        }
      });

      final response = await http.post(uri, headers: headers, body: body);
      final statusCode = response.statusCode;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (kDebugMode) {
        print('🔁 Refresh Response [$statusCode]: $decoded');
      }

      if (statusCode == 200 && decoded['success'] == true) {
        await _storage.writeSecureData('authToken', decoded['data']['token']);
        await _storage.writeSecureData(
            'refreshToken', decoded['data']['refresh_token']);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Refresh Token Error: $e');
    }

    return false;
  }
}
