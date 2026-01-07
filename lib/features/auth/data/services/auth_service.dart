import 'dart:io';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
          print(
              'AuthService: Tokens encontrados en data - access: ${data['access']?.substring(0, 20)}..., refresh: ${data['refresh']?.substring(0, 20)}...');
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
          print(
              'AuthService: Formato de respuesta de tokens inválido - data: $data');
          return {
            'success': false,
            'error': 'Formato de respuesta de tokens inválido',
            'data': null,
          };
        }
      } else {
        print(
            'AuthService: Login falló - success: ${response['success']}, data: ${response['data']}');
        return {
          'success': false,
          'error': response['error'] ??
              response['message'] ??
              'Credenciales inválidas',
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

  /// Login con Google usando google_sign_in y backend dj-rest-auth
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final googleSignIn = gsi.GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) {
        return {'success': false, 'error': 'Inicio de sesión cancelado'};
      }
      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        return {'success': false, 'error': 'Google no entregó access_token'};
      }
      final url =
          '${AppConfig.socialBaseUrl()}${AppConfig.socialGoogleEndpoint}';
      final payload = {
        'access_token': accessToken,
      };
      final response = await _apiService.post(url, payload);
      return _handleSocialLoginResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error en login con Google: $e',
      };
    }
  }

  /// Login con Facebook usando flutter_facebook_auth y backend dj-rest-auth
  Future<Map<String, dynamic>> loginWithFacebook() async {
    try {
      final result = await FacebookAuth.instance
          .login(permissions: ['email', 'public_profile']);
      if (result.status != LoginStatus.success) {
        return {
          'success': false,
          'error': 'No se pudo iniciar sesión en Facebook'
        };
      }
      final accessToken = result.accessToken?.tokenString;
      final url =
          '${AppConfig.socialBaseUrl()}${AppConfig.socialFacebookEndpoint}';
      final payload = {
        if (accessToken != null) 'access_token': accessToken,
      };
      final response = await _apiService.post(url, payload);
      return _handleSocialLoginResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error en login con Facebook: $e',
      };
    }
  }

  /// Login con Apple (solo iOS) usando sign_in_with_apple y backend dj-rest-auth
  Future<Map<String, dynamic>> loginWithApple() async {
    try {
      if (!Platform.isIOS) {
        return {
          'success': false,
          'error': 'Apple Sign-In solo disponible en iOS'
        };
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName
        ],
      );
      final identityToken = credential.identityToken;
      final url =
          '${AppConfig.socialBaseUrl()}${AppConfig.socialAppleEndpoint}';
      if (identityToken == null || identityToken.isEmpty) {
        return {'success': false, 'error': 'Apple no entregó id_token'};
      }
      final payload = {
        'id_token': identityToken,
      };
      final response = await _apiService.post(url, payload);
      return _handleSocialLoginResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error en login con Apple: $e',
      };
    }
  }

  /// Maneja respuesta del backend de login social y guarda tokens
  Map<String, dynamic> _handleSocialLoginResponse(
      Map<String, dynamic> response) {
    try {
      if (response['success'] && response['data'] != null) {
        final envelope = response['data'];
        Map<String, dynamic> data;
        if (envelope is Map && envelope['data'] is Map) {
          data = Map<String, dynamic>.from(envelope['data'] as Map);
        } else if (envelope is Map) {
          data = Map<String, dynamic>.from(envelope);
        } else {
          data = {};
        }

        final access = data['access'] ?? data['access_token'];
        final refresh = data['refresh'] ?? data['refresh_token'];
        if (access is String && refresh is String) {
          _tokenStorage.saveTokens(access, refresh);
          return {
            'success': true,
            'data': {
              'access_token': access,
              'refresh_token': refresh,
            },
            'message': response['message'] ?? 'Inicio de sesión exitoso',
          };
        }
        return {
          'success': false,
          'error': 'Formato de respuesta de tokens inválido',
        };
      }
      return {
        'success': false,
        'error': response['error'] ?? 'Error de autenticación social',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error procesando respuesta social: $e',
      };
    }
  }

  /// Registrar nuevo usuario con perfil
  /// Ruta: POST /api/users/
  /// Datos de negocio: User entity + Profile data + password + opcional profile image
  /// Retorna: Usuario creado (el perfil se crea automáticamente)
  Future<Map<String, dynamic>> register(
      User user, Profile profile, String password,
      {File? profileImage}) async {
    try {
      // Preparar datos de negocio para la API
      final userData = user.toCreateJson();
      userData['password'] = password;
      userData['user_type'] = profile.userType;
      userData['phone'] = profile.phone;

      final response =
          await _apiService.post(AppConfig.usersEndpoint, userData);

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
          final profileResponse =
              await _apiService.get(AppConfig.currentProfileEndpoint);
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
              print(
                  'Advertencia: No se pudo subir la imagen de perfil: ${imageResponse['error']}');
            }
          }
        }

        return {
          'success': true,
          'data': createdUser,
          'message': (envelope is Map ? envelope['message'] : null) ??
              response['message'] ??
              'Usuario registrado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ??
              response['message'] ??
              'Error al crear usuario',
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
          'message': (envelope is Map ? envelope['message'] : null) ??
              response['message'] ??
              'Usuario obtenido exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ??
              response['message'] ??
              'Error al obtener usuario actual',
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
  /// Si el token expiró pero existe refresh token, intenta refrescar la sesión
  Future<bool> isAuthenticated() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null) return false;

    // 1. Verificar si el token es válido localmente (no expirado)
    if (await _tokenStorage.isTokenValid()) {
      return true;
    }

    // 2. Si expiró, verificar si tenemos refresh token
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      print(
          'AuthService: Token expirado localmente, intentando refrescar sesión...');

      // 3. Intentar validar sesión haciendo una petición autenticada.
      // Si el token está expirado, ApiService interceptará el 401
      // e intentará usar el refresh token automáticamente.
      final result = await getCurrentUser();

      if (result['success']) {
        print('AuthService: Sesión recuperada exitosamente vía refresh');
        return true;
      } else {
        print(
            'AuthService: Falló la recuperación de sesión: ${result['error']}');
      }
    }

    return false;
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
