import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'provider_client.dart';

class GeminiClient implements ProviderClient {
  static const String _kTextModelId = 'gemini-1.5-flash';
  static const String _kVisionModelId = 'gemini-1.5-flash';

  final String _apiKey;
  GenerativeModel? _textGenModel;
  GenerativeModel? _visionGenModel;

  GeminiClient() : _apiKey = const String.fromEnvironment('GEMINI_API_KEY');

  @override
  String get providerId => 'gemini';

  @override
  Future<String> complete(
    List<Map<String, String>> messages, {
    Map<String, dynamic>? options,
  }) async {
    try {
      final response = await _text.generateContent(_toContents(messages));
      return response.text ?? '';
    } on GenerativeAIException catch (e) {
      if (_isRateLimit(e.message)) throw ProviderQuotaExceededException(providerId);
      rethrow;
    }
  }

  @override
  Stream<String> stream(
    List<Map<String, String>> messages, {
    Map<String, dynamic>? options,
  }) async* {
    try {
      await for (final chunk in _text.generateContentStream(_toContents(messages))) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) yield text;
      }
    } on GenerativeAIException catch (e) {
      if (_isRateLimit(e.message)) throw ProviderQuotaExceededException(providerId);
      rethrow;
    }
  }

  @override
  Future<String> vision(Uint8List imageBytes, String prompt) async {
    _assertKey();
    try {
      final content = Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]);
      final response = await _vision.generateContent([content]);
      return response.text ?? '';
    } on GenerativeAIException catch (e) {
      if (_isRateLimit(e.message)) throw ProviderQuotaExceededException(providerId);
      rethrow;
    }
  }

  @override
  Future<List<double>> embed(String input) =>
      throw UnsupportedError('Use OpenRouter for embeddings');

  // -- helpers --

  GenerativeModel get _text {
    _assertKey();
    return _textGenModel ??= GenerativeModel(
      model: _kTextModelId,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(temperature: 0.2),
    );
  }

  GenerativeModel get _vision {
    _assertKey();
    return _visionGenModel ??= GenerativeModel(
      model: _kVisionModelId,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(temperature: 0.1),
    );
  }

  List<Content> _toContents(List<Map<String, String>> messages) {
    return messages.map((m) {
      final role = m['role'] == 'assistant' ? 'model' : 'user';
      return Content(role, [TextPart(m['content'] ?? '')]);
    }).toList();
  }

  void _assertKey() {
    if (_apiKey.isEmpty) {
      throw StateError(
          'GEMINI_API_KEY is not set. Pass via --dart-define=GEMINI_API_KEY=<key>.');
    }
  }

  bool _isRateLimit(String message) =>
      message.contains('quota') ||
      message.contains('429') ||
      message.contains('RESOURCE_EXHAUSTED');
}
