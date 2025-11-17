import 'dart:io';
import '../../../../config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/token_storage.dart';
import '../../domain/entities/profile.dart';
import '../../../auth/domain/entities/user.dart';

/// Servicio de perfil - Capa de negocio
/// Responsabilidad: Implementar la lógica de negocio para perfiles de usuario
/// - Conoce las rutas de la API específicas de perfiles
/// - Maneja la serialización de datos de negocio
/// - Convierte respuestas JSON a entidades de dominio
class ProfileService {
  final ApiService _apiService;
  final TokenStorage _tokenStorage;

  ProfileService({
    ApiService? apiService,
    TokenStorage? tokenStorage,
  })  : _apiService = apiService ?? ApiService(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  /// Obtener perfil del usuario actual
  /// Ruta: GET /api/profiles/me/
  /// Retorna: Profile entity y User entity del usuario actual
  Future<Map<String, dynamic>> getCurrentProfile() async {
    try {
      print('ProfileService: Iniciando getCurrentProfile()');
      final response = await _apiService.get(AppConfig.currentProfileEndpoint);
      
      print('ProfileService: Respuesta recibida: $response');

      if (response['success'] && response['data'] != null) {
        // La API puede envolver los datos como { success, message, data: { ...perfil } }
        final envelope = response['data'];
        // Si existe envelope['data'], úsalo; de lo contrario, el envelope ya es el perfil
        final userProfile = envelope is Map && envelope['data'] is Map
            ? Map<String, dynamic>.from(envelope['data'] as Map)
            : envelope is Map
                ? Map<String, dynamic>.from(envelope)
                : null;
        print('ProfileService: Datos del perfil extraídos: $userProfile');

        if (userProfile != null) {
          // Convertir respuestas JSON a entidades de dominio
          print('ProfileService: Creando Profile.fromJson...');
          final profile = Profile.fromJson(userProfile);
          print('ProfileService: Profile creado exitosamente: ${profile.toString()}');
          
          // El usuario ya está incluido en el perfil, no necesitamos extraerlo por separado
          final user = profile.user;
          print('ProfileService: Usuario extraído del perfil: ${user.toString()}');

          return {
            'success': true,
            'data': {
              'profile': profile,
              'user': user,
            },
            'message': response['message'] ?? 'Perfil obtenido exitosamente',
          };
        } else {
          print('ProfileService: Error - userProfile es null');
          return {
            'success': false,
            'error': 'Datos del perfil no encontrados en la respuesta',
            'data': null,
          };
        }
      } else {
        print('ProfileService: Error en respuesta - success: ${response['success']}, data: ${response['data']}');
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener perfil',
          'data': null,
        };
      }
    } catch (e, stackTrace) {
      print('ProfileService: Error capturado: $e');
      print('ProfileService: Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Error obteniendo perfil: $e',
        'data': null,
      };
    }
  }

