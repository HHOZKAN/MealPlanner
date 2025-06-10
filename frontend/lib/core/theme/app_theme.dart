import 'package:flutter/material.dart';

class AppTheme {
  // Application Colors
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryColor = Color(0xFFFF5722);    // Orange pour les accents
  static const Color backgroundColor = Color(0xFFF9F5F0); // Beige clair pour le fond
  static const Color textColor = Color(0xFF2D3142);       // Gris foncé pour le texte
  static const Color cardColor = Colors.white;            // Blanc pour les champs
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  
  // Spacing Constants
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Border Radius Constants
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 15.0;
  static const double radiusXL = 20.0;
  
  // Font Sizes
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  
  // Common Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: textColor.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0.5,
    ),
  ];
  
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: textColor.withOpacity(0.05),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0.5,
    ),
  ];
  
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}