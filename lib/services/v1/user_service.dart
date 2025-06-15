import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/secure_storage.dart'; // UUID buradan okunacak

class UserService {
  final V1ApiManager _api = V1ApiManager();

  /// 🔍 Kullanıcının profilini getirir (token zorunlu)
  Future<Map<String, dynamic>> getProfile() async {
    final storage = SecureStorage();
    final deviceUUID = await storage.readSecureData('deviceUUID');

    final response = await _api.call(
      module: 'user',
      action: 'getProfile',
      requiresAuth: true,
      params: {
        'device_uuid': deviceUUID,
      },
    );

    if (response['success'] == true && response['data'] != null) {
      return {'success': true, 'user': response['data']};
    } else {
      return {
        'success': false,
        'message': response['message'] ?? 'Failed to fetch user profile.'
      };
    }
  }
}
