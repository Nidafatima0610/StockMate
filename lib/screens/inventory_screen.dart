import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/stock_movement.dart';
import '../services/inventory_storage.dart';
import '../theme/app_theme.dart';
import 'add_edit_product_screen.dart';
import 'settings_screen.dart';
import 'stock_history_screen.dart';

/// Professional small-business inventory management application for StockMate.
///
/// Features a unified 4-page navigation shell:
/// 1. Dashboard: overview metrics, valuation hero, stock alerts, quick actions, recent products
/// 2. Products: complete catalog with search, category filtering, stock filters, sorting, and full cards
/// 3. Stock History: complete audit ledger with KPI metrics, search, and type filters
/// 4. Settings: configurable low-stock threshold, inventory rules, and catalog data management
class InventoryScreen extends StatefulWidget {
  final InventoryStorage storage;
  final int initialIndex;

  const InventoryScreen({
    super.key,
    this.storage = const InventoryStorage(),
    this.initialIndex = 0,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late int _selectedIndex;

  // In-memory product catalog initialized with sample products
  late List<Product> _products = List.from(sampleProducts);

  // Stock movement history and low stock threshold configuration
  late List<StockMovement> _movements = [];
  int _lowStockThreshold = kDefaultLowStockThreshold;

  // Search, filter, category, and sort state
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StockFilter _selectedFilter = StockFilter.all;
  String _selectedCategory = 'All Categories';
  ProductSortOption _selectedSort = ProductSortOption.nameAsc;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadFromStorage();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  /// Updates and persists the low-stock threshold rule across all screens.
  void _setLowStockThreshold(int newThreshold) {
    setState(() {
      _lowStockThreshold = newThreshold;
    });
    widget.storage.saveLowStockThreshold(newThreshold);
  }

  /// Restores default sample products and saves to persistent storage.
  Future<void> _resetDemoCatalog() async {
    setState(() {
      _products = List<Product>.from(sampleProducts);
    });
    await widget.storage.saveProducts(_products);
  }

  /// Clears historical stock movement logs and saves to storage.
  Future<void> _clearMovements() async {
    setState(() {
      _movements = [];
    });
    await widget.storage.saveMovements([]);
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
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.jumpTo(0.0);
      }
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
    switch (category.toLowerCase().trim()) {
      case 'electronics':
        return Icons.devices_rounded;
      case 'accessories':
        return Icons.cable_rounded;
      case 'office':
        return Icons.business_center_rounded;
      case 'peripherals':
        return Icons.mouse_rounded;
      case 'audio':
        return Icons.headphones_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase().trim()) {
      case 'electronics':
        return const Color(0xFF2563EB);
      case 'accessories':
        return const Color(0xFF5B2EBC);
      case 'office':
        return const Color(0xFF059669);
      case 'peripherals':
        return const Color(0xFFD946EF);
      case 'audio':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF5B2EBC);
    }
  }

