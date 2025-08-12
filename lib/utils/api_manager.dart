// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/secure_storage.dart';

class ApiManager {
  final String? token;
  final String baseUrl;
  final String baseAddress;
  int _retryCount = 0;
  bool _isRefreshing = false;

  ApiManager(
    this.token, {
    this.baseUrl = 'https://localhost/seaofsea',
    this.baseAddress = '/public/api.php',
  });

  factory ApiManager.empty() => ApiManager(null);
  

  String showImage(String imagePath, bool asset) {
    if (asset) {
      return 'assets/$imagePath';
    }
    return '${baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'}$imagePath';
  }

  Future<dynamic> request(
    BuildContext context, {
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
  }) async {
    final secureStorage = SecureStorage();

    String? authToken = await secureStorage.readSecureData('authToken');

    if (authToken == null || authToken.isEmpty) {
      debugPrint('⚠️ Hata: authToken null or empty (Need Login).');
    }

    Uri uri = Uri.parse('$baseUrl$baseAddress?endpoint=$endpoint');

    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (authToken != null && authToken.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };
    debugPrint(
        "🔐 Sending Authorization: ${headers['Authorization'] ?? 'NO TOKEN'}");
    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'POST':
          response =
              await http.post(uri, headers: headers, body: jsonEncode(body));
          break;
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        default:
          throw Exception('❌ Unsupported HTTP method: $method');
      }

      debugPrint("📢 API Response Code: ${response.statusCode}");
      debugPrint("📢 API Response: ${response.body}");

      String utf8Body = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(utf8Body);

      if (response.statusCode == 401) {
        debugPrint("❌ 401 Unauthorized Hatası! Token expired.");

        if (_retryCount < 2) {
          _retryCount++;
          final refreshSuccessful = await _refreshToken(context);
          debugPrint("🔄 Refresh Token Action: $refreshSuccessful");

          if (refreshSuccessful) {
            _retryCount = 0;
            authToken = await secureStorage.readSecureData('authToken');
            debugPrint("✅ New token is using: $authToken");
            headers['Authorization'] = 'Bearer $authToken';
            return request(context,
                endpoint: endpoint,
                method: method,
                body: body,
                queryParams: queryParams);
          } else {
            debugPrint("❌ Refresh token is not taking! User not logged in.");
            if (context.mounted) {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.v1logout();
            }
            throw Exception('Session expired. Please log in again.');
          }
        }
      }
      if (response.statusCode == 200 && responseData['success'] == false) {
        if (responseData['errors']?['error'] == 'Expired token') {
          debugPrint("⏰ Token süresi dolmuş ama kod 200. Refresh deneniyor...");
          if (_retryCount < 2) {
            _retryCount++;
            final refreshSuccessful = await _refreshToken(context);
            if (refreshSuccessful) {
              authToken = await secureStorage.readSecureData('authToken');
              headers['Authorization'] = 'Bearer $authToken';
              return request(
                context,
                endpoint: endpoint,
                method: method,
                body: body,
                queryParams: queryParams,
              );
            } else {
              if (context.mounted) {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.v1logout();
              }
              throw Exception('Session expired. Please log in again.');
            }
          }
        }
      }

      return _handleResponse(context, responseData);
    } catch (e) {
      String errorMessage = 'An unknown error occurred.';
      if (e is SocketException) {
        if (e.osError?.message.contains("ağ bağlantısını reddetti") ?? false) {
          errorMessage =
              'Cannot connect to the server. Please ensure the backend service is running.';
        } else {
          errorMessage = 'Network error: ${e.osError?.message}';
        }
      } else {
        errorMessage = 'Request failed: $e';
      }

      if (context.mounted) {
        _showSnackbar(context, errorMessage, isSuccess: false);
        return {'success': false, 'message': errorMessage, 'data': null};
      }
      rethrow;
    }
  }

  Future<dynamic> post(
      BuildContext context, String endpoint, Map<String, dynamic> body) {
    return request(context, endpoint: endpoint, method: 'POST', body: body);
  }

  Future<dynamic> get(BuildContext context, String endpoint,
      {Map<String, dynamic>? queryParams}) {
    return request(context,
        endpoint: endpoint, method: 'GET', queryParams: queryParams);
  }

  dynamic _handleResponse(
      BuildContext context, Map<String, dynamic> responseData) {
    final success = responseData['success'] ?? false;
    final message = responseData['message'] ?? 'No message provided';
    final showMessage = responseData['showMessage'] ?? true;

    if (showMessage) {
      _showSnackbar(context, message, isSuccess: success);
    }

    return responseData;
  }

  Future<dynamic> postMultipartWithImage({
    required BuildContext context,
    required String action,
    required Map<String, String> fields,
    File? imageFile,
  }) async {
    // ignore: prefer_interpolation_to_compose_strings
    final uri = Uri.parse(baseUrl + '/public/api.php?action=' + action);
    final request = http.MultipartRequest('POST', uri);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final secureStorage = SecureStorage();
    String? token = authProvider.token;
    final userId = authProvider.userInfo?['id']?.toString();

    if (userId != null) {
      fields['user_id'] = userId;
    }

    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'webp'),
      ));
    }

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("📢 Multipart API Response Code: ${response.statusCode}");
      debugPrint("📢 Multipart API Response: ${response.body}");

      String utf8Body = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(utf8Body);

      if (response.statusCode == 401) {
        debugPrint("❌ 401 Unauthorized in Multipart. Trying refresh...");
        if (_retryCount < 2) {
          _retryCount++;
          final refreshSuccessful = await _refreshToken(context);
          if (refreshSuccessful) {
            token = await secureStorage.readSecureData('authToken');
            return postMultipartWithImage(
              context: context,
              action: action,
              fields: fields,
              imageFile: imageFile,
            );
          } else {
            if (context.mounted) {
              await authProvider.v1logout();
            }
            throw Exception('Session expired. Please log in again.');
          }
        }
      }

      return _handleResponse(context, responseData);
    } catch (e) {
      String errorMessage = 'An unknown error occurred.';
      if (e is SocketException) {
        if (e.osError?.message.contains("ağ bağlantısını reddetti") ?? false) {
          errorMessage =
              'Cannot connect to the server. Please ensure the backend service is running.';
        } else {
          errorMessage = 'Network error: ${e.osError?.message}';
        }
      } else {
        errorMessage = 'Request failed: $e';
      }

      if (context.mounted) {
        _showSnackbar(context, errorMessage, isSuccess: false);
        return {'success': false, 'message': errorMessage, 'data': null};
      }
      rethrow;
    }
  }

  bool _isSnackbarVisible = false;
  void _showSnackbar(BuildContext context, String message,
      {bool isSuccess = true}) async {
    if (_isSnackbarVisible) return;

    _isSnackbarVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
        if (scaffoldMessenger != null) {
          scaffoldMessenger
              .showSnackBar(
                SnackBar(
                  content: Text(
                    message,
                    style: TextStyle(
                      color: isSuccess ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor:
                      isSuccess ? Colors.grey.shade900 : Colors.red.shade100,
                ),
              )
              .closed
              .whenComplete(() => _isSnackbarVisible = false);
        } else {
          _isSnackbarVisible = false;
        }
      } else {
        _isSnackbarVisible = false;
      }
    });
  }

  Future<dynamic> uploadImage(
    BuildContext context, {
    required String endpoint,
    required File file,
    Map<String, String>? meta,
  }) async {
    final secureStorage = SecureStorage();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Kullanıcı ID'yi çek, boşsa AuthProvider'ı güncelle
    String? userId = await secureStorage.readSecureData('userId');
    if (userId == null || userId.isEmpty) {
      // ✅ DÜZENLENDİ: Kullanıcı ID boşsa AuthProvider güncelleniyor
      debugPrint("User ID is empty, refreshing user info...");
      //await authProvider.refreshUserInfo(context);
      userId = await secureStorage.readSecureData('userId');
    }

    if (userId == null) {
      debugPrint('Error: User ID is still null.');
      return null;
    }

    final uri = Uri.parse('$baseUrl$baseAddress?endpoint=$endpoint');
    final authToken = await secureStorage.readSecureData('authToken') ?? '';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..fields['user_id'] = userId
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      meta?.forEach((key, value) {
        request.fields[key] = value;
      });

      debugPrint('Request Body: ${request.fields}');

      final response = await request.send();
      if (response.statusCode != 200) {
        debugPrint('Upload failed: ${response.reasonPhrase}');
        return null;
      }
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);

      debugPrint('Response Body: $responseBody');

      if (response.statusCode == 200 && responseData['success']) {
        final newImage = responseData['data']['file_name'];
        debugPrint('New Image: $newImage');

        // Görsel güncellendi, şimdi AuthProvider'ı ve SecureStorage'ı güncelleyelim
        await secureStorage.writeSecureData(
            endpoint.contains('profile') ? 'profileImage' : 'coverImage',
            newImage);
        //await authProvider.refreshUserInfo(context);
        imageCache.clear();
        imageCache.clearLiveImages();

        return responseData;
      } else {
        debugPrint('Upload failed: ${responseData['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  Future<bool> _refreshToken(BuildContext context) async {
    debugPrint("🔄 `_refreshToken()` Called.");

    if (_isRefreshing) {
      debugPrint("🔄 Refresh token job already continou...");
      return false;
    }
    _isRefreshing = true;

    final secureStorage = SecureStorage();
    final refreshToken = await secureStorage.readSecureData('refreshToken');
    debugPrint("🔄 New token is not taking with refresh token: $refreshToken");

    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint("❌ Refresh token did not found! User not logged in.");
      _isRefreshing = false;
      return false;
    }

    final uri = Uri.parse('$baseUrl$baseAddress?endpoint=refresh_token');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      final responseBody = jsonDecode(response.body);
      debugPrint("📢 Refresh Token Response: $responseBody");

      if (response.statusCode == 200 && responseBody['success']) {
        final newAuthToken = responseBody['data']?['access_token'];
        final newRefreshToken = responseBody['data']?['refresh_token'];

        if (newAuthToken == null || newRefreshToken == null) {
          debugPrint("❌ New token specific data did not found!");
          _isRefreshing = false;
          return false;
        }

        await secureStorage.writeSecureData('authToken', newAuthToken);
        await secureStorage.writeSecureData('refreshToken', newRefreshToken);

        debugPrint("✅ New token did not send: $newAuthToken");

        _isRefreshing = false;
        return true;
      } else {
        debugPrint('❌ Refresh Token Error: ${responseBody['message']}');
        _isRefreshing = false;
        return false;
      }
    } catch (e) {
      debugPrint('❌ Refresh Token Error: $e');
      _isRefreshing = false;
      return false;
    }
  }
}
