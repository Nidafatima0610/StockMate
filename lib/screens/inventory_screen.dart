import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/stock_movement.dart';
import '../services/inventory_storage.dart';
import 'add_edit_product_screen.dart';
import 'stock_history_screen.dart';

/// Professional small-business inventory dashboard for StockMate.
///
/// Features calculated stock health metrics, valuation summary, persistent storage,
/// quick +/- quantity adjustments, sort and category filtering, product deletion with undo,
/// stock movement history auditing, and user-configurable low-stock threshold.
class InventoryScreen extends StatefulWidget {
  final InventoryStorage storage;

  const InventoryScreen({super.key, this.storage = const InventoryStorage()});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // In-memory product catalog initialized with sample products
  late List<Product> _products = List.from(sampleProducts);

  // Stock movement history and low stock threshold configuration
  late List<StockMovement> _movements = [];
  int _lowStockThreshold = kDefaultLowStockThreshold;

  // Search, filter, category, and sort state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StockFilter _selectedFilter = StockFilter.all;
  String _selectedCategory = 'All Categories';
  ProductSortOption _selectedSort = ProductSortOption.nameAsc;

  @override
  void initState() {
    super.initState();
    _loadFromStorage();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Loads products, stock movements, and configured threshold from local storage.
  Future<void> _loadFromStorage() async {
    try {
      final loadedProducts = await widget.storage.loadProducts();
      final loadedMovements = await widget.storage.loadMovements();
      final loadedThreshold = await widget.storage.loadLowStockThreshold(
        defaultThreshold: kDefaultLowStockThreshold,
      );
      if (mounted) {
        setState(() {
          _products = loadedProducts;
          _movements = loadedMovements;
          _lowStockThreshold = loadedThreshold;
        });
      }
    } catch (_) {}
  }

  /// Saves the current product catalog to persistent local storage.
  Future<void> _saveToStorage() async {
    try {
      await widget.storage.saveProducts(_products);
    } catch (_) {}
  }

  /// Records an inventory movement event and persists history locally.
  void _recordMovement({
    required Product product,
    required int previousQuantity,
    required int newQuantity,
    required StockMovementType type,
    String? note,
  }) {
    if (previousQuantity == newQuantity) return;

    final movement = StockMovement(
      id: 'mov-${DateTime.now().microsecondsSinceEpoch}-${product.id}',
      productId: product.id,
      productName: product.name,
      previousQuantity: previousQuantity,
      newQuantity: newQuantity,
      quantityChanged: (newQuantity - previousQuantity).abs(),
      movementType: type,
      timestamp: DateTime.now(),
      note: note,
    );

    setState(() {
      _movements.insert(0, movement);
    });
    widget.storage.saveMovements(_movements);
  }

  /// Navigates to the Stock Movement History screen.
  Future<void> _navigateToHistory() async {
    final activeIds = _products.map((p) => p.id).toSet();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockHistoryScreen(
          movements: _movements,
          activeProductIds: activeIds,
        ),
      ),
    );
  }

  /// Displays the interactive modal dialog allowing the user to select and persist
  /// the minimum stock threshold.
  Future<void> _showThresholdDialog() async {
    int tempThreshold = _lowStockThreshold;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewCount = _products
                .where(
                  (p) =>
                      p.getStockStatus(tempThreshold) == StockStatus.lowStock,
                )
                .length;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EFFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF5B2EBC),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Low-Stock Threshold',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B1829),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Products with quantity between 1 and this threshold will be flagged as Low Stock. Out of stock products (0 qty) remain distinct.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF6B687E),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stepper control
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E2EA),
                        width: 1.1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Minimum Threshold Units',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7E7B92),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              key: const Key('threshold_decrement_button'),
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                              ),
                              color: tempThreshold > 1
                                  ? const Color(0xFF5B2EBC)
                                  : const Color(0xFFBDBBC8),
                              iconSize: 26,
                              onPressed: tempThreshold > 1
                                  ? () {
                                      setDialogState(() {
                                        tempThreshold--;
                                      });
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Container(
                              constraints: const BoxConstraints(minWidth: 40),
                              alignment: Alignment.center,
                              child: Text(
                                '$tempThreshold',
                                key: const Key('dialog_threshold_value'),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5B2EBC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              key: const Key('threshold_increment_button'),
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              color: const Color(0xFF5B2EBC),
                              iconSize: 26,
                              onPressed: () {
                                setDialogState(() {
                                  tempThreshold++;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Quick presets
                  const Text(
                    'Quick Presets:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7E7B92),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [2, 3, 5, 8, 10, 15, 20].map((preset) {
                      final isSelected = tempThreshold == preset;
                      return InkWell(
                        key: Key('threshold_preset_$preset'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setDialogState(() {
                            tempThreshold = preset;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5B2EBC)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF5B2EBC)
                                  : const Color(0xFFD4C8FA),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '≤ $preset',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF5B2EBC),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Live Preview Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFFDFB5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Preview: $previewCount products will be marked Low Stock',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5B2EBC),
                    side: const BorderSide(color: Color(0xFFD4C8FA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  key: const Key('save_threshold_button'),
                  onPressed: () => Navigator.pop(dialogContext, tempThreshold),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B2EBC),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save Threshold'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted && result != _lowStockThreshold) {
      setState(() {
        _lowStockThreshold = result;
      });
      await widget.storage.saveLowStockThreshold(result);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Low-stock threshold updated to ≤ $result'),
          backgroundColor: const Color(0xFF5B2EBC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Computes the unique list of categories present in the catalog.
  List<String> get _availableCategories {
    final categories = <String>{'All Categories'};
    for (final product in _products) {
      final cat = product.category.trim();
      if (cat.isNotEmpty) {
        categories.add(cat);
      }
    }
    return categories.toList();
  }

  /// Filtered and sorted product catalog.
  List<Product> get _filteredProducts {
    final list = _products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(
        _searchQuery.trim().toLowerCase(),
      );
      final matchesStock = switch (_selectedFilter) {
        StockFilter.all => true,
        StockFilter.lowStock =>
          product.getStockStatus(_lowStockThreshold) == StockStatus.lowStock,
        StockFilter.outOfStock =>
          product.getStockStatus(_lowStockThreshold) == StockStatus.outOfStock,
      };
      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          product.category.trim().toLowerCase() ==
              _selectedCategory.toLowerCase();

      return matchesSearch && matchesStock && matchesCategory;
    }).toList();

    switch (_selectedSort) {
      case ProductSortOption.nameAsc:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case ProductSortOption.nameDesc:
        list.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case ProductSortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.quantityAsc:
        list.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case ProductSortOption.quantityDesc:
        list.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
    }

    return list;
  }

  /// Increments quantity by 1, persists update, and logs movement history.
  void _incrementQuantity(Product product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      final oldQty = product.quantity;
      final newQty = oldQty + 1;
      setState(() {
        _products[index] = product.copyWith(quantity: newQty);
      });
      _saveToStorage();
      _recordMovement(
        product: product,
        previousQuantity: oldQty,
        newQuantity: newQty,
        type: StockMovementType.increase,
        note: 'Quick stepper increment (+1)',
      );
    }
  }

  /// Decrements quantity safely (never drops below 0), persists update, and logs movement history.
  void _decrementQuantity(Product product) {
    if (product.quantity <= 0) return;
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      final oldQty = product.quantity;
      final newQty = oldQty - 1;
      setState(() {
        _products[index] = product.copyWith(quantity: newQty);
      });
      _saveToStorage();
      _recordMovement(
        product: product,
        previousQuantity: oldQty,
        newQuantity: newQty,
        type: StockMovementType.decrease,
        note: 'Quick stepper decrement (-1)',
      );
    }
  }

  /// Navigates to the Add Product screen and awaits a newly created product.
  Future<void> _navigateToAddProduct() async {
    final newProduct = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditProductScreen(lowStockThreshold: _lowStockThreshold),
      ),
    );

    if (newProduct != null && mounted) {
      setState(() {
        _products.add(newProduct);
      });
      _saveToStorage();

      if (newProduct.quantity > 0) {
        _recordMovement(
          product: newProduct,
          previousQuantity: 0,
          newQuantity: newProduct.quantity,
          type: StockMovementType.increase,
          note: 'Initial stock on creation',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${newProduct.name} added to inventory!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF5B2EBC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Navigates to the Edit Product screen with pre-filled product details.
  Future<void> _navigateToEditProduct(Product product) async {
    final updatedProduct = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(
          product: product,
          lowStockThreshold: _lowStockThreshold,
        ),
      ),
    );

    if (updatedProduct != null && mounted) {
      final oldProduct = product;
      setState(() {
        final index = _products.indexWhere((p) => p.id == updatedProduct.id);
        if (index != -1) {
          _products[index] = updatedProduct;
        }
      });
      _saveToStorage();

      if (updatedProduct.quantity != oldProduct.quantity) {
        _recordMovement(
          product: updatedProduct,
          previousQuantity: oldProduct.quantity,
          newQuantity: updatedProduct.quantity,
          type: updatedProduct.quantity > oldProduct.quantity
              ? StockMovementType.increase
              : StockMovementType.decrease,
          note: 'Product details updated',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${updatedProduct.name} updated!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF5B2EBC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Shows confirmation dialog and deletes product on user approval with Undo action.
  Future<void> _confirmDeleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEECEB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFC02626),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Delete Product',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B1829),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? You can undo this action immediately.',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF555268),
            height: 1.35,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5B2EBC),
              side: const BorderSide(color: Color(0xFFD4C8FA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC02626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final deletedIndex = _products.indexWhere((p) => p.id == product.id);
      if (deletedIndex == -1) return;
      final removedProduct = _products[deletedIndex];

      setState(() {
        _products.removeAt(deletedIndex);
      });
      _saveToStorage();

      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${removedProduct.name} deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: const Color(0xFFFFD54F),
            onPressed: () {
              setState(() {
                _products.insert(deletedIndex, removedProduct);
              });
              _saveToStorage();
            },
          ),
          backgroundColor: const Color(0xFF322F3D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Maps product categories to contextual icons.
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices_rounded;
      case 'accessories':
        return Icons.cable_rounded;
      case 'office':
        return Icons.business_center_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically calculate stock metrics and inventory valuation
    final int totalCount = _products.length;
    final int lowStockCount = _products
        .where(
          (p) => p.getStockStatus(_lowStockThreshold) == StockStatus.lowStock,
        )
        .length;
    final int outOfStockCount = _products
        .where(
          (p) => p.getStockStatus(_lowStockThreshold) == StockStatus.outOfStock,
        )
        .length;
    final double totalValuation = _products.fold(
      0.0,
      (sum, p) => sum + (p.price * p.quantity),
    );

    final filteredList = _filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 1. Refined Brand Header, Overview Control Panel & Total Valuation
            _buildDashboardHeader(
              totalCount: totalCount,
              lowStockCount: lowStockCount,
              outOfStockCount: outOfStockCount,
              totalValuation: totalValuation,
            ),

            // 2. Search, Sort Selector, Stock Filters & Category Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 8),
                      _buildSortSelector(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildFilterChips(),
                  const SizedBox(height: 8),
                  _buildCategoryFilterRow(),
                ],
              ),
            ),

            // 3. Products Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: Color(0xFF5B2EBC),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Products (${filteredList.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B1829),
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    key: const Key('threshold_settings_button'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: _showThresholdDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EFFF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFE5DCFD),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 11,
                            color: Color(0xFF5B2EBC),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Threshold: ≤ $_lowStockThreshold',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF5B2EBC),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // 4. Products List or Polished Empty State
            if (filteredList.isEmpty)
              _buildEmptyState()
            else
              _buildProductListContainer(filteredList),

            // Clearance for Floating Action Button
            const SizedBox(height: 84),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddProduct,
        backgroundColor: const Color(0xFF5B2EBC),
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Add Product',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.1,
          ),
        ),
        tooltip: 'Add Product',
      ),
    );
  }

  /// Refined brand header with compact store status, calculated metrics, and valuation.
  Widget _buildDashboardHeader({
    required int totalCount,
    required int lowStockCount,
    required int outOfStockCount,
    required double totalValuation,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF451D87), Color(0xFF5B2EBC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Brand lockup and Store Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'StockMate',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 19,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Small Business Inventory',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFE2D9FC),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stock History screen button
                      InkWell(
                        key: const Key('history_button'),
                        onTap: _navigateToHistory,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'History',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Store Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              color: Color(0xFF4ADE80),
                              size: 7.5,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Store Active',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Compact horizontal summary metrics card
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _buildMetricTile(
                        count: '$totalCount',
                        label: 'Total Products',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF5B2EBC),
                        filter: StockFilter.all,
                      ),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Color(0xFFEAEAEE),
                      ),
                      _buildMetricTile(
                        count: '$lowStockCount',
                        label: 'Low Stock',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFB45309),
                        filter: StockFilter.lowStock,
                      ),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Color(0xFFEAEAEE),
                      ),
                      _buildMetricTile(
                        count: '$outOfStockCount',
                        label: 'Out of Stock',
                        icon: Icons.remove_circle_outline_rounded,
                        color: const Color(0xFFC02626),
                        filter: StockFilter.outOfStock,
                      ),
                    ],
                  ),
                ),
              ),

              // Total Inventory Valuation ribbon
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 15,
                            color: Color(0xFFE2D9FC),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Total Inventory Value',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFE2D9FC),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${totalValuation.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Single metric tile inside the horizontal summary card.
  Widget _buildMetricTile({
    required String count,
    required String label,
    required IconData icon,
    required Color color,
    required StockFilter filter,
  }) {
    final isSelected = _selectedFilter == filter;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.85),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Search bar for filtering products by name.
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2EA), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B1829).withValues(alpha: 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1B1829),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search products by name...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9E9CAF),
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF5B2EBC),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: Color(0xFF7E7B92),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// Sort selector menu button allowing users to order products.
  Widget _buildSortSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2EA), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B1829).withValues(alpha: 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<ProductSortOption>(
        key: const Key('sort_button'),
        tooltip: 'Sort Products',
        icon: const Icon(
          Icons.sort_rounded,
          color: Color(0xFF5B2EBC),
          size: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        initialValue: _selectedSort,
        onSelected: (option) {
          setState(() {
            _selectedSort = option;
          });
        },
        itemBuilder: (context) => [
          for (final option in ProductSortOption.values)
            PopupMenuItem(
              value: option,
              child: Row(
                children: [
                  Icon(
                    _selectedSort == option
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: _selectedSort == option
                        ? const Color(0xFF5B2EBC)
                        : const Color(0xFF9E9CAF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _selectedSort == option
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedSort == option
                            ? const Color(0xFF5B2EBC)
                            : const Color(0xFF1B1829),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Filter chips for quick status filtering (All, Low Stock, Out of Stock).
  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildChipItem(filter: StockFilter.all, label: 'All'),
        const SizedBox(width: 8),
        _buildChipItem(filter: StockFilter.lowStock, label: 'Low Stock'),
        const SizedBox(width: 8),
        _buildChipItem(filter: StockFilter.outOfStock, label: 'Out of Stock'),
      ],
    );
  }

  Widget _buildChipItem({required StockFilter filter, required String label}) {
    final isSelected = _selectedFilter == filter;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5B2EBC) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5B2EBC)
                  : const Color(0xFFE2E2EA),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF5B2EBC).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF555268),
            ),
          ),
        ),
      ),
    );
  }

  /// Horizontally scrollable category filter chips.
  Widget _buildCategoryFilterRow() {
    final categories = _availableCategories;
    return SizedBox(
      height: 29,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return InkWell(
            key: Key('category_chip_$cat'),
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF5B2EBC) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5B2EBC)
                      : const Color(0xFFE2E2EA),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF555268),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Unified, clean container grouping product rows with subtle dividers.
  Widget _buildProductListContainer(List<Product> products) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8EE), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B1829).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < products.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF1F1F6),
                indent: 64,
              ),
            _buildProductRow(products[i]),
          ],
        ],
      ),
    );
  }

  /// Single compact product row with category icon, stock badge, price, delete, and +/- quantity controls.
  Widget _buildProductRow(Product product) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToEditProduct(product),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category icon tile
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EFFF),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFFE5DCFD), width: 1),
                ),
                child: Icon(
                  _getCategoryIcon(product.category),
                  color: const Color(0xFF5B2EBC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title, Category/SKU, and Stock Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B1829),
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B687E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '#${product.id}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF9E9CAF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Stock status badge
                    _buildStockBadge(product),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Price, Delete button, and Quantity stepper
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5B2EBC),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        key: Key('delete_product_${product.id}'),
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _confirmDeleteProduct(product),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFF9E9CAF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Functional Quantity Stepper (+/-)
                  _buildQuantityStepper(product),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact, functional quantity adjustment widget (+ / -).
  Widget _buildQuantityStepper(Product product) {
    final bool canDecrement = product.quantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: product.quantity == 0
            ? const Color(0xFFFEECEB)
            : const Color(0xFFF4F3F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: product.quantity == 0
              ? const Color(0xFFFDC5C3)
              : const Color(0xFFE5E2EE),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement (-) button
          InkWell(
            key: Key('decrement_qty_${product.id}'),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(7),
            ),
            onTap: canDecrement ? () => _decrementQuantity(product) : () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Icon(
                Icons.remove_rounded,
                size: 15,
                color: canDecrement
                    ? (product.quantity == 0
                          ? const Color(0xFFC02626)
                          : const Color(0xFF5B2EBC))
                    : const Color(0xFFBDBBC8),
              ),
            ),
          ),
          // Current quantity display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Qty: ${product.quantity}',
              key: Key('product_qty_${product.id}'),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: product.quantity == 0
                    ? const Color(0xFFC02626)
                    : const Color(0xFF1B1829),
              ),
            ),
          ),
          // Increment (+) button
          InkWell(
            key: Key('increment_qty_${product.id}'),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(7),
            ),
            onTap: () => _incrementQuantity(product),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Icon(
                Icons.add_rounded,
                size: 15,
                color: Color(0xFF5B2EBC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact stock health badge.
  Widget _buildStockBadge(Product product) {
    final status = product.getStockStatus(_lowStockThreshold);
    Color badgeBg;
    Color badgeBorder;
    Color badgeText;
    IconData badgeIcon;
    String badgeLabel;

    switch (status) {
      case StockStatus.inStock:
        badgeBg = const Color(0xFFE6F7F0);
        badgeBorder = const Color(0xFFB8ECCF);
        badgeText = const Color(0xFF0F764C);
        badgeIcon = Icons.check_circle_rounded;
        badgeLabel = 'In Stock';
        break;
      case StockStatus.lowStock:
        badgeBg = const Color(0xFFFFF4E6);
        badgeBorder = const Color(0xFFFFDFB5);
        badgeText = const Color(0xFFB45309);
        badgeIcon = Icons.warning_amber_rounded;
        badgeLabel = 'Low Stock (${product.quantity})';
        break;
      case StockStatus.outOfStock:
        badgeBg = const Color(0xFFFEECEB);
        badgeBorder = const Color(0xFFFDC5C3);
        badgeText = const Color(0xFFC02626);
        badgeIcon = Icons.cancel_rounded;
        badgeLabel = 'Out of Stock';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeText, size: 11),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              badgeLabel,
              style: TextStyle(
                color: badgeText,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Clean empty state handler distinguishing empty search/filters vs. completely empty inventory.
  Widget _buildEmptyState() {
    if (_products.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8EE), width: 1.1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF3EFFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: Color(0xFF5B2EBC),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Products in Catalog',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B1829),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your inventory catalog is currently empty. Tap below to register your first product.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF6B687E)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToAddProduct,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add First Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B2EBC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildEmptySearchResults();
  }

  /// Thoughtful empty state when search or filter returns no matching items.
  Widget _buildEmptySearchResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8EE), width: 1.1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF3EFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: Color(0xFF5B2EBC),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Products Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1829),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'No items match "$_searchQuery".'
                : 'No products match the selected filter.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B687E)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedFilter = StockFilter.all;
                _selectedCategory = 'All Categories';
                _selectedSort = ProductSortOption.nameAsc;
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset Filters'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5B2EBC),
              side: const BorderSide(color: Color(0xFFD4C8FA)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
