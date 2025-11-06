import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../../../shared/widgets/custom_bottom_navigation.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../profile/presentation/pages/profile_page.dart' as profile;
import '../../../search/presentation/pages/search_page.dart' as search;
import '../../../chat/presentation/pages/chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  profile.UserMode _userMode = profile.UserMode.inquilino;

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true, // Cambiar a false para evitar que el body se extienda detrás
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
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Usando el gradiente del tema
      decoration: AppTheme.getProfileBackground(),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 0), // Quitar padding inferior
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola Ricardo!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        'Encuentra tu hogar ideal',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor, // Color mint del tema
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Barra de búsqueda con glassmorphism similar al bottom navigation
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      decoration: InputDecoration(
                        hintText: 'Buscar propiedades...',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: true,
                        icon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Categorías
              const Text(
                'Categorías',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCategoryItem('assets/icons/iconhouse.png', 'Casas', context),
                  _buildCategoryItem('assets/icons/iconaparment.png', 'Apartamentos', context),
                  _buildCategoryItem('assets/icons/iconoffice.png', 'Oficinas', context),
                  _buildCategoryItem('assets/icons/iconshop.png', 'Locales', context),
                ],
              ),
              const SizedBox(height: 16),

              // Propiedades destacadas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Propiedades Destacadas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Ver todas',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Tarjetero tipo Tinder con carrusel de fotos dentro de cada tarjeta
              Expanded(
                child: PropertySwipeDeck(properties: _mockProperties),
              ),
            ],
          ),
        ),
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

// ---- Modelo y datos mockeados ----
class Property {
  final String title;
  final String priceLabel;
  final List<String> images; // rutas locales por ahora
  final double distanceKm;

  Property({
    required this.title,
    required this.priceLabel,
    required this.images,
    required this.distanceKm,
  });
}

final List<Property> _mockProperties = [
  Property(
    title: 'Casa en Equipetrol',
    priceLabel: ' 2.200/mes',
    images: [
      'assets/images/casa1.jpg',
      'assets/images/casa2.jpg',
      'assets/images/casa3.jpg',
    ],
    distanceKm: 1.2,
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
  ),
];

// ---- Deck con swipe ----
class PropertySwipeDeck extends StatefulWidget {
  final List<Property> properties;
  const PropertySwipeDeck({super.key, required this.properties});

  @override
  State<PropertySwipeDeck> createState() => _PropertySwipeDeckState();
}

class _PropertySwipeDeckState extends State<PropertySwipeDeck>
    with SingleTickerProviderStateMixin {
  int topIndex = 0;
  double dragDx = 0.0; // para overlay del corazón

  void _handleDragEnd(DraggableDetails details) {
    final dx = details.offset.dx;
    const threshold = 120; // px

    bool liked = dx > threshold;
    bool dismissed = dx.abs() > threshold;

    setState(() {
      dragDx = 0.0;
      if (dismissed) {
        topIndex = (topIndex + 1).clamp(0, widget.properties.length);
      }
      // Aquí podríamos persistir el like si liked == true
    });
  }

  @override
  Widget build(BuildContext context) {
    if (topIndex >= widget.properties.length) {
      return Center(
        child: Text(
          'No hay más propiedades',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
      );
    }

    final cards = <Widget>[];
    for (int i = widget.properties.length - 1; i >= topIndex; i--) {
      final order = i - topIndex;
      final scale = 1.0 - (order * 0.04);
      final translateY = order * 14.0;
      final property = widget.properties[i];

      final card = Transform.translate(
        offset: Offset(0, translateY),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: i == topIndex
              ? Draggable<int>(
                  data: i,
                  onDragUpdate: (d) {
                    setState(() => dragDx = d.delta.dx + dragDx);
                  },
                  onDragEnd: _handleDragEnd,
                  feedback: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: PropertyCard(
                      property: property,
                      likeProgress: _likeProgressFromDx(dragDx),
                    ),
                  ),
                  childWhenDragging: const SizedBox.shrink(),
                  child: PropertyCard(
                    property: property,
                    likeProgress: _likeProgressFromDx(dragDx),
                  ),
                )
              : PropertyCard(
                  property: property,
                  likeProgress: 0.0,
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

  double _likeProgressFromDx(double dx) {
    // Solo derecha
    final p = (dx / 160).clamp(0.0, 1.0);
    return p;
  }
}

// ---- Tarjeta con carrusel ----
class PropertyCard extends StatefulWidget {
  final Property property;
  final double likeProgress; // 0..1 para overlay corazón

  const PropertyCard({
    super.key,
    required this.property,
    required this.likeProgress,
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

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
                itemCount: widget.property.images.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final path = widget.property.images[i];
                  return Image.asset(
                    path,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, size: 48),
                    ),
                  );
                },
              ),

              // Indicadores
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.property.images.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ),
              ),

              // Distancia chip
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
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

              // Gradiente inferior con info
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.property.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.property.priceLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Overlay corazón cuando se arrastra a la derecha
              Positioned(
                right: 16,
                bottom: 16,
                child: Opacity(
                  opacity: widget.likeProgress,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.6),
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
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
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

