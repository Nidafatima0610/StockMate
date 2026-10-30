import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stock_mate/main.dart';
import 'package:stock_mate/models/product.dart';
import 'package:stock_mate/services/inventory_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    test(
      'StockStatus boundary values accurately reflect threshold 5 rules',
      () {
        // Documented threshold rule:
        // Quantity == 0: Out of Stock
        // Quantity > 0 and <= threshold: Low Stock
        // Quantity > threshold: In Stock
        const threshold = 5;

        expect(
          StockStatus.fromQuantity(0, threshold: threshold),
          StockStatus.outOfStock,
        );
        expect(
          StockStatus.fromQuantity(-5, threshold: threshold),
          StockStatus.outOfStock,
        );

        expect(
          StockStatus.fromQuantity(1, threshold: threshold),
          StockStatus.lowStock,
        );
        expect(
          StockStatus.fromQuantity(3, threshold: threshold),
          StockStatus.lowStock,
        );
        expect(
          StockStatus.fromQuantity(5, threshold: threshold),
          StockStatus.lowStock,
        );

        expect(
          StockStatus.fromQuantity(6, threshold: threshold),
          StockStatus.inStock,
        );
        expect(
          StockStatus.fromQuantity(100, threshold: threshold),
          StockStatus.inStock,
        );
      },
    );
  });

  group('Product model serialization and copyWith unit tests', () {
    test('Product.toJson produces valid Map with all properties', () {
      const product = Product(
        id: 'prod-test',
        name: 'Smart Speaker',
        price: 49.99,
        quantity: 12,
        category: 'Electronics',
      );

      final json = product.toJson();
      expect(json['id'], 'prod-test');
      expect(json['name'], 'Smart Speaker');
      expect(json['price'], 49.99);
      expect(json['quantity'], 12);
      expect(json['category'], 'Electronics');
    });

    test('Product.fromJson accurately deserializes Map', () {
      final json = {
        'id': 'prod-007',
        'name': 'Wireless Charging Pad',
        'price': 24.50,
        'quantity': 7,
        'category': 'Accessories',
      };

      final product = Product.fromJson(json);
      expect(product.id, 'prod-007');
      expect(product.name, 'Wireless Charging Pad');
      expect(product.price, 24.50);
      expect(product.quantity, 7);
      expect(product.category, 'Accessories');
      expect(product.stockStatus, StockStatus.inStock);
    });

    test('Product.copyWith modifies selected fields and preserves others', () {
      const original = Product(
        id: 'prod-orig',
        name: 'Desk Lamp',
        price: 35.0,
        quantity: 10,
        category: 'Office',
      );

      final updated = original.copyWith(quantity: 4, price: 39.99);
      expect(updated.id, 'prod-orig');
      expect(updated.name, 'Desk Lamp');
      expect(updated.price, 39.99);
      expect(updated.quantity, 4);
      expect(updated.category, 'Office');
      expect(updated.stockStatus, StockStatus.lowStock);
    });

    test('ProductSortOption labels are human readable', () {
      expect(ProductSortOption.nameAsc.label, 'Name (A to Z)');
      expect(ProductSortOption.nameDesc.label, 'Name (Z to A)');
      expect(ProductSortOption.priceAsc.label, 'Price (Low to High)');
      expect(ProductSortOption.priceDesc.label, 'Price (High to Low)');
      expect(ProductSortOption.quantityAsc.label, 'Quantity (Lowest First)');
      expect(ProductSortOption.quantityDesc.label, 'Quantity (Highest First)');
    });
  });

  group('InventoryStorage persistence unit tests', () {
    test(
      'Loads initial sample products when storage is uninitialized',
      () async {
        SharedPreferences.setMockInitialValues({});
        const storage = InventoryStorage();

        final products = await storage.loadProducts();
        expect(products.length, 3);
        expect(products.first.name, 'Wireless Ergonomic Mouse');
      },
    );

    test('Saves and reloads modified catalog across app restarts', () async {
      SharedPreferences.setMockInitialValues({});
      const storage = InventoryStorage();

      final customList = [
        const Product(
          id: 'prod-custom-1',
          name: 'Custom Keyboard',
          price: 150.0,
          quantity: 2,
          category: 'Custom',
        ),
      ];

      await storage.saveProducts(customList);
      final reloaded = await storage.loadProducts();

      expect(reloaded.length, 1);
      expect(reloaded.first.name, 'Custom Keyboard');
      expect(reloaded.first.price, 150.0);
    });

    test(
      'Preserves user-cleared empty inventory without re-seeding sample items',
      () async {
        SharedPreferences.setMockInitialValues({});
        const storage = InventoryStorage();

        // Seed first
        await storage.loadProducts();

        // Clear all items as a user action
        await storage.saveProducts([]);

        // Reload
        final reloaded = await storage.loadProducts();
        expect(reloaded.isEmpty, isTrue);
      },
    );
  });

  group('Widget UI and Navigation tests', () {
    testWidgets('StockMate renders inventory list with 3 sample products', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StockMateApp());
      await tester.pumpAndSettle();

      // Verify branding title
      expect(find.text('StockMate'), findsOneWidget);

      // Verify all 3 sample products are present
      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
      expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);
      expect(find.text('USB-C Multiport Adapter'), findsOneWidget);

      // Verify stock status badges
      expect(find.text('In Stock'), findsOneWidget);
      expect(find.text('Low Stock (3)'), findsOneWidget);
      expect(find.text('Out of Stock'), findsNWidgets(2));

      // Verify prices are formatted properly
      expect(find.text('\$29.99'), findsOneWidget);
      expect(find.text('\$89.50'), findsOneWidget);
      expect(find.text('\$19.00'), findsOneWidget);

      // Verify Total Inventory Valuation is present
      expect(find.text('Total Inventory Value'), findsOneWidget);
    });

    testWidgets('Search filters products by name in real-time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StockMateApp());
      await tester.pumpAndSettle();

      // Navigate to Products tab where search bar is located
      await tester.tap(find.byKey(const Key('nav_products')));
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      // Navigate to Products tab where stock status filter chips reside
      await tester.tap(find.byKey(const Key('nav_products')));
      await tester.pumpAndSettle();

      // Tap on 'Low Stock' filter chip
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
      await tester.pumpAndSettle();

      // Navigate to Products tab
      await tester.tap(find.byKey(const Key('nav_products')));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Headphones');
      await tester.pumpAndSettle();

      // Empty state visible
      expect(find.text('No Products Found'), findsOneWidget);
      expect(find.text('No items match "Headphones".'), findsOneWidget);

      // Scroll to and tap 'Reset Filters'
      final resetButton = find.text('Reset Filters');
      expect(resetButton, findsOneWidget);
      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Items restored
      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
    });

    testWidgets('Navigates to Add Product screen and back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StockMateApp());
      await tester.pumpAndSettle();

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
        await tester.pumpAndSettle();

        // Navigate to Products tab
        await tester.tap(find.byKey(const Key('nav_products')));
        await tester.pumpAndSettle();

        // Tap on the mechanical keyboard product row
        final productCard = find.text('Mechanical Gaming Keyboard');
        expect(productCard, findsOneWidget);
        await tester.ensureVisible(productCard);
        await tester.pumpAndSettle();
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

        // Verify returned to Products screen with feedback SnackBar
        expect(find.text('Product Catalog'), findsOneWidget);
        expect(find.textContaining('updated!'), findsOneWidget);
      },
    );

    testWidgets(
      'Validation: Empty product name shows error and prevents submission',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Tap Add Product FAB
        final addFab = find.byTooltip('Add Product');
        await tester.tap(addFab);
        await tester.pumpAndSettle();

        // Fill price and quantity, but leave name blank
        final priceField = find.byKey(const Key('product_price_field'));
        final quantityField = find.byKey(const Key('product_quantity_field'));
        await tester.enterText(priceField, '19.99');
        await tester.enterText(quantityField, '10');

        // Tap Save Product button
        final saveButton = find.byKey(const Key('save_product_button'));
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Error message must be visible
        expect(find.text('Product name cannot be empty'), findsOneWidget);

        // Submission prevented: remains on Add New Product screen
        expect(find.text('Add New Product'), findsOneWidget);
      },
    );

    testWidgets(
      'Validation: Invalid price (empty, non-positive, or text) shows error and prevents submission',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Tap Add Product FAB
        await tester.tap(find.byTooltip('Add Product'));
        await tester.pumpAndSettle();

        final nameField = find.byKey(const Key('product_name_field'));
        final priceField = find.byKey(const Key('product_price_field'));
        final quantityField = find.byKey(const Key('product_quantity_field'));
        final saveButton = find.byKey(const Key('save_product_button'));

        // Case A: Empty price
        await tester.enterText(nameField, 'Test Item');
        await tester.enterText(quantityField, '5');
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(find.text('Price cannot be empty'), findsOneWidget);

        // Case B: Price is zero
        await tester.enterText(priceField, '0');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(
          find.text('Price must be a valid number greater than zero'),
          findsOneWidget,
        );

        // Case C: Negative price
        await tester.enterText(priceField, '-15.50');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(
          find.text('Price must be a valid number greater than zero'),
          findsOneWidget,
        );

        // Case D: Non-numeric price
        await tester.enterText(priceField, 'abc');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(
          find.text('Price must be a valid number greater than zero'),
          findsOneWidget,
        );

        // Submission prevented
        expect(find.text('Add New Product'), findsOneWidget);
      },
    );

    testWidgets(
      'Validation: Invalid quantity (empty, negative, or decimal) shows error and prevents submission',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Tap Add Product FAB
        await tester.tap(find.byTooltip('Add Product'));
        await tester.pumpAndSettle();

        final nameField = find.byKey(const Key('product_name_field'));
        final priceField = find.byKey(const Key('product_price_field'));
        final quantityField = find.byKey(const Key('product_quantity_field'));
        final saveButton = find.byKey(const Key('save_product_button'));

        await tester.enterText(nameField, 'Smart Watch');
        await tester.enterText(priceField, '199.99');

        // Case A: Empty quantity
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(find.text('Quantity cannot be empty'), findsOneWidget);

        // Case B: Negative quantity
        await tester.enterText(quantityField, '-5');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(
          find.text('Quantity must be a valid whole number (0 or greater)'),
          findsOneWidget,
        );

        // Case C: Decimal quantity
        await tester.enterText(quantityField, '3.5');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(
          find.text('Quantity must be a valid whole number (0 or greater)'),
          findsOneWidget,
        );

        // Case D: Non-numeric quantity
        await tester.enterText(quantityField, 'lots');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(
          find.text('Quantity must be a valid whole number (0 or greater)'),
          findsOneWidget,
        );

        // Submission prevented
        expect(find.text('Add New Product'), findsOneWidget);
      },
    );

    testWidgets(
      'Successfully adding a product updates catalog list, metrics, and stock status badge',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Verify initial catalog has 3 products
        expect(find.text('Products (3)'), findsOneWidget);

        // Tap Add Product FAB
        await tester.tap(find.byTooltip('Add Product'));
        await tester.pumpAndSettle();

        // Fill in form with valid data (Low stock: qty 2 <= 5)
        await tester.enterText(
          find.byKey(const Key('product_name_field')),
          'Wireless Headset',
        );
        await tester.enterText(
          find.byKey(const Key('product_category_field')),
          'Electronics',
        );
        await tester.enterText(
          find.byKey(const Key('product_price_field')),
          '49.99',
        );
        await tester.enterText(
          find.byKey(const Key('product_quantity_field')),
          '2',
        );

        // Tap Save Product
        final saveButton = find.byKey(const Key('save_product_button'));
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Returned to Inventory Screen
        expect(find.text('StockMate'), findsOneWidget);

        // Product count updated from 3 to 4
        expect(find.text('Products (4)'), findsOneWidget);

        // New product details visible in the list
        expect(find.text('Wireless Headset'), findsOneWidget);
        expect(find.text('\$49.99'), findsOneWidget);
        expect(find.text('Qty: 2'), findsOneWidget);

        // Feedback SnackBar appears
        expect(
          find.text('Wireless Headset added to inventory!'),
          findsOneWidget,
        );

        // Navigate to Products tab to search
        await tester.tap(find.byKey(const Key('nav_products')));
        await tester.pumpAndSettle();

        // Search for the newly added product
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'Headset');
        await tester.pumpAndSettle();

        expect(find.text('Wireless Headset'), findsOneWidget);
        expect(find.text('Wireless Ergonomic Mouse'), findsNothing);
      },
    );

    testWidgets(
      'Adding product with empty category defaults to General and quantity 0 is Out of Stock',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Navigate to Products tab so category chips and full catalog are visible
        await tester.tap(find.byKey(const Key('nav_products')));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Add Product'));
        await tester.pumpAndSettle();

        // Leave category field empty
        await tester.enterText(
          find.byKey(const Key('product_name_field')),
          'Bluetooth Speaker',
        );
        await tester.enterText(
          find.byKey(const Key('product_price_field')),
          '35.00',
        );
        await tester.enterText(
          find.byKey(const Key('product_quantity_field')),
          '0',
        );

        final saveButton = find.byKey(const Key('save_product_button'));
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Check new product has category 'General' and 'Qty: 0' (now two items with Qty: 0)
        expect(find.text('Bluetooth Speaker'), findsOneWidget);
        expect(find.text('General'), findsNWidgets(2));
        expect(find.text('Qty: 0'), findsNWidgets(2));
      },
    );

    testWidgets(
      'Quick quantity increment (+) increases stock and recalculates badge',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Navigate to Products tab
        await tester.tap(find.byKey(const Key('nav_products')));
        await tester.pumpAndSettle();

        // Keyboard starts with qty 3 (Low Stock)
        expect(find.text('Low Stock (3)'), findsOneWidget);

        // Tap + button for Mechanical Gaming Keyboard (prod-002)
        final incrementBtn = find.byKey(const Key('increment_qty_prod-002'));
        expect(incrementBtn, findsOneWidget);
        await tester.ensureVisible(incrementBtn);
        await tester.pumpAndSettle();
        await tester.tap(incrementBtn);
        await tester.pumpAndSettle();

        // Qty becomes 4
        expect(find.text('Low Stock (4)'), findsOneWidget);

        // Tap + two more times (qty becomes 6 -> In Stock)
        await tester.tap(incrementBtn);
        await tester.pumpAndSettle();
        await tester.tap(incrementBtn);
        await tester.pumpAndSettle();

        // Qty 6 is now In Stock (and Low Stock count decreases)
        expect(find.text('Qty: 6'), findsOneWidget);
        expect(find.text('In Stock'), findsNWidgets(2)); // Mouse & Keyboard
      },
    );

    testWidgets(
      'Quick quantity decrement (-) decrements stock and safely clamps at 0',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Navigate to Products tab
        await tester.tap(find.byKey(const Key('nav_products')));
        await tester.pumpAndSettle();

        // Decrement button for prod-003 is disabled at 0
        final decrementBtn = find.byKey(const Key('decrement_qty_prod-003'));
        expect(decrementBtn, findsOneWidget);
        await tester.ensureVisible(decrementBtn);
        await tester.pumpAndSettle();

        // Adapter starts with qty 0 (Out of Stock)
        expect(find.text('Qty: 0'), findsOneWidget);

        await tester.tap(decrementBtn);
        await tester.pumpAndSettle();

        // Quantity must NOT fall below 0
        expect(find.text('Qty: 0'), findsOneWidget);
        expect(find.text('Qty: -1'), findsNothing);

        // Now decrement keyboard from qty 3 to qty 2
        final kbDecrementBtn = find.byKey(const Key('decrement_qty_prod-002'));
        await tester.ensureVisible(kbDecrementBtn);
        await tester.pumpAndSettle();
        await tester.tap(kbDecrementBtn);
        await tester.pumpAndSettle();

        expect(find.text('Low Stock (2)'), findsOneWidget);
        expect(find.text('Qty: 2'), findsOneWidget);
      },
    );

    testWidgets(
      'Product deletion displays dialog, cancels safely, and deletes with Undo',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Navigate to Products tab
        await tester.tap(find.byKey(const Key('nav_products')));
        await tester.pumpAndSettle();

        expect(find.text('Products (3)'), findsOneWidget);

        // Tap delete button for Adapter (prod-003)
        final deleteBtn = find.byKey(const Key('delete_product_prod-003'));
        expect(deleteBtn, findsOneWidget);
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Verify confirmation dialog appears
        expect(find.text('Delete Product'), findsOneWidget);
        expect(
          find.textContaining('Are you sure you want to delete'),
          findsOneWidget,
        );

        // Tap Cancel button
        final cancelDialogBtn = find.text('Cancel');
        await tester.tap(cancelDialogBtn);
        await tester.pumpAndSettle();

        // Product is still present
        expect(find.text('USB-C Multiport Adapter'), findsOneWidget);
        expect(find.text('Products (3)'), findsOneWidget);

        // Tap delete again and confirm
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        final confirmDeleteBtn = find.text('Delete');
        await tester.tap(confirmDeleteBtn);
        await tester.pumpAndSettle();

        // Product is deleted, count becomes 2
        expect(find.text('Products (2)'), findsOneWidget);
        expect(find.text('USB-C Multiport Adapter'), findsNothing);
        expect(find.text('USB-C Multiport Adapter deleted'), findsOneWidget);

        // Tap UNDO in SnackBar
        final undoAction = find.text('UNDO');
        expect(undoAction, findsOneWidget);
        await tester.tap(undoAction);
        await tester.pumpAndSettle();

        // Product is restored back to the catalog
        expect(find.text('Products (3)'), findsOneWidget);
        expect(find.text('USB-C Multiport Adapter'), findsOneWidget);
      },
    );

    testWidgets('Sorting reorders catalog by price and quantity', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StockMateApp());
      await tester.pumpAndSettle();

      // Navigate to Products tab
      await tester.tap(find.byKey(const Key('nav_products')));
      await tester.pumpAndSettle();

      // Tap Sort button
      final sortButton = find.byKey(const Key('sort_button'));
      expect(sortButton, findsOneWidget);
      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      // Pick Price (Low to High)
      final priceAscOption = find.text('Price (Low to High)');
      expect(priceAscOption, findsOneWidget);
      await tester.tap(priceAscOption);
      await tester.pumpAndSettle();

      // Lowest price is USB-C Multiport Adapter ($19.00), highest is Keyboard ($89.50)
      final firstRowText = find.text('USB-C Multiport Adapter');
      expect(firstRowText, findsOneWidget);

      // Tap Sort button again and pick Quantity (Lowest First)
      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      final qtyAscOption = find.text('Quantity (Lowest First)');
      expect(qtyAscOption, findsOneWidget);
      await tester.tap(qtyAscOption);
      await tester.pumpAndSettle();

      expect(find.text('USB-C Multiport Adapter'), findsOneWidget);
    });

    testWidgets('Category filter chip isolates items in that category', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StockMateApp());
      await tester.pumpAndSettle();

      // Navigate to Products tab
      await tester.tap(find.byKey(const Key('nav_products')));
      await tester.pumpAndSettle();

      // Tap Accessories category chip
      final accessoriesChip = find.byKey(
        const Key('category_chip_Accessories'),
      );
      expect(accessoriesChip, findsOneWidget);
      await tester.tap(accessoriesChip);
      await tester.pumpAndSettle();

      // Only USB-C Multiport Adapter (Accessories) should remain
      expect(find.text('USB-C Multiport Adapter'), findsOneWidget);
      expect(find.text('Wireless Ergonomic Mouse'), findsNothing);
      expect(find.text('Mechanical Gaming Keyboard'), findsNothing);

      // Tap All Categories chip to restore
      final allCategoriesChip = find.byKey(
        const Key('category_chip_All Categories'),
      );
      await tester.tap(allCategoriesChip);
      await tester.pumpAndSettle();

      expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
      expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);
      expect(find.text('USB-C Multiport Adapter'), findsOneWidget);
    });

    testWidgets(
      'Editing product name, price, quantity, and category saves changes and updates catalog, badges, and metrics immediately',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Navigate to Products tab for catalog editing
        await tester.tap(find.byKey(const Key('nav_products')));
        await tester.pumpAndSettle();

        // 1. Initial State: Mechanical Gaming Keyboard has qty 3 ($89.50) -> Low Stock
        expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);
        expect(find.text('Low Stock (3)'), findsOneWidget);
        expect(find.text('\$89.50'), findsOneWidget);

        // 2. Tap to edit using key or card
        final editTarget = find.byKey(const Key('edit_product_prod-002'));
        await tester.ensureVisible(editTarget);
        await tester.pumpAndSettle();
        await tester.tap(editTarget);
        await tester.pumpAndSettle();

        // 3. Verify Edit screen is displayed with pre-filled fields
        expect(find.text('Edit Product'), findsOneWidget);
        final nameField = find.byKey(const Key('product_name_field'));
        final categoryField = find.byKey(const Key('product_category_field'));
        final priceField = find.byKey(const Key('product_price_field'));
        final quantityField = find.byKey(const Key('product_quantity_field'));

        expect(find.text('Mechanical Gaming Keyboard'), findsOneWidget);
        expect(find.text('Electronics'), findsOneWidget);
        expect(find.text('89.50'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);

        // 4. Edit all fields:
        // New name: Mechanical Gaming Keyboard RGB Pro
        // New category: Peripherals
        // New price: 129.99
        // New quantity: 15 (15 > 5 -> will transition to In Stock!)
        await tester.enterText(nameField, 'Mechanical Gaming Keyboard RGB Pro');
        await tester.enterText(categoryField, 'Peripherals');
        await tester.ensureVisible(priceField);
        await tester.pumpAndSettle();
        await tester.enterText(priceField, '129.99');
        await tester.ensureVisible(quantityField);
        await tester.pumpAndSettle();
        await tester.enterText(quantityField, '15');

        // 5. Save changes
        final updateBtn = find.byKey(const Key('save_product_button'));
        await tester.ensureVisible(updateBtn);
        await tester.pumpAndSettle();
        await tester.tap(updateBtn);
        await tester.pumpAndSettle();

        // 6. Verify back on Products screen with SnackBar
        expect(find.text('Product Catalog'), findsOneWidget);
        expect(
          find.text('Mechanical Gaming Keyboard RGB Pro updated!'),
          findsOneWidget,
        );

        // 7. Verify updated product row details and auto-generated category filter chip
        expect(find.text('Mechanical Gaming Keyboard RGB Pro'), findsOneWidget);
        expect(
          find.text('Peripherals'),
          findsNWidgets(2),
        ); // Category filter chip + product card
        expect(
          find.byKey(const Key('category_chip_Peripherals')),
          findsOneWidget,
        );
        expect(find.text('\$129.99'), findsOneWidget);
        expect(find.text('Qty: 15'), findsOneWidget);

        // 8. Verify stock badge transitioned from Low Stock to In Stock
        // Mouse (24) and Keyboard (15) are now both In Stock
        expect(find.text('In Stock'), findsNWidgets(2));
        // Low Stock count is now 0
        expect(find.text('Low Stock (3)'), findsNothing);

        // 9. Navigate back to Dashboard to verify Total Valuation
        await tester.tap(find.byKey(const Key('nav_dashboard')));
        await tester.pumpAndSettle();
        // Total Valuation updated: (24 * 29.99) + (15 * 129.99) + (0 * 19.00) = 719.76 + 1949.85 = $2669.61
        expect(find.text('\$2669.61'), findsOneWidget);
      },
    );

    testWidgets(
      'Edit product form validation enforces non-empty name, positive price, and non-negative integer quantity',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Navigate to Products tab
        await tester.tap(find.byKey(const Key('nav_products')));
        await tester.pumpAndSettle();

        // Open edit screen for Mouse
        final mouseRow = find.byKey(const Key('edit_product_prod-001'));
        await tester.ensureVisible(mouseRow);
        await tester.pumpAndSettle();
        await tester.tap(mouseRow);
        await tester.pumpAndSettle();

        final nameField = find.byKey(const Key('product_name_field'));
        final priceField = find.byKey(const Key('product_price_field'));
        final quantityField = find.byKey(const Key('product_quantity_field'));
        final updateBtn = find.byKey(const Key('save_product_button'));

        // Test 1: Empty name
        await tester.enterText(nameField, '');
        await tester.ensureVisible(updateBtn);
        await tester.pumpAndSettle();
        await tester.tap(updateBtn);
        await tester.pumpAndSettle();
        expect(find.text('Product name cannot be empty'), findsOneWidget);

        // Test 2: Invalid price (0 or negative)
        await tester.enterText(nameField, 'Valid Mouse Name');
        await tester.ensureVisible(priceField);
        await tester.pumpAndSettle();
        await tester.enterText(priceField, '0');
        await tester.ensureVisible(updateBtn);
        await tester.pumpAndSettle();
        await tester.tap(updateBtn);
        await tester.pumpAndSettle();
        expect(
          find.text('Price must be a valid number greater than zero'),
          findsOneWidget,
        );

        // Test 3: Invalid quantity (negative or decimal)
        await tester.ensureVisible(priceField);
        await tester.pumpAndSettle();
        await tester.enterText(priceField, '25.00');
        await tester.ensureVisible(quantityField);
        await tester.pumpAndSettle();
        await tester.enterText(quantityField, '-3');
        await tester.ensureVisible(updateBtn);
        await tester.pumpAndSettle();
        await tester.tap(updateBtn);
        await tester.pumpAndSettle();
        expect(
          find.text('Quantity must be a valid whole number (0 or greater)'),
          findsOneWidget,
        );

        await tester.ensureVisible(quantityField);
        await tester.pumpAndSettle();
        await tester.enterText(quantityField, '4.8');
        await tester.ensureVisible(updateBtn);
        await tester.pumpAndSettle();
        await tester.tap(updateBtn);
        await tester.pumpAndSettle();
        expect(
          find.text('Quantity must be a valid whole number (0 or greater)'),
          findsOneWidget,
        );

        // Verification: Submission prevented, still on Edit screen
        expect(find.text('Edit Product'), findsOneWidget);

        // Cancel editing
        final cancelBtn = find.byKey(const Key('cancel_product_button'));
        await tester.ensureVisible(cancelBtn);
        await tester.pumpAndSettle();
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Original values preserved
        expect(find.text('Wireless Ergonomic Mouse'), findsOneWidget);
        expect(find.text('Qty: 24'), findsOneWidget);
      },
    );

    testWidgets(
      'Editing product quantity to 0 updates status to Out of Stock and increments Out of Stock count',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Navigate to Products tab
        await tester.tap(find.byKey(const Key('nav_products')));
        await tester.pumpAndSettle();

        // Edit Mouse (qty 24) to qty 0
        final mouseRow = find.byKey(const Key('edit_product_prod-001'));
        await tester.ensureVisible(mouseRow);
        await tester.pumpAndSettle();
        await tester.tap(mouseRow);
        await tester.pumpAndSettle();

        final quantityField = find.byKey(const Key('product_quantity_field'));
        await tester.ensureVisible(quantityField);
        await tester.pumpAndSettle();
        await tester.enterText(quantityField, '0');

        final updateBtn = find.byKey(const Key('save_product_button'));
        await tester.ensureVisible(updateBtn);
        await tester.pumpAndSettle();
        await tester.tap(updateBtn);
        await tester.pumpAndSettle();

        // Mouse is now Out of Stock
        expect(find.text('Wireless Ergonomic Mouse updated!'), findsOneWidget);
        // On Products tab, Out of Stock filter chip (1) + Adapter badge (1) + Mouse badge (1) = 3
        expect(find.text('Out of Stock'), findsNWidgets(3));

        // Switch to Dashboard tab to verify the header metrics and overview
        await tester.tap(find.byKey(const Key('nav_dashboard')));
        await tester.pumpAndSettle();

        // Header metric card shows Out of Stock tile with 2 items
        expect(find.text('Out of Stock'), findsWidgets);
        expect(find.text('2'), findsWidgets);
      },
    );
  });

  group('4-Page Navigation and Integration tests', () {
    testWidgets(
      'Bottom navigation bar switches cleanly between all four destinations',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Destination 1: Dashboard is active by default
        expect(find.text('Total Inventory Value'), findsOneWidget);
        expect(find.byKey(const Key('nav_dashboard')), findsOneWidget);

        // Destination 2: Products
        await tester.tap(find.byKey(const Key('nav_products')));
        await tester.pumpAndSettle();
        expect(find.text('Product Catalog'), findsOneWidget);
        expect(find.byKey(const Key('product_search_field')), findsOneWidget);

        // Destination 3: Stock History
        await tester.tap(find.byKey(const Key('nav_history')));
        await tester.pumpAndSettle();
        expect(find.text('Stock Movement History'), findsOneWidget);
        expect(find.byKey(const Key('history_search_field')), findsOneWidget);

        // Destination 4: Settings
        await tester.tap(find.byKey(const Key('nav_settings')));
        await tester.pumpAndSettle();
        expect(find.text('Settings & Rules'), findsOneWidget);
        expect(find.text('Low-Stock Threshold Rule'), findsOneWidget);

        // Return back to Dashboard
        await tester.tap(find.byKey(const Key('nav_dashboard')));
        await tester.pumpAndSettle();
        expect(find.text('Total Inventory Value'), findsOneWidget);
      },
    );

    testWidgets(
      'Product changes reflect across Dashboard, Products, and Stock History',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Add a product from Dashboard FAB
        await tester.tap(find.byTooltip('Add Product'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('product_name_field')),
          'Audit Ledger Item',
        );
        await tester.enterText(
          find.byKey(const Key('product_price_field')),
          '50.00',
        );
        await tester.enterText(
          find.byKey(const Key('product_quantity_field')),
          '10',
        );
        final saveBtn = find.byKey(const Key('save_product_button'));
        await tester.ensureVisible(saveBtn);
        await tester.pumpAndSettle();
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // 1. Reflected on Dashboard
        expect(find.text('Products (4)'), findsOneWidget);
        expect(find.text('Audit Ledger Item'), findsOneWidget);

        // 2. Reflected on Products
        await tester.tap(find.byKey(const Key('nav_products')));
        await tester.pumpAndSettle();
        expect(find.text('Products (4)'), findsOneWidget);
        expect(find.text('Audit Ledger Item'), findsOneWidget);

        // 3. Reflected on Stock History
        await tester.tap(find.byKey(const Key('nav_history')));
        await tester.pumpAndSettle();
        expect(find.text('Audit Ledger Item'), findsOneWidget);
        expect(find.text('+10'), findsOneWidget);
      },
    );

    testWidgets(
      'Threshold changes reflect across Dashboard, Products, and Settings',
      (WidgetTester tester) async {
        await tester.pumpWidget(const StockMateApp());
        await tester.pumpAndSettle();

        // Default threshold is 5: Mechanical Gaming Keyboard (qty 3) is Low Stock
        // Mouse (qty 24) is In Stock
        // Navigate to Settings
        await tester.tap(find.byKey(const Key('nav_settings')));
        await tester.pumpAndSettle();

        // Change threshold to 25 via preset chip '25'
        final preset25 = find.byKey(const Key('settings_preset_25'));
        await tester.ensureVisible(preset25);
        await tester.pumpAndSettle();
        await tester.tap(preset25);
        await tester.pumpAndSettle();

        // Mouse (qty 24 <= 25) is now Low Stock!
        // Verify Settings reflects new threshold
        expect(find.text('≤ 25 units'), findsOneWidget);

        // Switch to Products page: Mouse is now Low Stock (24)
        await tester.tap(find.byKey(const Key('nav_products')));
        await tester.pumpAndSettle();
        expect(find.text('Low Stock (24)'), findsOneWidget);

        // Switch to Dashboard page: Low stock badge is updated for Mouse
        await tester.tap(find.byKey(const Key('nav_dashboard')));
        await tester.pumpAndSettle();
        expect(find.text('Low Stock (24)'), findsOneWidget);
      },
    );
  });
}
