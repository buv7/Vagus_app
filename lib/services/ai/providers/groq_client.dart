import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'provider_client.dart';

class GroqClient implements ProviderClient {
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _model = 'llama-3.3-70b-versatile';
  static const Duration _timeout = Duration(seconds: 30);

  final String _apiKey;

  GroqClient() : _apiKey = const String.fromEnvironment('GROQ_API_KEY');

  @override
  String get providerId => 'groq';

  @override
  Future<String> complete(
    List<Map<String, String>> messages, {
    Map<String, dynamic>? options,
  }) async {
    _assertKey();
    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: _headers(),
          body: jsonEncode({'model': _model, 'messages': messages, ...?options}),
        )
        .timeout(_timeout);

    _guardRateLimit(response.statusCode);
    if (response.statusCode != 200) {
      throw Exception('Groq ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['choices'][0]['message']['content'] as String;
  }

  @override
  Stream<String> stream(
    List<Map<String, String>> messages, {
    Map<String, dynamic>? options,
  }) async* {
    _assertKey();
    final request = http.Request('POST', Uri.parse('$_baseUrl/chat/completions'))
      ..headers.addAll(_headers())
      ..body = jsonEncode({'model': _model, 'messages': messages, 'stream': true, ...?options});

    final client = http.Client();
    try {
      final streamed = await client.send(request).timeout(_timeout);
      _guardRateLimit(streamed.statusCode);

      await for (final chunk in _parseSse(streamed.stream)) {
        yield chunk;
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<String> vision(Uint8List imageBytes, String prompt) =>
      throw UnsupportedError('Groq does not support vision');

  @override
  Future<List<double>> embed(String input) =>
      throw UnsupportedError('Groq does not support embeddings via this client');

  // -- helpers --

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

  void _assertKey() {
    if (_apiKey.isEmpty) {
      throw StateError(
          'GROQ_API_KEY is not set. Pass via --dart-define=GROQ_API_KEY=<key>.');
    }
  }

  void _guardRateLimit(int status) {
    if (status == 429) throw ProviderQuotaExceededException(providerId);
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
