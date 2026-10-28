import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_mate/main.dart';

Future<void> _loadRealFonts() async {
  final fontDir = Directory(
    r'C:\SRC\flutter\bin\cache\artifacts\material_fonts',
  );

  // Load Material Icons
  final iconLoader = FontLoader('MaterialIcons');
  final iconBytes = File(
    r'C:\SRC\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
  ).readAsBytesSync();
  iconLoader.addFont(Future.value(ByteData.view(iconBytes.buffer)));
  await iconLoader.load();

  // Load Roboto font family
  final robotoLoader = FontLoader('Roboto');
  for (final file in fontDir.listSync().whereType<File>()) {
    if (file.path.toLowerCase().contains('roboto') &&
        file.path.endsWith('.ttf')) {
      final bytes = file.readAsBytesSync();
      robotoLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await robotoLoader.load();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadRealFonts();

    // Ensure directory exists
    final dir = Directory('submission_evidence/day2');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  });

  testWidgets('Capture Day 2 genuine evidence screenshots', skip: true, (
    WidgetTester tester,
  ) async {
    // Emulate modern mobile device dimensions (412 x 915 @ 2x density)
    tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Launch App and navigate to Add Product screen
    await tester.pumpWidget(const StockMateApp());
    await tester.pumpAndSettle();

    final addFab = find.byTooltip('Add Product');
    await tester.tap(addFab);
    await tester.pumpAndSettle();

    // 2. Trigger validation errors by submitting empty form
    final saveButton = find.byKey(const Key('save_product_button'));
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Scroll up slightly to view the validation errors clearly
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 150));
    await tester.pumpAndSettle();

    // Evidence 1: Inline form validation errors
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day2/01_form_validation_errors.png',
      ),
    );

    // 3. Fill in valid data for a new product (Low Stock: 4 units <= 5)
    final nameField = find.byKey(const Key('product_name_field'));
    final categoryField = find.byKey(const Key('product_category_field'));
    final priceField = find.byKey(const Key('product_price_field'));
    final quantityField = find.byKey(const Key('product_quantity_field'));

    await tester.enterText(nameField, 'Wireless Studio Headphones');
    await tester.enterText(categoryField, 'Electronics');
    await tester.enterText(priceField, '129.99');
    await tester.enterText(quantityField, '4');
    await tester.pumpAndSettle();

    // Evidence 2: Form populated with valid product details
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day2/02_add_product_filled_form.png',
      ),
    );

    // 4. Submit form and return to inventory dashboard
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Evidence 3: Inventory dashboard with newly added product, updated metrics, and SnackBar
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day2/03_inventory_with_new_product.png',
      ),
    );

    // 5. Search for the newly added product
    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Headphones');
    await tester.pumpAndSettle();

    // Evidence 4: Live search filtering showing the newly added product
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day2/04_search_new_product.png',
      ),
    );
  });
}
