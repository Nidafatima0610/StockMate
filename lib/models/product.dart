/// Business rules and constants for StockMate inventory tracking.
///
/// Default threshold value for low stock warnings.
const int kDefaultLowStockThreshold = 5;

/// Any product with a quantity of [kLowStockThreshold] or fewer (and greater than 0)
/// is flagged as "Low Stock" to warn the business owner to reorder.
const int kLowStockThreshold = kDefaultLowStockThreshold;

/// Represents the three inventory states for a product.
enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  /// Determines the stock status based on the current product quantity and low stock threshold.
  /// - Quantity <= 0: Out of Stock
  /// - Quantity <= threshold: Low Stock
  /// - Quantity > threshold: In Stock
  static StockStatus fromQuantity(
    int quantity, {
    int threshold = kDefaultLowStockThreshold,
  }) {
    if (quantity <= 0) {
      return StockStatus.outOfStock;
    } else if (quantity <= threshold) {
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

/// Sorting criteria options for inventory catalog.
enum ProductSortOption {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  quantityAsc,
  quantityDesc;

  String get label {
    switch (this) {
      case ProductSortOption.nameAsc:
        return 'Name (A to Z)';
      case ProductSortOption.nameDesc:
        return 'Name (Z to A)';
      case ProductSortOption.priceAsc:
        return 'Price (Low to High)';
      case ProductSortOption.priceDesc:
        return 'Price (High to Low)';
      case ProductSortOption.quantityAsc:
        return 'Quantity (Lowest First)';
      case ProductSortOption.quantityDesc:
        return 'Quantity (Highest First)';
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

  /// Computes the stock status of this product using a custom threshold.
  StockStatus getStockStatus(int threshold) =>
      StockStatus.fromQuantity(quantity, threshold: threshold);

  /// Creates a copy of this product with optional updated properties.
  Product copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
    );
  }

  /// Converts product instance to a JSON map for local persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category,
    };
  }

  /// Deserializes a JSON map into a Product instance with safe type defaults.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'General',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price &&
          quantity == other.quantity &&
          category == other.category;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      price.hashCode ^
      quantity.hashCode ^
      category.hashCode;
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
