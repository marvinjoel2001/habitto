import 'package:flutter/material.dart';
import '../../../../features/matching/data/services/matching_service.dart';
import '../../../../features/properties/data/services/property_service.dart';
import '../../../../features/properties/data/services/photo_service.dart';
import '../../../../features/properties/domain/entities/property.dart';
import '../../../../features/properties/domain/entities/photo.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/custom_network_image.dart';
import '../../../../shared/widgets/swipe_property_card.dart';
import '../../../../core/services/api_service.dart';
import 'property_candidates_page.dart';
import 'package:habitto/config/app_config.dart';

class MatchRequestsPage extends StatefulWidget {
  final String userMode;

  const MatchRequestsPage({super.key, required this.userMode});

  @override
  State<MatchRequestsPage> createState() => _MatchRequestsPageState();
}

class _MatchRequestsPageState extends State<MatchRequestsPage> {
  final MatchingService _matchingService = MatchingService();
  final PropertyService _propertyService = PropertyService();
  final ApiService _apiService = ApiService();
  late final PhotoService _photoService = PhotoService(_apiService);

  final List<Map<String, dynamic>> _groupedRequests = [];
  final List<Property> _properties = [];
  final Map<int, int> _pendingCounts = {};
  final Map<int, int> _viewsCounts = {};
  final Map<int, String> _lastViews = {};

  final List<_TenantSwipeCardData> _tenantCards = [];

  bool _isLoading = true;
  String _error = '';

  bool get _isTenant => widget.userMode == 'inquilino';

  @override
  void initState() {
    super.initState();
    if (_isTenant) {
      _loadTenantSwipeDeck();
    } else {
      _loadOwnerDashboard();
    }
  }

  Future<void> _loadOwnerDashboard() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final propertiesResult = widget.userMode == 'agente'
          ? await _propertyService.getAgentProperties()
          : await _propertyService.getMyProperties();

      if (!propertiesResult['success']) {
        setState(() {
          _error = propertiesResult['error'] ?? 'Error cargando propiedades';
          _isLoading = false;
        });
        return;
      }

      final propertiesData =
          propertiesResult['data'] as Map<String, dynamic>? ?? {};
      final properties =
          propertiesData['properties'] as List<Property>? ?? <Property>[];

      final requestsResult = await _matchingService.getPendingMatchRequests();
      final requests = (requestsResult['data'] as List<dynamic>?) ?? [];
      final Map<int, Map<String, dynamic>> grouped = {};
      final Map<int, int> pendingCounts = {};

      for (final req in requests) {
        final property = req['property'] as Map<String, dynamic>? ?? {};
        final propId = property['id'] as int? ?? 0;
        if (propId == 0) continue;
        pendingCounts[propId] = (pendingCounts[propId] ?? 0) + 1;
        if (!grouped.containsKey(propId)) {
          grouped[propId] = {
            'property': property,
            'requests': <Map<String, dynamic>>[],
          };
        }
        grouped[propId]!['requests'].add(req);
      }

      final viewsResult = await _apiService.get('/api/properties/views/');
      final Map<int, int> viewsCounts = {};
      final Map<int, String> lastViews = {};
      List<dynamic> viewItems = <dynamic>[];
      if (viewsResult['success'] == true) {
        final dynamic viewsData = viewsResult['data'];
        final dynamic payload = (viewsData is Map && viewsData['data'] != null)
            ? viewsData['data']
            : viewsData;
        viewItems = payload is List
            ? payload
            : (payload is Map && payload['results'] is List)
                ? payload['results'] as List<dynamic>
                : <dynamic>[];
      }
      if (viewItems.isEmpty) {
        final statsResult =
            await _apiService.get('/api/properties/interaction_stats/');
        if (statsResult['success'] == true) {
          final dynamic statsData = statsResult['data'];
          final dynamic payload =
              (statsData is Map && statsData['data'] != null)
                  ? statsData['data']
                  : statsData;
          viewItems = payload is Map && payload['by_property'] is List
              ? payload['by_property'] as List<dynamic>
              : <dynamic>[];
        }
      }

      for (final item in viewItems) {
        if (item is! Map<String, dynamic>) continue;
        final int propertyId = item['property_id'] ?? item['property'] ?? 0;
        if (propertyId == 0) continue;
        final int count =
            item['views'] ?? item['count'] ?? item['views_count'] ?? 0;
        viewsCounts[propertyId] = count;
        final String last = item['last_viewed']?.toString() ??
            item['last_view']?.toString() ??
            '';
        if (last.isNotEmpty) {
          lastViews[propertyId] = last;
        }
      }

