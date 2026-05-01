import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:red_reader/app.dart';

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
  });

  testWidgets('smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RedReaderApp()));
    await tester.pump(); // allow Hive to settle if needed
    expect(find.text('REDEYE'), findsOneWidget);
  });
}
