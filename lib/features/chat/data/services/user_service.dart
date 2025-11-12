import '../../../../core/services/api_service.dart';
import '../../../../config/app_config.dart';

class UserService {
  final ApiService _apiService = ApiService();

  /// Obtiene la lista de todos los usuarios de la aplicación
  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final response = await _apiService.get(AppConfig.usersEndpoint);
      
      if (response['success']) {
        return {
          'success': true,
          'data': response['data']['results'] ?? [],
          'message': response['message'] ?? 'Usuarios obtenidos exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener usuarios',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al obtener usuarios: $e',
        'data': null,
      };
    }
  }

  /// Obtiene los detalles de un usuario específico
  Future<Map<String, dynamic>> getUser(int userId) async {
    try {
      final response = await _apiService.get('${AppConfig.usersEndpoint}$userId/');
      
      if (response['success']) {
        return {
          'success': true,
          'data': response['data'],
          'message': response['message'] ?? 'Usuario obtenido exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener usuario',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al obtener usuario: $e',
        'data': null,
      };
    }
  }

  /// Busca usuarios por nombre o username
  Future<Map<String, dynamic>> searchUsers(String query) async {
    try {
      final response = await _apiService.get('${AppConfig.usersEndpoint}?search=$query');
      
      if (response['success']) {
        return {
          'success': true,
          'data': response['data']['results'] ?? [],
          'message': response['message'] ?? 'Usuarios encontrados exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al buscar usuarios',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al buscar usuarios: $e',
        'data': null,
      };
    }
  }
}