// lib/services/v1/v1_api_manager.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:seaofsea/services/v1/auth_service.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/secure_storage.dart';
import 'v1_config.dart';

class V1ApiManager {
  // Global navigation / unauthorized handling hooks
  static GlobalKey<NavigatorState>? navKey;
  static void Function()? onUnauthorized;

  final String baseUrl;
  final SecureStorage _storage = SecureStorage();
  String? deviceUUID;
  static bool debugForceExpiringSoon = false; // only for local simulation

  /// single-flight locks
  static Future<bool>? _refreshLock;
  static Future<bool>? _reauthLock;

  V1ApiManager({this.baseUrl = V1Config.baseUrl});

  Future<void> _initDeviceUUID() async {
    deviceUUID ??= await _storage.readSecureData('deviceUUID');
  }

  Future<void> _ensureDeviceUUID() async {
    await _initDeviceUUID();
    if (deviceUUID == null || deviceUUID!.isEmpty) {
      final id = _genUUIDv4();
      await _storage.writeSecureData('deviceUUID', id);
      deviceUUID = id;
    }
  }

  String _genUUIDv4() {
    const chars = '0123456789abcdef';
    final r = Random.secure();
    String rand(int len) => String.fromCharCodes(
        List.generate(len, (_) => chars.codeUnitAt(r.nextInt(chars.length))));
    final timeLow = rand(8);
    final timeMid = rand(4);
    final timeHiAndVersion = '4' + rand(3); // v4
    final clkSeqHiAndReserved =
        (8 + r.nextInt(4)).toRadixString(16) + rand(3); // variant 10xx
    final node = rand(12);
    return '$timeLow-$timeMid-$timeHiAndVersion-$clkSeqHiAndReserved-$node';
  }

  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return '${info.manufacturer} ${info.model}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return '${info.name} ${info.model}';
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        return 'Windows ${info.computerName}';
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        return 'Mac ${info.model}';
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        return 'Linux ${info.prettyName}';
      }
    } catch (e) {
      debugPrint('⚠️ _getDeviceName error: $e');
    }
    return 'Unknown Device';
  }

  String _getPlatformName() => Platform.operatingSystem;
  String _getOSVersion() => Platform.operatingSystemVersion;

  Future<String> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<Map<String, dynamic>> getDeviceParams() async {
    await _ensureDeviceUUID();
    return {
      'device_uuid': deviceUUID,
      'device_name': await _getDeviceName(),
      'platform': _getPlatformName(),
      'os_version': _getOSVersion(),
      'app_version': await _getAppVersion(),
    };
  }

  Map<String, String?> _extractTokens(dynamic refreshResult) {
    if (refreshResult is Map) {
      final data = refreshResult['data'];
      if (data is Map) {
        return {
          'token': data['token']?.toString(),
          'refresh': data['refresh_token']?.toString(),
        };
      } else {
        return {
          'token': refreshResult['token']?.toString(),
          'refresh': refreshResult['refresh_token']?.toString(),
        };
      }
    }
    return {'token': null, 'refresh': null};
  }

  Future<bool> _refreshOnce() async {
    await _ensureDeviceUUID();

    final refreshResult = await AuthService().refreshToken();
    if (refreshResult == null) return false;

    final toks = _extractTokens(refreshResult);
    final newToken = toks['token'];
    final newRefresh = toks['refresh'];

    if (newToken == null || newToken.isEmpty) return false;

    await _storage.writeSecureData('authToken', newToken);
    if (newRefresh != null && newRefresh.isNotEmpty) {
      await _storage.writeSecureData('refreshToken', newRefresh);
    }
    return true;
  }

  Future<bool> _refreshWithLock() async {
    final f = _refreshLock ??= _refreshOnce();
    final ok = await f;
    if (identical(_refreshLock, f)) _refreshLock = null;
    return ok;
  }

  Future<bool> _reauthWithLock(BuildContext context) async {
    final f = _reauthLock ??= _showReAuthDialog(context);
    final ok = await f;
    if (identical(_reauthLock, f)) _reauthLock = null;
    return ok;
  }

  Future<Map<String, dynamic>> call({
    required String module,
    required String action,
    Map<String, dynamic>? params,
    bool requiresAuth = true,
    BuildContext? context,
    File? file,
    String? fileType,
    String? fileName,
    void Function(double progress)? onProgress,
    bool retried = false,
  }) async {
    final dio = Dio();
    final uri = '$baseUrl/v1/index.php';

    debugPrint("🔗 API Call: $module.$action");
    await _ensureDeviceUUID();

    String? token;

    if (requiresAuth) {
      final rawToken = await _storage.readSecureData('authToken');
      if (rawToken == null || rawToken.isEmpty) {
        await AuthProvider.instance.v1logout();
        return _unauthorizedResponse('User not logged in.');
      }

      final rememberMe = await _storage.readSecureData('rememberMe') == 'true';
      final hasRefresh =
          (await _storage.readSecureData('refreshToken'))?.isNotEmpty == true;
      String? tokenCandidate = rawToken;

      final isExpired = _isTokenExpired(rawToken);
      final isSoon = _isTokenExpiringSoon(rawToken);

      // —— Preflight decisions
      if (isExpired) {
        debugPrint(
            '[AUTH] preflight: token EXPIRED, remember=$rememberMe, hasRefresh=$hasRefresh');

        if (rememberMe && hasRefresh) {
          final ok = await _refreshWithLock();
          if (!ok) {
            // try re-auth as fallback (don’t kick user immediately)
            final ctx = context ?? V1ApiManager.navKey?.currentContext;
            if (ctx != null) {
              final reok = await _reauthWithLock(ctx);
              if (!reok) {
                await AuthProvider.instance.v1logout();
                V1ApiManager.onUnauthorized?.call();
                return _unauthorizedResponse('Session expired.');
              }
              tokenCandidate = await _storage.readSecureData('authToken');
            } else {
              await AuthProvider.instance.v1logout();
              V1ApiManager.onUnauthorized?.call();
              return _unauthorizedResponse('Session expired.');
            }
          } else {
            tokenCandidate = await _storage.readSecureData('authToken');
          }
        } else {
          // remember=false → ask password inline if possible
          final ctx = context ?? V1ApiManager.navKey?.currentContext;
          if (ctx != null) {
            final ok = await _reauthWithLock(ctx);
            if (!ok) {
              await AuthProvider.instance.v1logout();
              V1ApiManager.onUnauthorized?.call();
              return _unauthorizedResponse('Session expired.');
            }
            tokenCandidate = await _storage.readSecureData('authToken');
          } else {
            await AuthProvider.instance.v1logout();
            V1ApiManager.onUnauthorized?.call();
            return _unauthorizedResponse('Session expired.');
          }
        }
      } else if (isSoon) {
        if (rememberMe && hasRefresh) {
          final ok = await _refreshWithLock();
          if (ok) {
            tokenCandidate = await _storage.readSecureData('authToken');
          } else {
            debugPrint(
                '[AUTH] preflight: expiring soon & refresh FAILED → continue with current token');
          }
        }
      }

      if (tokenCandidate == null || tokenCandidate.isEmpty) {
        await AuthProvider.instance.v1logout();
        return _unauthorizedResponse('Authentication token is missing.');
      }
      token = tokenCandidate;
    }

    final fullParams = {
      ...?params,
      ...await getDeviceParams(),
    };

    final headers = {
      if (requiresAuth) 'Authorization': 'Bearer $token',
    };

    try {
      Response response;

      if (file != null) {
        final formData = FormData.fromMap({
          'module': module,
          'action': action,
          ...fullParams,
          'file': await MultipartFile.fromFile(
            file.path,
            filename: fileName ?? file.path.split('/').last,
            contentType: fileType != null ? MediaType.parse(fileType) : null,
          ),
        });

        response = await dio.post(
          uri,
          data: formData,
          options:
              Options(headers: headers, contentType: 'multipart/form-data'),
          onSendProgress: (sent, total) =>
              onProgress?.call(total == 0 ? 0 : sent / total),
        );
      } else {
        response = await dio.post(
          uri,
          data: {
            'module': module,
            'action': action,
            'params': fullParams,
          },
          options: Options(
            headers: {
              ...headers,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );
      }

      final decoded = response.data;
      return {
        'success': decoded is Map && decoded['success'] == true,
        'message':
            (decoded is Map ? (decoded['message'] ?? '') : '').toString(),
        'data': (decoded is Map ? decoded['data'] : null),
        'code': response.statusCode,
      };
    } on DioException catch (e) {
      // —— 401 handling
      if (e.response?.statusCode == 401 && requiresAuth && !retried) {
        final remembered =
            (await _storage.readSecureData('rememberMe')) == 'true';
        debugPrint(
            '[AUTH] 401 caught. remembered=$remembered retried=$retried');

        if (remembered) {
          // try refresh first
          final ok = await _refreshWithLock();
          if (!ok) {
            // 🔁 NEW: as a last chance, offer re-auth popup instead of immediate logout
            final ctx = context ?? V1ApiManager.navKey?.currentContext;
            if (ctx != null) {
              final reok = await _reauthWithLock(ctx);
              if (!reok) {
                debugPrint('[AUTH] 401: refresh FAIL & reauth FAIL → logout');
                await AuthProvider.instance.v1logout();
                V1ApiManager.onUnauthorized?.call();
                return _unauthorizedResponse('Session expired.');
              }
              // re-auth ok → retry once
              return await call(
                module: module,
                action: action,
                params: params,
                requiresAuth: requiresAuth,
                context: context,
                file: file,
                fileType: fileType,
                fileName: fileName,
                onProgress: onProgress,
                retried: true,
              );
            } else {
              debugPrint('[AUTH] 401: refresh FAIL & no context → logout');
              await AuthProvider.instance.v1logout();
              V1ApiManager.onUnauthorized?.call();
              return _unauthorizedResponse('Session expired.');
            }
          }

          // refresh ok → retry once
          return await call(
            module: module,
            action: action,
            params: params,
            requiresAuth: requiresAuth,
            context: context,
            file: file,
            fileType: fileType,
            fileName: fileName,
            onProgress: onProgress,
            retried: true,
          );
        } else {
          // remember=false → password popup
          final ctx = context ?? V1ApiManager.navKey?.currentContext;
          if (ctx != null) {
            final ok = await _reauthWithLock(ctx);
            if (!ok) {
              debugPrint('[AUTH] 401: reauth FAIL → logout');
              await AuthProvider.instance.v1logout();
              V1ApiManager.onUnauthorized?.call();
              return _unauthorizedResponse('Session expired.');
            }
            return await call(
              module: module,
              action: action,
              params: params,
              requiresAuth: requiresAuth,
              context: context,
              file: file,
              fileType: fileType,
              fileName: fileName,
              onProgress: onProgress,
              retried: true,
            );
          } else {
            debugPrint('[AUTH] 401: no context → logout');
            await AuthProvider.instance.v1logout();
            V1ApiManager.onUnauthorized?.call();
            return _unauthorizedResponse('Session expired.');
          }
        }
      }

      final resData = e.response?.data;
      final msg = (resData is Map && resData['message'] != null)
          ? resData['message'].toString()
          : 'Connection error: ${e.message}';

      return {
        'success': false,
        'message': msg,
        'data': null,
        'code': e.response?.statusCode,
      };
    }
  }

  Map<String, dynamic> _unauthorizedResponse(String message) => {
        'success': false,
        'message': message,
        'code': 401,
        'data': null,
      };

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = json.decode(payload);
      final exp = payloadMap['exp'];
      if (exp == null) return true;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (_) {
      return true;
    }
  }

  bool _isTokenExpiringSoon(String token, {int bufferInSeconds = 90}) {
    if (debugForceExpiringSoon) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final Map<String, dynamic> decoded = json.decode(payload);
      final int exp = decoded['exp'] ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return (exp - now) <= bufferInSeconds;
    } catch (e) {
      debugPrint("❌ Token expiration kontrolü başarısız: $e");
      return true;
    }
  }

  // ——— Moderation helpers ———
  Future<Map<String, dynamic>> moderationBlockUser({
    required int targetUserId,
    String? until, // 'YYYY-MM-DD HH:mm:ss'
    int? durationHours,
    String? reason,
  }) async {
    return await call(
      module: 'moderation',
      action: 'blockUser',
      params: {
        'target_user_id': targetUserId,
        if (until != null) 'until': until,
        if (durationHours != null) 'duration_hours': durationHours,
        if (reason != null) 'reason': reason,
      },
    );
  }

  Future<Map<String, dynamic>> moderationUnblockUser({
    required int targetUserId,
  }) async {
    return await call(
      module: 'moderation',
      action: 'unblockUser',
      params: {
        'target_user_id': targetUserId,
        'blocked_until': DateTime(1970, 1, 1)
            .toIso8601String()
            .replaceFirst('T', ' ')
            .split('.')
            .first,
      },
    );
  }

  Future<Map<String, dynamic>> moderationGetBlockStatus({
    required int targetUserId,
  }) async {
    return await call(
      module: 'moderation',
      action: 'getBlockStatus',
      params: {'target_user_id': targetUserId},
    );
  }

  Future<bool> _showReAuthDialog(BuildContext context) async {
    final email = await _storage.readSecureData('email') ?? '';
    String password = '';
    bool loading = false;
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Session expired'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please re-enter your password to continue.'),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: email,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  obscureText: true,
                  onChanged: (v) => password = v,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
                if (loading) ...[
                  const SizedBox(height: 12),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (password.trim().isEmpty) {
                    if (!ctx.mounted) return;
                    setState(() => error = 'Please enter your password.');
                    return;
                  }
                  if (!ctx.mounted) return;
                  setState(() {
                    loading = true;
                    error = null;
                  });

                  try {
                    final auth = AuthService();
                    final res =
                        await auth.login(email, password, rememberMe: false);
                    final success =
                        (res['success'] == true) && (res['token'] != null);

                    if (success) {
                      await _storage.writeSecureData(
                          'authToken', (res['token'] ?? '').toString());
                      if (res['refresh_token'] != null) {
                        await _storage.writeSecureData(
                          'refreshToken',
                          (res['refresh_token'] ?? '').toString(),
                        );
                      }
                      await _storage.writeSecureData('rememberMe', 'false');
                      if (ctx.mounted) Navigator.pop(ctx, true);
                      return; // try/finally'de finally sonrası setState koruması
                    } else {
                      if (!ctx.mounted) return;
                      setState(() => error =
                          (res['message'] ?? 'Login failed').toString());
                    }
                  } catch (e) {
                    if (!ctx.mounted) return;
                    setState(() => error = 'Login error: $e');
                  } finally {
                    if (!ctx.mounted) return;
                    setState(() => loading = false);
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          );
        });
      },
    );

    return ok == true;
  }
}
