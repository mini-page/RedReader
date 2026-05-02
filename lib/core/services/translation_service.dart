import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  final _modelManager = OnDeviceTranslatorModelManager();

  Future<String> translate(String text, {TranslateLanguage source = TranslateLanguage.english, TranslateLanguage target = TranslateLanguage.spanish}) async {
    final onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );

    try {
      // Ensure models are downloaded (ML Kit handles this automatically if requested, 
      // but we should check if they exist or trigger download)
      final bool isSourceDownloaded = await _modelManager.isModelDownloaded(source.bcpCode);
      final bool isTargetDownloaded = await _modelManager.isModelDownloaded(target.bcpCode);

      if (!isSourceDownloaded) await _modelManager.downloadModel(source.bcpCode);
      if (!isTargetDownloaded) await _modelManager.downloadModel(target.bcpCode);

      final String response = await onDeviceTranslator.translateText(text);
      return response;
    } catch (e) {
      return "Translation Error: $e";
    } finally {
      onDeviceTranslator.close();
    }
  }

  Future<void> deleteModel(TranslateLanguage language) async {
    await _modelManager.deleteModel(language.bcpCode);
  }
}
