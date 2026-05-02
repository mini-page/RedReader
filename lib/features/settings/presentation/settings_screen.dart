import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../shared/models/app_settings.dart';
import '../../reader/presentation/reader_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const List<String> availableFonts = [
    'Inter',
    'Roboto',
    'Montserrat',
    'Open Sans',
    'Lexend',
    'Poppins',
    'Lato',
    'Source Sans 3',
    'Merriweather',
    'EB Garamond',
    'Playfair Display',
    'JetBrains Mono',
    'Space Grotesk',
    'Work Sans',
  ];

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _aboutTapCount = 0;
  final TextEditingController _geminiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final storage = ref.read(secureStorageProvider);
    final key = await storage.getGeminiKey();
    if (key != null) {
      setState(() {
        _geminiKeyController.text = key;
      });
    }
  }

  Future<void> _saveKey(String key) async {
    final storage = ref.read(secureStorageProvider);
    await storage.saveGeminiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gemini API Key saved securely.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;
    final sectionTitleColor = onSurface.withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: isDark
          ? (settings.showOledBlack ? Colors.black : const Color(0xFF121212))
          : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.lexend(
              color: onSurface, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildSectionHeader('READING', sectionTitleColor),
          _buildSettingsCard([
            _buildModernSlider(
              title: 'Default WPM',
              subtitle: '${settings.defaultWpm} words / min',
              value: settings.defaultWpm.toDouble(),
              min: 100,
              max: 1200,
              onChanged: (v) =>
                  controller.update(settings.copyWith(defaultWpm: v.round())),
              onAdjust: (delta) => controller.update(settings.copyWith(
                  defaultWpm: (settings.defaultWpm + delta).clamp(100, 1200))),
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildChunkSelector(
              currentValue: settings.defaultChunkSize,
              onSelect: (v) =>
                  controller.update(settings.copyWith(defaultChunkSize: v)),
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildModernSlider(
              title: 'Font size',
              subtitle: '${settings.fontSize.toInt()}pt',
              value: settings.fontSize,
              min: 24,
              max: 120,
              onChanged: (v) =>
                  controller.update(settings.copyWith(fontSize: v)),
              onAdjust: (delta) => controller.update(settings.copyWith(
                  fontSize: (settings.fontSize + (delta / 5)).clamp(24, 120))),
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildFontSelector(context, settings, controller, isDark),
            _buildDivider(isDark),
            _buildSwitchTile(
              title: 'Pause on punctuation',
              subtitle: 'Slows on commas, periods.',
              value: settings.pauseOnPunctuation,
              onChanged: (v) =>
                  controller.update(settings.copyWith(pauseOnPunctuation: v)),
              isDark: isDark,
            ),
          ], isDark),
          const SizedBox(height: 32),
          _buildSectionHeader('AI INTELLIGENCE', sectionTitleColor),
          _buildSettingsCard([
            _buildAiConfig(onSurface, isDark),
          ], isDark),
          const SizedBox(height: 32),
          _buildSectionHeader('APPEARANCE', sectionTitleColor),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Dark mode',
              subtitle: 'OLED true black',
              value: isDark,
              onChanged: (v) => controller.update(settings.copyWith(
                  themeMode: v ? ThemeMode.dark : ThemeMode.light)),
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildSwitchTile(
              title: 'Hide status bar',
              subtitle: 'Immersive mode',
              value: settings.hideStatusBar,
              onChanged: (v) =>
                  controller.update(settings.copyWith(hideStatusBar: v)),
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildSwitchTile(
              title: 'Show navigation labels',
              subtitle: 'Bottom bar text',
              value: settings.showNavLabels,
              onChanged: (v) =>
                  controller.update(settings.copyWith(showNavLabels: v)),
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildColorPicker(
              title: 'Focal letter color',
              subtitle: 'The letter your eye locks onto',
              currentValue: settings.orpColorValue,
              onSelect: (v) =>
                  controller.update(settings.copyWith(orpColorValue: v)),
              isDark: isDark,
            ),
          ], isDark),
          const SizedBox(height: 32),
          _buildSectionHeader('DATA', sectionTitleColor),
          _buildSettingsCard([
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: const Text('Clear library',
                  style: TextStyle(
                      color: Color(0xFFFF3B3B), fontWeight: FontWeight.bold)),
              subtitle: FutureBuilder<int>(
                future: ref
                    .read(sessionRepositoryProvider)
                    .all()
                    .then((value) => value.length),
                builder: (context, snapshot) {
                  return Text('${snapshot.data ?? 0} sessions stored',
                      style:
                          TextStyle(color: onSurface.withValues(alpha: 0.4)));
                },
              ),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFFF3B3B).withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.delete_sweep_rounded,
                    color: Color(0xFFFF3B3B), size: 20),
              ),
              onTap: () => _showClearDialog(context, ref),
            ),
            _buildDivider(isDark),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: const Text('Reset Everything',
                  style: TextStyle(
                      color: Color(0xFFFF3B3B), fontWeight: FontWeight.bold)),
              subtitle: Text('Restore app to initial state',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.4))),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFFF3B3B).withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.refresh_rounded,
                    color: Color(0xFFFF3B3B), size: 20),
              ),
              onTap: () => _showResetDialog(context, ref),
            ),
          ], isDark),
          const SizedBox(height: 32),
          _buildSectionHeader('ABOUT', sectionTitleColor),
          _buildAboutCard(onSurface, isDark),
          const SizedBox(height: 48),
          Center(
            child: Text(
              'iReader · v1.0 · Built for focus',
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.2),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAiConfig(Color onSurface, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Color(0xFFFF3B3B), size: 18),
              const SizedBox(width: 8),
              Text('Gemini API Key',
                  style: TextStyle(
                      color: onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Required for summary & simplification',
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _geminiKeyController,
              obscureText: true,
              style: TextStyle(color: onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter your API key...',
                hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.3)),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save_rounded, color: Color(0xFFFF3B3B)),
                  onPressed: () => _saveKey(_geminiKeyController.text.trim()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8))
              ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02));
  }

  Widget _buildCircleButton(
      BuildContext context, IconData icon, VoidCallback onTap, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildModernSlider({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ValueChanged<int> onAdjust,
    required bool isDark,
  }) {
    final onSurface = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: onSurface, fontSize: 17, fontWeight: FontWeight.bold)),
          Text(subtitle,
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle_outline_rounded,
                    color: onSurface.withValues(alpha: 0.2)),
                onPressed: () => onAdjust(-25),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 12,
                    activeTrackColor: isDark ? Colors.white : Colors.black,
                    inactiveTrackColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    thumbColor: isDark ? Colors.white : Colors.black,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10, elevation: 4),
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
                icon: Icon(Icons.add_circle_outline_rounded,
                    color: onSurface.withValues(alpha: 0.2)),
                onPressed: () => onAdjust(25),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChunkSelector({
    required int currentValue,
    required Function(int) onSelect,
    required bool isDark,
  }) {
    final onSurface = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chunk size',
              style: TextStyle(
                  color: onSurface, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('Words shown per flash',
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [1, 2, 3, 4, 5].map((s) {
                final isSel = s == currentValue;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => onSelect(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: isSel
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$s word${s > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: isSel
                              ? (isDark ? Colors.black : Colors.white)
                              : onSurface.withValues(alpha: 0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSelector(BuildContext context, AppSettings settings,
      SettingsController controller, bool isDark) {
    final onSurface = isDark ? Colors.white : Colors.black;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: () => _showFontPicker(context, settings, controller),
      title: Text('Font style',
          style: TextStyle(
              color: onSurface, fontSize: 17, fontWeight: FontWeight.bold)),
      subtitle: Text(settings.fontFamily,
          style:
              TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 13)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: onSurface.withValues(alpha: 0.2)),
    );
  }

  void _showFontPicker(BuildContext context, AppSettings settings,
      SettingsController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: TextField(
                    autofocus: false,
                    style: TextStyle(color: onSurface),
                    onChanged: (v) => setModalState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search fonts',
                      prefixIcon: Icon(Icons.search_rounded,
                          color: onSurface.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: onSurface.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: SettingsScreen.availableFonts.length,
                    itemBuilder: (context, i) {
                      final font = SettingsScreen.availableFonts[i];
                      final isSelected = settings.fontFamily == font;
                      return ListTile(
                        onTap: () {
                          controller
                              .update(settings.copyWith(fontFamily: font));
                          Navigator.pop(context);
                        },
                        title: Text(font,
                            style: GoogleFonts.getFont(font,
                                color: onSurface, fontSize: 16)),
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
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    final onSurface = isDark ? Colors.white : Colors.black;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(title,
          style: TextStyle(
              color: onSurface, fontSize: 17, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          style:
              TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 13)),
      trailing: Transform.scale(
        scale: 0.9,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbImage: null,
          activeTrackColor: const Color(0xFFFF3B3B),
        ),
      ),
    );
  }

  Widget _buildColorPicker({
    required String title,
    required String subtitle,
    required int currentValue,
    required Function(int) onSelect,
    required bool isDark,
  }) {
    final onSurface = isDark ? Colors.white : Colors.black;
    final colors = [
      0xFFFF3B3B,
      0xFFFF9500,
      0xFFFFCC00,
      0xFF4CD964,
      0xFF007AFF,
      0xFFAF52DE
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: onSurface, fontSize: 17, fontWeight: FontWeight.bold)),
          Text(subtitle,
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: colors.map((colorVal) {
              final isSelected = colorVal == currentValue;
              return GestureDetector(
                onTap: () => onSelect(colorVal),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(colorVal),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isSelected ? onSurface : Colors.transparent,
                        width: 2),
                  ),
                  child: isSelected
                      ? Icon(Icons.check_rounded,
                          color: Colors.white.withValues(alpha: 0.9), size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(Color onSurface, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _aboutTapCount++;
          if (_aboutTapCount >= 7) {
            _aboutTapCount = 0;
            context.push('/love-gallery');
          }
        });
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8))
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/shalu.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.black),
              ),
            ),
            // Dark Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.4)
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFF3B3B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.favorite_rounded,
                            color: Color(0xFFFF3B3B), size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dedicated to Shalu',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text('By Raghavan S ❤️',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'I built iReader because my loved one, Shalu, would often get lost in long texts and lose her place while reading. This side project was my way of helping her focus.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'At her request, I’ve opened this application to everyone who seeks a more distilled and focused reading experience.',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset Everything?'),
        content: const Text(
            'This will clear your entire library and reset all settings to their initial state. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B3B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await ref.read(sessionRepositoryProvider).clearAll();
              await ref.read(settingsProvider.notifier).resetAll();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/splash');
              }
            },
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear Library?'),
        content: const Text(
            'This will delete all saved sessions. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B3B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await ref.read(sessionRepositoryProvider).clearAll();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
