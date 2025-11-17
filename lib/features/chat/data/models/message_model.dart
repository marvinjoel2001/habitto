class MessageModel {
  final int id;
  final int sender;
  final int receiver;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      sender: json['sender'],
      receiver: json['receiver'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: (json['is_read'] is bool)
          ? json['is_read'] as bool
          : (json['is_read'] == null
              ? false
              : json['is_read'].toString().toLowerCase() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'receiver': receiver,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convierte MessageModel a ChatMessage para compatibilidad con la UI existente
  ChatMessage toChatMessage({required int currentUserId, String? senderName}) {
    return ChatMessage(
      id: id.toString(),
      senderName: senderName ?? 'Usuario $sender',
      message: content,
      time: _formatTime(createdAt),
      isFromCurrentUser: sender == currentUserId,
      avatarUrl: '',
      isOnline: false,
    );
  }

  /// Convierte MessageModel a ConvMessage para la página de conversación
  ConvMessage toConvMessage({required int currentUserId}) {
    return ConvMessage(
      text: content,
      fromMe: sender == currentUserId,
      time: _formatTime(createdAt),
      status: 'delivered',
      isRead: isRead,
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }
}

// Clases existentes para compatibilidad
class ChatMessage {
  final String id;
  final String senderName;
  final String message;
  final String time;
  final bool isFromCurrentUser;
  final String avatarUrl;
  final bool isOnline;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.message,
    required this.time,
    required this.isFromCurrentUser,
    required this.avatarUrl,
    required this.isOnline,
  });
}

class ConvMessage {
  final String text;
  final bool fromMe;
  final String time;
  final String status;
  final bool isRead;

  ConvMessage({
    required this.text,
    required this.fromMe,
    required this.time,
    required this.status,
    required this.isRead,
  });
}