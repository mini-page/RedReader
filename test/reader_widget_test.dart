import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_reader/features/reader/presentation/reader_screen.dart';

void main() {
  testWidgets('reader screen renders controls', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ReaderScreen())));
    expect(find.byType(Slider), findsOneWidget);
    // New UI uses Icons.play_arrow_rounded when not playing
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
