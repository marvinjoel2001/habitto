import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/services/token_storage.dart';
import 'dart:ui';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/progress_indicator.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../../../generated/l10n.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  VideoPlayerController? _videoController;

  // NUEVO: Control de animación para el contenido
  bool _showContent = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    Future.microtask(_guardEntry);
    _initializeVideo();
    _initializeAnimations();

    // NUEVO: Mostrar contenido después de 10 segundos
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted && _currentPage == 0) {
        setState(() {
          _showContent = true;
        });
        _fadeController.forward();
      }
    });
  }

  Future<void> _guardEntry() async {
    final ts = TokenStorage();
    final isValid = await ts.isTokenValid();
    if (isValid) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    final hasLoggedOnce = await ts.getHasLoggedOnce();
    if (hasLoggedOnce) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController!.play();
        _videoController!.setLooping(true);
        _videoController!.setVolume(1.0); // Sonido inicial activado
      });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handlePageChange(int index) {
    setState(() {
      _currentPage = index;
    });

    // Resetear animación si volvemos a la primera página
    if (index == 0) {
      _showContent = false;
      _fadeController.reset();
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _currentPage == 0) {
          setState(() {
            _showContent = true;
          });
          _fadeController.forward();
        }
      });
    }

    // Controlar el sonido del video según la página
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (index == 0) {
        _videoController!
            .setVolume(1.0); // Sonido activado en la primera página
      } else {
        _videoController!.setVolume(0.0); // Sonido silenciado en otras páginas
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _handlePageChange,
            children: [
              _buildWelcomePage(),
              _buildSearchPage(),
              _buildSecurityPage(),
              _buildConnectionPage(),
            ],
          ),
          // Indicador de progreso SIN glassmorphismo para evitar superposición
          // SOLO mostrar si NO estamos en página 0 O si ya se mostró el contenido
          if (_currentPage != 3 && (_currentPage != 0 || _showContent))
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: CustomProgressIndicator(
                  currentStep: _currentPage,
                  totalSteps: 4,
                ),
              ),
            ),
          // Botones con glassmorphismo
          // SOLO mostrar si NO estamos en página 0 O si ya se mostró el contenido
          if (_currentPage != 0 || _showContent)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: _currentPage == 0 && _showContent
                  ? // ANIMACIÓN para la primera página
                  AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.2),
                                        Colors.white.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: CustomButton(
                                    text: S.of(context).nextButton,
                                    onPressed: _nextPage,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    textColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : // SIN animación para otras páginas
                  ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.white.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: _currentPage == 3
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomButton(
                                      text: S.of(context).loginButton,
                                      onPressed: () {
                                        Navigator.pushReplacementNamed(
                                            context, '/login');
                                      },
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      textColor: Colors.white,
                                    ),
                                    const SizedBox(height: 12),
                                    CustomButton(
                                      text: S.of(context).registerButton,
                                      onPressed: () {
                                        Navigator.pushReplacementNamed(
                                            context, '/register');
                                      },
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      textColor: Colors.white,
                                    ),
                                  ],
                                )
                              : CustomButton(
                                  text: S.of(context).nextButton,
                                  onPressed: _nextPage,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  textColor: Colors.white,
                                ),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Stack(
      children: [
        // Video de fondo LIMPIO - sin overlay oscuro
        if (_videoController != null && _videoController!.value.isInitialized)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),

        // NUEVO: Contenido que aparece después de 10 segundos con animación
        if (_showContent)
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                  child: Container(
                    // Overlay con degradado glassmorphic (solo cuando aparece el contenido)
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3 * _fadeAnimation.value),
                          Colors.black.withValues(alpha: 0.7 * _fadeAnimation.value),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.25),
                                      Colors.white.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      S.of(context).onboardingTitle1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 32,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                            color:
                                                Colors.black.withValues(alpha: 0.3),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      S.of(context).onboardingSubtitle1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 18,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(0, 1),
                                            blurRadius: 2,
                                            color:
                                                Colors.black.withValues(alpha: 0.3),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSearchPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.purple.shade50,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            _buildGlassmorphicTextContainer(
              title: S.of(context).onboardingTitle2,
              subtitle: S.of(context).onboardingSubtitle2,
            ),
            const SizedBox(height: 40),
            _buildGlassmorphicImageContainer('assets/images/mapa.png'),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.green.shade50,
            Colors.white,
            Colors.teal.shade50,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            _buildGlassmorphicTextContainer(
              title: S.of(context).onboardingTitle3,
              subtitle: S.of(context).onboardingSubtitle3,
            ),
            const SizedBox(height: 40),
            _buildGlassmorphicImageContainer('assets/images/seguridad.png'),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.orange.shade50,
            Colors.white,
            Colors.pink.shade50,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            _buildGlassmorphicTextContainer(
              title: S.of(context).onboardingTitle4,
              subtitle: S.of(context).onboardingSubtitle4,
            ),
            const SizedBox(height: 40),
            _buildGlassmorphicImageContainer('assets/images/conexion.png'),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassmorphicTextContainer(
      {required String title, required String subtitle}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 28,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicImageContainer(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
