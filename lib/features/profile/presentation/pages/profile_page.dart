import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/profile_mode_chip.dart';
import '../../../../shared/widgets/property_card.dart';

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
    _animationController.forward();
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        // Fondo con degradado sutil igual al home
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildModeSelector(),
                _buildUserInfo(),
                _buildModeContent(),
                _buildAdditionalButtons(),
                const SizedBox(height: 100), // Espacio para bottom navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Mi Perfil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Para centrar el título
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ProfileModeChip(
              text: 'Inquilino',
              isActive: _currentMode == UserMode.inquilino,
              onTap: () => _changeMode(UserMode.inquilino),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ProfileModeChip(
              text: 'Propietario',
              isActive: _currentMode == UserMode.propietario,
              onTap: () => _changeMode(UserMode.propietario),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ProfileModeChip(
              text: 'Agente',
              isActive: _currentMode == UserMode.agente,
              onTap: () => _changeMode(UserMode.agente),
            ),
          ),
        ],
      ),
    );
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
          child: Column(
            children: [
              // Foto de perfil
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFA8E6CE),
                        width: 3,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 37,
                      backgroundImage: AssetImage('assets/images/unnamed.png'),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA8E6CE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nombre y verificación
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getUserName(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Verificado',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

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
              const SizedBox(height: 24),

              // Botón Editar Perfil
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
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
      ),
    );
  }

  Widget _buildModeContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getModeTitle(),
              style: const TextStyle(
                fontSize: 18,
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
        'precio': 'Bs. 2,500',
        'estado': 'Activo',
      },
      {
        'nombre': 'Departamento Equipetrol',
        'precio': 'Bs. 3,800',
        'estado': 'Finalizado',
      },
    ];

    return alquileres.map((alquiler) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.40), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alquiler['nombre']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alquiler['precio']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA8E6CE),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Ver Detalles',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
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

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    propiedad['imagen']!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        propiedad['nombre']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOcupada
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          propiedad['estado']!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Gestionar', style: TextStyle(fontSize: 12)),
                ),
              ],
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                propiedad['imagen']!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    propiedad['nombre']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    propiedad['cliente']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    propiedad['comision']!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA8E6CE),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA8E6CE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Contactar',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildAdditionalButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFA8E6CE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Ver Reseñas',
                    style: TextStyle(
                      color: Color(0xFFA8E6CE),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFA8E6CE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Incentivos',
                    style: TextStyle(
                      color: Color(0xFFA8E6CE),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUserName() {
    switch (_currentMode) {
      case UserMode.inquilino:
      case UserMode.propietario:
        return 'Ricardo Vargas';
      case UserMode.agente:
        return 'Ana Gonzales';
    }
  }

  String _getUserId() {
    switch (_currentMode) {
      case UserMode.inquilino:
      case UserMode.propietario:
        return 'CI: 1234***-8';
      case UserMode.agente:
        return 'CI: 987****-1 LP';
    }
  }

  String _getUserEmail() {
    switch (_currentMode) {
      case UserMode.inquilino:
      case UserMode.propietario:
        return 'ricardo.v@email.com';
      case UserMode.agente:
        return 'ana.gonzales@email.com';
    }
  }

  String _getUserPhone() {
    switch (_currentMode) {
      case UserMode.inquilino:
      case UserMode.propietario:
        return '+591 71234567';
      case UserMode.agente:
        return '+591 777 54321';
    }
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
}
