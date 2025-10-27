import 'dart:io';
import '../../../../core/services/api_service.dart';
import '../../../../config/app_config.dart';
import '../../domain/entities/photo.dart';

/// Servicio para gestionar las fotos de propiedades
/// Maneja la lógica de negocio relacionada con las fotos
class PhotoService {
  final ApiService _apiService;

  PhotoService(this._apiService);

  /// Obtener fotos de una propiedad específica
  /// Ruta: GET /api/photos/?property={propertyId}
  /// Datos de negocio: Lista de fotos de la propiedad
  /// Retorna: Lista de Photo entities
  Future<Map<String, dynamic>> getPropertyPhotos(int propertyId) async {
    try {
      final response = await _apiService.get('${AppConfig.photosEndpoint}?property=$propertyId');

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> photosJson = response['data']['results'] ?? [];
        final List<Photo> photos = photosJson.map((json) => Photo.fromJson(json)).toList();

        return {
          'success': true,
          'data': {
            'photos': photos,
            'count': response['data']['count'] ?? 0,
          },
          'message': response['message'] ?? 'Fotos obtenidas exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener fotos',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo fotos: $e',
        'data': null,
      };
    }
  }

  /// Subir nueva foto para una propiedad
  /// Ruta: POST /api/photos/
  /// Datos de negocio: Archivo de imagen y datos de la foto
  /// Retorna: Photo entity creada
  Future<Map<String, dynamic>> uploadPropertyPhoto({
    required int propertyId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      // Preparar campos adicionales para el formulario
      final Map<String, String> formData = {
        'property': propertyId.toString(),
      };

      if (caption != null && caption.isNotEmpty) {
        formData['caption'] = caption;
      }

      final response = await _apiService.uploadFile(
        AppConfig.photosEndpoint,
        'image', // fieldName para el archivo
        imageFile,
        additionalFields: formData,
      );

      if (response['success'] == true && response['data'] != null) {
        final photo = Photo.fromJson(response['data']);

        return {
          'success': true,
          'data': photo,
          'message': response['message'] ?? 'Foto subida exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al subir foto',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error subiendo foto: $e',
        'data': null,
      };
    }
  }

  /// Actualizar caption de una foto
  /// Ruta: PATCH /api/photos/{photoId}/
  /// Datos de negocio: Nuevo caption para la foto
  /// Retorna: Photo entity actualizada
  Future<Map<String, dynamic>> updatePhotoCaption(int photoId, String caption) async {
    try {
      final response = await _apiService.patch('${AppConfig.photosEndpoint}$photoId/', {
        'caption': caption,
      });

      if (response['success'] == true && response['data'] != null) {
        final photo = Photo.fromJson(response['data']);

        return {
          'success': true,
          'data': photo,
          'message': response['message'] ?? 'Caption actualizado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al actualizar caption',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizando caption: $e',
        'data': null,
      };
    }
  }

  /// Eliminar una foto
  /// Ruta: DELETE /api/photos/{photoId}/
  /// Datos de negocio: ID de la foto a eliminar
  /// Retorna: Confirmación de eliminación
  Future<Map<String, dynamic>> deletePhoto(int photoId) async {
    try {
      final response = await _apiService.delete('${AppConfig.photosEndpoint}$photoId/');

      if (response['success'] == true) {
        return {
          'success': true,
          'data': null,
          'message': response['message'] ?? 'Foto eliminada exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al eliminar foto',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error eliminando foto: $e',
        'data': null,
      };
    }
  }
}