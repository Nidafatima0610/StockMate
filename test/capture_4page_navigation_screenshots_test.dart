import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_mate/main.dart';

Future<void> _loadRealFonts() async {
  try {
    final fontDir = Directory(
      r'C:\SRC\flutter\bin\cache\artifacts\material_fonts',
    );
    if (fontDir.existsSync()) {
      final iconLoader = FontLoader('MaterialIcons');
      final iconBytes = File(
        r'C:\SRC\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
      ).readAsBytesSync();
      iconLoader.addFont(Future.value(ByteData.view(iconBytes.buffer)));
      await iconLoader.load();

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
  } catch (_) {}
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadRealFonts();

    final dir = Directory('goldens/navigation_4page');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Capture 4-Page Navigation screenshots for visual verification', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StockMateApp());
    await tester.pumpAndSettle();

    // 1. Destination 1: Dashboard
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile('goldens/navigation_4page/01_dashboard.png'),
    );

    // 2. Destination 2: Products Complete Catalog
    await tester.tap(find.byKey(const Key('nav_products')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile('goldens/navigation_4page/02_products.png'),
    );

    // 3. Destination 3: Stock History Audit Ledger
    await tester.tap(find.byKey(const Key('nav_history')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile('goldens/navigation_4page/03_stock_history.png'),
    );

    // 4. Destination 4: Settings & Threshold Rules
    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(StockMateApp),
      matchesGoldenFile('goldens/navigation_4page/04_settings.png'),
    );
  });
}
