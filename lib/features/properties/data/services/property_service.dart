import '../../../../config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/token_storage.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/amenity.dart';
import '../../domain/entities/payment_method.dart';

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
        // Desenvolver posibles envolturas de 'data'
        final envelope = response['data'];
        final inner = (envelope is Map && envelope['data'] != null)
            ? envelope['data']
            : envelope;

        // Extraer lista de resultados
        final results = (inner is Map && inner['results'] is List)
            ? inner['results'] as List
            : (inner is List)
                ? inner
                : <dynamic>[];

        // Convertir respuesta JSON a entidades de dominio
        final amenities = results.map((amenity) => Amenity.fromJson(amenity)).toList();

        return {
          'success': true,
          'data': amenities,
          'message': response['message'] ?? 'Amenidades obtenidas exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener amenidades',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo amenidades: $e',
        'data': null,
      };
    }
  }

  /// Obtener métodos de pago disponibles
  /// Ruta: GET /api/payment-methods/
  /// Retorna: Lista de métodos de pago
  Future<Map<String, dynamic>> getPaymentMethods() async {
    try {
      print('PropertyService: Iniciando getPaymentMethods()');
      final response = await _apiService.get('/api/payment-methods/');
      
      print('PropertyService: Respuesta completa de payment-methods: $response');

      if (response['success'] && response['data'] != null) {
        print('PropertyService: Datos de payment-methods: ${response['data']}');

        // Desenvolver posibles envolturas de 'data'
        final envelope = response['data'];
        final inner = (envelope is Map && envelope['data'] != null)
            ? envelope['data']
            : envelope;

        // Extraer lista de resultados
        final results = (inner is Map && inner['results'] is List)
            ? inner['results'] as List
            : (inner is List)
                ? inner
                : <dynamic>[];

        print('PropertyService: Payment methods extraídos (lista): $results');

        return {
          'success': true,
          'payment_methods': results,
          'message': response['message'] ?? 'Métodos de pago obtenidos exitosamente',
        };
      } else {
        print('PropertyService: Error en respuesta: ${response['error'] ?? response['message']}');
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener métodos de pago',
          'data': null,
        };
      }
    } catch (e) {
      print('PropertyService: Excepción en getPaymentMethods: $e');
      return {
        'success': false,
        'error': 'Error obteniendo métodos de pago: $e',
        'data': null,
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

      if (response['success'] == true && response['data'] != null) {
        // Convertir respuesta JSON a entidad de dominio
        final property = Property.fromJson(response['data']);

        return {
          'success': true,
          'data': property,
          'message': 'Propiedad creada exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al crear propiedad',
          'data': null,
          'errors': response['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error creando propiedad: $e',
        'data': null,
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
          'data': {
            'properties': properties,
            'count': response['data']['count'],
            'next': response['data']['next'],
            'previous': response['data']['previous'],
          },
          'message': response['message'] ?? 'Propiedades obtenidas exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener propiedades',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo propiedades: $e',
        'data': null,
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
          'data': property,
          'message': response['message'] ?? 'Propiedad obtenida exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener propiedad',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo propiedad: $e',
        'data': null,
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
          'data': property,
          'message': response['message'] ?? 'Propiedad actualizada exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al actualizar propiedad',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizando propiedad: $e',
        'data': null,
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
          'data': null,
          'message': response['message'] ?? 'Propiedad eliminada exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al eliminar propiedad',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error eliminando propiedad: $e',
        'data': null,
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
          'data': null,
        };
      }

      // Obtener el ID del usuario actual
      final currentUserId = await _tokenStorage.getCurrentUserId();
      if (currentUserId == null) {
        return {
          'success': false,
          'error': 'No se pudo obtener el ID del usuario',
          'data': null,
        };
      }

      // Usar el método getProperties con filtro de propietario
      return await getProperties(
        type: type,
        owner: int.tryParse(currentUserId),
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
        'data': null,
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
          'data': property,
          'message': response['message'] ?? (isActive ? 'Propiedad activada' : 'Propiedad desactivada'),
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al cambiar estado de propiedad',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error cambiando estado: $e',
        'data': null,
      };
    }
  }

  /// Crear nuevo método de pago
  /// Ruta: POST /api/payment-methods/
  /// Datos de negocio: Información del método de pago
  /// Retorna: PaymentMethod entity creado
  Future<Map<String, dynamic>> createPaymentMethod(Map<String, dynamic> paymentMethodData) async {
    try {
      print('PropertyService: Iniciando createPaymentMethod()');
      final response = await _apiService.post('/api/payment-methods/', paymentMethodData);
      
      print('PropertyService: Respuesta completa de crear payment-method: $response');

      if (response['success'] == true && response['data'] != null) {
        // Convertir respuesta JSON a entidad de dominio
        final paymentMethod = PaymentMethod.fromJson(response['data']);

        return {
          'success': true,
          'data': paymentMethod,
          'message': response['message'] ?? 'Método de pago creado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al crear método de pago',
          'data': null,
          'errors': response['errors'] ?? {},
        };
      }
    } catch (e) {
      print('PropertyService: Excepción en createPaymentMethod: $e');
      return {
        'success': false,
        'error': 'Error creando método de pago: $e',
        'data': null,
      };
    }
  }
}
