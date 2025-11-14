import 'package:flutter/material.dart';
import 'package:habitto/features/chat/presentation/pages/conversation_page.dart';
import 'package:habitto/features/chat/presentation/pages/user_list_page.dart';
import 'package:habitto/core/services/token_storage.dart';
import 'package:habitto/features/profile/data/services/profile_service.dart';
import 'package:habitto/features/profile/domain/entities/profile.dart' as domain_profile;
import 'package:habitto/features/auth/domain/entities/user.dart' as domain_user;
import '../../data/services/user_service.dart';
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
  final TokenStorage _tokenStorage = TokenStorage();
  final UserService _userService = UserService();
  final ProfileService _profileService = ProfileService();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String _error = '';
  int? _currentUserId;
  Map<String, int> _messageUserIds = {}; // Map message ID to other user ID

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
      }

      // Fallback robusto: intentar obtener el usuario actual desde /api/profiles/me/
      if (_currentUserId == null) {
        final meRes = await _profileService.getCurrentProfile();
        if (meRes['success'] == true && meRes['data'] is Map) {
          final data = meRes['data'] as Map;
          final meUser = data['user'] as domain_user.User?;
          if (meUser != null) {
            setState(() {
              _currentUserId = meUser.id;
            });
          }
        }
      }

      print('Loading messages for user: $currentUserId');
      final result = await _messageService.getAllMessages();
      print('Message service result: $result');
      
      if (result['success']) {
        final messagesData = result['data'];
        if (messagesData == null || (messagesData as List).isEmpty) {
          print('No messages found or empty data, using fallback');
          setState(() {
            _messages = _getHardcodedMessages(); // Use fallback for empty messages
            _isLoading = false;
          });
          return;
        }
        
        List<MessageModel> messages;
        try {
          messages = messagesData as List<MessageModel>;
        } catch (e) {
          print('Error casting messages data: $e');
          setState(() {
            _error = 'Error al procesar mensajes: formato de datos inválido';
            _isLoading = false;
            _messages = _getHardcodedMessages(); // Fallback
          });
          return;
        }
        
        if (_currentUserId == null && messages.isNotEmpty) {
          final Map<int, int> freq = {};
          for (final m in messages) {
            freq[m.sender] = (freq[m.sender] ?? 0) + 1;
            freq[m.receiver] = (freq[m.receiver] ?? 0) + 1;
          }
          int guessedId = messages.first.sender;
          int maxCount = -1;
          freq.forEach((id, count) {
            if (count > maxCount) {
              maxCount = count;
              guessedId = id;
            }
          });
          _currentUserId = guessedId;
        }

        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final Map<int, ChatMessage> conversationMap = {};
        final Map<String, int> userIdMap = {};

        for (final message in messages) {
          if (message.sender == message.receiver) {
            continue;
          }
          final otherUserId = message.sender == _currentUserId ? message.receiver : message.sender;
          if (conversationMap.containsKey(otherUserId)) continue;

          final chatMessage = message.toChatMessage(
            currentUserId: _currentUserId!,
            senderName: 'Usuario $otherUserId',
          );

          conversationMap[otherUserId] = chatMessage;
          userIdMap[chatMessage.id] = otherUserId;
        }

        setState(() {
          _messages = conversationMap.values.toList();
          _messageUserIds = userIdMap;
          _isLoading = false;
        });

        // Enriquecer con nombres y fotos de perfil
        _enrichConversations(userIdMap);
      } else {
        // Manejar error
        setState(() {
          _error = 'Error: ${result['error']}';
          _isLoading = false;
          // Usar datos hardcodeados como fallback
          _messages = _getHardcodedMessages();
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar mensajes: $e';
        _isLoading = false;
        // Usar datos hardcodeados como fallback
        _messages = _getHardcodedMessages();
      });
    }
  }

  Future<void> _enrichConversations(Map<String, int> userIdMap) async {
    try {
      final ids = userIdMap.values.toSet().toList();
      final Map<int, String> names = {};
      final Map<int, String> avatars = {};

      for (final uid in ids) {
        // Intentar obtener perfil por user_id para foto y nombre completo
        final profRes = await _profileService.getProfileByUserId(uid);
        if (profRes['success'] == true && profRes['data'] is domain_profile.Profile) {
          final p = profRes['data'] as domain_profile.Profile;
          final fullName = p.user.fullName.isNotEmpty ? p.user.fullName : p.user.username;
          names[uid] = fullName;
          if (p.profileImage != null && p.profileImage!.isNotEmpty) {
            avatars[uid] = _sanitizeUrl(p.profileImage!);
          }
          continue;
        }

        // Fallback: obtener usuario para nombre
        final userRes = await _userService.getUser(uid);
        if (userRes['success'] == true && userRes['data'] is Map) {
          final data = Map<String, dynamic>.from(userRes['data'] as Map);
          final firstName = (data['first_name'] ?? '').toString();
          final lastName = (data['last_name'] ?? '').toString();
          final username = (data['username'] ?? '').toString();
          final fullName = ('$firstName $lastName').trim();
          names[uid] = fullName.isNotEmpty ? fullName : username.isNotEmpty ? username : 'Usuario $uid';
        } else {
          names[uid] = 'Usuario $uid';
        }
      }

      // Aplicar enriquecimiento a la lista de mensajes
      final updated = _messages.map((m) {
        final uid = userIdMap[m.id];
        if (uid == null) return m;
        final name = names[uid];
        final avatar = avatars[uid];
        if (name == null && avatar == null) return m;
        return ChatMessage(
          id: m.id,
          senderName: name ?? m.senderName,
          message: m.message,
          time: m.time,
          isFromCurrentUser: m.isFromCurrentUser,
          avatarUrl: avatar ?? m.avatarUrl,
          isOnline: m.isOnline,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _messages = updated;
        });
      }
    } catch (e) {
      // Silencioso: si falla, mantenemos los datos existentes
    }
  }

  String _sanitizeUrl(String url) {
    return url.replaceAll('`', '').trim();
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationPage(
              title: message.senderName,
              otherUserId: _messageUserIds[message.id],
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
                      Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
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
                  Text(
                    message.message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.3,
                    ),
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

  

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
