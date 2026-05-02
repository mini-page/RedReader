class Token {
  final String word;
  final int orpIndex;

  const Token({
    required this.word,
    required this.orpIndex,
  });
}

class Paragraph {
  final List<Token> tokens;
  final String text;
  final int globalStartIndex;

  const Paragraph({
    required this.tokens,
    required this.text,
    required this.globalStartIndex,
  });
}

List<Paragraph> paragraphize(String input) {
  if (input.trim().isEmpty) return const [];

  // Split by sentence endings: . ! ? followed by space or newline
  final sentenceRegExp = RegExp(r'(?<=[.!?])\s+');
  final sentenceTexts = input.trim().split(sentenceRegExp);

  List<Paragraph> paragraphs = [];
  int currentGlobalIndex = 0;

  for (final text in sentenceTexts) {
    if (text.trim().isEmpty) continue;
    
    final tokens = text.trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((word) => Token(word: word, orpIndex: getORPIndex(word)))
        .toList(growable: false);

    if (tokens.isNotEmpty) {
      paragraphs.add(Paragraph(
        tokens: tokens,
        text: text.trim(),
        globalStartIndex: currentGlobalIndex,
      ));
      currentGlobalIndex += tokens.length;
    }
  }

  return paragraphs;
}

int getORPIndex(String word) {
  if (word.length <= 1) return 0;
  if (word.length <= 5) return 1;
  if (word.length <= 9) return 2;
  if (word.length <= 13) return 3;
  return 4;
}

List<Token> tokenizeText(String input) {
  final paras = paragraphize(input);
  return paras.expand((p) => p.tokens).toList(growable: false);
}

Duration baseDelayForWpm(int wpm) {
  final clamped = wpm.clamp(100, 2000);
  return Duration(milliseconds: (60000 / clamped).round());
}

Duration adjustDelay(String word, Duration base,
    {bool pauseOnPunctuation = true}) {
  if (pauseOnPunctuation &&
      (word.endsWith('.') ||
          word.endsWith(',') ||
          word.endsWith(';') ||
          word.endsWith(':') ||
          word.endsWith('!') ||
          word.endsWith('?'))) {
    return Duration(milliseconds: (base.inMilliseconds * 2.0).round());
  }
  if (word.length > 10) {
    return Duration(milliseconds: (base.inMilliseconds * 1.3).round());
  }
  return base;
}
