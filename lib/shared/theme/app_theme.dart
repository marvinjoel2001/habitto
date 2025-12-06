import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFEC4A7E);
  static const Color secondaryColor = Color(0xFF9C55CC);
  static const Color accentMint = Color(0xFFFFD06A);
  static const Color mintGreen = Color(0xFF5C74F0);

  static const Color darkGrayBase = Color(0xFFF5F7FA);
  static const Color mediumGray = Color(0xFFECEFF4);
  static const Color lightGrayishDark = Color(0xFFE2E6ED);

  static const Color paleMint1 = Color(0xFFFF4848);
  static const Color whiteMint = Color(0xFFFFFFFF);

  static const Color blackColor = Color(0xFF000000);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color grayColor = Color(0xFFF0F5F2);
  static const Color errorColor = Color(0xFFCF6679);
  static const Color backgroundColor = darkGrayBase;

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: blackColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: blackColor,
  );

  static const LinearGradient profileGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      accentMint,
      paleMint1,
      primaryColor,
      secondaryColor,
      mintGreen,
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  static const LinearGradient profileGradientSoft = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      mintGreen,
      secondaryColor,
      primaryColor,
    ],
  );

  static const LinearGradient profileGradientWarm = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      accentMint,
      paleMint1,
      primaryColor,
    ],
  );

  static LinearGradient getCardGradient({double opacity = 0.20}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        whiteColor.withValues(alpha: 0.30),
        whiteColor.withValues(alpha: 0.65),
        whiteColor.withValues(alpha: 0.92),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: darkGrayBase,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: blackColor,
      secondary: accentMint,
      onSecondary: blackColor,
      tertiary: secondaryColor,
      onTertiary: blackColor,
      error: errorColor,
      onError: whiteColor,
      surface: whiteColor,
      onSurface: blackColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: blackColor,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: blackColor.withValues(alpha: 0.05),
      hintStyle: TextStyle(color: blackColor.withValues(alpha: 0.4)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: secondaryColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: blackColor.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: blackColor.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
    ),
  );

  static ThemeData darkTheme = lightTheme;

  static BoxDecoration getProfileBackground({int variant = 1}) {
    LinearGradient gradient;
    switch (variant) {
      case 1:
        gradient = profileGradient;
        break;
      case 2:
        gradient = profileGradientSoft;
        break;
      case 3:
        gradient = profileGradientWarm;
        break;
      default:
        gradient = profileGradient;
    }
    return BoxDecoration(gradient: gradient);
  }

  static BoxDecoration getGlassCard() {
    return BoxDecoration(
      gradient: getCardGradient(),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: blackColor.withValues(alpha: 0.1),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: blackColor.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration getMintButtonDecoration() {
    return BoxDecoration(
      gradient: profileGradient,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: accentMint.withValues(alpha: 0.2),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }

  static BoxDecoration getProfileImageBorder() {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: profileGradient,
      boxShadow: [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.3),
          blurRadius: 24,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
