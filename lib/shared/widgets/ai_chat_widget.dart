import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:habitto/core/services/ai_service.dart';
import 'package:habitto/shared/theme/app_theme.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:permission_handler/permission_handler.dart';

class AiChatWidget extends StatefulWidget {
  final String userName;
  final Function(Map<String, dynamic>)? onProfileCreated;
  final VoidCallback? onClose;

  const AiChatWidget({
    super.key,
    required this.userName,
    this.onProfileCreated,
    this.onClose,
  });

  @override
  State<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends State<AiChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  // Message history: each item is {role: 'user'|'assistant', content: '...'}
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // Quick suggestions
  final List<String> _defaultSuggestions = [
    'Buscar departamento',
    'Buscar roomie',
    'Crear perfil de búsqueda',
  ];
  List<String> _currentSuggestions = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _currentSuggestions = _defaultSuggestions;
    // Initial greeting if history is empty
    if (_messages.isEmpty) {
      _messages.add({
        'role': 'assistant',
        'content':
            '¡Hola ${widget.userName}! Soy tu asistente de Habitto. ¿En qué puedo ayudarte hoy?'
      });
    }
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing speech: $e');
    }
  }

  Future<void> _requestMicrophonePermission() async {
    // Request permission explicitly with permission_handler
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      // If granted, start listening
      _startListening();
    } else if (status.isPermanentlyDenied) {
      // If permanently denied, open settings
      _showPermissionDialog();
    } else {
      // If denied (not permanently), do nothing or show a small hint
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Se requiere permiso de micrófono para usar esta función.')),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permiso de Micrófono'),
        content: const Text(
          'Para usar el chat de voz, Habitto necesita acceso a tu micrófono. '
          'Por favor, habilítalo en la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  void _startListening() async {
    if (_speechEnabled) {
      setState(() => _isListening = true);
      try {
        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
            });
          },
          localeId: 'es_ES',
        );
      } catch (e) {
        setState(() => _isListening = false);
        print('Error starting speech listen: $e');
      }
    } else {
      // Try initializing again if it wasn't enabled
      _initSpeech();
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      _controller.clear();
      _currentSuggestions = []; // Clear suggestions while thinking
    });
    _scrollToBottom();

    // Prepare history for API
    final historyForApi = _messages
        .map((m) => {
              'role': m['role']!,
              'content': m['content']!,
            })
        .toList();

    // Call AI
    final response = await _aiService.chatCompletion(
      history: historyForApi,
      systemPrompt: AiService.profileCreationSystemPrompt,
    );

    setState(() {
      _isLoading = false;
      if (response != null) {
        // Check for JSON payload in response
        if (response.contains('PROFILE_DATA')) {
          _handleProfileData(response);
          // Remove the JSON part for display if desired, or keep it
          // For now, we'll strip the raw JSON from the display if it's a block
          final cleanResponse = response
              .replaceAll(RegExp(r'\{.*"PROFILE_DATA".*\}', dotAll: true), '')
              .trim();
          _messages.add({
            'role': 'assistant',
            'content':
                cleanResponse.isNotEmpty ? cleanResponse : '¡Perfil creado!'
          });
        } else {
          _messages.add({'role': 'assistant', 'content': response});
        }

        // Update suggestions based on context (simple heuristic or parsed from AI)
        // For now, reset to default or empty
      } else {
        _messages.add({
          'role': 'assistant',
          'content':
              'Lo siento, tuve un problema al procesar tu mensaje. ¿Podrías intentarlo de nuevo?'
        });
      }
    });
    _scrollToBottom();
  }

  void _handleProfileData(String response) {
    try {
      // Simple regex to find the JSON block
      final RegExp regex = RegExp(r'\{.*"PROFILE_DATA".*\}',
          dotAll: true); // This might be too greedy or simple
      // Better: find the first { and last }
      final int startIndex = response.indexOf('{');
      final int endIndex = response.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1) {
        final jsonStr = response.substring(startIndex, endIndex + 1);
        final jsonMap = json.decode(jsonStr);
        if (jsonMap is Map<String, dynamic> &&
            jsonMap.containsKey('PROFILE_DATA')) {
          if (widget.onProfileCreated != null) {
            widget.onProfileCreated!(jsonMap['PROFILE_DATA']);
          }
        }
      }
    } catch (e) {
      print('Error parsing profile data: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Glassmorphism container
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white
                .withValues(alpha: 0.5), // Reduced opacity to 50% as requested
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
              left: BorderSide(
                color: Colors.white.withValues(alpha: 0.4),
                width: 0.5,
              ),
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0.4),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.profileGradientWarm,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asistente Habitto',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    AppTheme.blackColor.withValues(alpha: 0.9),
                              ),
                            ),
                            Text(
                              'En línea ahora',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (widget.onClose != null)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: AppTheme.blackColor.withValues(alpha: 0.7),
                          onPressed: widget.onClose,
                        ),
                      ),
                  ],
                ),
              ),

              // Chat Area
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          gradient: isUser
                              ? const LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.secondaryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isUser
                              ? null
                              : AppTheme
                                  .mediumGray, // Use a solid light gray instead of transparent white
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: isUser
                                ? const Radius.circular(20)
                                : const Radius.circular(4),
                            bottomRight: isUser
                                ? const Radius.circular(4)
                                : const Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isUser
                                  ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: isUser
                              ? null
                              : Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 1,
                                ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Text(
                          msg['content'] ?? '',
                          style: TextStyle(
                            color: isUser ? Colors.white : AppTheme.blackColor,
                            fontSize: 15,
                            height: 1.4,
                            fontWeight:
                                isUser ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Escribiendo...',
                              style: TextStyle(
                                color:
                                    AppTheme.blackColor.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Suggestions
              if (_currentSuggestions.isNotEmpty && !_isLoading)
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _currentSuggestions.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _sendMessage(_currentSuggestions[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                _currentSuggestions[index],
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Input Area
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                decoration: const BoxDecoration(
                  color: Colors.white, // Solid white background for input area
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.lightGrayishDark,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme
                              .mediumGray, // Solid background for input field
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          enabled: !_isListening,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: _isListening
                                ? 'Escuchando...'
                                : 'Escribe tu consulta aquí...',
                            hintStyle: TextStyle(
                              color: _isListening
                                  ? AppTheme.primaryColor
                                  : AppTheme.blackColor.withValues(alpha: 0.4),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            prefixIcon: Icon(
                              _isListening
                                  ? Icons.mic
                                  : Icons.auto_awesome_mosaic_outlined,
                              color: _isListening
                                  ? AppTheme.primaryColor
                                  : AppTheme.primaryColor
                                      .withValues(alpha: 0.5),
                              size: 20,
                            ),
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        if (_isListening) {
                          _stopListening();
                        } else if (_controller.text.isNotEmpty) {
                          _sendMessage(_controller.text);
                        } else {
                          // Check permission before listening
                          _requestMicrophonePermission();
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isListening
                                ? [Colors.redAccent, Colors.red]
                                : [
                                    AppTheme.primaryColor,
                                    AppTheme.secondaryColor,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _isListening
                                  ? Colors.redAccent.withValues(alpha: 0.4)
                                  : AppTheme.primaryColor
                                      .withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening
                              ? Icons.stop
                              : (_controller.text.isEmpty
                                  ? Icons.mic
                                  : Icons.send_rounded),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
