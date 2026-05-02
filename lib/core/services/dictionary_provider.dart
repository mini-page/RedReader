import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../services/dictionary_service.dart';
import '../services/translation_service.dart';

final dictionaryServiceProvider = Provider((ref) => DictionaryService());
final translationServiceProvider = Provider((ref) => TranslationService());

final wordLookupProvider = FutureProvider.family<DictionaryEntry?, String>((ref, word) async {
  final service = ref.read(dictionaryServiceProvider);
  return service.lookup(word);
});

final wordTranslationProvider = FutureProvider.family<String?, String>((ref, word) async {
  final service = ref.read(translationServiceProvider);
  // We can eventually get this from user settings
  return service.translate(word, target: TranslateLanguage.spanish);
});

