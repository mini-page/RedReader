import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:red_reader/features/reader/presentation/reader_controller.dart';
import 'package:red_reader/features/settings/presentation/settings_controller.dart';
import 'package:red_reader/shared/models/session.dart';
import 'package:red_reader/shared/widgets/expandable_fab.dart';
import 'package:red_reader/shared/widgets/reading_action_mixin.dart';
import 'package:red_reader/features/home/presentation/widgets/home_widgets.dart';
import 'package:red_reader/features/home/data/sessions_provider.dart';

enum LibrarySortType { size, progress, title, date }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with ReadingActionMixin {
  String _searchQuery = '';
  LibrarySortType _sortType = LibrarySortType.date;
  bool _isAscending = false;

  List<Session> _getFilteredSessions(List<Session> sessions) {
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
    final sessionsAsync = ref.watch(sessionsProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark
          ? (settings.showOledBlack ? Colors.black : const Color(0xFF121212))
          : const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text('Your Library', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildSearchAndSort(onSurface, isDark),
              ),
              Expanded(
                child: sessionsAsync.when(
                  data: (sessions) {
                    final filtered = _getFilteredSessions(sessions);
                    if (filtered.isEmpty) return _buildEmptyState(onSurface);
                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildSessionCard(filtered[index], onSurface, isDark),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
          if (isProcessing) ProcessingOverlay(label: processingLabel),
        ],
      ),
      floatingActionButton: ExpandableFab(
        distance: 70,
        children: [
          ActionButton(
            onPressed: () => context.push('/preview', extra: {'title': '', 'content': '', 'id': null}),
            icon: const Icon(LucideIcons.clipboardSignature, color: Color(0xFFFF3B3B), size: 20),
            label: 'Paste Text',
          ),
          ActionButton(
            onPressed: pickFiles,
            icon: const Icon(LucideIcons.fileUp, color: Color(0xFFFF3B3B), size: 20),
            label: 'Upload File',
          ),
          ActionButton(
            onPressed: showTopicDialog,
            icon: const Icon(LucideIcons.sparkles, color: Color(0xFFFF3B3B), size: 20),
            label: 'AI Topic',
          ),
          ActionButton(
            onPressed: showWikiDialog,
            icon: const Icon(LucideIcons.globe, color: Color(0xFFFF3B3B), size: 20),
            label: 'Wikipedia',
          ),
          ActionButton(
            onPressed: () => context.push('/rss', extra: {'url': 'https://hnrss.org/frontpage', 'name': 'Hacker News'}),
            icon: const Icon(LucideIcons.rss, color: Color(0xFFFF3B3B), size: 20),
            label: 'Hacker News',
          ),
          ActionButton(
            onPressed: showUrlDialog,
            icon: const Icon(LucideIcons.link, color: Color(0xFFFF3B3B), size: 20),
            label: 'URL Reader',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSort(Color onSurface, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search documents...',
                hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.3)),
                prefixIcon: Icon(Icons.search_rounded, color: onSurface.withValues(alpha: 0.3), size: 20),
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
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sort_rounded, color: onSurface.withValues(alpha: 0.6), size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color onSurface) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_rounded, size: 64, color: onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text('Library is empty', style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session, Color onSurface, bool isDark) {
    final totalWords = session.content.split(RegExp(r'\s+')).length;
    final progress = ((session.position + 1) / totalWords).clamp(0.0, 1.0);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Slidable(
        key: ValueKey(session.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.4, // Wider area
          children: [
            CustomSlidableAction(
              onPressed: (context) async {
                await context.push('/preview', extra: {'id': session.id, 'title': session.title, 'content': session.content});
                WidgetsBinding.instance.addPostFrameCallback((_) {
                   if (mounted) ref.read(sessionsProvider.notifier).refresh();
                });
              },
              backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.08),
              foregroundColor: const Color(0xFF2196F3),
              child: const Icon(Icons.edit_rounded, size: 28),
            ),
            CustomSlidableAction(
              onPressed: (context) => _showDeleteDialog(session),
              backgroundColor: const Color(0xFFFF3B3B).withValues(alpha: 0.08),
              foregroundColor: const Color(0xFFFF3B3B),
              child: const Icon(Icons.delete_rounded, size: 28),
            ),
          ],
        ),
        child: InkWell(
          onTap: () async {
            await ref.read(readerProvider.notifier).loadSession(session);
            if (mounted) {
              await context.push('/reader');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted) ref.read(sessionsProvider.notifier).refresh();
              });
            }
          },
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
                          Text(session.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
                          const SizedBox(height: 4),
                          Text('${(progress * 100).toInt()}% • $totalWords words', style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Color(0xFFFF3B3B), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3)),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(decoration: BoxDecoration(color: const Color(0xFFFF3B3B), borderRadius: BorderRadius.circular(3))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 10))],
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
      title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFFF3B3B) : onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
      trailing: isSelected ? Icon(_isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: const Color(0xFFFF3B3B), size: 16) : null,
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF3B3B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await ref.read(sessionsProvider.notifier).deleteSession(session.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
