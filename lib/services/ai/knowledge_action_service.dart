import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/knowledge/knowledge_models.dart';

class KnowledgeActionService {
  KnowledgeActionService._();
  static final KnowledgeActionService I = KnowledgeActionService._();

  final _db = Supabase.instance.client;

  /// Extract actions from a note (using AI or pattern matching)
  Future<List<KnowledgeAction>> extractActionsFromNote({
    required String userId,
    required String noteId,
    required String noteContent,
  }) async {
    // Simple pattern-based extraction (can be enhanced with AI)
    final actions = <KnowledgeAction>[];

    // Pattern: "TODO:", "REMINDER:", "FOLLOW UP:", "ALERT:"
    final patterns = {
      'TODO:': KnowledgeActionType.task,
      'REMINDER:': KnowledgeActionType.reminder,
      'FOLLOW UP:': KnowledgeActionType.followUp,
      'ALERT:': KnowledgeActionType.alert,
    };

    for (final entry in patterns.entries) {
      if (noteContent.toUpperCase().contains(entry.key)) {
        final action = KnowledgeAction(
          id: 'temp',
          userId: userId,
          sourceNoteId: noteId,
          actionType: entry.value,
          actionData: {
            'note_id': noteId,
            'extracted_text': noteContent,
            'pattern': entry.key,
          },
          createdAt: DateTime.now(),
        );
        actions.add(action);
      }
    }

    return actions;
  }

  /// Create a knowledge action
  Future<String> createAction(KnowledgeAction action) async {
    try {
      final res = await _db
          .from('knowledge_actions')
          .insert(action.toInsertJson())
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      debugPrint('Failed to create knowledge action: $e');
      rethrow;
    }
  }

  /// Trigger an action (set triggered_at)
  Future<void> triggerAction(String actionId) async {
    try {
      await _db
          .from('knowledge_actions')
          .update({'triggered_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', actionId);
    } catch (e) {
      debugPrint('Failed to trigger action: $e');
    }
  }

  /// Complete an action
  Future<void> completeAction(String actionId) async {
    try {
      await _db
          .from('knowledge_actions')
          .update({'completed_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', actionId);
    } catch (e) {
      debugPrint('Failed to complete action: $e');
    }
  }

  /// Get pending actions for a user
  Future<List<KnowledgeAction>> getPendingActions({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final res = await _db
          .from('knowledge_actions')
          .select()
          .eq('user_id', userId)
          .isFilter('completed_at', null)
          .order('created_at', ascending: false)
          .limit(limit);

      return (res as List)
          .map((e) => KnowledgeAction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to get pending actions: $e');
      return [];
    }
  }

  /// Get actions for a specific note
  Future<List<KnowledgeAction>> getActionsForNote({
    required String noteId,
  }) async {
    try {
      final res = await _db
          .from('knowledge_actions')
          .select()
          .eq('source_note_id', noteId)
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => KnowledgeAction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to get actions for note: $e');
      return [];
    }
  }
}
