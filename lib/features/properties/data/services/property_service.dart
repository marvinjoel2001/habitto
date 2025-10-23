import '../../../../config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/token_storage.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/amenity.dart';

/// Servicio de propiedades - Capa de negocio
/// Responsabilidad: Implementar la lógica de negocio para propiedades
/// - Conoce las rutas de la API específicas de propiedades
/// - Maneja la serialización de datos de negocio
/// - Convierte respuestas JSON a entidades de dominio
class PropertyService {
  final ApiService _apiService;
  final TokenStorage _tokenStorage;

  PropertyService({
    ApiService? apiService,
    TokenStorage? tokenStorage,
  })  : _apiService = apiService ?? ApiService(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  /// Obtener todas las amenidades
  /// Ruta: GET /api/amenities/
  /// Retorna: Lista de Amenity entities
  Future<Map<String, dynamic>> getAmenities() async {
    try {
      final response = await _apiService.get(AppConfig.amenitiesEndpoint);

      if (response['success'] && response['data'] != null) {
        final results = response['data']['results'] as List;

        // Convertir respuesta JSON a entidades de dominio
        final amenities = results.map((amenity) => Amenity.fromJson(amenity)).toList();

        return {
          'success': true,
          'amenities': amenities,
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al obtener amenidades',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo amenidades: $e',
      };
    }
  }

  /// Obtener métodos de pago
  /// Ruta: GET /api/payment-methods/
  /// Retorna: Lista de métodos de pago disponibles
  Future<Map<String, dynamic>> getPaymentMethods() async {
    try {
      final response = await _apiService.get('/api/payment-methods/');

      if (response['success'] && response['data'] != null) {
        final results = response['data']['results'] as List;

        return {
          'success': true,
          'payment_methods': results,
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al obtener métodos de pago',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo métodos de pago: $e',
      };
    }
  }

  /// Crear nueva propiedad
  /// Ruta: POST /api/properties/
  /// Datos de negocio: Información completa de la propiedad
  /// Retorna: Property entity creada
  Future<Map<String, dynamic>> createProperty(Map<String, dynamic> propertyData) async {
    try {
      final response = await _apiService.post(AppConfig.propertiesEndpoint, propertyData);

      if (response['success'] && response['data'] != null) {
        // Convertir respuesta JSON a entidad de dominio
        final property = Property.fromJson(response['data']);

        return {
          'success': true,
          'property': property,
          'message': 'Propiedad creada exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al crear propiedad',
          'errors': response['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error creando propiedad: $e',
      };
    }
  }

  /// Obtener lista de propiedades con filtros
  /// Ruta: GET /api/properties/ con parámetros de consulta
  /// Lógica de negocio: Construir parámetros de filtrado y paginación
  /// Retorna: Lista paginada de Property entities
  Future<Map<String, dynamic>> getProperties({
    String? type,
    bool? isActive,
    int? owner,
    String? search,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Lógica de negocio: Construir parámetros de consulta
      final queryParams = <String, String>{};

      if (type != null) queryParams['type'] = type;
      if (isActive != null) queryParams['is_active'] = isActive.toString();
      if (owner != null) queryParams['owner'] = owner.toString();
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;
      queryParams['page'] = page.toString();
      queryParams['page_size'] = pageSize.toString();

      // Construir URL con parámetros de consulta
      final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.propertiesEndpoint}')
          .replace(queryParameters: queryParams);

      final response = await _apiService.get(uri.toString().replaceFirst(AppConfig.baseUrl, ''));

      if (response['success'] && response['data'] != null) {
        final results = response['data']['results'] as List;

        // Convertir respuestas JSON a entidades de dominio
        final properties = results.map((property) => Property.fromJson(property)).toList();

        return {
          'success': true,
          'properties': properties,
          'count': response['data']['count'],
          'next': response['data']['next'],
          'previous': response['data']['previous'],
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al obtener propiedades',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo propiedades: $e',
      };
    }
  }

  /// Obtener propiedad por ID
  /// Ruta: GET /api/properties/{id}/
  /// Datos de negocio: ID de la propiedad
  /// Retorna: Property entity
  Future<Map<String, dynamic>> getPropertyById(int propertyId) async {
    try {
      final response = await _apiService.get('${AppConfig.propertiesEndpoint}$propertyId/');

      if (response['success'] && response['data'] != null) {
        // Convertir respuesta JSON a entidad de dominio
        final property = Property.fromJson(response['data']);

        return {
          'success': true,
          'property': property,
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al obtener propiedad',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo propiedad: $e',
      };
    }
  }

  /// Actualizar propiedad
  /// Ruta: PUT /api/properties/{id}/
  /// Datos de negocio: ID de la propiedad y datos a actualizar
  /// Retorna: Property entity actualizada
  Future<Map<String, dynamic>> updateProperty(int propertyId, Map<String, dynamic> propertyData) async {
    try {
      final response = await _apiService.put('${AppConfig.propertiesEndpoint}$propertyId/', propertyData);

      if (response['success'] && response['data'] != null) {
        // Convertir respuesta JSON a entidad de dominio
        final property = Property.fromJson(response['data']);

        return {
          'success': true,
          'property': property,
          'message': 'Propiedad actualizada exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al actualizar propiedad',
          'errors': response['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizando propiedad: $e',
      };
    }
  }

  /// Eliminar propiedad
  /// Ruta: DELETE /api/properties/{id}/
  /// Datos de negocio: ID de la propiedad
  /// Retorna: Mensaje de confirmación
  Future<Map<String, dynamic>> deleteProperty(int propertyId) async {
    try {
      final response = await _apiService.delete('${AppConfig.propertiesEndpoint}$propertyId/');

      if (response['success']) {
        return {
          'success': true,
          'message': 'Propiedad eliminada exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al eliminar propiedad',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error eliminando propiedad: $e',
      };
    }
  }

  /// Obtener propiedades del usuario actual
  /// Lógica de negocio: Filtrar propiedades por propietario actual
  /// Retorna: Lista de Property entities del usuario
  Future<Map<String, dynamic>> getMyProperties({
    String? type,
    bool? isActive,
    String? search,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Lógica de negocio: Obtener ID del usuario actual desde el token
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      // Usar el método getProperties con filtro de propietario
      return await getProperties(
        type: type,
        isActive: isActive,
        search: search,
        ordering: ordering,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo mis propiedades: $e',
      };
    }
  }

  /// Activar/Desactivar propiedad
  /// Ruta: PATCH /api/properties/{id}/
  /// Lógica de negocio: Cambiar estado de activación de la propiedad
  /// Datos de negocio: ID de la propiedad y nuevo estado
  Future<Map<String, dynamic>> togglePropertyStatus(int propertyId, bool isActive) async {
    try {
      final response = await _apiService.patch(
        '${AppConfig.propertiesEndpoint}$propertyId/',
        {'is_active': isActive},
      );

      if (response['success'] && response['data'] != null) {
        // Convertir respuesta JSON a entidad de dominio
        final property = Property.fromJson(response['data']);

        return {
          'success': true,
          'property': property,
          'message': isActive ? 'Propiedad activada' : 'Propiedad desactivada',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Error al cambiar estado de propiedad',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error cambiando estado: $e',
      };
    }
  }
}