  /// Obtener perfil por ID
  /// Ruta: GET /api/profiles/{id}/
  /// Datos de negocio: ID del perfil
  /// Retorna: Profile entity
  Future<Map<String, dynamic>> getProfileById(int profileId) async {
    try {
      final response = await _apiService.get('${AppConfig.profilesEndpoint}$profileId/');

      if (response['success'] && response['data'] != null) {
        // Convertir respuesta JSON a entidad de dominio
        final profile = Profile.fromJson(response['data']);

        return {
          'success': true,
          'data': profile,
          'message': response['message'] ?? 'Perfil obtenido exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener perfil',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo perfil: $e',
        'data': null,
      };
    }
  }

  /// Obtener perfil por user_id
  /// Ruta: GET /api/profiles/?user_id=<id>
  /// Retorna: Primer Profile correspondiente al usuario
  Future<Map<String, dynamic>> getProfileByUserId(int userId) async {
    try {
      final response = await _apiService.get(AppConfig.profilesEndpoint, queryParameters: {'user_id': userId});

      if (response['success'] && response['data'] != null) {
        final envelope = response['data'];
        List<dynamic> results = [];
        if (envelope is Map && envelope['data'] is Map && (envelope['data'] as Map)['results'] is List) {
          results = List<dynamic>.from((envelope['data'] as Map)['results'] as List);
        } else if (envelope is Map && envelope['results'] is List) {
          results = List<dynamic>.from(envelope['results'] as List);
        } else if (envelope is List) {
          results = List<dynamic>.from(envelope);
        }

        if (results.isNotEmpty) {
          final profile = Profile.fromJson(Map<String, dynamic>.from(results.first as Map));
          return {
            'success': true,
            'data': profile,
            'message': response['message'] ?? 'Perfil obtenido exitosamente',
          };
        }

        return {
          'success': false,
          'error': 'No se encontró perfil para el usuario',
          'data': null,
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener perfil por usuario',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo perfil por usuario: $e',
        'data': null,
      };
    }
  }

  /// Actualizar perfil del usuario actual
  /// Ruta: PUT/PATCH /api/profiles/update_me/
  /// Datos de negocio: Datos del perfil a actualizar
  /// Retorna: Profile entity actualizado
  Future<Map<String, dynamic>> updateCurrentProfile(Map<String, dynamic> profileData, {File? profileImage}) async {
    try {
      Profile? lastProfile;

      // 1) Si hay imagen, usar el endpoint dedicado de subida de foto.
      if (profileImage != null) {
        final uploadResult = await uploadCurrentProfilePicture(profileImage);
        if (!uploadResult['success']) {
          return {
            'success': false,
            'error': uploadResult['error'] ?? 'Error al subir imagen de perfil',
            'data': null,
          };
        }
        lastProfile = uploadResult['data'] as Profile?;
      }

      // 2) Actualizar el resto de datos usando PATCH JSON al endpoint update_me
      final response = await _apiService.patch(
        AppConfig.updateProfileEndpoint,
        profileData,
      );

      if (response['success'] && response['data'] != null) {
        // La API puede responder como { success, message, data: { ...perfil } } o directamente { ...perfil }
        final envelope = response['data'];
        final profileJson = envelope is Map && envelope['data'] is Map
            ? Map<String, dynamic>.from(envelope['data'] as Map)
            : envelope is Map
                ? Map<String, dynamic>.from(envelope)
                : <String, dynamic>{};

        // Si no vino el perfil en esta respuesta, usar el último perfil de la subida
        final updatedProfile = profileJson.isNotEmpty
            ? Profile.fromJson(profileJson)
            : lastProfile;

        if (updatedProfile == null) {
          return {
            'success': false,
            'error': 'Respuesta del servidor inválida al actualizar el perfil',
            'data': null,
          };
        }

        return {
          'success': true,
          'data': updatedProfile,
          'message': response['message'] ?? 'Perfil actualizado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al actualizar perfil',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizando perfil: $e',
        'data': null,
      };
    }
  }

  /// Subir imagen de perfil del usuario actual
  /// Ruta: POST /api/profiles/upload_profile_picture/
  /// Datos de negocio: Archivo de imagen
  /// Retorna: Profile entity actualizado
  Future<Map<String, dynamic>> uploadCurrentProfilePicture(File imageFile) async {
    try {
      final response = await _apiService.uploadFile(
        AppConfig.uploadProfilePictureEndpoint,
        'profile_picture',
        imageFile,
        method: 'POST',
      );

      if (response['success'] && response['data'] != null) {
        // La API puede devolver { success, message, data: { ...perfil } } o el perfil directamente
        final envelope = response['data'];
        final profileJson = envelope is Map && envelope['data'] is Map
            ? Map<String, dynamic>.from(envelope['data'] as Map)
            : envelope is Map
                ? Map<String, dynamic>.from(envelope)
                : <String, dynamic>{};

        if (profileJson.isEmpty) {
          return {
            'success': false,
            'error': 'Respuesta del servidor inválida al subir imagen de perfil',
            'data': null,
          };
        }

        final updatedProfile = Profile.fromJson(profileJson);

        return {
          'success': true,
          'data': updatedProfile,
          'message': response['message'] ?? 'Imagen de perfil actualizada exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al actualizar imagen de perfil',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizando imagen: $e',
        'data': null,
      };
    }
  }

  /// Actualizar perfil
  /// Ruta: PUT /api/profiles/{id}/
  /// Datos de negocio: ID del perfil y datos a actualizar
  /// Retorna: Profile entity actualizado
  Future<Map<String, dynamic>> updateProfile(int profileId, Map<String, dynamic> profileData, {File? profileImage}) async {
    try {
      Map<String, dynamic> response;

      if (profileImage != null) {
        // Si hay imagen, usar multipart/form-data
        final additionalFields = <String, String>{};
        profileData.forEach((key, value) {
          additionalFields[key] = value.toString();
        });

        response = await _apiService.uploadFile(
          '${AppConfig.profilesEndpoint}$profileId/',
          'profile_picture',
          profileImage,
          method: 'PUT',
          additionalFields: additionalFields,
        );
      } else {
        // Si no hay imagen, usar JSON
        response = await _apiService.put(
          '${AppConfig.profilesEndpoint}$profileId/',
          profileData,
        );
      }

      if (response['success'] && response['data'] != null) {
        // Convertir respuesta JSON a entidad de dominio
        final updatedProfile = Profile.fromJson(response['data']);

        return {
          'success': true,
          'data': updatedProfile,
          'message': response['message'] ?? 'Perfil actualizado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al actualizar perfil',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizando perfil: $e',
        'data': null,
      };
    }
  }

  /// Verificar perfil
  /// Ruta: POST /api/profiles/{id}/verify/
  /// Datos de negocio: ID del perfil
  /// Retorna: Mensaje de confirmación
  Future<Map<String, dynamic>> verifyProfile(int profileId) async {
    try {
      final response = await _apiService.post('${AppConfig.profilesEndpoint}$profileId/verify/', {});

      if (response['success']) {
        return {
          'success': true,
          'data': null,
          'message': response['message'] ?? 'Perfil verificado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al verificar perfil',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error verificando perfil: $e',
        'data': null,
      };
    }
  }

  /// Agregar propiedad a favoritos
  /// Lógica de negocio: Obtener favoritos actuales, agregar nuevo ID, actualizar perfil
  /// Datos de negocio: ID del perfil y ID de la propiedad
  Future<Map<String, dynamic>> addToFavorites(int profileId, int propertyId) async {
    try {
      // Obtener perfil actual para obtener favoritos existentes
      final currentProfileResult = await getProfileById(profileId);
      if (!currentProfileResult['success']) {
        return currentProfileResult;
      }

      final Profile currentProfile = currentProfileResult['data'];
      final List<int> favorites = List<int>.from(currentProfile.favorites ?? []);

      // Lógica de negocio: No agregar duplicados
      if (!favorites.contains(propertyId)) {
        favorites.add(propertyId);
      }

      // Actualizar perfil con nuevos favoritos
      return await updateProfile(profileId, {'favorites': favorites});
    } catch (e) {
      return {
        'success': false,
        'error': 'Error agregando a favoritos: $e',
        'data': null,
      };
    }
  }

  /// Remover propiedad de favoritos
  /// Lógica de negocio: Obtener favoritos actuales, remover ID, actualizar perfil
  /// Datos de negocio: ID del perfil y ID de la propiedad
  Future<Map<String, dynamic>> removeFromFavorites(int profileId, int propertyId) async {
    try {
      // Obtener perfil actual para obtener favoritos existentes
      final currentProfileResult = await getProfileById(profileId);
      if (!currentProfileResult['success']) {
        return currentProfileResult;
      }

      final Profile currentProfile = currentProfileResult['data'];
      final List<int> favorites = List<int>.from(currentProfile.favorites ?? []);

      // Lógica de negocio: Remover de favoritos
      favorites.remove(propertyId);

      // Actualizar perfil con favoritos actualizados
      return await updateProfile(profileId, {'favorites': favorites});
    } catch (e) {
      return {
        'success': false,
        'error': 'Error removiendo de favoritos: $e',
        'data': null,
      };
    }
  }

  /// Actualizar imagen de perfil
  /// Ruta: PATCH /api/profiles/{id}/
  /// Datos de negocio: ID del perfil y archivo de imagen
  /// Retorna: Profile entity actualizado
  Future<Map<String, dynamic>> updateProfilePicture(int profileId, File imageFile) async {
    try {
      final response = await _apiService.uploadFile(
        '${AppConfig.profilesEndpoint}$profileId/',
        'profile_picture',
        imageFile,
        method: 'PATCH',
      );

      if (response['success'] && response['data'] != null) {
        // Convertir respuesta JSON a entidad de dominio
        final updatedProfile = Profile.fromJson(response['data']);

        return {
          'success': true,
          'data': updatedProfile,
          'message': response['message'] ?? 'Imagen de perfil actualizada exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al actualizar imagen de perfil',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizando imagen: $e',
        'data': null,
      };
    }
  }

  /// Crear perfil de búsqueda para el usuario actual
  /// Ruta: POST /api/profiles/search-profile/
  /// Datos de negocio: Datos del perfil de búsqueda
  /// Retorna: SearchProfile entity creado
  Future<Map<String, dynamic>> createSearchProfile(Map<String, dynamic> searchProfileData) async {
    try {
      final response = await _apiService.post(
        '/api/search_profiles/',
        searchProfileData,
      );

      if (response['success'] && response['data'] != null) {
        return {
          'success': true,
          'data': response['data'],
          'message': response['message'] ?? 'Perfil de búsqueda creado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al crear perfil de búsqueda',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error creando perfil de búsqueda: $e',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> addFavoriteViaApi(int propertyId) async {
    try {
      final response = await _apiService.post('/api/profiles/add_favorite/', {
        'property_id': propertyId,
      });
      return response['success'] == true
          ? {
              'success': true,
              'data': response['data'],
              'message': response['message'] ?? 'Favorito agregado',
            }
          : {
              'success': false,
              'error': response['error'] ?? response['message'] ?? 'Error al agregar favorito',
              'data': null,
            };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al agregar favorito: $e',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> removeFavoriteViaApi(int propertyId) async {
    try {
      final response = await _apiService.post('/api/profiles/remove_favorite/', {
        'property_id': propertyId,
      });
      return response['success'] == true
          ? {
              'success': true,
              'data': response['data'],
              'message': response['message'] ?? 'Favorito removido',
            }
          : {
              'success': false,
              'error': response['error'] ?? response['message'] ?? 'Error al remover favorito',
              'data': null,
            };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al remover favorito: $e',
        'data': null,
      };
    }
  }
}
