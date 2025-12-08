import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/social_login_button.dart';
import 'dart:ui' as ui;
import 'dart:io' show Platform;
import 'package:fluttertoast/fluttertoast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _socialLoading; // 'google' | 'facebook' | 'apple'
  double _keyboardHeight = 0;
  bool _isKeyboardVisible = false;
  bool _isPasswordFieldFocused = false;
  final double _originalPadding = 56;

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF98FB98).withValues(alpha: 0.9),
      textColor: Colors.black,
      fontSize: 14,
    );
  }

  @override
  void initState() {
    super.initState();
    // Reconfigurar ApiService tras hot reload para evitar bucles con interceptores antiguos
    ApiService().reinitialize();
    Future.microtask(_guardIfAuthenticated);

    // Configurar listeners para el teclado
    _emailFocusNode.addListener(_handleFocusChange);
    _passwordFocusNode.addListener(_handleFocusChange);

    // Escuchar cambios en el teclado con un listener más robusto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupKeyboardListener();
    });
  }

  void _setupKeyboardListener() {
    // Usar un listener periódico para detectar cambios en el teclado
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _updateKeyboardState();
        _setupKeyboardListener(); // Continuar escuchando
      }
    });
  }

  void _handleFocusChange() {
    // Detectar cuando el campo de contraseña recibe o pierde el foco
    final bool wasPasswordFocused = _isPasswordFieldFocused;
    _isPasswordFieldFocused = _passwordFocusNode.hasFocus;

    if (_passwordFocusNode.hasFocus) {
      // El campo de contraseña recibió el foco - desplazar suavemente
      _scrollToPasswordField();
      // Asegurar que el botón de login sea visible
      _ensureLoginButtonVisible();
    } else if (wasPasswordFocused && !_passwordFocusNode.hasFocus) {
      // El campo de contraseña perdió el foco - regresar a posición original
      _returnToOriginalPosition();
    }

    // Manejo general para cualquier campo enfocado
    if (_emailFocusNode.hasFocus || _passwordFocusNode.hasFocus) {
      _scrollToFocusedInput();
      // Asegurar que el botón de login sea visible cuando cualquier campo está enfocado
      _ensureLoginButtonVisible();
    }
  }

  void _updateKeyboardState() {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final newKeyboardHeight = viewInsets.bottom;
    final newKeyboardVisible = newKeyboardHeight > 0;

    if (mounted &&
        (newKeyboardHeight != _keyboardHeight ||
            newKeyboardVisible != _isKeyboardVisible)) {
      // Detectar cuando el teclado se oculta
      final bool keyboardWasHidden = _isKeyboardVisible && !newKeyboardVisible;

      setState(() {
        _keyboardHeight = newKeyboardHeight;
        _isKeyboardVisible = newKeyboardVisible;
      });

      // Si el teclado se oculta y el campo de contraseña estaba enfocado, regresar a posición original
      if (keyboardWasHidden && _isPasswordFieldFocused) {
        _returnToOriginalPosition();
      }
    }
  }

  void _ensureLoginButtonVisible() {
    if (!_isKeyboardVisible) return;

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      // Si el scroll actual deja poco espacio, ajustar
      if (_scrollController.offset < 60) {
        _scrollController.animateTo(
          20, // Desplazamiento reducido para que el botón quede visible
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _scrollToPasswordField() {
    if (!_isKeyboardVisible) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      // Obtener la posición del campo de contraseña
      final renderBox =
          _passwordFocusNode.context?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final inputPosition = renderBox.localToGlobal(Offset.zero);
      final inputBottom = inputPosition.dy + renderBox.size.height;
      final keyboardTop = MediaQuery.of(context).size.height - _keyboardHeight;
      final screenHeight = MediaQuery.of(context).size.height;

      // Verificar si el campo de contraseña está siendo tapado por el teclado
      if (inputBottom > keyboardTop) {
        // Calcular el desplazamiento necesario con margen de seguridad adaptativo
        final safetyMargin = screenHeight < 600
            ? 45.0
            : 55.0; // Márgenes ligeramente reducidos en pantallas pequeñas
        final targetPosition = keyboardTop -
            renderBox.size.height -
            safetyMargin -
            30; // 30px extra para el botón de login
        final currentScroll = _scrollController.offset;
        final neededScroll = inputPosition.dy - targetPosition;

        if (neededScroll > 0) {
          _scrollController.animateTo(
            currentScroll + neededScroll,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  void _returnToOriginalPosition() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _scrollToFocusedInput() {
    if (!_isKeyboardVisible) return;

    // Si el campo de contraseña está enfocado, usar el método específico
    if (_isPasswordFieldFocused) {
      _scrollToPasswordField();
      return;
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      // Calcular la posición del input enfocado (solo para email)
      final renderBox = _getFocusedInputRenderBox();
      if (renderBox == null) return;

      final inputPosition = renderBox.localToGlobal(Offset.zero);
      final inputTop = inputPosition.dy;
      final inputBottom = inputPosition.dy + renderBox.size.height;
      final keyboardTop = MediaQuery.of(context).size.height - _keyboardHeight;

      // Si el input está oculto por el teclado, desplazar suavemente
      if (inputBottom > keyboardTop) {
        // Calcular el desplazamiento necesario para que el input quede justo encima del teclado
        final targetPosition = keyboardTop -
            renderBox.size.height -
            30; // 30px de espacio adicional
        final currentScroll = _scrollController.offset;
        final neededScroll = inputTop - targetPosition;

        if (neededScroll > 0) {
          _scrollController.animateTo(
            currentScroll + neededScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });
  }

  RenderBox? _getFocusedInputRenderBox() {
    if (_emailFocusNode.hasFocus) {
      final renderObject = _emailFocusNode.context?.findRenderObject();
      return renderObject is RenderBox ? renderObject : null;
    } else if (_passwordFocusNode.hasFocus) {
      final renderObject = _passwordFocusNode.context?.findRenderObject();
      return renderObject is RenderBox ? renderObject : null;
    }
    return null;
  }

  Future<void> _guardIfAuthenticated() async {
    final ok = await _authService.isAuthenticated();
    if (ok) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/splash');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (response['success']) {
        navigator.pushReplacementNamed('/splash');
      } else {
        _showToast(response['error'] ?? 'Error de autenticación');
      }
    } catch (e) {
      _showToast('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Actualizar estado del teclado cuando cambie MediaQuery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateKeyboardState();
    });

    // Calcular padding responsive basado en el tamaño de pantalla

    return GestureDetector(
      onTap: () {
        // Cerrar el teclado y quitar el foco cuando se toca fuera
        if (_passwordFocusNode.hasFocus) {
          _passwordFocusNode.unfocus();
        }
        if (_emailFocusNode.hasFocus) {
          _emailFocusNode.unfocus();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false, // Prevenir banderas amarillas
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Fondo sin blur ni overlays encima
            Image.asset(
              'assets/images/login_background.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                // Si la imagen falla (por memoria o no encontrada), mostrar un fondo sólido oscuro
                return Container(
                  color: const Color(0xFF1A1A1A),
                );
              },
            ),
            // Overlay con tinte más oscuro (mejor legibilidad)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Contenedor glass con manejo inteligente del teclado
            SafeArea(
              child: Align(
                alignment: _isKeyboardVisible
                    ? Alignment.center
                    : Alignment.bottomCenter,
                child: AnimatedPadding(
                  padding: EdgeInsets.only(
                    bottom: _isKeyboardVisible
                        ? 60.0 // Espacio original cuando el teclado está visible
                        : _originalPadding,
                  ),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      margin: _isKeyboardVisible
                          ? const EdgeInsets.symmetric(horizontal: 20)
                          : EdgeInsets
                              .zero, // Márgenes originales cuando el teclado está visible
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            child: Form(
                              key: _formKey,
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
                                            color: Colors.white
                                                .withValues(alpha: 0.4),
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
                                    focusNode: _emailFocusNode,
                                    hintText: 'Email o nombre de usuario',
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    textColor: Colors.white,
                                    fillColor:
                                        Colors.white.withValues(alpha: 0.1),
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context)
                                          .requestFocus(_passwordFocusNode);
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa tu email o nombre de usuario';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // Campo de contraseña
                                  CustomTextField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    hintText: 'Contraseña',
                                    isPassword: true,
                                    textInputAction: TextInputAction.done,
                                    textColor: Colors.white,
                                    fillColor:
                                        Colors.white.withValues(alpha: 0.1),
                                    onFieldSubmitted: (_) {
                                      // Primero regresar a la posición original
                                      _returnToOriginalPosition();
                                      // Luego ejecutar el login
                                      _handleLogin();
                                    },
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
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Botón de iniciar sesión
                                  CustomButton(
                                    text: 'Iniciar Sesión',
                                    textColor: Colors.white,
                                    onPressed: _handleLogin,
                                    isLoading: _isLoading,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Divider(
                                              color: Colors.white
                                                  .withValues(alpha: 0.4))),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          'O inicia sesión con',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                          child: Divider(
                                              color: Colors.white
                                                  .withValues(alpha: 0.4))),
                                    ],
                                  ),
                                  // Botones de redes sociales en fila centrada
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SocialLoginButton(
                                        imageAsset: 'assets/icons/facebook.png',
                                        isLoading: _socialLoading == 'facebook',
                                        onPressed: _socialLoading == null
                                            ? () async {
                                                setState(() {
                                                  _socialLoading = 'facebook';
                                                });
                                                final navigator =
                                                    Navigator.of(context);
                                                try {
                                                  final res = await _authService
                                                      .loginWithFacebook();
                                                  if (res['success'] == true) {
                                                    navigator
                                                        .pushReplacementNamed(
                                                            '/splash');
                                                  } else {}
                                                } catch (e) {
                                                  _showToast('Error: $e');
                                                } finally {
                                                  if (mounted) {
                                                    setState(() {
                                                      _socialLoading = null;
                                                    });
                                                  }
                                                }
                                              }
                                            : () {},
                                      ),
                                      const SizedBox(width: 20),
                                      SocialLoginButton(
                                        imageAsset: 'assets/icons/google.png',
                                        isLoading: _socialLoading == 'google',
                                        onPressed: _socialLoading == null
                                            ? () async {
                                                setState(() {
                                                  _socialLoading = 'google';
                                                });
                                                final navigator =
                                                    Navigator.of(context);
                                                try {
                                                  final res = await _authService
                                                      .loginWithGoogle();
                                                  if (res['success'] == true) {
                                                    navigator
                                                        .pushReplacementNamed(
                                                            '/splash');
                                                  } else {
                                                    _showToast(res['error'] ??
                                                        'Error con Google');
                                                  }
                                                } catch (e) {
                                                  _showToast('Error: $e');
                                                } finally {
                                                  if (mounted) {
                                                    setState(() {
                                                      _socialLoading = null;
                                                    });
                                                  }
                                                }
                                              }
                                            : () {},
                                      ),
                                      if (Platform.isIOS) ...[
                                        const SizedBox(width: 20),
                                        SocialLoginButton(
                                          imageAsset: 'assets/icons/apple.png',
                                          isLoading: _socialLoading == 'apple',
                                          onPressed: _socialLoading == null
                                              ? () async {
                                                  setState(() {
                                                    _socialLoading = 'apple';
                                                  });
                                                  final navigator =
                                                      Navigator.of(context);
                                                  try {
                                                    final res =
                                                        await _authService
                                                            .loginWithApple();
                                                    if (res['success'] ==
                                                        true) {
                                                      navigator
                                                          .pushReplacementNamed(
                                                              '/home');
                                                    } else {
                                                      _showToast(res['error'] ??
                                                          'Error con Apple');
                                                    }
                                                  } catch (e) {
                                                    _showToast('Error: $e');
                                                  } finally {
                                                    if (mounted) {
                                                      setState(() {
                                                        _socialLoading = null;
                                                      });
                                                    }
                                                  }
                                                }
                                              : () {},
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '¿No tienes una cuenta? ',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize: 13,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                                context, '/register');
                                          },
                                          child: Text(
                                            'Regístrate',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
