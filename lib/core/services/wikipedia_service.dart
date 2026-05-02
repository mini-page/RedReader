import 'dart:convert';
import 'package:http/http.dart' as http;

class WikipediaArticle {
  final String title;
  final String extract;
  final String? imageUrl;
  final String? description;

  WikipediaArticle({
    required this.title,
    required this.extract,
    this.imageUrl,
    this.description,
  });

  factory WikipediaArticle.fromJson(Map<String, dynamic> json) {
    return WikipediaArticle(
      title: json['title'] ?? '',
      extract: json['extract'] ?? '',
      description: json['description'],
      imageUrl: json['originalimage']?['source'],
    );
  }
}

class WikipediaService {
  static const _baseUrl = 'https://en.wikipedia.org/api/rest_v1/page/summary';

  Future<WikipediaArticle?> fetchSummary(String title) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/${Uri.encodeComponent(title)}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WikipediaArticle.fromJson(data);
      }
    } catch (e) {
      // Log error
    }
    return null;
  }

  /// Fetches the full content using the mobile-sections endpoint for a complete reading session.
  Future<String> fetchFullContent(String title) async {
    try {
      // Using the mobile-sections endpoint to get more than just the summary
      final response = await http.get(Uri.parse(
          'https://en.wikipedia.org/api/rest_v1/page/mobile-sections/${Uri.encodeComponent(title)}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final leadSection = data['lead']['sections'][0]['text'] as String;
        final remainingSections = data['remaining']['sections'] as List;
        
        StringBuffer fullText = StringBuffer();
        fullText.writeln(_stripHtml(leadSection));
        
        for (var section in remainingSections) {
          final sectionTitle = section['line'] ?? '';
          final sectionText = section['text'] ?? '';
          if (sectionTitle.isNotEmpty) {
            fullText.writeln('\n\n$sectionTitle\n');
          }
          fullText.writeln(_stripHtml(sectionText));
        }
        
        return fullText.toString();
      }
    } catch (e) {
      // Fallback to summary if full fetch fails
    }
    
    final summary = await fetchSummary(title);
    return summary?.extract ?? '';
  }

  String _stripHtml(String html) {
    // Basic HTML stripping for clean text ingestion
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return html.replaceAll(exp, '').replaceAll('&nbsp;', ' ').trim();
  }
}
