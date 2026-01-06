import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../features/matching/data/services/matching_service.dart';
import '../../../../features/home/presentation/pages/home_page.dart';
import '../../../../shared/widgets/match_modal.dart';
import 'package:habitto/config/app_config.dart';
import 'package:habitto/shared/theme/app_theme.dart';
import '../../../../generated/l10n.dart';

class MatchRequestsPage extends StatefulWidget {
  const MatchRequestsPage({super.key});

  @override
  State<MatchRequestsPage> createState() => _MatchRequestsPageState();
}

class _MatchRequestsPageState extends State<MatchRequestsPage> {
  final MatchingService _matchingService = MatchingService();

  List<HomePropertyCardData> _matchRequests = [];
  bool _isLoading = true;
  String _error = '';

  final GlobalKey<PropertySwipeDeckState> _deckKey =
      GlobalKey<PropertySwipeDeckState>();
  HomePropertyCardData? _currentTopProperty;

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
        final cards = <HomePropertyCardData>[];

        for (final req in requests) {
          final match = req['match'] as Map<String, dynamic>? ?? {};
          final property = req['property'] as Map<String, dynamic>? ?? {};
          final interestedUser =
              req['interested_user'] as Map<String, dynamic>? ?? {};

          final userName =
              '${interestedUser['first_name'] ?? ''} ${interestedUser['last_name'] ?? ''}'
                  .trim();
          final userUsername =
              interestedUser['username'] as String? ?? 'Usuario';
          final displayName = userName.isNotEmpty ? userName : userUsername;

          String resolveAvatar(String? url) {
            final u =
                (url ?? '').trim().replaceAll('`', '').replaceAll('"', '');
            if (u.isEmpty) return '';
            if (u.startsWith('http://') || u.startsWith('https://')) return u;
            final base = Uri.parse(AppConfig.baseUrl);
            final abs = Uri(
                scheme: base.scheme,
                host: base.host,
                port: base.port == 0 ? null : base.port,
                path: u.startsWith('/') ? u : '/$u');
            return abs.toString();
          }

          final avatarUrl =
              resolveAvatar(interestedUser['profile_picture'] as String?);
          final score =
              match['score'] is num ? (match['score'] as num).round() : 0;
          final propertyTitle =
              property['title'] as String? ?? 'Propiedad sin título';
          final matchId = match['id'] is num ? (match['id'] as num).toInt() : 0;

          cards.add(HomePropertyCardData(
            id: matchId, // Usamos matchId en lugar de propertyId
            title: displayName, // Nombre del usuario como título
            priceLabel: '$score% Match', // Score como subtítulo
            images: [avatarUrl], // Foto de perfil como imagen principal
            distanceKm: 0.0,
            tags: [propertyTitle], // Título de la propiedad como tag
          ));
        }

