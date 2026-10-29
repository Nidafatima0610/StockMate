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

    final dir = Directory('submission_evidence/day4');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Capture Day 4 genuine evidence screenshots', skip: true, (
    WidgetTester tester,
  ) async {
    // Emulate modern mobile device dimensions (412 x 915 @ 2x density)
    tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Launch App - Dashboard showing History button and interactive Threshold pill
    await tester.pumpWidget(const StockMateApp());
    await tester.pumpAndSettle();

    // Evidence 1: Dashboard with History navigation button and Threshold: ≤ 5 pill
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day4/01_dashboard_with_history_and_threshold.png',
      ),
    );

    // 2. Generate stock movements via quick steppers, then open Stock History
    final incBtn = find.byKey(const Key('increment_qty_prod-001'));
    await tester.ensureVisible(incBtn);
    await tester.pumpAndSettle();
    await tester.tap(incBtn);
    await tester.pumpAndSettle();

    final decBtn = find.byKey(const Key('decrement_qty_prod-002'));
    await tester.ensureVisible(decBtn);
    await tester.pumpAndSettle();
    await tester.tap(decBtn);
    await tester.pumpAndSettle();

    // Open Stock History Screen
    final historyBtn = find.byKey(const Key('history_button'));
    await tester.tap(historyBtn);
    await tester.pumpAndSettle();

    // Evidence 2: Stock History screen with filter chips and color-coded movement cards
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day4/02_stock_history_screen_with_movements.png',
      ),
    );

    // Return back to inventory dashboard
    final backBtn = find.byKey(const Key('history_back_button'));
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // 3. Open Low-Stock Threshold configuration dialog
    final thresholdPill = find.byKey(const Key('threshold_settings_button'));
    await tester.tap(thresholdPill);
    await tester.pumpAndSettle();

    // Select preset ≤ 10 in dialog
    final preset10 = find.byKey(const Key('threshold_preset_10'));
    await tester.tap(preset10);
    await tester.pumpAndSettle();

    // Evidence 3: Threshold dialog showing stepper, preset chips, and live preview count
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day4/03_threshold_configuration_dialog.png',
      ),
    );

    // 4. Save threshold to apply and show updated dashboard
    final saveThresholdBtn = find.byKey(const Key('save_threshold_button'));
    await tester.tap(saveThresholdBtn);
    await tester.pumpAndSettle();

    // Evidence 4: Dashboard reflecting new threshold ≤ 10 with updated Low Stock count & SnackBar
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day4/04_dashboard_updated_after_threshold_change.png',
      ),
    );

    // 5. Delete a product and verify deleted product historical record
    final deleteBtn = find.byKey(const Key('delete_product_prod-002'));
    await tester.ensureVisible(deleteBtn);
    await tester.pumpAndSettle();
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    final confirmDelete = find.widgetWithText(ElevatedButton, 'Delete');
    await tester.tap(confirmDelete);
    await tester.pumpAndSettle();

    // Open History Screen to see deleted product entry
    await tester.tap(find.byKey(const Key('history_button')));
    await tester.pumpAndSettle();

    // Evidence 5: Stock History screen showing deleted product record with graceful badge
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day4/05_deleted_product_in_history.png',
      ),
    );

    // Return to dashboard
    await tester.tap(find.byKey(const Key('history_back_button')));
    await tester.pumpAndSettle();

    // 6. Delete remaining products to show empty inventory state
    for (final id in ['prod-001', 'prod-003', 'prod-004']) {
      final delBtn = find.byKey(Key('delete_product_$id'));
      if (delBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(delBtn);
        await tester.pumpAndSettle();
        await tester.tap(delBtn);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
        await tester.pumpAndSettle();
      }
    }

    // Evidence 6: Clean, informative empty inventory state with Add First Product button
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day4/06_empty_inventory_state.png',
      ),
    );

    // 7. Add a real product from empty state, then simulate app restart
    final addFirstBtn = find.byKey(const Key('empty_add_product_button'));
    await tester.ensureVisible(addFirstBtn);
    await tester.pumpAndSettle();
    await tester.tap(addFirstBtn);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('product_name_field')),
      'Wireless Barcode Scanner',
    );
    await tester.enterText(
      find.byKey(const Key('product_category_field')),
      'POS Equipment',
    );
    await tester.enterText(
      find.byKey(const Key('product_price_field')),
      '149.99',
    );
    await tester.enterText(
      find.byKey(const Key('product_quantity_field')),
      '12',
    );

    final saveBtn = find.byKey(const Key('save_product_button'));
    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Simulate App Restart by destroying widget tree and re-mounting StockMateApp
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    await tester.pumpWidget(const StockMateApp());
    await tester.pumpAndSettle();

    // Evidence 7: Restored custom inventory after restart without sample data overwrite
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile(
        '../submission_evidence/day4/07_restored_inventory_after_restart.png',
      ),
    );
  });
}
