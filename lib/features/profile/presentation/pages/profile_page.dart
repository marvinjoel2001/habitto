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
import '../../../properties/data/services/property_service.dart';
import '../../../properties/data/services/photo_service.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/domain/entities/photo.dart';
import '../../../properties/presentation/pages/property_photos_page.dart';
import '../../../properties/presentation/pages/property_detail_page.dart';
import '../../../../core/services/api_service.dart';
import 'edit_profile_page.dart';

enum UserMode { inquilino, propietario, agente }

class ProfilePage extends StatefulWidget {
  final Function(UserMode)? onModeChanged;

  const ProfilePage({
    super.key,
    this.onModeChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  UserMode _currentMode = UserMode.inquilino;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final PropertyService _propertyService = PropertyService();
  final PhotoService _photoService = PhotoService(ApiService());
  Profile? _currentProfile;
  User? _currentUser;
  List<Property> _userProperties = [];
  final Map<int, List<Photo>> _propertyPhotos = {};
  bool _isLoading = true;
  bool _isLoadingProperties = true;

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
    _loadUserProperties();
  }

  Future<void> _loadUserProperties() async {
    setState(() {
      _isLoadingProperties = true;
    });
    Map<String, dynamic> result;
    // Cargar según el modo actual: propietario o agente
    if (_currentMode == UserMode.agente) {
      result = await _propertyService.getAgentProperties();
    } else {
      result = await _propertyService.getMyProperties();
    }

    if (result['success']) {
      final properties = result['data']['properties'] as List<Property>;
      setState(() {
        _userProperties = properties;
        _isLoadingProperties = false;
      });

      // Cargar fotos para cada propiedad
      for (final property in properties) {
        _loadPropertyPhotos(property.id);
      }
    } else {
      setState(() {
        _isLoadingProperties = false;
      });
    }
  }

  Future<void> _loadPropertyPhotos(int propertyId) async {
    final result = await _photoService.getPropertyPhotos(propertyId);

    if (result['success']) {
      final photos = result['data']['photos'] as List<Photo>;
      setState(() {
        _propertyPhotos[propertyId] = photos;
      });
    }
  }

  Future<void> _loadCurrentProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _profileService.getCurrentProfile();

      if (response['success'] == true) {
        // Extract both profile and user data from the response
        _currentProfile = response['data']['profile'];
        _currentUser = response['data']['user'];

        // Establecer el modo actual basado en el tipo de usuario
        if (_currentProfile != null) {
          _setModeFromUserType(_currentProfile!.userType);

          // Notificar el modo inicial al padre después de cargar el perfil
          if (widget.onModeChanged != null) {
            widget.onModeChanged!(_currentMode);
          }
        } else {
          // If no profile, default to inquilino
          _currentMode = UserMode.inquilino;

          // Notificar el modo por defecto al padre
          if (widget.onModeChanged != null) {
            widget.onModeChanged!(_currentMode);
          }
        }
      } else {
        print('Error cargando perfil: ${response['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error cargando perfil: ${response['error']}')),
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

  Future<void> _editProfile() async {
    if (_currentProfile == null || _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo cargar la información del perfil')),
      );
      return;
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          profile: _currentProfile!,
          user: _currentUser!,
        ),
      ),
    );

    // Si se actualizó el perfil, recargar los datos
    if (result == true) {
      _loadCurrentProfile();
    }
  }

