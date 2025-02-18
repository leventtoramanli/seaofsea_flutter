import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/secure_storage.dart';

class ApiManager {
  final String? token;
  final String baseUrl;
  final String baseAddress;
  int _retryCount = 0;

  ApiManager(
    this.token, {
    this.baseUrl = 'http://localhost',
    this.baseAddress = '/public/api.php',
  });

  factory ApiManager.empty() => ApiManager(null);
  String showImage(String imagePath, bool asset) {
    if (asset) {
      return 'assets/$imagePath';
    }
    return '${baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'}$imagePath';
  }

  Future<void> testHeaderRequest(BuildContext context) async {
    final secureStorage = SecureStorage();
    final authToken = await secureStorage.readSecureData('authToken');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    final uri = Uri.parse('http://localhost/test/test_headers.php');

    final response = await http.get(uri, headers: headers);

    debugPrint('📡 Response Body: ${response.body}');
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
      debugPrint('⚠️ Hata: authToken null veya boş (Login gereklidir).');
    } else {
      debugPrint(
          '📡 Kullanılan Auth Token: $authToken'); // 📌 Token her zaman gösterilecek
    }

    Uri uri = Uri.parse('$baseUrl$baseAddress?endpoint=$endpoint');

    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    debugPrint('📡 Request headers: $headers');

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

      if (response.statusCode == 401 && _retryCount < 2) {
        // 📌 Retry sınırı 3'e çıktı
        _retryCount++;
        final refreshSuccessful = await _refreshToken(context);

        if (refreshSuccessful) {
          authToken = await secureStorage
              .readSecureData('authToken'); // 📌 Yeni token hemen kullanılmalı
          headers['Authorization'] = 'Bearer $authToken';

          debugPrint(
              "📌 Yeni Token ile Request Tekrar Gönderiliyor: $authToken");

          return request(context,
              endpoint: endpoint,
              method: method,
              body: body,
              queryParams: queryParams);
        } else {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.logout(context);
          throw Exception('Session expired. Please log in again.');
        }
      }

      if (context.mounted) {
        return _handleResponse(context, response);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackbar(context, 'Request failed: $e', isSuccess: false);
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

  dynamic _handleResponse(BuildContext context, http.Response response) {
    final responseBody = jsonDecode(response.body);
    final success = responseBody['success'] ?? false;
    final message = responseBody['message'] ?? 'No message provided';

    _showSnackbar(context, message, isSuccess: success);
    if (success) {
      return responseBody;
    } else {
      throw Exception(message);
    }
  }

  bool _isSnackbarVisible = false;
  void _showSnackbar(BuildContext context, String message,
      {bool isSuccess = true}) async {
    if (_isSnackbarVisible) return;

    _isSnackbarVisible = true;
    if (context.mounted) {
      await ScaffoldMessenger.of(context)
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
          .closed;
      _isSnackbarVisible = false;
    }
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
      await authProvider.refreshUserInfo(context);
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
        // ✅ DÜZENLENDİ: Hata yönetimi eklendi
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
        await authProvider.refreshUserInfo(context);
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
    final secureStorage = SecureStorage();
    final refreshToken = await secureStorage.readSecureData('refreshToken');
    AuthProvider _authProvider = Provider.of<AuthProvider>(context);

    debugPrint("🔄 Refresh Token İşlemi Başladı.");
    debugPrint("🔄 Mevcut Refresh Token: $refreshToken");

    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint("❌ Refresh token bulunamadı!");
      return false;
    }

    final uri = Uri.parse('$baseUrl$baseAddress?endpoint=refresh_token');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      debugPrint("🔄 Refresh Token Yanıtı: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success']) {
        final newAuthToken = responseBody['data']?['access_token'];
        final newRefreshToken = responseBody['data']?['refresh_token'];

        if (newAuthToken == null || newRefreshToken == null) {
          debugPrint("❌ Yeni token bilgileri eksik!");
          return false;
        }

        // 📌 ✅ **Yeni tokenları hemen sakla**
        await secureStorage.writeSecureData('authToken', newAuthToken);
        await secureStorage.writeSecureData('refreshToken', newRefreshToken);
        
        _authProvider.refreshUserInfo(context);

        debugPrint("✅ Yeni Access Token Güncellendi: $newAuthToken");
        debugPrint("✅ Yeni Refresh Token Güncellendi: $newRefreshToken");

        // 📌 **Sadece başarı olduğunda sıfırla**
        _retryCount = 0;
        return true;
      } else {
        debugPrint('❌ Refresh Token Başarısız: ${responseBody['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Refresh Token Hatası: $e');
      return false;
    }
  }
}
