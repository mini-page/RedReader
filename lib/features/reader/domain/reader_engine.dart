Duration baseDelayForWpm(int wpm) {
  final clamped = wpm.clamp(100, 1200);
  return Duration(milliseconds: (60000 / clamped).round());
}

int getORPIndex(String word) {
  if (word.length <= 1) return 0;
  if (word.length <= 5) return 1;
  if (word.length <= 9) return 2;
  return 3;
}

Duration adjustDelay(String word, Duration base) {
  if (word.endsWith('.') || word.endsWith(',') || word.endsWith(';') || word.endsWith(':')) {
    return Duration(milliseconds: (base.inMilliseconds * 1.5).round());
  }
  if (word.length > 10) {
    return Duration(milliseconds: (base.inMilliseconds * 1.2).round());
  }
  return base;
}
