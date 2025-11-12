import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../data/services/message_service.dart';
import '../../data/models/message_model.dart';
import 'package:habitto/core/services/token_storage.dart';

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

      final result = await _messageService.getConversation(currentUserId, widget.otherUserId!);
      
      if (result['success']) {
        final messages = result['data'] as List<MessageModel>;
        
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

  List<ConvMessage> _getHardcodedMessages() {
    return [
      ConvMessage(text: 'Hola, ¿sigues disponible?', fromMe: false, time: '10:40'),
      ConvMessage(text: 'Sí, claro. ¿Qué te interesa saber?', fromMe: true, time: '10:41'),
      ConvMessage(text: '¿Incluye garaje y está cerca del centro?', fromMe: false, time: '10:42'),
      ConvMessage(text: 'Incluye garaje y está a 10 min del centro.', fromMe: true, time: '10:43'),
      ConvMessage(text: 'Perfecto, ¿podemos agendar una visita?', fromMe: false, time: '10:44'),
      ConvMessage(text: 'Mañana a las 15:00 te sirve.', fromMe: true, time: '10:45'),
    ];
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (widget.otherUserId == null) {
      // Modo offline - solo agregar localmente
      setState(() {
        _messages.add(ConvMessage(text: text, fromMe: true, time: 'Ahora'));
        _controller.clear();
      });
      return;
    }

    try {
      // Agregar mensaje localmente primero para UX inmediata
      setState(() {
        _messages.add(ConvMessage(text: text, fromMe: true, time: 'Enviando...'));
        _controller.clear();
      });

      // Enviar mensaje a la API
      if (_currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: No se pudo obtener el ID del usuario actual'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await _messageService.sendMessage(
        senderId: _currentUserId!,
        receiverId: widget.otherUserId!,
        content: text,
      );

      if (result['success']) {
        // Actualizar el tiempo del último mensaje
        setState(() {
          _messages.last = ConvMessage(text: text, fromMe: true, time: 'Ahora');
        });
      } else {
        // Si falla, mostrar error pero mantener el mensaje localmente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _messages.last = ConvMessage(text: text, fromMe: true, time: 'Error');
        });
      }
    } catch (e) {
      // Si falla, mostrar error pero mantener el mensaje localmente
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar mensaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _messages.last = ConvMessage(text: text, fromMe: true, time: 'Error');
      });
    }
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
                                  child: Text(
                                    m.time,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                    ),
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
                            final text = _controller.text.trim();
                            if (text.isEmpty) return;
                            
                            // Limpiar el campo inmediatamente para mejor UX
                            _controller.clear();
                            
                            // Agregar mensaje localmente primero
                            final tempMessage = ConvMessage(text: text, fromMe: true, time: 'Enviando...');
                            setState(() {
                              _messages.add(tempMessage);
                            });
                            
                            // Enviar mensaje a través del API
                            if (widget.otherUserId != null) {
                              final result = await _messageService.sendMessage(
                                senderId: 1, // TODO: Obtener ID del usuario actual
                                receiverId: widget.otherUserId!,
                                content: text,
                              );
                              
                              if (result['success']) {
                                // Actualizar el mensaje local con tiempo real
                                setState(() {
                                  final index = _messages.indexOf(tempMessage);
                                  if (index != -1) {
                                    _messages[index] = ConvMessage(
                                      text: text, 
                                      fromMe: true, 
                                      time: _formatTime(DateTime.now())
                                    );
                                  }
                                });
                              } else {
                                // En caso de error, mostrar mensaje de error y mantener el mensaje local
                                setState(() {
                                  final index = _messages.indexOf(tempMessage);
                                  if (index != -1) {
                                    _messages[index] = ConvMessage(
                                      text: text, 
                                      fromMe: true, 
                                      time: 'Error al enviar'
                                    );
                                  }
                                });
                                
                                // Mostrar snackbar de error
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al enviar mensaje: ${result['error'] ?? 'Error desconocido'}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
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
