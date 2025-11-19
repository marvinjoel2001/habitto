import 'package:flutter/material.dart';
import '../../../../shared/widgets/match_modal.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../../../shared/widgets/custom_bottom_navigation.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/swipe_property_card.dart';
import '../../../matching/data/services/matching_service.dart';
import '../../../profile/presentation/pages/profile_page.dart' as profile;
import '../../../profile/presentation/pages/create_search_profile_page.dart';
import '../../../search/presentation/pages/search_page.dart' as search;
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/data/services/profile_service.dart';
import '../../../properties/data/services/property_service.dart';
import '../../../properties/data/services/photo_service.dart';
import '../../../properties/domain/entities/property.dart' as domain;
import '../../../properties/domain/entities/photo.dart' as domain_photo;
import '../../../../core/services/api_service.dart';
import '../../../../config/app_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  profile.UserMode _userMode = profile.UserMode.inquilino;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _initUserModeFromProfile();
  }

  Future<void> _initUserModeFromProfile() async {
    try {
      final result = await _profileService.getCurrentProfile();
      if (result['success'] == true && result['data'] != null) {
        final Profile currentProfile = result['data']['profile'] as Profile;
        final profile.UserMode mode = _mapUserTypeToMode(currentProfile.userType);
        if (mounted) {
          setState(() {
            _userMode = mode;
          });
        }
      }
    } catch (_) {
      // Ignorar errores en la inicialización; se puede permanecer como inquilino por defecto
    }
  }

  profile.UserMode _mapUserTypeToMode(String userType) {
    switch (userType.toLowerCase()) {
      case 'propietario':
        return profile.UserMode.propietario;
      case 'agente':
        return profile.UserMode.agente;
      case 'inquilino':
      default:
        return profile.UserMode.inquilino;
    }
  }

  // Callback para recibir cambios de modo desde ProfilePage
  void _onUserModeChanged(profile.UserMode mode) {
    setState(() {
      _userMode = mode;
    });
  }

  List<Widget> get _pages => [
        const HomeContent(),
        const search.SearchPage(),
        const ChatPage(),
        profile.ProfilePage(
          onModeChanged: _onUserModeChanged,
        ),
      ];

  bool get _showAddButton =>
      _userMode == profile.UserMode.propietario ||
      _userMode == profile.UserMode.agente;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.getProfileBackground(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: false,
        body: _pages[_currentIndex],
        bottomNavigationBar: CustomBottomNavigation(
          currentIndex: _currentIndex,
          showAddButton: _showAddButton,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _noImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 56, color: Colors.black54),
          SizedBox(height: 8),
          Text('Sin imagen', style: TextStyle(color: Colors.black54, fontSize: 16)),
        ],
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  final String label;
  const _GlassTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatefulWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _CircleActionButton({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
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
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppTheme.getCardGradient(opacity: 0.28),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.30),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late final ApiService _apiService;
  late final PropertyService _propertyService;
  late final MatchingService _matchingService;
  late final PhotoService _photoService;
  late final ProfileService _profileService;

  bool _isLoading = true;
  String? _error;

  List<HomePropertyCardData> _cards = [];
  final Map<int, List<String>> _photoUrlsByProperty = {};
  final Map<int, int> _matchIdByPropertyId = {};
  HomePropertyCardData? _currentTopProperty;
  String _currentUserImageUrl = 'assets/images/userempty.png';
  final GlobalKey<PropertySwipeDeckState> _deckKey = GlobalKey<PropertySwipeDeckState>();

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
  void initState() {
    super.initState();
    _apiService = ApiService();
    _propertyService = PropertyService(apiService: _apiService);
    _matchingService = MatchingService();
    _photoService = PhotoService(_apiService);
    _profileService = ProfileService(apiService: _apiService);
    _loadAllProperties();
    _loadCurrentUserImage();
  }

  Future<void> _loadCurrentUserImage() async {
    try {
      final res = await _profileService.getCurrentProfile();
      if (res['success'] == true && res['data'] != null) {
        final profile = res['data']['profile'];
        final urlRaw = (profile?.profileImage ?? '') as String;
        final url = AppConfig.sanitizeUrl(urlRaw);
        print('Home: profileImage -> ' + url);
        if (url.isNotEmpty && mounted) {
          setState(() => _currentUserImageUrl = url);
        }
      }
    } catch (_) {
      // Mantener imagen por defecto
    }
  }

  Future<void> _loadAllProperties() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final propsRes = await _propertyService.getProperties(orderByMatch: true, matchScore: 0, pageSize: 50);
    if (propsRes['success'] == true && propsRes['data'] != null) {
      final backendData = propsRes['data'] as Map<String, dynamic>;
      final List<domain.Property> props = List<domain.Property>.from(backendData['properties'] as List);
      final cards = <HomePropertyCardData>[];
      for (final p in props) {
        final initialImages = <String>[];
        if (p.mainPhoto != null && p.mainPhoto!.isNotEmpty) {
          initialImages.add(AppConfig.sanitizeUrl(p.mainPhoto!));
          print('Home: property ' + p.id.toString() + ' mainPhoto -> ' + AppConfig.sanitizeUrl(p.mainPhoto!));
        }
        final typeLabel = p.type.isNotEmpty ? _capitalize(p.type) : 'Propiedad';
        final addressLabel = p.address.isNotEmpty ? _capitalize(p.address) : 'Propiedad';
        final formattedTitle = "$typeLabel · $addressLabel";
        cards.add(HomePropertyCardData(
          id: p.id,
          title: formattedTitle,
          priceLabel: p.price > 0 ? 'Bs. ${p.price.toStringAsFixed(0)}/mes' : '—',
          images: initialImages,
          distanceKm: 0.0,
          tags: [p.type.isNotEmpty ? _capitalize(p.type) : ''],
        ));
      }

      setState(() {
        _cards = cards;
        _isLoading = false;
      });

      for (final c in cards) {
        if (!mounted) return;
        await _loadPhotosForProperty(c.id);
      }
    } else {
      setState(() {
        _error = propsRes['error'] ?? 'No se pudieron cargar propiedades';
        _isLoading = false;
      });
    }
  }

  Widget _EmptyMatches() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 36),
        decoration: BoxDecoration(
          gradient: AppTheme.getCardGradient(opacity: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
              ),
              child: const Icon(Icons.favorite_border, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 24),
            const Text(
              'Por el momento no tenemos matchs',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Desliza hacia abajo para recargar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
            ),
            const SizedBox(height: 24),
            const _PullHintHand(),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPhotosForProperty(int propertyId) async {
    final res = await _photoService.getPropertyPhotos(propertyId);
    if (res['success'] == true && res['data'] != null) {
      final photos = (res['data']['photos'] as List<domain_photo.Photo>?);
      // Unificar y evitar duplicados; mantener main_photo si existe
      final urls = List<String>.from((photos ?? [])
          .map((ph) => AppConfig.sanitizeUrl(ph.image))
          .where((u) => u.isNotEmpty)
          .toSet()
          .toList());
      print('Home: property ' + propertyId.toString() + ' photo urls -> ' + urls.join(', '));
      setState(() {
        _photoUrlsByProperty[propertyId] = urls;
        _cards = _cards.map((c) => c.id == propertyId ? c.copyWith(images: urls) : c).toList();
      });
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.getProfileBackground(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter button at the top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.black),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateSearchProfilePage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadAllProperties();
              },
              child: _isLoading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: const [
                        SizedBox(height: 200),
                        Center(child: CircularProgressIndicator()),
                        SizedBox(height: 600),
                      ],
                    )
                  : (_cards.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            const SizedBox(height: 40),
                            _EmptyMatches(),
                            const SizedBox(height: 800),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.66,
                              child: PropertySwipeDeck(
                                key: _deckKey,
                                properties: _cards,
                                onLike: (p) async {
                                int? matchId = _matchIdByPropertyId[p.id];
                                if (matchId == null) {
                                  final midRes = await _matchingService.getOrCreateMatchIdForProperty(p.id);
                                  if (midRes['success'] == true && midRes['data'] != null) {
                                    matchId = midRes['data'] as int;
                                    _matchIdByPropertyId[p.id] = matchId;
                                  }
                                }
                                if (matchId == null) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No se pudo obtener match')),
                                    );
                                  }
                                  return;
                                }
                                final res = await _matchingService.likeMatch(matchId);
                                if (res['success'] != true) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(res['error'] ?? 'Error al hacer like')),
                                    );
                                  }
                                  return;
                                }
                                _spawnHeartsBurst();
                                final userImage = _currentUserImageUrl;
                                final propertyImage = (p.images.isNotEmpty)
                                    ? p.images[0]
                                    : 'assets/images/empty.jpg';
                                MatchModal.show(
                                  context,
                                  userImageUrl: userImage,
                                  propertyImageUrl: propertyImage,
                                  propertyTitle: p.title,
                                );
                              },
                              onReject: (p) async {
                                int? matchId = _matchIdByPropertyId[p.id];
                                if (matchId == null) {
                                  final midRes = await _matchingService.getOrCreateMatchIdForProperty(p.id);
                                  if (midRes['success'] == true && midRes['data'] != null) {
                                    matchId = midRes['data'] as int;
                                    _matchIdByPropertyId[p.id] = matchId;
                                  }
                                }
                                if (matchId != null) {
                                  final res = await _matchingService.rejectMatch(matchId);
                                  if (res['success'] != true && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(res['error'] ?? 'Error al rechazar')),
                                    );
                                  }
                                }
                              },
                              onTopChange: (p) => setState(() => _currentTopProperty = p),
                            ),
                            ),
                          ],
                        )),
            ),
          ),
          if (!_isLoading && _currentTopProperty != null && _cards.isNotEmpty)
            Container(
              color: Colors.transparent,
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleActionButton(
                    icon: Icons.rotate_left,
                    bgColor: Colors.transparent,
                    iconColor: Colors.amber,
                    onTap: () => _deckKey.currentState?.goBack(),
                  ),
                  const SizedBox(width: 18),
                  _CircleActionButton(
                    icon: Icons.close,
                    bgColor: Colors.transparent,
                    iconColor: Colors.redAccent,
                    onTap: () async {
                      final p = _currentTopProperty;
                      if (p != null) {
                        await _matchingService.rejectProperty(p.id);
                      }
                      _spawnBigXAndSwipeLeft();
                    },
                  ),
                  const SizedBox(width: 18),
                  _CircleActionButton(
                    icon: Icons.favorite,
                    bgColor: Colors.transparent,
                    iconColor: AppTheme.secondaryColor,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final p = _currentTopProperty;
                      if (p != null) {
                        final res = await _matchingService.likeProperty(p.id);
                        if (res['success'] == true) {
                          _spawnHeartsBurst();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('¡Like enviado! El propietario será notificado.'),
                              backgroundColor: AppTheme.secondaryColor,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          _deckKey.currentState?.swipeRight();
                        } else {
                          messenger.showSnackBar(
                            SnackBar(content: Text(res['error'] ?? 'Error al hacer like')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 18),
                  _CircleActionButton(
                    icon: Icons.star,
                    bgColor: Colors.transparent,
                    iconColor: Colors.blueAccent,
                    onTap: () async {
                      final p = _currentTopProperty;
                      if (p != null) {
                        final res = await _profileService.addFavoriteViaApi(p.id);
                        if (res['success'] != true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['error'] ?? 'Error al agregar favorito')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String imagePath, String label, BuildContext context) {
    return _FloatingCategoryItem(
      imagePath: imagePath,
      label: label,
    );
  }
}

// ---- Datos para las tarjetas en Home (derivadas de dominio) ----
class HomePropertyCardData {
  final int id;
  final String title;
  final String priceLabel;
  final List<String> images; // URLs de imágenes
  final double distanceKm;
  final List<String> tags; // etiquetas destacadas

  HomePropertyCardData({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.images,
    required this.distanceKm,
    required this.tags,
  });

  HomePropertyCardData copyWith({
    List<String>? images,
  }) {
    return HomePropertyCardData(
      id: id,
      title: title,
      priceLabel: priceLabel,
      images: images ?? this.images,
      distanceKm: distanceKm,
      tags: tags,
    );
  }
}

class _PullHintHand extends StatefulWidget {
  const _PullHintHand();

  @override
  State<_PullHintHand> createState() => _PullHintHandState();
}

class _PullHintHandState extends State<_PullHintHand> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  int _cycles = 0;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _offset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.25)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _startSequence();
  }

  Future<void> _startSequence() async {
    if (_running) return;
    _running = true;
    _cycles = 0;
    for (int i = 0; i < 3; i++) {
      await _controller.forward();
      await Future.delayed(const Duration(milliseconds: 150));
      await _controller.reverse();
      await Future.delayed(const Duration(milliseconds: 300));
      _cycles++;
    }
    _running = false;
    await Future.delayed(const Duration(minutes: 1));
    if (mounted) _startSequence();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: SlideTransition(
        position: _offset,
        child: Opacity(
          opacity: 0.7,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
            ),
            child: const Icon(Icons.touch_app, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

/* final List<Property> _mockProperties = [
  Property(
    title: 'Casa en Equipetrol',
    priceLabel: ' 2.200/mes',
    images: [
      'assets/images/casa1.jpg',
      'assets/images/casa2.jpg',
      'assets/images/casa3.jpg',
    ],
    distanceKm: 1.2,
    tags: ['Music', 'Anime', 'Reading'],
  ),
  Property(
    title: 'Departamento céntrico',
    priceLabel: ' 1.500/mes',
    images: [
      'assets/images/casa2.jpg',
      'assets/images/casa3.jpg',
      'assets/images/casa1.jpg',
    ],
    distanceKm: 0.8,
    tags: ['Gym', 'Coffee', 'Pet-friendly'],
  ),
  Property(
    title: 'Loft minimalista',
    priceLabel: ' 1.800/mes',
    images: [
      'assets/images/casa3.jpg',
      'assets/images/casa1.jpg',
      'assets/images/casa2.jpg',
    ],
    distanceKm: 2.5,
    tags: ['Tech', 'Books', 'Minimal'],
  ),
]; */

// ---- Deck con swipe ----
class PropertySwipeDeck extends StatefulWidget {
  final List<HomePropertyCardData> properties;
  final ValueChanged<HomePropertyCardData>? onTopChange;
  final ValueChanged<HomePropertyCardData>? onLike;
  final ValueChanged<HomePropertyCardData>? onReject;
  const PropertySwipeDeck({
    super.key,
    required this.properties,
    this.onTopChange,
    this.onLike,
    this.onReject,
  });

  @override
  State<PropertySwipeDeck> createState() => PropertySwipeDeckState();
}

class PropertySwipeDeckState extends State<PropertySwipeDeck>
    with SingleTickerProviderStateMixin {
  int topIndex = 0;
  double dragDx = 0.0; // para overlay del corazón
  bool _isDragging = false; // visual para card durante arrastre
  late AnimationController _animController;
  Animation<double>? _animDx;
  bool _pendingDismiss = false; // evita duplicar avance por listeners múltiples

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    // Reportar la tarjeta inicial al padre
    if (widget.properties.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final current = widget.properties[topIndex];
        widget.onTopChange?.call(current);
      });
    }

    // Listener único para completar animación y avanzar índice si corresponde
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          dragDx = 0.0;
          _isDragging = false;
          if (_pendingDismiss) {
            topIndex = (topIndex + 1).clamp(0, widget.properties.length);
          }
        });
        if (_pendingDismiss && topIndex < widget.properties.length) {
          final current = widget.properties[topIndex];
          widget.onTopChange?.call(current);
        }
        _pendingDismiss = false;
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleDragEnd(DraggableDetails details) {
    final dx = details.offset.dx;
    const threshold = 120; // px

    bool liked = dx > threshold;
    bool dismissed = dx.abs() > threshold;

    setState(() {
      dragDx = 0.0;
      _isDragging = false;
      if (dismissed) {
        topIndex = (topIndex + 1).clamp(0, widget.properties.length);
      }
      // Aquí podríamos persistir el like si liked == true
    });
  }

  void _animateTo(double target, {bool dismiss = false}) {
    _animController.stop();
    final tween = Tween<double>(begin: dragDx, end: target);
    _animDx = tween.animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ))
      ..addListener(() {
        setState(() {
          dragDx = _animDx!.value;
        });
      });
    _pendingDismiss = dismiss;
    _animController.forward(from: 0.0);
  }

  // --- Controles programáticos ---
  void swipeLeft() {
    final width = MediaQuery.of(context).size.width;
    _animateTo(-width * 1.2, dismiss: true);
  }

  void swipeRight() {
    final width = MediaQuery.of(context).size.width;
    _animateTo(width * 1.2, dismiss: true);
  }

  void goBack() {
    if (topIndex > 0) {
      setState(() {
        topIndex = topIndex - 1;
        dragDx = 0.0;
        _isDragging = false;
      });
      if (topIndex < widget.properties.length) {
        final current = widget.properties[topIndex];
        widget.onTopChange?.call(current);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (topIndex >= widget.properties.length) {
      return Center(
        child: Text(
          'No hay más propiedades',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
      );
    }

    final cards = <Widget>[];
    for (int i = widget.properties.length - 1; i >= topIndex; i--) {
      final order = i - topIndex;
      final scale = 1.0 - (order * 0.04);
      final translateY = order * 14.0;
      final property = widget.properties[i];
      final double dx = i == topIndex ? dragDx : 0.0;
      final double rotation = i == topIndex ? (dx * 0.0009) : 0.0;

      final card = Transform.translate(
        offset: Offset(0, translateY),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: i == topIndex
              ? Transform.translate(
                  offset: Offset(dx, 0),
                  child: Transform.rotate(
                    angle: rotation,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) => setState(() => _isDragging = true),
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          dragDx += details.delta.dx;
                        });
                      },
                      onHorizontalDragEnd: (details) {
                        final width = MediaQuery.of(context).size.width;
                        // Menor distancia requerida y opción por velocidad para activar swipe
                        final threshold = width * 0.35; // antes: 0.55
                        final vx = details.velocity.pixelsPerSecond.dx;
                        const velocityThreshold = 700; // px/seg

                        final shouldDismiss =
                            dragDx.abs() > threshold || vx.abs() > velocityThreshold;

                        if (shouldDismiss) {
                          final directionPositive = (dragDx + vx * 0.001) > 0;
                          final target = directionPositive ? width * 1.2 : -width * 1.2;
                          final current = widget.properties[topIndex];
                          if (directionPositive) {
                            widget.onLike?.call(current);
                          } else {
                            widget.onReject?.call(current);
                          }
                          _animateTo(target, dismiss: true);
                        } else {
                          _animateTo(0.0, dismiss: false);
                        }
                      },
                      child: SwipePropertyCard(
                        images: property.images,
                        title: property.title,
                        priceLabel: property.priceLabel,
                        tags: property.tags,
                        distanceKm: property.distanceKm,
                        likeProgress: _likeProgressFromDx(
                          dragDx,
                          MediaQuery.of(context).size.width,
                        ),
                        isDragging: _isDragging,
                        dragDx: dragDx,
                        onOpenImage: (index) => _openFullScreen(property.images, index),
                        outerTopPadding: 0.0,
                        overlayBottomSpace: 0.0,
                      ),
                    ),
                  ),
                )
            : SwipePropertyCard(
                images: property.images,
                title: property.title,
                priceLabel: property.priceLabel,
                tags: property.tags,
                distanceKm: property.distanceKm,
                likeProgress: 0.0,
                isDragging: false,
                dragDx: 0.0,
                onOpenImage: (index) => _openFullScreen(property.images, index),
                outerTopPadding: 0.0,
                overlayBottomSpace: 0.0,
              ),
        ),
      );
      cards.add(card);
    }

    return Stack(
      alignment: Alignment.center,
      children: cards,
    );
  }

  double _likeProgressFromDx(double dx, double width) {
    // Solo derecha; progreso en función del ancho con menor distancia requerida
    final required = width * 0.35; // coincide con nuevo threshold
    final p = (dx / required).clamp(0.0, 1.0);
    return p;
  }

  void _openFullScreen(List<String> images, int initialIndex) {
    if (images.isEmpty) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.98),
      pageBuilder: (context, anim1, anim2) {
        return FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
          onClose: () {},
        );
      },
      transitionDuration: const Duration(milliseconds: 160),
      transitionBuilder: (context, anim, secondary, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }
}

