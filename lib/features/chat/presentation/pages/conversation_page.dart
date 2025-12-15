import 'package:flutter/material.dart';
import 'dart:convert';
import '../../data/services/message_service.dart';
import '../../data/models/message_model.dart';
import 'package:habitto/core/services/token_storage.dart';
import 'package:habitto/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:habitto/shared/theme/app_theme.dart';
import '../../../profile/data/services/profile_service.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../../../generated/l10n.dart';

class ConversationPage extends StatefulWidget {
  final String title;
  final int? otherUserId; // ID del otro usuario en la conversación
  final String? avatarUrl;

  const ConversationPage({
    super.key,
    required this.title,
    this.otherUserId,
    this.avatarUrl,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _controller = TextEditingController();
  final MessageService _messageService = MessageService();
  final TokenStorage _tokenStorage = TokenStorage();
  final ScrollController _scrollController = ScrollController();
  final ProfileService _profileService = ProfileService();
  List<GlobalKey> _itemKeys = [];
  List<ConvMessage> _messages = [];
  bool _isLoading = true;
  String _error = '';
  int? _currentUserId;
  WebSocketChannel? _wsChannel;
  String? _counterpartAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    if (widget.otherUserId == null) {
      // Si no hay otherUserId, usar datos hardcodeados
      setState(() {
        _messages = _getHardcodedMessages();
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              _jumpToFirstUnreadOrBottom();
            }
          });
        }
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Obtener el ID del usuario actual
      final currentUserIdStr = await _tokenStorage.getCurrentUserId();
      final currentUserId =
          currentUserIdStr != null ? int.tryParse(currentUserIdStr) : null;

      if (currentUserId == null) {
        setState(() {
          _error = S.of(context).errorGetCurrentUser;
          _isLoading = false;
          _messages = _getHardcodedMessages(); // Fallback
        });
        return;
      }

      setState(() {
        _currentUserId = currentUserId;
      });

      _loadCounterpartAvatar();
      _openWebSocket();

      final result = await _messageService.getThread(widget.otherUserId!,
          page: 1, pageSize: 50);

      if (result['success']) {
        final allMessages = result['data'] as List<MessageModel>;
        final messages = List<MessageModel>.from(allMessages)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        setState(() {
          _messages = messages
              .map((message) => message.toConvMessage(
                    currentUserId: _currentUserId!,
                  ))
              .toList();
          // Generar keys para todos los mensajes
          _itemKeys = List.generate(_messages.length, (index) => GlobalKey());
          _isLoading = false;
        });
        // Esperar a que se renderice completamente
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                _jumpToFirstUnreadOrBottom();
              }
            });
          }
        });
      } else {
        setState(() {
          _error = S.of(context).errorMessage(result['error']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = S.of(context).errorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCounterpartAvatar() async {
    try {
      if (widget.otherUserId == null) return;
      if ((widget.avatarUrl ?? '').isNotEmpty) {
        setState(() {
          _counterpartAvatarUrl = _resolveAvatar(widget.avatarUrl!);
        });
        return;
      }
      final res = await _profileService.getProfileByUserId(widget.otherUserId!);
      if (res['success'] == true && res['data'] != null) {
        final profile = res['data'] as Profile;
        final url = _resolveAvatar(profile.profileImage ?? '');
        if (url.isNotEmpty && mounted) {
          setState(() {
            _counterpartAvatarUrl = url;
          });
        }
      }
    } catch (_) {}
  }

  void _openWebSocket() async {
    try {
      if (_currentUserId == null || widget.otherUserId == null) return;

      final roomId = _computeRoomId(_currentUserId!, widget.otherUserId!);

      final accessToken = await _tokenStorage.getAccessToken();

      final wsUri1 = AppConfig.buildWsUri('${AppConfig.wsChatPath}$roomId/',
          token: accessToken);

      WebSocketChannel? ch;
      try {
        ch = WebSocketChannel.connect(wsUri1);
      } catch (_) {}
      if (ch == null) {
        final wsUri2 = AppConfig.buildWsUri(AppConfig.wsChatPath + roomId,
            token: accessToken);
        try {
          ch = WebSocketChannel.connect(wsUri2);
        } catch (_) {}
      }
      if (ch == null) {
        final roomRev = '${widget.otherUserId!}-${_currentUserId!}';
        final wsUri3 = AppConfig.buildWsUri('${AppConfig.wsChatPath}$roomRev/',
            token: accessToken);
        try {
          ch = WebSocketChannel.connect(wsUri3);
        } catch (_) {}
        if (ch == null) {
          final wsUri4 = AppConfig.buildWsUri(AppConfig.wsChatPath + roomRev,
              token: accessToken);
          try {
            ch = WebSocketChannel.connect(wsUri4);
          } catch (_) {}
        }
      }
      if (ch == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(S.of(context).wsRouteNotFound),
                backgroundColor: Colors.red),
          );
        }
        return;
      }
      _wsChannel = ch;

      _wsChannel!.stream.listen(
        (raw) {
          try {
            final data = raw is String ? jsonDecode(raw) : raw;
            if (data is Map<String, dynamic>) {
              final sender = data['sender'] as int?;
              final receiver = data['receiver'] as int?;
              final content = data['content'] as String? ?? '';
              final createdAtStr = data['created_at'] as String?;
              DateTime createdAt;
              if (createdAtStr != null) {
                createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
              } else {
                createdAt = DateTime.now();
              }

              final fromMe = sender != null && sender == _currentUserId;
              final msg = ConvMessage(
                text: content,
                fromMe: fromMe,
                time: _formatTime(createdAt),
                status: 'delivered',
                isRead: fromMe ? true : false,
              );

              if (mounted) {
                if (fromMe) {
                  final idx = _messages.lastIndexWhere((m) =>
                      m.fromMe && m.text == content && m.status == 'sent');
                  if (idx != -1) {
                    setState(() {
                      _messages[idx] = msg;
                    });
                  } else {
                    setState(() {
                      _messages.add(msg);
                    });
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _scrollToBottom();
                    }
                  });
                } else {
                  setState(() {
                    _messages.add(msg);
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _scrollToBottom();
                    }
                  });
                }
                // Posición sin animaciones gestionada al entrar al chat
              }
            }
          } catch (_) {}
        },
        onError: (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(S.of(context).wsError(err.toString())),
                  backgroundColor: Colors.red),
            );
          }
        },
        onDone: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(S.of(context).wsConnectionClosed),
                  backgroundColor: Colors.orange),
            );
          }
        },
        cancelOnError: false,
      );
    } catch (_) {}
  }

  String _computeRoomId(int a, int b) {
    final u1 = a < b ? a : b;
    final u2 = a < b ? b : a;
    return '$u1-$u2';
  }

  String _resolveAvatar(String url) {
    final u = (url).trim();
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

  List<ConvMessage> _getHardcodedMessages() {
    return [
      ConvMessage(
          text: S.of(context).chatExampleMessage1,
          fromMe: false,
          time: '10:40',
          status: 'delivered',
          isRead: false),
      ConvMessage(
          text: S.of(context).chatExampleMessage2,
          fromMe: true,
          time: '10:41',
          status: 'delivered',
          isRead: true),
      ConvMessage(
          text: S.of(context).chatExampleMessage3,
          fromMe: false,
          time: '10:42',
          status: 'delivered',
          isRead: false),
      ConvMessage(
          text: S.of(context).chatExampleMessage4,
          fromMe: true,
          time: '10:43',
          status: 'delivered',
          isRead: true),
      ConvMessage(
          text: S.of(context).chatExampleMessage5,
          fromMe: false,
          time: '10:44',
          status: 'delivered',
          isRead: false),
      ConvMessage(
          text: S.of(context).chatExampleMessage6,
          fromMe: true,
          time: '10:45',
          status: 'delivered',
          isRead: true),
    ];
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (widget.otherUserId == null) {
      // Modo offline - solo agregar localmente
      setState(() {
        _messages.add(ConvMessage(
            text: text,
            fromMe: true,
            time: S.of(context).nowLabel,
            status: 'delivered',
            isRead: true));
        _controller.clear();
      });
      return;
    }

    try {
      setState(() {
        _messages.add(ConvMessage(
            text: text,
            fromMe: true,
            time: S.of(context).sendingMessage,
            status: 'sent',
            isRead: true));
        _controller.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBottom();
        }
      });

      if (_currentUserId == null || widget.otherUserId == null) {
        return;
      }

      final payload = {
        'sender': _currentUserId!,
        'receiver': widget.otherUserId!,
        'content': text,
      };

      if (_wsChannel == null) {
        final idx = _messages.lastIndexWhere(
            (m) => m.fromMe && m.text == text && m.status == 'sent');
        if (idx != -1) {
          setState(() {
            _messages[idx] = ConvMessage(
                text: text,
                fromMe: true,
                time: S.of(context).errorSendingMessage,
                status: 'sent',
                isRead: true);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.of(context).wsConnectionUnavailable),
              backgroundColor: Colors.red),
        );
        return;
      }

      _wsChannel!.sink.add(jsonEncode(payload));

      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        final idx = _messages.lastIndexWhere(
            (m) => m.fromMe && m.text == text && m.status == 'sent');
        if (idx != -1) {
          setState(() {
            _messages[idx] = ConvMessage(
                text: text,
                fromMe: true,
                time: S.of(context).errorSendingMessage,
                status: 'sent',
                isRead: true);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(S.of(context).serverNoConfirmation),
                backgroundColor: Colors.red),
          );
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.verified, color: Colors.blue, size: 18),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) async {
              if (value == 'clear') {
                await _confirmAndClearConversation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'clear',
                child: Text(S.of(context).clearChatTitle),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              cs.primary.withValues(alpha: 0.06),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Text(S.of(context).todayLabel,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.black12,
                        backgroundImage:
                            (_counterpartAvatarUrl ?? '').isNotEmpty
                                ? NetworkImage(_counterpartAvatarUrl!)
                                : null,
                        child: (_counterpartAvatarUrl ?? '').isEmpty
                            ? const Icon(Icons.person, color: Colors.black54)
                            : null,
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(S.of(context).matchedWithUser(widget.title),
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  final align =
                      m.fromMe ? Alignment.centerRight : Alignment.centerLeft;
                  final cs = Theme.of(context).colorScheme;

                  return KeyedSubtree(
                    key: _getItemKey(index),
                    child: Align(
                      alignment: align,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: m.fromMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 280),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    m.fromMe ? cs.primary : AppTheme.grayColor,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x11000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 4)),
                                ],
                              ),
                              child: Text(
                                m.text,
                                style: TextStyle(
                                  color:
                                      m.fromMe ? cs.onPrimary : Colors.black87,
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  m.time,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black45),
                                ),
                                if (m.fromMe) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    m.status == 'delivered'
                                        ? Icons.done_all
                                        : Icons.check,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: Colors.black54),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: S.of(context).typingPlaceholder,
                                border: InputBorder.none,
                                hintStyle:
                                    const TextStyle(color: Colors.black38),
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.schedule, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: AppTheme.getMintButtonDecoration(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.black),
                      onPressed: () async {
                        await _sendMessage();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndClearConversation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(S.of(context).clearChatTitle),
          content: Text(S.of(context).clearChatConfirmation),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(S.of(context).cancelButton)),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(S.of(context).clearButton)),
          ],
        );
      },
    );
    if (ok != true) return;

    if (widget.otherUserId == null) {
      setState(() {
        _messages = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).chatClearedLocally)),
      );
      return;
    }

    final res = await _messageService.clearConversation(widget.otherUserId!);
    if (res['success'] == true) {
      setState(() {
        _messages = [];
        _itemKeys = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).chatClearedForAccount)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(S.of(context).errorMessage(res['error'])),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    try {
      _wsChannel?.sink.close();
    } catch (_) {}
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return S.of(context).nowLabel;
    } else if (difference.inHours < 1) {
      return S.of(context).minutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  GlobalKey _getItemKey(int index) {
    if (index < _itemKeys.length) return _itemKeys[index];
    while (_itemKeys.length <= index) {
      _itemKeys.add(GlobalKey());
    }
    return _itemKeys[index];
  }

  void _jumpToFirstUnreadOrBottom() {
    if (_messages.isEmpty) return;
    // Buscar el ÚLTIMO mensaje no leído del otro usuario, avanzando hacia abajo
    int idx = _messages.lastIndexWhere((m) => !m.isRead && !m.fromMe);
    // Si no hay mensajes no leídos, ir al final (último mensaje de abajo)
    if (idx == -1) idx = _messages.length - 1;
    if (idx < 0 || idx >= _messages.length) return;
    final key = _getItemKey(idx);
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: Duration.zero,
        alignment:
            1.0, // Posicionar el objetivo hacia la parte inferior del viewport
      );
    }
    // Si no se encontró el contexto, intentar después de un pequeño delay
    else {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          final retryCtx = key.currentContext;
          if (retryCtx != null) {
            Scrollable.ensureVisible(
              retryCtx,
              duration: Duration.zero,
              alignment:
                  1.0, // Posicionar el objetivo hacia la parte inferior del viewport
            );
          }
        }
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(pos);
  }
}
