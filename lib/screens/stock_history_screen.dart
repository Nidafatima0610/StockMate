import 'package:flutter/material.dart';

import '../models/stock_movement.dart';
import '../theme/app_theme.dart';

/// Screen displaying the chronological audit trail of all inventory quantity adjustments.
///
/// Redesigned with an executive audit ledger style:
/// - Quick Summary KPI metrics (Stock In, Stock Out, Total Logs)
/// - Modern search and movement-type filter controls
/// - Ledger-style cards with directional icons, SKU pills, delta badges, and timestamp
/// - Graceful handling of deleted products
/// - Empty state for zero records or unmatched search queries
class StockHistoryScreen extends StatefulWidget {
  final List<StockMovement> movements;
  final Set<String> activeProductIds;
  final VoidCallback? onBackToDashboard;

  const StockHistoryScreen({
    super.key,
    required this.movements,
    this.activeProductIds = const {},
    this.onBackToDashboard,
  });

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  StockMovementType? _selectedTypeFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns movements sorted newest first, filtered by type and search query.
  List<StockMovement> get _filteredMovements {
    final list = List<StockMovement>.from(widget.movements);
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return list.where((m) {
      final matchesType =
          _selectedTypeFilter == null || m.movementType == _selectedTypeFilter;
      final matchesSearch =
          _searchQuery.isEmpty ||
          m.productName.toLowerCase().contains(_searchQuery) ||
          m.productId.toLowerCase().contains(_searchQuery) ||
          (m.note?.toLowerCase().contains(_searchQuery) ?? false);

      return matchesType && matchesSearch;
    }).toList();
  }

  /// Formats [DateTime] into a clean human-readable string without external dependencies.
  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year • $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMovements;
    final totalMovements = widget.movements.length;

