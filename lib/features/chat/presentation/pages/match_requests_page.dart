import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../features/matching/data/services/matching_service.dart';
import 'package:habitto/config/app_config.dart';
import 'package:habitto/shared/theme/app_theme.dart';

class MatchRequestsPage extends StatefulWidget {
  const MatchRequestsPage({super.key});

  @override
  State<MatchRequestsPage> createState() => _MatchRequestsPageState();
}

class _MatchRequestsPageState extends State<MatchRequestsPage>
    with SingleTickerProviderStateMixin {
  final MatchingService _matchingService = MatchingService();
  List<dynamic> _matchRequests = [];
  bool _isLoading = true;
  String _error = '';

  // Swipe animation controller
  late AnimationController _animationController;
  Animation<Offset>? _offsetAnimation;

  // Card tracking
  int _currentCardIndex = 0;
  bool _isDragging = false;
  Offset _dragPosition = Offset.zero;

  // Flag to indicate if we are animating off-screen
  bool _isAnimatingOut = false;
  int _pendingDirection = 0; // -1: Left (Reject), 1: Right (Accept)

  // Swipe thresholds
  static const double _swipeThreshold = 120.0;
  static const double _maxRotation = 0.3; // radians

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isAnimatingOut) {
          // Animation completed, move to next card
          final direction = _pendingDirection;
          final currentRequest = _currentCardIndex < _matchRequests.length
              ? _matchRequests[_currentCardIndex]
              : null;
          final matchId = currentRequest != null
              ? (currentRequest['match']?['id'] as int? ?? 0)
              : 0;

          setState(() {
            _currentCardIndex++;
            _dragPosition = Offset.zero;
            _isDragging = false;
            _isAnimatingOut = false;
            _pendingDirection = 0;
          });

          // Reset controller for next usage
          _animationController.reset();

          // Perform action after UI update
          if (direction == 1) {
            _acceptMatchRequest(matchId);
          } else if (direction == -1) {
            _rejectMatchRequest(matchId);
          }
        } else {
          // Reset animation (snap back) completed
          setState(() {
            _dragPosition = Offset.zero;
            _isDragging = false;
          });
          _animationController.reset();
        }
      }
    });

    _animationController.addListener(() {
      if (_offsetAnimation != null) {
        setState(() {
          _dragPosition = _offsetAnimation!.value;
        });
      }
    });

    _loadMatchRequests();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      if (mounted) {
        if (result['success']) {
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aceptar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _rejectMatchRequest(int matchId) async {
    try {
      final result = await _matchingService.rejectMatchRequest(matchId);
      if (mounted) {
        if (result['success']) {
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rechazar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Swipe gesture handling
  void _onPanStart(DragStartDetails details) {
    if (_currentCardIndex >= _matchRequests.length ||
        _animationController.isAnimating) return;

    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentCardIndex >= _matchRequests.length ||
        _animationController.isAnimating) return;

    setState(() {
      _dragPosition += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentCardIndex >= _matchRequests.length ||
        _animationController.isAnimating) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final width = MediaQuery.of(context).size.width;
    final threshold = width * 0.35;

    final shouldSwipeLeft = _dragPosition.dx < -threshold || velocity < -700;
    final shouldSwipeRight = _dragPosition.dx > threshold || velocity > 700;

    if (shouldSwipeLeft) {
      _swipeCardLeft();
    } else if (shouldSwipeRight) {
      _swipeCardRight();
    } else {
      _resetCardPosition();
    }
  }

  void _animateTo(Offset target, {bool isDismiss = false, int direction = 0}) {
    _isAnimatingOut = isDismiss;
    _pendingDirection = direction;

    _offsetAnimation = Tween<Offset>(
      begin: _dragPosition,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward(from: 0.0);
  }

  void _swipeCardLeft() {
    final width = MediaQuery.of(context).size.width;
    _animateTo(Offset(-width * 1.5, _dragPosition.dy),
        isDismiss: true, direction: -1);
  }

  void _swipeCardRight() {
    final width = MediaQuery.of(context).size.width;
    _animateTo(Offset(width * 1.5, _dragPosition.dy),
        isDismiss: true, direction: 1);
  }

  void _resetCardPosition() {
    _animateTo(Offset.zero, isDismiss: false);
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
      body: Column(
        children: [
          // Card stack area
          Expanded(
            child: _isLoading
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
                              color: onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: onSurface.withOpacity(0.8),
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
                    : _currentCardIndex >= _matchRequests.length
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: 64,
                                  color: onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tienes más solicitudes de match',
                                  style: TextStyle(
                                    color: onSurface.withOpacity(0.8),
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Las nuevas solicitudes aparecerán aquí',
                                  style: TextStyle(
                                    color: onSurface.withOpacity(0.6),
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
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final cardWidth = constraints.maxWidth * 0.9;
                              final cardHeight = constraints.maxHeight * 0.85;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_currentCardIndex + 1 <
                                      _matchRequests.length)
                                    _buildBackgroundCard(
                                        1, cardWidth, cardHeight),
                                  if (_currentCardIndex + 2 <
                                      _matchRequests.length)
                                    _buildBackgroundCard(
                                        2, cardWidth, cardHeight),
                                  _buildSwipeCard(cardWidth, cardHeight),
                                ],
                              );
                            },
                          ),
          ),

          // Action buttons
          if (_currentCardIndex < _matchRequests.length) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject button
                  GestureDetector(
                    onTap: _swipeCardLeft,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.2),
                            Colors.red.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Accept button
                  GestureDetector(
                    onTap: _swipeCardRight,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.secondaryColor.withOpacity(0.8),
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 32,
                        color: AppTheme.darkGrayBase,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildSwipeCard(double cardWidth, double cardHeight) {
    if (_currentCardIndex >= _matchRequests.length) {
      return const SizedBox.shrink();
    }

    final request = _matchRequests[_currentCardIndex];
    final match = request['match'] as Map<String, dynamic>? ?? {};
    final property = request['property'] as Map<String, dynamic>? ?? {};
    final interestedUser =
        request['interested_user'] as Map<String, dynamic>? ?? {};

    final userName =
        '${interestedUser['first_name'] ?? ''} ${interestedUser['last_name'] ?? ''}'
            .trim();
    final userUsername = interestedUser['username'] as String? ?? 'Usuario';
    final displayName = userName.isNotEmpty ? userName : userUsername;

    String resolveAvatar(String? url) {
      final u = (url ?? '').trim().replaceAll('`', '').replaceAll('"', '');
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
    final score = match['score'] is num ? (match['score'] as num).round() : 0;
    final propertyTitle =
        property['title'] as String? ?? 'Propiedad sin título';
    final propertyAddress =
        property['address'] as String? ?? 'Dirección no especificada';

    // Use _dragPosition directly, which is updated by animation listener
    final cardOffset = _dragPosition;
    final cardAngle = _isDragging
        ? (_dragPosition.dx / _swipeThreshold) * _maxRotation
        : (_dragPosition.dx / _swipeThreshold) * _maxRotation;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform(
        transform: Matrix4.identity()
          ..translate(cardOffset.dx, cardOffset.dy)
          ..rotateZ(cardAngle),
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.85),
                      Colors.white.withOpacity(0.65),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 65,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                          image: avatarUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarUrl.isEmpty
                            ? Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor.withOpacity(0.3),
                                      AppTheme.secondaryColor.withOpacity(0.3),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/userempty.png',
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF005041),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      flex: 35,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(24)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF005041),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '@$userUsername',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: const Color(0xFF1A1A1A)
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.secondaryColor
                                              .withOpacity(0.8),
                                          AppTheme.primaryColor
                                              .withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '$score%',
                                      style: const TextStyle(
                                        color: AppTheme.darkGrayBase,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Flexible(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor.withOpacity(0.1),
                                        AppTheme.secondaryColor
                                            .withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        propertyTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF005041),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        propertyAddress,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: const Color(0xFF1A1A1A)
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundCard(int offset, double cardWidth, double cardHeight) {
    final cardIndex = _currentCardIndex + offset;
    if (cardIndex >= _matchRequests.length) return const SizedBox.shrink();

    return Transform.scale(
      scale: 1.0 - (offset * 0.05),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.3 - (offset * 0.1)),
              Colors.white.withOpacity(0.2 - (offset * 0.1)),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2 - (offset * 0.05)),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
