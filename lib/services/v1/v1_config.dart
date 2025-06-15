
class V1Config {
  /// API sunucusunun kök URL'si
  static const String baseUrl = 'http://localhost/seaofsea/';

  /// Varsayılan zaman aşımı süresi (ms cinsinden)
  static const int defaultTimeout = 10000;

  /// JSON gönderim formatı
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  /// Başarılı response için beklenen key
  static const String successKey = 'success';

  /// Hata mesajları için kullanılan key
  static const String messageKey = 'message';

  /// JWT token gönderiminde kullanılan header
  static const String authHeaderKey = 'Authorization';

  /// Token ön eki
  static const String bearerPrefix = 'Bearer ';
}
