import 'package:supabase_flutter/supabase_flutter.dart';
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
      print('Failed to upsert note embedding: $e');
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

      if (sourceResult == null) {
        return [];
      }

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
      print('Failed to find similar notes: $e');
      return [];
    }
  }

  // Stubs for message embeddings (TODO: implement when schema is known)
  Future<void> upsertMessageEmbedding(String messageId, String content) async {
    // TODO: Implement when message schema is finalized
    print('Message embedding upsert not yet implemented');
  }

  Future<List<Map<String, dynamic>>> similarMessages({
    required String messageId,
    int k = 5,
  }) async {
    // TODO: Implement when message schema is finalized
    print('Message similarity search not yet implemented');
    return [];
  }

  // Stubs for workout embeddings (TODO: implement when schema is known)
  Future<void> upsertWorkoutEmbedding(String workoutId, String content) async {
    // TODO: Implement when workout schema is finalized
    print('Workout embedding upsert not yet implemented');
  }

  Future<List<Map<String, dynamic>>> similarWorkouts({
    required String workoutId,
    int k = 5,
  }) async {
    // TODO: Implement when workout schema is finalized
    print('Workout similarity search not yet implemented');
    return [];
  }
}
