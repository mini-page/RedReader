import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/library/data/session_repository.dart';
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

  const ReaderState({
    required this.sessionId,
    required this.title,
    required this.content,
    required this.tokens,
    required this.index,
    required this.wpm,
    required this.isPlaying,
  });

  Token? get current => tokens.isEmpty ? null : tokens[index.clamp(0, tokens.length - 1)];

  ReaderState copyWith({String? sessionId, String? title, String? content, List<Token>? tokens, int? index, int? wpm, bool? isPlaying}) => ReaderState(
        sessionId: sessionId ?? this.sessionId,
        title: title ?? this.title,
        content: content ?? this.content,
        tokens: tokens ?? this.tokens,
        index: index ?? this.index,
        wpm: wpm ?? this.wpm,
        isPlaying: isPlaying ?? this.isPlaying,
      );
}

class ReaderController extends StateNotifier<ReaderState> {
  ReaderController(this._repo)
      : super(const ReaderState(sessionId: '', title: '', content: '', tokens: [], index: 0, wpm: 550, isPlaying: false));

  final SessionRepository _repo;
  Timer? _timer;
  DateTime? _nextTickAt;

  Future<void> loadText(String title, String content, {int? start, int? wpm}) async {
    final tokens = tokenizeText(content);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    state = state.copyWith(
      sessionId: id,
      title: title,
      content: content,
      tokens: tokens,
      index: start ?? 0,
      wpm: wpm ?? state.wpm,
      isPlaying: false,
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
    );
  }

  void play() {
    if (state.tokens.isEmpty) return;
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

  Future<void> next() async {
    if (state.tokens.isEmpty) return;
    state = state.copyWith(index: (state.index + 1).clamp(0, state.tokens.length - 1));
    await _persist();
  }

  Future<void> previous() async {
    if (state.tokens.isEmpty) return;
    state = state.copyWith(index: (state.index - 1).clamp(0, state.tokens.length - 1));
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
      return;
    }
    state = state.copyWith(index: state.index + 1);
    final base = baseDelayForWpm(state.wpm);
    final delay = adjustDelay(state.current!.word, base);
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

final sessionRepositoryProvider = Provider<SessionRepository>((ref) => SessionRepository());
final readerProvider = StateNotifierProvider<ReaderController, ReaderState>((ref) => ReaderController(ref.read(sessionRepositoryProvider)));
