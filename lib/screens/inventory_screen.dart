import 'package:flutter/material.dart';

import '../models/product.dart';
import 'add_edit_product_screen.dart';

/// Professional small-business inventory dashboard for StockMate.
///
/// Features calculated stock health metrics, in-memory search and filter chips,
/// scannable product rows with accessible stock badges, and seamless navigation.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // In-memory product catalog initialized with 3 sample products
  final List<Product> _products = List.from(sampleProducts);

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StockFilter _selectedFilter = StockFilter.all;

  @override
  void initState() {
    super.initState();
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

  /// Filtered product catalog based on active search query and filter chip.
  List<Product> get _filteredProducts {
    return _products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(
        _searchQuery.trim().toLowerCase(),
      );
      final matchesFilter = switch (_selectedFilter) {
        StockFilter.all => true,
        StockFilter.lowStock => product.stockStatus == StockStatus.lowStock,
        StockFilter.outOfStock => product.stockStatus == StockStatus.outOfStock,
      };
      return matchesSearch && matchesFilter;
    }).toList();
  }

  /// Navigates to the Add Product screen.
  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditProductScreen()),
    );
  }

  /// Navigates to the Edit Product screen with pre-filled product details.
  void _navigateToEditProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: product),
      ),
    );
  }

  /// Maps product categories to contextual icons.
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices_rounded;
      case 'accessories':
        return Icons.cable_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically calculate stock metrics from the full product catalog
    final int totalCount = _products.length;
    final int lowStockCount = _products
        .where((p) => p.stockStatus == StockStatus.lowStock)
        .length;
    final int outOfStockCount = _products
        .where((p) => p.stockStatus == StockStatus.outOfStock)
        .length;

    final filteredList = _filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 1. Refined Brand Header & Overview Control Panel
            _buildDashboardHeader(
              totalCount: totalCount,
              lowStockCount: lowStockCount,
              outOfStockCount: outOfStockCount,
            ),

            // 2. Search Field and Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 10),
                  _buildFilterChips(),
                ],
              ),
            ),

            // 3. Products Section Editorial Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Color(0xFF5B2EBC),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Products (${filteredList.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B1829),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
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
                    child: Text(
                      'Threshold: ≤ $kLowStockThreshold',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5B2EBC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 4. Products List or Empty State
            if (filteredList.isEmpty)
              _buildEmptySearchResults()
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

  /// Refined brand header with compact store status and calculated metrics.
  Widget _buildDashboardHeader({
    required int totalCount,
    required int lowStockCount,
    required int outOfStockCount,
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Brand lockup and Store Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      const Column(
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
                          ),
                          Text(
                            'Small Business Inventory',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFE2D9FC),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

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
                        Icon(Icons.circle, color: Color(0xFF4ADE80), size: 7.5),
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

              const SizedBox(height: 16),

              // Compact horizontal summary metrics card
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
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

  /// Single compact product row with category icon tile, stock badge, and price.
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
                        Text(
                          product.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B687E),
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

              // Price, Quantity pill, and interactive chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5B2EBC),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: product.quantity == 0
                          ? const Color(0xFFFEECEB)
                          : const Color(0xFFF4F3F8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warehouse_outlined,
                          size: 11.5,
                          color: product.quantity == 0
                              ? const Color(0xFFC02626)
                              : const Color(0xFF6B687E),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Qty: ${product.quantity}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: product.quantity == 0
                                ? const Color(0xFFC02626)
                                : const Color(0xFF1B1829),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFFB5B3C2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact stock health badge.
  Widget _buildStockBadge(Product product) {
    final status = product.stockStatus;
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
          Text(
            badgeLabel,
            style: TextStyle(
              color: badgeText,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