        setState(() {
          _matchRequests = cards;
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

  void _spawnHeartsBurst() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => const _HeartsBurstOverlay(),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1750), () {
      entry.remove();
    });
  }

  void _spawnBigXAndSwipeLeft() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => const _BigXOverlay(),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 600), () {
      _deckKey.currentState?.swipeLeft();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Solicitudes de Match',
          style: TextStyle(
            color: onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: onSurface),
            onPressed: _loadMatchRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMatchRequests,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.darkGrayBase,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _matchRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes más solicitudes de match',
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.8),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Las nuevas solicitudes aparecerán aquí',
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadMatchRequests,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.darkGrayBase,
                            ),
                            child: const Text('Actualizar'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(builder: (ctx, constraints) {
                            // Altura de la fila de botones de acción
                            const double actionRowHeight = 80.0;
                            // Espacio para el bottom spacing que hemos aumentado (para levantar botones)
                            const double extraBottomSpacing = 85.0;
                            final pad = MediaQuery.of(ctx).padding;

                            // Ajustamos reservedBottom considerando el nuevo espaciado inferior
                            // para que la card se reduzca y no haya overflow.
                            final double reservedBottom = actionRowHeight +
                                extraBottomSpacing +
                                (pad.bottom > 0 ? pad.bottom : 0.0);

                            // Altura disponible para el área principal
                            // Reducimos un poco más para asegurar que los botones no tapen información vital
                            const double sizeReduction = 20.0;

                            final double availableHeight =
                                constraints.maxHeight -
                                    reservedBottom -
                                    sizeReduction;

                            // Altura dinámica de la card
                            final double cardHeight =
                                math.max(availableHeight, 400.0);

                            return SizedBox(
                              height: cardHeight,
                              child: PropertySwipeDeck(
                                key: _deckKey,
                                properties: _matchRequests,
                                overlayBottomSpace: -(actionRowHeight / 2),
                                onLike: (p) async {
                                  final res = await _matchingService
                                      .acceptMatchRequest(p.id);
                                  if (res['success'] != true) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(res['error'] ??
                                                'Error al aceptar')),
                                      );
                                    }
                                    return;
                                  }
                                  _spawnHeartsBurst();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Solicitud aceptada'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                  setState(() {
                                    _matchRequests.removeWhere(
                                        (element) => element.id == p.id);
                                  });
                                },
                                onReject: (p) async {
                                  final res = await _matchingService
                                      .rejectMatchRequest(p.id);
                                  if (res['success'] != true && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(res['error'] ??
                                              'Error al rechazar')),
                                    );
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Solicitud rechazada'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                  setState(() {
                                    _matchRequests.removeWhere(
                                        (element) => element.id == p.id);
                                  });
                                },
                                onTopChange: (p) =>
                                    setState(() => _currentTopProperty = p),
                              ),
                            );
                          }),
                        ),
                        if (_matchRequests.isNotEmpty)
                          Transform.translate(
                            offset: const Offset(0, -40.0),
                            child: Container(
                              color: Colors.transparent,
                              margin: EdgeInsets.zero,
                              padding: EdgeInsets.zero,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _CircleActionButton(
                                    icon: Icons.rotate_left,
                                    color: Colors.amber,
                                    size: 54,
                                    onTap: () =>
                                        _deckKey.currentState?.goBack(),
                                  ),
                                  const SizedBox(width: 18),
                                  _CircleActionButton(
                                    icon: Icons.close,
                                    color: Colors.redAccent,
                                    size: 54,
                                    onTap: () async {
                                      final p = _currentTopProperty;
                                      if (p != null) {
                                        await _matchingService
                                            .rejectMatchRequest(p.id);
                                        setState(() {
                                          _matchRequests.removeWhere(
                                              (element) => element.id == p.id);
                                        });
                                      }
                                      _spawnBigXAndSwipeLeft();
                                    },
                                  ),
                                  const SizedBox(width: 18),
                                  _CircleActionButton(
                                    icon: Icons.favorite,
                                    color: AppTheme.secondaryColor,
                                    size: 78,
                                    onTap: () async {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      final p = _currentTopProperty;
                                      if (p != null) {
                                        final res = await _matchingService
                                            .acceptMatchRequest(p.id);
                                        if (res['success'] == true) {
                                          _spawnHeartsBurst();
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Solicitud aceptada'),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          _deckKey.currentState?.swipeRight();
                                          setState(() {
                                            _matchRequests.removeWhere(
                                                (element) =>
                                                    element.id == p.id);
                                          });
                                        } else {
                                          messenger.showSnackBar(
                                            SnackBar(
                                                content: Text(res['error'] ??
                                                    'Error al aceptar')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
    );
  }
}

class _CircleActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double size;

  const _CircleActionButton({
    required this.icon,
    required this.color,
    this.onTap,
    this.size = 64.0,
  });

  @override
  State<_CircleActionButton> createState() => _CircleActionButtonState();
}

class _CircleActionButtonState extends State<_CircleActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child:
              Icon(widget.icon, color: Colors.white, size: widget.size * 0.45),
        ),
      ),
    );
  }
}

// Overlay de burst de corazones al presionar el botón de like
class _HeartsBurstOverlay extends StatefulWidget {
  const _HeartsBurstOverlay();

  @override
  State<_HeartsBurstOverlay> createState() => _HeartsBurstOverlayState();
}

class _HeartsBurstOverlayState extends State<_HeartsBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_HeartParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    final rand = math.Random();
    _particles = List.generate(22, (i) {
      // Ángulos hacia arriba (de -π a 0), más disperso
      final angle = -math.pi * rand.nextDouble();
      final speed = 140 + rand.nextDouble() * 180; // px/s
      final size = 18 + rand.nextDouble() * 16; // px
      final drift = (rand.nextDouble() * 160) - 80; // px lateral extra
      final delay = rand.nextDouble() * 0.25; // pequeño desfase
      return _HeartParticle(
        angle: angle,
        speed: speed,
        baseSize: size,
        driftX: drift,
        startDelay: delay,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final startX =
        size.width / 2; // alineado al centro, donde están los botones
    final startY = size.height - 140; // justo encima de la fila de acciones

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final tGlobal = _controller.value; // 0..1
          return Positioned.fill(
            child: Stack(
              children: _particles.map((p) {
                final t = (tGlobal - p.startDelay).clamp(0.0, 1.0);
                // Movimiento radial con drift lateral
                final vx = math.cos(p.angle) * p.speed;
                final vy = math.sin(p.angle) * p.speed +
                    220; // empuje superior adicional
                final x = startX + (vx * t) + (p.driftX * t);
                final y = startY - (vy * t);
                final opacity = (1.0 - t).clamp(0.0, 1.0);
                final scale = 1.0 + 0.4 * t;

                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: p.baseSize,
                        height: p.baseSize,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              colors: [
                                AppTheme.secondaryColor.withValues(alpha: 0.95),
                                AppTheme.secondaryColor.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: p.baseSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _HeartParticle {
  final double angle;
  final double speed;
  final double baseSize;
  final double driftX;
  final double startDelay;

  _HeartParticle({
    required this.angle,
    required this.speed,
    required this.baseSize,
    required this.driftX,
    required this.startDelay,
  });
}

// Overlay de X grande antes de avanzar
class _BigXOverlay extends StatefulWidget {
  const _BigXOverlay();

  @override
  State<_BigXOverlay> createState() => _BigXOverlayState();
}

class _BigXOverlayState extends State<_BigXOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scale = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Positioned.fill(
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: size.height * 0.38,
                  child: Center(
                    child: Opacity(
                      opacity: _opacity.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: Container(
                          width: size.width * 0.5,
                          height: size.width * 0.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.85),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: size.width * 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