  Color _getCategoryBg(String category) {
    switch (category.toLowerCase().trim()) {
      case 'electronics':
        return const Color(0xFFEFF6FF);
      case 'accessories':
        return const Color(0xFFF3EFFF);
      case 'office':
        return const Color(0xFFECFDF5);
      case 'peripherals':
        return const Color(0xFFFDF2F8);
      case 'audio':
        return const Color(0xFFFFF7ED);
      default:
        return const Color(0xFFF5F3FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      body: _buildCurrentPage(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEAEAEE), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          elevation: 4,
          indicatorColor: const Color(0xFFF3EFFF),
          destinations: const [
            NavigationDestination(
              key: Key('nav_dashboard'),
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(
                Icons.dashboard_rounded,
                color: Color(0xFF5B2EBC),
              ),
              label: 'Dashboard',
            ),
            NavigationDestination(
              key: Key('nav_products'),
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFF5B2EBC),
              ),
              label: 'Products',
            ),
            NavigationDestination(
              key: Key('nav_history'),
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(
                Icons.history_rounded,
                color: Color(0xFF5B2EBC),
              ),
              label: 'History',
            ),
            NavigationDestination(
              key: Key('nav_settings'),
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(
                Icons.settings_rounded,
                color: Color(0xFF5B2EBC),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1)
          ? FloatingActionButton(
              key: const Key('add_product_fab'),
              onPressed: _navigateToAddProduct,
              backgroundColor: const Color(0xFF5B2EBC),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tooltip: 'Add Product',
              child: const Icon(Icons.add_rounded, size: 26),
            )
          : null,
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardPage();
      case 1:
        return _buildProductsPage();
      case 2:
        return _buildHistoryPage();
      case 3:
        return _buildSettingsPage();
      default:
        return _buildDashboardPage();
    }
  }

  /// Page 1: Dashboard Overview
  Widget _buildDashboardPage() {
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

    // Shows recent/featured items on dashboard
    final recentProducts = _products.take(6).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 84),
              children: [
                // 1. Dashboard Subtitle / Header
                _buildDashboardHeader(),
                const SizedBox(height: 4),

                // 2. Executive Total Valuation Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildValuationCard(
                    totalValuation: totalValuation,
                    totalCount: totalCount,
                    lowStockCount: lowStockCount,
                    outOfStockCount: outOfStockCount,
                  ),
                ),
                const SizedBox(height: 6),

                // 3. 3-Card Summary Metrics Grid
                _buildMetricsOverview(
                  totalCount: totalCount,
                  lowStockCount: lowStockCount,
                  outOfStockCount: outOfStockCount,
                ),
                const SizedBox(height: 8),

                // 4. Products Section Header with Threshold Action Pill
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: Color(0xFF5B2EBC),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Products ($totalCount)',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B1829),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildThresholdPill(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 5. Important Stock Alerts Section
                _buildStockAlertBanner(
                  lowStockCount: lowStockCount,
                  outOfStockCount: outOfStockCount,
                ),
                const SizedBox(height: 8),

                // 6. Quick Actions Bar
                _buildQuickActionBar(),
                const SizedBox(height: 8),

