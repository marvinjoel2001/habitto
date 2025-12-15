import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';
import '../../generated/l10n.dart';

class MatchModal {
  static Future<void> show(
    BuildContext context, {
    required String userImageUrl,
    required String propertyImageUrl,
    String? propertyTitle,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: S.of(context).closeButton,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) {
        return _FullScreenMatchContent(
          userImageUrl: userImageUrl,
          propertyImageUrl: propertyImageUrl,
          propertyTitle: propertyTitle,
        );
      },
      transitionBuilder: (context, anim, secondary, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(opacity: curved, child: child);
      },
    );
    return;
  }
}

class _FullScreenMatchContent extends StatelessWidget {
  final String userImageUrl;
  final String propertyImageUrl;
  final String? propertyTitle;

  const _FullScreenMatchContent({
    required this.userImageUrl,
    required this.propertyImageUrl,
    this.propertyTitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Fondo degradado de tema a pantalla completa
          Positioned.fill(
            child: Container(
              decoration: AppTheme.getProfileBackground(),
            ),
          ),
          // Blur & Dark Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Contenido
          Positioned.fill(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Header opcional: nombre app o close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      // Título superior pequeño
                      Text(
                        S.of(context).matchTitle,
                        style: const TextStyle(
                          color: AppTheme.blackColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Zona de tarjetas inclinadas con íconos flotantes
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        height: 360,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 52,
                              top: 24,
                              child: Transform.rotate(
                                angle: -0.12,
                                child: _RoundedImageCard(
                                  url: userImageUrl,
                                  size: const Size(200, 300),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 52,
                              top: 0,
                              child: Transform.rotate(
                                angle: 0.12,
                                child: _RoundedImageCard(
                                  url: propertyImageUrl,
                                  size: const Size(200, 300),
                                ),
                              ),
                            ),
                            // Íconos flotantes
                            Positioned(
                              top: 40,
                              right: 60,
                              child: _FloatingIcon(
                                bg: cs.secondary,
                                icon: Icons.mail_outline,
                              ),
                            ),
                            Positioned(
                              top: 120,
                              left: 40,
                              child: _FloatingIcon(
                                bg: cs.primary,
                                icon: Icons.card_giftcard,
                              ),
                            ),
                            // Corazón central
                            Positioned(
                              bottom: 16,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppTheme.accentMint.withValues(alpha: 0.45),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.favorite,
                                    color: Colors.white, size: 30),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Título grande con énfasis (match con propiedad)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: S.of(context).matchPrefix,
                            style: const TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: S.of(context).matchWord,
                            style: TextStyle(
                              color: cs.secondary,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: '${S.of(context).matchSuffix}\n',
                            style: const TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: S.of(context).matchWith,
                            style: const TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: propertyTitle?.isNotEmpty == true
                                ? propertyTitle!
                                : S.of(context).thisProperty,
                            style: TextStyle(
                              color: cs.secondary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Subtítulo contextual
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      S.of(context).matchSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // CTA deslizable con glassmorphism
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: _DraggableCta(
                      onComplete: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedImageCard extends StatelessWidget {
  final String url;
  final Size size;

  const _RoundedImageCard({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _buildImage(url),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.cover);
    }
    return Image.asset(url, fit: BoxFit.cover);
  }
}

class _FloatingIcon extends StatelessWidget {
  final Color bg;
  final IconData icon;
  const _FloatingIcon({required this.bg, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _DraggableCta extends StatefulWidget {
  final VoidCallback onComplete;
  const _DraggableCta({required this.onComplete});

  @override
  State<_DraggableCta> createState() => _DraggableCtaState();
}

class _DraggableCtaState extends State<_DraggableCta>
    with TickerProviderStateMixin {
  double _drag = 0.0;
  late AnimationController _controller;
  late AnimationController _handController;
  late AnimationController _tapController;
  Animation<double>? _handAnimation;
  Animation<double>? _tapAnimation;
  bool _showHandHint = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));

    // Animación de tap (presionar)
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _tapAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );

    // Animación de deslizamiento
    _handController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _handAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _handController, curve: Curves.easeInOut),
    );

    // Iniciar secuencia de animación
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || !_showHandHint) return;

    // Repetir 3 veces
    for (int i = 0; i < 3; i++) {
      if (!mounted || !_showHandHint) return;

      // Animación de tap
      await _tapController.forward();
      await _tapController.reverse();
      await Future.delayed(const Duration(milliseconds: 100));

      // Animación de deslizamiento
      await _handController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      _handController.reset();

      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }

    // Esperar 1 minuto y repetir
    await Future.delayed(const Duration(seconds: 60));
    if (mounted && _showHandHint) {
      _startAnimationSequence();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _handController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _hideHandHint() {
    if (_showHandHint) {
      setState(() => _showHandHint = false);
      _handController.stop();
      _tapController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double height = 72;
    const double knobSize = 44;
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxDrag =
                  constraints.maxWidth - knobSize - 24; // padding lateral
              final double progress = (_drag / maxDrag).clamp(0.0, 1.0);
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Texto centrado
                  Text(
                    S.of(context).sendMessageButton,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  // Flechas a la derecha
                  const Positioned(
                    right: 18,
                    child: Icon(Icons.keyboard_double_arrow_right,
                        color: Colors.white70, size: 28),
                  ),
                  // Animación de mano deslizando (hint)
                  if (_showHandHint &&
                      _handAnimation != null &&
                      _tapAnimation != null)
                    AnimatedBuilder(
                      animation:
                          Listenable.merge([_handAnimation!, _tapAnimation!]),
                      builder: (context, child) {
                        final slideProgress = _handAnimation!.value;
                        final tapScale = _tapAnimation!.value;
                        final handPosition =
                            20 + (slideProgress * maxDrag * 0.65);

                        // Opacidad: aparece al inicio, se mantiene, desaparece al final
                        final opacity = slideProgress < 0.05
                            ? slideProgress * 20
                            : slideProgress > 0.85
                                ? (1.0 - slideProgress) * 6.67
                                : 1.0;

                        return Positioned(
                          left: handPosition,
                          child: Opacity(
                            opacity: opacity * 0.7,
                            child: Transform.scale(
                              scale: tapScale,
                              child: Transform.rotate(
                                angle: -0.4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.touch_app,
                                    color: Colors.white,
                                    size: 48,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
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
                  // Knob arrastrable
                  Positioned(
                    left: 12 + _drag,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) => _hideHandHint(),
                      onHorizontalDragUpdate: (details) {
                        _hideHandHint();
                        setState(() {
                          _drag =
                              (_drag + details.delta.dx).clamp(0.0, maxDrag);
                        });
                      },
                      onHorizontalDragEnd: (details) {
                        // Completa si cruza 65%
                        if (progress >= 0.65) {
                          widget.onComplete();
                        } else {
                          // Animar de vuelta
                          final tween = Tween<double>(begin: _drag, end: 0.0)
                              .animate(_controller);
                          _controller
                            ..reset()
                            ..addListener(() {
                              setState(() => _drag = tween.value);
                            })
                            ..forward();
                        }
                      },
                      child: Container(
                        width: knobSize,
                        height: knobSize,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35), width: 1),
                        ),
                        child: const Icon(Icons.chat_bubble,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
