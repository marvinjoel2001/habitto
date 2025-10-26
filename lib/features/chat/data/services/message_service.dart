import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/services/api_service.dart';
import '../models/message_model.dart';

class MessageService {
  final ApiService _apiService = ApiService();

  /// Obtiene mensajes entre dos usuarios específicos
  Future<List<MessageModel>> getConversation(int userId1, int userId2) async {
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
      
      return messages;
    } catch (e) {
      throw Exception('Error al obtener la conversación: $e');
    }
  }

  /// Obtiene todos los mensajes del usuario actual (para la lista de chats)
  Future<List<MessageModel>> getAllMessages() async {
    try {
      final response = await _apiService.get('/api/messages/');
      
      if (response['success']) {
        final results = response['data']['results'] as List;
        return results.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        throw Exception(response['error'] ?? 'Error al obtener mensajes');
      }
    } catch (e) {
      throw Exception('Error al obtener mensajes: $e');
    }
  }

  /// Envía un nuevo mensaje
  Future<MessageModel> sendMessage({
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
        return MessageModel.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Error al enviar mensaje');
      }
    } catch (e) {
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  /// Obtiene un mensaje específico por ID
  Future<MessageModel> getMessage(int messageId) async {
    try {
      final response = await _apiService.get('/api/messages/$messageId/');
      
      if (response['success']) {
        return MessageModel.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Error al obtener mensaje');
      }
    } catch (e) {
      throw Exception('Error al obtener mensaje: $e');
    }
  }

  /// Actualiza un mensaje existente
  Future<MessageModel> updateMessage(int messageId, String newContent) async {
    try {
      final response = await _apiService.patch('/api/messages/$messageId/', {
        'content': newContent,
      });

      if (response['success']) {
        return MessageModel.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Error al actualizar mensaje');
      }
    } catch (e) {
      throw Exception('Error al actualizar mensaje: $e');
    }
  }

  /// Elimina un mensaje
  Future<bool> deleteMessage(int messageId) async {
    try {
      final response = await _apiService.delete('/api/messages/$messageId/');
      return response['success'];
    } catch (e) {
      throw Exception('Error al eliminar mensaje: $e');
    }
  }
}