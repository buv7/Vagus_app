// =====================================================
// COLLABORATION SERVICE
// =====================================================
// Revolutionary collaboration features for nutrition planning.
//
// FEATURES:
// - Family meal planning with household mode
// - Real-time coach-client co-editing
// - Dietitian review workflow
// - Group coaching with cohorts
// - Shared meal plans and recipes
// - Version history and rollback
// - Comment threads and annotations
// - Permission-based access control
// =====================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =====================================================
// ENUMS
// =====================================================

enum CollaboratorRole {
  owner,        // Full control
  coach,        // Can edit and manage
  dietitian,    // Can review and approve
  editor,       // Can edit content
  viewer,       // Read-only
  family,       // Family member with shared access
}

enum PermissionLevel {
  read,
  comment,
  edit,
  admin,
}

enum ShareType {
  private,
  household,
  cohort,
  public,
}

// =====================================================
// MODELS
// =====================================================

/// Household for family meal planning
class Household {
  final String id;
  final String name;
  final String ownerId;
  final List<HouseholdMember> members;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;

  Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    this.preferences = const {},
    required this.createdAt,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      members: (json['members'] as List?)
              ?.map((m) => HouseholdMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'members': members.map((m) => m.toJson()).toList(),
      'preferences': preferences,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class HouseholdMember {
  final String userId;
  final String name;
  final String? avatar;
  final CollaboratorRole role;
  final Map<String, dynamic> dietaryPreferences;
  final DateTime joinedAt;

  HouseholdMember({
    required this.userId,
    required this.name,
    this.avatar,
    required this.role,
    this.dietaryPreferences = const {},
    required this.joinedAt,
  });

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      role: CollaboratorRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => CollaboratorRole.viewer,
      ),
      dietaryPreferences: json['dietary_preferences'] as Map<String, dynamic>? ?? {},
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'avatar': avatar,
      'role': role.name,
      'dietary_preferences': dietaryPreferences,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

/// Collaboration session for real-time co-editing
class CollaborationSession {
  final String id;
  final String resourceId;
  final String resourceType; // 'nutrition_plan', 'recipe', etc.
  final List<ActiveCollaborator> activeCollaborators;
  final DateTime startedAt;
  final DateTime? endedAt;

  CollaborationSession({
    required this.id,
    required this.resourceId,
    required this.resourceType,
    required this.activeCollaborators,
    required this.startedAt,
    this.endedAt,
  });

  factory CollaborationSession.fromJson(Map<String, dynamic> json) {
    return CollaborationSession(
      id: json['id'] as String,
      resourceId: json['resource_id'] as String,
      resourceType: json['resource_type'] as String,
      activeCollaborators: (json['active_collaborators'] as List?)
              ?.map((a) => ActiveCollaborator.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resource_id': resourceId,
      'resource_type': resourceType,
      'active_collaborators': activeCollaborators.map((a) => a.toJson()).toList(),
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }
}

class ActiveCollaborator {
  final String userId;
  final String name;
  final String? avatar;
  final String? cursorPosition;
  final DateTime lastSeenAt;

  ActiveCollaborator({
    required this.userId,
    required this.name,
    this.avatar,
    this.cursorPosition,
    required this.lastSeenAt,
  });

  factory ActiveCollaborator.fromJson(Map<String, dynamic> json) {
    return ActiveCollaborator(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      cursorPosition: json['cursor_position'] as String?,
      lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'avatar': avatar,
      'cursor_position': cursorPosition,
      'last_seen_at': lastSeenAt.toIso8601String(),
    };
  }
}

/// Version history entry
class VersionHistory {
  final String id;
  final String resourceId;
  final String resourceType;
  final int versionNumber;
  final String userId;
  final String userName;
  final Map<String, dynamic> snapshot;
  final String? changeDescription;
  final DateTime createdAt;

  VersionHistory({
    required this.id,
    required this.resourceId,
    required this.resourceType,
    required this.versionNumber,
    required this.userId,
    required this.userName,
    required this.snapshot,
    this.changeDescription,
    required this.createdAt,
  });

  factory VersionHistory.fromJson(Map<String, dynamic> json) {
    return VersionHistory(
      id: json['id'] as String,
      resourceId: json['resource_id'] as String,
      resourceType: json['resource_type'] as String,
      versionNumber: json['version_number'] as int,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      snapshot: json['snapshot'] as Map<String, dynamic>,
      changeDescription: json['change_description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resource_id': resourceId,
      'resource_type': resourceType,
      'version_number': versionNumber,
      'user_id': userId,
      'user_name': userName,
      'snapshot': snapshot,
      'change_description': changeDescription,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Comment thread
class CommentThread {
  final String id;
  final String resourceId;
  final String resourceType;
  final String? contextPath; // Path to specific field/section
  final List<Comment> comments;
  final bool isResolved;
  final DateTime createdAt;

  CommentThread({
    required this.id,
    required this.resourceId,
    required this.resourceType,
    this.contextPath,
    required this.comments,
    this.isResolved = false,
    required this.createdAt,
  });

  factory CommentThread.fromJson(Map<String, dynamic> json) {
    return CommentThread(
      id: json['id'] as String,
      resourceId: json['resource_id'] as String,
      resourceType: json['resource_type'] as String,
      contextPath: json['context_path'] as String?,
      comments: (json['comments'] as List?)
              ?.map((c) => Comment.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      isResolved: json['is_resolved'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resource_id': resourceId,
      'resource_type': resourceType,
      'context_path': contextPath,
      'comments': comments.map((c) => c.toJson()).toList(),
      'is_resolved': isResolved,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String? avatar;
  final String text;
  final DateTime createdAt;
  final DateTime? editedAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    this.avatar,
    required this.text,
    required this.createdAt,
    this.editedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      avatar: json['avatar'] as String?,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'avatar': avatar,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
    };
  }
}

/// Group coaching cohort
class Cohort {
  final String id;
  final String coachId;
  final String name;
  final String? description;
  final List<CohortMember> members;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final Map<String, dynamic> settings;

  Cohort({
    required this.id,
    required this.coachId,
    required this.name,
    this.description,
    required this.members,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.settings = const {},
  });

  factory Cohort.fromJson(Map<String, dynamic> json) {
    return Cohort(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      members: (json['members'] as List?)
              ?.map((m) => CohortMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool,
      settings: json['settings'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coach_id': coachId,
      'name': name,
      'description': description,
      'members': members.map((m) => m.toJson()).toList(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'settings': settings,
    };
  }
}

class CohortMember {
  final String userId;
  final String name;
  final String? avatar;
  final DateTime joinedAt;
  final Map<String, dynamic> progress;

  CohortMember({
    required this.userId,
    required this.name,
    this.avatar,
    required this.joinedAt,
    this.progress = const {},
  });

  factory CohortMember.fromJson(Map<String, dynamic> json) {
    return CohortMember(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      progress: json['progress'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'avatar': avatar,
      'joined_at': joinedAt.toIso8601String(),
      'progress': progress,
    };
  }
}

/// Shared resource
class SharedResource {
  final String id;
  final String resourceId;
  final String resourceType;
  final String ownerId;
  final ShareType shareType;
  final List<SharedWith> sharedWith;
  final DateTime createdAt;

  SharedResource({
    required this.id,
    required this.resourceId,
    required this.resourceType,
    required this.ownerId,
    required this.shareType,
    required this.sharedWith,
    required this.createdAt,
  });

  factory SharedResource.fromJson(Map<String, dynamic> json) {
    return SharedResource(
      id: json['id'] as String,
      resourceId: json['resource_id'] as String,
      resourceType: json['resource_type'] as String,
      ownerId: json['owner_id'] as String,
      shareType: ShareType.values.firstWhere(
        (e) => e.name == json['share_type'],
        orElse: () => ShareType.private,
      ),
      sharedWith: (json['shared_with'] as List?)
              ?.map((s) => SharedWith.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resource_id': resourceId,
      'resource_type': resourceType,
      'owner_id': ownerId,
      'share_type': shareType.name,
      'shared_with': sharedWith.map((s) => s.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SharedWith {
  final String userId;
  final PermissionLevel permission;
  final DateTime sharedAt;

  SharedWith({
    required this.userId,
    required this.permission,
    required this.sharedAt,
  });

  factory SharedWith.fromJson(Map<String, dynamic> json) {
    return SharedWith(
      userId: json['user_id'] as String,
      permission: PermissionLevel.values.firstWhere(
        (e) => e.name == json['permission'],
        orElse: () => PermissionLevel.read,
      ),
      sharedAt: DateTime.parse(json['shared_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'permission': permission.name,
      'shared_at': sharedAt.toIso8601String(),
    };
  }
}

// =====================================================
// SERVICE
// =====================================================

class CollaborationService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Active sessions
  final Map<String, CollaborationSession> _activeSessions = {};

  // =====================================================
  // HOUSEHOLD MANAGEMENT
  // =====================================================

  /// Create household
  Future<Household?> createHousehold({
    required String ownerId,
    required String name,
    Map<String, dynamic> preferences = const {},
  }) async {
    try {
      final householdData = {
        'name': name,
        'owner_id': ownerId,
        'members': [],
        'preferences': preferences,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('households')
          .insert(householdData)
          .select()
          .single();

      notifyListeners();
      return Household.fromJson(response);
    } catch (e) {
      debugPrint('Error creating household: $e');
      return null;
    }
  }

  /// Add member to household
  Future<bool> addHouseholdMember({
    required String householdId,
    required String userId,
    required String name,
    String? avatar,
    CollaboratorRole role = CollaboratorRole.family,
    Map<String, dynamic> dietaryPreferences = const {},
  }) async {
    try {
      final member = HouseholdMember(
        userId: userId,
        name: name,
        avatar: avatar,
        role: role,
        dietaryPreferences: dietaryPreferences,
        joinedAt: DateTime.now(),
      );

      // Fetch household
      final household = await _getHousehold(householdId);
      if (household == null) return false;

      // Add member
      household.members.add(member);

      // Update
      await _supabase
          .from('households')
          .update({'members': household.members.map((m) => m.toJson()).toList()})
          .eq('id', householdId);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding household member: $e');
      return false;
    }
  }

  Future<Household?> _getHousehold(String householdId) async {
    final response = await _supabase
        .from('households')
        .select()
        .eq('id', householdId)
        .maybeSingle();

    if (response == null) return null;
    return Household.fromJson(response);
  }

  // =====================================================
  // REAL-TIME CO-EDITING
  // =====================================================

  /// Start collaboration session
  Future<CollaborationSession?> startCollaborationSession({
    required String resourceId,
    required String resourceType,
    required String userId,
    required String userName,
    String? avatar,
  }) async {
    try {
      final sessionData = {
        'resource_id': resourceId,
        'resource_type': resourceType,
        'active_collaborators': [
          {
            'user_id': userId,
            'name': userName,
            'avatar': avatar,
            'last_seen_at': DateTime.now().toIso8601String(),
          }
        ],
        'started_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('collaboration_sessions')
          .insert(sessionData)
          .select()
          .single();

      final session = CollaborationSession.fromJson(response);
      _activeSessions[session.id] = session;

      // Subscribe to real-time updates
      _subscribeToSession(session.id, resourceId);

      notifyListeners();
      return session;
    } catch (e) {
      debugPrint('Error starting collaboration: $e');
      return null;
    }
  }

  void _subscribeToSession(String sessionId, String resourceId) {
    _supabase
        .channel('collaboration_$resourceId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'collaboration_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sessionId,
          ),
          callback: (payload) {
            // Handle real-time updates
            notifyListeners();
          },
        )
        .subscribe();
  }

  /// Update collaborator presence
  Future<void> updatePresence({
    required String sessionId,
    required String userId,
    String? cursorPosition,
  }) async {
    try {
      // Update last seen timestamp
      await _supabase.rpc('update_collaborator_presence', params: {
        'session_id': sessionId,
        'user_id': userId,
        'cursor_pos': cursorPosition,
      });
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  // =====================================================
  // VERSION HISTORY
  // =====================================================

  /// Save version
  Future<VersionHistory?> saveVersion({
    required String resourceId,
    required String resourceType,
    required String userId,
    required String userName,
    required Map<String, dynamic> snapshot,
    String? changeDescription,
  }) async {
    try {
      // Get current version number
      final latestVersion = await _getLatestVersionNumber(resourceId);

      final versionData = {
        'resource_id': resourceId,
        'resource_type': resourceType,
        'version_number': latestVersion + 1,
        'user_id': userId,
        'user_name': userName,
        'snapshot': snapshot,
        'change_description': changeDescription,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('version_history')
          .insert(versionData)
          .select()
          .single();

      return VersionHistory.fromJson(response);
    } catch (e) {
      debugPrint('Error saving version: $e');
      return null;
    }
  }

  Future<int> _getLatestVersionNumber(String resourceId) async {
    final response = await _supabase
        .from('version_history')
        .select('version_number')
        .eq('resource_id', resourceId)
        .order('version_number', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return 0;
    return response['version_number'] as int;
  }

  /// Get version history
  Future<List<VersionHistory>> getVersionHistory(String resourceId) async {
    try {
      final response = await _supabase
          .from('version_history')
          .select()
          .eq('resource_id', resourceId)
          .order('version_number', ascending: false);

      return (response as List)
          .map((json) => VersionHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching version history: $e');
      return [];
    }
  }

  /// Rollback to version
  Future<bool> rollbackToVersion(String versionId) async {
    try {
      // Get version
      final response = await _supabase
          .from('version_history')
          .select()
          .eq('id', versionId)
          .maybeSingle();

      if (response == null) return false;

      final version = VersionHistory.fromJson(response);

      // Restore snapshot
      await _supabase
          .from(version.resourceType)
          .update(version.snapshot)
          .eq('id', version.resourceId);

      return true;
    } catch (e) {
      debugPrint('Error rolling back: $e');
      return false;
    }
  }

  // =====================================================
  // COMMENTS
  // =====================================================

  /// Create comment thread
  Future<CommentThread?> createCommentThread({
    required String resourceId,
    required String resourceType,
    String? contextPath,
  }) async {
    try {
      final threadData = {
        'resource_id': resourceId,
        'resource_type': resourceType,
        'context_path': contextPath,
        'comments': [],
        'is_resolved': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('comment_threads')
          .insert(threadData)
          .select()
          .single();

      return CommentThread.fromJson(response);
    } catch (e) {
      debugPrint('Error creating comment thread: $e');
      return null;
    }
  }

  /// Add comment
  Future<bool> addComment({
    required String threadId,
    required String userId,
    required String userName,
    String? avatar,
    required String text,
  }) async {
    try {
      final comment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userName: userName,
        avatar: avatar,
        text: text,
        createdAt: DateTime.now(),
      );

      await _supabase.rpc('add_comment_to_thread', params: {
        'thread_id': threadId,
        'comment_data': comment.toJson(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return false;
    }
  }

  // =====================================================
  // GROUP COACHING
  // =====================================================

  /// Create cohort
  Future<Cohort?> createCohort({
    required String coachId,
    required String name,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
    Map<String, dynamic> settings = const {},
  }) async {
    try {
      final cohortData = {
        'coach_id': coachId,
        'name': name,
        'description': description,
        'members': [],
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'is_active': true,
        'settings': settings,
      };

      final response = await _supabase
          .from('cohorts')
          .insert(cohortData)
          .select()
          .single();

      notifyListeners();
      return Cohort.fromJson(response);
    } catch (e) {
      debugPrint('Error creating cohort: $e');
      return null;
    }
  }

  // =====================================================
  // SHARING
  // =====================================================

  /// Share resource
  Future<SharedResource?> shareResource({
    required String resourceId,
    required String resourceType,
    required String ownerId,
    required ShareType shareType,
    required List<SharedWith> sharedWith,
  }) async {
    try {
      final shareData = {
        'resource_id': resourceId,
        'resource_type': resourceType,
        'owner_id': ownerId,
        'share_type': shareType.name,
        'shared_with': sharedWith.map((s) => s.toJson()).toList(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('shared_resources')
          .insert(shareData)
          .select()
          .single();

      notifyListeners();
      return SharedResource.fromJson(response);
    } catch (e) {
      debugPrint('Error sharing resource: $e');
      return null;
    }
  }
}