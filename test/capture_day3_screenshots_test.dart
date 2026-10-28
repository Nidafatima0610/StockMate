import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    final dir = Directory('submission_evidence/day3');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Capture Day 3 genuine evidence screenshots', skip: true, (
    WidgetTester tester,
  ) async {
    // Emulate modern mobile device dimensions (412 x 915 @ 2x density)
    tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Launch App - Dashboard with valuation, category chips, and steppers
    await tester.pumpWidget(const StockMateApp());
    await tester.pumpAndSettle();

    // Evidence 1: Dashboard with Valuation ribbon, steppers, and category chips
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day3/01_dashboard_with_valuation_and_steppers.png',
      ),
    );

    // 2. Open Sort menu to show 6 sort choices
    final sortButton = find.byKey(const Key('sort_button'));
    await tester.tap(sortButton);
    await tester.pumpAndSettle();

    // Evidence 2: Sort popup menu displaying all 6 sort options
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile('../submission_evidence/day3/02_sort_options_menu.png'),
    );

    // Close sort menu by selecting Price (High to Low)
    await tester.tap(find.text('Price (High to Low)'));
    await tester.pumpAndSettle();

    // 3. Filter by Category ('Electronics')
    final electronicsChip = find.byKey(const Key('category_chip_Electronics'));
    await tester.tap(electronicsChip);
    await tester.pumpAndSettle();

    // Evidence 3: Category filter active (Electronics selected, showing filtered results)
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day3/03_category_filter_active.png',
      ),
    );

    // Reset category to All Categories
    final allChip = find.byKey(const Key('category_chip_All Categories'));
    await tester.tap(allChip);
    await tester.pumpAndSettle();

    // 4. Trigger Delete Product confirmation dialog for USB-C Adapter
    final deleteButton = find.byKey(const Key('delete_product_prod-003'));
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Evidence 4: Delete confirmation dialog with styled Delete/Cancel buttons
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day3/04_delete_confirmation_dialog.png',
      ),
    );

    // 5. Confirm deletion to show floating SnackBar with UNDO action
    final confirmDelete = find.widgetWithText(ElevatedButton, 'Delete');
    await tester.tap(confirmDelete);
    await tester.pumpAndSettle();

    // Evidence 5: Product deletion feedback SnackBar with working UNDO button
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day3/05_delete_undo_snackbar.png',
      ),
    );
  });
}
