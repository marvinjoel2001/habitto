import '../../../../core/services/api_service.dart';
import '../models/message_model.dart';

class MessageService {
  final ApiService _apiService = ApiService();

  /// Obtiene mensajes entre dos usuarios específicos
  Future<Map<String, dynamic>> getConversation(int userId1, int userId2) async {
    try {
      // Obtener mensajes en ambas direcciones
      final response1 = await _apiService.get('/api/messages/?sender=$userId1&receiver=$userId2');
      final response2 = await _apiService.get('/api/messages/?sender=$userId2&receiver=$userId1');

      List<MessageModel> messages = [];
      
      if (response1['success']) {
        final results1 = response1['data']['results'] as List;
        messages.addAll(results1.map((json) => MessageModel.fromJson(json)));
      }
      
      if (response2['success']) {
        final results2 = response2['data']['results'] as List;
        messages.addAll(results2.map((json) => MessageModel.fromJson(json)));
      }

      // Ordenar por fecha de creación
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      return {
        'success': true,
        'data': messages,
        'message': 'Conversación obtenida exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al obtener la conversación: $e',
        'data': null,
      };
    }
  }

  /// Obtiene todos los mensajes del usuario actual (para la lista de chats)
  Future<Map<String, dynamic>> getAllMessages() async {
    try {
      final response = await _apiService.get('/api/messages/');
      
      // Debug: print the response structure
      print('API Response: $response');
      
      if (response['success']) {
        // Handle different response structures
        List<dynamic> results = [];
        
        if (response['data'] != null) {
          if (response['data'] is List) {
            // Direct list response
            results = response['data'] as List;
          } else if (response['data']['results'] != null) {
            // Paginated response with results field
            results = response['data']['results'] as List;
          } else if (response['data'] is Map) {
            // Handle empty response or different structure
            print('Unexpected data structure: ${response['data']}');
            results = [];
          }
        }
        
        final messages = results.map((json) => MessageModel.fromJson(json)).toList();
        
        return {
          'success': true,
          'data': messages,
          'message': response['message'] ?? 'Mensajes obtenidos exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener mensajes',
          'data': [],
        };
      }
    } catch (e) {
      print('Error in getAllMessages: $e');
      return {
        'success': false,
        'error': 'Error al obtener mensajes: $e',
        'data': [],
      };
    }
  }

  /// Envía un nuevo mensaje
  Future<Map<String, dynamic>> sendMessage({
    required int senderId,
    required int receiverId,
    required String content,
  }) async {
    try {
      final response = await _apiService.post('/api/messages/', {
        'sender': senderId,
        'receiver': receiverId,
        'content': content,
      });

      if (response['success']) {
        final message = MessageModel.fromJson(response['data']);
        
        return {
          'success': true,
          'data': message,
          'message': response['message'] ?? 'Mensaje enviado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al enviar mensaje',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al enviar mensaje: $e',
        'data': null,
      };
    }
  }

  /// Obtiene un mensaje específico por ID
  Future<Map<String, dynamic>> getMessage(int messageId) async {
    try {
      final response = await _apiService.get('/api/messages/$messageId/');
      
      if (response['success']) {
        final message = MessageModel.fromJson(response['data']);
        
        return {
          'success': true,
          'data': message,
          'message': response['message'] ?? 'Mensaje obtenido exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener mensaje',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al obtener mensaje: $e',
        'data': null,
      };
    }
  }

  /// Actualiza un mensaje existente
  Future<Map<String, dynamic>> updateMessage(int messageId, String newContent) async {
    try {
      final response = await _apiService.patch('/api/messages/$messageId/', {
        'content': newContent,
      });

      if (response['success']) {
        final message = MessageModel.fromJson(response['data']);
        
        return {
          'success': true,
          'data': message,
          'message': response['message'] ?? 'Mensaje actualizado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al actualizar mensaje',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al actualizar mensaje: $e',
        'data': null,
      };
    }
  }

  /// Elimina un mensaje
  Future<Map<String, dynamic>> deleteMessage(int messageId) async {
    try {
      final response = await _apiService.delete('/api/messages/$messageId/');
      
      if (response['success']) {
        return {
          'success': true,
          'data': null,
          'message': response['message'] ?? 'Mensaje eliminado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al eliminar mensaje',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al eliminar mensaje: $e',
        'data': null,
      };
    }
  }
}