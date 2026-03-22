import 'package:flutter/material.dart';

class AppTheme {
  // Primary palette: deep navy + soft teal + warm coral
  static const Color navy = Color(0xFF0D1B2A);
  static const Color navyLight = Color(0xFF1A2D42);
  static const Color teal = Color(0xFF00C2CB);
  static const Color tealLight = Color(0xFF4DD9E0);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color gold = Color(0xFFFFD166);
  static const Color green = Color(0xFF06D6A0);
  static const Color surface = Color(0xFF142236);
  static const Color card = Color(0xFF1E3048);
  static const Color textPrimary = Color(0xFFE8F4F8);
  static const Color textSecondary = Color(0xFF8BA8C0);
  static const Color divider = Color(0xFF2A4060);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navy,
        colorScheme: const ColorScheme.dark(
          primary: teal,
          secondary: coral,
          surface: surface,
          onPrimary: navy,
          onSurface: textPrimary,
        ),
        cardColor: card,
        fontFamily: 'SF Pro Display',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -1.5,
          ),
          displayMedium: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -1.0,
          ),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: teal,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          iconTheme: IconThemeData(color: teal),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: teal,
            foregroundColor: navy,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

  // Vital status colors
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
      case 'good':
        return green;
      case 'elevated':
      case 'moderate':
        return gold;
      default:
        return coral;
    }
  }
}
