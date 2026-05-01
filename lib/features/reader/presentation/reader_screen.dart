import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:red_reader/shared/models/app_settings.dart';
import 'package:red_reader/features/settings/presentation/settings_controller.dart';
import 'package:red_reader/features/settings/presentation/settings_screen.dart';
import 'package:red_reader/features/reader/presentation/reader_controller.dart';
import 'package:red_reader/core/services/ai_service.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _showSettingsPopup = false;
  final ScrollController _scrollController = ScrollController();
  final double _itemHeight = 80.0;

  void _toggleSettings() {
    setState(() {
      _showSettingsPopup = !_showSettingsPopup;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runTransform(Future<String> Function(AIProvider p) action) async {
    final controller = ref.read(readerProvider.notifier);
    final error = await controller.transform(action);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFFF3B3B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ReaderState>(readerProvider, (previous, next) {
      if (previous?.isCompleted != true && next.isCompleted) {
        _showCompletionDialog(next);
      }
      if (next.index != previous?.index) {
        if (next.mode == ReadingMode.scroll) {
          _scrollToCurrent(next.index);
        } else if (next.mode == ReadingMode.rsvp || next.mode == ReadingMode.audio) {
          _scrollToContextWord(next.index);
        }
      }
    });

    final state = ref.watch(readerProvider);
    final controller = ref.read(readerProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final isPlaying = state.isPlaying;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Bar
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (isPlaying && state.mode == ReadingMode.rsvp) ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: (isPlaying && state.mode == ReadingMode.rsvp),
                    child: _buildAppBar(context, state),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (isPlaying) {
                        controller.pause();
                      } else {
                        if (_showSettingsPopup) {
                          setState(() => _showSettingsPopup = false);
                        } else {
                          controller.play();
                        }
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: _buildMainView(state, settings),
                  ),
                ),
                // Bottom Controls
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (isPlaying && state.mode == ReadingMode.rsvp) ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: (isPlaying && state.mode == ReadingMode.rsvp),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeSelector(state, controller),
                        const SizedBox(height: 16),
                        _buildBottomControls(state, controller),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_showSettingsPopup && !isPlaying)
              Positioned(
                top: 70,
                right: 16,
                child: _buildQuickSettingsPopup(context, ref),
              ),

            if (state.isLoadingAI)
              Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFFFF3B3B),
                        strokeWidth: 4,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'AI IS THINKING...',
                        style: GoogleFonts.lexend(
                          color: const Color(0xFFFF3B3B),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Transforming your reading experience',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _scrollToContextWord(int index) {
    if (!_scrollController.hasClients) return;
    
    final viewportHeight = _scrollController.position.viewportDimension;
    const wordsPerLine = 6;
    final line = (index / wordsPerLine).floor();
    const lineHeight = 44.0; 
    
    final offset = (line * lineHeight) - (viewportHeight / 2) + (lineHeight / 2);
    
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<List<T>> _chunkList<T>(List<T> list, int size) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return chunks;
  }

  void _scrollToCurrent(int index) {
    if (!_scrollController.hasClients) return;
    final viewportHeight = _scrollController.position.viewportDimension;
    final offset = (index * _itemHeight) - (viewportHeight / 2) + (_itemHeight / 2);
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildMainView(ReaderState state, AppSettings settings) {
    switch (state.mode) {
      case ReadingMode.rsvp:
      case ReadingMode.audio:
        return _buildRsvpView(state, settings.fontSize,
            Color(settings.orpColorValue), settings.fontFamily);
      case ReadingMode.scroll:
        return _buildScrollView(state, settings);
    }
  }

  Widget _buildRsvpView(
      ReaderState state, double fontSize, Color orpColor, String fontFamily) {
    final currentTokens = state.current;
    if (currentTokens.isEmpty) return const SizedBox.shrink();

    const wordsPerLine = 6;
    final contextLines = _chunkList(state.tokens, wordsPerLine);

    return Column(
      children: [
        // 1. Top Context View (Line-based ListView for perfect centering)
        Expanded(
          flex: 5,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListView.builder(
                controller: _scrollController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contextLines.length,
                itemExtent: 44.0,
                padding: EdgeInsets.symmetric(vertical: constraints.maxHeight / 2 - 22),
                itemBuilder: (context, lineIdx) {
                  final lineTokens = contextLines[lineIdx];
                  return Center(
                    child: Wrap(
                      spacing: 4,
                      alignment: WrapAlignment.center,
                      children: lineTokens.asMap().entries.map((entry) {
                        final tokenIdxInLine = entry.key;
                        final token = entry.value;
                        final absoluteIdx = (lineIdx * wordsPerLine) + tokenIdxInLine;
                        final isCurrent = absoluteIdx == state.index;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCurrent ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            token.word,
                            style: GoogleFonts.getFont(
                              fontFamily,
                              fontSize: 16,
                              color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.3),
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w400,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            }
          ),
        ),

        // Divider/Space
        const SizedBox(height: 40),

        // 2. Central Focal RSVP Area
        Expanded(
          flex: 4,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    height: 2,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B3B).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(1),
                    )),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: currentTokens
                      .map((token) => _WordView(
                            word: token.word,
                            orpIndex: token.orpIndex,
                            fontSize: fontSize,
                            orpColor: orpColor,
                            fontFamily: fontFamily,
                            baseColor: Colors.white,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 32),
                Container(
                    height: 2,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B3B).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(1),
                    )),
                
                if (state.mode == ReadingMode.audio) ...[
                  const SizedBox(height: 40),
                  const Icon(LucideIcons.volume2, color: Color(0xFFFF3B3B), size: 32),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollView(ReaderState state, AppSettings settings) {
    final viewportHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        // Center Focus Background Highlight
        Center(
          child: Container(
            height: _itemHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        ListView.builder(
          controller: _scrollController,
          physics: const NeverScrollableScrollPhysics(), // Scroll managed by controller index
          itemCount: state.tokens.length,
          itemExtent: _itemHeight,
          padding: EdgeInsets.symmetric(
              vertical: (viewportHeight / 2) - (_itemHeight / 2)),
          itemBuilder: (context, index) {
            final isCurrent = index == state.index;
            final token = state.tokens[index];
            
            // Calculate distance from center to fade out words
            final distance = (index - state.index).abs();
            final opacity = isCurrent ? 1.0 : (0.2 / (distance + 1)).clamp(0.02, 0.2);
            final scale = isCurrent ? 1.0 : (1.0 - (distance * 0.05)).clamp(0.7, 1.0);

            return Center(
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: _WordView(
                    word: token.word,
                    orpIndex: token.orpIndex,
                    fontSize: settings.fontSize,
                    orpColor: isCurrent ? Color(settings.orpColorValue) : Colors.transparent,
                    fontFamily: settings.fontFamily,
                    baseColor: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        // Visual Focus Brackets (Red)
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 2, width: 40, decoration: BoxDecoration(color: const Color(0xFFFF3B3B), borderRadius: BorderRadius.circular(1))),
              SizedBox(height: _itemHeight),
              Container(height: 2, width: 40, decoration: BoxDecoration(color: const Color(0xFFFF3B3B), borderRadius: BorderRadius.circular(1))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(ReaderState state, ReaderController controller) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeButton(
              icon: LucideIcons.zap,
              label: 'RSVP',
              isSelected: state.mode == ReadingMode.rsvp,
              onTap: () => controller.setMode(ReadingMode.rsvp),
            ),
            _ModeButton(
              icon: LucideIcons.alignLeft,
              label: 'Scroll',
              isSelected: state.mode == ReadingMode.scroll,
              onTap: () => controller.setMode(ReadingMode.scroll),
            ),
            _ModeButton(
              icon: LucideIcons.headphones,
              label: 'Audio',
              isSelected: state.mode == ReadingMode.audio,
              onTap: () => controller.setMode(ReadingMode.audio),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(ReaderState state) {
    final totalWords = state.tokens.length;
    final normalTimeMins = totalWords / 250;
    final yourTimeMins = totalWords / state.wpm;
    final savedMins = (normalTimeMins - yourTimeMins).clamp(0, double.infinity);

    final settings = ref.read(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Session Complete!',
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: Color(0xFFFF3B3B), size: 48),
            const SizedBox(height: 16),
            Text('You read $totalWords words at ${state.wpm} WPM.',
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 8),
            Text('Time saved vs average: ${savedMins.toStringAsFixed(1)} mins!',
                style: const TextStyle(
                    color: Color(0xFFFF3B3B),
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B3B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(context); // close dialog
              context.pop(); // exit reader
            },
            child: const Text('Awesome'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ReaderState state) {
    final progressPercent = (state.progress * 100).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(Icons.arrow_back_rounded, () => context.pop()),
          Expanded(
            child: Column(
              children: [
                Text(
                  state.title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${state.index} / ${state.tokens.length} • $progressPercent%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildCircleButton(Icons.tune_rounded, _toggleSettings,
              isSelected: _showSettingsPopup),
          const SizedBox(width: 8),
          _buildCircleButton(LucideIcons.sparkles, () => _showAiMenu(context, ref)),
        ],
      ),
    );
  }

  void _showAiMenu(BuildContext context, WidgetRef ref) async {
    final aiService = ref.read(aiServiceProvider);
    final provider = await aiService.getProvider();
    final state = ref.read(readerProvider);

    if (!context.mounted) return;

    if (provider == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI Not Configured'),
          content: const Text('Please add your Gemini API Key in Settings to use AI features.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('AI TRANSFORMATIONS', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _AiActionTile(
              icon: LucideIcons.fileText,
              title: 'Summarize',
              subtitle: 'Condense into key points',
              onTap: () {
                Navigator.pop(context);
                _runTransform((p) => p.summarize(state.content));
              },
            ),
            _AiActionTile(
              icon: LucideIcons.wand2,
              title: 'Simplify',
              subtitle: 'Make it easier to understand',
              onTap: () {
                Navigator.pop(context);
                _runTransform((p) => p.simplify(state.content));
              },
            ),
            _AiActionTile(
              icon: LucideIcons.languages,
              title: 'Translate',
              subtitle: 'Translate to another language',
              onTap: () {
                Navigator.pop(context);
                _showLanguagePicker(context, state);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, ReaderState state) {
    final languages = ['Spanish', 'French', 'German', 'Chinese', 'Japanese', 'Hindi'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: languages.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(languages[i], style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _runTransform((p) => p.translate(state.content, languages[i]));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap,
      {bool isSelected = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon,
            color: isSelected ? Colors.black : Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildBottomControls(ReaderState state, ReaderController controller) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.first_page_rounded,
                      color: Colors.white, size: 28),
                  onPressed: controller.previous),
              IconButton(
                  icon: const Icon(Icons.fast_rewind_rounded,
                      color: Colors.white, size: 28),
                  onPressed: controller.skipBackward),
              GestureDetector(
                onTap: state.isPlaying ? controller.pause : controller.play,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 5),
                    ],
                  ),
                  child: Icon(
                    state.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 48,
                  ),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.fast_forward_rounded,
                      color: Colors.white, size: 28),
                  onPressed: controller.skipForward),
              IconButton(
                  icon: const Icon(Icons.last_page_rounded,
                      color: Colors.white, size: 28),
                  onPressed: controller.next),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: state.progress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B3B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettingsPopup(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.read(settingsProvider.notifier);
    final readerCtrl = ref.read(readerProvider.notifier);
    final readerState = ref.watch(readerProvider);

    final size = MediaQuery.of(context).size;
    final width = size.width * (3 / 4);
    final height = size.height * (2 / 3);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          alignment: Alignment.topRight,
          child: Opacity(
            opacity: val.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 50,
                offset: const Offset(0, 20)),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  _buildPopupSectionTitle('CHUNKS'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [1, 2, 3, 4, 5].map((s) {
                        final isSel = readerState.chunkSize == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => readerCtrl.setChunkSize(s),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text('$s word${s > 1 ? 's' : ''}',
                                  style: TextStyle(
                                      color: isSel
                                          ? Colors.black
                                          : Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPopupSectionTitle('WPM (${readerState.wpm})'),
                  _buildThickSlider(
                    value: readerState.wpm.toDouble(),
                    min: 100,
                    max: 1200,
                    onChanged: (v) => readerCtrl.setWpm(v),
                    onAdjust: (delta) =>
                        readerCtrl.setWpm((readerState.wpm + delta).toDouble()),
                  ),
                  const SizedBox(height: 24),
                  _buildPopupSectionTitle(
                      'FONT SIZE (${settings.fontSize.toInt()}pt)'),
                  _buildThickSlider(
                    value: settings.fontSize,
                    min: 24,
                    max: 120,
                    onChanged: (v) =>
                        settingsCtrl.update(settings.copyWith(fontSize: v)),
                    onAdjust: (delta) => settingsCtrl.update(settings.copyWith(
                        fontSize: settings.fontSize + (delta / 5))),
                  ),
                  const SizedBox(height: 24),
                  _buildPopupSectionTitle('FONT STYLE'),
                  const SizedBox(height: 8),
                  _buildPopupFontSelector(context, settings, settingsCtrl),
                  const SizedBox(height: 24),
                  _buildPopupSectionTitle('FOCAL COLOR'),
                  const SizedBox(height: 12),
                  _buildPopupColorPicker(settings, settingsCtrl),
                  const SizedBox(height: 24),
                  _buildPopupSectionTitle('OPTIONS'),
                  _buildPopupToggle(
                    'Pause on Punctuation',
                    settings.pauseOnPunctuation,
                    (v) => settingsCtrl
                        .update(settings.copyWith(pauseOnPunctuation: v)),
                  ),
                  _buildPopupToggle(
                    'Dark Mode',
                    settings.themeMode == ThemeMode.dark,
                    (v) => settingsCtrl.update(settings.copyWith(
                        themeMode: v ? ThemeMode.dark : ThemeMode.light)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2),
    );
  }

  Widget _buildThickSlider({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ValueChanged<int> onAdjust,
  }) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.remove_circle_outline_rounded,
              color: Colors.white.withValues(alpha: 0.3), size: 20),
          onPressed: () => onAdjust(-25),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 10,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8, elevation: 4),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.add_circle_outline_rounded,
              color: Colors.white.withValues(alpha: 0.3), size: 20),
          onPressed: () => onAdjust(25),
        ),
      ],
    );
  }

  Widget _buildPopupToggle(
      String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      title: Text(title,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500)),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFFFF3B3B),
        ),
      ),
    );
  }

  Widget _buildPopupFontSelector(
      BuildContext context, AppSettings settings, SettingsController ctrl) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2))),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    itemCount: SettingsScreen.availableFonts.length,
                    itemBuilder: (context, i) {
                      final font = SettingsScreen.availableFonts[i];
                      final isSelected = settings.fontFamily == font;
                      return ListTile(
                        onTap: () {
                          ctrl.update(settings.copyWith(fontFamily: font));
                          Navigator.pop(context);
                        },
                        title: Text(font,
                            style: GoogleFonts.getFont(font,
                                color: Colors.white, fontSize: 16)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFFFF3B3B))
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(settings.fontFamily,
                style: GoogleFonts.getFont(settings.fontFamily,
                    color: Colors.white, fontSize: 14)),
            Icon(Icons.unfold_more_rounded,
                color: Colors.white.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupColorPicker(AppSettings settings, SettingsController ctrl) {
    final colors = [
      0xFFFF3B3B,
      0xFFFF9500,
      0xFFFFCC00,
      0xFF4CD964,
      0xFF007AFF,
      0xFFAF52DE
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: colors.map((c) {
        final isSel = settings.orpColorValue == c;
        return GestureDetector(
          onTap: () => ctrl.update(settings.copyWith(orpColorValue: c)),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSel ? Colors.white : Colors.transparent, width: 2),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AiActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AiActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: const Color(0xFFFF3B3B), size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF3B3B) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 18),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WordView extends StatelessWidget {
  final String word;
  final int orpIndex;
  final double fontSize;
  final Color orpColor;
  final String fontFamily;
  final Color baseColor;

  const _WordView(
      {required this.word,
      required this.orpIndex,
      required this.fontSize,
      required this.orpColor,
      required this.fontFamily,
      required this.baseColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(word.length, (i) {
        final isOrp = i == orpIndex;
        return Text(
          word[i],
          style: GoogleFonts.getFont(
            fontFamily,
            fontSize: fontSize,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: isOrp && orpColor != Colors.transparent ? orpColor : baseColor,
          ),
        );
      }),
    );
  }
}
