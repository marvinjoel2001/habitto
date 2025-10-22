import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/profile_mode_chip.dart';
import '../../../../shared/widgets/property_card.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../data/services/profile_service.dart';
import '../../domain/entities/profile.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/data/services/auth_service.dart';

enum UserMode { inquilino, propietario, agente }

class ProfilePage extends StatefulWidget {
  final Function(UserMode)? onModeChanged;

  const ProfilePage({
    Key? key,
    this.onModeChanged,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  UserMode _currentMode = UserMode.inquilino;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  Profile? _currentProfile;
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _profileService.getCurrentProfile();

      if (response['success'] == true) {
        // Extract both profile and user data from the response
        _currentProfile = response['profile'];
        _currentUser = response['user'];

        // Establecer el modo actual basado en el tipo de usuario
        if (_currentProfile != null) {
          _setModeFromUserType(_currentProfile!.userType);
        } else {
          // If no profile, default to inquilino
          _currentMode = UserMode.inquilino;
        }
      } else {
        print('Error cargando perfil: ${response['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando perfil: ${response['error']}')),
        );
      }
    } catch (e) {
      print('Error cargando perfil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando perfil: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          );
        },
      );

      if (shouldLogout == true) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        // Perform logout
        await _authService.logout();

        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to login page and clear navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/onboarding',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
      );
    }
  }

  void _setModeFromUserType(String userType) {
    switch (userType.toLowerCase()) {
      case 'inquilino':
        _currentMode = UserMode.inquilino;
        break;
      case 'propietario':
        _currentMode = UserMode.propietario;
        break;
      case 'agente':
        _currentMode = UserMode.agente;
        break;
      default:
        _currentMode = UserMode.inquilino;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _changeMode(UserMode mode) {
    if (_currentMode != mode) {
      _animationController.reset();
      setState(() {
        _currentMode = mode;
      });
      _animationController.forward();

      // Notificar el cambio de modo al padre
      if (widget.onModeChanged != null) {
        widget.onModeChanged!(mode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.getProfileBackground(),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: AppTheme.getProfileBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildModernHeader(),
                const SizedBox(height: 8),
                _buildModernModeSelector(),
                const SizedBox(height: 20),
                _buildModernProfileSection(),
                const SizedBox(height: 40),
                _buildModernActionButtons(),
                const SizedBox(height: 30),
                _buildModeContent(),
                _buildModernBottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert,
              color: Colors.black,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: UserMode.values.map((mode) {
          final isActive = _currentMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => _changeMode(mode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
                child: Text(
                  _getModeDisplayName(mode),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getModeDisplayName(UserMode mode) {
    switch (mode) {
      case UserMode.inquilino:
        return 'Inquilino';
      case UserMode.propietario:
        return 'Propietario';
      case UserMode.agente:
        return 'Agente';
    }
  }

  Widget _buildUserInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(

            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto de perfil - Alineada a la izquierda y más grande
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 57,
                      backgroundImage: AssetImage('assets/images/unnamed.png'),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),

              // Información del usuario - A la derecha de la foto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre y verificación
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _getUserName(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (_isUserVerified()) ...[
                          const SizedBox(width: 8),
                          _buildVerificationBadge(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            textColor: Colors.white,
                          )!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Información de contacto
                    Text(
                      _getUserId(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getUserEmail(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getUserPhone(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botón Editar Perfil
                    SizedBox(
                      width: 140,
                      child: CustomButton(
                        text: 'Editar Perfil',
                        onPressed: () {
                          // Navegar a editar perfil
                        },
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getModeTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildModeItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildModeItems() {
    switch (_currentMode) {
      case UserMode.inquilino:
        return _buildInquilinoItems();
      case UserMode.propietario:
        return _buildPropietarioItems();
      case UserMode.agente:
        return _buildAgenteItems();
    }
  }

  List<Widget> _buildInquilinoItems() {
    final alquileres = [
      {
        'nombre': 'Casa en el centro',
        'precio': 'Bs. 2,500/mes',
        'estado': 'Activo',
        'imagen': 'assets/images/casa1.jpg',
      },
      {
        'nombre': 'Departamento Equipetrol',
        'precio': 'Bs. 3,800/mes',
        'estado': 'Finalizado',
        'imagen': 'assets/images/casa2.jpg',
      },
    ];

    return alquileres.map((alquiler) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      alquiler['imagen']!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.home, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alquiler['nombre']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alquiler['precio']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      'Ver Detalles',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPropietarioItems() {
    final propiedades = [
      {
        'nombre': 'Apartamento en Equipetrol',
        'estado': 'Ocupada',
        'imagen': 'assets/images/casa1.jpg',
      },
      {
        'nombre': 'Casa en zona norte',
        'estado': 'Disponible',
        'imagen': 'assets/images/casa2.jpg',
      },
    ];

    return propiedades.map((propiedad) {
      final isOcupada = propiedad['estado'] == 'Ocupada';

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      propiedad['imagen']!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.home, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          propiedad['nombre']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOcupada ? Colors.red : AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            propiedad['estado']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isOcupada ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Gestionar',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildAgenteItems() {
    final propiedadesAsignadas = [
      {
        'nombre': 'Casa en Equipetrol',
        'cliente': 'Cliente: Sofía Ramírez',
        'comision': 'Comisión: 5%',
        'imagen': 'assets/images/casa3.jpg',
      },
      {
        'nombre': 'Departamento en el centro',
        'cliente': 'Cliente: Carlos Mendoza',
        'comision': 'Comisión: 4%',
        'imagen': 'assets/images/casa4.jpg',
      },
    ];

    return propiedadesAsignadas.map((propiedad) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      propiedad['imagen']!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.home, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          propiedad['nombre']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          propiedad['cliente']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          propiedad['comision']!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7FFFD4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7FFFD4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Contactar',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAdditionalButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: const Color(0xFF7FFFD4),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Ver Reseñas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF7FFFD4),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: const Color(0xFF7FFFD4),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Incentivos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF7FFFD4),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Cerrar Sesión',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUserName() {
    if (_currentUser != null) {
      final firstName = _currentUser!.firstName.isNotEmpty ? _currentUser!.firstName : '';
      final lastName = _currentUser!.lastName.isNotEmpty ? _currentUser!.lastName : '';
      final fullName = '$firstName $lastName'.trim();
      return fullName.isNotEmpty ? fullName : 'Usuario';
    }
    return 'Usuario';
  }

  String _getUserId() {
    if (_currentUser != null) {
      return 'ID: ${_currentUser!.id}';
    }
    return 'ID: ---';
  }

  String _getUserEmail() {
    if (_currentUser != null && _currentUser!.email.isNotEmpty) {
      return _currentUser!.email;
    }
    return 'email@ejemplo.com';
  }

  String _getUserPhone() {
    if (_currentProfile != null && _currentProfile!.phone.isNotEmpty) {
      return _currentProfile!.phone;
    }
    return '+591 --------';
  }

  String _getModeTitle() {
    switch (_currentMode) {
      case UserMode.inquilino:
        return 'Mis Alquileres';
      case UserMode.propietario:
        return 'Mis Propiedades';
      case UserMode.agente:
        return 'Propiedades Asignadas';
    }
  }

  bool _isUserVerified() {
    return _currentProfile?.isVerified ?? false;
  }

  Widget? _buildVerificationBadge({required Color backgroundColor, required Color textColor}) {
    if (!_isUserVerified()) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            'Verificado',
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto de perfil - Alineada a la izquierda
          Align(
            alignment: Alignment.centerLeft,
            child: Stack(
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/unnamed.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Información del usuario - DEBAJO de la foto, alineada a la izquierda
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre y verificación
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _getUserName(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_isUserVerified()) ...[
                    const SizedBox(width: 8),
                    _buildVerificationBadge(
                      backgroundColor: AppTheme.primaryColor,
                      textColor: Colors.black,
                    )!,
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Información de contacto
              Text(
                _getUserId(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getUserEmail(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getUserPhone(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 20),

              // Botón Editar Perfil
              SizedBox(
                width: 140,
                child: CustomButton(
                  text: 'Editar Perfil',
                  onPressed: () {
                    // Navegar a editar perfil
                  },
                  backgroundColor: AppTheme.primaryColor,
                  textColor: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF7FFFD4),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildModernActionButtons() {
    List<String> options = _getOptionsForCurrentMode();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: options.asMap().entries.map((entry) {
          int index = entry.key;
          String option = entry.value;
          bool isActive = index == 0; // Primer elemento activo por defecto

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < options.length - 1 ? 12 : 0),
              child: _buildModernActionButton(option, isActive),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<String> _getOptionsForCurrentMode() {
    switch (_currentMode) {
      case UserMode.inquilino:
        return ['Pagos', 'Contratos', 'Reportes', 'Historial'];
      case UserMode.propietario:
        return ['Propiedades', 'Ingresos', 'Inquilinos', 'Mantenimiento'];
      case UserMode.agente:
        return ['Clientes', 'Ventas', 'Comisiones', 'Agenda'];
    }
  }

  Widget _buildModernActionButton(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isActive ? Colors.transparent : Colors.white.withOpacity(0.3),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildModernBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: const Color(0xFF7FFFD4),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Ver Reseñas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7FFFD4),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: const Color(0xFF7FFFD4),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Incentivos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7FFFD4),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _handleLogout,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Cerrar Sesión',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
