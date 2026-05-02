import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryEntry {
  final String word;
  final String? phonetic;
  final List<Meaning> meanings;
  final String? audioUrl;

  DictionaryEntry({
    required this.word,
    this.phonetic,
    required this.meanings,
    this.audioUrl,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    String? audio;
    final phonetics = json['phonetics'] as List?;
    if (phonetics != null && phonetics.isNotEmpty) {
      for (var p in phonetics) {
        if (p['audio'] != null && p['audio'].toString().isNotEmpty) {
          audio = p['audio'];
          break;
        }
      }
    }

    return DictionaryEntry(
      word: json['word'],
      phonetic: json['phonetic'],
      meanings: (json['meanings'] as List)
          .map((m) => Meaning.fromJson(m))
          .toList(),
      audioUrl: audio,
    );
  }
}

class Meaning {
  final String partOfSpeech;
  final List<Definition> definitions;
  final List<String> synonyms;

  Meaning({
    required this.partOfSpeech,
    required this.definitions,
    required this.synonyms,
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    return Meaning(
      partOfSpeech: json['partOfSpeech'],
      definitions: (json['definitions'] as List)
          .map((d) => Definition.fromJson(d))
          .toList(),
      synonyms: List<String>.from(json['synonyms'] ?? []),
    );
  }
}

class Definition {
  final String definition;
  final String? example;

  Definition({required this.definition, this.example});

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      definition: json['definition'],
      example: json['example'],
    );
  }
}

class DictionaryService {
  static const _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  Future<DictionaryEntry?> lookup(String word) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$word'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return DictionaryEntry.fromJson(data[0]);
        }
      }
    } catch (e) {
      // Log or handle error
    }
    return null;
  }
}
