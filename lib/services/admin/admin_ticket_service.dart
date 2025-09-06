import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/admin/ticket_models.dart';

class AdminTicketService {
  AdminTicketService._();
  static final AdminTicketService instance = AdminTicketService._();

  // In-memory demo data for UI (replace with Supabase later)
  final List<TicketSummary> _list = List.generate(20, (i) {
    final pr = TicketPriority.values[i % TicketPriority.values.length];
    final st = TicketStatus.values[i % TicketStatus.values.length];
    final created = DateTime.now().subtract(Duration(hours: 8 + i * 3));
    final age = DateTime.now().difference(created);
    return TicketSummary(
      id: 'T${1000 + i}',
      subject: 'Issue #$i — unexpected behavior in module',
      requesterName: ['Liam','Noah','Olivia','Amelia','Ava','Mia'][i%6],
      assigneeName: (i%3==0) ? 'Alex' : null,
      userId: (i % 3 == 0) ? 'user-${100 + i}' : null, // Some tickets have userId for Co-Pilot demo
      status: st,
      priority: pr,
      tags: (i%2==0) ? ['billing'] : ['ios','export'],
      createdAt: created,
      lastReplyAt: created.add(const Duration(hours: 2)),
      age: age,
    );
  });

  Future<List<TicketSummary>> listTickets({
    TicketStatus? status,
    TicketPriority? priority,
    String query = '',
    String? tagFilter,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _list.where((t) {
      final byStatus = status == null || t.status == status;
      final byPrio = priority == null || t.priority == priority;
      final byTag = tagFilter == null || t.tags.contains(tagFilter);
      final byQ = query.isEmpty || t.subject.toLowerCase().contains(query.toLowerCase());
      return byStatus && byPrio && byTag && byQ;
    }).toList();
  }

  Future<TicketDetail> getTicket(String id) async {
    final m = _list.firstWhere((t) => t.id == id);
    return TicketDetail(
      meta: m,
      body: 'Customer reports an issue with ${m.subject}. Steps to reproduce…',
      thread: [
        TicketMessage(
          id: 'm1', 
          author: m.requesterName, 
          at: m.createdAt, 
          text: 'Hi, I have a problem…'
        ),
        TicketMessage(
          id: 'm2', 
          author: m.assigneeName ?? 'Support', 
          at: m.createdAt.add(const Duration(hours: 2)), 
          text: 'Thanks, can you share logs?'
        ),
      ],
    );
  }

  Future<bool> setAssignee(String id, String? assignee) async {
    debugPrint('[admin] setAssignee $id -> $assignee');
    return true;
  }

  Future<bool> setStatus(String id, TicketStatus s) async {
    debugPrint('[admin] setStatus $id -> $s');
    return true;
  }

  Future<bool> setPriority(String id, TicketPriority p) async {
    debugPrint('[admin] setPriority $id -> $p');
    return true;
  }

  Future<bool> addTags(String id, List<String> tags) async {
    debugPrint('[admin] addTags $id -> $tags');
    return true;
  }

  Future<bool> reply(String id, String message, {bool internal=false}) async {
    debugPrint('[admin] reply $id internal=$internal :: ${message.substring(0, message.length.clamp(0, 60))}');
    return true;
  }

  // Escalations (stubbed)
  final List<EscalationRule> _rules = [
    const EscalationRule(
      id:'r1',
      name:'Billing P1',
      matchTags:['billing'],
      minPriority: TicketPriority.urgent,
      actionAssignGroup:'Billing',
      notifySlack:true
    ),
    const EscalationRule(
      id:'r2',
      name:'iOS export aging',
      matchTags:['ios','export'],
      maxResolution: Duration(hours: 24),
      actionSetPriority: TicketPriority.high
    ),
  ];

  Future<List<EscalationRule>> listRules() async => List.unmodifiable(_rules);

  Future<EscalationRule> upsertRule(EscalationRule r) async {
    final i = _rules.indexWhere((x)=>x.id==r.id);
    if (i>=0) {
      _rules[i] = r;
    } else {
      _rules.add(r);
    }
    return r;
  }

  Future<bool> deleteRule(String id) async {
    _rules.removeWhere((x)=>x.id==id);
    return true;
  }

  Future<bool> applyRules(String ticketId) async {
    debugPrint('[admin] applyRules -> $ticketId');
    return true;
  }

  // Playbooks (stubbed)
  final List<Playbook> _plays = [
    const Playbook(
      id:'p1',
      title:'Payment Failed — Stripe',
      tags:['billing'],
      steps:[
        PlayStep(kind:'reply', value:'Sorry about that — could you confirm the last 4 digits?'),
        PlayStep(kind:'tag', value:'billing'),
        PlayStep(kind:'status', value:'pending'),
      ],
    ),
  ];

  Future<List<Playbook>> listPlaybooks() async => List.unmodifiable(_plays);

  Future<Playbook> upsertPlaybook(Playbook p) async {
    final i = _plays.indexWhere((x)=>x.id==p.id);
    if (i>=0) {
      _plays[i] = p;
    } else {
      _plays.add(p);
    }
    return p;
  }

  Future<bool> deletePlaybook(String id) async {
    _plays.removeWhere((x)=>x.id==id);
    return true;
  }

  Future<bool> runPlaybook(String ticketId, String playbookId) async {
    debugPrint('[admin] runPlaybook $playbookId -> $ticketId');
    return true;
  }
}
