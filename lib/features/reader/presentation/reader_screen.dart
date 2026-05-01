import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/models/app_settings.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import 'reader_controller.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _showSettingsPopup = false;

  void _toggleSettings() {
    setState(() {
      _showSettingsPopup = !_showSettingsPopup;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ReaderState>(readerProvider, (previous, next) {
      if (previous?.isCompleted != true && next.isCompleted) {
        _showCompletionDialog(next);
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
            // Main Reader View / Interaction Layer
            GestureDetector(
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
              child: Column(
                children: [
                  // Top Bar - Hidden when playing
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isPlaying ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: isPlaying,
                      child: _buildAppBar(context, state),
                    ),
                  ),
                  const Spacer(),
                  // The Reading View
                  _buildReaderView(state, settings.fontSize,
                      Color(settings.orpColorValue), settings.fontFamily),
                  const Spacer(),
                  // Bottom Controls - Hidden when playing
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isPlaying ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: isPlaying,
                      child: _buildBottomControls(state, controller),
                    ),
                  ),
                ],
              ),
            ),

            // Settings Popup Overlay
            if (_showSettingsPopup && !isPlaying)
              Positioned(
                top: 70,
                right: 16,
                child: _buildQuickSettingsPopup(context, ref),
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
    final progressPercent = state.tokens.isEmpty
        ? 0
        : (state.index / state.tokens.length * 100).toInt();
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
        ],
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

  Widget _buildReaderView(
      ReaderState state, double fontSize, Color orpColor, String fontFamily) {
    final currentTokens = state.current;
    if (currentTokens.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              height: 12, width: 2, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
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
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Container(
              height: 12, width: 2, color: Colors.white.withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ReaderState state, ReaderController controller) {
    final progress = state.tokens.isEmpty
        ? 0.0
        : (state.index / state.tokens.length).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
              widthFactor: progress,
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

class _WordView extends StatelessWidget {
  final String word;
  final int orpIndex;
  final double fontSize;
  final Color orpColor;
  final String fontFamily;

  const _WordView(
      {required this.word,
      required this.orpIndex,
      required this.fontSize,
      required this.orpColor,
      required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(word.length, (i) {
        return Text(
          word[i],
          style: GoogleFonts.getFont(
            fontFamily,
            fontSize: fontSize,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: i == orpIndex ? orpColor : Colors.white,
          ),
        );
      }),
    );
  }
}