  Widget _buildGlassContainer({
    required Widget child,
    double blur = 15,
    double opacity = 0.1,
    double borderRadius = 20,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color color = Colors.white,
    Border? border,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.25),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(color: Colors.white.withOpacity(0.4), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildNewHeader(),
              const SizedBox(height: 24),
              _buildStatsButtons(),
              const SizedBox(height: 24),
              _buildPropertiesTitle(),
              const SizedBox(height: 16),
              _buildModeContent(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewHeader() {
    return Column(
      children: [
        // Top Bar (Back & Settings)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              IconButton(
                onPressed: _showSettingsModal,
                icon: const Icon(Icons.settings_outlined,
                    color: Colors.white, size: 28),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Avatar & Ribbon & Info
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate center of the screen/stack
            final centerX = constraints.maxWidth / 2;
            // Overlap amount (how much the label goes under the avatar)
            const overlap = 30.0;
            // Avatar radius (approximate based on width 130)
            const avatarRadius = 65.0;

            return SizedBox(
              height: 140,
              width: double.infinity, // Use full width
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Ribbon (User Type) - Behind Avatar
                  // Anchored to the right side of the label space
                  Positioned(
                    right:
                        (constraints.maxWidth / 2) + (avatarRadius - overlap),
                    child: _buildGlassContainer(
                      borderRadius: 30,
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 50, // Padding to clear the overlap + gap
                        top: 8,
                        bottom: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getModeIcon(_currentMode),
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getModeDisplayName(_currentMode).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Avatar - In Front
                  Center(
                    child: Container(
                      width: 130,
                      height: 130,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.white30, Colors.white10],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _getProfileImage(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          _getUserName().toUpperCase(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          _getModeDisplayName(_currentMode).toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getUserEmail(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        if (_getUserPhone().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  _getUserPhone(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _getModeIcon(UserMode mode) {
    switch (mode) {
      case UserMode.inquilino:
        return Icons.person_outline;
      case UserMode.propietario:
        return Icons.home_work_outlined;
      case UserMode.agente:
        return Icons.verified_user_outlined;
    }
  }

  Widget _buildStatsButtons() {
    final buttons = ['CLIENTES', 'VENTAS', 'COMISIONES', 'AGENDA'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: buttons.map((label) {
          return GestureDetector(
            onTap: () {},
            child: _buildGlassContainer(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPropertiesTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            _currentMode == UserMode.inquilino
                ? 'MIS ALQUILERES'
                : 'PROPIEDADES ASIGNADAS',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white
                  .withOpacity(0.9), // Slightly more opaque for readability
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuración de Perfil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'CAMBIAR MODO DE USUARIO',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...UserMode.values.map((mode) => ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _currentMode == mode
                                ? const Color(0xFF8E2DE2).withOpacity(0.1)
                                : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getModeIcon(mode),
                            color: _currentMode == mode
                                ? const Color(0xFF8E2DE2)
                                : Colors.grey,
                          ),
                        ),
                        title: Text(_getModeDisplayName(mode)),
                        trailing: _currentMode == mode
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFF8E2DE2))
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _onSelectMode(mode);
                        },
                      )),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('Verificar Perfil'),
                    onTap: () {
                      Navigator.pop(context);
                      _handleVerification();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Editar Perfil'),
                    onTap: () {
                      Navigator.pop(context);
                      _editProfile();
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Eliminar Cuenta',
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _handleDeleteAccount();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Cerrar Sesión',
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerification() async {
    // TODO: Implement full verification flow with file upload
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verificación de Perfil'),
        content: const Text(
            'Para verificar tu perfil, necesitamos validar tu identidad. Esta funcionalidad estará disponible pronto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción programará la eliminación de tus datos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _profileService.requestDeleteAccount();
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    result['message'] ?? 'Eliminación de cuenta programada')),
          );
          // Optionally logout or show more info
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(result['error'] ?? 'Error al solicitar eliminación')),
          );
        }
      }
    }
  }

  // --- Cambio de modo con confirmación y creación de perfil ---
  Future<void> _onSelectMode(UserMode mode) async {
    final targetType = _modeToUserType(mode);
    final currentType = _currentProfile?.userType.toLowerCase();

    // Si ya tiene el perfil, solo cambia de pestaña sin modal
    if (currentType == targetType) {
      _changeMode(mode);
      return;
    }

    // Mostrar modal de confirmación para crear/cambiar el perfil
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.85),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                mode == UserMode.propietario
                    ? Icons.home_work_outlined
                    : mode == UserMode.agente
                        ? Icons.verified_user_outlined
                        : Icons.meeting_room_outlined,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Confirmar cambio a ${_getModeDisplayName(mode)}',
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              _getModeConfirmationText(mode),
              style: TextStyle(color: Colors.white.withOpacity(0.85)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Ejecutar cambio en backend: PATCH /api/profiles/update_me/ { user_type }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Actualizando perfil...')),
    );

    final result = await _profileService.updateCurrentProfile({
      'user_type': targetType,
    });

    if (result['success'] == true) {
      final updatedProfile = result['data'] as Profile;
      setState(() {
        _currentProfile = updatedProfile;
      });

      // Cambiar pestaña y notificar
      _changeMode(mode);

      // Si es propietario/agente, refrescar sus propiedades visibles
      if (mode == UserMode.propietario || mode == UserMode.agente) {
        _loadUserProperties();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Perfil actualizado a ${_getModeDisplayName(mode)}')),
      );
    } else {
      final errorMsg =
          result['error']?.toString() ?? 'Error al actualizar el perfil';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  String _modeToUserType(UserMode mode) {
    switch (mode) {
      case UserMode.inquilino:
        return 'inquilino';
      case UserMode.propietario:
        return 'propietario';
      case UserMode.agente:
        return 'agente';
    }
  }

  String _getModeConfirmationText(UserMode mode) {
    switch (mode) {
      case UserMode.inquilino:
        return 'Como Inquilino podrás gestionar pagos, contratos y reportes de tus alquileres.';
      case UserMode.propietario:
        return 'Como Propietario ahora podrás crear y administrar propiedades, ver ingresos y gestionar inquilinos.';
      case UserMode.agente:
        return 'Como Agente podrás subir propiedades, recibir pagos y gestionar clientes y comisiones.';
    }
  }

  Widget _buildModeContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildModeItems(),
        ],
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
      return _buildGlassContainer(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
                      color: Colors.grey[200],
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
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: alquiler['estado'] == 'Activo'
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alquiler['estado']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: alquiler['estado'] == 'Activo'
                            ? Colors.greenAccent
                            : Colors.grey[300],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildPropietarioItems() {
    if (_isLoadingProperties) {
      return [
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      ];
    }

    if (_userProperties.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.home_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No tienes propiedades registradas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }

    return _userProperties.map((property) {
      final isActive = property.isActive;

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailPage(propertyId: property.id),
            ),
          );
        },
        child: _buildGlassContainer(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildPropertyImage(property),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.address ?? 'Propiedad sin dirección',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        isActive ? 'Disponible' : 'No disponible',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isActive ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToPropertyPhotos(property),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Gestionar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildAgenteItems() {
    if (_isLoadingProperties) {
      return [
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ];
    }

    if (_userProperties.isEmpty) {
      return [
        _buildGlassContainer(
          padding: const EdgeInsets.all(32),
          child: const Column(
            children: [
              Icon(
                Icons.business_outlined,
                size: 64,
                color: Colors.white70,
              ),
              SizedBox(height: 16),
              Text(
                'No tienes propiedades asignadas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }

    return _userProperties.map((property) {
      final isActive = property.isActive;

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailPage(propertyId: property.id),
            ),
          );
        },
        child: _buildGlassContainer(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildPropertyImage(property),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.address ?? 'Propiedad sin dirección',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        isActive ? 'Disponible' : 'No disponible',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isActive ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToPropertyPhotos(property),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Gestionar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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
                  child: _buildGlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: 25,
                    border: Border.all(
                      color: const Color(0xFF7FFFD4),
                      width: 1,
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
                  child: _buildGlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: 25,
                    border: Border.all(
                      color: const Color(0xFF7FFFD4),
                      width: 1,
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
              child: _buildGlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: 25,
                color: const Color(0xFFFF6B6B),
                opacity: 0.8,
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
      final firstName =
          _currentUser!.firstName.isNotEmpty ? _currentUser!.firstName : '';
      final lastName =
          _currentUser!.lastName.isNotEmpty ? _currentUser!.lastName : '';
      final fullName = '$firstName $lastName'.trim();
      return fullName.isNotEmpty ? fullName : 'Usuario';
    }
    return 'Usuario';
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

  String _getUserType() {
    if (_currentProfile != null) {
      switch (_currentProfile!.userType) {
        case 'inquilino':
          return 'Inquilino';
        case 'propietario':
          return 'Propietario';
        case 'agente':
          return 'Agente';
        default:
          return 'Usuario';
      }
    }
    return 'Usuario';
  }

  ImageProvider _getProfileImage() {
    // Verificar si el usuario tiene una foto de perfil
    if (_currentProfile?.profileImage != null &&
        _currentProfile!.profileImage!.isNotEmpty) {
      return NetworkImage(_currentProfile!.profileImage!);
    }

    // Si no tiene foto de perfil, mostrar la imagen por defecto
    // Cambiado a un asset existente para evitar errores de carga
    return const AssetImage('assets/images/unnamed.png');
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

  Widget? _buildVerificationBadge(
      {required Color backgroundColor, required Color textColor}) {
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

  Widget _buildPropertyImage(Property property) {
    final photos = _propertyPhotos[property.id];

    if (photos != null && photos.isNotEmpty) {
      // Mostrar la primera foto de la propiedad
      return Image.network(
        photos.first.image,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultPropertyImage();
        },
      );
    } else {
      // Mostrar imagen por defecto
      return _buildDefaultPropertyImage();
    }
  }

  Widget _buildDefaultPropertyImage() {
    return Image.asset(
      'assets/images/empty.jpg',
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
    );
  }

  void _navigateToPropertyPhotos(Property property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyPhotosPage(property: property),
      ),
    ).then((_) {
      // Recargar fotos después de regresar de la página de gestión
      _loadPropertyPhotos(property.id);
    });
  }
}
