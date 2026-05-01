Duration baseDelayForWpm(int wpm) {
  final clamped = wpm.clamp(100, 2000);
  return Duration(milliseconds: (60000 / clamped).round());
}

int getORPIndex(String word) {
  if (word.length <= 1) return 0;
  if (word.length <= 5) return 1;
  if (word.length <= 9) return 2;
  if (word.length <= 13) return 3;
  return 4;
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
