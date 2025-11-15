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
        List<dynamic> results1 = [];
        final d1 = response1['data'];
        if (d1 is Map && d1['data'] is Map && (d1['data'] as Map)['results'] is List) {
          results1 = List<dynamic>.from((d1['data'] as Map)['results'] as List);
        } else if (d1 is Map && d1['results'] is List) {
          results1 = List<dynamic>.from(d1['results'] as List);
        } else if (d1 is List) {
          results1 = List<dynamic>.from(d1);
        }
        messages.addAll(results1.map((json) => MessageModel.fromJson(json)));
      }
      
      if (response2['success']) {
        List<dynamic> results2 = [];
        final d2 = response2['data'];
        if (d2 is Map && d2['data'] is Map && (d2['data'] as Map)['results'] is List) {
          results2 = List<dynamic>.from((d2['data'] as Map)['results'] as List);
        } else if (d2 is Map && d2['results'] is List) {
          results2 = List<dynamic>.from(d2['results'] as List);
        } else if (d2 is List) {
          results2 = List<dynamic>.from(d2);
        }
        messages.addAll(results2.map((json) => MessageModel.fromJson(json)));
      }

      // Ordenar por fecha de creación
      // El backend puede devolver el mismo set para ambas consultas; eliminar duplicados por ID
      final Map<int, MessageModel> uniq = {
        for (final m in messages) m.id: m,
      };
      messages = uniq.values.toList();
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
        // Extraer resultados de estructuras anidadas comunes
        List<dynamic> results = [];

        final d = response['data'];
        if (d != null) {
          if (d is List) {
            results = List<dynamic>.from(d);
          } else if (d is Map) {
            // Caso 1: { success, message, data: { results: [...] } }
            if (d['data'] is Map && (d['data'] as Map)['results'] is List) {
              results = List<dynamic>.from(((d['data'] as Map)['results'] as List));
            }
            // Caso 2: { results: [...] }
            else if (d['results'] is List) {
              results = List<dynamic>.from(d['results'] as List);
            }
            // Caso 3: { data: [...] }
            else if (d['data'] is List) {
              results = List<dynamic>.from(d['data'] as List);
            } else {
              print('Unexpected data structure in getAllMessages: $d');
            }
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

  /// Obtiene conversaciones del usuario autenticado con su último mensaje
  /// Endpoint: GET /api/messages/conversations/
  Future<Map<String, dynamic>> getConversations() async {
    try {
      final response = await _apiService.get('/api/messages/conversations/');
      if (response['success']) {
        final envelope = response['data'];
        final convs = parseConversationsEnvelope(envelope);

        return {
          'success': true,
          'data': convs,
          'message': response['message'] ?? 'Conversaciones obtenidas exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener conversaciones',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al obtener conversaciones: $e',
        'data': [],
      };
    }
  }

  List<Map<String, dynamic>> parseConversationsEnvelope(dynamic envelope) {
    List<dynamic> results = [];
    if (envelope is Map && envelope['data'] is Map && (envelope['data'] as Map)['results'] is List) {
      results = List<dynamic>.from((envelope['data'] as Map)['results'] as List);
    } else if (envelope is Map && envelope['results'] is List) {
      results = List<dynamic>.from(envelope['results'] as List);
    } else if (envelope is List) {
      results = List<dynamic>.from(envelope);
    }

    return results.map((json) {
      final m = MessageModel.fromJson(Map<String, dynamic>.from(json['last_message'] as Map));
      final counterpart = Map<String, dynamic>.from(json['counterpart'] as Map);
      final unread = json['unread_count'] ?? 0;
      return {
        'counterpart_id': counterpart['id'] as int,
        'counterpart_username': counterpart['username'] as String?,
        'counterpart_full_name': counterpart['full_name'] as String?,
        'counterpart_profile_picture': counterpart['profile_picture'] as String?,
        'unread_count': unread is int ? unread : int.tryParse(unread.toString()) ?? 0,
        'last_message': m,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> markThreadRead(int otherUserId) async {
    try {
      final response = await _apiService.post('/api/messages/mark_thread_read/', {
        'other_user_id': otherUserId,
      });
      if (response['success']) {
        return {
          'success': true,
          'data': response['data'],
        };
      }
      return {
        'success': false,
        'error': response['error'] ?? 'Error al marcar como leído',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al marcar hilo leído: $e',
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

  /// Obtiene el hilo con otro usuario (más recientes primero)
  Future<Map<String, dynamic>> getThread(int otherUserId, {int page = 1, int pageSize = 50}) async {
    try {
      final response = await _apiService.get('/api/messages/thread/', queryParameters: {
        'other_user_id': otherUserId,
        'page': page,
        'page_size': pageSize,
      });

      if (response['success']) {
        final envelope = response['data'];
        List<dynamic> results = [];
        if (envelope is Map && envelope['data'] is Map && (envelope['data'] as Map)['results'] is List) {
          results = List<dynamic>.from((envelope['data'] as Map)['results'] as List);
        } else if (envelope is Map && envelope['results'] is List) {
          results = List<dynamic>.from(envelope['results'] as List);
        } else if (envelope is List) {
          results = List<dynamic>.from(envelope);
        }

        final messages = results.map((json) => MessageModel.fromJson(json)).toList();
        return {
          'success': true,
          'data': messages,
          'message': response['message'] ?? 'Hilo obtenido exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? response['message'] ?? 'Error al obtener hilo',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al obtener hilo: $e',
        'data': [],
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