      if (!mounted) return;
      setState(() {
        _properties
          ..clear()
          ..addAll(properties);
        _groupedRequests
          ..clear()
          ..addAll(grouped.values);
        _pendingCounts
          ..clear()
          ..addAll(pendingCounts);
        _viewsCounts
          ..clear()
          ..addAll(viewsCounts);
        _lastViews
          ..clear()
          ..addAll(lastViews);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<Set<int>> _loadTenantLockedPropertyIds() async {
    final Set<int> ids = {};
    final pendingResult = await _matchingService.getMyMatches(
        type: 'property', status: 'pending');
    final acceptedResult = await _matchingService.getMyMatches(
        type: 'property', status: 'accepted');
    final combined = <dynamic>[
      ...(pendingResult['data'] as List<dynamic>? ?? <dynamic>[]),
      ...(acceptedResult['data'] as List<dynamic>? ?? <dynamic>[]),
    ];
    for (final item in combined) {
      if (item is! Map<String, dynamic>) continue;
      final sid = item['subject_id'];
      final id = sid is int ? sid : int.tryParse(sid?.toString() ?? '');
      if (id != null) ids.add(id);
    }
    return ids;
  }

  Future<void> _loadTenantSwipeDeck() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final propsResult = await _propertyService.getProperties(
        orderByMatch: true,
        matchScore: 0,
        pageSize: 80,
      );
      if (propsResult['success'] != true || propsResult['data'] == null) {
        setState(() {
          _error = propsResult['error']?.toString() ?? 'Error cargando matches';
          _isLoading = false;
        });
        return;
      }
      final data = propsResult['data'] as Map<String, dynamic>;
      final List<Property> properties =
          data['properties'] as List<Property>? ?? <Property>[];
      final hiddenIds = await _loadTenantLockedPropertyIds();
      final available = properties
          .where((p) => p.isActive && !hiddenIds.contains(p.id))
          .toList();
      final cards = await Future.wait(
        available.map((p) async {
          final images = await _loadPropertyImages(p);
          return _TenantSwipeCardData(
            propertyId: p.id,
            title: p.address.isNotEmpty ? p.address : 'Propiedad',
            priceLabel: 'Bs ${p.price.toStringAsFixed(0)}',
            tags: [
              if (p.type.isNotEmpty) p.type,
              '${p.bedrooms} hab',
              '${p.bathrooms} baños',
            ],
            images: images,
          );
        }),
      );

      if (!mounted) return;
      setState(() {
        _tenantCards
          ..clear()
          ..addAll(cards);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _loadPropertyImages(Property property) async {
    final ordered = <String>[];
    final seen = <String>{};

    void addImage(String? raw) {
      final cleaned = AppConfig.sanitizeUrl((raw ?? '').trim());
      if (cleaned.isEmpty || seen.contains(cleaned)) return;
      seen.add(cleaned);
      ordered.add(cleaned);
    }

    addImage(property.mainPhoto);
    try {
      final res = await _photoService.getPropertyPhotos(property.id);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        final photos = data['photos'] as List<Photo>? ?? <Photo>[];
        for (final photo in photos) {
          addImage(photo.image);
        }
      }
    } catch (_) {}
    return ordered;
  }

  void _sendTenantLikeInBackground(int propertyId) async {
    try {
      final res = await _matchingService.likeProperty(propertyId);
      if (res['success'] != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res['error']?.toString() ?? 'Error al dar like')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar like')),
        );
      }
    }
  }

  void _sendTenantRejectInBackground(int propertyId) async {
    try {
      await _matchingService.rejectProperty(propertyId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar rechazo')),
        );
      }
    }
  }

