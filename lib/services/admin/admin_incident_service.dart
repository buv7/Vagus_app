import 'dart:async';
import 'dart:io' show File, Directory; // non-web; we'll guard web at call-site
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/admin/incident_models.dart';
import '../../models/admin/ticket_models.dart';
import '../../models/admin/support_models.dart'; // Added for CannedReply

// ---- ADMIN V18: Enhanced features ----

// Pin/unpin tickets
class TicketPinManager {
  static final Map<String,bool> _pinnedMem = {};
  
  static Future<void> setPinned(String id, bool v) async {
    try { 
      await Supabase.instance.client.from('incidents').update({'pinned': v}).eq('id', id); 
    } catch(_) { 
      _pinnedMem[id]=v; 
    }
  }
  
  static Future<bool> getPinned(String id) async {
    try { 
      final r = await Supabase.instance.client.from('incidents').select('pinned').eq('id',id).maybeSingle(); 
      return (r?['pinned'] as bool?) ?? false; 
    } catch(_) { 
      return _pinnedMem[id] ?? false; 
    }
  }
}

// Simple analytics snapshot
class AdminStats {
  final int total, newCnt, investigatingCnt, blockedCnt, resolvedCnt;
  const AdminStats(this.total,this.newCnt,this.investigatingCnt,this.blockedCnt,this.resolvedCnt);
}

// Playbooks (checklist templates)
class AdminPlaybook {
  final String id, name;
  final List<String> steps;
  const AdminPlaybook(this.id, this.name, this.steps);
}

// Enhanced playbook tracking
class PlaybookRun { 
  final String id, ticketId, playbookId; 
  final List<bool> done; 
  PlaybookRun(this.id,this.ticketId,this.playbookId,this.done); 
}

// Macros with variables
class AdminMacro {
  final String id;
  final String name;
  final String body; // e.g. "Hello {{name}}, your case {{id}} is {{status}}"
  const AdminMacro({required this.id, required this.name, required this.body});
}

class DevImpersonation {
  static String? currentUserId; // dev-only stub
}

class AdminIncidentService {
  AdminIncidentService._();
  static final AdminIncidentService instance = AdminIncidentService._();

  // In-memory demo stores (back them by Supabase later if desired)
  final List<IncidentEvent> _events = <IncidentEvent>[];
  final List<IncidentNote> _notes = <IncidentNote>[];
  final List<TriageRule> _rules = <TriageRule>[
    const TriageRule(
      id: 'r1',
      name: 'Network spikes',
      enabled: true,
      includeTags: ['network'],
      actions: [TriageAction.tag],
    ),
  ];
  final List<SavedView> _views = <SavedView>[
    const SavedView(
      id: 'v1',
      name: 'All Open',
      filters: {'status': 'open'},
    ),
  ];
  
  // Demo tickets for SLA computation
  final List<TicketSummary> _tickets = <TicketSummary>[
    TicketSummary(
      id: 't1',
      subject: 'Demo ticket 1',
      requesterName: 'User 1',
      status: TicketStatus.open,
      priority: TicketPriority.normal,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      age: const Duration(hours: 2),
    ),
    TicketSummary(
      id: 't2',
      subject: 'Demo ticket 2',
      requesterName: 'User 2',
      status: TicketStatus.open,
      priority: TicketPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      age: const Duration(hours: 6),
    ),
  ];

  // Public getter for tickets
  List<TicketSummary> get tickets => _tickets;