                // 7. Recent Product Cards or Empty State
                if (recentProducts.isEmpty)
                  _buildEmptyState()
                else
                  Column(
                    children: [
                      for (final product in recentProducts)
                        _buildProductCard(product),
                    ],
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Page 2: Products Complete Catalog
  Widget _buildProductsPage() {
    final filteredList = _filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      appBar: _buildProductsAppBar(),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 10, bottom: 84),
              children: [
                // 1. Search & Sort Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 8),
                      _buildSortSelector(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 2. Stock Status Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFilterChips(),
                ),
                const SizedBox(height: 8),

                // 3. Category Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCategoryFilterRow(),
                ),
                const SizedBox(height: 10),

                // 4. Products Section Header with Threshold Action Pill
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.format_list_bulleted_rounded,
                              size: 16,
                              color: Color(0xFF5B2EBC),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Products (${filteredList.length})',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B1829),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildThresholdPill(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 5. Individual Product Cards or Polished Empty State
                if (filteredList.isEmpty)
                  _buildEmptyState()
                else
                  Column(
                    children: [
                      for (final product in filteredList)
                        _buildProductCard(product),
                    ],
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Page 3: Stock Movement Audit History
  Widget _buildHistoryPage() {
    return StockHistoryScreen(
      movements: _movements,
      activeProductIds: _products.map((p) => p.id).toSet(),
      onBackToDashboard: () {
        setState(() {
          _selectedIndex = 0;
        });
      },
    );
  }

  /// Page 4: Settings & Threshold Rules
  Widget _buildSettingsPage() {
    return SettingsScreen(
      lowStockThreshold: _lowStockThreshold,
      onThresholdChanged: _setLowStockThreshold,
      onOpenThresholdDialog: _showThresholdDialog,
      products: _products,
      onResetDemoCatalog: _resetDemoCatalog,
      onClearHistory: _clearMovements,
    );
  }

  /// Interactive stock alert banner displayed on Dashboard.
  Widget _buildStockAlertBanner({
    required int lowStockCount,
    required int outOfStockCount,
  }) {
    final hasAlerts = lowStockCount > 0 || outOfStockCount > 0;

    if (!hasAlerts) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F7F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB8ECCF), width: 1),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF0F764C),
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Optimal Stock Health • All catalog items above warning thresholds.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F764C),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isCritical = outOfStockCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCritical ? const Color(0xFFFEECEB) : const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical ? const Color(0xFFFDC5C3) : const Color(0xFFFFDFB5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isCritical
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFFDE68A),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCritical
                  ? Icons.error_outline_rounded
                  : Icons.warning_amber_rounded,
              color: isCritical
                  ? const Color(0xFF991B1B)
                  : const Color(0xFF92400E),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical ? 'Urgent Restock Required' : 'Low Stock Alert',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isCritical
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF92400E),
                  ),
                ),
                Text(
                  '$lowStockCount low stock, $outOfStockCount depleted item(s).',
                  style: TextStyle(
                    fontSize: 11,
                    color: isCritical
                        ? const Color(0xFF7F1D1D)
                        : const Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            key: const Key('alert_review_button'),
            onTap: () {
              setState(() {
                _selectedIndex = 1;
                _selectedFilter = isCritical
                    ? StockFilter.outOfStock
                    : StockFilter.lowStock;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCritical
                      ? const Color(0xFFFDC5C3)
                      : const Color(0xFFFFDFB5),
                ),
              ),
              child: Text(
                'Review',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isCritical
                      ? const Color(0xFF991B1B)
                      : const Color(0xFF92400E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick actions bar displayed on Dashboard.
  Widget _buildQuickActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('dashboard_add_product_button'),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
              label: const Text('Add Product'),
              onPressed: _navigateToAddProduct,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5B2EBC),
                side: const BorderSide(color: Color(0xFFD4C8FA)),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('dashboard_view_catalog_button'),
              icon: const Icon(Icons.inventory_2_outlined, size: 15),
              label: const Text('View Catalog'),
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5B2EBC),
                side: const BorderSide(color: Color(0xFFD4C8FA)),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive threshold indicator pill.
  Widget _buildThresholdPill() {
    return InkWell(
      key: const Key('threshold_settings_button'),
      borderRadius: BorderRadius.circular(8),
      onTap: _showThresholdDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5DCFD), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 11, color: Color(0xFF5B2EBC)),
            const SizedBox(width: 4),
            Text(
              'Threshold: ≤ $_lowStockThreshold',
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF5B2EBC),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Distinctive App Bar for Page 2 (Products Catalog).
  PreferredSizeWidget _buildProductsAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: const Color(0xFF431C9A),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5B2EBC), Color(0xFF431C9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_rounded, size: 20, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Product Catalog',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Distinctive top App Bar with branding lockup, live indicator, and Stock History.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: const Color(0xFF431C9A),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A0F55), Color(0xFF431C9A), Color(0xFF5B2EBC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 6),
          const Flexible(
            child: Text(
              'StockMate',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: InkWell(
            key: const Key('history_button'),
            onTap: _navigateToHistory,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.24),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_movements.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_movements.length}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Executive store header displaying inventory title and catalog status.
  Widget _buildDashboardHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store Inventory',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF161324),
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage store catalog, pricing & stock health',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF7E7B92),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFEBFDF2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFB9F3CE), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 5, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  'Catalog Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F764C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Executive total inventory valuation banner.
  Widget _buildValuationCard({
    required double totalValuation,
    required int totalCount,
    required int lowStockCount,
    required int outOfStockCount,
  }) {
    final healthyCount = totalCount - lowStockCount - outOfStockCount;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF260D59), Color(0xFF3F168A), Color(0xFF5B2EBC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF431C9A).withValues(alpha: 0.26),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 13,
                      color: Color(0xFFE2D9FC),
                    ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Total Inventory Value',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE2D9FC),
                          letterSpacing: 0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalCount Items',
                      style: const TextStyle(
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
          const SizedBox(height: 4),
          Text(
            '\$${totalValuation.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_graph_rounded,
                  size: 12,
                  color: Color(0xFFE2D9FC),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$healthyCount Optimal  •  $lowStockCount Low  •  $outOfStockCount Depleted',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE2D9FC),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Row of 3 dedicated, interactive KPI overview cards.
  Widget _buildMetricsOverview({
    required int totalCount,
    required int lowStockCount,
    required int outOfStockCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildKpiCard(
            count: '$totalCount',
            label: 'Total Products',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF5B2EBC),
            filter: StockFilter.all,
          ),
          const SizedBox(width: 6),
          _buildKpiCard(
            count: '$lowStockCount',
            label: 'Low Stock',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFB45309),
            filter: StockFilter.lowStock,
          ),
          const SizedBox(width: 6),
          _buildKpiCard(
            count: '$outOfStockCount',
            label: 'Out of Stock',
            icon: Icons.remove_circle_outline_rounded,
            color: const Color(0xFFC02626),
            filter: StockFilter.outOfStock,
          ),
        ],
      ),
    );
  }

  /// Single interactive KPI metric card.
  Widget _buildKpiCard({
    required String count,
    required String label,
    required IconData icon,
    required Color color,
    required StockFilter filter,
  }) {
    final isSelected = _selectedFilter == filter;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFEAEAEE),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withValues(alpha: 0.12)
                    : const Color(0xFF161324).withValues(alpha: 0.03),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: color),
                  const SizedBox(width: 4),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 15.5,
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
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : const Color(0xFF5C5872),
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
        key: const Key('product_search_field'),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _buildCategoryChip(categories[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String cat) {
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        child: Text(
          cat,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF555268),
          ),
        ),
      ),
    );
  }

  /// Individual elevated product card with clear product name, category, SKU, price,
  /// delete action, stock status badge, and +/- quantity controls.
  Widget _buildProductCard(Product product) {
    final status = product.getStockStatus(_lowStockThreshold);
    final isOutOfStock = status == StockStatus.outOfStock;
    final isLowStock = status == StockStatus.lowStock;

    final Color statusAccent = isOutOfStock
        ? const Color(0xFFEF4444)
        : (isLowStock ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEE), width: 1.1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusAccent, width: 3.5)),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Top clickable portion: Category avatar, Name, Category chip, SKU, Price, Delete
              InkWell(
                key: Key('edit_product_${product.id}'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => _navigateToEditProduct(product),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Category icon avatar tile with tailored tinting
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _getCategoryBg(product.category),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: _getCategoryColor(product.category)
                              .withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getCategoryIcon(product.category),
                        color: _getCategoryColor(product.category),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Product Title, Category capsule, SKU
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF161324),
                              letterSpacing: -0.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3.5),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F3F8),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    product.category,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6B687E),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '#${product.id}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF9E9CAF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Price & Delete action
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EFFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5B2EBC),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Delete product',
                          child: InkWell(
                            key: Key('delete_product_${product.id}'),
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _confirmDeleteProduct(product),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 17,
                                color: Color(0xFF9E9CAF),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F6)),
              const SizedBox(height: 8),

              // Bottom row: Stock status badge on left, Quantity stepper on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: _buildStockBadge(product)),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuantityStepper(product),
                      if (MediaQuery.of(context).size.width > 600)
                        const SizedBox(width: 72),
                    ],
                  ),
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
          Tooltip(
            message: 'Decrease quantity',
            child: InkWell(
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
          Tooltip(
            message: 'Increase quantity',
            child: InkWell(
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
              key: const Key('empty_add_product_button'),
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