  String _getPropertyMainPhoto(Property property) {
    final photoUrl = property.mainPhoto;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return AppConfig.sanitizeUrl(photoUrl);
    }
    return '';
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return 'Sin fecha';
    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return raw;
    }
  }

  String getPropertyMainPhoto(Property property) =>
      _getPropertyMainPhoto(property);

  String formatDate(String raw) => _formatDate(raw);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _isTenant ? 'Matches' : 'Matches de Propiedades',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isTenant ? _loadTenantSwipeDeck : _loadOwnerDashboard,
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
              ? Center(child: Text(_error))
              : _isTenant
                  ? buildTenantMatches()
                  : buildOwnerMatches(),
    );
  }

  Widget buildOwnerMatches() {
    if (_properties.isEmpty) {
      return const Center(child: Text('No hay propiedades registradas'));
    }
    return ListView.builder(
      itemCount: _properties.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final property = _properties[index];
        final pendingCount = _pendingCounts[property.id] ?? 0;
        final viewsCount = _viewsCounts[property.id] ?? 0;
        final lastView = _lastViews[property.id] ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: InkWell(
            onTap: () {
              final group = _groupedRequests.firstWhere(
                (g) =>
                    (g['property'] as Map<String, dynamic>?)?['id'] ==
                    property.id,
                orElse: () => {},
              );
              if (group.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyCandidatesPage(
                      property: group['property'] as Map<String, dynamic>,
                      requests: group['requests'] as List<Map<String, dynamic>>,
                    ),
                  ),
                ).then((_) => _loadOwnerDashboard());
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: CustomNetworkImage(
                    imageUrl: getPropertyMainPhoto(property),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.address,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: property.isActive
                                  ? AppTheme.primaryColor
                                      .withValues(alpha: 0.12)
                                  : Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              property.isActive ? 'Publicado' : 'Inactivo',
                              style: TextStyle(
                                color: property.isActive
                                    ? AppTheme.primaryColor
                                    : Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Bs ${property.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          buildMetricItem(
                            Icons.favorite_border,
                            'Matches activos',
                            '$pendingCount',
                          ),
                          const SizedBox(width: 12),
                          buildMetricItem(
                            Icons.visibility_outlined,
                            'Visibilidad',
                            '$viewsCount',
                          ),
                        ],
                      ),
                      if (lastView.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Última vista: ${formatDate(lastView)}',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildMetricItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTenantMatches() {
    if (_tenantCards.isEmpty) {
      return const Center(
          child: Text('No hay propiedades nuevas para mostrar por ahora'));
    }
    return _TenantSwipeDeck(
      cards: _tenantCards,
      onLike: (card) {
        _sendTenantLikeInBackground(card.propertyId);
      },
      onReject: (card) {
        _sendTenantRejectInBackground(card.propertyId);
      },
    );
  }
}

class _TenantSwipeCardData {
  final int propertyId;
  final String title;
  final String priceLabel;
  final List<String> tags;
  final List<String> images;

  const _TenantSwipeCardData({
    required this.propertyId,
    required this.title,
    required this.priceLabel,
    required this.tags,
    required this.images,
  });
}

typedef _TenantCardAction = void Function(_TenantSwipeCardData card);

class _TenantSwipeDeck extends StatefulWidget {
  final List<_TenantSwipeCardData> cards;
  final _TenantCardAction onLike;
  final _TenantCardAction onReject;

  const _TenantSwipeDeck({
    required this.cards,
    required this.onLike,
    required this.onReject,
  });

  @override
  State<_TenantSwipeDeck> createState() => _TenantSwipeDeckState();
}

class _TenantSwipeDeckState extends State<_TenantSwipeDeck>
    with SingleTickerProviderStateMixin {
  late List<_TenantSwipeCardData> _queue;
  double _dragDx = 0.0;
  bool _isDragging = false;
  late AnimationController _animController;
  Animation<double>? _animDx;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _queue = List<_TenantSwipeCardData>.from(widget.cards);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didUpdateWidget(covariant _TenantSwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cards != widget.cards) {
      _queue = List<_TenantSwipeCardData>.from(widget.cards);
      _dragDx = 0.0;
      _isDragging = false;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _animateTo(double target) async {
    _animController.stop();
    final tween = Tween<double>(begin: _dragDx, end: target);
    _animDx = tween.animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ))
      ..addListener(() {
        setState(() => _dragDx = _animDx!.value);
      });
    await _animController.forward(from: 0.0);
  }

  Future<void> _handleLike() async {
    if (_queue.isEmpty || _isAnimating) return;
    _isAnimating = true;
    final width = MediaQuery.of(context).size.width;
    final current = _queue.first;
    await _animateTo(width * 1.2);
    if (!mounted) return;
    setState(() {
      _queue.removeAt(0);
      _dragDx = 0.0;
      _isDragging = false;
    });
    widget.onLike(current);
    _isAnimating = false;
  }

  Future<void> _handleReject() async {
    if (_queue.isEmpty || _isAnimating) return;
    _isAnimating = true;
    final width = MediaQuery.of(context).size.width;
    final current = _queue.first;
    await _animateTo(-width * 1.2);
    if (!mounted) return;
    setState(() {
      final moved = _queue.removeAt(0);
      _queue.add(moved);
      _dragDx = 0.0;
      _isDragging = false;
    });
    widget.onReject(current);
    _isAnimating = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return const Center(child: Text('Sin propiedades para swipe'));
    }
    final top = _queue.first;
    final second = _queue.length > 1 ? _queue[1] : null;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    const actionsBottom = 74.0;
    const actionRowHeight = 86.0;
    const reserveExtra = 12.0;
    final reservedBottom =
        actionsBottom + actionRowHeight + reserveExtra + safeBottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = (constraints.maxHeight - reservedBottom)
            .clamp(280.0, constraints.maxHeight);
        return Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: cardHeight,
                child: Stack(
                  children: [
                    if (second != null)
                      Transform.translate(
                        offset: const Offset(0, 14),
                        child: Transform.scale(
                          scale: 0.96,
                          alignment: Alignment.topCenter,
                          child: SwipePropertyCard(
                            images: second.images,
                            title: second.title,
                            priceLabel: second.priceLabel,
                            tags: second.tags,
                            likeProgress: 0.0,
                            outerHorizontalPadding: 4,
                            outerTopPadding: 1,
                            overlayBottomSpace: 52,
                          ),
                        ),
                      ),
                    Transform.translate(
                      offset: Offset(_dragDx, 0),
                      child: Transform.rotate(
                        angle: _dragDx * 0.0009,
                        child: GestureDetector(
                          onHorizontalDragStart: (_) =>
                              setState(() => _isDragging = true),
                          onHorizontalDragUpdate: (details) {
                            if (_isAnimating) return;
                            setState(() => _dragDx += details.delta.dx);
                          },
                          onHorizontalDragEnd: (details) async {
                            if (_isAnimating) return;
                            final width = MediaQuery.of(context).size.width;
                            final threshold = width * 0.35;
                            final vx = details.velocity.pixelsPerSecond.dx;
                            const velocityThreshold = 700;
                            final shouldDismiss = _dragDx.abs() > threshold ||
                                vx.abs() > velocityThreshold;
                            if (!shouldDismiss) {
                              await _animateTo(0.0);
                              if (!mounted) return;
                              setState(() {
                                _dragDx = 0.0;
                                _isDragging = false;
                              });
                              return;
                            }
                            final right = (_dragDx + vx * 0.001) > 0;
                            if (right) {
                              await _handleLike();
                            } else {
                              await _handleReject();
                            }
                          },
                          child: SwipePropertyCard(
                            images: top.images,
                            title: top.title,
                            priceLabel: top.priceLabel,
                            tags: top.tags,
                            likeProgress: _dragDx > 0
                                ? (_dragDx /
                                        (MediaQuery.of(context).size.width *
                                            0.35))
                                    .clamp(0.0, 1.0)
                                : 0.0,
                            isDragging: _isDragging,
                            dragDx: _dragDx,
                            outerHorizontalPadding: 4,
                            outerTopPadding: 1,
                            overlayBottomSpace: 52,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: actionsBottom + safeBottom,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TenantActionButton(
                    icon: Icons.close_rounded,
                    borderColor: Colors.redAccent,
                    iconColor: Colors.redAccent,
                    size: 56,
                    onTap: _isAnimating ? null : _handleReject,
                  ),
                  const SizedBox(width: 18),
                  _TenantActionButton(
                    icon: Icons.favorite,
                    borderColor: AppTheme.primaryColor,
                    iconColor: Colors.white,
                    backgroundColor: AppTheme.primaryColor,
                    size: 78,
                    onTap: _isAnimating ? null : _handleLike,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TenantActionButton extends StatelessWidget {
  final IconData icon;
  final Color borderColor;
  final Color iconColor;
  final Color? backgroundColor;
  final double size;
  final Future<void> Function()? onTap;

  const _TenantActionButton({
    required this.icon,
    required this.borderColor,
    required this.iconColor,
    this.backgroundColor,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!.call(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.45),
      ),
    );
  }
}
