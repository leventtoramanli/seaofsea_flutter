import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiManager {
  final String baseUrl;
  final String baseAddress;

  ApiManager({
    required this.baseUrl,
    required this.baseAddress,
  });

  /// Genel bir POST isteği
  Future<dynamic> post(
      BuildContext context, String endpoint, Map<String, dynamic> body) async {
    return _makeRequest(context, 'POST', endpoint, body: body);
  }

  /// Genel bir GET isteği
  Future<dynamic> get(BuildContext context, String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    return _makeRequest(context, 'GET', endpoint, queryParams: queryParams);
  }

  /// Genel bir PUT isteği
  Future<dynamic> put(
      BuildContext context, String endpoint, Map<String, dynamic> body) async {
    return _makeRequest(context, 'PUT', endpoint, body: body);
  }

  /// Genel bir DELETE isteği
  Future<dynamic> delete(BuildContext context, String endpoint) async {
    return _makeRequest(context, 'DELETE', endpoint);
  }

  /// Hata ve başarı mesajlarını gösteren metot
  void showSnackbar(BuildContext context, String message,
      {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        showCloseIcon: true,
        backgroundColor:
            isSuccess ? Colors.green.shade100 : Colors.red.shade100,
      ),
    );
  }

  /// Özel işlemler için soyutlama
  Future<dynamic> _makeRequest(
    BuildContext context,
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
  }) async {
    final url =
        Uri.https(baseUrl.replaceFirst('https://', ''), endpoint, queryParams);
    final headers = {'Content-Type': 'application/json'};
    late http.Response response;

    try {
      // HTTP isteği yap
      switch (method) {
        case 'POST':
          response =
              await http.post(url, headers: headers, body: jsonEncode(body));
          break;
        case 'PUT':
          response =
              await http.put(url, headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response =
              await http.delete(url, headers: headers, body: jsonEncode(body));
          break;
        case 'GET':
        default:
          response = await http.get(url, headers: headers);
          break;
      }

      // HTTP yanıtını işle
      return _handleResponse(context, response);
    } catch (e) {
      showSnackbar(context, 'Request failed: $e', isSuccess: false);
      throw Exception('Request failed: $e');
    }
  }

  /// Yanıtı işleyen metot
  dynamic _handleResponse(BuildContext context, http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseBody = jsonDecode(response.body);

      if (responseBody['success'] == true) {
        showSnackbar(context, responseBody['message'] ?? 'Operation successful',
            isSuccess: true);
        return responseBody;
      } else {
        final errors = responseBody['errors'] ?? ['Unknown error'];
        showSnackbar(context, errors.join('\n'), isSuccess: false);
        return responseBody;
      }
    } else {
      showSnackbar(context,
          'HTTP Error ${response.statusCode}: ${response.reasonPhrase}',
          isSuccess: false);
      throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
    }
  }

  /// CRUD ve diğer işlem bazlı metotlar
  Future<dynamic> createUser(
      BuildContext context, Map<String, dynamic> userData) async {
    return post(context, '$baseAddress/register.php', userData);
  }

  Future<dynamic> loginUser(
      BuildContext context, Map<String, dynamic> loginData) async {
    return post(context, '$baseAddress/login.php', loginData);
  }

  Future<dynamic> updateUser(BuildContext context, String userId,
      Map<String, dynamic> userData) async {
    return put(context, '$baseAddress/users/$userId', userData);
  }

  Future<dynamic> getUser(BuildContext context, String userId) async {
    return get(context, '$baseAddress/users/$userId');
  }

  Future<dynamic> deleteUser(BuildContext context, String userId) async {
    return delete(context, '$baseAddress/users/$userId');
  }
}
