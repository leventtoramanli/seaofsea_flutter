/lib/services/v1/
├── v1_api_manager.dart         # Yeni merkezi API yöneticisi
├── auth_service.dart           # login, logout, refresh işlemleri
├── user_service.dart           # getProfile, updateProfile vb.
├── v1_config.dart              # V1 ayarları (baseURL, headers vs.)

Login İşlemi

final api = V1ApiManager();
final result = await api.call(
  module: 'auth',
  action: 'login',
  params: {
    'email': email,
    'password': password,
  },
  requiresAuth: false,
);

login_page.dart içinde

final authProvider = Provider.of<AuthProvider>(context, listen: false);
final success = await authProvider.v1Login(context, email, password);

if (success && context.mounted) {
  Navigator.pushReplacementNamed(context, Routes.home);
}

v1_api_manager.dart
headers[V1Config.authHeaderKey] = '${V1Config.bearerPrefix}$token';

Sunucu URL’si:
Uri.parse('${V1Config.baseUrl}/v1/index.php')
