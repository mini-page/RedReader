import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';

class RssFeedItem {
  final String title;
  final String? link;
  final String? description;
  final DateTime? pubDate;
  final String? imageUrl;

  RssFeedItem({
    required this.title,
    this.link,
    this.description,
    this.pubDate,
    this.imageUrl,
  });
}

class RssService {
  Future<List<RssFeedItem>> fetchFeed(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final feed = RssFeed.parse(response.body);
        return feed.items?.map((item) => RssFeedItem(
          title: item.title ?? 'No Title',
          link: item.link,
          description: item.description,
          pubDate: item.pubDate,
          imageUrl: item.content?.images.firstOrNull ?? item.enclosure?.url,
        )).toList() ?? [];
      }
    } catch (e) {
      // Re-throw to be caught by UI handlers
      rethrow;
    }
    return [];
  }
}
