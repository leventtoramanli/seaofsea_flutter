import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  /// Genel bir POST isteği
  Future<dynamic> post(
      BuildContext context, String endpoint, Map<String, dynamic> body) async {
        print('Post istegi: $endpoint');
    final secureStorage = SecureStorage(); // SecureStorage tanımlaması
    final authToken =
        await secureStorage.readSecureData('authToken'); // Token'ı oku
    print('Total address: $baseUrl$baseAddress?$endpoint');
    final response = await http.post(
      Uri.parse('$baseUrl$baseAddress?endpoint=$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      // Token süresi doldu, yenileme işlemi
      await refreshToken(context); // Token yenile
      return post(context, endpoint, body); // Yeniden dene
    }

    return jsonDecode(response.body);
  }

  /// Genel bir GET isteği
  Future<dynamic> get(BuildContext context, String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    final fullPath = '$baseUrl$baseAddress?endpoint=$endpoint';
    return _makeRequest(context, 'GET', fullPath, queryParams: queryParams);
  }

  /// Özel işlemler için soyutlama
  Future<dynamic> _makeRequest(
    BuildContext context,
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
  }) async {
    final uri = Uri.parse(url);
    final headers = {'Content-Type': 'application/json'};
    late http.Response response;

    try {
      switch (method) {
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
      return _handleResponse(context, response); // Yanıt işleme burada yapılır
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Request failed: $e'), backgroundColor: Colors.red),
      );
      throw Exception('Request failed: $e');
    }
  }

  /// Yanıtı işleyen metot
  dynamic _handleResponse(BuildContext context, http.Response response) {
    try {
      // HTTP yanıtın gövdesini çözümle
      final responseBody = jsonDecode(response.body);
      print('Response body: $responseBody');

      final success = responseBody['success'] ?? false;
      final message = responseBody['message'] ?? "No message provided";

      if (success) {
        // Başarılı yanıt için Snackbar veya diğer işlemler
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green),
        );
        return responseBody;
      } else {
        // Başarısız yanıt için hata mesajını Snackbar'da göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message,
                  style: TextStyle(
                      color: Colors.grey.shade100,
                      fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red),
        );
        return responseBody;
      }
    } catch (e) {
      // JSON hatası veya beklenmedik durumlarda hata yakala
      final errorMessage = "An error occurred: ${e.toString()}";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red),
      );
      throw Exception(errorMessage);
    }
  }

  /// Kullanıcı Girişi
  Future<dynamic> loginUser(
    BuildContext context,
    Map<String, dynamic> userData,
  ) async {
    return post(context, 'login', userData);
  }

  /// Kullanıcı Kayıt
  Future<dynamic> createUser(
    BuildContext context,
    Map<String, dynamic> userData,
  ) async {
    return post(context, 'register', userData);
  }

  /// Şifre Sıfırlama İsteği
  Future<dynamic> resetPasswordRequest(
    BuildContext context,
    String email,
  ) async {
    return post(context, 'reset_password_request', {'email': email});
  }

  /// Şifre Sıfırlama
  Future<dynamic> resetPassword(
    BuildContext context,
    String email,
    String newPassword,
    String confirmPassword,
  ) async {
    return post(context, 'reset_password', {
      'email': email,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
  }

  Future<List<Map<String, dynamic>>> getUsersWithRoles(
      BuildContext context) async {
    final response = await get(context, 'get_users_with_roles');
    if (response['success']) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw Exception(
          response['message'] ?? 'Failed to retrieve users with roles.');
    }
  }

  Future<void> refreshToken(BuildContext context) async {
    final secureStorage = SecureStorage();
    final refreshToken = await secureStorage.readSecureData('refreshToken');

    if (refreshToken == null) {
      throw Exception('No refresh token available.');
    }

    final response =
        await post(context, 'refresh_token', {'refresh_token': refreshToken});

    if (response['success']) {
      final newAccessToken = response['data']['access_token'];
      await secureStorage.writeSecureData('authToken', newAccessToken);
    } else {
      throw Exception(response['message']);
    }
  }

  /// Hata ve başarı mesajlarını gösteren metot
  void showSnackbar(BuildContext context, String message,
      {bool isSuccess = true}) {
    if (message.isEmpty) {
      message = "An unknown error occurred."; // Varsayılan mesaj
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isSuccess
              ? TextStyle(
                  color: Colors.grey.shade500, fontWeight: FontWeight.bold)
              : const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }
}
