import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';

import 'package:red_reader/features/library/data/session_repository.dart';
import 'package:red_reader/features/settings/presentation/settings_controller.dart';
import 'package:red_reader/shared/models/session.dart';
import 'package:red_reader/features/reader/domain/reader_engine.dart';
import 'package:red_reader/core/services/ai_service.dart';
import 'package:red_reader/features/stats/data/stats_repository.dart';
import 'package:red_reader/features/bookmarks/presentation/bookmarks_provider.dart';
import 'package:red_reader/features/bookmarks/data/bookmark_repository.dart';
import 'package:red_reader/features/bookmarks/domain/bookmark.dart';

enum ReadingMode { rsvp, scroll }

class ReaderState {
  final String sessionId;
  final String title;
  final String content;
  final List<Token> tokens;
  final List<Paragraph> paragraphs;
  final int index;
  final int wpm;
  final bool isPlaying;
  final int chunkSize;
  final bool isCompleted;
  final ReadingMode mode;
  final bool isLoadingAI;
  final bool showContext;
  final bool isAudioEnabled;
  final Set<int> bookmarks;
  final bool isReviewMode;

  const ReaderState({
    required this.sessionId,
    required this.title,
    required this.content,
    required this.tokens,
    required this.paragraphs,
    required this.index,
    required this.wpm,
    required this.isPlaying,
    this.chunkSize = 1,
    this.isCompleted = false,
    this.mode = ReadingMode.rsvp,
    this.isLoadingAI = false,
    this.showContext = true,
    this.isAudioEnabled = false,
    this.bookmarks = const {},
    this.isReviewMode = false,
  });

  int get currentParagraphIndex {
    for (int i = 0; i < paragraphs.length; i++) {
      final p = paragraphs[i];
      if (index >= p.globalStartIndex && index < p.globalStartIndex + p.tokens.length) {
        return i;
      }
    }
    return 0;
  }

  List<Token> get current {
    if (tokens.isEmpty) return [];
    final end = (index + chunkSize).clamp(0, tokens.length);
    return tokens.sublist(index, end);
  }

  double get progress => tokens.isEmpty ? 0 : (index / tokens.length).clamp(0.0, 1.0);

  ReaderState copyWith({
    String? sessionId,
    String? title,
    String? content,
    List<Token>? tokens,
    List<Paragraph>? paragraphs,
    int? index,
    int? wpm,
    bool? isPlaying,
    int? chunkSize,
    bool? isCompleted,
    ReadingMode? mode,
    bool? isLoadingAI,
    bool? showContext,
    bool? isAudioEnabled,
    Set<int>? bookmarks,
    bool? isReviewMode,
  }) =>
      ReaderState(
        sessionId: sessionId ?? this.sessionId,
        title: title ?? this.title,
        content: content ?? this.content,
        tokens: tokens ?? this.tokens,
        paragraphs: paragraphs ?? this.paragraphs,
        index: index ?? this.index,
        wpm: wpm ?? this.wpm,
        isPlaying: isPlaying ?? this.isPlaying,
        chunkSize: chunkSize ?? this.chunkSize,
        isCompleted: isCompleted ?? this.isCompleted,
        mode: mode ?? this.mode,
        isLoadingAI: isLoadingAI ?? this.isLoadingAI,
        showContext: showContext ?? this.showContext,
        isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
        bookmarks: bookmarks ?? this.bookmarks,
        isReviewMode: isReviewMode ?? this.isReviewMode,
      );
}

final bookmarkRepositoryProvider = Provider((ref) => BookmarkRepository());

class ReaderController extends Notifier<ReaderState> {
  final FlutterTts _tts = FlutterTts();
  final _uuid = const Uuid();
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
      paragraphs: [],
      index: 0,
      wpm: settings.defaultWpm,
      isPlaying: false,
      chunkSize: settings.defaultChunkSize,
      isCompleted: false,
      mode: ReadingMode.rsvp,
      isLoadingAI: false,
      bookmarks: {},
    );
  }

  void _initTts() {
    _tts.setCompletionHandler(() {
      if (state.isPlaying && state.isAudioEnabled) {
        _onParagraphComplete();
      }
    });
  }

  SessionRepository get _repo => ref.read(sessionRepositoryProvider);
  BookmarkRepository get _bookmarkRepo => ref.read(bookmarkRepositoryProvider);
  Timer? _timer;
  DateTime? _nextTickAt;
Future<void> toggleBookmark([int? targetIndex]) async {
  final idx = targetIndex ?? state.index;
  if (idx < 0 || idx >= state.tokens.length) return;

  final currentWord = state.tokens[idx].word;
  final bookmarkId = '${state.sessionId}_$idx';

  // Update local state immediately for snappy UI
  final newBookmarks = Set<int>.from(state.bookmarks);
  final isAdding = !newBookmarks.contains(idx);

  if (isAdding) {
    newBookmarks.add(idx);
  } else {
    newBookmarks.remove(idx);
  }
  state = state.copyWith(bookmarks: newBookmarks);

  // Persist to repository in background
  if (isAdding) {
    await _bookmarkRepo.add(Bookmark(
      id: bookmarkId,
      word: currentWord,
      index: idx,
      sessionId: state.sessionId,
      sessionTitle: state.title,
      createdAt: DateTime.now(),
    ));
  } else {
    await _bookmarkRepo.delete(bookmarkId);
  }

  // Refresh the global bookmarks provider for other screens
  ref.invalidate(bookmarksProvider);
}

