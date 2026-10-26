import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_mate/main.dart';
import 'package:stock_mate/models/product.dart';

void main() {
  group('StockStatus unit tests', () {
    test('Correctly categorizes in stock, low stock, and out of stock based on threshold', () {
      // Documented threshold: kLowStockThreshold = 5
      expect(kLowStockThreshold, 5);

      // Quantities > 5 should be inStock
      expect(StockStatus.fromQuantity(6), StockStatus.inStock);
      expect(StockStatus.fromQuantity(25), StockStatus.inStock);

      // Quantities 1..5 should be lowStock
      expect(StockStatus.fromQuantity(5), StockStatus.lowStock);
      expect(StockStatus.fromQuantity(4), StockStatus.lowStock);
      expect(StockStatus.fromQuantity(1), StockStatus.lowStock);

      // Quantity <= 0 should be outOfStock
      expect(StockStatus.fromQuantity(0), StockStatus.outOfStock);
      expect(StockStatus.fromQuantity(-1), StockStatus.outOfStock);
    });

    test('Status labels are human readable', () {
      expect(StockStatus.inStock.label, 'In Stock');
      expect(StockStatus.lowStock.label, 'Low Stock');
      expect(StockStatus.outOfStock.label, 'Out of Stock');
    });
  });

  group('Widget UI and Navigation tests', () {
    testWidgets('StockMate renders inventory list with 3 sample products', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StockMateApp());

      // Verify branding title
      expect(find.text('StockMate'), findsOneWidget);

      // Verify all 3 sample products are present
      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
      expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);
      expect(find.text('USB-C Multiport Adapter'), findsOneWidget);

      // Verify stock status badges
      // Note: 'Out of Stock' appears in summary tile, filter chip, and product badge (3 times)
      expect(find.text('In Stock'), findsOneWidget);
      expect(find.text('Low Stock (3)'), findsOneWidget);
      expect(find.text('Out of Stock'), findsNWidgets(3));

      // Verify prices are formatted properly
      expect(find.text('\$29.99'), findsOneWidget);
      expect(find.text('\$89.50'), findsOneWidget);
      expect(find.text('\$19.00'), findsOneWidget);
    });

    testWidgets('Search filters products by name in real-time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StockMateApp());

      // Search field is present
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter search query "Mouse"
      await tester.enterText(searchField, 'Mouse');
      await tester.pumpAndSettle();

      // Only Mouse should be visible
      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
      expect(find.text('Mechanical Gaming Keyboard'), findsNothing);
      expect(find.text('USB-C Multiport Adapter'), findsNothing);

      // Clear search query
      final clearButton = find.byIcon(Icons.clear_rounded);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // All 3 products return
      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
      expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);
      expect(find.text('USB-C Multiport Adapter'), findsOneWidget);
    });

    testWidgets('Filter chips filter products by stock status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StockMateApp());

      // Tap on 'Low Stock' filter chip (use the InkWell/Text inside filter row)
      final lowStockChip = find.widgetWithText(InkWell, 'Low Stock').first;
      await tester.tap(lowStockChip);
      await tester.pumpAndSettle();

      // Only the keyboard (qty 3) should remain
      expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);
      expect(find.text('Wireless Ergonomic Mouse'), findsNothing);
      expect(find.text('USB-C Multiport Adapter'), findsNothing);

      // Tap on 'Out of Stock' filter chip
      final outOfStockChip = find.widgetWithText(InkWell, 'Out of Stock').first;
      await tester.tap(outOfStockChip);
      await tester.pumpAndSettle();

      // Only the adapter (qty 0) should remain
      expect(find.text('USB-C Multiport Adapter'), findsOneWidget);
      expect(find.text('Wireless Ergonomic Mouse'), findsNothing);
      expect(find.text('Mechanical Gaming Keyboard'), findsNothing);

      // Tap 'All' filter chip
      final allChip = find.widgetWithText(InkWell, 'All');
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      // All 3 items should be restored
      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
      expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);
      expect(find.text('USB-C Multiport Adapter'), findsOneWidget);
    });

    testWidgets('Empty search shows thoughtful empty state and resets', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StockMateApp());

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Headphones');
      await tester.pumpAndSettle();

      // Empty state visible
      expect(find.text('No Products Found'), findsOneWidget);
      expect(find.text('No items match "Headphones".'), findsOneWidget);

      // Tap 'Reset Filters'
      final resetButton = find.text('Reset Filters');
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Items restored
      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
    });

    testWidgets('Navigates to Add Product screen and back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StockMateApp());

      // Verify FAB is present
      final addFab = find.byTooltip('Add Product');
      expect(addFab, findsOneWidget);

      // Tap the FAB to navigate to Add Product screen
      await tester.tap(addFab);
      await tester.pumpAndSettle();

      // Verify we are on the Add Product screen
      expect(find.text('Add New Product'), findsOneWidget);
      expect(find.text('Product Name'), findsOneWidget);
      expect(find.text('Price (\$)'), findsOneWidget);
      expect(find.text('Quantity in Stock'), findsOneWidget);

      // Scroll to and tap Cancel button to return to Inventory
      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);
      await tester.ensureVisible(cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify we are back on the Inventory screen
      expect(find.text('StockMate'), findsOneWidget);
      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
    });

    testWidgets(
      'Tapping product card navigates to Edit Product screen and Save triggers feedback',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());

        // Tap on the mechanical keyboard product row
        final productCard = find.text('Mechanical Gaming Keyboard');
        expect(productCard, findsOneWidget);
        await tester.tap(productCard);
        await tester.pumpAndSettle();

        // Verify edit product screen is displayed
        expect(find.text('Edit Product'), findsOneWidget);
        expect(find.text('89.50'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);

        // Scroll to and tap Save Product button
        final saveButton = find.text('Update Product');
        expect(saveButton, findsOneWidget);
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Verify returned to Inventory screen with feedback SnackBar
        expect(find.text('StockMate'), findsOneWidget);
        expect(
          find.textContaining('Product form layout ready!'),
          findsOneWidget,
        );
      },
    );
  });
}
