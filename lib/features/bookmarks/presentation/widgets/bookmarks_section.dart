import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../bookmarks_provider.dart';
import '../../domain/bookmark.dart';

class BookmarksSection extends ConsumerStatefulWidget {
  const BookmarksSection({super.key});

  @override
  ConsumerState<BookmarksSection> createState() => _BookmarksSectionState();
}

class _BookmarksSectionState extends ConsumerState<BookmarksSection> {
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BOOKMARKS',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                color: onSurface.withValues(alpha: 0.3),
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(
                _isSearchOpen ? LucideIcons.x : LucideIcons.search,
                size: 16,
                color: onSurface.withValues(alpha: 0.4),
              ),
              onPressed: () {
                setState(() {
                  _isSearchOpen = !_isSearchOpen;
                  if (!_isSearchOpen) {
                    _query = '';
                    _searchController.clear();
                  }
                });
              },
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _isSearchOpen
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(color: onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search bookmarked words...',
                      hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.2)),
                      prefixIcon: const Icon(LucideIcons.search, size: 14),
                      filled: true,
                      fillColor: onSurface.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                )
              : const SizedBox(),
        ),
        bookmarksAsync.when(
          data: (bookmarks) {
            final filtered = bookmarks
                .where((b) => b.word.toLowerCase().contains(_query.toLowerCase()))
                .toList();

            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    _query.isEmpty ? 'No bookmarks yet.' : 'No matches found.',
                    style: TextStyle(color: onSurface.withValues(alpha: 0.2), fontSize: 13),
                  ),
                ),
              );
            }

            // Group by sessionId
            final Map<String, List<Bookmark>> grouped = {};
            for (var b in filtered) {
              grouped.putIfAbsent(b.sessionId, () => []).add(b);
            }

            return Column(
              children: grouped.entries.map((entry) {
                final sessionId = entry.key;
                final sessionBookmarks = entry.value;
                final title = sessionBookmarks.first.sessionTitle;

                return _buildSessionGroup(context, title, sessionId, sessionBookmarks, onSurface, isDark);
              }).toList(),
            );
          },
          loading: () => const Center(child: LinearProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildSessionGroup(
    BuildContext context,
    String title,
    String sessionId,
    List<Bookmark> bookmarks,
    Color onSurface,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${bookmarks.length} word${bookmarks.length > 1 ? 's' : ''}',
            style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 12),
          ),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          expandedAlignment: Alignment.topLeft,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bookmarks.map((b) => _buildBookmarkChip(context, b, onSurface)).toList(),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/bookmarks/$sessionId'),
                icon: const Icon(LucideIcons.arrowRight, size: 14),
                label: const Text('Review Session'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF3B3B),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkChip(BuildContext context, Bookmark b, Color onSurface) {
    return GestureDetector(
      onTap: () => context.push('/bookmarks/${b.sessionId}', extra: b),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          b.word,
          style: TextStyle(color: onSurface.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
