import '../../../../core/services/api_service.dart';
import '../../../../config/app_config.dart';
import '../../../../core/services/token_storage.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/user.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiService.post(AppConfig.loginEndpoint, {
        'username': username,
        'password': password,
      });

      if (response['success'] && response['data'] != null) {
        final data = response['data'];

        // Save tokens
        if (data['access'] != null && data['refresh'] != null) {
          await _tokenStorage.saveTokens(data['access'], data['refresh']);
          _apiService.setAuthToken(data['access']);

          return {
            'success': true,
            'access_token': data['access'],
            'refresh_token': data['refresh'],
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid token response format',
          };
        }
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Invalid credentials',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> register(User user, Profile profile, String password) async {
    try {
      // Crear el usuario con password según la documentación de la API
      final userData = user.toCreateJson();
      userData['password'] = password; // Agregar password requerido por la API
      
      final userResponse = await _apiService.post(AppConfig.usersEndpoint, userData);

      if (userResponse['success'] && userResponse['data'] != null) {
        final userId = userResponse['data']['id'];

        // Crear el perfil asociado - según la API, no necesitamos pasar el user ID explícitamente
        // ya que se crea para el usuario autenticado
        final profileData = profile.toCreateJson();
        
        final profileResponse = await _apiService.post(AppConfig.profilesEndpoint, profileData);

        if (profileResponse['success']) {
          return {
            'success': true,
            'user': userResponse['data'],
            'profile': profileResponse['data'],
          };
        } else {
          return {
            'success': false,
            'error': profileResponse['error'] ?? 'Failed to create profile',
          };
        }
      } else {
        return {
          'success': false,
          'error': userResponse['error'] ?? 'Failed to create user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Registration error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiService.get(AppConfig.currentUserEndpoint);
      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting current user: $e',
      };
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post(AppConfig.logoutEndpoint, {});
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await _tokenStorage.clearTokens();
      _apiService.clearAuthToken();
    }
  }

  Future<void> initializeAuth() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null) {
      _apiService.setAuthToken(accessToken);
    }
  }

  Future<bool> isAuthenticated() async {
    final accessToken = await _tokenStorage.getAccessToken();
    return accessToken != null && await _tokenStorage.isTokenValid();
  }

  void setAuthToken(String token) {
    _apiService.setAuthToken(token);
  }

  void clearAuthToken() {
    _apiService.clearAuthToken();
  }
}