Future<void> speakWords(String text) async {
  await _tts.speak(text);
}

  Future<void> loadText(String title, String content,
      {int? start, int? wpm}) async {
    final paragraphs = paragraphize(content);
    final tokens = paragraphs.expand((p) => p.tokens).toList();
    final id = _uuid.v4();
    final settings = ref.read(settingsProvider);
    
    // Load existing bookmarks for this text (simple check by content hash or similar? for now text title)
    // Actually, Text ID would be better.
    
    state = state.copyWith(
      sessionId: id,
      title: title,
      content: content,
      tokens: tokens,
      paragraphs: paragraphs,
      index: start ?? 0,
      wpm: wpm ?? settings.defaultWpm,
      chunkSize: settings.defaultChunkSize,
      isPlaying: false,
      isCompleted: false,
      bookmarks: {},
    );
    await _persist();
  }

  Future<void> loadSession(Session s) async {
    final paragraphs = paragraphize(s.content);
    final tokens = paragraphs.expand((p) => p.tokens).toList();
    
    // Load bookmarks for this session
    final bks = await _bookmarkRepo.bySession(s.id);
    final bookmarkIndices = bks.map((b) => b.index).toSet();

    state = state.copyWith(
      sessionId: s.id,
      title: s.title,
      content: s.content,
      tokens: tokens,
      paragraphs: paragraphs,
      index: s.position,
      wpm: s.wpm,
      isPlaying: false,
      isCompleted: false,
      bookmarks: bookmarkIndices,
    );
  }

  void setMode(ReadingMode mode) {
    if (state.isPlaying) pause();
    state = state.copyWith(mode: mode);
  }

  void toggleContext() {
    state = state.copyWith(showContext: !state.showContext);
  }

  void toggleAudio() {
    final newValue = !state.isAudioEnabled;
    if (state.isPlaying && !newValue) _tts.stop();
    state = state.copyWith(isAudioEnabled: newValue);
    if (state.isPlaying && newValue) _speakCurrentParagraph();
  }

  void play() {
    if (state.tokens.isEmpty || state.isCompleted) return;
    _wordsReadInCurrentSession = 0;
    _sessionStartTime = DateTime.now();
    state = state.copyWith(isPlaying: true);

    if (state.isAudioEnabled) {
      _speakCurrentParagraph();
    }
    _scheduleNextTick(baseDelayForWpm(state.wpm));
  }

  Future<void> pause() async {
    _timer?.cancel();
    if (state.isAudioEnabled) {
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

  void _speakCurrentParagraph() async {
    if (!state.isPlaying || !state.isAudioEnabled || state.paragraphs.isEmpty) return;
    
    final currentP = state.paragraphs[state.currentParagraphIndex];
    double rate = (state.wpm / 400).clamp(0.0, 1.0);
    await _tts.setSpeechRate(rate);
    await _tts.speak(currentP.text);
  }

  void _onParagraphComplete() {
    if (!state.isPlaying || !state.isAudioEnabled) return;
  }

  void setWpm(double value) {
    state = state.copyWith(wpm: value.round());
    if (state.isPlaying && state.isAudioEnabled) {
      _tts.stop();
      _speakCurrentParagraph();
    }
  }

  void setChunkSize(int size) {
    state = state.copyWith(chunkSize: size);
  }

  Future<void> seekTo(double percent) async {
    final newIndex = (percent * (state.tokens.length - 1)).round().clamp(0, state.tokens.length - 1);
    final oldParaIndex = state.currentParagraphIndex;
    state = state.copyWith(index: newIndex, isCompleted: false);
    
    if (state.isPlaying && state.isAudioEnabled && state.currentParagraphIndex != oldParaIndex) {
      _tts.stop();
      _speakCurrentParagraph();
    }
    await _persist();
  }

  Future<void> jumpToIndex(int i) async {
    final oldParaIndex = state.currentParagraphIndex;
    state = state.copyWith(index: i.clamp(0, state.tokens.length - 1), isCompleted: false);
    
    if (state.isPlaying && state.isAudioEnabled && state.currentParagraphIndex != oldParaIndex) {
      _tts.stop();
      _speakCurrentParagraph();
    }
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
        final paragraphs = paragraphize(transformedText);
        state = state.copyWith(
          content: transformedText,
          tokens: paragraphs.expand((p) => p.tokens).toList(),
          paragraphs: paragraphs,
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

  Future<void> nextParagraph() async {
    if (state.paragraphs.isEmpty) return;
    final currentPara = state.currentParagraphIndex;
    if (currentPara < state.paragraphs.length - 1) {
      jumpToIndex(state.paragraphs[currentPara + 1].globalStartIndex);
    }
  }

  Future<void> previousParagraph() async {
    if (state.paragraphs.isEmpty) return;
    final currentPara = state.currentParagraphIndex;
    if (currentPara > 0) {
      jumpToIndex(state.paragraphs[currentPara - 1].globalStartIndex);
    }
  }

  Future<void> skipWords(int count) async {
    jumpToIndex(state.index + count);
  }

  Future<void> skipForward() async => skipWords(2);
  Future<void> skipBackward() async => skipWords(-2);

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

    final oldParaIndex = state.currentParagraphIndex;
    final nextIndex = (state.index + state.chunkSize).clamp(0, state.tokens.length - 1);
    state = state.copyWith(index: nextIndex);
    _wordsReadInCurrentSession += state.chunkSize;

    if (state.isAudioEnabled && state.currentParagraphIndex != oldParaIndex) {
      _tts.stop();
      _speakCurrentParagraph();
    }

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
