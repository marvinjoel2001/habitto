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
      print('AuthService: Iniciando login para usuario: $username');
      // Payload de login según documentación: username + password
      final payload = {
        'username': username,
        'password': password,
      };

      // Único endpoint soportado: /api/login/
      final response = await _apiService.post(AppConfig.loginEndpoint, payload);

      print('AuthService: Respuesta completa del login: $response');

      if (response['success'] && response['data'] != null) {
        final envelope = response['data'];
        print('AuthService: Respuesta del backend (envelope): $envelope');

        // La API devuelve { success, message, data: { access, refresh } }
        // Evitamos el uso de generics en 'is' para compatibilidad del analizador.
        Map<String, dynamic> data;
        if (envelope is Map && envelope['data'] is Map) {
          data = Map<String, dynamic>.from(envelope['data'] as Map);
        } else if (envelope is Map) {
          data = Map<String, dynamic>.from(envelope);
        } else {
          data = {};
        }

        // Validar formato de respuesta
        if (data['access'] != null && data['refresh'] != null) {
          print('AuthService: Tokens encontrados en data - access: ${data['access']?.substring(0, 20)}..., refresh: ${data['refresh']?.substring(0, 20)}...');
          // Guardar tokens usando TokenStorage
          await _tokenStorage.saveTokens(data['access'], data['refresh']);
          print('AuthService: Tokens guardados exitosamente');
          await _tokenStorage.setHasLoggedOnce(true);

          return {
            'success': true,
            'data': {
              'access_token': data['access'],
              'refresh_token': data['refresh'],
            },
            'message': response['message'] ?? 'Inicio de sesión exitoso',
          };
        } else {
          print('AuthService: Formato de respuesta de tokens inválido - data: $data');
          return {
            'success': false,
            'error': 'Formato de respuesta de tokens inválido',
            'data': null,
          };
        }
      } else {
        print('AuthService: Login falló - success: ${response['success']}, data: ${response['data']}');
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Credenciales inválidas',
          'data': null,
        };
      }
    } catch (e) {
      print('AuthService: Excepción durante login: $e');
      return {
        'success': false,
        'error': 'Error de autenticación: $e',
        'data': null,
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
        // La API devuelve un envelope { success, message, data: {...} }
        final envelope = response['data'];
        Map<String, dynamic> data;
        if (envelope is Map && envelope['data'] is Map) {
          data = Map<String, dynamic>.from(envelope['data'] as Map);
        } else if (envelope is Map) {
          data = Map<String, dynamic>.from(envelope);
        } else {
          data = {};
        }

        // Convertir respuesta JSON a entidad de dominio usando el contenido de data
        final createdUser = User.fromJson(data);

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
          'data': createdUser,
          'message': (envelope is Map ? envelope['message'] : null) ?? response['message'] ?? 'Usuario registrado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al crear usuario',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de registro: $e',
        'data': null,
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
        // Manejar envelope { success, message, data }
        final envelope = response['data'];
        Map<String, dynamic> data;
        if (envelope is Map && envelope['data'] is Map) {
          data = Map<String, dynamic>.from(envelope['data'] as Map);
        } else if (envelope is Map) {
          data = Map<String, dynamic>.from(envelope);
        } else {
          data = {};
        }

        // Convertir respuesta JSON a entidad de dominio
        final currentUser = User.fromJson(data);

        return {
          'success': true,
          'data': currentUser,
          'message': (envelope is Map ? envelope['message'] : null) ?? response['message'] ?? 'Usuario obtenido exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener usuario actual',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo usuario: $e',
        'data': null,
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
      'data': null,
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
