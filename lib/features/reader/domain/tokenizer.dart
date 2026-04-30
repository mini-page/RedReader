import 'token.dart';
import 'reader_engine.dart';

List<Token> tokenizeText(String input) {
  final normalized = input.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return const [];

  return normalized
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((word) => Token(word, getORPIndex(word)))
      .toList(growable: false);
}
