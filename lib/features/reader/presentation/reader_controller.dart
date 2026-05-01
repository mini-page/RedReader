import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../library/data/session_repository.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../../shared/models/session.dart';
import '../domain/reader_engine.dart';
import '../domain/token.dart';
import '../domain/tokenizer.dart';
import '../../../core/services/ai_service.dart';
import '../../stats/data/stats_repository.dart';

enum ReadingMode { rsvp, scroll, audio }

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
  final ReadingMode mode;
  final bool isLoadingAI;

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
    this.mode = ReadingMode.rsvp,
    this.isLoadingAI = false,
  });

  List<Token> get current {
    if (tokens.isEmpty) return [];
    final end = (index + chunkSize).clamp(0, tokens.length);
    return tokens.sublist(index, end);
  }

  double get progress => tokens.isEmpty ? 0 : (index / tokens.length).clamp(0.0, 1.0);

  // Time calculations based on WPM
  int get totalDurationSeconds => tokens.isEmpty ? 0 : (tokens.length / (wpm / 60)).round();
  int get currentDurationSeconds => tokens.isEmpty ? 0 : (index / (wpm / 60)).round();

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
    ReadingMode? mode,
    bool? isLoadingAI,
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
        mode: mode ?? this.mode,
        isLoadingAI: isLoadingAI ?? this.isLoadingAI,
      );
}

class ReaderController extends Notifier<ReaderState> {
  final FlutterTts _tts = FlutterTts();
  DateTime? _sessionStartTime;
  int _wordsReadInCurrentSession = 0;

