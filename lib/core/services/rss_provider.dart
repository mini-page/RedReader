import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rss_service.dart';

final rssServiceProvider = Provider((ref) => RssService());

final rssFeedProvider = FutureProvider.family<List<RssFeedItem>, String>((ref, url) async {
  final service = ref.read(rssServiceProvider);
  return service.fetchFeed(url);
});
