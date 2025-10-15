import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:habitto/features/chat/presentation/pages/conversation_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  // Datos hardcodeados para los mensajes
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      senderName: 'Agente Inmobiliario',
      message: '¡Claro! Te envío los detalles ahora mismo.',
      time: '10:42 AM',
      isFromCurrentUser: false,
      avatarUrl: 'assets/images/agent_avatar.png',
      isOnline: true,
    ),
    ChatMessage(
      id: '2',
      senderName: 'Carlos Ruiz',
      message: 'Hola, ¿sigues disponible?',
      time: 'Ayer',
      isFromCurrentUser: false,
      avatarUrl: 'assets/images/carlos_avatar.png',
      isOnline: false,
    ),
    ChatMessage(
      id: '3',
      senderName: 'Ana Gomez',
      message: 'Perfecto, gracias por la información.',
      time: '2d',
      isFromCurrentUser: false,
      avatarUrl: 'assets/images/ana_avatar.png',
      isOnline: false,
    ),
    ChatMessage(
      id: '4',
      senderName: 'Soporte Habitto',
      message: 'Bienvenido a Habitto. ¿Cómo podemos ayudarte?',
      time: '4d',
      isFromCurrentUser: false,
      avatarUrl: 'assets/images/support_avatar.png',
      isOnline: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mensajes',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // Implementar búsqueda
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda estilo glass
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.30),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar conversaciones...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.black54),
                      hintStyle: TextStyle(color: Colors.black87),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageTile(message);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(ChatMessage message) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationPage(title: message.senderName),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha:
                    message.id == '1' ? 0.35 : 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[300],
                      child: message.avatarUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: _buildAvatarImage(message),
                            )
                          : Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: 28,
                            ),
                    ),
                    if (message.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Contenido del mensaje
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            message.senderName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            message.time,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(ChatMessage message) {
    // Como no tenemos las imágenes reales, usamos colores de fondo diferentes
    Color avatarColor;
    IconData avatarIcon;

    switch (message.senderName) {
      case 'Agente Inmobiliario':
        avatarColor = const Color(0xFF4CAF50);
        avatarIcon = Icons.business;
        break;
      case 'Carlos Ruiz':
        avatarColor = const Color(0xFF2196F3);
        avatarIcon = Icons.person;
        break;
      case 'Ana Gomez':
        avatarColor = const Color(0xFFFF9800);
        avatarIcon = Icons.person;
        break;
      case 'Soporte Habitto':
        avatarColor = const Color(0xFF9C27B0);
        avatarIcon = Icons.support_agent;
        break;
      default:
        avatarColor = Colors.grey;
        avatarIcon = Icons.person;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        avatarIcon,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

// Modelo para los mensajes
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
