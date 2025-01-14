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

  ApiManager(
    this.token, {
    this.baseUrl = 'http://localhost',
    this.baseAddress = '/public/api.php',
  });

  factory ApiManager.empty() => ApiManager(null);

  Future<dynamic> request(
    BuildContext context, {
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
  }) async {
    final secureStorage = SecureStorage();
    final authToken = await secureStorage.readSecureData('authToken');
    final uri = Uri.parse('$baseUrl$baseAddress?endpoint=$endpoint');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    try {
      http.Response response;

      // HTTP yöntemi seçimi
      switch (method.toUpperCase()) {
        case 'POST':
          response =
              await http.post(uri, headers: headers, body: jsonEncode(body));
          break;
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      // Eğer yanıt 401 ise token yenilemeyi dene
      if (response.statusCode == 401) {
        // ignore: use_build_context_synchronously
        final refreshSuccessful = await _refreshToken(context);
        if (refreshSuccessful) {
          // Yeni token ile isteği tekrar dene
          return request(
            // ignore: use_build_context_synchronously
            context,
            endpoint: endpoint,
            method: method,
            body: body,
            queryParams: queryParams,
          );
        } else {
          // Token yenileme başarısızsa oturumu kapat
          final authProvider =
              // ignore: use_build_context_synchronously
              Provider.of<AuthProvider>(context, listen: false);
          // ignore: use_build_context_synchronously
          await authProvider.logout(context);
          throw Exception('Session expired. Please log in again.');
        }
      }

      // ignore: use_build_context_synchronously
      return _handleResponse(context, response); // Yanıtı işle
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showSnackbar(context, 'Request failed: $e', isSuccess: false);
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
      {bool isSuccess = true}) {
    if (_isSnackbarVisible) return;

    _isSnackbarVisible = true;
    {
      ScaffoldMessenger.of(context)
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
          .then((value) => _isSnackbarVisible = false);
    }
  }

  Future<dynamic> uploadFile(
    BuildContext context, {
    required String endpoint,
    required File file,
  }) async {
    final secureStorage = SecureStorage();
    final authToken = await secureStorage.readSecureData('authToken');
    final uri = Uri.parse('$baseUrl$baseAddress?endpoint=$endpoint');

    final headers = {
      'Authorization': 'Bearer $authToken',
    };

    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData['success']) {
          _showSnackbar(
              context, responseData['message'] ?? 'File uploaded successfully!',
              isSuccess: true);
          return responseData;
        } else {
          throw Exception(responseData['message'] ?? 'Upload failed.');
        }
      } else {
        throw Exception('Failed to upload file: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar(context, 'Error uploading file: $e', isSuccess: false);
      rethrow;
    }
  }

  Future<bool> _refreshToken(BuildContext context) async {
    final secureStorage = SecureStorage();
    final refreshToken = await secureStorage.readSecureData('refreshToken');

    if (refreshToken == null) {
      debugPrint('No refresh token found.');
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

      if (response.statusCode == 200 && responseBody['success']) {
        final newAuthToken = responseBody['data']['auth_token'];
        await secureStorage.writeSecureData('authToken', newAuthToken);
        return true;
      } else {
        debugPrint('Token refresh failed: ${responseBody['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }
}
