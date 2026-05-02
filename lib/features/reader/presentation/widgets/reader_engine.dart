import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../reader_controller.dart';
import 'reader_widgets.dart';

class ReaderEngineView extends ConsumerWidget {
  final ScrollController scrollController;
  final double fontSize;
  final Color orpColor;
  final String fontFamily;

  const ReaderEngineView({
    super.key,
    required this.scrollController,
    required this.fontSize,
    required this.orpColor,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerProvider);
    final controller = ref.read(readerProvider.notifier);
    
    if (state.tokens.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Top Context / Scroll View Area
        Expanded(
          child: Stack(
            children: [
              // Paragraph View (Used for both modes)
              _buildParagraphView(state, controller),

              // Bookmark Visual Pulse (Subtle overlay for current word)
              if (state.bookmarks.contains(state.index))
                Positioned(
                  top: 0, right: 0, left: 0, bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFFF3B3B).withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Eye Toggle Icon (Top Right) - Only in RSVP mode
              if (state.mode == ReadingMode.rsvp)
                Positioned(
                  top: 12,
                  right: 20,
                  child: GestureDetector(
                    onTap: controller.toggleContext,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        state.showContext ? LucideIcons.eye : LucideIcons.eyeOff,
                        color: state.showContext ? const Color(0xFFFF3B3B) : Colors.white30,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // RSVP Focal Area (Bottom part, only in RSVP mode)
        if (state.mode == ReadingMode.rsvp) ...[
          const SizedBox(height: 24),
          _buildRsvpFocalArea(state, controller),
          const SizedBox(height: 40),
        ],
      ],
    );
  }

  Widget _buildParagraphView(ReaderState state, ReaderController controller) {
    final isRsvp = state.mode == ReadingMode.rsvp;
    // In RSVP mode, we fade this based on showContext.
    // In Scroll mode, it's always fully visible and centered.
    final opacity = isRsvp ? (state.showContext ? 1.0 : 0.0) : 1.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView.builder(
            controller: scrollController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.paragraphs.length,
            padding: EdgeInsets.symmetric(
              vertical: constraints.maxHeight / 2 - 40,
              horizontal: 24,
            ),
            itemBuilder: (context, pIdx) {
              final paragraph = state.paragraphs[pIdx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.start,
                  children: paragraph.tokens.asMap().entries.map((entry) {
                    final tokenIdx = entry.key;
                    final token = entry.value;
                    final absoluteIdx = paragraph.globalStartIndex + tokenIdx;
                    final isHighlighted = absoluteIdx >= state.index && absoluteIdx < state.index + state.chunkSize;
                    final isBookmarked = state.bookmarks.contains(absoluteIdx);

                    return GestureDetector(
                      onTap: () => controller.toggleBookmark(absoluteIdx),
                      child: Stack(
                        children: [
                          WordView(
                            word: token.word,
                            orpIndex: token.orpIndex,
                            fontSize: 18,
                            orpColor: Colors.transparent,
                            fontFamily: fontFamily,
                            baseColor: Colors.white,
                            isHighlighted: isHighlighted,
                            isRsvp: false,
                          ),
                          if (isBookmarked)
                            Positioned(
                              top: 0, right: 0,
                              child: Container(
                                width: 4, height: 4,
                                decoration: const BoxDecoration(color: Color(0xFFFF3B3B), shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRsvpFocalArea(ReaderState state, ReaderController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const SizedBox(width: 24), // Reduced spacer
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, // Left aligned
              children: [
                _buildFocalBracket(),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.start, // Left aligned
                  spacing: 12,
                  runSpacing: 12,
                  children: state.current.map((token) => WordView(
                    word: token.word,
                    orpIndex: token.orpIndex,
                    fontSize: fontSize,
                    orpColor: orpColor,
                    fontFamily: fontFamily,
                    baseColor: Colors.white,
                    isRsvp: true, // Use ORP highlighting
                  )).toList(),
                ),
                const SizedBox(height: 32),
                _buildFocalBracket(),
              ],
            ),
          ),
          // Speaker Toggle
          GestureDetector(
            onTap: controller.toggleAudio,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: state.isAudioEnabled ? const Color(0xFFFF3B3B).withValues(alpha: 0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                state.isAudioEnabled ? LucideIcons.volume2 : LucideIcons.volumeX,
                color: state.isAudioEnabled ? const Color(0xFFFF3B3B) : Colors.white24,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocalBracket() {
    return Container(
      height: 2,
      width: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B3B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
