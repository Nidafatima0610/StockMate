import 'package:flutter/material.dart';

import 'screens/inventory_screen.dart';

void main() {
  runApp(const StockMateApp());
}

/// StockMate — Small Business Inventory App (Week 1 Day 1)
///
/// Premium small-business inventory dashboard featuring:
/// - Custom purple dashboard hero identity (#5B2EBC / #431C9A)
/// - Neutral canvas background (#F7F7FC)
/// - Crisp white cards with structured typography and accessible status badges
class StockMateApp extends StatelessWidget {
  const StockMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF5B2EBC);
    const backgroundCanvas = Color(0xFFF7F7FC);

    return MaterialApp(
      title: 'StockMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundCanvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryPurple,
          primary: primaryPurple,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEAEAEE), width: 1.2),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      home: const InventoryScreen(),
    );
  }
}
