import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:habitto/features/chat/presentation/pages/conversation_page.dart';
import '../../data/services/message_service.dart';
import '../../data/models/message_model.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final MessageService _messageService = MessageService();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final messages = await _messageService.getAllMessages();
      
      // Convertir MessageModel a ChatMessage y agrupar por conversación
      final Map<int, ChatMessage> conversationMap = {};
      
      for (final message in messages) {
        final otherUserId = message.sender == 1 ? message.receiver : message.sender; // Asumiendo usuario actual ID = 1
        final chatMessage = message.toChatMessage(
          currentUserId: 1, // TODO: Obtener ID del usuario actual desde auth
          senderName: 'Usuario $otherUserId',
        );
        
        // Solo mantener el mensaje más reciente por conversación
        if (!conversationMap.containsKey(otherUserId) || 
            message.createdAt.isAfter(DateTime.parse('2025-01-01'))) { // Comparación simplificada
          conversationMap[otherUserId] = chatMessage;
        }
      }

      setState(() {
        _messages = conversationMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar mensajes: $e';
        _isLoading = false;
        // Usar datos hardcodeados como fallback
        _messages = _getHardcodedMessages();
      });
    }
  }

  List<ChatMessage> _getHardcodedMessages() {
    return [
      ChatMessage(
        id: '1',
        senderName: 'María González',
        message: '¡Claro! Te envío los detalles ahora mismo.',
        time: '10:30',
        isFromCurrentUser: false,
        avatarUrl: 'assets/images/maria_avatar.png',
        isOnline: true,
      ),
      ChatMessage(
        id: '2',
        senderName: 'Carlos Mendoza',
        message: 'Hola, ¿sigues disponible?',
        time: '09:45',
        isFromCurrentUser: false,
        avatarUrl: 'assets/images/carlos_avatar.png',
        isOnline: false,
      ),
      ChatMessage(
        id: '3',
        senderName: 'Ana Rodríguez',
        message: 'Perfecto, gracias por la información.',
        time: '08:20',
        isFromCurrentUser: false,
        avatarUrl: 'assets/images/ana_avatar.png',
        isOnline: true,
      ),
      ChatMessage(
        id: '4',
        senderName: 'Soporte Habitto',
        message: 'Bienvenido a Habitto. ¿Cómo podemos ayudarte?',
        time: 'Ayer',
        isFromCurrentUser: false,
        avatarUrl: 'assets/images/support_avatar.png',
        isOnline: false,
      ),
    ];
  }

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
          // Barra de búsqueda con glassmorphism similar al home
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar conversaciones...',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: true,
                      icon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tienes conversaciones aún',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Inicia una conversación con otros usuarios',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMessages,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                return _buildMessageTile(message);
                              },
                            ),
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
