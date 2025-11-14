import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import '../../data/services/message_service.dart';
import '../../data/models/message_model.dart';
import 'package:habitto/core/services/token_storage.dart';
import 'package:habitto/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ConversationPage extends StatefulWidget {
  final String title;
  final int? otherUserId; // ID del otro usuario en la conversación

  const ConversationPage({
    super.key, 
    required this.title,
    this.otherUserId,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _controller = TextEditingController();
  final MessageService _messageService = MessageService();
  final TokenStorage _tokenStorage = TokenStorage();
  List<ConvMessage> _messages = [];
  bool _isLoading = true;
  String _error = '';
  int? _currentUserId;
  WebSocketChannel? _wsChannel;

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
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Obtener el ID del usuario actual
      final currentUserIdStr = await _tokenStorage.getCurrentUserId();
      final currentUserId = currentUserIdStr != null ? int.tryParse(currentUserIdStr) : null;
      
      if (currentUserId == null) {
        setState(() {
          _error = 'Error: No se pudo obtener el ID del usuario actual';
          _isLoading = false;
          _messages = _getHardcodedMessages(); // Fallback
        });
        return;
      }

      setState(() {
        _currentUserId = currentUserId;
      });

      _openWebSocket();

      final result = await _messageService.getConversation(currentUserId, widget.otherUserId!);
      
      if (result['success']) {
        final allMessages = result['data'] as List<MessageModel>;
        final messages = allMessages.length > 50 
            ? allMessages.sublist(allMessages.length - 50) 
            : allMessages;

        setState(() {
          _messages = messages.map((message) => message.toConvMessage(
            currentUserId: _currentUserId!,
          )).toList();
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
        _error = 'Error cargando conversación: $e';
        _isLoading = false;
      });
    }
  }

  void _openWebSocket() async {
    try {
      if (_currentUserId == null || widget.otherUserId == null) return;

      final roomId = _computeRoomId(_currentUserId!, widget.otherUserId!);
      final baseUri = Uri.parse(AppConfig.baseUrl);
      final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';

      final accessToken = await _tokenStorage.getAccessToken();

      final wsUri1 = Uri(
        scheme: wsScheme,
        host: baseUri.host,
        port: AppConfig.wsPort,
        path: AppConfig.wsChatPath + roomId + '/',
        queryParameters: accessToken != null ? {AppConfig.wsTokenQueryName: accessToken} : null,
      );

      WebSocketChannel? ch;
      try { ch = WebSocketChannel.connect(wsUri1); } catch (_) {}
      if (ch == null) {
        final wsUri2 = Uri(
          scheme: wsScheme,
          host: baseUri.host,
          port: AppConfig.wsPort,
          path: AppConfig.wsChatPath + roomId,
          queryParameters: accessToken != null ? {AppConfig.wsTokenQueryName: accessToken} : null,
        );
        try { ch = WebSocketChannel.connect(wsUri2); } catch (_) {}
      }
      if (ch == null) {
        final roomRev = '${widget.otherUserId!}_${_currentUserId!}';
        final wsUri3 = Uri(
          scheme: wsScheme,
          host: baseUri.host,
          port: AppConfig.wsPort,
          path: AppConfig.wsChatPath + roomRev + '/',
          queryParameters: accessToken != null ? {AppConfig.wsTokenQueryName: accessToken} : null,
        );
        try { ch = WebSocketChannel.connect(wsUri3); } catch (_) {}
        if (ch == null) {
          final wsUri4 = Uri(
            scheme: wsScheme,
            host: baseUri.host,
            port: AppConfig.wsPort,
            path: AppConfig.wsChatPath + roomRev,
            queryParameters: accessToken != null ? {AppConfig.wsTokenQueryName: accessToken} : null,
          );
          try { ch = WebSocketChannel.connect(wsUri4); } catch (_) {}
        }
      }
      if (ch == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WS 404: ruta /ws/chat/<room_id> no encontrada'), backgroundColor: Colors.red),
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
              );

              if (mounted) {
                if (fromMe) {
                  final idx = _messages.lastIndexWhere((m) => m.fromMe && m.text == content && m.status == 'sent');
                  if (idx != -1) {
                    setState(() {
                      _messages[idx] = msg;
                    });
                  } else {
                    setState(() {
                      _messages.add(msg);
                    });
                  }
                } else {
                  setState(() {
                    _messages.add(msg);
                  });
                }
              }
            }
          } catch (_) {}
        },
        onError: (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error de WebSocket: $err'), backgroundColor: Colors.red),
            );
          }
        },
        onDone: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conexión WebSocket cerrada'), backgroundColor: Colors.orange),
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
    return '$u1\_$u2';
  }

  List<ConvMessage> _getHardcodedMessages() {
    return [
      ConvMessage(text: 'Hola, ¿sigues disponible?', fromMe: false, time: '10:40', status: 'delivered'),
      ConvMessage(text: 'Sí, claro. ¿Qué te interesa saber?', fromMe: true, time: '10:41', status: 'delivered'),
      ConvMessage(text: '¿Incluye garaje y está cerca del centro?', fromMe: false, time: '10:42', status: 'delivered'),
      ConvMessage(text: 'Incluye garaje y está a 10 min del centro.', fromMe: true, time: '10:43', status: 'delivered'),
      ConvMessage(text: 'Perfecto, ¿podemos agendar una visita?', fromMe: false, time: '10:44', status: 'delivered'),
      ConvMessage(text: 'Mañana a las 15:00 te sirve.', fromMe: true, time: '10:45', status: 'delivered'),
    ];
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (widget.otherUserId == null) {
      // Modo offline - solo agregar localmente
      setState(() {
        _messages.add(ConvMessage(text: text, fromMe: true, time: 'Ahora', status: 'delivered'));
        _controller.clear();
      });
      return;
    }

    try {
      setState(() {
        _messages.add(ConvMessage(text: text, fromMe: true, time: 'Enviando...', status: 'sent'));
        _controller.clear();
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
        final idx = _messages.lastIndexWhere((m) => m.fromMe && m.text == text && m.status == 'sent');
        if (idx != -1) {
          setState(() {
            _messages[idx] = ConvMessage(text: text, fromMe: true, time: 'Error al enviar', status: 'sent');
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conexión WebSocket no disponible'), backgroundColor: Colors.red),
        );
        return;
      }

      _wsChannel!.sink.add(jsonEncode(payload));

      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        final idx = _messages.lastIndexWhere((m) => m.fromMe && m.text == text && m.status == 'sent');
        if (idx != -1) {
          setState(() {
            _messages[idx] = ConvMessage(text: text, fromMe: true, time: 'Error al enviar', status: 'sent');
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se recibió confirmación del servidor'), backgroundColor: Colors.red),
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
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              cs.primary.withOpacity(0.06),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  final align = m.fromMe ? Alignment.centerRight : Alignment.centerLeft;
                  final bubbleRadius = BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(m.fromMe ? 16 : 4),
                    bottomRight: Radius.circular(m.fromMe ? 4 : 16),
                  );

                  return Align(
                    alignment: align,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ClipRRect(
                        borderRadius: bubbleRadius,
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (m.fromMe ? cs.primary : cs.surface).withOpacity(m.fromMe ? 0.25 : 0.18),
                              borderRadius: bubbleRadius,
                              border: Border.all(
                                color: cs.primary.withOpacity(m.fromMe ? 0.35 : 0.28),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.text,
                                  style: TextStyle(
                                    color: m.fromMe ? Colors.black : Colors.black87,
                                    fontSize: 14,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        m.time,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (m.fromMe)
                                        Icon(
                                          m.status == 'delivered' ? Icons.done_all : Icons.check,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Barra de entrada estilo glass
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              filled: true,
                              icon: Icon(Icons.message, color: Colors.white.withValues(alpha: 0.7)),
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cs.primary.withOpacity(0.35)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.black),
                          onPressed: () async {
                            await _sendMessage();
                          },
                        ),
                      ),
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

  @override
  void dispose() {
    _controller.dispose();
    try {
      _wsChannel?.sink.close();
    } catch (_) {}
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
