import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/stock_movement.dart';

/// Service responsible for persisting the product catalog, stock movement history,
/// and user-configurable settings to local storage via [SharedPreferences].
///
/// Preserves existing products, movement history, and low-stock threshold across app restarts.
class InventoryStorage {
  static const String _kProductsKey = 'stockmate_products_catalog';
  static const String _kInitializedKey = 'stockmate_has_initialized';
  static const String _kMovementsKey = 'stockmate_stock_movements';
  static const String _kThresholdKey = 'stockmate_low_stock_threshold';

  final SharedPreferences? _prefs;

  const InventoryStorage([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Loads the persisted products catalog.
  ///
  /// On first run, initializes storage with [sampleProducts].
  /// On subsequent runs, returns the saved inventory (even if empty).
  Future<List<Product>> loadProducts() async {
    try {
      final prefs = await _getPrefs();
      final hasInitialized = prefs.getBool(_kInitializedKey) ?? false;

      if (!hasInitialized) {
        await saveProducts(sampleProducts);
        await prefs.setBool(_kInitializedKey, true);
        return List<Product>.from(sampleProducts);
      }

      final jsonString = prefs.getString(_kProductsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        final products = <Product>[];
        for (final item in decoded) {
          if (item is Map) {
            try {
              products.add(Product.fromJson(Map<String, dynamic>.from(item)));
            } catch (_) {
              // Gracefully skip any corrupted individual records
            }
          }
        }
        return products;
      }
    } catch (_) {
      // In case of corrupt or uninitialized test storage, fall back safely to sample products
      return List<Product>.from(sampleProducts);
    }

    return [];
  }

  /// Persists the product catalog as a JSON string.
  Future<bool> saveProducts(List<Product> products) async {
    try {
      final prefs = await _getPrefs();
      final jsonString = jsonEncode(products.map((p) => p.toJson()).toList());
      await prefs.setBool(_kInitializedKey, true);
      return await prefs.setString(_kProductsKey, jsonString);
    } catch (_) {
      return false;
    }
  }

  /// Loads the persisted stock movement history (newest first).
  Future<List<StockMovement>> loadMovements() async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(_kMovementsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        final list = <StockMovement>[];
        for (final item in decoded) {
          if (item is Map) {
            try {
              list.add(StockMovement.fromJson(Map<String, dynamic>.from(item)));
            } catch (_) {}
          }
        }
        // Ensure sorted newest first
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  /// Persists the stock movement history as a JSON string.
  Future<bool> saveMovements(List<StockMovement> movements) async {
    try {
      final prefs = await _getPrefs();
      final jsonString = jsonEncode(movements.map((m) => m.toJson()).toList());
      return await prefs.setString(_kMovementsKey, jsonString);
    } catch (_) {
      return false;
    }
  }

  /// Loads the persisted low-stock threshold, falling back to [defaultThreshold].
  Future<int> loadLowStockThreshold({
    int defaultThreshold = kDefaultLowStockThreshold,
  }) async {
    try {
      final prefs = await _getPrefs();
      return prefs.getInt(_kThresholdKey) ?? defaultThreshold;
    } catch (_) {
      return defaultThreshold;
    }
  }

  /// Persists the low-stock threshold value.
  Future<bool> saveLowStockThreshold(int threshold) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.setInt(_kThresholdKey, threshold);
    } catch (_) {
      return false;
    }
  }

  /// Clears storage (useful for testing or reset flows).
  Future<void> clear() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_kProductsKey);
      await prefs.remove(_kInitializedKey);
      await prefs.remove(_kMovementsKey);
      await prefs.remove(_kThresholdKey);
    } catch (_) {}
  }
}
