import 'package:flutter/material.dart';
import 'package:habitto/features/chat/presentation/pages/conversation_page.dart';
import 'package:habitto/features/chat/presentation/pages/user_list_page.dart';
import 'package:habitto/core/services/token_storage.dart';
import 'package:habitto/core/services/api_service.dart';
import '../../data/services/message_service.dart';
import '../../data/models/message_model.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:habitto/config/app_config.dart';
import 'package:habitto/features/matching/data/services/matching_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final MessageService _messageService = MessageService();
  final TokenStorage _tokenStorage = TokenStorage();
  final ApiService _apiService = ApiService();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String _error = '';
  int? _currentUserId;
  Map<String, int> _messageUserIds = {}; // Map message ID to other user ID
  final Map<int, int> _unreadByUserId = {};
  final Map<int, String> _avatarByUserId = {};
  WebSocketChannel? _inboxChannel;
  final Set<String> _processedMessageIds = <String>{};
  int _inboxReconnectDelayMs = 1000;
  int _pendingMatchRequestsCount = 0;
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadPendingMatchRequests();
    _loadUnreadNotificationsCount();
  }

  Future<void> _loadPendingMatchRequests() async {
    try {
      final matchingService = MatchingService();
      final result = await matchingService.getPendingMatchRequests();
      if (result['success'] && result['data'] != null) {
        final requests = result['data'] as List<dynamic>;
        setState(() {
          _pendingMatchRequestsCount = requests.length;
        });
      }
    } catch (e) {
      print('Error loading pending match requests: $e');
    }
  }

  Future<void> _loadUnreadNotificationsCount() async {
    try {
      final resp = await _apiService.get('/api/notifications/', queryParameters: {'is_read': false});
      if (resp['success'] == true) {
        final data = resp['data'];
        int count = 0;
        if (data is Map && data['count'] is int) {
          count = data['count'] as int;
        } else if (data is Map && data['results'] is List) {
          count = (data['results'] as List).length;
        } else if (data is List) {
          count = data.length;
        }
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    } catch (_) {}
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
        if (data.isNotEmpty && data.first is Map && (data.first as Map)['last_message'] != null) {
          final convs = List<Map<String, dynamic>>.from(data);
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
            final avatar = _resolveAvatar((c['counterpart_profile_picture'] as String?) ?? '');
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
            if (avatar.isNotEmpty) {
              _avatarByUserId[otherUserId] = avatar;
            }
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

  String _resolveAvatar(String url) {
    final u = _sanitizeUrl(url);
    if (u.isEmpty) return '';
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final baseUri = Uri.parse(AppConfig.baseUrl);
    final abs = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.port == 0 ? null : baseUri.port,
      path: u.startsWith('/') ? u : '/$u',
    );
    return abs.toString();
  }

  Future<void> _openInboxWebSocket() async {
    if (_currentUserId == null) return;
    if (_inboxChannel != null) return;
    final accessToken = await _tokenStorage.getAccessToken();
    final userId = _currentUserId!;
    WebSocketChannel? ch;
    try {
      final uri1 = AppConfig.buildWsUri('${AppConfig.wsInboxPath}$userId/', token: accessToken);
      ch = WebSocketChannel.connect(uri1);
    } catch (_) {}
    if (ch == null) {
      try {
        final uri2 = AppConfig.buildWsUri('${AppConfig.wsInboxPath}$userId', token: accessToken);
        ch = WebSocketChannel.connect(uri2);
      } catch (_) {}
    }
    if (ch == null) {
      try {
        final uri3 = AppConfig.buildWsUri('/ws/notifications/$userId/', token: accessToken);
        ch = WebSocketChannel.connect(uri3);
      } catch (_) {}
      if (ch == null) {
        try {
          final uri4 = AppConfig.buildWsUri('/ws/notifications/$userId', token: accessToken);
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
          final avatar = _resolveAvatar(((data['counterpart_profile_picture'] as String?) ?? '').trim());
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
              avatarUrl: (_avatarByUserId[other] ?? (avatar.isNotEmpty ? avatar : prev.avatarUrl)),
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
              if (avatar.isNotEmpty) {
                _avatarByUserId[other] = avatar;
              }
            });
          } else {
            final added = ChatMessage(
              id: mid ?? '${DateTime.now().microsecondsSinceEpoch}',
              senderName: displayName,
              message: content,
              time: timeStr,
              isFromCurrentUser: sender == _currentUserId,
              avatarUrl: (_avatarByUserId[other] ?? avatar),
              isOnline: false,
            );
            setState(() {
              _messages.insert(0, added);
              _messageUserIds[added.id] = other;
              if (sender != _currentUserId) {
                _unreadByUserId[other] = (_unreadByUserId[other] ?? 0) + 1;
              }
              if (avatar.isNotEmpty) {
                _avatarByUserId[other] = avatar;
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
                                ElevatedButton(onPressed: () async { await _loadMessages(); await _loadPendingMatchRequests(); }, child: const Text('Reintentar')),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await _loadMessages();
                              await _loadPendingMatchRequests();
                              await _loadUnreadNotificationsCount();
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              itemCount: _messages.length + 2,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _buildNotificationsShortcutTile();
                                } else if (index == 1) {
                                  return _buildMatchRequestsShortcutTile();
                                }
                                final message = _messages[index - 2];
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
                Builder(builder: (context) {
                  final otherId = _messageUserIds[message.id];
                  final url = otherId != null ? (_avatarByUserId[otherId] ?? message.avatarUrl) : message.avatarUrl;
                  return CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
                    child: url.isEmpty
                        ? Icon(
                            Icons.person,
                            color: Colors.grey[600],
                            size: 28,
                          )
                        : null,
                  );
                }),
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

  Widget _buildMatchRequestsShortcutTile() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const _MatchRequestsPage(),
          ),
        ).then((_) {
          _loadPendingMatchRequests();
        });
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
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
              child: const Icon(Icons.favorite, color: Colors.white, size: 24),
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
                          const Text(
                            'Solicitudes de Match',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                          const SizedBox(width: 8),
                          if (_pendingMatchRequestsCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                              child: Text('$_pendingMatchRequestsCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Color(0xFF9CA3AF), size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _pendingMatchRequestsCount > 0 ? 'Toca para revisar y aceptar' : 'Por el momento no tienes solicitudes',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsShortcutTile() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const _NotificationsPage(),
          ),
        ).then((_) {
          _loadUnreadNotificationsCount();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDBEAFE)),
          boxShadow: const [
            BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.indigoAccent.withValues(alpha: 0.3),
              child: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Notificaciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                  SizedBox(height: 4),
                  Text('Revisa tus avisos recientes', style: TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ),
            if (_unreadNotificationsCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.indigoAccent, borderRadius: BorderRadius.circular(10)),
                child: Text('$_unreadNotificationsCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF9CA3AF), size: 16),
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

class _MatchRequestsPage extends StatefulWidget {
  const _MatchRequestsPage({super.key});

  @override
  State<_MatchRequestsPage> createState() => _MatchRequestsPageState();
}

class _NotificationsPage extends StatefulWidget {
  const _NotificationsPage({super.key});

  @override
  State<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<_NotificationsPage> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() { _isLoading = true; _error = ''; });
      final resp = await _api.get('/api/notifications/', queryParameters: {'page_size': 50});
      if (resp['success'] == true) {
        final data = resp['data'];
        List<Map<String, dynamic>> results = [];
        if (data is Map && data['results'] is List) {
          results = List<Map<String, dynamic>>.from((data['results'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
        } else if (data is List) {
          results = List<Map<String, dynamic>>.from(data.map((e) => Map<String, dynamic>.from(e as Map)));
        }
        setState(() { _items = results; _isLoading = false; });
      } else {
        setState(() { _error = 'Error: ${resp['error']}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Error al cargar notificaciones: $e'; _isLoading = false; });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      final resp = await _api.post('/api/notifications/$id/mark_as_read/', {});
      if (resp['success'] == true) {
        setState(() {
          final idx = _items.indexWhere((n) => (n['id'] as int?) == id);
          if (idx != -1) {
            _items[idx]['is_read'] = true;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notificación marcada como leída'), duration: Duration(seconds: 2)));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Notificaciones', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: _load)],
      ),
      body: _isLoading
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
                      ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off, size: 64, color: Colors.black26),
                          SizedBox(height: 16),
                          Text('Por el momento no tienes notificaciones', style: TextStyle(color: Colors.black54, fontSize: 18)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final n = _items[index];
                          final title = (n['title'] as String?) ?? 'Notificación';
                          final message = (n['message'] as String?) ?? (n['content'] as String?) ?? '';
                          final isRead = (n['is_read'] as bool?) ?? false;
                          final createdAt = (n['created_at'] as String?) ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isRead ? const Color(0xFFF9FAFB) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 4))],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.indigoAccent.withValues(alpha: 0.25),
                                  child: const Icon(Icons.notifications, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                                          Text(createdAt, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(message, style: const TextStyle(fontSize: 14, color: Colors.black87), maxLines: 3, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 8),
                                      if (!isRead)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () => _markRead((n['id'] as int?) ?? 0),
                                            icon: const Icon(Icons.done, size: 16),
                                            label: const Text('Marcar como leída'),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _MatchRequestsPageState extends State<_MatchRequestsPage> {
  final MatchingService _matchingService = MatchingService();
  List<dynamic> _matchRequests = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadMatchRequests();
  }

  Future<void> _loadMatchRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });
      final result = await _matchingService.getPendingMatchRequests();
      if (result['success']) {
        final requests = (result['data'] as List<dynamic>?) ?? [];
        setState(() {
          _matchRequests = requests;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error: ${result['error']}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar solicitudes: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptMatchRequest(int matchId) async {
    try {
      final result = await _matchingService.acceptMatchRequest(matchId);
      if (result['success']) {
        setState(() {
          _matchRequests.removeWhere((request) => (request['match'] as Map?)?['id'] == matchId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud de match aceptada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aceptar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _rejectMatchRequest(int matchId) async {
    try {
      final result = await _matchingService.rejectMatchRequest(matchId);
      if (result['success']) {
        setState(() {
          _matchRequests.removeWhere((request) => (request['match'] as Map?)?['id'] == matchId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud de match rechazada'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al rechazar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
          'Solicitudes de Match',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadMatchRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(_error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadMatchRequests, child: const Text('Reintentar')),
                          ],
                        ),
                      )
                    : _matchRequests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('No tienes solicitudes de match pendientes', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                                const SizedBox(height: 8),
                                Text('Las nuevas solicitudes aparecerán aquí', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMatchRequests,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _matchRequests.length,
                              itemBuilder: (context, index) {
                                final request = _matchRequests[index] as Map<String, dynamic>;
                                return _buildMatchRequestTile(request);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchRequestTile(Map<String, dynamic> request) {
    final match = request['match'] as Map<String, dynamic>? ?? {};
    final property = request['property'] as Map<String, dynamic>? ?? {};
    final interestedUser = request['interested_user'] as Map<String, dynamic>? ?? {};
    final matchId = match['id'] as int? ?? 0;
    final propertyTitle = property['title'] as String? ?? 'Propiedad sin título';
    final propertyAddress = property['address'] as String? ?? 'Dirección no especificada';
    final userName = '${interestedUser['first_name'] ?? ''} ${interestedUser['last_name'] ?? ''}'.trim();
    final userUsername = interestedUser['username'] as String? ?? 'Usuario';
    final displayName = userName.isNotEmpty ? userName : userUsername;
    final score = match['score'] as int? ?? 0;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 2),
                    Text('@$userUsername', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1),
                ),
                child: Text('$score%', style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(propertyTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(propertyAddress, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _rejectMatchRequest(matchId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    foregroundColor: Colors.red[700],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3), width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Rechazar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptMatchRequest(matchId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    foregroundColor: Colors.green[700],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.green.withValues(alpha: 0.3), width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Aceptar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
