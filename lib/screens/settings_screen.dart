import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';

/// Screen allowing the user to configure the low-stock threshold,
/// customize inventory preferences, and manage local catalog data.
class SettingsScreen extends StatefulWidget {
  final int lowStockThreshold;
  final ValueChanged<int> onThresholdChanged;
  final VoidCallback onOpenThresholdDialog;
  final List<Product> products;
  final VoidCallback? onResetDemoCatalog;
  final VoidCallback? onClearHistory;

  const SettingsScreen({
    super.key,
    required this.lowStockThreshold,
    required this.onThresholdChanged,
    required this.onOpenThresholdDialog,
    required this.products,
    this.onResetDemoCatalog,
    this.onClearHistory,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _confirmDeletions = true;
  bool _autoRecordInflows = true;

  static const List<int> _presetThresholds = [3, 5, 10, 15, 20, 25];

  void _showResetCatalogDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.restart_alt_rounded, color: Color(0xFF5B2EBC)),
              SizedBox(width: 8),
              Text(
                'Reset Demo Catalog',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF161324),
                ),
              ),
            ],
          ),
          content: const Text(
            'This will reset your catalog to the default sample products (Mouse, Keyboard, Adapter). Any custom products will be replaced.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF524F64),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                widget.onResetDemoCatalog?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Demo catalog restored successfully.'),
                    backgroundColor: const Color(0xFF5B2EBC),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B2EBC),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset Catalog'),
            ),
          ],
        );
      },
    );
  }

  void _showClearHistoryDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text(
                'Clear Movement Logs',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF161324),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to clear all historical stock movement audit logs? This action cannot be undone.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF524F64),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                widget.onClearHistory?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Movement history cleared.'),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear History'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = widget.products
        .where(
          (p) =>
              p.getStockStatus(widget.lowStockThreshold) ==
              StockStatus.lowStock,
        )
        .length;
    final outOfStockCount = widget.products
        .where(
          (p) =>
              p.getStockStatus(widget.lowStockThreshold) ==
              StockStatus.outOfStock,
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      appBar: AppBar(
        titleSpacing: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 12),
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Settings & Rules',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Inventory thresholds & app preferences',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFE5DCFD),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5B2EBC), Color(0xFF431C9A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // 1. Low-Stock Threshold Rule Section
                _buildSectionHeader(
                  icon: Icons.tune_rounded,
                  title: 'Low-Stock Threshold Rule',
                  badgeText: 'Active',
                ),
                const SizedBox(height: 10),
                _buildThresholdCard(
                  lowStockCount: lowStockCount,
                  outOfStockCount: outOfStockCount,
                ),
                const SizedBox(height: 20),

                // 2. Preferences Section
                _buildSectionHeader(
                  icon: Icons.toggle_on_outlined,
                  title: 'Inventory Preferences',
                  badgeText: 'Saved Locally',
                ),
                const SizedBox(height: 10),
                _buildPreferencesCard(),
                const SizedBox(height: 20),

                // 3. Data & Catalog Management
                _buildSectionHeader(
                  icon: Icons.storage_rounded,
                  title: 'Data & Catalog Management',
                  badgeText: 'Actions',
                ),
                const SizedBox(height: 10),
                _buildDataManagementCard(),
                const SizedBox(height: 20),

                // 4. System Diagnostics & Info
                _buildSystemInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String badgeText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF5B2EBC)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF161324),
                letterSpacing: -0.15,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EFFF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5DCFD), width: 1),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5B2EBC),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdCard({
    required int lowStockCount,
    required int outOfStockCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Warning Trigger Limit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF161324),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Quantities at or below this value are Low Stock',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B687E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFDFB5), width: 1),
                ),
                child: Text(
                  '≤ ${widget.lowStockThreshold} units',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Preset Chips Row
          const Text(
            'Quick Preset Selection',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF524F64),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetThresholds.map((preset) {
              final isSelected = widget.lowStockThreshold == preset;
              return ChoiceChip(
                key: Key('settings_preset_$preset'),
                label: Text(
                  '≤ $preset',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF524F64),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF5B2EBC),
                backgroundColor: const Color(0xFFF4F3F8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF5B2EBC)
                        : const Color(0xFFE5E2EE),
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    widget.onThresholdChanged(preset);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Stepper and Modal Dialog Opener
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('settings_threshold_dialog_button'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Open Threshold Dialog'),
                  onPressed: widget.onOpenThresholdDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5B2EBC),
                    side: const BorderSide(color: Color(0xFFD4C8FA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF2F2F6)),
          const SizedBox(height: 10),

          // Live Affected Count Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: Color(0xFF6B687E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live Impact: $lowStockCount low stock, $outOfStockCount out of stock out of ${widget.products.length} products.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF524F64),
                      fontWeight: FontWeight.w500,
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

  Widget _buildPreferencesCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1.1),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text(
                'Confirm Before Deleting',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF161324),
                ),
              ),
              subtitle: const Text(
                'Display a confirmation dialog before permanently removing an item',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B687E)),
              ),
              activeThumbColor: const Color(0xFF5B2EBC),
              activeTrackColor: const Color(0xFFE5DCFD),
              value: _confirmDeletions,
              onChanged: (val) {
                setState(() {
                  _confirmDeletions = val;
                });
              },
            ),
            const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Color(0xFFF2F2F6),
            ),
            SwitchListTile(
              title: const Text(
                'Auto-Record Inflow on Add',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF161324),
                ),
              ),
              subtitle: const Text(
                'Automatically log initial stock in the movement ledger when registering items',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B687E)),
              ),
              activeThumbColor: const Color(0xFF5B2EBC),
              activeTrackColor: const Color(0xFFE5DCFD),
              value: _autoRecordInflows,
              onChanged: (val) {
                setState(() {
                  _autoRecordInflows = val;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catalog Operations',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF161324),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage initial demo products or reset local database state safely.',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B687E)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('reset_catalog_button'),
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('Reset Demo Catalog'),
                  onPressed: _showResetCatalogDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5B2EBC),
                    side: const BorderSide(color: Color(0xFFD4C8FA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('clear_history_button'),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text('Clear History'),
                  onPressed: _showClearHistoryDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFDC5C3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEE), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Color(0xFF5B2EBC),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StockMate Small Business Inventory',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF161324),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Version 1.2.0 • SharedPreferences JSON Storage • Offline Ready',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF6B687E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
