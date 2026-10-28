/// Represents the type of inventory quantity movement.
enum StockMovementType {
  increase,
  decrease,
  adjustment;

  /// Human-readable label for movement display.
  String get label {
    switch (this) {
      case StockMovementType.increase:
        return 'Stock In';
      case StockMovementType.decrease:
        return 'Stock Out';
      case StockMovementType.adjustment:
        return 'Adjustment';
    }
  }
}

/// Model representing a single recorded stock change event.
///
/// Stores product information snapshot, previous/new quantities,
/// change magnitude, movement type, and timestamp.
class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final int previousQuantity;
  final int newQuantity;
  final int quantityChanged;
  final StockMovementType movementType;
  final DateTime timestamp;
  final String? note;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.previousQuantity,
    required this.newQuantity,
    required this.quantityChanged,
    required this.movementType,
    required this.timestamp,
    this.note,
  });

  /// Serializes movement record to a JSON map for local storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'previousQuantity': previousQuantity,
      'newQuantity': newQuantity,
      'quantityChanged': quantityChanged,
      'movementType': movementType.name,
      'timestamp': timestamp.toIso8601String(),
      if (note != null) 'note': note,
    };
  }

  /// Deserializes JSON map into a StockMovement instance with safe fallbacks.
  factory StockMovement.fromJson(Map<String, dynamic> json) {
    final typeName = json['movementType'] as String? ?? 'adjustment';
    final movementType = StockMovementType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => StockMovementType.adjustment,
    );

    return StockMovement(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? 'Unknown Product',
      previousQuantity: (json['previousQuantity'] as num?)?.toInt() ?? 0,
      newQuantity: (json['newQuantity'] as num?)?.toInt() ?? 0,
      quantityChanged: (json['quantityChanged'] as num?)?.toInt() ?? 0,
      movementType: movementType,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String?,
    );
  }

  /// Creates a copy with optional updated properties.
  StockMovement copyWith({
    String? id,
    String? productId,
    String? productName,
    int? previousQuantity,
    int? newQuantity,
    int? quantityChanged,
    StockMovementType? movementType,
    DateTime? timestamp,
    String? note,
  }) {
    return StockMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      previousQuantity: previousQuantity ?? this.previousQuantity,
      newQuantity: newQuantity ?? this.newQuantity,
      quantityChanged: quantityChanged ?? this.quantityChanged,
      movementType: movementType ?? this.movementType,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productId == other.productId &&
          productName == other.productName &&
          previousQuantity == other.previousQuantity &&
          newQuantity == other.newQuantity &&
          quantityChanged == other.quantityChanged &&
          movementType == other.movementType &&
          timestamp == other.timestamp &&
          note == other.note;

  @override
  int get hashCode =>
      id.hashCode ^
      productId.hashCode ^
      productName.hashCode ^
      previousQuantity.hashCode ^
      newQuantity.hashCode ^
      quantityChanged.hashCode ^
      movementType.hashCode ^
      timestamp.hashCode ^
      note.hashCode;
}
