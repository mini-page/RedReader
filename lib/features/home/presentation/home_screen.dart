import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:red_reader/core/constants/demo_text.dart';
import 'package:red_reader/features/reader/presentation/reader_controller.dart';
import 'package:red_reader/features/settings/presentation/settings_controller.dart';
import 'package:red_reader/features/home/data/sessions_provider.dart';
import 'package:red_reader/features/home/presentation/widgets/home_widgets.dart';
import 'package:red_reader/shared/widgets/reading_action_mixin.dart';
import 'package:red_reader/features/bookmarks/presentation/widgets/bookmarks_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with ReadingActionMixin {
  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark
          ? (settings.showOledBlack ? Colors.black : const Color(0xFF121212))
          : const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: isDark
                    ? (settings.showOledBlack ? Colors.black : const Color(0xFF121212))
                    : const Color(0xFFF6F6F6),
                elevation: 0,
                pinned: true,
                centerTitle: false,
                titleSpacing: 20,
                toolbarHeight: 72,
                title: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'i',
                        style: TextStyle(color: Color(0xFFFF3B3B)),
                      ),
                      TextSpan(
                        text: 'Reader',
                        style: TextStyle(color: onSurface),
                      ),
                    ],
                  ),
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: _buildCircleIconButton(
                      isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                      onSurface,
                      () => ref.read(settingsProvider.notifier).update(settings.copyWith(themeMode: isDark ? ThemeMode.light : ThemeMode.dark)),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: _buildActionSlider(onSurface, isDark),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                sliver: sessionsAsync.when(
                  data: (sessions) => SliverList(
                    delegate: SliverChildListDelegate([
                      if (sessions.isNotEmpty) ...[
                        ContinueReadingCard(
                          session: sessions.first,
                          onSurface: onSurface,
                          isDark: isDark,
                          onPlay: () async {
                            await ref.read(readerProvider.notifier).loadSession(sessions.first);
                            if (mounted) {
                              await context.push('/reader');
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  ref.read(sessionsProvider.notifier).refresh();
                                }
                              });
                            }
                          },                        ),
                        const SizedBox(height: 32),
                      ],
                      const BookmarksSection(),
                      const SizedBox(height: 32),
                      if (!settings.hasRunDemo) ...[
                        _buildDemoBar(onSurface, isDark),
                        const SizedBox(height: 40),
                      ],
                      const SizedBox(height: 100),
                    ]),
                  ),
                  loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
                ),
              ),
            ],
          ),
          if (isProcessing) ProcessingOverlay(label: processingLabel),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon, Color onSurface, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(icon, color: onSurface.withValues(alpha: 0.8), size: 20),
      ),
    );
  }

  Widget _buildActionSlider(Color onSurface, bool isDark) {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          HomeActionCard(title: 'Paste text', subtitle: 'Direct edit', icon: LucideIcons.clipboardSignature, iconBg: const Color(0xFFFF3B3B), onSurface: onSurface, isDark: isDark, onTap: () => context.push('/preview', extra: {'title': '', 'content': '', 'id': null})),
          const SizedBox(width: 16),
          HomeActionCard(title: 'Upload file', subtitle: 'PDF, DOCX, TXT', icon: LucideIcons.fileUp, iconBg: onSurface.withValues(alpha: 0.1), onSurface: onSurface, isDark: isDark, onTap: pickFiles),
          const SizedBox(width: 16),
          HomeActionCard(title: 'AI Topic', subtitle: 'Generate article', icon: LucideIcons.sparkles, iconBg: const Color(0xFFFF3B3B), onSurface: onSurface, isDark: isDark, onTap: showTopicDialog),
          const SizedBox(width: 16),
          HomeActionCard(title: 'Wikipedia', subtitle: 'Fetch article', icon: LucideIcons.globe, iconBg: onSurface.withValues(alpha: 0.1), onSurface: onSurface, isDark: isDark, onTap: showWikiDialog),
          const SizedBox(width: 16),
          HomeActionCard(title: 'URL Reader', subtitle: 'Extract text', icon: LucideIcons.link, iconBg: onSurface.withValues(alpha: 0.1), onSurface: onSurface, isDark: isDark, onTap: showUrlDialog),
          const SizedBox(width: 16),
          HomeActionCard(title: 'Random', subtitle: 'Unread discovery', icon: LucideIcons.shuffle, iconBg: onSurface.withValues(alpha: 0.1), onSurface: onSurface, isDark: isDark, onTap: _pickRandomUnread),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildDemoBar(Color onSurface, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return GestureDetector(
      onTap: _runDemo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFFFF3B3B), size: 24),
            const SizedBox(width: 12),
            Text('Try a 60-second demo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface)),
          ],
        ),
      ),
    );
  }

  void _pickRandomUnread() {
    final sessions = ref.read(sessionsProvider).value ?? [];
    if (sessions.isEmpty) return;
    final unread = sessions.where((s) => s.position == 0).toList();
    final list = unread.isEmpty ? sessions : unread;
    final random = list[math.Random().nextInt(list.length)];
    ref.read(readerProvider.notifier).loadSession(random);
    context.push('/reader');
  }

  Future<void> _runDemo() async {
    final settings = ref.watch(settingsProvider);
    await ref.read(readerProvider.notifier).loadText('Welcome to iReader', demoText, wpm: settings.defaultWpm);
    if (mounted) {
      await context.push('/reader');
      ref.read(settingsProvider.notifier).completeDemo();
      ref.invalidate(sessionsProvider);
    }
  }
}
