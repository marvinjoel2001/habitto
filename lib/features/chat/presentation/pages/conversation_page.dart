import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ConversationPage extends StatefulWidget {
  final String title;

  const ConversationPage({Key? key, required this.title}) : super(key: key);

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _controller = TextEditingController();

  // Mensajes hardcodeados de ejemplo
  final List<ConvMessage> _messages = [
    ConvMessage(text: 'Hola, ¿sigues disponible?', fromMe: false, time: '10:40'),
    ConvMessage(text: 'Sí, claro. ¿Qué te interesa saber?', fromMe: true, time: '10:41'),
    ConvMessage(text: '¿Incluye garaje y está cerca del centro?', fromMe: false, time: '10:42'),
    ConvMessage(text: 'Incluye garaje y está a 10 min del centro.', fromMe: true, time: '10:43'),
    ConvMessage(text: 'Perfecto, ¿podemos agendar una visita?', fromMe: false, time: '10:44'),
    ConvMessage(text: 'Mañana a las 15:00 te sirve.', fromMe: true, time: '10:45'),
  ];

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
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.surface.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cs.primary.withOpacity(0.30)),
                          ),
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              border: InputBorder.none,
                              icon: Icon(Icons.message, color: Colors.black54),
                            ),
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
                          onPressed: () {
                            // Por ahora solo agregamos localmente el texto
                            final text = _controller.text.trim();
                            if (text.isEmpty) return;
                            setState(() {
                              _messages.add(ConvMessage(text: text, fromMe: true, time: 'Ahora'));
                              _controller.clear();
                            });
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
}

class ConvMessage {
  final String text;
  final bool fromMe;
  final String time;

  ConvMessage({required this.text, required this.fromMe, required this.time});
}
