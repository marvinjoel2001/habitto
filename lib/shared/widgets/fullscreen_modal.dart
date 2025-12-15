import 'package:flutter/material.dart';

class ModalActionButton {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  ModalActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class FullscreenModal extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;
  final List<ModalActionButton> actionButtons;
  final String title;
  final String subtitle;

  const FullscreenModal({
    super.key,
    required this.isVisible,
    required this.onClose,
    required this.actionButtons,
    this.title = '',
    this.subtitle = '',
  });

  @override
  State<FullscreenModal> createState() => _FullscreenModalState();
}

class _FullscreenModalState extends State<FullscreenModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(FullscreenModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _animationController.isDismissed) {
      return const SizedBox.shrink();
    }

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // Overlay semi-transparente con 50% opacidad
              GestureDetector(
                onTap: _handleClose,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withValues(alpha: 0.5 * _fadeAnimation.value),
                ),
              ),

            // Contenido del modal
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título y subtítulo (si existen)
                    if (widget.title.isNotEmpty || widget.subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            if (widget.title.isNotEmpty)
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (widget.subtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  widget.subtitle,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Botones de acción
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive: adaptar el número de botones por fila
                          final crossAxisCount =
                              constraints.maxWidth > 400 ? 3 : 2;
                          final buttonSize =
                              constraints.maxWidth > 400 ? 80.0 : 64.0;

                          return Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            alignment: WrapAlignment.center,
                            children: widget.actionButtons.map((button) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Botón circular
                                  Container(
                                    width: buttonSize,
                                    height: buttonSize,
                                    decoration: BoxDecoration(
                                      color: button.color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          button.onTap();
                                          _handleClose();
                                        },
                                        borderRadius: BorderRadius.circular(
                                            buttonSize / 2),
                                        child: Center(
                                          child: Icon(
                                            button.icon,
                                            color: Colors.white,
                                            size: buttonSize * 0.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Etiqueta del botón
                                  Text(
                                    button.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),

                    // Botón de cierre
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: GestureDetector(
                        onTap: _handleClose,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '✕',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
    );
  }
}
