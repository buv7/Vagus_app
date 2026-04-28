/// Models for SHEETIFY — bidirectional Google Sheets sync.
/// These mirror the DB tables defined in 20260428000000_sheetify_tables.sql.

enum SyncTab { checkIns, workout, nutrition }

extension SyncTabExtension on SyncTab {
  String get dbName {
    switch (this) {
      case SyncTab.checkIns:
        return 'check_ins';
      case SyncTab.workout:
        return 'workout';
      case SyncTab.nutrition:
        return 'nutrition';
    }
  }

  String get displayName {
    switch (this) {
      case SyncTab.checkIns:
        return 'Check-ins';
      case SyncTab.workout:
        return 'Workout';
      case SyncTab.nutrition:
        return 'Nutrition';
    }
  }
}

class CoachGoogleConnection {
  final String coachId;
  final String googleEmail;
  final DateTime connectedAt;
  final bool isRevoked;

  const CoachGoogleConnection({
    required this.coachId,
    required this.googleEmail,
    required this.connectedAt,
    required this.isRevoked,
  });

  bool get isActive => !isRevoked;

  factory CoachGoogleConnection.fromJson(Map<String, dynamic> json) {
    return CoachGoogleConnection(
      coachId: json['coach_id'] as String,
      googleEmail: json['google_email'] as String,
      connectedAt: DateTime.parse(json['connected_at'] as String),
      isRevoked: json['revoked_at'] != null,
    );
  }
}

class ClientSheet {
  final String id;
  final String coachId;
  final String clientId;
  final String sheetId;
  final String sheetUrl;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;

  const ClientSheet({
    required this.id,
    required this.coachId,
    required this.clientId,
    required this.sheetId,
    required this.sheetUrl,
    this.lastSyncedAt,
    required this.createdAt,
  });

  factory ClientSheet.fromJson(Map<String, dynamic> json) {
    return ClientSheet(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      clientId: json['client_id'] as String,
      sheetId: json['sheet_id'] as String,
      sheetUrl: json['sheet_url'] as String,
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SyncConflict {
  final String id;
  final String coachId;
  final String clientId;
  final String sheetId;
  final SyncTab tab;
  final String? rowId;
  final Map<String, dynamic> localValue;
  final Map<String, dynamic> sheetValue;
  final DateTime detectedAt;
  final DateTime? resolvedAt;
  final String? resolution;

  const SyncConflict({
    required this.id,
    required this.coachId,
    required this.clientId,
    required this.sheetId,
    required this.tab,
    this.rowId,
    required this.localValue,
    required this.sheetValue,
    required this.detectedAt,
    this.resolvedAt,
    this.resolution,
  });

  bool get isResolved => resolvedAt != null;

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    final tabStr = json['tab'] as String;
    final tab = SyncTab.values.firstWhere(
      (t) => t.dbName == tabStr,
      orElse: () => SyncTab.checkIns,
    );
    return SyncConflict(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      clientId: json['client_id'] as String,
      sheetId: json['sheet_id'] as String,
      tab: tab,
      rowId: json['row_id'] as String?,
      localValue: Map<String, dynamic>.from(json['local_value'] as Map),
      sheetValue: Map<String, dynamic>.from(json['sheet_value'] as Map),
      detectedAt: DateTime.parse(json['detected_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolution: json['resolution'] as String?,
    );
  }
}

enum SyncStatus { idle, syncing, error, conflicted }

class SheetSyncState {
  final SyncStatus status;
  final int pendingConflicts;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const SheetSyncState({
    required this.status,
    required this.pendingConflicts,
    this.lastSyncedAt,
    this.errorMessage,
  });

  static const idle = SheetSyncState(status: SyncStatus.idle, pendingConflicts: 0);

  SheetSyncState copyWith({
    SyncStatus? status,
    int? pendingConflicts,
    DateTime? lastSyncedAt,
    String? errorMessage,
  }) {
    return SheetSyncState(
      status: status ?? this.status,
      pendingConflicts: pendingConflicts ?? this.pendingConflicts,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
