import 'package:flutter/material.dart';

import 'screens/inventory_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const StockMateApp());
}

/// StockMate — Modern Small Business Inventory Application
///
/// Production-grade inventory management system featuring:
/// - Custom purple dashboard hero identity (#5B2EBC / #431C9A)
/// - Neutral canvas background (#F7F7FC)
/// - Crisp white cards with structured typography and accessible status badges
/// - Configurable low-stock threshold, stock movements audit ledger, and offline persistence
class StockMateApp extends StatelessWidget {
  const StockMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const InventoryScreen(),
    );
  }
}
