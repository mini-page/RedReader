import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../services/translation_service.dart';

final translationServiceProvider = Provider((ref) => TranslationService());

final translationProvider = FutureProvider.family<String, String>((ref, text) async {
  final service = ref.read(translationServiceProvider);
  return service.translate(text);
});

class TargetLanguageNotifier extends Notifier<TranslateLanguage> {
  @override
  TranslateLanguage build() => TranslateLanguage.spanish;
  void setLanguage(TranslateLanguage lang) => state = lang;
}

final targetLanguageProvider = NotifierProvider<TargetLanguageNotifier, TranslateLanguage>(TargetLanguageNotifier.new);
