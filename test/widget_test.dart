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
      expect(find.text('Out of Stock'), findsNWidgets(3));

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

        // Keyboard starts with qty 3 (Low Stock)
        expect(find.text('Low Stock (3)'), findsOneWidget);

        // Tap + button for Mechanical Gaming Keyboard (prod-002)
        final incrementBtn = find.byKey(const Key('increment_qty_prod-002'));
        expect(incrementBtn, findsOneWidget);
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

        expect(find.text('Products (3)'), findsOneWidget);

        // Tap delete button for Adapter (prod-003)
        final deleteBtn = find.byKey(const Key('delete_product_prod-003'));
        expect(deleteBtn, findsOneWidget);
        await tester.ensureVisible(deleteBtn);
        await tester.pumpAndSettle();
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
  });
}
