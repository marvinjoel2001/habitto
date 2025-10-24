class AppConfig {
  static const String appName = 'Habitto';
  static const String version = '1.0.0';

  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const int timeoutDuration = 30000; // milliseconds

  // API Endpoints
  static const String usersEndpoint = '/api/users/';
  static const String currentUserEndpoint = '/api/users/me/';
  static const String profilesEndpoint = '/api/profiles/';
  static const String currentProfileEndpoint = '/api/profiles/me/';
  static const String updateProfileEndpoint = '/api/profiles/update_me/';
  static const String uploadProfilePictureEndpoint = '/api/profiles/upload_profile_picture/';
  static const String propertiesEndpoint = '/api/properties/';
  static const String amenitiesEndpoint = '/api/amenities/';
  static const String photosEndpoint = '/api/photos/';
  static const String loginEndpoint = '/api/login/';
  static const String logoutEndpoint = '/api/logout/';
  static const String refreshTokenEndpoint = '/api/refresh/';

  // Database Configuration
  static const String databaseName = 'habitto.db';
  static const int databaseVersion = 1;
}
