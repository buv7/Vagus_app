// No imports needed for this file

enum TicketStatus { open, pending, solved, archived }
enum TicketPriority { low, normal, high, urgent }

class TicketSummary {
  final String id;
  final String subject;
  final String requesterName;
  final String? assigneeName;
  final String? userId; // User ID for Session Co-Pilot integration
  final TicketStatus status;
  final TicketPriority priority;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? lastReplyAt;
  final Duration age;

  const TicketSummary({
    required this.id,
    required this.subject,
    required this.requesterName,
    this.assigneeName,
    this.userId,
    required this.status,
    required this.priority,
    this.tags = const [],
    required this.createdAt,
    this.lastReplyAt,
    required this.age,
  });
}

class TicketDetail {
  final TicketSummary meta;
  final String body;
  final List<TicketMessage> thread; // newest last

  const TicketDetail({
    required this.meta, 
    required this.body, 
    this.thread = const []
  });
}

class TicketMessage {
  final String id;
  final String author;
  final DateTime at;
  final String text;
  final bool internalNote;

  const TicketMessage({
    required this.id, 
    required this.author, 
    required this.at, 
    required this.text, 
    this.internalNote=false
  });
}

class EscalationRule {
  final String id;
  final String name;
  final List<String> matchTags;             // any-of
  final TicketPriority? minPriority;
  final Duration? maxFirstResponse;         // breach triggers
  final Duration? maxResolution;            // breach triggers
  final String actionAssignGroup;           // e.g., 'L2', 'Billing', 'iOS'
  final List<String> actionAddTags;         // tags to add
  final TicketPriority? actionSetPriority;
  final bool notifySlack;                   // stubbed to analytics log

  const EscalationRule({
    required this.id,
    required this.name,
    this.matchTags = const [],
    this.minPriority,
    this.maxFirstResponse,
    this.maxResolution,
    this.actionAssignGroup = '',
    this.actionAddTags = const [],
    this.actionSetPriority,
    this.notifySlack = false,
  });
}

class Playbook {
  final String id;
  final String title;
  final List<PlayStep> steps;
  final List<String> tags; // categorization

  const Playbook({
    required this.id, 
    required this.title, 
    this.steps = const [], 
    this.tags = const []
  });
}

class PlayStep {
  final String kind; // 'reply'|'note'|'assign'|'tag'|'status'|'macro'
  final String value;

  const PlayStep({
    required this.kind, 
    required this.value
  });
}
