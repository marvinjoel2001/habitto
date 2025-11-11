import 'package:flutter/material.dart';
import '../../../../shared/widgets/match_modal.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../../../shared/widgets/custom_bottom_navigation.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/swipe_property_card.dart';
import '../../../profile/presentation/pages/profile_page.dart' as profile;
import '../../../search/presentation/pages/search_page.dart' as search;
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/data/services/profile_service.dart';
import '../../../properties/data/services/property_service.dart';
import '../../../properties/data/services/photo_service.dart';
import '../../../properties/domain/entities/property.dart' as domain;
import '../../../properties/domain/entities/photo.dart' as domain_photo;
import '../../../../core/services/api_service.dart';

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
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

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _CircleActionButton({
    super.key,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 28),
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
  late final PhotoService _photoService;
  late final ProfileService _profileService;

  bool _isLoading = true;
  String? _error;

  List<HomePropertyCardData> _cards = [];
  final Map<int, List<String>> _photoUrlsByProperty = {};
  HomePropertyCardData? _currentTopProperty;
  String _currentUserImageUrl = 'assets/images/userempty.png';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _propertyService = PropertyService(apiService: _apiService);
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
        final url = (profile?.profileImage ?? '') as String;
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

    final result = await _propertyService.getProperties(
      isActive: true,
      page: 1,
      pageSize: 50,
      ordering: '-created_at',
    );

    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      final List<domain.Property> properties = data['properties'] ?? [];

      final cards = <HomePropertyCardData>[];
      for (final p in properties) {
        // Semilla de imágenes: si el backend incluye main_photo, úsalo para evitar repetición y N+1
        final initialImages = <String>[];
        if (p.mainPhoto != null && p.mainPhoto!.isNotEmpty) {
          initialImages.add(p.mainPhoto!);
        }
        cards.add(HomePropertyCardData(
          id: p.id,
          title: p.address.isNotEmpty ? p.address : 'Propiedad',
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

      for (final p in properties) {
        if (!mounted) return;
        await _loadPhotosForProperty(p.id);
      }
    } else {
      setState(() {
        _error = result['error'] ?? 'No se pudieron cargar propiedades';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPhotosForProperty(int propertyId) async {
    final res = await _photoService.getPropertyPhotos(propertyId);
    if (res['success'] == true && res['data'] != null) {
      final photos = (res['data']['photos'] as List<domain_photo.Photo>?);
      // Unificar y evitar duplicados; mantener main_photo si existe
      final urls = (photos ?? []).map((ph) => ph.image).where((u) => u.isNotEmpty).toSet().toList();
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!, style: const TextStyle(color: Colors.white)),
                      )
                    : PropertySwipeDeck(
                        properties: _cards,
                        onTopChange: (p) => setState(() => _currentTopProperty = p),
                      ),
          ),
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleActionButton(
                  icon: Icons.rotate_left,
                  bgColor: Colors.white,
                  iconColor: Colors.amber,
                ),
                const SizedBox(width: 18),
                _CircleActionButton(
                  icon: Icons.close,
                  bgColor: Colors.white,
                  iconColor: Colors.redAccent,
                ),
                const SizedBox(width: 18),
                _CircleActionButton(
                  icon: Icons.favorite,
                  bgColor: Colors.white,
                  iconColor: const Color.fromARGB(255, 247, 22, 1),
                  onTap: () {
                    final userImage = _currentUserImageUrl;
                    final propertyImage = (_currentTopProperty?.images.isNotEmpty ?? false)
                        ? _currentTopProperty!.images[0]
                        : 'assets/images/empty.jpg';
                    MatchModal.show(
                      context,
                      userImageUrl: userImage,
                      propertyImageUrl: propertyImage,
                      propertyTitle: _currentTopProperty?.title,
                    );
                  },
                ),
                const SizedBox(width: 18),
                _CircleActionButton(
                  icon: Icons.star,
                  bgColor: Colors.white,
                  iconColor: Colors.blueAccent,
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
  const PropertySwipeDeck({
    super.key,
    required this.properties,
    this.onTopChange,
  });

  @override
  State<PropertySwipeDeck> createState() => _PropertySwipeDeckState();
}

class _PropertySwipeDeckState extends State<PropertySwipeDeck>
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
                      onPanStart: (_) => setState(() => _isDragging = true),
                      onPanUpdate: (details) {
                        setState(() {
                          dragDx += details.delta.dx;
                        });
                      },
                      onPanEnd: (details) {
                        final width = MediaQuery.of(context).size.width;
                        final threshold = width * 0.55; // requiere arrastre más largo
                        if (dragDx.abs() > threshold) {
                          final target = dragDx > 0 ? width * 1.2 : -width * 1.2;
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
                        onOpenImage: (index) => _openFullScreen(property.images, index),
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
                  onOpenImage: (index) => _openFullScreen(property.images, index),
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
    // Solo derecha; progreso en función del ancho para menor sensibilidad
    final required = width * 0.55; // coincide con threshold visual
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
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
    final double bottomSpace = 16; // ligeramente por encima del bottom navigation
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
            BorderSide(color: Colors.white, width: 0.5),
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
                  return Padding(
                    padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 10),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openFullScreen(i),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
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
                        gradient: AppTheme.getCardGradient(opacity: 0.28),
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

              // Overlay corazón cuando se arrastra a la derecha (rojo)
              Positioned(
                right: 16,
                bottom: 16,
                child: Opacity(
                  opacity: widget.likeProgress,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.favorite, color: Colors.redAccent),
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

