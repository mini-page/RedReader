import 'dart:io';
import 'dart:async';

import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/constants/demo_text.dart';
import '../../reader/presentation/reader_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../../shared/models/session.dart';

enum LibrarySortType { size, progress, title, date }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Session> sessions = const [];
  bool _isExtracting = false;
  String _searchQuery = '';
  LibrarySortType _sortType = LibrarySortType.date;
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    sessions = await ref.read(sessionRepositoryProvider).all();
    if (mounted) setState(() {});
  }

  List<Session> get _filteredSessions {
    List<Session> filtered = sessions.where((s) {
      final query = _searchQuery.toLowerCase();
      return s.title.toLowerCase().contains(query) ||
          s.content.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (_sortType) {
        case LibrarySortType.size:
          cmp = a.content.length.compareTo(b.content.length);
          break;
        case LibrarySortType.progress:
          final progressA = a.position / a.content.split(RegExp(r'\s+')).length;
          final progressB = b.position / b.content.split(RegExp(r'\s+')).length;
          cmp = progressA.compareTo(progressB);
          break;
        case LibrarySortType.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case LibrarySortType.date:
          cmp = a.updatedAt.compareTo(b.updatedAt);
          break;
      }
      return _isAscending ? cmp : -cmp;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final latestSession = sessions.isNotEmpty ? sessions.first : null;
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark
          ? (settings.showOledBlack ? Colors.black : const Color(0xFF121212))
          : const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: isDark
                      ? (settings.showOledBlack
                          ? Colors.black
                          : const Color(0xFF121212))
                      : const Color(0xFFF6F6F6),
                  toolbarHeight: 80,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      child: _buildHeader(context, onSurface, isDark),
                    ),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (latestSession != null && _searchQuery.isEmpty) ...[
                        _buildContinueReading(latestSession, onSurface, isDark),
                        const SizedBox(height: 24),
                      ],
                      _buildActionGrid(onSurface, isDark),
                      const SizedBox(height: 24),
                      if (!settings.hasRunDemo) ...[
                        _buildDemoBar(onSurface, isDark),
                        const SizedBox(height: 40),
                      ],
                      _buildLibraryHeader(onSurface, isDark),
                      const SizedBox(height: 16),
                      if (sessions.isEmpty)
                        _buildEmptyLibrary(onSurface, isDark)
                      else
                        ..._filteredSessions
                            .skip((latestSession != null && _searchQuery.isEmpty)
                                ? 1
                                : 0)
                            .map((s) => _buildSessionCard(s, onSurface, isDark)),
                      const SizedBox(height: 100), // Bottom padding
                    ]),
                  ),
                ),
              ],
            ),
            if (_isExtracting) _buildExtractionOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color onSurface, bool isDark) {
    final controller = ref.read(settingsProvider.notifier);
    final settings = ref.read(settingsProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: GestureDetector(
            onTap: () => _showBrandingTooltip(context, isDark),
            child: Image.asset(
              isDark
                  ? 'assets/images/transparent_white_icon.png'
                  : 'assets/images/transparent_black_icon.png',
              width: 32,
              height: 32,
            ),
          ),
        ),
        Row(
          children: [
            _buildCircleIconButton(
              isDark
                  ? Icons.wb_sunny_outlined
                  : Icons.nightlight_round_outlined,
              onSurface,
              () => controller.update(settings.copyWith(
                  themeMode: isDark ? ThemeMode.light : ThemeMode.dark)),
            ),
            const SizedBox(width: 12),
            _buildCircleIconButton(Icons.settings_outlined, onSurface,
                () async {
              await context.push('/settings');
              _loadSessions();
            }),
          ],
        ),
      ],
    );
  }

  void _showBrandingTooltip(BuildContext context, bool isDark) {
    final onSurface = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B3B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Color(0xFFFF3B3B), size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'What is iReader?',
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'iReader is a "Flash Fast" reading tool designed to eliminate eye movement and maximize focus. By showing words in rapid succession at a single focal point, it allows you to process information at lightning speeds without distraction.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF3B3B),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Got it',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIconButton(
      IconData icon, Color onSurface, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: onSurface.withValues(alpha: 0.8), size: 24),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildContinueReading(Session session, Color onSurface, bool isDark) {
    final totalWords = session.content.split(RegExp(r'\s+')).length;
    final progress = ((session.position + 1) / totalWords).clamp(0.0, 1.0);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTINUE READING',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            color: onSurface.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(progress * 100).toInt()}% • $totalWords words',
                            style: TextStyle(
                              fontSize: 14,
                              color: onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await ref
                            .read(readerProvider.notifier)
                            .loadSession(session);
                        if (mounted) {
                          await context.push('/reader');
                          _loadSessions();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B3B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B3B),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyLibrary(Color onSurface, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: onSurface.withValues(alpha: 0.1),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Text(
            'No sessions yet',
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.6),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste an article or upload a file to start reading.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(Color onSurface, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Paste text',
            'Direct edit',
            Icons.edit_note_rounded,
            const Color(0xFFFF3B3B),
            onSurface,
            isDark,
            () => context.push('/preview',
                extra: {'title': '', 'content': '', 'id': null}),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            'Upload file',
            'PDF, DOCX, TXT',
            Icons.insert_drive_file_outlined,
            onSurface.withValues(alpha: 0.1),
            onSurface,
            isDark,
            _pickFiles,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon,
      Color iconBg, Color onSurface, bool isDark, VoidCallback onTap) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon,
                  color: iconBg == const Color(0xFFFF3B3B)
                      ? Colors.white
                      : onSurface,
                  size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
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
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFFFF3B3B), size: 24),
            const SizedBox(width: 12),
            Text(
              'Try a 60-second demo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryHeader(Color onSurface, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LIBRARY',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                color: onSurface.withValues(alpha: 0.3),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (sessions.isNotEmpty)
              Text(
                '${sessions.length} items',
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search your library...',
                    hintStyle:
                        TextStyle(color: onSurface.withValues(alpha: 0.3)),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: onSurface.withValues(alpha: 0.3), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTapDown: (details) => _showSortPopup(details.globalPosition),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sort_rounded,
                    color: onSurface.withValues(alpha: 0.6), size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSortPopup(Offset tapPosition) {
    final settings = ref.read(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SortPopup',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: anim1,
            alignment: Alignment.topRight,
            child: Stack(
              children: [
                Positioned(
                  top: tapPosition.dy + 10,
                  right: 20,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSortTile('Title', LibrarySortType.title),
                          _buildSortTile('Date', LibrarySortType.date),
                          _buildSortTile('Words Count', LibrarySortType.size),
                          _buildSortTile('Progress', LibrarySortType.progress),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortTile(String label, LibrarySortType type) {
    final isSelected = _sortType == type;
    final isDark = ref.read(settingsProvider).themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(label,
          style: TextStyle(
              color: isSelected ? const Color(0xFFFF3B3B) : onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14)),
      trailing: isSelected
          ? Icon(
              _isAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: const Color(0xFFFF3B3B),
              size: 16)
          : null,
      onTap: () {
        setState(() {
          if (_sortType == type) {
            _isAscending = !_isAscending;
          } else {
            _sortType = type;
            _isAscending = true;
          }
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSessionCard(Session session, Color onSurface, bool isDark) {
    final totalWords = session.content.split(RegExp(r'\s+')).length;
    final progress = ((session.position + 1) / totalWords).clamp(0.0, 1.0);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Slidable(
        key: ValueKey(session.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.45,
          children: [
            SlidableAction(
              onPressed: (context) async {
                final navigator = GoRouter.of(context);
                await navigator.push('/preview', extra: {
                  'id': session.id,
                  'title': session.title,
                  'content': session.content
                });
                if (mounted) _loadSessions();
              },
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: 'Edit',
              padding: EdgeInsets.zero,
            ),
            SlidableAction(
              onPressed: (context) => _showDeleteDialog(session),
              backgroundColor: const Color(0xFFFF3B3B),
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Del',
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        child: Stack(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(
                session.title,
                style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${(progress * 100).toInt()}% • $totalWords words • ${session.wpm} wpm',
                style: TextStyle(
                    color: onSurface.withValues(alpha: 0.5), fontSize: 13),
              ),
              trailing: Icon(Icons.chevron_right,
                  color: onSurface.withValues(alpha: 0.2)),
              onTap: () async {
                await ref.read(readerProvider.notifier).loadSession(session);
                if (mounted) {
                  await context.push('/reader');
                  _loadSessions();
                }
              },
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                      color: const Color(0xFFFF3B3B).withValues(alpha: 0.7)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Session session) {
    final isDark = ref.read(settingsProvider).themeMode == ThemeMode.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Session?'),
        content: Text('Are you sure you want to delete "${session.title}"?'),
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
              final repo = ref.read(sessionRepositoryProvider);
              final navigator = Navigator.of(context);
              await repo.delete(session.id);
              navigator.pop();
              if (mounted) _loadSessions();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractionOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MatrixRailAnimation(),
            const SizedBox(height: 32),
            const Text(
              'EXTRACTING KNOWLEDGE',
              style: TextStyle(
                  color: Color(0xFFFF3B3B),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Processing document tokens...',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runDemo() async {
    final settings = ref.read(settingsProvider);
    await ref
        .read(readerProvider.notifier)
        .loadText('Welcome to iReader', demoText, wpm: settings.defaultWpm);
    if (mounted) {
      await context.push('/reader');
      ref.read(settingsProvider.notifier).completeDemo();
      _loadSessions();
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'docx'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _isExtracting = true);
    await Future.delayed(const Duration(seconds: 2));

    final file = File(result.files.single.path!);
    final extension = result.files.single.extension?.toLowerCase();
    String content = '';
    String title = result.files.single.name;

    try {
      if (extension == 'txt') {
        content = await file.readAsString();
      } else if (extension == 'pdf') {
        final PdfDocument document =
            PdfDocument(inputBytes: await file.readAsBytes());
        content = PdfTextExtractor(document).extractText();
        document.dispose();
      } else if (extension == 'docx') {
        final bytes = await file.readAsBytes();
        content = docxToText(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error reading file: $e')));
      }
    }

    setState(() => _isExtracting = false);

    if (content.trim().isNotEmpty) {
      if (mounted) {
        await context.push('/preview',
            extra: {'title': title, 'content': content, 'id': null});
        _loadSessions();
      }
    }
  }
}

class _MatrixRailAnimation extends StatefulWidget {
  const _MatrixRailAnimation();

  @override
  State<_MatrixRailAnimation> createState() => _MatrixRailAnimationState();
}

class _MatrixRailAnimationState extends State<_MatrixRailAnimation>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  final List<String> _lines = [];
  late final int _random;

  @override
  void initState() {
    super.initState();
    _random = DateTime.now().millisecondsSinceEpoch;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _lines.insert(0, _generateRandomString(20));
          if (_lines.length > 10) _lines.removeLast();
        });
      }
    });
  }

  String _generateRandomString(int length) {
    const String chars = r'0123456789ABCDEF!@#$%^&*()_+';
    return List.generate(length,
            (index) => chars[(index + _random + _timer.tick) % chars.length])
        .join();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _lines.asMap().entries.map((e) {
        return Opacity(
          opacity: (1.0 - (e.key / 10.0)).clamp(0.0, 1.0),
          child: Text(
            e.value,
            style: const TextStyle(
                color: Color(0xFFFF3B3B),
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }
}
