import 'package:readability/readability.dart' as readability;

class ExtractedArticle {
  final String title;
  final String content;
  final String? excerpt;
  final String? siteName;

  ExtractedArticle({
    required this.title,
    required this.content,
    this.excerpt,
    this.siteName,
  });
}

class ArticleService {
  Future<ExtractedArticle?> extractFromUrl(String url) async {
    try {
      final result = await readability.parseAsync(url);
      
      return ExtractedArticle(
        title: result.title ?? 'Untitled',
        content: result.textContent ?? '',
        excerpt: result.excerpt,
        siteName: result.siteName,
      );
    } catch (e) {
      // Error handling managed by Mixin
    }
    return null;
  }
}
