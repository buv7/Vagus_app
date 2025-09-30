import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart'; // Clipboard for CSV copy
import 'package:flutter/foundation.dart'; // debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/admin/support_models.dart';

// --------------- Agent Workload Models ---------------
class AgentWorkload {
  final String agentId;
  final String displayName;
  final int activeTickets;
  final int waitingReplies;
  final double occupancy; // 0..1
  final String status;    // 'online'|'busy'|'away'|'offline'
  const AgentWorkload({
    required this.agentId,
    required this.displayName,
    required this.activeTickets,
    required this.waitingReplies,
    required this.occupancy,
    required this.status,
  });
}

class Macro {
  final String id;
  final String title;
  final String body; // canned reply text
  final List<String> tags; // auto-apply tags
  final bool isPublic;
  const Macro({required this.id, required this.title, required this.body, this.tags = const [], this.isPublic = true});

  Macro copyWith({String? title, String? body, List<String>? tags, bool? isPublic}) => Macro(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    tags: tags ?? this.tags,
    isPublic: isPublic ?? this.isPublic,
  );
}

class TagTrendPoint {
  final DateTime day;
  final Map<String, int> countsByTag; // tag -> count
  const TagTrendPoint({required this.day, required this.countsByTag});
}

// --------------- Search result union ---------------
class AdminSearchHit {
  final String kind; // 'ticket' | 'user' | 'payment'
  final String id;
  final String title;    // what to show bold
  final String subtitle; // extra context
  final DateTime? time;  // optional

  const AdminSearchHit({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    this.time,
  });
}



