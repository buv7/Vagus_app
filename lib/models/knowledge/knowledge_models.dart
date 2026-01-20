import 'package:flutter/foundation.dart';

enum KnowledgeActionType {
  reminder,
  task,
  followUp,
  alert;

  String get label {
    switch (this) {
      case KnowledgeActionType.reminder:
        return 'Reminder';
      case KnowledgeActionType.task:
        return 'Task';
      case KnowledgeActionType.followUp:
        return 'Follow Up';
      case KnowledgeActionType.alert:
        return 'Alert';
    }
  }

  String toDb() => name;

  static KnowledgeActionType fromDb(String value) {
    return KnowledgeActionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => KnowledgeActionType.reminder,
    );
  }
}

@immutable
class ContextualMemoryCache {
  final String id;
  final String userId;
  final String contextKey;
  final List<String> relevantNoteIds;
  final List<double> relevanceScores;
  final DateTime cachedAt;
  final DateTime expiresAt;

  const ContextualMemoryCache({
    required this.id,
    required this.userId,
    required this.contextKey,
    required this.relevantNoteIds,
    required this.relevanceScores,
    required this.cachedAt,
    required this.expiresAt,
  });

  factory ContextualMemoryCache.fromJson(Map<String, dynamic> json) {
    return ContextualMemoryCache(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contextKey: json['context_key'] as String,
      relevantNoteIds: List<String>.from(json['relevant_note_ids'] as List),
      relevanceScores: (json['relevance_scores'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      cachedAt: DateTime.parse(json['cached_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'context_key': contextKey,
      'relevant_note_ids': relevantNoteIds,
      'relevance_scores': relevanceScores,
      'expires_at': expiresAt.toUtc().toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

@immutable
class KnowledgeAction {
  final String id;
  final String userId;
  final String? sourceNoteId;
  final KnowledgeActionType actionType;
  final Map<String, dynamic> actionData;
  final DateTime? triggeredAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const KnowledgeAction({
    required this.id,
    required this.userId,
    this.sourceNoteId,
    required this.actionType,
    required this.actionData,
    this.triggeredAt,
    this.completedAt,
    required this.createdAt,
  });

  factory KnowledgeAction.fromJson(Map<String, dynamic> json) {
    return KnowledgeAction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sourceNoteId: json['source_note_id'] as String?,
      actionType: KnowledgeActionType.fromDb(json['action_type'] as String),
      actionData: json['action_data'] as Map<String, dynamic>,
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'source_note_id': sourceNoteId,
      'action_type': actionType.toDb(),
      'action_data': actionData, // JSONB column accepts Map directly
      'triggered_at': triggeredAt?.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
    };
  }

  bool get isCompleted => completedAt != null;
  bool get isTriggered => triggeredAt != null;
}

@immutable
class SharedKnowledge {
  final String id;
  final String coachId;
  final String clientId;
  final String? sourceNoteId;
  final String sharedContent;
  final DateTime sharedAt;
  final DateTime? viewedAt;

  const SharedKnowledge({
    required this.id,
    required this.coachId,
    required this.clientId,
    this.sourceNoteId,
    required this.sharedContent,
    required this.sharedAt,
    this.viewedAt,
  });

  factory SharedKnowledge.fromJson(Map<String, dynamic> json) {
    return SharedKnowledge(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      clientId: json['client_id'] as String,
      sourceNoteId: json['source_note_id'] as String?,
      sharedContent: json['shared_content'] as String,
      sharedAt: DateTime.parse(json['shared_at'] as String),
      viewedAt: json['viewed_at'] != null
          ? DateTime.parse(json['viewed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'coach_id': coachId,
      'client_id': clientId,
      'source_note_id': sourceNoteId,
      'shared_content': sharedContent,
    };
  }

  bool get isViewed => viewedAt != null;
}
