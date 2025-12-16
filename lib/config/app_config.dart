class AppConfig {
  static const String appName = 'Habitto';
  static const String version = '1.0.0';

  // API Configuration
  //static const String baseUrl = 'http://192.168.1.128:8000';
  //static const String baseUrl = 'http://10.0.2.2:8000';
  static const String baseUrl = 'https://web-production-67a04a.up.railway.app/';
  static const int timeoutDuration = 30000; // milliseconds

  // API Endpoints
  static const String usersEndpoint = '/api/users/';
  static const String currentUserEndpoint = '/api/users/me/';
  static const String profilesEndpoint = '/api/profiles/';
  static const String currentProfileEndpoint = '/api/profiles/me/';
  static const String updateProfileEndpoint = '/api/profiles/update_me/';
  static const String uploadProfilePictureEndpoint =
      '/api/profiles/upload_profile_picture/';
  static const String searchProfilesEndpoint = '/api/profiles/search-profile/';
  static const String propertiesEndpoint = '/api/properties/';
  static const String amenitiesEndpoint = '/api/amenities/';
  static const String photosEndpoint = '/api/photos/';
  static const String loginEndpoint = '/api/login/';
  static const String logoutEndpoint = '/api/logout/';
  static const String refreshTokenEndpoint = '/api/refresh/';

  // Social Auth Endpoints (dj-rest-auth)
  static const String socialGoogleEndpoint = '/dj-rest-auth/google/';
  static const String socialFacebookEndpoint = '/dj-rest-auth/facebook/';
  static const String socialAppleEndpoint = '/dj-rest-auth/apple/';

  // Endpoints alternativos (compatibilidad                               con documentación nueva)
  // Algunos despliegues usan SimpleJWT por defecto:
  //  - Obtener tokens: POST /api/token/
  //  - Refrescar token: POST /api/token/refresh/
  static const String tokenObtainEndpoint = '/api/token/';
  static const String tokenRefreshEndpoint = '/api/token/refresh/';
  static const String authLoginEndpoint = '/api/auth/login/';

  // Database Configuration
  static const String databaseName = 'habitto.db';
  static const int databaseVersion = 1;

  // AI Configuration
  static const String deepseekApiKey = 'sk-7bb75d41367543b48c164f3ff23459d5';
  static const String deepseekBaseUrl = 'https://api.deepseek.com';

  static const int wsPort = 8000;
  static const String wsChatPath = '/ws/chat/';
  static const String wsTokenQueryName = 'token';
  static const String wsInboxPath = '/ws/chat/inbox/';

  static Uri httpBaseUri() {
    try {
      return Uri.parse(baseUrl);
    } catch (_) {
      return Uri.parse('http://localhost:8000');
    }
  }

  // Base URL para pruebas locales de login social según plataforma
  static String socialBaseUrl() {
    return httpBaseUri().toString();
  }

  static String wsScheme() {
    final http = httpBaseUri();
    return http.scheme == 'https' ? 'wss' : 'ws';
  }

  static String wsHost() {
    final http = httpBaseUri();
    return http.host;
  }

  static Uri buildWsUri(String subpath, {String? token}) {
    final http = httpBaseUri();
    return Uri(
      scheme: wsScheme(),
      host: wsHost(),
      port: http.hasPort ? http.port : null,
      path: subpath,
      queryParameters: token != null ? {wsTokenQueryName: token} : null,
    );
  }

  static String sanitizeUrl(String url) {
    if (url.isEmpty) return url;
    Uri? u;
    try {
      u = Uri.parse(url);
    } catch (_) {}
    if (u == null || !u.hasScheme) return url;
    final http = httpBaseUri();
    final host =
        (u.host == 'localhost' || u.host == '127.0.0.1') ? http.host : u.host;
    final port = (u.host == 'localhost' || u.host == '127.0.0.1')
        ? http.port
        : (u.hasPort ? u.port : http.port);
    final scheme = http.scheme;
    final rebuilt = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: u.path,
      query: u.query,
      fragment: u.fragment,
    );
    return rebuilt.toString();
  }
}
