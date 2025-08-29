import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../billing/plan_access_manager.dart';

class TranscriptionAI {
  static const String _configKey = 'TRANSCRIPTION_ENDPOINT';
  static const String _defaultEndpoint = 'https://api.openrouter.ai/v1/audio/transcriptions';
  
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Transcribes audio from a Supabase Storage path
  /// Returns the transcribed text or throws an exception on failure
  Future<String> transcribeAudio({
    required String storagePath,
    String? languageHint,
  }) async {
    try {
      // AI gating check
      final remaining = await PlanAccessManager.instance.remainingAICalls();
      if (remaining <= 0) {
        throw Exception('AI quota exceeded. Please upgrade your plan or try again later.');
      }

      // Get the transcription endpoint from environment or use default
      final endpoint = await _getTranscriptionEndpoint();
      
      // Check if we have an API key configured
      final apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Transcription service not configured: Missing API key. Please set TRANSCRIPTION_API_KEY in your environment or app config.');
      }
      
      // Download the audio file from Supabase Storage
      final audioBytes = await _downloadAudioFile(storagePath);
      
      // Prepare the request
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));
      
      // Add the audio file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: storagePath.split('/').last,
        ),
      );
      
      // Add model parameter (OpenRouter compatible)
      request.fields['model'] = 'whisper-1';
      
      // Add language hint if provided
      if (languageHint != null) {
        request.fields['language'] = languageHint;
      }
      
      // Add API key (already validated above)
      request.headers['Authorization'] = 'Bearer $apiKey';
      
      // Send the request
      final response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Transcription request timed out'),
      );
      
      // Handle the response
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        
        if (jsonResponse['text'] != null) {
          return jsonResponse['text'] as String;
        } else {
          throw Exception('Invalid response format: missing text field');
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Transcription failed: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Transcription failed: $e');
      }
    }
  }

  /// Downloads audio file from Supabase Storage
  Future<List<int>> _downloadAudioFile(String storagePath) async {
    try {
      final response = await _supabase.storage
          .from('vagus-media')
          .download(storagePath);
      
      return response;
    } catch (e) {
      throw Exception('Failed to download audio file: $e');
    }
  }

  /// Gets the transcription endpoint from configuration
  Future<String> _getTranscriptionEndpoint() async {
    try {
      // Try to get from Supabase config table first
      final configResponse = await _supabase
          .from('app_config')
          .select('value')
          .eq('key', _configKey)
          .single();
      
      if (configResponse['value'] != null) {
        return configResponse['value'] as String;
      }
    } catch (e) {
      // Config not found, continue to environment variable
    }
    
    // Fallback to environment variable or default
    return const String.fromEnvironment(_configKey, defaultValue: _defaultEndpoint);
  }

  /// Gets the API key from configuration
  Future<String?> _getApiKey() async {
    try {
      // Try to get from Supabase config table first
      final configResponse = await _supabase
          .from('app_config')
          .select('value')
          .eq('key', 'TRANSCRIPTION_API_KEY')
          .single();
      
      if (configResponse['value'] != null) {
        return configResponse['value'] as String;
      }
    } catch (e) {
      // Config not found, continue to environment variable
    }
    
    // Fallback to environment variable
    return const String.fromEnvironment('TRANSCRIPTION_API_KEY');
  }

  /// Tests the transcription service with a small audio file
  Future<bool> testConnection() async {
    try {
      // This is a simple connectivity test
      final endpoint = await _getTranscriptionEndpoint();
      final uri = Uri.parse(endpoint);
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection test timed out'),
      );
      
      // Most endpoints will return 405 Method Not Allowed for GET,
      // which means the endpoint is reachable
      return response.statusCode != 404;
    } catch (e) {
      return false;
    }
  }
}
