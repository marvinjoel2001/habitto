import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Paleta de colores - Menta Fresca y Grises Oscuros Balanceados
  static const Color primaryColor = Color(0xFFA9F9E2); // Menta suave principal
  static const Color secondaryColor =
      Color(0xFF7CE6B8); // Menta más intenso para contraste
  static const Color accentMint =
      Color(0xFF66FFC4); // Menta vibrante para acentos

  // 🌑 Tonos Grises Oscuros para el degradado y fondos (NO NEGRO PURO)
  static const Color darkGrayBase =
      Color(0xFF1C1C1E); // Gris muy oscuro, base principal
  static const Color mediumGray =
      Color(0xFF2C2C2E); // Gris oscuro medio para transiciones
  static const Color lightGrayishDark =
      Color(0xFF424244); // Un gris oscuro más claro

  // 🍃 Paleta de soporte (tonos neutros y verdes)
  static const Color paleMint1 = Color(0xFFDFFFF6); // Menta muy pálido
  static const Color whiteMint =
      Color(0xFFF5FFFA); // Un blanco con un toque mínimo de menta

  // 🎭 Colores base (Tonos Neutros y de Sistema)
  static const Color blackColor =
      Color(0xFF0A0A0A); // Se mantiene para algunas sombras o detalles
  static const Color whiteColor = Color(0xFFFCFCFC); // Blanco puro y limpio
  static const Color grayColor = Color(
      0xFFF0F5F2); // Para inputs en light theme (si se usara un light mode real)
  static const Color errorColor = Color(0xFFCF6679);
  static const Color backgroundColor = darkGrayBase; // Color de fondo principal

  // 📝 Estilos de texto
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: whiteColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: whiteColor,
  );

  // 🌟 Gradiente PRINCIPAL - (Blanco/Menta a Gris Oscuro - Más luminoso arriba, sutil abajo)
  static const LinearGradient profileGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      whiteMint, // Empieza casi blanco con un toque de menta
      primaryColor, // Pasa por el menta suave
      mediumGray, // Transiciona a un gris oscuro medio
      darkGrayBase, // Termina en un gris muy oscuro (no negro)
    ],
    // Ajusta los stops para la transición más gradual y luminosa arriba
    stops: [0.0, 0.25, 0.65, 1.0],
  );

  // 🌈 Gradiente SUAVE - (Similar, pero quizá menos contraste)
  static const LinearGradient profileGradientSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      paleMint1,
      mediumGray,
    ],
    stops: [0.0, 1.0],
  );

  // 💫 Gradiente VIBRANTE - (Para botones y elementos destacados)
  static const LinearGradient profileGradientWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      secondaryColor,
      accentMint,
    ],
    stops: [0.0, 1.0],
  );

  // 🎨 Gradiente para cards - Glassmorphism (Menta y Transparencia sobre el fondo)
  // Ajustamos las opacidades para que se vean bien sobre el nuevo fondo
  static LinearGradient getCardGradient({double opacity = 0.20}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color.fromARGB(255, 0, 0, 0)
            .withValues(alpha: opacity * 1.5), // Más transparente, pero presente
        primaryColor.withValues(alpha: opacity * 0.5), // Toque de menta muy sutil
      ],
      stops: const [0.0, 1.0],
    );
  }

  // 🌞 Light/Main Theme - Diseñado para usarse con el fondo de degradado
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness:
        Brightness.dark, // Para que el texto de la barra de estado sea blanco
    scaffoldBackgroundColor: darkGrayBase, // Fondo base gris oscuro
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryColor,
      onPrimary: Color(0xFF003D2B), // Texto oscuro sobre el menta
      secondary: accentMint,
      onSecondary: blackColor,
      tertiary: paleMint1,
      onTertiary: blackColor,
      error: errorColor,
      onError: blackColor,
      surface:
          mediumGray, // Superficies ligeramente más claras que el fondo base
      onSurface: whiteColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: whiteColor,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: const Color(0xFF003D2B),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromARGB(255, 254, 254, 255), // Un gris oscuro claro para los inputs
      hintStyle: TextStyle(color: const Color.fromARGB(255, 220, 220, 220)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        // Borde plomito delgado también al enfocar
        borderSide: BorderSide(color: darkGrayBase.withOpacity(0.4), width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        // Borde plomito súper delgado en estado normal
        borderSide: BorderSide(
          color: darkGrayBase.withOpacity(0.3),
          width: 0.8,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: darkGrayBase.withOpacity(0.2),
          width: 0.8,
        ),
      ),
    ),
  );

  // 🌚 Dark Theme - (Esencialmente el mismo que el lightTheme en este diseño)
  static ThemeData darkTheme = lightTheme;

  // 🎨 Fondo del perfil con variantes
  static BoxDecoration getProfileBackground({int variant = 1}) {
    LinearGradient gradient;
    switch (variant) {
      case 1:
        gradient = profileGradient; // Principal: Blanco/Menta a Gris Oscuro
        break;
      case 2:
        gradient = profileGradientSoft; // Suave
        break;
      case 3:
        gradient = profileGradientWarm; // Vibrante (para otros elementos)
        break;
      default:
        gradient = profileGradient;
    }
    return BoxDecoration(gradient: gradient);
  }

  // 💎 Cards con glassmorphism
  // Hemos ajustado las opacidades en getCardGradient directamente para mayor control
  static BoxDecoration getGlassCard() {
    return BoxDecoration(
      gradient: getCardGradient(), // Usa el gradiente ajustado para las cards
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: whiteColor.withOpacity(0.25), // Borde un poco más visible
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: blackColor.withOpacity(0.15), // Sombra más suave
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // ✨ Botón mint con gradiente y glow
  static BoxDecoration getMintButtonDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [secondaryColor, primaryColor, accentMint],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.5),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: accentMint.withOpacity(0.3),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }

  // 🎯 Borde para foto de perfil
  static BoxDecoration getProfileImageBorder() {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentMint, secondaryColor, primaryColor],
        stops: [0.0, 0.5, 1.0],
      ),
      boxShadow: [
        BoxShadow(
          color: accentMint.withOpacity(0.4),
          blurRadius: 24,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
