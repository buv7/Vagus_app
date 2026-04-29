import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'provider_client.dart';

// Free models tried in descending capability order.
const _kFreeModels = [
  'meta-llama/llama-3.3-70b-instruct:free',
  'deepseek/deepseek-r1:free',
  'qwen/qwen3-235b-a22b:free',
  'google/gemma-3-27b-it:free',
];

class OpenRouterClient implements ProviderClient {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _embedModel = 'openai/text-embedding-3-small';
  static const Duration _timeout = Duration(seconds: 30);

  final String _apiKey;

  OpenRouterClient() : _apiKey = const String.fromEnvironment('OPENROUTER_API_KEY');

  @override
  String get providerId => 'openrouter';

  @override
  Future<String> complete(
    List<Map<String, String>> messages, {
    Map<String, dynamic>? options,
  }) async {
    _assertKey();
    // Try free models in order until one succeeds.
    Object? lastError;
    for (final model in _kFreeModels) {
      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl/chat/completions'),
              headers: _headers(),
              body: jsonEncode({'model': model, 'messages': messages, ...?options}),
            )
            .timeout(_timeout);

        if (response.statusCode == 429) throw ProviderQuotaExceededException(providerId);
        if (response.statusCode != 200) {
          lastError = Exception('OpenRouter $model ${response.statusCode}: ${response.body}');
          continue;
        }
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      } catch (e) {
        if (e is ProviderQuotaExceededException) rethrow;
        lastError = e;
        continue;
      }
    }
    throw lastError ?? Exception('All OpenRouter free models failed');
  }

  @override
  Stream<String> stream(
    List<Map<String, String>> messages, {
    Map<String, dynamic>? options,
  }) async* {
    _assertKey();
    final model = _kFreeModels.first;
    final request = http.Request('POST', Uri.parse('$_baseUrl/chat/completions'))
      ..headers.addAll(_headers())
      ..body =
          jsonEncode({'model': model, 'messages': messages, 'stream': true, ...?options});

    final client = http.Client();
    try {
      final streamed = await client.send(request).timeout(_timeout);
      if (streamed.statusCode == 429) throw ProviderQuotaExceededException(providerId);

      await for (final chunk in _parseSse(streamed.stream)) {
        yield chunk;
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<String> vision(Uint8List imageBytes, String prompt) =>
      throw UnsupportedError('Use GeminiClient for vision tasks');

  @override
  Future<List<double>> embed(String input) async {
    _assertKey();
    final response = await http
        .post(
          Uri.parse('$_baseUrl/embeddings'),
          headers: _headers(),
          body: jsonEncode({'model': _embedModel, 'input': input}),
        )
        .timeout(_timeout);

    if (response.statusCode == 429) throw ProviderQuotaExceededException(providerId);
    if (response.statusCode != 200) {
      throw Exception('OpenRouter embed ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['data'][0]['embedding'] as List<dynamic>).cast<double>();
  }

  // -- helpers --

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://vagus-app.com',
        'X-Title': 'VAGUS App',
      };

  void _assertKey() {
    if (_apiKey.isEmpty) {
      throw StateError(
          'OPENROUTER_API_KEY is not set. Pass via --dart-define=OPENROUTER_API_KEY=<key>.');
    }
  }

  Stream<String> _parseSse(Stream<List<int>> raw) {
    return raw
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.startsWith('data: ') && line != 'data: [DONE]')
        .map((line) {
      try {
        final json = jsonDecode(line.substring(6)) as Map<String, dynamic>;
        return json['choices']?[0]?['delta']?['content'] as String? ?? '';
      } catch (_) {
        return '';
      }
    }).where((s) => s.isNotEmpty);
  }
}
