import 'dart:io';

import '../../../../core/services/api_service.dart';
import '../../../../config/app_config.dart';
import '../../../../core/services/token_storage.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/user.dart';

/// Servicio de autenticación - Capa de negocio
/// Responsabilidad: Implementar la lógica de negocio para autenticación
/// - Conoce las rutas de la API específicas de auth
/// - Maneja la serialización de datos de negocio
/// - Convierte respuestas JSON a entidades de dominio
class AuthService {
  final ApiService _apiService;
  final TokenStorage _tokenStorage;

  AuthService({
    ApiService? apiService,
    TokenStorage? tokenStorage,
  })  : _apiService = apiService ?? ApiService(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  /// Iniciar sesión con credenciales
  /// Ruta: POST /api/login/
  /// Datos de negocio: username, password
  /// Retorna: tokens de acceso y refresh
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiService.post(AppConfig.loginEndpoint, {
        'username': username,
        'password': password,
      });

      if (response['success'] && response['data'] != null) {
        final data = response['data'];

        // Validar formato de respuesta
        if (data['access'] != null && data['refresh'] != null) {
          // Guardar tokens usando TokenStorage
          await _tokenStorage.saveTokens(data['access'], data['refresh']);

          return {
            'success': true,
            'access_token': data['access'],
            'refresh_token': data['refresh'],
            'message': 'Inicio de sesión exitoso',
          };
        } else {
          return {
            'success': false,
            'error': 'Formato de respuesta de tokens inválido',
          };
        }
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Credenciales inválidas',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de autenticación: $e',
      };
    }
  }

  /// Registrar nuevo usuario con perfil
  /// Ruta: POST /api/users/
  /// Datos de negocio: User entity + Profile data + password + opcional profile image
  /// Retorna: Usuario creado (el perfil se crea automáticamente)
  Future<Map<String, dynamic>> register(User user, Profile profile, String password, {File? profileImage}) async {
    try {
      // Preparar datos de negocio para la API
      final userData = user.toCreateJson();
      userData['password'] = password;
      userData['user_type'] = profile.userType;
      userData['phone'] = profile.phone;

      final response = await _apiService.post(AppConfig.usersEndpoint, userData);

      if (response['success'] && response['data'] != null) {
        // Convertir respuesta JSON a entidad de dominio
        final createdUser = User.fromJson(response['data']);

        // Si se proporcionó una imagen de perfil, subirla después del registro
        if (profileImage != null) {
          // Obtener el perfil creado para obtener su ID
          final profileResponse = await _apiService.get(AppConfig.currentProfileEndpoint);
          if (profileResponse['success'] && profileResponse['data'] != null) {
            final createdProfile = Profile.fromJson(profileResponse['data']);

            // Subir la imagen de perfil
            final imageResponse = await _apiService.uploadFile(
              '${AppConfig.profilesEndpoint}${createdProfile.id}/',
              'profile_picture',
              profileImage,
              method: 'PATCH',
            );

            if (!imageResponse['success']) {
              // Si falla la subida de imagen, aún consideramos el registro exitoso
              print('Advertencia: No se pudo subir la imagen de perfil: ${imageResponse['error']}');
            }
          }
        }

        return {
          'success': true,
          'user': createdUser,
          'message': 'Usuario registrado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al crear usuario',
          'errors': response['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de registro: $e',
      };
    }
  }

  /// Obtener usuario actual autenticado
  /// Ruta: GET /api/users/me/
  /// Retorna: User entity del usuario actual
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiService.get(AppConfig.currentUserEndpoint);

      if (response['success'] && response['data'] != null) {
        // Convertir respuesta JSON a entidad de dominio
        final currentUser = User.fromJson(response['data']);

        return {
          'success': true,
          'user': currentUser,
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al obtener usuario actual',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo usuario: $e',
      };
    }
  }

  /// Cerrar sesión
  /// Ruta: POST /api/logout/
  /// Limpia tokens locales independientemente del resultado de la API
  Future<Map<String, dynamic>> logout() async {
    try {
      // Intentar notificar al servidor sobre el logout
      await _apiService.post(AppConfig.logoutEndpoint, {});
    } catch (e) {
      // Continuar con logout local aunque falle la API
    } finally {
      // Siempre limpiar tokens locales
      await _tokenStorage.clearTokens();
      await _apiService.clearAuthToken();
    }

    return {
      'success': true,
      'message': 'Sesión cerrada exitosamente',
    };
  }

  /// Verificar si el usuario está autenticado
  /// Verifica la existencia y validez del token local
  Future<bool> isAuthenticated() async {
    final accessToken = await _tokenStorage.getAccessToken();
    return accessToken != null && await _tokenStorage.isTokenValid();
  }

  /// Inicializar autenticación al arrancar la app
  /// Restaura el estado de autenticación desde el almacenamiento local
  Future<void> initializeAuth() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null && await _tokenStorage.isTokenValid()) {
      // El token será añadido automáticamente por el interceptor de ApiService
      // No necesitamos hacer nada más aquí
    }
  }
}
