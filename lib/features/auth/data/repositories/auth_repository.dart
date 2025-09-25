
import '../../../../core/services/api_service.dart';
import '../../domain/entities/user.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  
  Future<User> login(String email, String password) async {
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });
      
      return User.fromJson(response['user']);
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }
  
  Future<User> register(String email, String password, String name) async {
    try {
      final response = await _apiService.post('/auth/register', {
        'email': email,
        'password': password,
        'name': name,
      });
      
      return User.fromJson(response['user']);
    } catch (e) {
      throw Exception('Error al registrarse: $e');
    }
  }
  
  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout', {});
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }
}