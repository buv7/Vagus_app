import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/knowledge/knowledge_models.dart';
import 'ai_client.dart';
import 'model_registry.dart';

class ContextualMemoryService {
  ContextualMemoryService._();
  static final ContextualMemoryService I = ContextualMemoryService._();

  final _db = Supabase.instance.client;
  final _aiClient = AIClient();
  final _modelRegistry = ModelRegistry();

  /// Surface relevant notes based on context (using embeddings similarity)
  Future<List<Map<String, dynamic>>> surfaceRelevantNotes({
    required String userId,
    required String contextKey,
    required String contextText,
    int limit = 5,
    double minSimilarity = 0.7,
  }) async {
    try {
      // Check cache first
      final cached = await getCachedMemory(userId: userId, contextKey: contextKey);
      if (cached != null && !cached.isExpired) {
        // Return cached results
        final notes = await _fetchNotesByIds(cached.relevantNoteIds);
        return notes.asMap().entries.map((entry) {
          return {
            'note': entry.value,
            'relevance_score': cached.relevanceScores[entry.key],
          };
        }).toList();
      }

      // Generate embedding for context using AIClient
      final model = _modelRegistry.modelFor('embedding.default');
      final embedding = await _aiClient.embed(model: model, input: contextText);
      
      // Format embedding as PostgreSQL vector string
      final vectorString = '[${embedding.join(',')}]';
      
      // Search notes using pgvector cosine similarity via similar_notes function
      final res = await _db.rpc('similar_notes', params: {
        'source_embedding': vectorString,
        'limit_count': limit,
      });

      if (res == null || (res is List && res.isEmpty)) return [];

      // Filter by similarity threshold and fetch note details
      final resList = res is List ? res : [];
      final filtered = resList.where((e) {
        final sim = (e['similarity'] as num?)?.toDouble() ?? 0.0;
        return sim >= minSimilarity;
      }).toList();

      if (filtered.isEmpty) return [];

      // Fetch note details for matched IDs
      final noteIds = filtered.map((e) => e['note_id'] as String).toList();
      if (noteIds.isEmpty) return [];
      
      // Use inFilter to filter by multiple IDs
      final notesRes = await _db
          .from('coach_notes')
          .select()
          .inFilter('id', noteIds);

      final notesMap = <String, Map<String, dynamic>>{};
      for (final note in notesRes as List) {
        notesMap[note['id'] as String] = note as Map<String, dynamic>;
      }

      final results = filtered.map((e) {
        final noteId = e['note_id'] as String;
        final note = notesMap[noteId];
        if (note == null) return null;
        return {
          'note': note,
          'relevance_score': (e['similarity'] as num?)?.toDouble() ?? 0.0,
        };
      }).whereType<Map<String, dynamic>>().toList();

      // Cache results
      await cacheContextualMemory(
        userId: userId,
        contextKey: contextKey,
        relevantNoteIds: results.map((r) => r['note']['id'] as String).toList(),
        relevanceScores: results.map((r) => r['relevance_score'] as double).toList(),
      );

      return results;
    } catch (e) {
      debugPrint('Failed to surface relevant notes: $e');
      return [];
    }
  }

  Future<void> cacheContextualMemory({
    required String userId,
    required String contextKey,
    required List<String> relevantNoteIds,
    required List<double> relevanceScores,
    Duration cacheDuration = const Duration(hours: 24),
  }) async {
    try {
      final expiresAt = DateTime.now().add(cacheDuration);
      final cache = ContextualMemoryCache(
        id: 'temp',
        userId: userId,
        contextKey: contextKey,
        relevantNoteIds: relevantNoteIds,
        relevanceScores: relevanceScores,
        cachedAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      await _db.from('contextual_memory_cache').upsert(
        cache.toInsertJson(),
        onConflict: 'user_id,context_key',
      );
    } catch (e) {
      debugPrint('Failed to cache contextual memory: $e');
    }
  }

  Future<ContextualMemoryCache?> getCachedMemory({
    required String userId,
    required String contextKey,
  }) async {
    try {
      final res = await _db
          .from('contextual_memory_cache')
          .select()
          .eq('user_id', userId)
          .eq('context_key', contextKey)
          .maybeSingle();

      if (res == null) return null;
      return ContextualMemoryCache.fromJson(res);
    } catch (e) {
      debugPrint('Failed to get cached memory: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNotesByIds(List<String> noteIds) async {
    if (noteIds.isEmpty) return [];

    try {
      // Use inFilter to filter by multiple IDs
      final res = await _db
          .from('coach_notes')
          .select()
          .inFilter('id', noteIds);

      return (res as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Failed to fetch notes by IDs: $e');
      return [];
    }
  }
}