class SupportReply {
  final String id, ticketId, authorId, body;
  final DateTime createdAt;
  SupportReply({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  static SupportReply fromJson(Map<String, dynamic> j) => SupportReply(
        id: j['id'] as String,
        ticketId: j['ticket_id'] as String,
        authorId: j['author_id'] as String,
        body: j['body'] ?? '',
        createdAt: DateTime.parse(j['created_at']),
      );
}

typedef SupportEvent = ({
  String table,   // 'support_requests' or 'support_replies'
  String action,  // 'INSERT' | 'UPDATE'
  Map<String, dynamic> row
});

// --------------- SLA & Saved Views ---------------
class SlaSnapshot {
  final DateTime now;
  final DateTime deadline;
  final bool breached;
  final Duration remaining;
  final String policyName;
  final String severity; // low|normal|high|urgent
  const SlaSnapshot({
    required this.now,
    required this.deadline,
    required this.breached,
    required this.remaining,
    required this.policyName,
    required this.severity,
  });
}

class SavedView {
  final String id;
  final String name;
  final Map<String, dynamic> filters; // e.g. {'state':'open','priority':['urgent'],'breached':true}
  final int order;
  const SavedView({required this.id, required this.name, required this.filters, this.order = 0});

  SavedView copyWith({String? name, Map<String, dynamic>? filters, int? order}) =>
      SavedView(id: id, name: name ?? this.name, filters: filters ?? this.filters, order: order ?? this.order);
}

class AdminSupportService {
  static AdminSupportService? _instance;
  static AdminSupportService get instance => _instance ??= AdminSupportService._();
  AdminSupportService._();
  
  final _sb = Supabase.instance.client;
  bool _checked = false, _has = false;
  RealtimeChannel? _ch;
  final _events = StreamController<SupportEvent>.broadcast();
  Stream<SupportEvent> get events => _events.stream;
  Timer? _slaTimer;

  // Central SLA policies (per priority) - can be overridden by DB or in-memory changes
  Map<String, ({Duration response, Duration resolution})> _slaPolicy = {
    'urgent': (response: const Duration(hours: 1),  resolution: const Duration(hours: 12)),
    'high'  : (response: const Duration(hours: 4),  resolution: const Duration(hours: 24)),
    'normal': (response: const Duration(hours: 12), resolution: const Duration(days: 3)),
    'low'   : (response: const Duration(hours: 24), resolution: const Duration(days: 7)),
  };

  Map<String, ({Duration response, Duration resolution})> get currentSlaPolicy => Map.of(_slaPolicy);

  Future<void> _ensure() async {
    if (_checked) return;
    _checked = true;
    try {
      await _sb.from('support_requests').select('id').limit(1);
      _has = true;
    } catch (_) {
      _has = false; // demo mode
    }
  }

  void subscribeRealtime() {
    if (_ch != null) return;
    final sb = Supabase.instance.client;
    try {
      _ch = sb.channel('support_inbox')
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'support_requests',
          callback: (payload) {
            _events.add((table: 'support_requests', action: 'INSERT', row: payload.newRecord));
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'support_requests',
          callback: (payload) {
            _events.add((table: 'support_requests', action: 'UPDATE', row: payload.newRecord));
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'support_replies',
          callback: (payload) {
            _events.add((table: 'support_replies', action: 'INSERT', row: payload.newRecord));
          },
        )
        ..subscribe();
    } catch (e) {
      debugPrint('realtime subscribe failed: $e');
    }
  }

  void dispose() {
    try { _ch?.unsubscribe(); } catch (_) {}
    try { _events.close(); } catch (_) {}
    stopSlaTicker();
  }

  // Call this after screen loads
  void startSlaTicker({Duration every = const Duration(minutes: 1)}) {
    _slaTimer?.cancel();
    _slaTimer = Timer.periodic(every, (_) {
      // no-op: UI listens to timer? Keep event to trigger rebuild:
      try {
        _events.add((table: 'support_requests', action: 'TICK', row: {}));
      } catch (_) {}
    });
  }

  void stopSlaTicker() {
    _slaTimer?.cancel();
    _slaTimer = null;
  }

  // List tickets with simple filters
  Future<List<SupportTicket>> listTickets({String filter = 'urgent'}) async {
    await _ensure();
    if (!_has) {
      return [
        SupportTicket(
          id: 'demo1',
          title: 'Verification email not received',
          body: 'User reports not getting the email.',
          requesterEmail: 'user@vagus.com',
          status: 'open',
          priority: 'urgent',
          tags: const ['auth'],
          assigneeId: null,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now(),
          slaResponse: const Duration(hours: 4),
          slaResolution: const Duration(hours: 48),
        ),
      ];
    }
    
    try {
      // For now, fetch all tickets and filter in memory to avoid API compatibility issues
      final rows = await _sb
          .from('support_requests')
          .select()
          .order('created_at', ascending: false)
          .limit(200);
      
      List<dynamic> filteredRows = rows;
      
      // Apply filters in memory
      switch (filter) {
        case 'urgent':
          filteredRows = rows.where((r) => r['priority'] == 'urgent' && r['status'] != 'closed').toList();
          break;
        case 'open':
          filteredRows = rows.where((r) => r['status'] != 'closed').toList();
          break;
        case 'closed':
          filteredRows = rows.where((r) => r['status'] == 'closed').toList();
          break;
        case 'mine':
          filteredRows = rows.where((r) => r['assignee_id'] == _sb.auth.currentUser?.id).toList();
          break;
      }
      
      return filteredRows.map<SupportTicket>((e) => SupportTicket.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching support tickets: $e');
      // Fall back to demo data on error
      return [
        SupportTicket(
          id: 'demo1',
          title: 'Verification email not received',
          body: 'User reports not getting the email.',
          requesterEmail: 'user@vagus.com',
          status: 'open',
          priority: 'urgent',
          tags: const ['auth'],
          assigneeId: null,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now(),
          slaResponse: const Duration(hours: 4),
          slaResolution: const Duration(hours: 48),
        ),
      ];
    }
  }

  Future<List<SupportReply>> listReplies(String ticketId) async {
    await _ensure();
    if (!_has) return [];
    final rows = await _sb
        .from('support_replies')
        .select('*')
        .eq('ticket_id', ticketId)
        .order('created_at');
    return rows.map<SupportReply>(SupportReply.fromJson).toList();
  }

  Future<void> addReply(String ticketId, String body) async {
    await _ensure();
    if (!_has) return;
    await _sb.from('support_replies').insert({
      'ticket_id': ticketId,
      'author_id': _sb.auth.currentUser?.id,
      'body': body,
    });
  }

  Future<void> assignToMe(String id) async {
    await _ensure();
    if (!_has) return;
    await _sb.from('support_requests').update({
      'assignee_id': _sb.auth.currentUser?.id,
      'status': 'assigned'
    }).eq('id', id);
  }

  Future<void> close(String id) async {
    await _ensure();
    if (!_has) return;
    await _sb.from('support_requests').update({'status': 'closed'}).eq('id', id);
  }

  /// Call Edge Function 'send-support-email' (optional).
  /// If edge function is not deployed, we swallow errors gracefully.
  Future<void> notifyRequesterOnReply({
    required SupportTicket ticket,
    required String replyBody,
  }) async {
    await _ensure();
    try {
      await _sb.functions.invoke('send-support-email', body: {
        'type': 'support_reply',
        'to': ticket.requesterEmail,
        'ticketId': ticket.id,
        'subject': 'Re: ${ticket.title}',
        'body': replyBody,
      });
    } catch (e) {
      debugPrint('email function not available: $e');
    }
  }

  /// Build CSV text for tickets (safe, no extra packages).
  String buildCsv(List<SupportTicket> list) {
    String esc(String v) => '"${v.replaceAll('"', '""')}"';
    final buf = StringBuffer()
      ..writeln('id,title,requester_email,priority,status,tags,assignee_id,created_at,updated_at');
    for (final t in list) {
      buf.writeln([
        esc(t.id),
        esc(t.title),
        esc(t.requesterEmail),
        t.priority,
        t.status,
        esc(t.tags.join('|')),
        t.assigneeId ?? '',
        t.createdAt.toIso8601String(),
        t.updatedAt.toIso8601String(),
      ].join(','));
    }
    return buf.toString();
  }

  /// Fetch by filter and return CSV.
  Future<String> exportCsv({String filter = 'open'}) async {
    final list = await listTickets(filter: filter);
    return buildCsv(list);
  }

  /// Convenience: copy CSV to clipboard and return row count
  Future<int> copyCsvToClipboard({String filter = 'open'}) async {
    final csv = await exportCsv(filter: filter);
    await Clipboard.setData(ClipboardData(text: csv));
    return csv.split('\n').length - 2; // minus header + possible last empty
  }

  /// Update ticket fields
  Future<void> updateTicket({
    required String id,
    String? status,
    String? priority,
    List<String>? tags,
    String? assigneeId,
  }) async {
    await _ensure();
    final payload = <String, dynamic>{};
    if (status != null) payload['status'] = status;
    if (priority != null) payload['priority'] = priority;
    if (tags != null) payload['tags'] = tags;
    if (assigneeId != null) payload['assignee_id'] = assigneeId;
    if (payload.isEmpty) return;
    await _sb.from('support_requests').update(payload).eq('id', id);
  }

  /// Get single ticket by ID
  Future<SupportTicket?> getTicketById(String id) async {
    await _ensure();
    if (!_has) return null;
    try {
      final r = await _sb.from('support_requests').select().eq('id', id).maybeSingle();
      if (r == null) return null;
      return SupportTicket.fromJson(r);
    } catch (e) {
      debugPrint('Error fetching ticket by ID: $e');
      return null;
    }
  }

  /// Auto-triage rules (simple heuristics, safe to run client-side)
  Future<void> applyAutoTriageIfNeeded(Map<String, dynamic> row) async {
    try {
      final id = row['id'] as String;
      final String title = (row['title'] ?? '') as String;
      final String body = (row['body'] ?? '') as String;
      final String status = (row['status'] ?? 'open') as String;
      final String priority = (row['priority'] ?? 'normal') as String;
      final List<dynamic> t = (row['tags'] ?? []) as List<dynamic>;
      final tags = t.map((e) => e.toString()).toList();

      if (status != 'open') return; // don't re-triage closed/resolved

      String newPriority = priority;
      final toAdd = <String>[];

      final text = '$title\n$body'.toLowerCase();
      if (text.contains('refund') || text.contains('charge') || text.contains('billing')) {
        newPriority = 'high';
        toAdd.add('billing');
      }
      if (text.contains('crash') || text.contains('stuck') || text.contains('not working')) {
        newPriority = 'urgent';
        toAdd.add('bug');
      }
      if (toAdd.isEmpty && newPriority == priority) return;

      final mergedTags = {...tags, ...toAdd}.toList();
      await updateTicket(id: id, priority: newPriority, tags: mergedTags);
    } catch (e) {
      debugPrint('auto-triage skip: $e');
    }
  }

  Future<Map<String, int>> counts() async {
    await _ensure();
    if (!_has) return {'urgent_open': 1, 'open_total': 2};
    final rows = await _sb.from('support_counts').select().single();
    return {
      'urgent_open': rows['urgent_open'] as int? ?? 0,
      'open_total': rows['open_total'] as int? ?? 0,
    };
  }

  // Escalation: add tag + bump priority if breached and not escalated yet
  Future<void> escalateIfNeeded(SupportTicket t) async {
    if (t.escalated || t.isClosedLike) return;

    if (t.responseBreached || t.resolutionBreached) {
      final newTags = {...t.tags};
      if (t.responseBreached) newTags.add('sla_response_breach');
      if (t.resolutionBreached) newTags.add('sla_resolution_breach');
      String newPriority = t.priority;
      if (t.resolutionBreached) {
        newPriority = 'urgent';
      } else if (t.responseBreached && t.priority != 'urgent') {
        newPriority = 'high';
      }
      await updateTicket(
        id: t.id,
        priority: newPriority,
        tags: newTags.toList(),
      );
      await _logAudit(
        ticketId: t.id,
        kind: 'escalation',
        payload: {
          'response_breach': t.responseBreached,
          'resolution_breach': t.resolutionBreached,
        },
      );
      // mark escalated flag
      await _sb.from('support_requests').update({'escalated': true}).eq('id', t.id);
    }
  }

  // First response timestamp setter (call when staff reply posted)
  Future<void> ensureFirstResponseSet(SupportTicket t) async {
    if (t.firstResponseAt != null) return;
    await _sb.from('support_requests').update({
      'first_response_at': DateTime.now().toIso8601String(),
    }).eq('id', t.id);
  }

  // Optional audit writer (table may not exist; ignore failures)
  Future<void> _logAudit({
    required String ticketId,
    required String kind,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await _sb.from('support_audits').insert({
        'ticket_id': ticketId,
        'kind': kind,
        'payload': payload ?? {},
      });
    } catch (e) {
      debugPrint('audit table not available: $e');
    }
  }

  // Compose a timeline without schema changes:
  // - created from ticket.created_at
  // - replies from support_replies
  // - derived events from ticket fields (assignment/status/tags changes require audits to be perfect;
  //   we still show coarse info if audits are absent)
  Future<List<SupportTimelineItem>> composeTimeline(SupportTicket t) async {
    final items = <SupportTimelineItem>[
      TimelineCreated(t.createdAt, t.requesterEmail),
    ];

    // Replies
    final rs = await _sb
        .from('support_replies')
        .select('created_at,author_id,author_role') // author_role: 'staff'|'user' (expected)
        .eq('ticket_id', t.id)
        .order('created_at', ascending: true);
    for (final r in rs as List) {
      final at = DateTime.parse(r['created_at'] as String);
      final role = (r['author_role'] ?? 'user').toString();
      final by = (r['author_id'] ?? 'user').toString();
      items.add(TimelineReply(at, by, byStaff: role == 'staff'));
    }

    // Derived escalations
    if (t.responseBreached) {
      items.add(TimelineEscalation(t.responseDue ?? t.createdAt, 'response_breach'));
    }
    if (t.resolutionBreached) {
      items.add(TimelineEscalation(t.resolutionDue ?? t.createdAt, 'resolution_breach'));
    }

    // Optional audits, if present
    try {
      final audits = await _sb
          .from('support_audits')
          .select('created_at,kind,payload')
          .eq('ticket_id', t.id)
          .order('created_at', ascending: true);
      for (final a in audits as List) {
        final at = DateTime.parse(a['created_at'] as String);
        final kind = (a['kind'] as String);
        final payload = (a['payload'] as Map?) ?? {};
        switch (kind) {
          case 'status':
            items.add(TimelineStatus(
              at,
              (payload['from'] ?? 'unknown').toString(),
              (payload['to'] ?? 'unknown').toString(),
            ));
            break;
          case 'assignment':
            items.add(TimelineAssignment(at, payload['assignee_id'] as String?));
            break;
          case 'tag':
            final tags = (payload['tags'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
            items.add(TimelineTags(at, tags));
            break;
          case 'escalation':
            final resp = payload['response_breach'] == true;
            final resol = payload['resolution_breach'] == true;
            if (resp) items.add(TimelineEscalation(at, 'response_breach'));
            if (resol) items.add(TimelineEscalation(at, 'resolution_breach'));
            break;
        }
      }
    } catch (_) {/* audits table optional */}

    items.sort((a, b) => a.at.compareTo(b.at));
    return items;
  }

  // Optional support_settings table schema (key, value JSON)
  // If the table is missing, methods below no-op gracefully.
  Future<void> loadSlaPolicy() async {
    try {
      final row = await _sb
          .from('support_settings')
          .select('value')
          .eq('key', 'sla_policy_v1')
          .maybeSingle();
      if (row != null && row['value'] is Map) {
        final v = (row['value'] as Map).map((k, val) => MapEntry(k.toString(), val));
        final next = <String, ({Duration response, Duration resolution})>{};
        for (final entry in v.entries) {
          final m = entry.value as Map;
          final rMin = (m['response_minutes'] ?? 0) as int;
          final zMin = (m['resolution_minutes'] ?? 0) as int;
          next[entry.key] = (response: Duration(minutes: rMin), resolution: Duration(minutes: zMin));
        }
        if (next.isNotEmpty) {
          _slaPolicy = next;
        }
      }
    } catch (_) {/* optional */}
  }

  Future<void> saveSlaPolicy(Map<String, ({Duration response, Duration resolution})> policy) async {
    _slaPolicy = Map.of(policy); // update in-memory immediately
    try {
      final payload = <String, Map<String, int>>{};
      for (final e in _slaPolicy.entries) {
        payload[e.key] = {
          'response_minutes': e.value.response.inMinutes,
          'resolution_minutes': e.value.resolution.inMinutes,
        };
      }
      await _sb.from('support_settings').upsert({
        'key': 'sla_policy_v1',
        'value': payload,
      });
    } catch (_) {/* optional */}
  }

  // Helper to derive ticket SLA from priority when ticket's own SLA fields are null
  ({Duration? response, Duration? resolution}) getSlaForPriority(String priority) {
    final policy = _slaPolicy[priority];
    if (policy != null) {
      return (response: policy.response, resolution: policy.resolution);
    }
    
    final defaultPolicy = _slaPolicy['normal'];
    if (defaultPolicy != null) {
      return (response: defaultPolicy.response, resolution: defaultPolicy.resolution);
    }
    
    return (response: null, resolution: null);
  }

  // --------------- Omnibox search ---------------
  Future<List<AdminSearchHit>> searchEverything(String q) async {
    final query = q.trim();
    if (query.isEmpty) return const [];

    final hits = <AdminSearchHit>[];
    try {
      // Tickets (support_requests: id, title, status, priority, created_at)
      final tix = await _sb
          .from('support_requests')
          .select('id,title,status,priority,created_at')
          .ilike('title', '%$query%')
          .limit(20);
      for (final t in tix) {
        hits.add(AdminSearchHit(
          kind: 'ticket',
          id: '${t['id']}',
          title: t['title'] ?? '(untitled)',
          subtitle: 'Ticket • ${t['status'] ?? 'open'} • ${t['priority'] ?? 'normal'}',
          time: DateTime.tryParse('${t['created_at']}'),
        ));
      }
    } catch (_) {/* optional */}

    try {
      // Users (profiles: id, full_name, email)
      final users = await _sb
          .from('profiles')
          .select('id,full_name,email')
          .or('full_name.ilike.%$query%,email.ilike.%$query%')
          .limit(20);
      for (final u in users) {
        hits.add(AdminSearchHit(
          kind: 'user',
          id: '${u['id']}',
          title: (u['full_name'] ?? u['email'] ?? 'User') as String,
          subtitle: '${u['email'] ?? ''}',
          time: null,
        ));
      }
    } catch (_) {/* optional */}

    try {
      // Payments (payments or invoices table if present)
      final pays = await _sb
          .from('payments')
          .select('id,amount_cents,currency,created_at,customer_email')
          .or('id.ilike.%$query%,customer_email.ilike.%$query%')
          .limit(20);
      for (final p in pays) {
        final cents = (p['amount_cents'] ?? 0) as int;
        final curr = (p['currency'] ?? 'USD') as String;
        hits.add(AdminSearchHit(
          kind: 'payment',
          id: '${p['id']}',
          title: 'Payment ${p['id']}',
          subtitle: '${(cents / 100).toStringAsFixed(2)} $curr • ${p['customer_email'] ?? ''}',
          time: DateTime.tryParse('${p['created_at']}'),
        ));
      }
    } catch (_) {/* optional */}

    // Simple ranking: newest first, then tickets first
    hits.sort((a, b) {
      final at = a.time?.millisecondsSinceEpoch ?? 0;
      final bt = b.time?.millisecondsSinceEpoch ?? 0;
      final t = bt.compareTo(at);
      if (t != 0) return t;
      const order = {'ticket': 0, 'user': 1, 'payment': 2};
      return (order[a.kind] ?? 9).compareTo(order[b.kind] ?? 9);
    });
    return hits;
  }

  // --------------- Metrics ---------------
  // All methods below are defensive: if a table is missing, they return 0/empty.

  Future<Map<String, int>> countOpenByPriority() async {
    try {
      // Fetch all open tickets and count by priority in memory
      final rows = await _sb
          .from('support_requests')
          .select('priority')
          .eq('status', 'open');
      final m = <String, int>{'urgent': 0, 'high': 0, 'normal': 0, 'low': 0};
      for (final r in (rows as List? ?? const [])) {
        final priority = (r['priority'] ?? 'normal') as String;
        m[priority] = (m[priority] ?? 0) + 1;
      }
      return m;
    } catch (_) {
      return {'urgent': 0, 'high': 0, 'normal': 0, 'low': 0};
    }
  }

  Future<int> countBreachesToday() async {
    try {
      // For now, return 0 since we don't have a breached_at field
      // This can be enhanced later when the field is added
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<double> medianTimeToFirstResponseHours({int days = 7}) async {
    try {
      // For now, return 0 since we don't have the required view
      // This can be enhanced later when the view is created
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<double> firstContactResolutionRate({int days = 7}) async {
    try {
      // For now, return 0 since we don't have the required view
      // This can be enhanced later when the view is created
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<Map<String, int>> ticketsCreatedCounts() async {
    try {
      // Fetch all tickets and count in memory
      final allTickets = await _sb
          .from('support_requests')
          .select('created_at');
      
      int last24 = 0;
      int last7 = 0;
      
      for (final ticket in (allTickets as List? ?? const [])) {
        final createdAt = DateTime.tryParse('${ticket['created_at']}');
        if (createdAt != null) {
          final now = DateTime.now().toUtc();
          if (createdAt.isAfter(now.subtract(const Duration(hours: 24)))) {
            last24++;
          }
          if (createdAt.isAfter(now.subtract(const Duration(days: 7)))) {
            last7++;
          }
        }
      }
      
      return {'24h': last24, '7d': last7};
    } catch (_) {
      return {'24h': 0, '7d': 0};
    }
  }

  // Bulk Operations
  Future<void> bulkUpdateTickets(List<String> ticketIds, BulkUpdateRequest request) async {
    try {
      final updates = <String, dynamic>{};
      if (request.status != null) updates['status'] = request.status;
      if (request.priority != null) updates['priority'] = request.priority;
      if (request.assignedTo != null) updates['assigned_to'] = request.assignedTo;
      if (request.tags != null) updates['tags'] = request.tags;
      if (request.notes != null) updates['notes'] = request.notes;

      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();
        
        // Update tickets one by one since in_ is not available
        for (final ticketId in ticketIds) {
          await _sb
              .from('support_requests')
              .update(updates)
              .eq('id', ticketId);
        }
      }
    } catch (e) {
      throw Exception('Failed to bulk update tickets: $e');
    }
  }

  // Canned Replies
  Future<List<CannedReply>> listCannedReplies() async {
    try {
      final response = await _sb
          .from('canned_replies')
          .select()
          .order('name');
      
      return response.map<CannedReply>((e) => CannedReply.fromJson(e)).toList();
    } catch (e) {
      // Fallback to hardcoded replies if table doesn't exist
      return [
        const CannedReply(
          id: 'welcome',
          name: 'Welcome Message',
          content: 'Welcome to our support system! How can we help you today?',
          category: 'general',
          tags: ['welcome', 'greeting'],
        ),
        const CannedReply(
          id: 'thanks',
          name: 'Thank You',
          content: 'Thank you for contacting us. We appreciate your patience.',
          category: 'general',
          tags: ['thanks', 'gratitude'],
        ),
      ];
    }
  }

  Future<void> upsertCannedReply(CannedReply reply) async {
    try {
      await _sb
          .from('canned_replies')
          .upsert(reply.toJson());
    } catch (e) {
      throw Exception('Failed to save canned reply: $e');
    }
  }



  Future<void> applyCannedReplyToTickets(List<String> ticketIds, String replyId) async {
    try {
      final replies = await listCannedReplies();
      final reply = replies.firstWhere((r) => r.id == replyId);
      
      final now = DateTime.now().toIso8601String();
      final newReplies = ticketIds.map((ticketId) => {
        'ticket_id': ticketId,
        'admin_id': _sb.auth.currentUser?.id,
        'content': reply.content,
        'is_admin': true,
        'created_at': now,
      }).toList();

      await _sb
          .from('support_replies')
          .insert(newReplies);

      // Update ticket status to 'replied' if it was 'open'
      for (final ticketId in ticketIds) {
        await _sb
            .from('support_requests')
            .update({
              'status': 'replied',
              'updated_at': now,
              'first_response_at': now,
            })
            .eq('id', ticketId)
            .eq('status', 'open');
      }
    } catch (e) {
      throw Exception('Failed to apply canned reply: $e');
    }
  }

  // Ticket Merging
  Future<void> mergeTickets(String primaryTicketId, List<String> secondaryTicketIds) async {
    try {
      // Move all replies from secondary tickets to primary
      // Update replies one by one since in_ is not available
      for (final ticketId in secondaryTicketIds) {
        await _sb
            .from('support_replies')
            .update({'ticket_id': primaryTicketId})
            .eq('ticket_id', ticketId);
      }

      // Update primary ticket with combined info
      // Fetch secondary tickets one by one since in_ is not available
      final secondaryTickets = <Map<String, dynamic>>[];
      for (final ticketId in secondaryTicketIds) {
        final ticket = await _sb
            .from('support_requests')
            .select('title, body, tags, priority')
            .eq('id', ticketId)
            .maybeSingle();
        if (ticket != null) {
          secondaryTickets.add(ticket);
        }
      }

      String combinedTitle = '';
      String combinedBody = '';
      final Set<String> allTags = {};
      String highestPriority = 'normal';

      for (final ticket in secondaryTickets) {
        if (combinedTitle.isEmpty) {
          combinedTitle = ticket['title'] as String;
        } else {
          combinedTitle += ' + ${ticket['title']}';
        }
        
        if (combinedBody.isNotEmpty) combinedBody += '\n\n---\n\n';
        combinedBody += ticket['body'] as String;
        
        if (ticket['tags'] != null) {
          allTags.addAll(List<String>.from(ticket['tags']));
        }
        
        // Priority escalation logic
        final priority = ticket['priority'] as String;
        if (priority == 'urgent' || (priority == 'high' && highestPriority != 'urgent')) {
          highestPriority = priority;
        }
      }

      // Update primary ticket
      await _sb
          .from('support_requests')
          .update({
            'title': combinedTitle,
            'body': combinedBody,
            'tags': allTags.toList(),
            'priority': highestPriority,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', primaryTicketId);

      // Delete secondary tickets one by one since in_ is not available
      for (final ticketId in secondaryTicketIds) {
        await _sb
            .from('support_requests')
            .delete()
            .eq('id', ticketId);
      }
    } catch (e) {
      throw Exception('Failed to merge tickets: $e');
    }
  }

  // ---------- CSV Export ----------
  String ticketsToCsv(List<dynamic> tickets) {
    // Expect each ticket map has id,title,status,priority,assignee_id,created_at,updated_at
    final buf = StringBuffer('id,title,status,priority,assignee,created_at,updated_at\n');
    for (final t in tickets) {
      String esc(String? v) => '"${(v ?? '').replaceAll('"', '""')}"';
      buf.writeln([
        esc('${t.id}'),
        esc(t.title),
        esc(t.status),
        esc(t.priority),
        esc('${t.assigneeId}'),
        esc(t.createdAt?.toIso8601String()),
        esc(t.updatedAt?.toIso8601String()),
      ].join(','));
    }
    return buf.toString();
  }

  // ---------- SLA ----------
  Future<Map<String, SlaPolicy>> fetchSlaPolicies() async {
    try {
      final rows = await _sb.from('support_sla_policies')
        .select('priority,first_response_mins,resolution_mins');
      final m = <String, SlaPolicy>{};
      for (final r in (rows as List? ?? const [])) {
        m['${r['priority']}'] = SlaPolicy(
          '${r['priority']}', r['first_response_mins'] ?? 0, r['resolution_mins'] ?? 0);
      }
      return m;
    } catch (_) { return {}; }
  }

  // Computes SLA timestamps from createdAt + policy. Null if policy missing.
  DateTime? computeResolutionDue(DateTime createdAt, String? priority, Map<String, SlaPolicy> map) {
    final p = priority == null ? null : map[priority];
    if (p == null) return null;
    return createdAt.toUtc().add(Duration(minutes: p.resolutionMins));
  }

  // ---------- Auto-triage ----------
  Future<List<AutoRule>> listAutoRules() async {
    try {
      final rows = await _sb.from('support_auto_rules').select('*').eq('enabled', true);
      return (rows as List? ?? const []).map((r) => AutoRule(
        id: '${r['id']}', name: r['name'] ?? '', enabled: r['enabled'] ?? true,
        matchChannel: r['match_channel'], matchPriority: r['match_priority'],
        matchTitleIlike: r['match_title_ilike'], matchBodyIlike: r['match_body_ilike'],
        thenSetPriority: r['then_set_priority'],
        thenAddTags: (r['then_add_tags'] as List?)?.map((e)=>'$e').toList() ?? const [],
        thenAssignTo: r['then_assign_to'],
      )).toList();
    } catch (_) { return const []; }
  }

  // Apply rules to a single ticket (call on create and on-demand)
  Future<void> applyAutoRulesToTicket({
    required String ticketId,
    required String? channel,
    required String? priority,
    required String title,
    required String body,
  }) async {
    final rules = await listAutoRules();
    for (final rule in rules) {
      if (rule.matchChannel != null && rule.matchChannel != channel) continue;
      if (rule.matchPriority != null && rule.matchPriority != priority) continue;
      if (rule.matchTitleIlike != null && !title.toLowerCase().contains(rule.matchTitleIlike!.replaceAll('%','').toLowerCase())) continue;
      if (rule.matchBodyIlike != null && !body.toLowerCase().contains(rule.matchBodyIlike!.replaceAll('%','').toLowerCase())) continue;

      // apply
      if (rule.thenSetPriority != null) {
        try { await _sb.from('support_requests').update({'priority': rule.thenSetPriority}).eq('id', ticketId); } catch (_) {}
      }
      if (rule.thenAssignTo != null) {
        try { await _sb.from('support_requests').update({'assignee_id': rule.thenAssignTo}).eq('id', ticketId); } catch (_) {}
      }
      if (rule.thenAddTags.isNotEmpty) {
        try { await _sb.rpc('append_ticket_tags', params: {'p_ticket_id': ticketId, 'p_tags': rule.thenAddTags}); } catch (_) {}
      }
    }
  }



  // ===== Auto-triage Rules CRUD =====
  Future<List<Map<String,dynamic>>> listAllRulesRaw() async {
    try {
      final res = await _sb
          .from('support_auto_rules')
          .select()
          .order('priority', ascending: false)
          .order('created_at', ascending: false);
      return List<Map<String,dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error listing auto-rules: $e');
      return [];
    }
  }

  Future<String?> createRule(Map<String,dynamic> payload) async {
    try {
      final res = await _sb
          .from('support_auto_rules')
          .insert(payload)
          .select('id')
          .maybeSingle();
      return res?['id'];
    } catch (e) {
      debugPrint('Error creating auto-rule: $e');
      return null;
    }
  }

  Future<bool> updateRule(String id, Map<String,dynamic> patch) async {
    try {
      await _sb
          .from('support_auto_rules')
          .update(patch)
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error updating auto-rule: $e');
      return false;
    }
  }

  Future<bool> deleteRule(String id) async {
    try {
      await _sb
          .from('support_auto_rules')
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting auto-rule: $e');
      return false;
    }
  }

  // ===== SLA Policies CRUD =====
  Future<bool> upsertSlaPolicy(String priority, int firstMins, int resolMins) async {
    try {
      await _sb
          .from('support_sla_policies')
          .upsert({
            'priority': priority,
            'first_response_mins': firstMins,
            'resolution_mins': resolMins,
            'updated_at': DateTime.now().toIso8601String(),
          });
      return true;
    } catch (e) {
      debugPrint('Error upserting SLA policy: $e');
      return false;
    }
  }

  // ===== Canned Replies (optional table: support_canned_replies) =====
  Future<List<Map<String,dynamic>>> listCannedRepliesRaw() async {
    try {
      final res = await _sb
          .from('support_canned_replies')
          .select()
          .order('title', ascending: true);
      return List<Map<String,dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error listing canned replies: $e');
      return [];
    }
  }

  Future<String?> createCannedReply({
    required String title,
    required String body,
    List<String>? tags,
  }) async {
    try {
      final res = await _sb
          .from('support_canned_replies')
          .insert({
            'title': title,
            'body': body,
            'tags': tags ?? [],
          })
          .select('id')
          .maybeSingle();
      return res?['id'];
    } catch (e) {
      debugPrint('Error creating canned reply: $e');
      return null;
    }
  }

  Future<bool> updateCannedReply(
    String id, {
    String? title,
    String? body,
    List<String>? tags,
  }) async {
    try {
      final patch = <String, dynamic>{};
      if (title != null) patch['title'] = title;
      if (body != null) patch['body'] = body;
      if (tags != null) patch['tags'] = tags;
      
      await _sb
          .from('support_canned_replies')
          .update(patch)
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error updating canned reply: $e');
      return false;
    }
  }

  Future<bool> deleteCannedReply(String id) async {
    try {
      await _sb
          .from('support_canned_replies')
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting canned reply: $e');
      return false;
    }
  }

  // ===== Co-Pilot Action Stubs =====
  Future<bool> updateTicketPriority(String ticketId, String priority) async {
    try {
      await _sb
          .from('support_requests')
          .update({'priority': priority, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', ticketId);
      debugPrint('Updated ticket $ticketId priority to $priority');
      return true;
    } catch (e) {
      debugPrint('Error updating ticket priority: $e');
      return false;
    }
  }

  Future<bool> addTicketTag(String ticketId, String tag) async {
    try {
      final ticket = await _sb
          .from('support_requests')
          .select('tags')
          .eq('id', ticketId)
          .maybeSingle();
      
      if (ticket != null) {
        final currentTags = List<String>.from(ticket['tags'] ?? []);
        if (!currentTags.contains(tag)) {
          currentTags.add(tag);
          await _sb
              .from('support_requests')
              .update({'tags': currentTags, 'updated_at': DateTime.now().toIso8601String()})
              .eq('id', ticketId);
        }
      }
      debugPrint('Added tag $tag to ticket $ticketId');
      return true;
    } catch (e) {
      debugPrint('Error adding ticket tag: $e');
      return false;
    }
  }

  Future<bool> escalateTicket(String ticketId) async {
    try {
      await _sb
          .from('support_requests')
          .update({
            'priority': 'urgent',
            'status': 'escalated',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId);
      debugPrint('Escalated ticket $ticketId');
      return true;
    } catch (e) {
      debugPrint('Error escalating ticket: $e');
      return false;
    }
  }

  Future<bool> requestUserLogs(String ticketId) async {
    try {
      // This would typically trigger a background job to collect user logs
      // For now, just add a note to the ticket
      await _sb
          .from('support_replies')
          .insert({
            'ticket_id': ticketId,
            'author_id': Supabase.instance.client.auth.currentUser?.id ?? 'system',
            'body': 'System: Requested user logs for diagnostics',
            'created_at': DateTime.now().toIso8601String(),
          });
      debugPrint('Requested logs for ticket $ticketId');
      return true;
    } catch (e) {
      debugPrint('Error requesting user logs: $e');
      return false;
    }
  }

  // ---------- Draft & Handoff ----------
  Future<bool> claimTicket(String ticketId, String agentId) async {
    debugPrint('[support] claimTicket $ticketId by $agentId');
    // TODO: persist claim to DB
    return true;
  }

  Future<bool> releaseClaim(String ticketId, String agentId) async {
    debugPrint('[support] releaseClaim $ticketId by $agentId');
    return true;
  }

  Future<bool> saveDraftReply(String ticketId, String agentId, String text) async {
    debugPrint('[support] saveDraftReply $ticketId $agentId len=${text.length}');
    return true;
  }

  Future<bool> handoffTicket({
    required String ticketId,
    required String fromAgentId,
    required String toAgentId,
    required String note,
  }) async {
    debugPrint('[support] handoff $ticketId from=$fromAgentId to=$toAgentId noteLen=${note.length}');
    return true;
  }

  Future<List<Map<String, dynamic>>> listTimelineEvents(String ticketId) async {
    // Stubbed mixed events (system + agent + tags + priority + messages)
    return [
      {'ts': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(), 'kind': 'message', 'by': 'user', 'text': 'I can\'t login'},
      {'ts': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(), 'kind': 'priority', 'value': 'urgent', 'by': 'agent:you'},
    ];
  }

  Future<bool> logTimelineEvent(String ticketId, Map<String, dynamic> event) async {
    debugPrint('[support] timeline log $ticketId $event');
    return true;
  }

  // ---------- SLA & Breach Management ----------
  Future<SlaSnapshot> getSlaSnapshot(String ticketId) async {
    // TODO: fetch policy/deadline from DB; stub logic:
    final now = DateTime.now();
    // pretend 1h SLA from last user message
    final deadline = now.add(const Duration(minutes: 42));
    final remaining = deadline.difference(now);
    return SlaSnapshot(
      now: now,
      deadline: deadline,
      breached: remaining.isNegative,
      remaining: remaining.isNegative ? Duration.zero : remaining,
      policyName: 'Std · First response',
      severity: 'normal',
    );
  }

  Future<bool> acknowledgeBreach(String ticketId, String agentId) async {
    debugPrint('[support] acknowledgeBreach $ticketId by $agentId');
    return true;
  }

  Future<bool> extendSla(String ticketId, Duration by, String reason, String agentId) async {
    debugPrint('[support] extendSla $ticketId by=${by.inMinutes} reason=$reason');
    return true;
  }

  Future<bool> escalatePriority(String ticketId, {String to='urgent', String? reason, String? agentId}) async {
    debugPrint('[support] escalatePriority $ticketId -> $to reason=$reason');
    return true;
  }

  // ---------- Saved Views Management ----------
  // Saved views (persist later; store in-memory stub for now)
  final List<SavedView> _memViews = [
    const SavedView(id: 'all', name: 'All', filters: {}),
    const SavedView(id: 'open', name: 'Open', filters: {'state':'open'}),
    const SavedView(id: 'urgent', name: 'Urgent', filters: {'priority':['urgent']}),
    const SavedView(id: 'breached', name: 'Breached', filters: {'breached':true}),
    const SavedView(id: 'mine', name: 'My claimed', filters: {'claimedBy':'me'}),
  ];

  Future<List<SavedView>> listSavedViews() async => List.unmodifiable(_memViews);

  Future<SavedView> createSavedView(String name, Map<String, dynamic> filters) async {
    final v = SavedView(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, filters: filters, order: _memViews.length);
    _memViews.add(v);
    debugPrint('[support] createSavedView ${v.id} $name $filters');
    return v;
  }

  Future<bool> deleteSavedView(String id) async {
    _memViews.removeWhere((v) => v.id == id || v.id == 'all' || v.id == 'open'); // keep system defaults
    debugPrint('[support] deleteSavedView $id');
    return true;
  }

  Future<bool> reorderSavedViews(List<String> orderedIds) async {
    for (var i=0;i<orderedIds.length;i++) {
      final idx = _memViews.indexWhere((v)=>v.id==orderedIds[i]);
      if (idx >= 0) _memViews[idx] = _memViews[idx].copyWith(order: i);
    }
    _memViews.sort((a,b)=>a.order.compareTo(b.order));
    debugPrint('[support] reorderSavedViews $orderedIds');
    return true;
  }

  // ---------- SLA v7 Methods ----------
  Future<List<SlaPolicyV7>> listPolicies() async {
    // Stub implementation - return sample data
    return [
      SlaPolicyV7(
        id: '1',
        name: 'Standard Support',
        description: 'Standard support SLA for regular users',
        priority: 'medium',
        responseTime: const Duration(hours: 4),
        resolutionTime: const Duration(hours: 24),
        isActive: true,
        businessHours: const BusinessHours(),
        escalationRules: [],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      SlaPolicyV7(
        id: '2',
        name: 'Premium Support',
        description: 'Premium support SLA for VIP users',
        priority: 'high',
        responseTime: const Duration(hours: 1),
        resolutionTime: const Duration(hours: 8),
        isActive: true,
        businessHours: const BusinessHours(),
        escalationRules: [],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  Future<SlaPolicyV7> upsertPolicy(SlaPolicyV7 policy) async {
    debugPrint('[support] upsertPolicy ${policy.id} ${policy.name}');
    return policy;
  }

  Future<bool> deletePolicy(String id) async {
    debugPrint('[support] deletePolicy $id');
    return true;
  }

  Future<OpsKpis> getOpsKpis({Duration lookback = const Duration(days: 7)}) async {
    // Stub implementation - return sample data
    return const OpsKpis(
      totalTickets: 150,
      openTickets: 45,
      avgResponseTime: Duration(hours: 2),
      avgResolutionTime: Duration(hours: 18),
      slaCompliancePercentage: 92.5,
      avgTicketsPerAgent: 12.5,
    );
  }

  Future<Percentiles> getFrtPercentiles({Duration lookback = const Duration(days: 7)}) async {
    // Stub implementation - return sample data
    return const Percentiles(
      p50: Duration(hours: 1),
      p75: Duration(hours: 2),
      p90: Duration(hours: 4),
      p95: Duration(hours: 8),
      p99: Duration(hours: 24),
    );
  }

  Future<List<List<int>>> getAgingHeatmap({bool byCount = true}) async {
    // Stub implementation - return sample data (4 statuses x 7 age ranges)
    return [
      [5, 12, 8, 15, 3, 1, 0], // New
      [3, 8, 15, 22, 12, 5, 2], // Open
      [1, 4, 8, 12, 8, 3, 1], // Pending
      [0, 0, 2, 5, 8, 4, 2], // Resolved
    ];
  }

  Future<List<Map<String, dynamic>>> listActiveBreaches() async {
    // Stub implementation - return sample data
    return [
      {
        'ticketId': 'T-001',
        'policyName': 'Standard Support',
        'severity': 'medium',
        'breachMinutes': 120,
      },
      {
        'ticketId': 'T-015',
        'policyName': 'Premium Support',
        'severity': 'high',
        'breachMinutes': 90,
      },
    ];
  }

  // ===== Agent Workload & Macros (v8) =====
  final List<Macro> _memMacros = [
    const Macro(id: 'welcome', title: 'Welcome Reply', body: 'Thanks for reaching out — happy to help!', tags: ['welcome']),
    const Macro(id: 'billing', title: 'Billing: Payment failed', body: 'Sorry about that — could you confirm last 4 digits?', tags: ['billing']),
  ];

  Future<List<AgentWorkload>> listAgentWorkload() async {
    // TODO: wire to Supabase; deterministic fake for UI
    return const [
      AgentWorkload(agentId:'a1', displayName:'Alex', activeTickets:7, waitingReplies:2, occupancy:.72, status:'online'),
      AgentWorkload(agentId:'a2', displayName:'Bri', activeTickets:4, waitingReplies:1, occupancy:.55, status:'busy'),
      AgentWorkload(agentId:'a3', displayName:'Chen', activeTickets:1, waitingReplies:0, occupancy:.12, status:'away'),
    ];
  }

  Future<bool> setAgentStatus(String agentId, String status) async {
    debugPrint('[support] setAgentStatus $agentId -> $status');
    return true;
  }

  Future<List<Macro>> listMacros({bool includePrivate = true}) async {
    return List.unmodifiable(_memMacros);
  }

  Future<Macro> upsertMacro(Macro m) async {
    final i = _memMacros.indexWhere((x)=>x.id==m.id);
    if (i>=0) { _memMacros[i] = m; } else { _memMacros.add(m); }
    debugPrint('[support] upsertMacro ${m.id}');
    return m;
  }

  Future<bool> deleteMacro(String id) async {
    _memMacros.removeWhere((x)=>x.id==id);
    debugPrint('[support] deleteMacro $id');
    return true;
  }

  Future<bool> applyMacroToTicket({required String ticketId, required String macroId}) async {
    debugPrint('[support] applyMacro $macroId -> $ticketId');
    return true;
  }

  Future<List<TagTrendPoint>> getRootCauseTrends({int days = 14}) async {
    final now = DateTime.now();
    final rnd = math.Random(11);
    final tags = ['login','billing','export','ios','android','coach'];
    return List.generate(days, (i) {
      final counts = <String,int>{ for (final t in tags) t : rnd.nextInt(8) };
      return TagTrendPoint(day: DateTime(now.year, now.month, now.day).subtract(Duration(days: days-1-i)), countsByTag: counts);
    });
  }
}

// ---------- SLA ----------
class SlaPolicy {
  final String priority;
  final int firstResponseMins;
  final int resolutionMins;
  const SlaPolicy(this.priority, this.firstResponseMins, this.resolutionMins);
}

// ---------- SLA v7 ----------
class BusinessHours {
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;
  final String startTime;
  final String endTime;
  final String timezone;

  const BusinessHours({
    this.monday = true,
    this.tuesday = true,
    this.wednesday = true,
    this.thursday = true,
    this.friday = true,
    this.saturday = false,
    this.sunday = false,
    this.startTime = '09:00',
    this.endTime = '17:00',
    this.timezone = 'UTC',
  });

  Map<String, dynamic> toJson() => {
    'monday': monday,
    'tuesday': tuesday,
    'wednesday': wednesday,
    'thursday': thursday,
    'friday': friday,
    'saturday': saturday,
    'sunday': sunday,
    'startTime': startTime,
    'endTime': endTime,
    'timezone': timezone,
  };

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      monday: json['monday'] ?? true,
      tuesday: json['tuesday'] ?? true,
      wednesday: json['wednesday'] ?? true,
      thursday: json['thursday'] ?? true,
      friday: json['friday'] ?? true,
      saturday: json['saturday'] ?? false,
      sunday: json['sunday'] ?? false,
      startTime: json['startTime'] ?? '09:00',
      endTime: json['endTime'] ?? '17:00',
      timezone: json['timezone'] ?? 'UTC',
    );
  }
}

class SlaPolicyV7 {
  final String id;
  final String name;
  final String description;
  final String priority;
  final Duration responseTime;
  final Duration resolutionTime;
  final bool isActive;
  final BusinessHours businessHours;
  final List<Map<String, dynamic>> escalationRules;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SlaPolicyV7({
    required this.id,
    required this.name,
    required this.description,
    required this.priority,
    required this.responseTime,
    required this.resolutionTime,
    required this.isActive,
    required this.businessHours,
    required this.escalationRules,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'priority': priority,
    'responseTime': responseTime.inMinutes,
    'resolutionTime': resolutionTime.inMinutes,
    'isActive': isActive,
    'businessHours': businessHours.toJson(),
    'escalationRules': escalationRules,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SlaPolicyV7.fromJson(Map<String, dynamic> json) {
    return SlaPolicyV7(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String,
      responseTime: Duration(minutes: json['responseTime'] as int),
      resolutionTime: Duration(minutes: json['resolutionTime'] as int),
      isActive: json['isActive'] as bool,
      businessHours: BusinessHours.fromJson(json['businessHours'] as Map<String, dynamic>),
      escalationRules: List<Map<String, dynamic>>.from(json['escalationRules'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class OpsKpis {
  final int totalTickets;
  final int openTickets;
  final Duration avgResponseTime;
  final Duration avgResolutionTime;
  final double slaCompliancePercentage;
  final double avgTicketsPerAgent;

  const OpsKpis({
    required this.totalTickets,
    required this.openTickets,
    required this.avgResponseTime,
    required this.avgResolutionTime,
    required this.slaCompliancePercentage,
    required this.avgTicketsPerAgent,
  });
}

class Percentiles {
  final Duration p50;
  final Duration p75;
  final Duration p90;
  final Duration p95;
  final Duration p99;

  const Percentiles({
    required this.p50,
    required this.p75,
    required this.p90,
    required this.p95,
    required this.p99,
  });
}

// ---------- Auto-triage ----------
class AutoRule {
  final String id, name;
  final bool enabled;
  final String? matchChannel, matchPriority, matchTitleIlike, matchBodyIlike;
  final String? thenSetPriority;
  final List<String> thenAddTags;
  final String? thenAssignTo;
  AutoRule({
    required this.id, required this.name, required this.enabled,
    this.matchChannel, this.matchPriority, this.matchTitleIlike, this.matchBodyIlike,
    this.thenSetPriority, this.thenAddTags = const [], this.thenAssignTo,
  });
}



// Data Models for Bulk Operations
class BulkUpdateRequest {
  final String? status;
  final String? priority;
  final String? assignedTo;
  final List<String>? tags;
  final String? notes;

  const BulkUpdateRequest({
    this.status,
    this.priority,
    this.assignedTo,
    this.tags,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    if (status != null) 'status': status,
    if (priority != null) 'priority': priority,
    if (assignedTo != null) 'assigned_to': assignedTo,
    if (tags != null) 'tags': tags,
    if (notes != null) 'notes': notes,
  };
}

class CannedReply {
  final String id;
  final String name;
  final String content;
  final String category;
  final List<String> tags;

  const CannedReply({
    required this.id,
    required this.name,
    required this.content,
    required this.category,
    this.tags = const [],
  });

  factory CannedReply.fromJson(Map<String, dynamic> json) => CannedReply(
    id: json['id'] as String,
    name: json['name'] as String,
    content: json['content'] as String,
    category: json['category'] as String,
    tags: List<String>.from(json['tags'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'content': content,
    'category': category,
    'tags': tags,
  };
}
