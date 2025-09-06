enum IncidentKind { system, push, deeplink, banner, auth, network, note }
enum TriageAction { assign, tag, close, escalate, cannedReply }

class IncidentEvent {
  final String id;
  final String ticketId;
  final IncidentKind kind;
  final String title;
  final String details;        // small, single-line preferred
  final DateTime at;
  final String by;             // userId or "system"
  
  const IncidentEvent({
    required this.id,
    required this.ticketId,
    required this.kind,
    required this.title,
    required this.details,
    required this.at,
    required this.by,
  });
}

class IncidentNote {
  final String id;
  final String ticketId;
  final String author;         // admin uid
  final String text;
  final DateTime at;
  
  const IncidentNote({
    required this.id,
    required this.ticketId,
    required this.author,
    required this.text,
    required this.at,
  });
}

class TriageRule {
  final String id;
  final String name;
  final bool enabled;
  final List<String> includeTags;   // simple contains filters
  final List<String> excludeTags;
  final List<TriageAction> actions; // order respected
  
  const TriageRule({
    required this.id,
    required this.name,
    required this.enabled,
    this.includeTags = const [],
    this.excludeTags = const [],
    this.actions = const [],
  });
}

class SavedView {
  final String id;
  final String name;
  final Map<String, dynamic> filters; // e.g. {"status":"open","assignee":"me"}
  
  const SavedView({
    required this.id,
    required this.name,
    required this.filters,
  });
}

enum SlaPriority { low, normal, high, urgent }

class SlaMeta {
  final SlaPriority priority;
  final DateTime createdAt;
  final DateTime dueAt;  // computed
  final bool breached;
  const SlaMeta({
    required this.priority,
    required this.createdAt,
    required this.dueAt,
    required this.breached,
  });

  Duration get remaining => dueAt.difference(DateTime.now());
}
