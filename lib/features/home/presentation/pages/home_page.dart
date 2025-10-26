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

              // Lista de propiedades
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                      bottom: 120), // Añadir padding inferior aquí
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image:
                              AssetImage('assets/images/casa${index + 1}.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter:
                                  ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Casa en Equipetrol ${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '\$${(800 + index * 200)}/mes',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
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
                  },
                ),
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

