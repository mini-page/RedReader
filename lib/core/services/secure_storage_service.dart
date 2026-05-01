import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _openAiKey = 'openai_api_key';
  static const _geminiKey = 'gemini_api_key';
  static const _groqKey = 'groq_api_key';

  Future<void> saveOpenAiKey(String key) async => await _storage.write(key: _openAiKey, value: key);
  Future<String?> getOpenAiKey() async => await _storage.read(key: _openAiKey);

  Future<void> saveGeminiKey(String key) async => await _storage.write(key: _geminiKey, value: key);
  Future<String?> getGeminiKey() async => await _storage.read(key: _geminiKey);

  Future<void> saveGroqKey(String key) async => await _storage.write(key: _groqKey, value: key);
  Future<String?> getGroqKey() async => await _storage.read(key: _groqKey);

  Future<void> deleteAll() async => await _storage.deleteAll();
}

final secureStorageProvider = Provider((ref) => SecureStorageService());