  Stream<List<IncidentEvent>> streamEvents(String ticketId) async* {
    // Poll every 3s – replace with realtime later
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 3));
      yield _events
          .where((e) => e.ticketId == ticketId)
          .toList()
        ..sort((a, b) => b.at.compareTo(a.at));
    }
  }

  Future<void> addEvent(IncidentEvent e) async {
    _events.add(e);
  }

  Future<void> addNote(IncidentNote n) async {
    _notes.add(n);
  }

  Future<List<IncidentNote>> listNotes(String ticketId) async =>
      _notes
          .where((n) => n.ticketId == ticketId)
          .toList()
        ..sort((a, b) => b.at.compareTo(a.at));

  // Rules
  Future<List<TriageRule>> listRules() async => List<TriageRule>.from(_rules);

  Future<void> upsertRule(TriageRule r) async {
    final i = _rules.indexWhere((x) => x.id == r.id);
    if (i >= 0) {
      _rules[i] = r;
    } else {
      _rules.add(r);
    }
  }

  Future<void> deleteRule(String id) async {
    _rules.removeWhere((x) => x.id == id);
  }

  // Very simple evaluation: if any include tag matches and none of exclude
  Future<List<TriageAction>> evaluate(Iterable<String> tags) async {
    final tagSet = Set<String>.from(tags);
    final actions = <TriageAction>[];
    for (final r in _rules.where((r) => r.enabled)) {
      final incOk = r.includeTags.isEmpty || r.includeTags.any(tagSet.contains);
      final excOk = r.excludeTags.isEmpty || !r.excludeTags.any(tagSet.contains);
      if (incOk && excOk) actions.addAll(r.actions);
    }
    return actions;
  }

  // Saved views
  Future<List<SavedView>> listSavedViews() async => List<SavedView>.from(_views);

  Future<void> upsertView(SavedView v) async {
    final i = _views.indexWhere((x) => x.id == v.id);
    if (i >= 0) {
      _views[i] = v;
    } else {
      _views.add(v);
    }
  }

  Future<void> deleteView(String id) async {
    _views.removeWhere((v) => v.id == id);
  }

  // ---- SLA COMPUTE ----------------------------------------------------------
  SlaMeta computeSla({
    required DateTime createdAt,
    SlaPriority priority = SlaPriority.normal,
  }) {
    Duration target;
    switch (priority) {
      case SlaPriority.low:    target = const Duration(hours: 72); break;
      case SlaPriority.normal: target = const Duration(hours: 24); break;
      case SlaPriority.high:   target = const Duration(hours: 8);  break;
      case SlaPriority.urgent: target = const Duration(hours: 2);  break;
    }
    final due = createdAt.add(target);
    return SlaMeta(priority: priority, createdAt: createdAt, dueAt: due, breached: DateTime.now().isAfter(due));
  }

  // Example lookup: returns SLA meta for each ticket id
  Future<Map<String, SlaMeta>> getSlaForTickets(List<String> ticketIds) async {
    final out = <String, SlaMeta>{};
    for (final id in ticketIds) {
      final t = _tickets.firstWhere((x)=> x.id==id, orElse: ()=> _tickets.first); // fallback demo
      out[id] = computeSla(createdAt: t.createdAt, priority: SlaPriority.normal);
    }
    return out;
  }

  // ---- BULK APPLY (demo) ----------------------------------------------------
  Future<void> bulkApply({
    required List<String> ticketIds,
    Map<String, String>? reply, // Changed to simple map: {name: String, content: String}
    List<String> actions = const [], // Changed from IncidentAction to String for simplicity
  }) async {
    // Simulate latency
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // Attach reply as a note to each ticket (if provided)
    if (reply != null) {
      for (final id in ticketIds) {
        await addEvent(IncidentEvent(
          id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
          ticketId: id,
          kind: IncidentKind.note,
          title: 'Canned reply • ${reply['name']}',
          details: reply['content'] ?? '', // Changed to map access
          at: DateTime.now(),
          by: 'admin',
        ));
      }
    }
    // Apply actions (labels/routing) — demo: just note the action names
    if (actions.isNotEmpty) {
      for (final id in ticketIds) {
        final names = actions.join(', ');
        await addEvent(IncidentEvent(
          id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
          ticketId: id,
          kind: IncidentKind.note,
          title: 'Actions applied',
          details: names,
          at: DateTime.now(),
          by: 'admin',
        ));
      }
    }
  }

  // ---- EXPORT TO FILE (non-web) ---------------------------------------------
  Future<String> writeTextTemp(String filename, String contents) async {
    final dir = Directory.systemTemp.path;
    final path = '$dir/$filename';
    final f = File(path);
    await f.writeAsString(contents);
    return path;
  }

  // ---- TIMELINE CSV EXPORT ---------------------------------------------------
  Future<String> buildTimelineCsv(String ticketId) async {
    final events = _events.where((e) => e.ticketId == ticketId).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    
    final csv = StringBuffer();
    csv.writeln('Timestamp,Event,Title,Details,By');
    for (final event in events) {
      csv.writeln('${event.at.toIso8601String()},${event.kind.name},${event.title},${event.details},${event.by}');
    }
    return csv.toString();
  }

  // ---- DEV IMPERSONATION (stub) ---------------------------------------------
  bool get canImpersonate => !kReleaseMode; // only when NOT release
  Future<void> impersonateUser(String userId) async {
    if (kReleaseMode) return; // hard stop in release builds
    DevImpersonation.currentUserId = userId;
    await addEvent(IncidentEvent(
      id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
      ticketId: _tickets.isNotEmpty ? _tickets.first.id : 'na',
      kind: IncidentKind.note,
      title: 'Dev impersonation',
      details: 'Now impersonating $userId (dev-only).',
      at: DateTime.now(),
      by: 'admin',
    ));
  }

  // ---- AI ASSIST (stubbed) ----------------------------------------------------
  Future<String> suggestReply(String ticketId, {String? hint}) async {
    // Stub: build a naive suggestion from last 3 events.
    final ev = await getEvents(ticketId);
    final tail = ev.reversed.take(3).map((e) => '- ${e.title}: ${e.details}').join('\n');
    return 'Hi! Thanks for your patience.\n\nWe reviewed your case:\n$tail\n\nProposed next step: please try these steps and let us know if the issue persists.';
  }

  // ---- MACROS (with variables) ------------------------------------------------
  final List<AdminMacro> _macros = [
    AdminMacro(id: 'm1', name: 'Welcome + next steps', body: 'Hello {{name}}, thanks for reaching out. For case {{id}}, do {{step}}.'),
    AdminMacro(id: 'm2', name: 'Escalation notice',  body: 'Hi {{name}}, we escalated case {{id}} to tier {{tier}}. ETA {{eta}}.'),
  ];

  Future<List<AdminMacro>> listMacros() async => _macros;

  String applyMacro(AdminMacro m, Map<String,String> vars) {
    var out = m.body;
    vars.forEach((k,v){ out = out.replaceAll('{{$k}}', v); });
    return out;
  }

  // ---- PRESENCE (dev/local memory) -------------------------------------------
  final Map<String, DateTime> _presence = {}; // ticketId -> lastPing
  void pingPresence(String ticketId){ _presence[ticketId] = DateTime.now(); }
  int presenceCount(String ticketId){
    final now = DateTime.now();
    return _presence.entries.where((e)=> e.key==ticketId && now.difference(e.value) < const Duration(seconds: 45)).length;
  }

  // ---- TIMELINE CSV by range --------------------------------------------------
  Future<String> buildTimelineCsvRange(String ticketId, {DateTime? from, DateTime? to}) async {
    final ev = await getEvents(ticketId);
    final filtered = ev.where((e){
      final okFrom = from==null || !e.at.isBefore(from);
      final okTo   = to==null   || !e.at.isAfter(to);
      return okFrom && okTo;
    }).toList();
    final rows = [
      'id,at,kind,title,details,by',
      ...filtered.map((e)=> '${e.id},${e.at.toIso8601String()},${e.kind.name},"${e.title.replaceAll('"','""')}","${e.details.replaceAll('"','""')}",${e.by}')
    ];
    return rows.join('\n');
  }

  // ---- ADMIN V17: Status persistence, analytics, playbooks, escalation ----

  // Persist status (Supabase table: incidents; if not available, fallback to memory)
  final Map<String,String> _statusMem = {}; // ticketId -> status

  Future<void> setTicketStatus(String ticketId, String status) async {
    // Try Supabase update if your incidents table has a 'status' column; else memory.
    try {
      final sb = Supabase.instance.client;
      await sb.from('incidents').update({'status': status})
        .eq('id', ticketId);
    } catch (_) {
      _statusMem[ticketId] = status;
    }
  }

  Future<String?> getStatus(String ticketId) async {
    try {
      final sb = Supabase.instance.client;
      final r = await sb.from('incidents').select('status').eq('id', ticketId).maybeSingle();
      return r?['status'] as String?;
    } catch (_) {
      return _statusMem[ticketId];
    }
  }

  // Simple analytics snapshot
  Future<AdminStats> computeStats() async {
    final all = _tickets; // Use demo tickets for now
    int n=0,i=0,b=0,r=0;
    for (final t in all) {
      final s = t.status.name; // Use the actual status enum
      if (s=='open') n++; else if (s=='pending') i++; else if (s=='solved') r++; else if (s=='archived') b++;
    }
    return AdminStats(all.length,n,i,b,r);
  }

  // Playbooks (checklist templates)
  final List<AdminPlaybook> _playbooks = [
    AdminPlaybook('pb1','Authentication lockout',['Verify identity','Reset sign-in methods','Force token refresh','Notify user']),
    AdminPlaybook('pb2','Payment failure',['Check recent invoices','Retry charge','Offer alt method','Create support note']),
  ];
  
  Future<List<AdminPlaybook>> listPlaybooks() async => _playbooks;

  // Escalate stub
  Future<void> escalate(String ticketId, {String tier='T2'}) async {
    await addEvent(IncidentEvent(
      id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
      ticketId: ticketId,
      kind: IncidentKind.note,
      title: 'Escalated',
      details: 'Escalated to $tier',
      at: DateTime.now(),
      by: 'admin',
    ));
  }

  // Enhanced playbook tracking
  final Map<String,PlaybookRun> _runs = {};
  
  Future<PlaybookRun> startPlaybook(String ticketId, AdminPlaybook pb){
    final run = PlaybookRun(
      'run-${DateTime.now().millisecondsSinceEpoch}', 
      ticketId, 
      pb.id, 
      List.filled(pb.steps.length, false)
    );
    _runs[run.id]=run; 
    return Future.value(run);
  }
  
  Future<void> toggleStep(String runId, int idx) async {
    final r=_runs[runId]; 
    if(r==null) return; 
    r.done[idx]=!r.done[idx]; 
  }
  
  Future<PlaybookRun?> getPlaybookRun(String ticketId) async {
    try {
      return _runs.values.firstWhere((r) => r.ticketId == ticketId);
    } catch (e) {
      return null;
    }
  }

  // Get events for a ticket
  Future<List<IncidentEvent>> getEvents(String ticketId) async {
    // For now, return empty list - this would connect to your events table
    return [];
  }

  // Pin/unpin tickets
  Future<void> setPinned(String id, bool v) async {
    await TicketPinManager.setPinned(id, v);
  }
  
  Future<bool> getPinned(String id) async {
    return await TicketPinManager.getPinned(id);
  }
}
