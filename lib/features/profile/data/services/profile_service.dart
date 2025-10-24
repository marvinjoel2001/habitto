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
      final response = await _apiService.get(AppConfig.currentProfileEndpoint);

      if (response['success'] && response['data'] != null) {
        final userProfile = response['data'];

        // Convertir respuestas JSON a entidades de dominio
        final profile = Profile.fromJson(userProfile);
        final user = User.fromJson(userProfile['user']);

        return {
          'success': true,
          'profile': profile,
          'user': user,
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al obtener el perfil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo perfil: $e',
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
          'profile': profile,
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al obtener perfil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo perfil: $e',
      };
    }
  }

  /// Actualizar perfil del usuario actual
  /// Ruta: PUT/PATCH /api/profiles/update_me/
  /// Datos de negocio: Datos del perfil a actualizar
  /// Retorna: Profile entity actualizado
  Future<Map<String, dynamic>> updateCurrentProfile(Map<String, dynamic> profileData, {File? profileImage}) async {
    try {
      Map<String, dynamic> response;

      if (profileImage != null) {
        // Si hay imagen, usar multipart/form-data
        final additionalFields = <String, String>{};
        profileData.forEach((key, value) {
          additionalFields[key] = value.toString();
        });

        response = await _apiService.uploadFile(
          AppConfig.updateProfileEndpoint,
          'profile_picture',
          profileImage,
          method: 'PATCH',
          additionalFields: additionalFields,
        );
      } else {
        // Si no hay imagen, usar JSON
        response = await _apiService.patch(
          AppConfig.updateProfileEndpoint,
          profileData,
        );
      }

      if (response['success'] && response['data'] != null) {
        // Convertir respuesta JSON a entidad de dominio
        final updatedProfile = Profile.fromJson(response['data']);

        return {
          'success': true,
          'profile': updatedProfile,
          'message': 'Perfil actualizado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al actualizar perfil',
          'errors': response['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizando perfil: $e',
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
        // Convertir respuesta JSON a entidad de dominio
        final updatedProfile = Profile.fromJson(response['data']);

        return {
          'success': true,
          'profile': updatedProfile,
          'message': 'Imagen de perfil actualizada exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al actualizar imagen de perfil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizando imagen: $e',
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
          'profile': updatedProfile,
          'message': 'Perfil actualizado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al actualizar perfil',
          'errors': response['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizando perfil: $e',
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
          'message': 'Perfil verificado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al verificar perfil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error verificando perfil: $e',
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

      final Profile currentProfile = currentProfileResult['profile'];
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

      final Profile currentProfile = currentProfileResult['profile'];
      final List<int> favorites = List<int>.from(currentProfile.favorites ?? []);

      // Lógica de negocio: Remover de favoritos
      favorites.remove(propertyId);

      // Actualizar perfil con favoritos actualizados
      return await updateProfile(profileId, {'favorites': favorites});
    } catch (e) {
      return {
        'success': false,
        'error': 'Error removiendo de favoritos: $e',
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
          'profile': updatedProfile,
          'message': 'Imagen de perfil actualizada exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al actualizar imagen de perfil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizando imagen: $e',
      };
    }
  }
}
