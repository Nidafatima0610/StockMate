import 'package:flutter/material.dart';

/// StockMate Design System & Theme Tokens
///
/// Provides a cohesive, production-grade visual language:
/// - Refined purple palette with deep royal tones and soft lavender accents
/// - Crisp typography scale with balanced contrast and letter spacing
/// - Modern card elevations, multi-layer soft shadows, and subtle micro-borders
/// - Semantic status color palettes (In Stock, Low Stock, Out of Stock)
class AppTheme {
  AppTheme._();

  // Core Brand Colors
  static const Color primary = Color(0xFF5B2EBC);
  static const Color primaryDark = Color(0xFF431C9A);
  static const Color primaryLight = Color(0xFF7A4EE5);
  static const Color primarySubtle = Color(0xFFF3EFFF);
  static const Color primaryBorder = Color(0xFFE5DCFD);

  // Neutral Canvas & Surface Colors
  static const Color background = Color(0xFFF7F7FC);
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = Color(0xFFFAFAFD);
  static const Color surfaceMuted = Color(0xFFF2F2F7);

  // Border & Divider Tones
  static const Color border = Color(0xFFEAEAEE);
  static const Color borderLight = Color(0xFFF0F0F5);
  static const Color borderSubtle = Color(0xFFE2E2EA);

  // Text Colors
  static const Color textPrimary = Color(0xFF161324);
  static const Color textSecondary = Color(0xFF5C5872);
  static const Color textMuted = Color(0xFF8F8CA1);
  static const Color textDisabled = Color(0xFFBDBBC8);

  // Semantic Status: In Stock (Emerald)
  static const Color inStockText = Color(0xFF0F764C);
  static const Color inStockBg = Color(0xFFE6F7F0);
  static const Color inStockBorder = Color(0xFFB8ECCF);

  // Semantic Status: Low Stock (Amber)
  static const Color lowStockText = Color(0xFFB45309);
  static const Color lowStockBg = Color(0xFFFFF4E6);
  static const Color lowStockBorder = Color(0xFFFFDFB5);

  // Semantic Status: Out of Stock (Rose Crimson)
  static const Color outOfStockText = Color(0xFFC02626);
  static const Color outOfStockBg = Color(0xFFFEECEB);
  static const Color outOfStockBorder = Color(0xFFFDC5C3);

  // Soft Layered Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF161324).withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: const Color(0xFF161324).withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.32),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get headerShadow => [
    BoxShadow(
      color: primaryDark.withValues(alpha: 0.22),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // Material 3 ThemeData definition
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18.5,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1.1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }
}
