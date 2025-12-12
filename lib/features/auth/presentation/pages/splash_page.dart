import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../shared/theme/app_theme.dart';
import '../../../profile/data/services/profile_service.dart';
import '../../../../generated/l10n.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final ProfileService _profileService = ProfileService();
  bool _showFakeSplash = true;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _opacity = 0.0;
          });
        }
      });
    });
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    // 1. Verificar perfil
    try {
      await _profileService.getCurrentProfile();
    } catch (_) {}

    if (!mounted) return;

    // 2. Solicitar permisos necesarios antes de ir a Home
    await _requestAppPermissions();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _requestAppPermissions() async {
    // Lista de permisos requeridos
    final permissions = [
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.photos,
      Permission.microphone,
      Permission.notification,
    ];

    // Solicitar uno por uno para mejor UX (o en grupo si se prefiere)
    // Aquí usamos un loop simple, pero se podría mostrar una UI explicativa para cada uno
    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        // Opcional: Mostrar un diálogo explicando por qué se necesita
        // Por simplicidad en el splash, solicitamos directamente.
        // El sistema operativo mostrará el diálogo nativo si es necesario.
        await permission.request();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo con fondo blanco fijo (Stack: círculo blanco + imagen)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/images/logoHabitto.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  S.of(context).verifyingProfile,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                // Indicador de carga y animación de "reload"
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          // Fake Splash Overlay
          if (_showFakeSplash)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                onEnd: () {
                  setState(() {
                    _showFakeSplash = false;
                  });
                },
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 120,
                      height: 120,
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
