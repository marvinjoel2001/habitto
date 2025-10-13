import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/social_login_button.dart';
import 'dart:ui' as ui;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    // Simular delay de login
    await Future.delayed(const Duration(seconds: 1));

    // Ir al home siempre (por ahora sin validar)
    Navigator.pushReplacementNamed(context, '/home');

    setState(() {
      _isLoading = false;
    });
  }


  // Dentro de _LoginPageState -> método build(BuildContext context)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fondo sin blur ni overlays encima
          Image.asset(
            'assets/images/loginConexion.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Overlay con tinte verde (usando el color primario del tema)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.25),
                    Colors.black.withOpacity(0.10),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Contenedor glass un poco más arriba y más compacto
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                // Subimos el contenedor (antes 24/30), ahora 56
                padding: const EdgeInsets.only(bottom: 56),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Bienvenido a\nHabitto',
                              style: TextStyle(
                                // título más pequeño para ocupar menos vertical
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black.withOpacity(0.4),
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Campo de email
                          CustomTextField(
                            controller: _emailController,
                            hintText: 'Email o teléfono',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu email o teléfono';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          // Campo de contraseña
                          CustomTextField(
                            controller: _passwordController,
                            hintText: 'Contraseña',
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu contraseña';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Navegar a recuperar contraseña
                              },
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Botón de iniciar sesión
                          CustomButton(
                            text: 'Iniciar Sesión',
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.4))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'O inicia sesión con',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.4))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SocialLoginButton(
                                  icon: Icons.facebook,
                                  text: 'Facebook',
                                  onPressed: () {
                                    // Login con Facebook
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SocialLoginButton(
                                  icon: Icons.g_mobiledata,
                                  text: 'Google',
                                  onPressed: () {
                                    // Login con Google
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '¿No tienes una cuenta? ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Navegar a registro
                                  },
                                  child: Text(
                                    'Regístrate',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

            ),
          ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
