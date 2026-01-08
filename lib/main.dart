import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'shared/theme/app_theme.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/properties/presentation/pages/add_property_page.dart';
import 'features/properties/presentation/pages/payment_methods_page.dart';
import 'features/social_areas/presentation/pages/social_areas_page.dart';
import 'features/alerts/presentation/pages/alert_history_page.dart';
import 'features/auth/data/services/auth_service.dart';

import 'features/auth/presentation/pages/auth_selection_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Inicializar autenticación
  final authService = AuthService();
  await authService.initializeAuth();

  // Configurar orientación de pantalla
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const HabittoApp());
}

class HabittoApp extends StatelessWidget {
  const HabittoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitto',
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const AuthWrapper(),
      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const AuthSelectionPage(),
        '/login-form': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/splash': (context) => const SplashPage(),
        '/home': (context) => const HomePage(),
        '/add-property': (context) => const AddPropertyPage(),
        '/payment-methods': (context) => const PaymentMethodsPage(),
        '/social-areas': (context) => const SocialAreasPage(),
        '/alert-history': (context) => const AlertHistoryPage(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isCheckingAuth = false; // Flag to prevent repeated auth checks

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (_isCheckingAuth) return; // Prevent repeated calls

    _isCheckingAuth = true;
    try {
      final isAuthenticated = await _authService.isAuthenticated();
      if (mounted) {
        setState(() {
          _isAuthenticated = isAuthenticated;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('AuthWrapper: Error checking auth status: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    } finally {
      _isCheckingAuth = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isAuthenticated) {
      return const SplashPage();
    } else {
      return const OnboardingPage();
    }
  }
}
