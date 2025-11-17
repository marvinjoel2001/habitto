import 'package:flutter/material.dart';
import 'package:habitto/features/chat/presentation/pages/conversation_page.dart';
import 'package:habitto/features/chat/presentation/pages/user_list_page.dart';
import 'package:habitto/core/services/token_storage.dart';
import '../../data/services/message_service.dart';
import '../../data/models/message_model.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:habitto/config/app_config.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final MessageService _messageService = MessageService();
  final TokenStorage _tokenStorage = TokenStorage();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String _error = '';
  int? _currentUserId;
  Map<String, int> _messageUserIds = {}; // Map message ID to other user ID
  Map<int, int> _unreadByUserId = {};
  WebSocketChannel? _inboxChannel;
  final Set<String> _processedMessageIds = <String>{};
  int _inboxReconnectDelayMs = 1000;

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

      // Obtener el ID del usuario actual
      final currentUserIdStr = await _tokenStorage.getCurrentUserId();
      final currentUserId = currentUserIdStr != null ? int.tryParse(currentUserIdStr) : null;
      
      print('Current user ID from token: $currentUserId');
      
      if (currentUserId != null) {
        setState(() {
          _currentUserId = currentUserId;
        });
        _openInboxWebSocket();
      }

      // Fallback robusto: intentar obtener el usuario actual desde /api/profiles/me/
      // Si no hay token/ID, no forzar resolución; evitamos consultas extra

      print('Loading conversations for user: $currentUserId');
      Map<String, dynamic> result = await _messageService.getConversations();
      print('Conversations service result: $result');
      
      if (result['success']) {
        final data = result['data'];
        if (data == null || (data as List).isEmpty) {
          setState(() {
            _messages = [];
            _messageUserIds = {};
            _isLoading = false;
          });
          return;
        }
        if (data is List && data.isNotEmpty && data.first is Map && (data.first as Map)['last_message'] != null) {
          final convs = List<Map<String, dynamic>>.from(data as List);
          final Map<String, int> userIdMap = {};
          final List<ChatMessage> items = [];
          for (final c in convs) {
            final otherUserId = c['counterpart_id'] as int;
            final lastMsg = c['last_message'] as MessageModel;
            final counterpartName = (c['counterpart_full_name'] as String?)?.trim();
            final counterpartUsername = (c['counterpart_username'] as String?)?.trim();
            final name = (counterpartName != null && counterpartName.isNotEmpty)
                ? counterpartName
                : (counterpartUsername != null && counterpartUsername.isNotEmpty
                    ? counterpartUsername
                    : 'Usuario $otherUserId');
            final avatar = _sanitizeUrl((c['counterpart_profile_picture'] as String?) ?? '');
            final chatMessage = lastMsg.toChatMessage(
              currentUserId: _currentUserId ?? lastMsg.receiver,
              senderName: name,
            );
            final enriched = ChatMessage(
              id: chatMessage.id,
              senderName: name,
              message: chatMessage.message,
              time: chatMessage.time,
              isFromCurrentUser: chatMessage.isFromCurrentUser,
              avatarUrl: avatar,
              isOnline: chatMessage.isOnline,
            );
            items.add(enriched);
            userIdMap[enriched.id] = otherUserId;
            final unread = c['unread_count'] as int? ?? 0;
            _unreadByUserId[otherUserId] = unread;
          }
          setState(() {
            _messages = items;
            _messageUserIds = userIdMap;
            _isLoading = false;
          });
          _openInboxWebSocket();
          
        } else {
          setState(() {
            _messages = [];
            _messageUserIds = {};
            _isLoading = false;
          });
        }
      } else {
        // Manejar error
        setState(() {
          _error = 'Error: ${result['error']}';
          _isLoading = false;
          _messages = [];
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar mensajes: $e';
        _isLoading = false;
        _messages = [];
      });
    }
  }

  // Enriquecimiento eliminado; backend ya provee los datos requeridos

  String _sanitizeUrl(String url) {
    return url.replaceAll('`', '').trim();
  }

  Future<void> _openInboxWebSocket() async {
    if (_currentUserId == null) return;
    if (_inboxChannel != null) return;
    final baseUri = Uri.parse(AppConfig.baseUrl);
    final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final accessToken = await _tokenStorage.getAccessToken();
    final userId = _currentUserId!;
    WebSocketChannel? ch;
    try {
      final uri1 = Uri(
        scheme: wsScheme,
        host: baseUri.host,
        port: AppConfig.wsPort,
        path: AppConfig.wsChatPath + 'inbox/$userId/',
        queryParameters: accessToken != null ? {AppConfig.wsTokenQueryName: accessToken} : null,
      );
      ch = WebSocketChannel.connect(uri1);
    } catch (_) {}
    if (ch == null) {
      try {
        final uri2 = Uri(
          scheme: wsScheme,
          host: baseUri.host,
          port: AppConfig.wsPort,
          path: AppConfig.wsChatPath + 'inbox/$userId',
          queryParameters: accessToken != null ? {AppConfig.wsTokenQueryName: accessToken} : null,
        );
        ch = WebSocketChannel.connect(uri2);
      } catch (_) {}
    }
    if (ch == null) {
      try {
        final uri3 = Uri(
          scheme: wsScheme,
          host: baseUri.host,
          port: AppConfig.wsPort,
          path: '/ws/notifications/$userId/',
          queryParameters: accessToken != null ? {AppConfig.wsTokenQueryName: accessToken} : null,
        );
        ch = WebSocketChannel.connect(uri3);
      } catch (_) {}
      if (ch == null) {
        try {
          final uri4 = Uri(
            scheme: wsScheme,
            host: baseUri.host,
            port: AppConfig.wsPort,
            path: '/ws/notifications/$userId',
            queryParameters: accessToken != null ? {AppConfig.wsTokenQueryName: accessToken} : null,
          );
          ch = WebSocketChannel.connect(uri4);
        } catch (_) {}
      }
    }
    if (ch == null) return;
    _inboxChannel = ch;
    ch.stream.listen((raw) {
      try {
        final data = raw is String ? _tryParseJson(raw) : raw;
        if (data is Map<String, dynamic>) {
          final mid = (data['message_id'] ?? data['id'])?.toString();
          if (mid != null && _processedMessageIds.contains(mid)) return;
          if (mid != null) _processedMessageIds.add(mid);
          final sender = data['sender'] as int?;
          final receiver = data['receiver'] as int?;
          final content = (data['content'] as String?) ?? '';
          final createdAtStr = data['created_at'] as String?;
          DateTime createdAt = DateTime.now();
          if (createdAtStr != null) {
            createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
          }
          final other = (sender == _currentUserId) ? (receiver ?? sender ?? 0) : (sender ?? receiver ?? 0);
          final nameRaw = (data['counterpart_full_name'] as String?)?.trim();
          final usernameRaw = (data['counterpart_username'] as String?)?.trim();
          final displayName = (nameRaw != null && nameRaw.isNotEmpty)
              ? nameRaw
              : (usernameRaw != null && usernameRaw.isNotEmpty ? usernameRaw : 'Usuario $other');
          final avatar = _sanitizeUrl(((data['counterpart_profile_picture'] as String?) ?? '').trim());
          final timeStr = _formatTime(createdAt);
          final existingIndex = _messages.indexWhere((m) => _messageUserIds[m.id] == other);
          if (existingIndex != -1) {
            final prev = _messages[existingIndex];
            final updated = ChatMessage(
              id: mid ?? prev.id,
              senderName: displayName.isNotEmpty ? displayName : prev.senderName,
              message: content.isNotEmpty ? content : prev.message,
              time: timeStr,
              isFromCurrentUser: sender == _currentUserId,
              avatarUrl: avatar.isNotEmpty ? avatar : prev.avatarUrl,
              isOnline: prev.isOnline,
            );
            setState(() {
              _messages.removeAt(existingIndex);
              _messages.insert(0, updated);
              _messageUserIds.remove(prev.id);
              _messageUserIds[updated.id] = other;
              if (sender != _currentUserId) {
                _unreadByUserId[other] = (_unreadByUserId[other] ?? 0) + 1;
              }
            });
          } else {
            final added = ChatMessage(
              id: mid ?? '${DateTime.now().microsecondsSinceEpoch}',
              senderName: displayName,
              message: content,
              time: timeStr,
              isFromCurrentUser: sender == _currentUserId,
              avatarUrl: avatar,
              isOnline: false,
            );
            setState(() {
              _messages.insert(0, added);
              _messageUserIds[added.id] = other;
              if (sender != _currentUserId) {
                _unreadByUserId[other] = (_unreadByUserId[other] ?? 0) + 1;
              }
            });
          }
        }
      } catch (_) {}
    }, onError: (err) {
      _inboxChannel = null;
      _scheduleInboxReconnect();
    }, onDone: () {
      _inboxChannel = null;
      _scheduleInboxReconnect();
    }, cancelOnError: false);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  Map<String, dynamic>? _tryParseJson(String s) {
    try {
      return s.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(s) as Map) : null;
    } catch (_) {
      return null;
    }
  }

  void _scheduleInboxReconnect() {
    final delay = Duration(milliseconds: _inboxReconnectDelayMs);
    Future.delayed(delay, () {
      if (mounted && _inboxChannel == null) {
        _openInboxWebSocket();
        _inboxReconnectDelayMs = (_inboxReconnectDelayMs * 2).clamp(1000, 10000);
      }
    });
  }

  Widget _buildUnreadBadge(int? otherUserId) {
    if (otherUserId == null) return const SizedBox.shrink();
    final count = _unreadByUserId[otherUserId] ?? 0;
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildLastMessageText(ChatMessage message) {
    final otherId = _messageUserIds[message.id];
    final count = otherId != null ? _unreadByUserId[otherId] ?? 0 : 0;
    final isUnread = count > 0;
    return Text(
      message.message,
      style: TextStyle(
        fontSize: 14,
        color: Colors.black54,
        height: 1.3,
        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
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
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: const Text(
          'Mensajes',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserListPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar conversaciones...',
                  hintStyle: const TextStyle(color: Colors.black45),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 64, color: Colors.black26),
                                const SizedBox(height: 16),
                                Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 16)),
                                const SizedBox(height: 16),
                                ElevatedButton(onPressed: _loadMessages, child: const Text('Reintentar')),
                              ],
                            ),
                          )
                        : _messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.chat_bubble_outline, size: 64, color: Colors.black26),
                                    SizedBox(height: 16),
                                    Text('No tienes conversaciones aún', style: TextStyle(color: Colors.black54, fontSize: 18)),
                                    SizedBox(height: 8),
                                    Text('Inicia una conversación con otros usuarios', style: TextStyle(color: Colors.black45, fontSize: 14)),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadMessages,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    final message = _messages[index];
                                    return _buildMessageTile(message);
                                  },
                                ),
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
        final otherId = _messageUserIds[message.id];
        if (otherId != null) {
          _messageService.markThreadRead(otherId).then((_) {
            setState(() {
              _unreadByUserId[otherId] = 0;
            });
          });
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationPage(
              title: message.senderName,
              otherUserId: _messageUserIds[message.id],
              avatarUrl: message.avatarUrl,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: message.avatarUrl.isNotEmpty ? NetworkImage(message.avatarUrl) : null,
                  child: message.avatarUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 28,
                        )
                      : null,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            message.senderName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildUnreadBadge(_messageUserIds[message.id]),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            message.time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.done_all,
                            size: 16,
                            color: message.isFromCurrentUser ? Colors.blueAccent : Colors.transparent,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildLastMessageText(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  @override
  void dispose() {
    _messageController.dispose();
    try {
      _inboxChannel?.sink.close();
    } catch (_) {}
    super.dispose();
  }
}