    final increaseCount = widget.movements
        .where((m) => m.movementType == StockMovementType.increase)
        .length;
    final decreaseCount = widget.movements
        .where((m) => m.movementType == StockMovementType.decrease)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          key: const Key('history_back_button'),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else if (widget.onBackToDashboard != null) {
              widget.onBackToDashboard!();
            }
          },
        ),
        title: const Text(
          'Stock Movement History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.5,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: const Color(0xFF5B2EBC),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Text(
              '$totalMovements logs',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                // Top controls container: Audit KPI Summary + Search + Filters
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFEAEAEE), width: 1.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B1829).withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Audit KPI metrics banner (only shown if there are movements)
                      if (totalMovements > 0) ...[
                        Row(
                          children: [
                            _buildKpiCard(
                              title: 'Inflow',
                              value: '+$increaseCount logs',
                              icon: Icons.south_west_rounded,
                              iconColor: const Color(0xFF0F764C),
                              bgColor: const Color(0xFFE6F7F0),
                              borderColor: const Color(0xFFB8ECCF),
                            ),
                            const SizedBox(width: 8),
                            _buildKpiCard(
                              title: 'Outflow',
                              value: '-$decreaseCount logs',
                              icon: Icons.north_east_rounded,
                              iconColor: const Color(0xFFC02626),
                              bgColor: const Color(0xFFFEECEB),
                              borderColor: const Color(0xFFFDC5C3),
                            ),
                            const SizedBox(width: 8),
                            _buildKpiCard(
                              title: 'Audit Total',
                              value: '$totalMovements records',
                              icon: Icons.receipt_long_rounded,
                              iconColor: const Color(0xFF5B2EBC),
                              bgColor: const Color(0xFFF3EFFF),
                              borderColor: const Color(0xFFE5DCFD),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Search input
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7FC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE2E2EA),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          key: const Key('history_search_field'),
                          controller: _searchController,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF1B1829),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by product name or ID...',
                            hintStyle: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF9E9CAF),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF5B2EBC),
                              size: 18,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 16,
                                      color: Color(0xFF7E7B92),
                                    ),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter chips
                      Row(
                        children: [
                          _buildTypeFilterChip(
                            label: 'All',
                            type: null,
                            count: widget.movements.length,
                          ),
                          const SizedBox(width: 8),
                          _buildTypeFilterChip(
                            label: 'Stock In',
                            type: StockMovementType.increase,
                            count: increaseCount,
                            activeColor: const Color(0xFF0F764C),
                          ),
                          const SizedBox(width: 8),
                          _buildTypeFilterChip(
                            label: 'Stock Out',
                            type: StockMovementType.decrease,
                            count: decreaseCount,
                            activeColor: const Color(0xFFC02626),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Movements list or empty state
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _buildMovementCard(filtered[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact executive KPI card for top audit summary
  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B687E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip({
    required String label,
    required StockMovementType? type,
    required int count,
    Color activeColor = const Color(0xFF5B2EBC),
  }) {
    final isSelected = _selectedTypeFilter == type;

    return Expanded(
      child: InkWell(
        key: Key('history_filter_${type?.name ?? 'all'}'),
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _selectedTypeFilter = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : const Color(0xFFF7F7FC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE2E2EA),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF555268),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFEAEAEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF6B687E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovementCard(StockMovement movement) {
    final isDeleted =
        widget.activeProductIds.isNotEmpty &&
        !widget.activeProductIds.contains(movement.productId);

    final isIncrease = movement.movementType == StockMovementType.increase;
    final isDecrease = movement.movementType == StockMovementType.decrease;

    final Color badgeBg;
    final Color badgeBorder;
    final Color badgeColor;
    final IconData icon;
    final String sign;

    if (isIncrease) {
      badgeBg = const Color(0xFFE6F7F0);
      badgeBorder = const Color(0xFFB8ECCF);
      badgeColor = const Color(0xFF0F764C);
      icon = Icons.south_west_rounded;
      sign = '+';
    } else if (isDecrease) {
      badgeBg = const Color(0xFFFEECEB);
      badgeBorder = const Color(0xFFFDC5C3);
      badgeColor = const Color(0xFFC02626);
      icon = Icons.north_east_rounded;
      sign = '-';
    } else {
      badgeBg = const Color(0xFFF3EFFF);
      badgeBorder = const Color(0xFFE5DCFD);
      badgeColor = const Color(0xFF5B2EBC);
      icon = Icons.swap_horiz_rounded;
      sign = 'Δ';
    }

    return Container(
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
            border: Border(left: BorderSide(color: badgeColor, width: 3.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Type Icon, Product Name, SKU, and Magnitude Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular movement type indicator
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: badgeBorder, width: 1),
                    ),
                    child: Icon(icon, color: badgeColor, size: 18),
                  ),
                  const SizedBox(width: 10),

                  // Product Name and SKU
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                movement.productName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B1829),
                                  letterSpacing: -0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isDeleted) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F3F8),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFDCD9E6),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'Deleted',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7E7B92),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F2F8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${movement.productId}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF7E7B92),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isIncrease
                                    ? 'Stock Restock'
                                    : isDecrease
                                    ? 'Stock Deduction'
                                    : 'Manual Adjustment',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: badgeColor,
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

                  // Quantity Change Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeBorder, width: 1),
                    ),
                    child: Text(
                      '$sign${movement.quantityChanged}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFF1F1F6),
              ),
              const SizedBox(height: 8),

              // Bottom row: Transition (Previous -> New), Reason / Note, and Timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quantity Transition
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7FC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFEAEAEE),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Qty: ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7E7B92),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${movement.previousQuantity}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF555268),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 11,
                            color: Color(0xFF9E9CAF),
                          ),
                        ),
                        Text(
                          '${movement.newQuantity}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Timestamp with clock icon
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: Color(0xFF9E9CAF),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatDateTime(movement.timestamp),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF9E9CAF),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (movement.note != null &&
                  movement.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 12,
                        color: Color(0xFF9E9CAF),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          movement.note!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF6B687E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFFF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5DCFD), width: 1.5),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 44,
                color: Color(0xFF5B2EBC),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Stock Movements Found',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B1829),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty || _selectedTypeFilter != null
                  ? 'No movements match your current search or filter criteria.'
                  : 'Adjust product quantities using the + / - steppers on the inventory screen to record stock movement history.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF6B687E),
                height: 1.4,
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedTypeFilter != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedTypeFilter = null;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset History Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5B2EBC),
                  side: const BorderSide(color: Color(0xFFD4C8FA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
