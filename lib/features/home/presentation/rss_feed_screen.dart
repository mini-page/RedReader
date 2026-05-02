import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:red_reader/core/services/rss_provider.dart';
import 'package:red_reader/core/services/rss_service.dart';
import 'package:red_reader/shared/widgets/skeleton_loaders.dart';
import 'package:red_reader/shared/widgets/reading_action_mixin.dart';
import 'package:red_reader/features/home/presentation/widgets/home_widgets.dart';

class RssFeedScreen extends ConsumerStatefulWidget {
  final String feedUrl;
  final String feedName;

  const RssFeedScreen({
    super.key,
    required this.feedUrl,
    required this.feedName,
  });

  @override
  ConsumerState<RssFeedScreen> createState() => _RssFeedScreenState();
}

class _RssFeedScreenState extends ConsumerState<RssFeedScreen> with ReadingActionMixin {
  @override
  Widget build(BuildContext context) {
    final rssAsync = ref.watch(rssFeedProvider(widget.feedUrl));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.feedName.toUpperCase(),
          style: GoogleFonts.lexend(
            color: onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Stack(
        children: [
          rssAsync.when(
            data: (items) => ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildRssItem(item, onSurface, isDark);
              },
            ),
            loading: () => Padding(
              padding: const EdgeInsets.all(20),
              child: SkeletonList(isDark: isDark),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.wifiOff, color: onSurface.withValues(alpha: 0.2), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Network error or invalid feed.',
                    style: TextStyle(color: onSurface.withValues(alpha: 0.4)),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(rssFeedProvider(widget.feedUrl)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          if (isProcessing) ProcessingOverlay(label: processingLabel),
        ],
      ),
    );
  }

  Widget _buildRssItem(RssFeedItem item, Color onSurface, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: onSurface.withValues(alpha: 0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () {
          if (item.link != null) {
            extractAndRead(item.link!);
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    item.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (item.imageUrl != null) const SizedBox(height: 16),
              Text(
                item.title,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              if (item.description != null)
                Text(
                  _stripHtml(item.description!),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 12, color: onSurface.withValues(alpha: 0.3)),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(item.pubDate),
                    style: TextStyle(color: onSurface.withValues(alpha: 0.3), fontSize: 11),
                  ),
                  const Spacer(),
                  const Text(
                    'Tap to Read',
                    style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return html.replaceAll(exp, '').trim();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    // Simple relative date or formatted string
    return "${date.day}/${date.month}/${date.year}";
  }
}