  @override
  ReaderState build() {
    final settings = ref.watch(settingsProvider);
    _initTts();
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
      mode: ReadingMode.rsvp,
      isLoadingAI: false,
    );
  }

  void _initTts() {
    _tts.setCompletionHandler(() {
      if (state.isPlaying) {
        _onTtsComplete();
      }
    });
  }

  SessionRepository get _repo => ref.read(sessionRepositoryProvider);
  Timer? _timer;
  DateTime? _nextTickAt;

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

  void setMode(ReadingMode mode) {
    if (state.isPlaying) pause();
    state = state.copyWith(mode: mode);
  }

  void play() {
    if (state.tokens.isEmpty || state.isCompleted) return;
    _wordsReadInCurrentSession = 0;
    _sessionStartTime = DateTime.now();
    state = state.copyWith(isPlaying: true);

    if (state.mode == ReadingMode.audio) {
      _startTts();
    } else {
      _scheduleNextTick(baseDelayForWpm(state.wpm));
    }
  }

  Future<void> pause() async {
    _timer?.cancel();
    if (state.mode == ReadingMode.audio) {
      await _tts.stop();
    }
    
    if (_sessionStartTime != null && _wordsReadInCurrentSession > 0) {
      final duration = DateTime.now().difference(_sessionStartTime!).inSeconds;
      if (duration > 0) {
        await ref.read(statsRepositoryProvider).addSession(
          _wordsReadInCurrentSession,
          duration,
          state.wpm.toDouble(),
        );
      }
    }
    _sessionStartTime = null;

    state = state.copyWith(isPlaying: false);
    await _persist();
  }

  void _startTts() async {
    if (state.index >= state.tokens.length) return;
    double rate = (state.wpm / 400).clamp(0.0, 1.0);
    await _tts.setSpeechRate(rate);
    _speakNextWord();
  }

  void _speakNextWord() async {
    if (!state.isPlaying || state.index >= state.tokens.length) {
      if (state.index >= state.tokens.length) {
        state = state.copyWith(isCompleted: true, isPlaying: false);
      }
      return;
    }
    final word = state.tokens[state.index].word;
    await _tts.speak(word);
  }

  void _onTtsComplete() {
    if (!state.isPlaying) return;
    final nextIndex = state.index + 1;
    _wordsReadInCurrentSession++;
    if (nextIndex >= state.tokens.length) {
      state = state.copyWith(index: nextIndex, isCompleted: true, isPlaying: false);
      pause();
    } else {
      state = state.copyWith(index: nextIndex);
      _speakNextWord();
    }
  }

  void setWpm(double value) {
    state = state.copyWith(wpm: value.round());
    if (state.isPlaying && state.mode == ReadingMode.audio) {
      _startTts();
    }
  }

  void setChunkSize(int size) {
    state = state.copyWith(chunkSize: size);
  }

  Future<void> seekTo(double percent) async {
    final newIndex = (percent * (state.tokens.length - 1)).round().clamp(0, state.tokens.length - 1);
    state = state.copyWith(index: newIndex, isCompleted: false);
    if (state.isPlaying && state.mode == ReadingMode.audio) {
      _startTts();
    }
    await _persist();
  }

  Future<void> jumpToIndex(int i) async {
    state = state.copyWith(index: i.clamp(0, state.tokens.length - 1), isCompleted: false);
    if (state.isPlaying && state.mode == ReadingMode.audio) {
      _startTts();
    }
    await _persist();
  }

  Future<void> skipSeconds(int seconds) async {
    final wordsToSkip = (seconds * (state.wpm / 60)).round();
    final newIndex = (state.index + wordsToSkip).clamp(0, state.tokens.length - 1);
    state = state.copyWith(index: newIndex, isCompleted: false);
    if (state.isPlaying && state.mode == ReadingMode.audio) _startTts();
    await _persist();
  }

  Future<String?> transform(Future<String> Function(AIProvider provider) action) async {
    final aiService = ref.read(aiServiceProvider);
    final provider = await aiService.getProvider();
    if (provider == null) return "AI Provider not available";

    if (state.isPlaying) await pause();
    state = state.copyWith(isLoadingAI: true);

    try {
      final transformedText = await action(provider);
      if (transformedText.isNotEmpty) {
        final newTokens = tokenizeText(transformedText);
        state = state.copyWith(
          content: transformedText,
          tokens: newTokens,
          index: 0,
          isCompleted: false,
          isLoadingAI: false,
        );
        await _persist();
        return null;
      } else {
        state = state.copyWith(isLoadingAI: false);
        return "Empty response from AI";
      }
    } catch (e) {
      state = state.copyWith(isLoadingAI: false);
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  Future<void> next() async {
    if (state.tokens.isEmpty) return;
    state = state.copyWith(
        index: (state.index + state.chunkSize).clamp(0, state.tokens.length - 1),
        isCompleted: false);
    if (state.isPlaying && state.mode == ReadingMode.audio) _startTts();
    await _persist();
  }

  Future<void> previous() async {
    if (state.tokens.isEmpty) return;
    state = state.copyWith(
        index: (state.index - state.chunkSize).clamp(0, state.tokens.length - 1),
        isCompleted: false);
    if (state.isPlaying && state.mode == ReadingMode.audio) _startTts();
    await _persist();
  }

  Future<void> skipForward() async => skipSeconds(10);
  Future<void> skipBackward() async => skipSeconds(-10);

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

    final nextIndex = (state.index + state.chunkSize).clamp(0, state.tokens.length - 1);
    state = state.copyWith(index: nextIndex);
    _wordsReadInCurrentSession += state.chunkSize;

    final base = baseDelayForWpm(state.wpm);
    final settings = ref.read(settingsProvider);

    Duration delay = adjustDelay(state.tokens[state.index].word, base,
            pauseOnPunctuation: settings.pauseOnPunctuation) *
        state.chunkSize;

    if (_wordsReadInCurrentSession < 25) {
      final factor = 1.0 + ((25 - _wordsReadInCurrentSession) * 0.04);
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

final sessionRepositoryProvider = Provider<SessionRepository>((ref) => SessionRepository());
final readerProvider = NotifierProvider<ReaderController, ReaderState>(ReaderController.new);
