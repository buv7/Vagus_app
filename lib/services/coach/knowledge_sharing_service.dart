import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/knowledge/knowledge_models.dart';

class KnowledgeSharingService {
  KnowledgeSharingService._();
  static final KnowledgeSharingService I = KnowledgeSharingService._();

  final _db = Supabase.instance.client;

  /// Share knowledge from a coach note with a client
  Future<String> shareKnowledgeWithClient({
    required String coachId,
    required String clientId,
    required String sharedContent,
    String? sourceNoteId,
  }) async {
    try {
      final shared = SharedKnowledge(
        id: 'temp',
        coachId: coachId,
        clientId: clientId,
        sourceNoteId: sourceNoteId,
        sharedContent: sharedContent,
        sharedAt: DateTime.now(),
        viewedAt: null,
      );

      final res = await _db
          .from('shared_knowledge')
          .insert(shared.toInsertJson())
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      debugPrint('Failed to share knowledge: $e');
      rethrow;
    }
  }

  /// Get shared knowledge for a client
  Future<List<SharedKnowledge>> getSharedKnowledgeForClient({
    required String clientId,
    int limit = 50,
  }) async {
    try {
      final res = await _db
          .from('shared_knowledge')
          .select()
          .eq('client_id', clientId)
          .order('shared_at', ascending: false)
          .limit(limit);

      return (res as List)
          .map((e) => SharedKnowledge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to get shared knowledge: $e');
      return [];
    }
  }

  /// Get shared knowledge by a coach
  Future<List<SharedKnowledge>> getSharedKnowledgeByCoach({
    required String coachId,
    int limit = 50,
  }) async {
    try {
      final res = await _db
          .from('shared_knowledge')
          .select()
          .eq('coach_id', coachId)
          .order('shared_at', ascending: false)
          .limit(limit);

      return (res as List)
          .map((e) => SharedKnowledge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to get shared knowledge by coach: $e');
      return [];
    }
  }

  /// Mark shared knowledge as viewed
  Future<void> markAsViewed(String sharedKnowledgeId) async {
    try {
      await _db
          .from('shared_knowledge')
          .update({'viewed_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', sharedKnowledgeId);
    } catch (e) {
      debugPrint('Failed to mark as viewed: $e');
    }
  }

  /// Revoke shared knowledge (delete)
  Future<void> revokeSharedKnowledge(String sharedKnowledgeId) async {
    try {
      await _db.from('shared_knowledge').delete().eq('id', sharedKnowledgeId);
    } catch (e) {
      debugPrint('Failed to revoke shared knowledge: $e');
    }
  }
}
