import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:red_reader/features/settings/presentation/settings_controller.dart';
import 'package:red_reader/features/settings/presentation/settings_screen.dart';
import 'package:red_reader/features/reader/presentation/reader_controller.dart';
import 'package:red_reader/core/services/ai_service.dart';

class QuickSettingsPopup extends ConsumerWidget {
  final Future<void> Function(Future<String> Function(AIProvider p) action) onRunTransform;

  const QuickSettingsPopup({super.key, required this.onRunTransform});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.read(settingsProvider.notifier);
    final readerCtrl = ref.read(readerProvider.notifier);
    final readerState = ref.watch(readerProvider);

    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

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
          color: cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.1),
                blurRadius: 50,
                offset: const Offset(0, 20)),
          ],
          border: Border.all(color: onSurface.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  _buildSectionTitle('AI ACTIONS', onSurface),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildAiActionItem(
                          icon: LucideIcons.fileText,
                          label: 'Summarize',
                          onTap: () => onRunTransform((p) => p.summarize(readerState.content)),
                          onSurface: onSurface,
                        ),
                        _buildAiActionItem(
                          icon: LucideIcons.wand2,
                          label: 'Simplify',
                          onTap: () => onRunTransform((p) => p.simplify(readerState.content)),
                          onSurface: onSurface,
                        ),
                        _buildAiActionItem(
                          icon: LucideIcons.languages,
                          label: 'Translate',
                          onTap: () => _showLanguagePicker(context, readerState, onSurface, cardColor),
                          onSurface: onSurface,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('READING MODES', onSurface),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildModeToggle(
                        icon: LucideIcons.zap,
                        label: 'RSVP',
                        isSelected: readerState.mode == ReadingMode.rsvp,
                        onTap: () => readerCtrl.setMode(ReadingMode.rsvp),
                        isDark: isDark,
                        onSurface: onSurface,
                      ),
                      const SizedBox(width: 12),
                      _buildModeToggle(
                        icon: LucideIcons.alignLeft,
                        label: 'Scroll',
                        isSelected: readerState.mode == ReadingMode.scroll,
                        onTap: () => readerCtrl.setMode(ReadingMode.scroll),
                        isDark: isDark,
                        onSurface: onSurface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('CHUNKS', onSurface),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSel ? onSurface : onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text("$s word${s > 1 ? "s" : ""}",
                                  style: TextStyle(
                                      color: isSel ? (isDark ? Colors.black : Colors.white) : onSurface.withValues(alpha: 0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('WPM (${readerState.wpm})', onSurface),
                  _buildThickSlider(
                    value: readerState.wpm.toDouble(),
                    min: 100,
                    max: 1200,
                    onChanged: (v) => readerCtrl.setWpm(v),
                    onAdjust: (delta) => readerCtrl.setWpm((readerState.wpm + delta).toDouble()),
                    onSurface: onSurface,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('FONT SIZE (${settings.fontSize.toInt()}pt)', onSurface),
                  _buildThickSlider(
                    value: settings.fontSize,
                    min: 24,
                    max: 120,
                    onChanged: (v) => settingsCtrl.update(settings.copyWith(fontSize: v)),
                    onAdjust: (delta) => settingsCtrl.update(settings.copyWith(fontSize: settings.fontSize + (delta / 5))),
                    onSurface: onSurface,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('FONT STYLE', onSurface),
                  const SizedBox(height: 8),
                  _buildFontSelector(context, settings, settingsCtrl, onSurface, cardColor),
                  const SizedBox(height: 24),
                  _buildSectionTitle('FOCAL COLOR', onSurface),
                  const SizedBox(height: 12),
                  _buildColorPicker(settings, settingsCtrl, onSurface),
                  const SizedBox(height: 24),
                  _buildSectionTitle('OPTIONS', onSurface),
                  _buildToggle(
                    'Pause on Punctuation',
                    settings.pauseOnPunctuation,
                    (v) => settingsCtrl.update(settings.copyWith(pauseOnPunctuation: v)),
                    onSurface: onSurface,
                  ),
                  _buildToggle(
                    'Dark Mode',
                    settings.themeMode == ThemeMode.dark,
                    (v) => settingsCtrl.update(settings.copyWith(themeMode: v ? ThemeMode.dark : ThemeMode.light)),
                    onSurface: onSurface,
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

  Widget _buildAiActionItem({required IconData icon, required String label, required VoidCallback onTap, required Color onSurface}) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: onSurface.withValues(alpha: 0.05)),
              ),
              child: Icon(icon, color: const Color(0xFFFF3B3B), size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle({required IconData icon, required String label, required bool isSelected, required VoidCallback onTap, required bool isDark, required Color onSurface}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? onSurface : onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? (isDark ? Colors.black : Colors.white) : onSurface.withValues(alpha: 0.38), size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? (isDark ? Colors.black : Colors.white) : onSurface.withValues(alpha: 0.38), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color onSurface) {
    return Text(
      title,
      style: TextStyle(
          color: onSurface.withValues(alpha: 0.3),
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
    required Color onSurface,
    required bool isDark,
  }) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.remove_circle_outline_rounded, color: onSurface.withValues(alpha: 0.3), size: 20),
          onPressed: () => onAdjust(-25),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 10,
              activeTrackColor: onSurface,
              inactiveTrackColor: onSurface.withValues(alpha: 0.05),
              thumbColor: onSurface,
              overlayColor: onSurface.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 4),
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
          icon: Icon(Icons.add_circle_outline_rounded, color: onSurface.withValues(alpha: 0.3), size: 20),
          onPressed: () => onAdjust(25),
        ),
      ],
    );
  }

  Widget _buildToggle(String title, bool value, ValueChanged<bool> onChanged, {required Color onSurface}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      title: Text(title, style: TextStyle(color: onSurface.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
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

  Widget _buildFontSelector(BuildContext context, dynamic settings, SettingsController ctrl, Color onSurface, Color cardColor) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: SettingsScreen.availableFonts.length,
                    itemBuilder: (context, i) {
                      final font = SettingsScreen.availableFonts[i];
                      final isSelected = settings.fontFamily == font;
                      return ListTile(
                        onTap: () {
                          ctrl.update(settings.copyWith(fontFamily: font));
                          Navigator.pop(context);
                        },
                        title: Text(font, style: GoogleFonts.getFont(font, color: onSurface, fontSize: 16)),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF3B3B)) : null,
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
          color: onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(settings.fontFamily, style: GoogleFonts.getFont(settings.fontFamily, color: onSurface, fontSize: 14)),
            Icon(Icons.unfold_more_rounded, color: onSurface.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(dynamic settings, SettingsController ctrl, Color onSurface) {
    final colors = [0xFFFF3B3B, 0xFFFF9500, 0xFFFFCC00, 0xFF4CD964, 0xFF007AFF, 0xFFAF52DE];
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
              border: Border.all(color: isSel ? onSurface : Colors.transparent, width: 2),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showLanguagePicker(BuildContext context, ReaderState state, Color onSurface, Color cardColor) {
    final languages = ['Spanish', 'French', 'German', 'Chinese', 'Japanese', 'Hindi'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: languages.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(languages[i], style: TextStyle(color: onSurface)),
            onTap: () {
              Navigator.pop(context);
              onRunTransform((p) => p.translate(state.content, languages[i]));
            },
          ),
        ),
      ),
    );
  }
}
