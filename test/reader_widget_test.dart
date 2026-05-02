import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_reader/features/reader/presentation/reader_screen.dart';

void main() {
  testWidgets('reader screen renders controls', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ReaderScreen())));
    
    // Tap settings button to show the popup which contains the sliders
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsAtLeast(1));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
