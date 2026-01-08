import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../shared/widgets/custom_network_image.dart';
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
import '../../../../config/app_config.dart';
import 'edit_profile_page.dart';
import '../../../properties/presentation/pages/edit_property_page.dart';
import '../../../../generated/l10n.dart';

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
    if (!mounted) return;
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

    if (!mounted) return;

    if (result['success']) {
      final properties = result['data']['properties'] as List<Property>;
      setState(() {
        _userProperties = properties;
        _isLoadingProperties = false;
      });

      // Cargar fotos para cada propiedad
      for (final property in properties) {
        if (!mounted) return;
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

    if (!mounted) return;

    if (result['success']) {
      final photos = result['data']['photos'] as List<Photo>;
      setState(() {
        _propertyPhotos[propertyId] = photos;
      });
    }
  }

  Future<void> _loadCurrentProfile() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      final response = await _profileService.getCurrentProfile();

      if (!mounted) return;

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
              content: Text(S.of(context).profileLoadError(response['error']))),
        );
      }
    } catch (e) {
      print('Error cargando perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).profileLoadError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(S.of(context).logoutTitle),
            content: Text(S.of(context).logoutConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(S.of(context).cancelButton),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(S.of(context).logoutTitle),
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
        SnackBar(content: Text(S.of(context).logoutError(e.toString()))),
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
        SnackBar(content: Text(S.of(context).profileInfoLoadError)),
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
            color: Colors.black.withValues(alpha: 0.15),
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
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                      color: Colors.white.withValues(alpha: 0.4), width: 1),
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
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent, // Mantener transparente arriba
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: [
              // White Background Card (Starting from mid-avatar)
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                ),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 150),
                  padding: const EdgeInsets.only(top: 80, bottom: 40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      _buildUserInfo(),
                      const SizedBox(height: 24),
                      _buildStatsButtons(),
                      const SizedBox(height: 24),
                      _buildPropertiesTitle(),
                      const SizedBox(height: 16),
                      _buildModeContent(),
                    ],
                  ),
                ),
              ),

              // Avatar Section (Centered on the edge of white card)
              Positioned(
                top: 80, // 150 (margin) - 70 (half height of 140 container)
                left: 0,
                right: 0,
                child: _buildAvatarSection(),
              ),

              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          IconButton(
            onPressed: _showSettingsModal,
            icon: const Icon(Icons.settings_outlined,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate center of the screen/stack
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
                right: (constraints.maxWidth / 2) + (avatarRadius - overlap),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (constraints.maxWidth / 2) -
                        (avatarRadius - overlap) -
                        10, // Margin from left
                  ),
                  child: _buildGlassContainer(
                    borderRadius: 30,
                    padding: const EdgeInsets.only(
                      left: 16, // Reduced padding
                      right: 50, // Padding to clear the overlap + gap
                      top: 8,
                      bottom: 8,
                    ),
                    color: AppTheme.primaryColor
                        .withValues(alpha: 0.8), // Visible on white/transparent
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getModeIcon(_currentMode),
                          color: Colors.white,
                          size: 16, // Reduced icon size
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _getModeDisplayName(_currentMode).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11, // Slightly reduced font size
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        color: Colors.black.withValues(alpha: 0.2),
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
                    child: ClipOval(
                      child: _buildProfileImageWidget(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          _getUserName().toUpperCase(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87, // Changed to black
            letterSpacing: 1.0,
          ),
        ),
        Text(
          _getModeDisplayName(_currentMode).toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black54, // Changed to dark grey
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
                color: Colors.black54, // Changed to dark grey
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
                const Icon(Icons.phone,
                    size: 14, color: Colors.black54), // Changed to dark grey
                const SizedBox(width: 4),
                Text(
                  _getUserPhone(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54, // Changed to dark grey
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
    final buttons = [
      S.of(context).clientsButton,
      S.of(context).salesButton,
      S.of(context).commissionsButton,
      S.of(context).agendaButton
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: buttons.map((label) {
          return GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
                ? S.of(context).myRentalsTitle
                : S.of(context).assignedPropertiesTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87, // Changed to black
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
              color: Colors.white.withValues(
                  alpha: 0.9), // Slightly more opaque for readability
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).profileSettingsTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    S.of(context).changeUserModeLabel,
                    style: const TextStyle(
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
                                ? const Color(0xFF8E2DE2).withValues(alpha: 0.1)
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
                    title: Text(S.of(context).verifyProfileLabel),
                    onTap: () {
                      Navigator.pop(context);
                      _handleVerification();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(S.of(context).editProfileLabel),
                    onTap: () {
                      Navigator.pop(context);
                      _editProfile();
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: Text(S.of(context).deleteAccountLabel,
                        style: const TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _handleDeleteAccount();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(S.of(context).logoutTitle,
                        style: const TextStyle(color: Colors.red)),
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
        title: Text(S.of(context).profileVerificationTitle),
        content: Text(S.of(context).profileVerificationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).understoodButton),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).deleteAccountLabel),
        content: Text(S.of(context).deleteAccountConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(S.of(context).deleteButton),
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
                content: Text(result['message'] ??
                    S.of(context).accountDeletionScheduled)),
          );
          // Optionally logout or show more info
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(result['error'] ?? S.of(context).deleteAccountError)),
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
          backgroundColor: Colors.black.withValues(alpha: 0.85),
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
                  S.of(context).confirmModeChange(_getModeDisplayName(mode)),
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).cancelButton),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).acceptButton),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Ejecutar cambio en backend: PATCH /api/profiles/update_me/ { user_type }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).updatingProfile)),
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
            content: Text(
                S.of(context).profileModeUpdated(_getModeDisplayName(mode)))),
      );
    } else {
      final errorMsg = result['error']?.toString() ??
          S.of(context).profileUpdateGenericError;
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
        return S.of(context).tenantModeDescription;
      case UserMode.propietario:
        return S.of(context).landlordModeDescription;
      case UserMode.agente:
        return S.of(context).agentModeDescription;
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
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alquiler['precio']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: alquiler['estado'] == 'Activo'
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alquiler['estado']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: alquiler['estado'] == 'Activo'
                            ? Colors.green
                            : Colors.grey[600],
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
                S.of(context).noRegisteredProperties,
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
              builder: (_) => EditPropertyPage(property: property),
            ),
          ).then((_) => _loadUserProperties());
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                      property.address ?? S.of(context).propertyNoAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        isActive
                            ? S.of(context).availableStatus
                            : S.of(context).unavailableStatus,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.green : Colors.redAccent,
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
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    S.of(context).manageButton,
                    style: const TextStyle(
                      color: Colors.white, // Keep white on primary button
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
                Icons.business_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context).noAssignedProperties,
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                      property.address ?? S.of(context).propertyNoAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        isActive
                            ? S.of(context).availableStatus
                            : S.of(context).unavailableStatus,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.green : Colors.redAccent,
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
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    S.of(context).manageButton,
                    style: const TextStyle(
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.teal,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      S.of(context).viewReviewsButton,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.teal,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.teal,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      S.of(context).incentivesButton,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.teal,
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
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  S.of(context).logoutTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
      return fullName.isNotEmpty ? fullName : S.of(context).userLabel;
    }
    return S.of(context).userLabel;
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
          return S.of(context).tenantRole;
        case 'propietario':
          return S.of(context).landlordRole;
        case 'agente':
          return S.of(context).agentRole;
        default:
          return S.of(context).userLabel;
      }
    }
    return S.of(context).userLabel;
  }

  Widget _buildProfileImageWidget() {
    // Verificar si el usuario tiene una foto de perfil
    if (_currentProfile?.profileImage != null &&
        _currentProfile!.profileImage!.isNotEmpty) {
      return CustomNetworkImage(
        imageUrl: _currentProfile!.profileImage!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorWidget: Image.asset(
          'assets/images/unnamed.png',
          fit: BoxFit.cover,
        ),
      );
    }

    // Si no tiene foto de perfil, mostrar la imagen por defecto
    return Image.asset(
      'assets/images/unnamed.png',
      fit: BoxFit.cover,
      width: 120,
      height: 120,
    );
  }

  String _getModeTitle() {
    switch (_currentMode) {
      case UserMode.inquilino:
        return S.of(context).myRentalsTitleMixed;
      case UserMode.propietario:
        return S.of(context).myPropertiesTitle;
      case UserMode.agente:
        return S.of(context).assignedPropertiesTitleMixed;
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
            S.of(context).verifiedLabel,
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
        return S.of(context).tenantRole;
      case UserMode.propietario:
        return S.of(context).landlordRole;
      case UserMode.agente:
        return S.of(context).agentRole;
    }
  }

  Widget _buildPropertyImage(Property property) {
    final photos = _propertyPhotos[property.id];

    if (photos != null && photos.isNotEmpty) {
      // Mostrar la primera foto de la propiedad
      return CustomNetworkImage(
        imageUrl: photos.first.image,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorWidget: _buildDefaultPropertyImage(),
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
        builder: (context) => EditPropertyPage(property: property),
      ),
    ).then((_) {
      // Recargar fotos después de regresar de la página de gestión
      _loadPropertyPhotos(property.id);
      _loadUserProperties();
    });
  }
}
