import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:red_reader/features/settings/presentation/settings_controller.dart';
import 'package:red_reader/features/reader/presentation/reader_controller.dart';
import 'package:red_reader/features/reader/presentation/widgets/reader_layout.dart';
import 'package:red_reader/features/reader/presentation/widgets/reader_engine.dart';
import 'package:red_reader/features/reader/presentation/widgets/quick_settings_popup.dart';
import 'package:red_reader/core/services/ai_service.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _showSettingsPopup = false;
  final ScrollController _scrollController = ScrollController();

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

  void _showThemedSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message, 
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black, 
            fontWeight: FontWeight.bold,
            fontSize: 13,
          )
        ),
        backgroundColor: isError 
            ? const Color(0xFFFF3B3B) 
            : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 10,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _runTransform(Future<String> Function(AIProvider p) action) async {
    final controller = ref.read(readerProvider.notifier);
    final error = await controller.transform(action);
    if (error != null && mounted) {
      _showThemedSnackBar(error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerProvider);
    final controller = ref.read(readerProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final isPlaying = state.isPlaying;

    ref.listen<ReaderState>(readerProvider, (previous, next) {
      if (previous?.isCompleted != true && next.isCompleted) {
        _showCompletionDialog(next);
      }
      if (next.index != previous?.index) {
        _scrollToCurrent(next.index);
      }
    });

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF6F6F6),
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
                    child: ReaderAppBar(
                      onToggleSettings: _toggleSettings,
                      isSettingsOpen: _showSettingsPopup,
                    ),
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
                    child: ReaderEngineView(
                      scrollController: _scrollController,
                      fontSize: settings.fontSize,
                      orpColor: Color(settings.orpColorValue),
                      fontFamily: settings.fontFamily,
                    ),
                  ),
                ),
                // Bottom Controls
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (isPlaying && state.mode == ReadingMode.rsvp) ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: (isPlaying && state.mode == ReadingMode.rsvp),
                    child: const ReaderBottomControls(),
                  ),
                ),
              ],
            ),

            if (_showSettingsPopup && !isPlaying)
              Positioned(
                top: 70,
                right: 16,
                child: QuickSettingsPopup(onRunTransform: _runTransform),
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

  void _scrollToCurrent(int index) {
    if (!_scrollController.hasClients) return;
    
    final viewportHeight = _scrollController.position.viewportDimension;
    const wordsPerLine = 8;
    final line = (index / wordsPerLine).floor();
    const lineHeight = 44.0; 
    
    final offset = (line * lineHeight) - (viewportHeight / 2) + (lineHeight / 2);
    
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
}
