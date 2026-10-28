import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_mate/main.dart';
import 'package:stock_mate/screens/add_edit_product_screen.dart';
import 'package:stock_mate/models/product.dart';

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
  });

  testWidgets(
    'Capture genuine evidence screenshots with real fonts and icons',
    skip: true,
    (WidgetTester tester) async {
      // Emulate typical Android phone screen dimensions (412 x 915)
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Inventory Dashboard
      await tester.pumpWidget(const StockMateApp());
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(StockMateApp),
        matchesGoldenFile(
          '../submission_evidence/day1/01_inventory_dashboard.png',
        ),
      );

      // 2. Search and Filter Interface (search for 'Mouse')
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Mouse');
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(StockMateApp),
        matchesGoldenFile(
          '../submission_evidence/day1/02_search_and_filter.png',
        ),
      );

      // 3. Add Product Screen
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFFF7F7FC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5B2EBC),
              primary: const Color(0xFF5B2EBC),
            ),
          ),
          home: const AddEditProductScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../submission_evidence/day1/03_add_product_screen.png',
        ),
      );

      // 4. Edit Product Screen
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFFF7F7FC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5B2EBC),
              primary: const Color(0xFF5B2EBC),
            ),
          ),
          home: AddEditProductScreen(
            key: const ValueKey('edit_screen'),
            product: sampleProducts[1],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../submission_evidence/day1/04_edit_product_screen.png',
        ),
      );
    },
  );
}
