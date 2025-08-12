// lib/services/v1/user_service.dart
import 'package:seaofsea/services/v1/v1_api_manager.dart';

class UserService {
  final V1ApiManager _api = V1ApiManager();

  /// Kendi profilin (id göndermezsen) veya başka kullanıcının profili (id ile)
  /// DÖNÜŞ: { success: bool, user: Map<String, dynamic>, message?: String }
  Future<Map<String, dynamic>> getProfile({int? id}) async {
    final resp = await _api.call(
      module: 'profile',
      action: 'getProfile',
      requiresAuth: true,
      params: {
        if (id != null) 'id': id, // başkasının profili için
      }, // device_uuid vs. eklemiyoruz; V1ApiManager otomatik ekliyor
    );

    if (resp['success'] == true && resp['data'] != null) {
      // normalize: her yerde result['user'] olarak eriş
      return {
        'success': true,
        'user': resp['data'],               // <- data'yı user'a map’ledik
        'message': resp['message'] ?? '',
      };
    }

    return {
      'success': false,
      'message': resp['message'] ?? 'Failed to fetch user profile.',
    };
  }
}
