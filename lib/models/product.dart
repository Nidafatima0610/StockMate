/// Business rules and constants for StockMate inventory tracking.
///
/// Any product with a quantity of [kLowStockThreshold] or fewer (and greater than 0)
/// is flagged as "Low Stock" to warn the business owner to reorder.
const int kLowStockThreshold = 5;

/// Represents the three inventory states for a product.
enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  /// Determines the stock status based on the current product quantity.
  /// - Quantity <= 0: Out of Stock
  /// - Quantity <= 5: Low Stock
  /// - Quantity > 5: In Stock
  static StockStatus fromQuantity(int quantity) {
    if (quantity <= 0) {
      return StockStatus.outOfStock;
    } else if (quantity <= kLowStockThreshold) {
      return StockStatus.lowStock;
    } else {
      return StockStatus.inStock;
    }
  }

  /// User-facing label for the status badge.
  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }
}

/// Filter options for inventory browsing.
enum StockFilter {
  all,
  lowStock,
  outOfStock;

  String get label {
    switch (this) {
      case StockFilter.all:
        return 'All';
      case StockFilter.lowStock:
        return 'Low Stock';
      case StockFilter.outOfStock:
        return 'Out of Stock';
    }
  }
}

/// Product data model representing a single inventory item.
class Product {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String category;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.category = 'General',
  });

  /// Computes the stock status of this product based on its quantity.
  StockStatus get stockStatus => StockStatus.fromQuantity(quantity);
}

/// Exactly 3 sample products for Week 1 Day 1 demonstrating:
/// 1. In Stock (quantity: 24 > 5)
/// 2. Low Stock (quantity: 3 <= 5)
/// 3. Out of Stock (quantity: 0)
final List<Product> sampleProducts = [
  const Product(
    id: 'prod-001',
    name: 'Wireless Ergonomic Mouse',
    price: 29.99,
    quantity: 24,
    category: 'Electronics',
  ),
  const Product(
    id: 'prod-002',
    name: 'Mechanical Gaming Keyboard',
    price: 89.50,
    quantity: 3,
    category: 'Electronics',
  ),
  const Product(
    id: 'prod-003',
    name: 'USB-C Multiport Adapter',
    price: 19.00,
    quantity: 0,
    category: 'Accessories',
  ),
];
