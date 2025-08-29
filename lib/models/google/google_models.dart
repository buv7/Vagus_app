

/// Google account connection model
class GoogleAccount {
  final String userId;
  final String kind; // 'coach' or 'org'
  final String email;
  final DateTime connectedAt;
  final String? workspaceFolder;
  final Map<String, dynamic> credsMeta;

  GoogleAccount({
    required this.userId,
    required this.kind,
    required this.email,
    required this.connectedAt,
    this.workspaceFolder,
    required this.credsMeta,
  });

  factory GoogleAccount.fromJson(Map<String, dynamic> json) {
    return GoogleAccount(
      userId: json['user_id'] as String,
      kind: json['kind'] as String,
      email: json['email'] as String,
      connectedAt: DateTime.parse(json['connected_at'] as String),
      workspaceFolder: json['workspace_folder'] as String?,
      credsMeta: json['creds_meta'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'kind': kind,
      'email': email,
      'connected_at': connectedAt.toIso8601String(),
      'workspace_folder': workspaceFolder,
      'creds_meta': credsMeta,
    };
  }

  GoogleAccount copyWith({
    String? userId,
    String? kind,
    String? email,
    DateTime? connectedAt,
    String? workspaceFolder,
    Map<String, dynamic>? credsMeta,
  }) {
    return GoogleAccount(
      userId: userId ?? this.userId,
      kind: kind ?? this.kind,
      email: email ?? this.email,
      connectedAt: connectedAt ?? this.connectedAt,
      workspaceFolder: workspaceFolder ?? this.workspaceFolder,
      credsMeta: credsMeta ?? this.credsMeta,
    );
  }
}

/// Google Drive file link model
class GoogleFileLink {
  final String id;
  final String ownerId;
  final String googleId;
  final String mime;
  final String name;
  final String webUrl;
  final DateTime createdAt;

  GoogleFileLink({
    required this.id,
    required this.ownerId,
    required this.googleId,
    required this.mime,
    required this.name,
    required this.webUrl,
    required this.createdAt,
  });

  factory GoogleFileLink.fromJson(Map<String, dynamic> json) {
    return GoogleFileLink(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      googleId: json['google_id'] as String,
      mime: json['mime'] as String,
      name: json['name'] as String,
      webUrl: json['web_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'google_id': googleId,
      'mime': mime,
      'name': name,
      'web_url': webUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Google export model
class GoogleExport {
  final String id;
  final String ownerId;
  final String kind; // 'metrics', 'checkins', 'workouts', 'nutrition'
  final String status; // 'queued', 'running', 'done', 'error'
  final String? sheetUrl;
  final String? error;
  final DateTime createdAt;

  GoogleExport({
    required this.id,
    required this.ownerId,
    required this.kind,
    required this.status,
    this.sheetUrl,
    this.error,
    required this.createdAt,
  });

  factory GoogleExport.fromJson(Map<String, dynamic> json) {
    return GoogleExport(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      kind: json['kind'] as String,
      status: json['status'] as String,
      sheetUrl: json['sheet_url'] as String?,
      error: json['error'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'kind': kind,
      'status': status,
      'sheet_url': sheetUrl,
      'error': error,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCompleted => status == 'done';
  bool get hasError => status == 'error';
  bool get isInProgress => status == 'running';
  bool get isQueued => status == 'queued';
}

/// Google export schedule model (Pro feature)
class GoogleExportSchedule {
  final String id;
  final String ownerId;
  final String kind; // 'metrics', 'checkins', 'workouts', 'nutrition'
  final String cron;
  final bool active;
  final DateTime createdAt;

  GoogleExportSchedule({
    required this.id,
    required this.ownerId,
    required this.kind,
    required this.cron,
    required this.active,
    required this.createdAt,
  });

  factory GoogleExportSchedule.fromJson(Map<String, dynamic> json) {
    return GoogleExportSchedule(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      kind: json['kind'] as String,
      cron: json['cron'] as String,
      active: json['active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'kind': kind,
      'cron': cron,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Forms mapping model for coaches
class FormsMapping {
  final String id;
  final String coachId;
  final String externalId;
  final Map<String, dynamic> mapJson;
  final String webhookSecret;
  final DateTime createdAt;

  FormsMapping({
    required this.id,
    required this.coachId,
    required this.externalId,
    required this.mapJson,
    required this.webhookSecret,
    required this.createdAt,
  });

  factory FormsMapping.fromJson(Map<String, dynamic> json) {
    return FormsMapping(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      externalId: json['external_id'] as String,
      mapJson: json['map_json'] as Map<String, dynamic>? ?? {},
      webhookSecret: json['webhook_secret'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coach_id': coachId,
      'external_id': externalId,
      'map_json': mapJson,
      'webhook_secret': webhookSecret,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Target types for Drive attachments
enum DriveAttachmentTarget {
  note,
  workout,
  message,
  calendarEvent,
}

/// Extension to get display name for target types
extension DriveAttachmentTargetExtension on DriveAttachmentTarget {
  String get displayName {
    switch (this) {
      case DriveAttachmentTarget.note:
        return 'Note';
      case DriveAttachmentTarget.workout:
        return 'Workout';
      case DriveAttachmentTarget.message:
        return 'Message';
      case DriveAttachmentTarget.calendarEvent:
        return 'Calendar Event';
    }
  }
}
