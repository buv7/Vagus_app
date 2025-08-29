import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'ai_client.dart';
import 'model_registry.dart';

class EmbeddingHelper {
  static final EmbeddingHelper _instance = EmbeddingHelper._internal();
  factory EmbeddingHelper() => _instance;
  EmbeddingHelper._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AIClient _aiClient = AIClient();
  final ModelRegistry _modelRegistry = ModelRegistry();

  Future<void> upsertNoteEmbedding(String noteId, String content) async {
    try {
      final model = _modelRegistry.modelFor('embedding.default');
      final embedding = await _aiClient.embed(model: model, input: content);

      // Convert embedding to PostgreSQL vector format
      final vectorString = '[${embedding.join(',')}]';

      // Delete existing embedding for this note
      await _supabase
          .from('note_embeddings')
          .delete()
          .eq('note_id', noteId);

      // Insert new embedding
      await _supabase.from('note_embeddings').insert({
        'note_id': noteId,
        'model': model,
        'content': content,
        'embedding': vectorString,
      });
    } catch (e) {
      // Silent failure - don't crash the app
      debugPrint('Failed to upsert note embedding: $e');
    }
  }

  Future<List<Map<String, dynamic>>> similarNotes({
    required String noteId,
    int k = 5,
  }) async {
    try {
      // Get the embedding for the source note
      final sourceResult = await _supabase
          .from('note_embeddings')
          .select('embedding')
          .eq('note_id', noteId)
          .single();

      final sourceEmbedding = sourceResult['embedding'] as String;

      // Find similar notes using cosine similarity
      final similarResult = await _supabase
          .rpc('similar_notes', params: {
            'source_embedding': sourceEmbedding,
            'exclude_note_id': noteId,
            'limit_count': k,
          });

      if (similarResult == null) {
        return [];
      }

      return List<Map<String, dynamic>>.from(similarResult);
    } catch (e) {
      // Return empty list on any error
      debugPrint('Failed to find similar notes: $e');
      return [];
    }
  }

  Future<void> upsertMessageEmbedding(String messageId, String content) async {
    try {
      final model = _modelRegistry.modelFor('embedding.default');
      final embedding = await _aiClient.embed(model: model, input: content);

      // Convert embedding to PostgreSQL vector format
      final vectorString = '[${embedding.join(',')}]';

      // Delete existing embedding for this message
      await _supabase
          .from('message_embeddings')
          .delete()
          .eq('message_id', messageId);

      // Insert new embedding
      await _supabase.from('message_embeddings').insert({
        'message_id': messageId,
        'model': model,
        'content': content,
        'embedding': vectorString,
      });
    } catch (e) {
      // Silent failure - don't crash the app
      debugPrint('Failed to upsert message embedding: $e');
    }
  }

  Future<List<Map<String, dynamic>>> similarMessages({
    required String messageId,
    int k = 5,
  }) async {
    try {
      // Get the embedding for the source message
      final sourceResult = await _supabase
          .from('message_embeddings')
          .select('embedding')
          .eq('message_id', messageId)
          .single();

      final sourceEmbedding = sourceResult['embedding'] as String;

      // Find similar messages using cosine similarity
      final similarResult = await _supabase
          .rpc('similar_messages', params: {
            'source_embedding': sourceEmbedding,
            'exclude_message_id': messageId,
            'limit_count': k,
          });

      if (similarResult == null) {
        return [];
      }

      return List<Map<String, dynamic>>.from(similarResult);
    } catch (e) {
      // Return empty list on any error
      debugPrint('Failed to find similar messages: $e');
      return [];
    }
  }

  Future<void> upsertWorkoutEmbedding(String workoutId, String content) async {
    try {
      final model = _modelRegistry.modelFor('embedding.default');
      final embedding = await _aiClient.embed(model: model, input: content);

      // Convert embedding to PostgreSQL vector format
      final vectorString = '[${embedding.join(',')}]';

      // Delete existing embedding for this workout
      await _supabase
          .from('workout_embeddings')
          .delete()
          .eq('workout_id', workoutId);

      // Insert new embedding
      await _supabase.from('workout_embeddings').insert({
        'workout_id': workoutId,
        'model': model,
        'content': content,
        'embedding': vectorString,
      });
    } catch (e) {
      // Silent failure - don't crash the app
      debugPrint('Failed to upsert workout embedding: $e');
    }
  }

  Future<List<Map<String, dynamic>>> similarWorkouts({
    required String workoutId,
    int k = 5,
  }) async {
    try {
      // Get the embedding for the source workout
      final sourceResult = await _supabase
          .from('workout_embeddings')
          .select('embedding')
          .eq('workout_id', workoutId)
          .single();

      final sourceEmbedding = sourceResult['embedding'] as String;

      // Find similar workouts using cosine similarity
      final similarResult = await _supabase
          .rpc('similar_workouts', params: {
            'source_embedding': sourceEmbedding,
            'exclude_workout_id': workoutId,
            'limit_count': k,
          });

      if (similarResult == null) {
        return [];
      }

      return List<Map<String, dynamic>>.from(similarResult);
    } catch (e) {
      // Return empty list on any error
      debugPrint('Failed to find similar workouts: $e');
      return [];
    }
  }
}
