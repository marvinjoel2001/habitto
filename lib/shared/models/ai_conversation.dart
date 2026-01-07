import 'dart:convert';

class AiConversation {
  final String id;
  final String title;
  final List<Map<String, String>> messages;
  final DateTime timestamp;

  AiConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'messages': messages,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AiConversation.fromMap(Map<String, dynamic> map) {
    return AiConversation(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Nueva conversación',
      messages: List<Map<String, String>>.from(
        (map['messages'] as List).map(
          (e) => Map<String, String>.from(e),
        ),
      ),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  String toJson() => json.encode(toMap());

  factory AiConversation.fromJson(String source) =>
      AiConversation.fromMap(json.decode(source));
      
  AiConversation copyWith({
    String? id,
    String? title,
    List<Map<String, String>>? messages,
    DateTime? timestamp,
  }) {
    return AiConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
