import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/data/session_repository.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../../shared/models/session.dart';
import '../domain/reader_engine.dart';
import '../domain/token.dart';
import '../domain/tokenizer.dart';

class ReaderState {
  final String sessionId;
  final String title;
  final String content;
  final List<Token> tokens;
  final int index;
  final int wpm;
  final bool isPlaying;
  final int chunkSize;
  final bool isCompleted;

  const ReaderState({
    required this.sessionId,
    required this.title,
    required this.content,
    required this.tokens,
    required this.index,
    required this.wpm,
    required this.isPlaying,
    this.chunkSize = 1,
    this.isCompleted = false,
  });

  List<Token> get current {
    if (tokens.isEmpty) return [];
    final end = (index + chunkSize).clamp(0, tokens.length);
    return tokens.sublist(index, end);
  }

  ReaderState copyWith({
    String? sessionId,
    String? title,
    String? content,
    List<Token>? tokens,
    int? index,
    int? wpm,
    bool? isPlaying,
    int? chunkSize,
    bool? isCompleted,
  }) =>
      ReaderState(
        sessionId: sessionId ?? this.sessionId,
        title: title ?? this.title,
        content: content ?? this.content,
        tokens: tokens ?? this.tokens,
        index: index ?? this.index,
        wpm: wpm ?? this.wpm,
        isPlaying: isPlaying ?? this.isPlaying,
        chunkSize: chunkSize ?? this.chunkSize,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

class ReaderController extends Notifier<ReaderState> {
  @override
  ReaderState build() {
    final settings = ref.watch(settingsProvider);
    return ReaderState(
      sessionId: '',
      title: '',
      content: '',
      tokens: [],
      index: 0,
      wpm: settings.defaultWpm,
      isPlaying: false,
      chunkSize: settings.defaultChunkSize,
      isCompleted: false,
    );
  }

  SessionRepository get _repo => ref.read(sessionRepositoryProvider);
  Timer? _timer;
  DateTime? _nextTickAt;
  int _wordsReadInCurrentSession = 0;

  Future<void> loadText(String title, String content,
      {int? start, int? wpm}) async {
    final tokens = tokenizeText(content);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final settings = ref.read(settingsProvider);
    state = state.copyWith(
      sessionId: id,
      title: title,
      content: content,
      tokens: tokens,
      index: start ?? 0,
      wpm: wpm ?? settings.defaultWpm,
      chunkSize: settings.defaultChunkSize,
      isPlaying: false,
      isCompleted: false,
    );
    await _persist();
  }

  Future<void> loadSession(Session s) async {
    state = state.copyWith(
      sessionId: s.id,
      title: s.title,
      content: s.content,
      tokens: tokenizeText(s.content),
      index: s.position,
      wpm: s.wpm,
      isPlaying: false,
      isCompleted: false,
    );
  }

  void play() {
    if (state.tokens.isEmpty || state.isCompleted) return;
    _wordsReadInCurrentSession = 0;
    state = state.copyWith(isPlaying: true);
    _scheduleNextTick(baseDelayForWpm(state.wpm));
  }

  Future<void> pause() async {
    _timer?.cancel();
    state = state.copyWith(isPlaying: false);
    await _persist();
  }

  void setWpm(double value) {
    state = state.copyWith(wpm: value.round());
  }

  void setChunkSize(int size) {
    state = state.copyWith(chunkSize: size);
  }

  Future<void> next() async {
    if (state.tokens.isEmpty) return;
    state = state.copyWith(
        index:
            (state.index + state.chunkSize).clamp(0, state.tokens.length - 1),
        isCompleted: false);
    await _persist();
  }

  Future<void> previous() async {
    if (state.tokens.isEmpty) return;
    state = state.copyWith(
        index:
            (state.index - state.chunkSize).clamp(0, state.tokens.length - 1),
        isCompleted: false);
    await _persist();
  }

  Future<void> skipForward() async {
    if (state.tokens.isEmpty) return;
    state = state.copyWith(
        index: (state.index + 50).clamp(0, state.tokens.length - 1),
        isCompleted: false);
    await _persist();
  }

  Future<void> skipBackward() async {
    if (state.tokens.isEmpty) return;
    state = state.copyWith(
        index: (state.index - 50).clamp(0, state.tokens.length - 1),
        isCompleted: false);
    await _persist();
  }

  void _scheduleNextTick(Duration fromNow) {
    _timer?.cancel();
    _nextTickAt = DateTime.now().add(fromNow);
    _timer = Timer(fromNow, _onTick);
  }

  void _onTick() {
    if (!state.isPlaying || state.tokens.isEmpty) return;
    if (state.index >= state.tokens.length - 1) {
      pause();
      state = state.copyWith(isCompleted: true);
      return;
    }

    final nextIndex =
        (state.index + state.chunkSize).clamp(0, state.tokens.length - 1);
    state = state.copyWith(index: nextIndex);
    _wordsReadInCurrentSession += state.chunkSize;

    final base = baseDelayForWpm(state.wpm);
    final settings = ref.read(settingsProvider);

    // Adjust delay based on word length and punctuation
    Duration delay = adjustDelay(state.current.first.word, base,
            pauseOnPunctuation: settings.pauseOnPunctuation) *
        state.chunkSize;

    // Warm-up mode: Ramps up speed over the first 25 words
    if (_wordsReadInCurrentSession < 25) {
      final factor = 1.0 +
          ((25 - _wordsReadInCurrentSession) *
              0.04); // Start 2x slower, ramp up to 1x
      delay = Duration(milliseconds: (delay.inMilliseconds * factor).round());
    }

    final now = DateTime.now();
    final ideal = (_nextTickAt ?? now).add(delay);
    final driftAware = ideal.difference(now);
    _scheduleNextTick(driftAware.isNegative ? Duration.zero : driftAware);
  }

  Future<void> _persist() async {
    if (state.sessionId.isEmpty) return;
    await _repo.save(Session(
      id: state.sessionId,
      title: state.title,
      content: state.content,
      position: state.index,
      wpm: state.wpm,
      updatedAt: DateTime.now(),
    ));
  }
}

final sessionRepositoryProvider =
    Provider<SessionRepository>((ref) => SessionRepository());
final readerProvider =
    NotifierProvider<ReaderController, ReaderState>(ReaderController.new);
