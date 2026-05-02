import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';

import '../domain/bookmark.dart';
import '../presentation/bookmarks_provider.dart';
import 'package:red_reader/core/services/dictionary_provider.dart';
import 'package:red_reader/features/reader/presentation/reader_controller.dart';

class BookmarkSessionScreen extends ConsumerWidget {
  final String sessionId;

  const BookmarkSessionScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true, // Center the header
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Session Review',
          style: GoogleFonts.lexend(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: bookmarksAsync.when(
        data: (bookmarks) {
          final sessionBookmarks = bookmarks.where((b) => b.sessionId == sessionId).toList();
          if (sessionBookmarks.isEmpty) {
            return const Center(child: Text('No bookmarks found for this session.'));
          }

          final sessionTitle = sessionBookmarks.first.sessionTitle;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                sessionTitle.toUpperCase(),
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.3),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ...sessionBookmarks.map((b) => _BookmarkDetailCard(bookmark: b, onSurface: onSurface, isDark: isDark)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _BookmarkDetailCard extends ConsumerWidget {
  final Bookmark bookmark;
  final Color onSurface;
  final bool isDark;

  const _BookmarkDetailCard({required this.bookmark, required this.onSurface, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordInfoAsync = ref.watch(wordLookupProvider(bookmark.word));
    
    // Note: Creating a temporary AudioPlayer for simple preview. 
    final audioPlayer = AudioPlayer();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: onSurface.withValues(alpha: 0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: wordInfoAsync.when(
        data: (info) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookmark.word,
                      style: GoogleFonts.lexend(
                        color: onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (info?.phonetic != null)
                      Text(
                        info!.phonetic!,
                        style: TextStyle(color: const Color(0xFFFF3B3B), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
                _buildActionIcon(LucideIcons.volume2, () async {
                  if (info?.audioUrl != null) {
                    await audioPlayer.play(UrlSource(info!.audioUrl!));
                  } else {
                    ref.read(readerProvider.notifier).speakWords(bookmark.word);
                  }
                }, onSurface: onSurface),
              ],
            ),
            const SizedBox(height: 20),
            if (info != null && info.meanings.isNotEmpty) ...[
              _buildLearningField('Meaning', info.meanings[0].definitions[0].definition, onSurface),
              const SizedBox(height: 16),
              if (info.meanings[0].synonyms.isNotEmpty)
                _buildLearningField('Synonyms', info.meanings[0].synonyms.take(3).join(', '), onSurface),
              const SizedBox(height: 16),
              if (info.meanings[0].definitions[0].example != null)
                _buildLearningField('Example', info.meanings[0].definitions[0].example!, onSurface),
            ] else
              Text('No detailed info found for this word.', style: TextStyle(color: onSurface.withValues(alpha: 0.3), fontSize: 13)),
            
            const SizedBox(height: 24),
            Row(
              children: [
                _buildLearningAction(LucideIcons.bookOpen, 'Usage', onSurface),
                const Spacer(),
                _buildActionIcon(LucideIcons.trash2, () {
                  ref.read(bookmarksProvider.notifier).deleteBookmark(bookmark.id);
                }, color: const Color(0xFFFF3B3B), onSurface: onSurface),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
        error: (e, _) => Text('Error loading word details', style: TextStyle(color: onSurface.withValues(alpha: 0.3))),
      ),
    );
  }

  Widget _buildLearningField(String label, String value, Color onSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: const Color(0xFFFF3B3B).withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildLearningAction(IconData icon, String label, Color onSurface) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap, {Color? color, required Color onSurface}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? onSurface).withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color ?? onSurface.withValues(alpha: 0.4)),
      ),
    );
  }
}