// ---- Tarjeta con carrusel ----
class PropertyCard extends StatefulWidget {
  final HomePropertyCardData property;
  final double likeProgress; // 0..1 para overlay corazón
  final bool isDragging; // visual feedback al arrastrar

  const PropertyCard({
    super.key,
    required this.property,
    required this.likeProgress,
    this.isDragging = false,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Placeholder used when a property has no images or a network image fails
  Widget _noImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 56, color: Colors.black54),
          SizedBox(height: 8),
          Text(
            'Sin imagen',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double bottomSpace = 16; // ligeramente por encima del bottom navigation
    return SizedBox.expand(
      child: AnimatedScale(
        scale: widget.isDragging ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: const Border.fromBorderSide(
            BorderSide(color: Colors.white, width: 1.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color:
                  Colors.white.withOpacity(widget.isDragging ? 0.35 : 0.0),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Carrusel
              PageView.builder(
                controller: _pageController,
                itemCount: widget.property.images.isNotEmpty ? widget.property.images.length : 1,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  if (widget.property.images.isEmpty) {
                    return _noImagePlaceholder();
                  }
                  final url = widget.property.images[i];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openFullScreen(i),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stack) => _noImagePlaceholder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Indicadores
              Positioned(
                top: 36,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      widget.property.images.isNotEmpty ? widget.property.images.length : 1, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 42 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(active ? 0.9 : 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ),
              ),

              // Distancia chip
              Positioned(
                // Alinear el centro del chip con los marcadores del carrusel
                top: 26,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_outlined,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.property.distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Overlay inferior con blur y gradiente acorde al fondo
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomSpace),
                      decoration: BoxDecoration(
                        // Usar el gradiente de cards para que el fondo plomito
                        // coincida con el que se percibe detrás del bottom navigation
                        gradient: AppTheme.getCardGradient(opacity: 0.62),
                        border: Border(
                          top: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                              width: 0.8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AutoSizeText(
                                  widget.property.title,
                                  maxLines: 3,
                                  minFontSize: 18,
                                  stepGranularity: 1,
                                  overflow: TextOverflow.visible,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.property.priceLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.property.tags
                                .map((t) => _GlassTag(label: t))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Overlay corazón cuando se arrastra a la derecha (tema)
              Positioned(
                right: 16,
                bottom: 16,
                child: Opacity(
                  opacity: widget.likeProgress,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.secondaryColor.withValues(alpha: 0.95),
                          AppTheme.secondaryColor.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.favorite, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      )
    );
  }

  void _openFullScreen(int initialIndex) {
    if (widget.property.images.isEmpty) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.98),
      pageBuilder: (context, anim1, anim2) {
        return FullScreenImageViewer(
          images: widget.property.images,
          initialIndex: initialIndex,
          onClose: () {},
        );
      },
      transitionDuration: const Duration(milliseconds: 160),
      transitionBuilder: (context, anim, secondary, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }
}

class _FloatingCategoryItem extends StatefulWidget {
  final String imagePath;
  final String label;

  const _FloatingCategoryItem({
    required this.imagePath,
    required this.label,
  });

  @override
  State<_FloatingCategoryItem> createState() => _FloatingCategoryItemState();
}

class _FloatingCategoryItemState extends State<_FloatingCategoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 3 * math.sin(_animation.value)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: 60,
                      height: 60,

                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Image.asset(
                              widget.imagePath,
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error cargando imagen: ${widget.imagePath}');
                                print('Detalle del error: $error');
                                return const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 24,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
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
    final startX = size.width / 2; // alineado al centro, donde están los botones
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
                final vy = math.sin(p.angle) * p.speed + 220; // empuje superior adicional
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
                            color: Colors.white.withOpacity(0.85),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
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

