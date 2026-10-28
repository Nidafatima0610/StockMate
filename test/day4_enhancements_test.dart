import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stock_mate/main.dart';
import 'package:stock_mate/models/product.dart';
import 'package:stock_mate/models/stock_movement.dart';
import 'package:stock_mate/screens/inventory_screen.dart';
import 'package:stock_mate/screens/stock_history_screen.dart';
import 'package:stock_mate/services/inventory_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StockMovement Model & Enum Unit Tests', () {
    test('StockMovementType provides human readable labels', () {
      expect(StockMovementType.increase.label, 'Stock In');
      expect(StockMovementType.decrease.label, 'Stock Out');
      expect(StockMovementType.adjustment.label, 'Adjustment');
    });

    test('StockMovement serializes and deserializes accurately with JSON', () {
      final now = DateTime(2026, 10, 27, 12, 0);
      final movement = StockMovement(
        id: 'mov-101',
        productId: 'prod-001',
        productName: 'Ergonomic Mouse',
        previousQuantity: 10,
        newQuantity: 15,
        quantityChanged: 5,
        movementType: StockMovementType.increase,
        timestamp: now,
        note: 'Restock shipment',
      );

      final json = movement.toJson();
      expect(json['id'], 'mov-101');
      expect(json['productId'], 'prod-001');
      expect(json['productName'], 'Ergonomic Mouse');
      expect(json['previousQuantity'], 10);
      expect(json['newQuantity'], 15);
      expect(json['quantityChanged'], 5);
      expect(json['movementType'], 'increase');
      expect(json['timestamp'], now.toIso8601String());
      expect(json['note'], 'Restock shipment');

      final reconstructed = StockMovement.fromJson(json);
      expect(reconstructed, movement);
    });

    test(
      'StockMovement.fromJson handles missing or null fields gracefully',
      () {
        final json = <String, dynamic>{
          'id': 'mov-empty',
          'productId': 'prod-999',
        };

        final movement = StockMovement.fromJson(json);
        expect(movement.id, 'mov-empty');
        expect(movement.productId, 'prod-999');
        expect(movement.productName, 'Unknown Product');
        expect(movement.previousQuantity, 0);
        expect(movement.newQuantity, 0);
        expect(movement.quantityChanged, 0);
        expect(movement.movementType, StockMovementType.adjustment);
        expect(movement.note, isNull);
      },
    );

    test('StockMovement.copyWith preserves unchanged properties', () {
      final movement = StockMovement(
        id: 'mov-1',
        productId: 'prod-1',
        productName: 'Item',
        previousQuantity: 5,
        newQuantity: 8,
        quantityChanged: 3,
        movementType: StockMovementType.increase,
        timestamp: DateTime(2026, 10, 27),
      );

      final modified = movement.copyWith(newQuantity: 10, quantityChanged: 5);
      expect(modified.id, 'mov-1');
      expect(modified.productId, 'prod-1');
      expect(modified.newQuantity, 10);
      expect(modified.quantityChanged, 5);
      expect(modified.previousQuantity, 5);
    });
  });

  group('Configurable Threshold & StockStatus Boundary Logic Tests', () {
    test('Default threshold constant is 5', () {
      expect(kDefaultLowStockThreshold, 5);
      expect(kLowStockThreshold, 5);
    });

    test('Out-of-stock boundary: quantity <= 0 is always Out of Stock across any threshold', () {
      for (final threshold in [0, 1, 5, 10, 25, 50]) {
        expect(
          StockStatus.fromQuantity(0, threshold: threshold),
          StockStatus.outOfStock,
          reason: 'Quantity 0 must be Out of Stock at threshold $threshold',
        );
        expect(
          StockStatus.fromQuantity(-1, threshold: threshold),
          StockStatus.outOfStock,
          reason:
              'Negative quantity must be Out of Stock at threshold $threshold',
        );
        expect(
          StockStatus.fromQuantity(-10, threshold: threshold),
          StockStatus.outOfStock,
        );
      }
    });

    test(
      'Low-stock boundary: quantity between 1 and threshold is Low Stock',
      () {
        // Threshold = 5
        expect(StockStatus.fromQuantity(1, threshold: 5), StockStatus.lowStock);
        expect(StockStatus.fromQuantity(3, threshold: 5), StockStatus.lowStock);
        expect(StockStatus.fromQuantity(5, threshold: 5), StockStatus.lowStock);

        // Threshold = 10
        expect(
          StockStatus.fromQuantity(6, threshold: 10),
          StockStatus.lowStock,
        );
        expect(
          StockStatus.fromQuantity(10, threshold: 10),
          StockStatus.lowStock,
        );

        // Threshold = 1
        expect(StockStatus.fromQuantity(1, threshold: 1), StockStatus.lowStock);
        expect(StockStatus.fromQuantity(2, threshold: 1), StockStatus.inStock);
      },
    );

    test(
      'In-stock boundary: quantity strictly greater than threshold is In Stock',
      () {
        expect(StockStatus.fromQuantity(6, threshold: 5), StockStatus.inStock);
        expect(StockStatus.fromQuantity(24, threshold: 5), StockStatus.inStock);
        expect(
          StockStatus.fromQuantity(11, threshold: 10),
          StockStatus.inStock,
        );
        expect(StockStatus.fromQuantity(2, threshold: 1), StockStatus.inStock);
      },
    );

    test('Zero threshold edge case: threshold = 0 has 0 as Out of Stock and >=1 as In Stock', () {
      expect(StockStatus.fromQuantity(0, threshold: 0), StockStatus.outOfStock);
      expect(StockStatus.fromQuantity(1, threshold: 0), StockStatus.inStock);
      expect(StockStatus.fromQuantity(5, threshold: 0), StockStatus.inStock);
    });

    test(
      'Product.getStockStatus evaluates according to specified threshold',
      () {
        const product = Product(
          id: 'p-eval',
          name: 'Evaluation Item',
          price: 15.0,
          quantity: 8,
        );

        // At threshold 5 (default), quantity 8 is In Stock
        expect(product.stockStatus, StockStatus.inStock);
        expect(product.getStockStatus(5), StockStatus.inStock);

        // At threshold 10, quantity 8 is Low Stock
        expect(product.getStockStatus(10), StockStatus.lowStock);

        // At threshold 8 (boundary equality), quantity 8 is Low Stock
        expect(product.getStockStatus(8), StockStatus.lowStock);

        // At threshold 7, quantity 8 is In Stock
        expect(product.getStockStatus(7), StockStatus.inStock);
      },
    );
  });

  group('InventoryStorage Persistence for Movements and Threshold', () {
    test('Saves and loads movement history sorted newest first', () async {
      SharedPreferences.setMockInitialValues({});
      const storage = InventoryStorage();

      final first = StockMovement(
        id: 'mov-first',
        productId: 'p-1',
        productName: 'Item 1',
        previousQuantity: 10,
        newQuantity: 12,
        quantityChanged: 2,
        movementType: StockMovementType.increase,
        timestamp: DateTime(2026, 10, 27, 10, 0),
      );

      final second = StockMovement(
        id: 'mov-second',
        productId: 'p-1',
        productName: 'Item 1',
        previousQuantity: 12,
        newQuantity: 11,
        quantityChanged: 1,
        movementType: StockMovementType.decrease,
        timestamp: DateTime(2026, 10, 27, 11, 0),
      );

      // Save list (order doesn't matter; load will sort newest first)
      await storage.saveMovements([first, second]);
      final loaded = await storage.loadMovements();

      expect(loaded.length, 2);
      expect(loaded.first.id, 'mov-second');
      expect(loaded.last.id, 'mov-first');
    });

    test('Saves and loads user-configured low stock threshold', () async {
      SharedPreferences.setMockInitialValues({});
      const storage = InventoryStorage();

      // Initially loads default
      final initialThreshold = await storage.loadLowStockThreshold();
      expect(initialThreshold, 5);

      // Persist custom threshold
      await storage.saveLowStockThreshold(12);
      final reloaded = await storage.loadLowStockThreshold();
      expect(reloaded, 12);
    });

    test('Storage clear cleans movements and threshold keys', () async {
      SharedPreferences.setMockInitialValues({});
      const storage = InventoryStorage();

      await storage.saveLowStockThreshold(15);
      await storage.saveMovements([
        StockMovement(
          id: 'm-1',
          productId: 'p-1',
          productName: 'Item',
          previousQuantity: 1,
          newQuantity: 2,
          quantityChanged: 1,
          movementType: StockMovementType.increase,
          timestamp: DateTime.now(),
        ),
      ]);

      await storage.clear();

      final movements = await storage.loadMovements();
      final threshold = await storage.loadLowStockThreshold();

      expect(movements, isEmpty);
      expect(threshold, 5); // default fallback
    });
  });

  group('Day 4 Widget Tests — Movement History & History Screen', () {
    testWidgets('History button in header navigates to StockHistoryScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StockMateApp());
      await tester.pumpAndSettle();

      final historyBtn = find.byKey(const Key('history_button'));
      expect(historyBtn, findsOneWidget);

      await tester.tap(historyBtn);
      await tester.pumpAndSettle();

      // We should now be on the Stock Movement History screen
      expect(find.text('Stock Movement History'), findsOneWidget);
      expect(find.byType(StockHistoryScreen), findsOneWidget);

      // Initially, no movements have occurred yet
      expect(find.text('No Stock Movements Found'), findsOneWidget);

      // Back navigation returns to inventory
      final backBtn = find.byKey(const Key('history_back_button'));
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(InventoryScreen), findsOneWidget);
    });

    testWidgets('Quick quantity increment (+) logs Stock In movement', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const StockMateApp());
      await tester.pumpAndSettle();

      // Wireless Ergonomic Mouse has initial quantity 24
      final incrementBtn = find.byKey(const Key('increment_qty_prod-001'));
      expect(incrementBtn, findsOneWidget);
      await tester.ensureVisible(incrementBtn);
      await tester.pumpAndSettle();
      await tester.tap(incrementBtn);
      await tester.pumpAndSettle();

      // Quantity is now 25
      expect(find.text('Qty: 25'), findsOneWidget);

      // Navigate to History Screen
      await tester.tap(find.byKey(const Key('history_button')));
      await tester.pumpAndSettle();

      // Movement entry should be visible
      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('24'), findsOneWidget); // previous
      expect(find.text('25'), findsOneWidget); // new
      expect(find.text('1 logs'), findsOneWidget);
    });

    testWidgets('Quick quantity decrement (-) logs Stock Out movement', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const StockMateApp());
      await tester.pumpAndSettle();

      // Mechanical Gaming Keyboard has initial quantity 3
      final decrementBtn = find.byKey(const Key('decrement_qty_prod-002'));
      expect(decrementBtn, findsOneWidget);
      await tester.ensureVisible(decrementBtn);
      await tester.pumpAndSettle();
      await tester.tap(decrementBtn);
      await tester.pumpAndSettle();

      // Quantity is now 2
      expect(find.text('Qty: 2'), findsOneWidget);

      // Navigate to History Screen
      await tester.tap(find.byKey(const Key('history_button')));
      await tester.pumpAndSettle();

      expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);
      expect(find.text('-1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // previous
      expect(find.text('2'), findsOneWidget); // new
    });

    testWidgets(
      'Decrementing out-of-stock item (0 quantity) does not log any movement',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // USB-C Multiport Adapter has initial quantity 0
        final decrementBtn = find.byKey(const Key('decrement_qty_prod-003'));
        expect(decrementBtn, findsOneWidget);
        await tester.ensureVisible(decrementBtn);
        await tester.pumpAndSettle();
        await tester.tap(decrementBtn);
        await tester.pumpAndSettle();

        // Quantity stays 0
        expect(find.text('Qty: 0'), findsOneWidget);

        // Navigate to History Screen - must be empty!
        await tester.tap(find.byKey(const Key('history_button')));
        await tester.pumpAndSettle();

        expect(find.text('No Stock Movements Found'), findsOneWidget);
        expect(find.text('0 logs'), findsOneWidget);
      },
    );

    testWidgets(
      'Deleted product records remain readable with "Deleted" indicator in History',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // 1. Increment Mechanical Keyboard to generate a movement log
        final incrementBtn = find.byKey(const Key('increment_qty_prod-002'));
        await tester.ensureVisible(incrementBtn);
        await tester.pumpAndSettle();
        await tester.tap(incrementBtn);
        await tester.pumpAndSettle();

        // 2. Delete Mechanical Keyboard
        final deleteBtn = find.byKey(const Key('delete_product_prod-002'));
        await tester.ensureVisible(deleteBtn);
        await tester.pumpAndSettle();
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Confirm Delete dialog
        final confirmDelete = find.widgetWithText(ElevatedButton, 'Delete');
        await tester.tap(confirmDelete);
        await tester.pumpAndSettle();

        // Product removed from active catalog
        expect(find.text('Mechanical Gaming Keyboard'), findsNothing);

        // 3. Open Stock Movement History
        await tester.tap(find.byKey(const Key('history_button')));
        await tester.pumpAndSettle();

        // Historical record still readable with "Deleted" chip!
        expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);
        expect(find.text('#prod-002'), findsOneWidget);
        expect(find.text('Deleted'), findsOneWidget);
        expect(find.text('+1'), findsOneWidget);
      },
    );

    testWidgets('History screen filters by Stock In and Stock Out', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const StockMateApp());
      await tester.pumpAndSettle();

      // Produce 1 Stock In (Mouse +1) and 1 Stock Out (Keyboard -1)
      final incMouse = find.byKey(const Key('increment_qty_prod-001'));
      await tester.ensureVisible(incMouse);
      await tester.pumpAndSettle();
      await tester.tap(incMouse);
      await tester.pumpAndSettle();

      final decKb = find.byKey(const Key('decrement_qty_prod-002'));
      await tester.ensureVisible(decKb);
      await tester.pumpAndSettle();
      await tester.tap(decKb);
      await tester.pumpAndSettle();

      // Open History
      await tester.tap(find.byKey(const Key('history_button')));
      await tester.pumpAndSettle();

      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
      expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);

      // Filter by Stock In
      await tester.tap(find.byKey(const Key('history_filter_increase')));
      await tester.pumpAndSettle();

      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
      expect(find.text('Mechanical Gaming Keyboard'), findsNothing);

      // Filter by Stock Out
      await tester.tap(find.byKey(const Key('history_filter_decrease')));
      await tester.pumpAndSettle();

      expect(find.text('Wireless Ergonomic Mouse'), findsNothing);
      expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);

      // Reset to All
      await tester.tap(find.byKey(const Key('history_filter_all')));
      await tester.pumpAndSettle();

      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
      expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);
    });
  });

  group('Day 4 Widget Tests — Configurable Low-Stock Threshold', () {
    testWidgets('Threshold setting dialog opens from pill button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StockMateApp());
      await tester.pumpAndSettle();

      // Check initial threshold pill
      final thresholdPill = find.byKey(const Key('threshold_settings_button'));
      expect(thresholdPill, findsOneWidget);
      expect(find.text('Threshold: ≤ 5'), findsOneWidget);

      // Tap to open dialog
      await tester.tap(thresholdPill);
      await tester.pumpAndSettle();

      expect(find.text('Low-Stock Threshold'), findsOneWidget);
      expect(find.byKey(const Key('dialog_threshold_value')), findsOneWidget);
      expect(find.text('5'), findsWidgets);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Low-Stock Threshold'), findsNothing);
      expect(find.text('Threshold: ≤ 5'), findsOneWidget);
    });

    testWidgets(
      'Changing threshold via preset chip immediately updates counts and badges',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Initially (threshold 5):
        // - Mouse: 24 (In Stock)
        // - Keyboard: 3 (Low Stock)
        // - USB-C Adapter: 0 (Out of Stock)
        expect(find.text('Low Stock (3)'), findsOneWidget);
        expect(find.text('In Stock'), findsOneWidget);
        expect(find.text('Out of Stock'), findsWidgets);

        // Open Threshold Dialog
        await tester.tap(find.byKey(const Key('threshold_settings_button')));
        await tester.pumpAndSettle();

        // If we change threshold to ≤ 2:
        // Keyboard qty is 3, so with threshold 2, Keyboard becomes "In Stock"!
        // Low stock count becomes 0!
        final preset2 = find.byKey(const Key('threshold_preset_2'));
        await tester.tap(preset2);
        await tester.pumpAndSettle();

        // Save threshold
        await tester.tap(find.byKey(const Key('save_threshold_button')));
        await tester.pumpAndSettle();

        // Verify immediate updates:
        expect(find.text('Threshold: ≤ 2'), findsOneWidget);
        // Low stock count is now 0 (Keyboard with qty 3 is > 2, so In Stock!)
        expect(find.text('Low Stock (3)'), findsNothing);
        expect(find.text('Low-stock threshold updated to ≤ 2'), findsOneWidget);
      },
    );

    testWidgets(
      'Raising threshold to 25 makes Mouse (qty 24) Low Stock immediately',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Open Threshold Dialog
        await tester.tap(find.byKey(const Key('threshold_settings_button')));
        await tester.pumpAndSettle();

        // Select preset 20 and step up to 25
        final preset20 = find.byKey(const Key('threshold_preset_20'));
        await tester.tap(preset20);
        await tester.pumpAndSettle();

        final incrementBtn = find.byKey(
          const Key('threshold_increment_button'),
        );
        for (int i = 0; i < 5; i++) {
          await tester.tap(incrementBtn);
          await tester.pumpAndSettle();
        }

        expect(find.text('25'), findsWidgets);

        // Save threshold
        await tester.tap(find.byKey(const Key('save_threshold_button')));
        await tester.pumpAndSettle();

        // Dashboard now has threshold ≤ 25
        expect(find.text('Threshold: ≤ 25'), findsOneWidget);

        // Both Mouse (24) and Keyboard (3) are now Low Stock!
        expect(find.text('Low Stock (24)'), findsOneWidget);
        expect(find.text('Low Stock (3)'), findsOneWidget);

        // USB-C Adapter (0) is STILL Out of Stock (distinct from Low Stock!)
        expect(find.text('Out of Stock'), findsWidgets);
      },
    );

    testWidgets('Threshold update is persisted across screen reloads', (
      WidgetTester tester,
    ) async {
      final storage = const InventoryStorage();
      await storage.saveLowStockThreshold(15);

      await tester.pumpWidget(StockMateApp());
      await tester.pumpAndSettle();

      expect(find.text('Threshold: ≤ 15'), findsOneWidget);
    });
  });
}
