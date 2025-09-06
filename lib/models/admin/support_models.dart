class SupportTicket {
  final String id;
  final String title;
  final String body;       // ticket description/content
  final String requesterEmail;
  final String priority;   // 'low'|'normal'|'high'|'urgent'
  final String status;     // 'open'|'pending'|'resolved'|'closed'
  final List<String> tags;
  final String? assigneeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // NEW: SLA config & timestamps (nullable, optional)
  final Duration? slaResponse;      // e.g., 4h
  final Duration? slaResolution;    // e.g., 48h
  final DateTime? firstResponseAt;  // filled when first staff reply posted
  final DateTime? resolvedAt;       // when moved to resolved
  final bool escalated;             // set by auto escalations

  SupportTicket({
    required this.id,
    required this.title,
    required this.body,
    required this.requesterEmail,
    required this.priority,
    required this.status,
    required this.tags,
    required this.assigneeId,
    required this.createdAt,
    required this.updatedAt,
    this.slaResponse,
    this.slaResolution,
    this.firstResponseAt,
    this.resolvedAt,
    this.escalated = false,
  });

  // helper accessors
  bool get isClosedLike => status == 'resolved' || status == 'closed';
  bool get responded => firstResponseAt != null;

  // ETA helpers (null means no SLA configured)
  DateTime? get responseDue =>
      slaResponse == null ? null : createdAt.add(slaResponse!);

  DateTime? get resolutionDue {
    final anchor = createdAt;
    return slaResolution == null ? null : anchor.add(slaResolution!);
  }

  bool get responseBreached =>
      responseDue != null && !responded && DateTime.now().isAfter(responseDue!);

  bool get resolutionBreached =>
      resolutionDue != null &&
      !isClosedLike &&
      DateTime.now().isAfter(resolutionDue!);

  // copyWith
  SupportTicket copyWith({
    String? status,
    String? priority,
    List<String>? tags,
    String? assigneeId,
    DateTime? firstResponseAt,
    DateTime? resolvedAt,
    bool? escalated,
  }) {
    return SupportTicket(
      id: id,
      title: title,
      body: body,
      requesterEmail: requesterEmail,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      assigneeId: assigneeId ?? this.assigneeId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      slaResponse: slaResponse,
      slaResolution: slaResolution,
      firstResponseAt: firstResponseAt ?? this.firstResponseAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      escalated: escalated ?? this.escalated,
    );
  }

  factory SupportTicket.fromJson(Map<String, dynamic> j) {
    List<String> parseTags(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const <String>[];
    }

    Duration? parseDur(dynamic v) {
      if (v == null) return null;
      // allow minutes or ISO8601-ish like "PT4H"
      if (v is int) return Duration(minutes: v);
      final s = v.toString();
      if (s.startsWith('PT') && s.endsWith('H')) {
        final h = int.tryParse(s.substring(2, s.length - 1));
        if (h != null) return Duration(hours: h);
      }
      final m = int.tryParse(s);
      return m == null ? null : Duration(minutes: m);
    }

    DateTime? parseDT(dynamic v) => v == null ? null : DateTime.parse(v as String);

    return SupportTicket(
      id: j['id'] as String,
      title: j['title'] as String,
      body: (j['body'] ?? '') as String,
      requesterEmail: j['requester_email'] as String,
      priority: (j['priority'] ?? 'normal') as String,
      status: (j['status'] ?? 'open') as String,
      tags: parseTags(j['tags']),
      assigneeId: j['assignee_id'] as String?,
      createdAt: DateTime.parse(j['created_at'] as String),
      updatedAt: DateTime.parse(j['updated_at'] as String),
      slaResponse: parseDur(j['sla_response']),
      slaResolution: parseDur(j['sla_resolution']),
      firstResponseAt: parseDT(j['first_response_at']),
      resolvedAt: parseDT(j['resolved_at']),
      escalated: (j['escalated'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'requester_email': requesterEmail,
        'priority': priority,
        'status': status,
        'tags': tags,
        'assignee_id': assigneeId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'sla_response': slaResponse?.inMinutes,
        'sla_resolution': slaResolution?.inMinutes,
        'first_response_at': firstResponseAt?.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
        'escalated': escalated,
      };
}

// Timeline types
abstract class SupportTimelineItem {
  DateTime get at;
  String get kind; // 'created'|'status'|'reply'|'assignment'|'tag'|'escalation'
  String describe();
}

class TimelineCreated implements SupportTimelineItem {
  @override final DateTime at;
  final String by;
  TimelineCreated(this.at, this.by);
  @override String get kind => 'created';
  @override String describe() => 'Ticket created by $by';
}

class TimelineReply implements SupportTimelineItem {
  @override final DateTime at;
  final String by;
  final bool byStaff;
  TimelineReply(this.at, this.by, {required this.byStaff});
  @override String get kind => 'reply';
  @override String describe() => byStaff ? 'Staff reply by $by' : 'User reply by $by';
}

class TimelineStatus implements SupportTimelineItem {
  @override final DateTime at;
  final String from;
  final String to;
  TimelineStatus(this.at, this.from, this.to);
  @override String get kind => 'status';
  @override String describe() => 'Status: $from → $to';
}

class TimelineAssignment implements SupportTimelineItem {
  @override final DateTime at;
  final String? toAssigneeId;
  TimelineAssignment(this.at, this.toAssigneeId);
  @override String get kind => 'assignment';
  @override String describe() => toAssigneeId == null ? 'Unassigned' : 'Assigned to $toAssigneeId';
}

class TimelineTags implements SupportTimelineItem {
  @override final DateTime at;
  final List<String> tags;
  TimelineTags(this.at, this.tags);
  @override String get kind => 'tag';
  @override String describe() => 'Tags: ${tags.join(', ')}';
}

class TimelineEscalation implements SupportTimelineItem {
  @override final DateTime at;
  final String level; // 'response_breach'|'resolution_breach'
  TimelineEscalation(this.at, this.level);
  @override String get kind => 'escalation';
  @override String describe() => level == 'response_breach'
      ? '⚠ Response SLA breached'
      : '⏱ Resolution SLA breached';
}
