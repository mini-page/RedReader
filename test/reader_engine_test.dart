import 'package:flutter_test/flutter_test.dart';
import 'package:red_reader/features/reader/domain/reader_engine.dart';
import 'package:red_reader/features/reader/domain/tokenizer.dart';

void main() {
  test('orp index rules', () {
    expect(getORPIndex('a'), 0);
    expect(getORPIndex('word'), 1);
    expect(getORPIndex('reading'), 2);
    expect(getORPIndex('elevencharsx'), 3);
  });

  test('tokenizer normalizes spaces', () {
    final tokens = tokenizeText('hello   world');
    expect(tokens.length, 2);
    expect(tokens.first.word, 'hello');
  });

  test('timing adjustment for punctuation', () {
    const base = Duration(milliseconds: 100);
    expect(adjustDelay('hello,', base).inMilliseconds, 150);
  });
}
