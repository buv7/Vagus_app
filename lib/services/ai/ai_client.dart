import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'ai_usage_service.dart';

class AIClient {
  static final AIClient _instance = AIClient._internal();
  factory AIClient() => _instance;
  AIClient._internal();

  final String _apiKey = const String.fromEnvironment('OPENROUTER_API_KEY');
  final String _baseUrl = const String.fromEnvironment(
    'OPENROUTER_BASE_URL',
    defaultValue: 'https://openrouter.ai/api/v1',
  );
  
  final AIUsageService _usageService = AIUsageService.instance;

  Future<String> chat({
    required String model,
    required List<Map<String, String>> messages,
    Map<String, dynamic>? options,
  }) async {
    try {
      // Check quota before making the call
      if (!await _usageService.canMakeRequest('chat')) {
        return 'Quota exceeded. Please upgrade your plan or try again later.';
      }

      if (_apiKey.isEmpty) {
        return 'AI service not configured. Please contact support.';
      }

      final response = await _makeRequestWithRetry(
        'POST',
        '/chat/completions',
        {
          'model': model,
          'messages': messages,
          ...?options,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Increment usage on success
        await _usageService.incrementUsage('chat', model);
        
        return content;
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return 'AI service temporarily unavailable. Please try again.';
    }
  }

  Future<List<double>> embed({
    required String model,
    required String input,
  }) async {
    try {
      // Check quota before making the call
      if (!await _usageService.canMakeRequest('embedding')) {
        throw Exception('Quota exceeded. Please upgrade your plan or try again later.');
      }

      if (_apiKey.isEmpty) {
        throw Exception('AI service not configured. Please contact support.');
      }

      final response = await _makeRequestWithRetry(
        'POST',
        '/embeddings',
        {
          'model': model,
          'input': input,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final embedding = data['data'][0]['embedding'] as List<dynamic>;
        
        // Increment usage on success
        await _usageService.incrementUsage('embedding', model);
        
        return embedding.cast<double>();
      } else {
        throw Exception(_handleErrorResponse(response));
      }
    } catch (e) {
      throw Exception('Embedding service temporarily unavailable. Please try again.');
    }
  }

  Future<http.Response> _makeRequestWithRetry(
    String method,
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    const maxRetries = 2;
    const timeout = Duration(seconds: 20);

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl$endpoint'),
              headers: {
                'Authorization': 'Bearer $_apiKey',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://vagus-app.com',
                'X-Title': 'VAGUS App',
              },
              body: json.encode(body),
            )
            .timeout(timeout);

        return response;
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow;
        }
        
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: (pow(2, attempt) * 1000).toInt()));
      }
    }

    throw Exception('Request failed after $maxRetries retries');
  }

  String _handleErrorResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      return data['error']?['message'] ?? 'AI service error (${response.statusCode})';
    } catch (e) {
      return 'AI service error (${response.statusCode})';
    }
  }
}
