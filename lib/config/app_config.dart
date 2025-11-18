class AppConfig {
  static const String appName = 'Habitto';
  static const String version = '1.0.0';

  // API Configuration
  //static const String baseUrl = 'http://192.168.1.128:8000';
  static const String baseUrl = 'http://10.0.2.2:8001';
  static const int timeoutDuration = 30000; // milliseconds

  // API Endpoints
  static const String usersEndpoint = '/api/users/';
  static const String currentUserEndpoint = '/api/users/me/';
  static const String profilesEndpoint = '/api/profiles/';
  static const String currentProfileEndpoint = '/api/profiles/me/';
  static const String updateProfileEndpoint = '/api/profiles/update_me/';
  static const String uploadProfilePictureEndpoint = '/api/profiles/upload_profile_picture/';
  static const String searchProfilesEndpoint = '/api/profiles/search-profile/';
  static const String propertiesEndpoint = '/api/properties/';
  static const String amenitiesEndpoint = '/api/amenities/';
  static const String photosEndpoint = '/api/photos/';
  static const String loginEndpoint = '/api/login/';
  static const String logoutEndpoint = '/api/logout/';
  static const String refreshTokenEndpoint = '/api/refresh/';

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

  static const int wsPort = 8000;
  static const String wsChatPath = '/ws/chat/';
  static const String wsTokenQueryName = 'token';
  static const String wsInboxPath = '/ws/chat/inbox/';

  static Uri httpBaseUri() {
    // Android emulator usa 10.0.2.2 para apuntar a localhost del host
    // iOS/macOS/desktop usan localhost directamente
    try {
      // dart:io Platform no está importado aquí; usamos el baseUrl como pista
      final uri = Uri.parse(baseUrl);
      final isAndroidEmulator = uri.host == '10.0.2.2';
      if (isAndroidEmulator) {
        return Uri.parse('http://10.0.2.2:8001');
      }
      return Uri.parse('http://localhost:8001');
    } catch (_) {
      return Uri.parse('http://localhost:8001');
    }
  }

  // Sanitiza URLs recibidas del backend y ajusta host/puerto según plataforma
  static String sanitizeUrl(String url) {
    final raw = url.replaceAll('`', '').replaceAll('"', '').trim();
    if (raw.isEmpty) return raw;
    Uri? u;
    try { u = Uri.parse(raw); } catch (_) {}
    if (u == null || !u.hasScheme) return raw;
    final http = httpBaseUri();
    final isLocalHost = (u.host == 'localhost' || u.host == '127.0.0.1');
    final host = isLocalHost ? http.host : u.host;
    final port = isLocalHost ? http.port : (u.hasPort ? u.port : http.port);
    final scheme = http.scheme;
    final rebuilt = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: u.path,
      query: u.query.isNotEmpty ? u.query : null,
      fragment: u.fragment.isNotEmpty ? u.fragment : null,
    );
    return rebuilt.toString();
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
    return Uri(
      scheme: wsScheme(),
      host: wsHost(),
      port: wsPort,
      path: subpath,
      queryParameters: token != null ? {wsTokenQueryName: token} : null,
    );
  }

}
