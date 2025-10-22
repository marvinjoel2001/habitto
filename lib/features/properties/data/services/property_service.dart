import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/token_storage.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/amenity.dart';

class PropertyService {
  final ApiService _apiService;
  final TokenStorage _tokenStorage;

  PropertyService({
    ApiService? apiService,
    TokenStorage? tokenStorage,
  })  : _apiService = apiService ?? ApiService(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  /// Get all amenities from the API
  Future<Map<String, dynamic>> getAmenities() async {
    try {
      final response = await _apiService.get(AppConfig.amenitiesEndpoint);

      if (response['success'] && response['data'] != null) {
        final results = response['data']['results'] as List;
        final amenities = results.map((amenity) => Amenity.fromJson(amenity)).toList();
        
        return {
          'success': true,
          'amenities': amenities,
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to get amenities',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Get all payment methods from the API
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
          'error': response['error'] ?? 'Failed to get payment methods',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Create a new property
  Future<Map<String, dynamic>> createProperty(Map<String, dynamic> propertyData) async {
    try {
      final response = await _apiService.post(AppConfig.propertiesEndpoint, propertyData);

      if (response['success'] && response['data'] != null) {
        return {
          'success': true,
          'property': Property.fromJson(response['data']),
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to create property',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Get properties list
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
      final queryParams = <String, String>{};
      
      if (type != null) queryParams['type'] = type;
      if (isActive != null) queryParams['is_active'] = isActive.toString();
      if (owner != null) queryParams['owner'] = owner.toString();
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;
      queryParams['page'] = page.toString();
      queryParams['page_size'] = pageSize.toString();

      final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.propertiesEndpoint}')
          .replace(queryParameters: queryParams);
      
      final response = await _apiService.get(uri.toString().replaceFirst(AppConfig.baseUrl, ''));

      if (response['success'] && response['data'] != null) {
        final results = response['data']['results'] as List;
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
          'error': response['error'] ?? 'Failed to get properties',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Get property by ID
  Future<Map<String, dynamic>> getPropertyById(int propertyId) async {
    try {
      final response = await _apiService.get('${AppConfig.propertiesEndpoint}$propertyId/');

      if (response['success'] && response['data'] != null) {
        return {
          'success': true,
          'property': Property.fromJson(response['data']),
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to get property',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Update property
  Future<Map<String, dynamic>> updateProperty(int propertyId, Map<String, dynamic> propertyData) async {
    try {
      final response = await _apiService.put('${AppConfig.propertiesEndpoint}$propertyId/', propertyData);

      if (response['success'] && response['data'] != null) {
        return {
          'success': true,
          'property': Property.fromJson(response['data']),
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to update property',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Delete property
  Future<Map<String, dynamic>> deleteProperty(int propertyId) async {
    try {
      final response = await _apiService.delete('${AppConfig.propertiesEndpoint}$propertyId/');

      if (response['success']) {
        return {
          'success': true,
          'message': 'Property deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to delete property',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}