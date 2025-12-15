import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io' show Platform;
import '../../data/services/auth_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../generated/l10n.dart';

class AuthSelectionPage extends StatefulWidget {
  const AuthSelectionPage({super.key});

  @override
  State<AuthSelectionPage> createState() => _AuthSelectionPageState();
}

class _AuthSelectionPageState extends State<AuthSelectionPage> {
  final AuthService _authService = AuthService();
  String? _socialLoading; // 'google' | 'facebook' | 'apple'

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() {
      _socialLoading = provider;
    });

    final navigator = Navigator.of(context);
    Map<String, dynamic> res;

    try {
      if (provider == 'facebook') {
        res = await _authService.loginWithFacebook();
      } else if (provider == 'google') {
        res = await _authService.loginWithGoogle();
      } else if (provider == 'apple') {
        res = await _authService.loginWithApple();
      } else {
        return;
      }

      if (res['success'] == true) {
        navigator.pushReplacementNamed('/splash');
      } else {
        _showToast(res['error'] ?? S.of(context).socialLoginError(provider));
      }
    } catch (e) {
      _showToast(S.of(context).errorMessage(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _socialLoading = null;
        });
      }
    }
  }

  Widget _buildGlassButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    String? imageAsset,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : onPressed,
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (imageAsset != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Image.asset(
                                  imageAsset,
                                  width: 24,
                                  height: 24,
                                ),
                              )
                            else if (icon != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            Text(
                              text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF1A1A1A),
                );
              },
            ),
          ),

          // Gradient Overlay - MATCHING LOGIN PAGE EXACTLY
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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Logo/Brand
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: const Text(
                        'HABITTO',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Buttons
                  _buildGlassButton(
                    text: S.of(context).loginWithEmailButton,
                    onPressed: () {
                      Navigator.pushNamed(context, '/login-form');
                    },
                  ),

                  _buildGlassButton(
                    text: S.of(context).loginWithGoogleButton,
                    imageAsset: 'assets/icons/google.png',
                    isLoading: _socialLoading == 'google',
                    onPressed: () => _handleSocialLogin('google'),
                  ),

                  if (Platform.isIOS)
                    _buildGlassButton(
                      text: S.of(context).loginWithAppleButton,
                      imageAsset: 'assets/icons/apple.png',
                      isLoading: _socialLoading == 'apple',
                      onPressed: () => _handleSocialLogin('apple'),
                    ),

                  _buildGlassButton(
                    text: S.of(context).loginWithFacebookButton,
                    imageAsset: 'assets/icons/facebook.png',
                    isLoading: _socialLoading == 'facebook',
                    onPressed: () => _handleSocialLogin('facebook'),
                  ),

                  const Spacer(),

                  Text(
                    S.of(context).tagline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
