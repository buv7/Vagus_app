import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../services/admin/admin_support_service.dart';
import '../../../../models/admin/support_models.dart';
import '../../../../data/canned_replies.dart';
import '../../../../data/support_macros.dart';
import '../../../../widgets/admin/support/draft_handoff_sheet.dart';
import '../../../../widgets/admin/support/ticket_timeline.dart';
import '../../../../widgets/admin/support/sla_badge.dart';
import '../../../../widgets/admin/support/breach_banner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;
  final Future<void> Function() onAssignToMe;
  final Future<void> Function() onClose;
  const TicketCard({super.key, required this.ticket, required this.onTap, required this.onAssignToMe, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final color = ticket.priority == 'urgent' ? Colors.red : Colors.grey;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.support_agent, color: color),
        title: Text(ticket.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${ticket.requesterEmail} • ${ticket.status.toUpperCase()}'),
        trailing: Wrap(spacing: 6, children: [
          IconButton(onPressed: onAssignToMe, icon: const Icon(Icons.person_add_alt_1)),
          IconButton(onPressed: onClose, icon: const Icon(Icons.check)),
        ]),
      ),
    );
  }
}

class TicketDetailsSheet extends StatefulWidget {
  final SupportTicket ticket;
  final AdminSupportService service;
  const TicketDetailsSheet({super.key, required this.ticket, required this.service});
  @override State<TicketDetailsSheet> createState() => _TicketDetailsSheetState();
}

class _TicketDetailsSheetState extends State<TicketDetailsSheet> {
  final _replyCtl = TextEditingController();
  bool _sending = false;
  late Future<List<SupportReply>> _repliesF;
  
  // New fields for Draft & Handoff
  bool _claimedByMe = false;
  String? _currentAgentId;
  
  // SLA fields
  SlaSnapshot? _sla;

  @override
  void initState() {
    super.initState();
    _repliesF = widget.service.listReplies(widget.ticket.id);
    
    // Initialize agent ID and check existing claim
    final user = Supabase.instance.client.auth.currentUser;
    _currentAgentId = user?.id ?? 'unknown';
    // TODO: Check existing claim in DB; default false for now
    
    // Load SLA snapshot
    unawaited(_loadSla());
  }

  Future<void> _loadSla() async {
    final s = await widget.service.getSlaSnapshot(widget.ticket.id);
    if (!mounted) return;
    setState(() => _sla = s);
  }

  @override
  void dispose() { _replyCtl.dispose(); super.dispose(); }

    @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (_, c) => Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: DefaultTabController(
          length: 3, // Conversation | Info | Timeline
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.support_agent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.ticket.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                  // Claim/Release button
                  IconButton(
                    tooltip: _claimedByMe ? 'Release claim' : 'Claim ticket',
                    icon: Icon(_claimedByMe ? Icons.lock_open : Icons.lock),
                    onPressed: () async {
                      final contextRef = context;
                      final ok = _claimedByMe
                        ? await widget.service.releaseClaim(widget.ticket.id, _currentAgentId ?? 'unknown')
                        : await widget.service.claimTicket(widget.ticket.id, _currentAgentId ?? 'unknown');
                      if (!mounted) return;
                      setState(() => _claimedByMe = ok ? !_claimedByMe : _claimedByMe);
                      final verb = _claimedByMe ? 'claimed' : 'released';
                      // ignore: use_build_context_synchronously
                      final scaffoldMessenger = ScaffoldMessenger.of(contextRef);
                      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Ticket $verb')));
                      unawaited(widget.service.logTimelineEvent(widget.ticket.id, {
                        'ts': DateTime.now().toIso8601String(),
                        'kind': 'claim',
                        'by': 'agent:${_currentAgentId ?? 'unknown'}',
                        'value': _claimedByMe ? 'claimed' : 'released',
                      }));
                      // Refresh SLA after claim/release
                      unawaited(_loadSla());
                    },
                  ),
                  // Draft & Handoff button
                  IconButton(
                    tooltip: 'Draft & handoff',
                    icon: const Icon(Icons.redo),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                        builder: (_) => SizedBox(
                          height: MediaQuery.of(context).size.height * .80,
                          child: DraftHandoffSheet(
                            ticketId: widget.ticket.id,
                            agentId: _currentAgentId ?? 'unknown',
                            teammates: [
                              // TODO: Get actual teammates from presence service
                              {'id': 'agent1', 'name': 'Agent 1'},
                              {'id': 'agent2', 'name': 'Agent 2'},
                            ],
                            initialDraft: _replyCtl.text.isEmpty ? null : _replyCtl.text,
                          ),
                        ),
                      );
                    },
                  ),
                  // SLA Badge
                  if (_sla != null) Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SlaBadge(ticketId: widget.ticket.id),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ]),
              ),
              // Tab Bar
              const TabBar(tabs: [
                Tab(text: 'Conversation'),
                Tab(text: 'Info'),
                Tab(text: 'Timeline'),
              ]),
              // Breach Banner (if SLA is breached)
              if (_sla != null) BreachBanner(ticketId: widget.ticket.id, agentId: _currentAgentId ?? 'unknown', snap: _sla!),
              // Tab Content
              Expanded(
                child: TabBarView(children: [
                  _buildConversation(),
                  _buildInfo(),
                  _buildTimeline(),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String t) => Chip(label: Text(t));

  Widget _buildConversation() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.ticket.body),
        const SizedBox(height: 12),
        FutureBuilder<List<SupportReply>>(
          future: _repliesF,
          builder: (_, snap) {
            final items = snap.data ?? const [];
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              );
            }
            if (items.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Conversation', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...items.map((r) => ListTile(
                  leading: const Icon(Icons.reply),
                  title: Text(r.body),
                  subtitle: Text(r.createdAt.toLocal().toString()),
                )),
                const Divider(height: 24),
              ],
            );
          },
        ),
        const Text('Reply', style: TextStyle(fontWeight: FontWeight.w600)),
        TextField(
          controller: _replyCtl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Type a helpful reply…'),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendReply,
              icon: const Icon(Icons.send),
              label: const Text('Send'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Apply macro',
            icon: const Icon(Icons.bolt),
            onPressed: () async {
              final macro = await showModalBottomSheet<SupportMacro>(
                context: context,
                showDragHandle: true,
                builder: (_) => SafeArea(
                  child: ListView(
                    children: [
                      const ListTile(title: Text('Reply Macros')),
                      for (final m in kSupportMacros)
                        ListTile(
                          leading: const Icon(Icons.bolt),
                          title: Text(m.name),
                          subtitle: Text(m.reply, maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => Navigator.pop(context, m),
                        ),
                    ],
                  ),
                ),
              );
              if (macro == null || !mounted) return;
              _replyCtl.text = macro.reply;
              if (macro.assignToMe) {
                final uid = Supabase.instance.client.auth.currentUser?.id;
                if (uid != null) {
                  await widget.service.updateTicket(id: widget.ticket.id, assigneeId: uid);
                }
              }
              if (macro.addTags.isNotEmpty) {
                final tags = {...widget.ticket.tags, ...macro.addTags}.toList();
                await widget.service.updateTicket(id: widget.ticket.id, tags: tags);
              }
              if (macro.statusAfter != null) {
                await widget.service.updateTicket(id: widget.ticket.id, status: macro.statusAfter);
              }
              if (mounted) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Macro applied: ${macro.name}')),
                );
                setState(() {}); // reflect UI
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              _replyCtl.text = v;
              setState(() {});
            },
            itemBuilder: (_) => cannedReplies
                .map((t) => PopupMenuItem(
                      value: t,
                      child: Text(
                        t,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
          ),
        ]),
      ],
    );
  }

  Widget _buildInfo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(spacing: 8, children: [
          _chip('Priority: ${widget.ticket.priority}'),
          _chip('Status: ${widget.ticket.status}'),
          if (widget.ticket.tags.isNotEmpty) _chip(widget.ticket.tags.join(' • ')),
        ]),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Created'),
          subtitle: Text(widget.ticket.createdAt.toLocal().toString()),
        ),
        ListTile(
          title: const Text('Updated'),
          subtitle: Text(widget.ticket.updatedAt.toLocal().toString()),
        ),
        if (widget.ticket.firstResponseAt != null)
          ListTile(
            title: const Text('First Response'),
            subtitle: Text(widget.ticket.firstResponseAt!.toLocal().toString()),
          ),
        if (widget.ticket.resolvedAt != null)
          ListTile(
            title: const Text('Resolved'),
            subtitle: Text(widget.ticket.resolvedAt!.toLocal().toString()),
          ),
        if (widget.ticket.slaResponse != null)
          ListTile(
            title: const Text('Response SLA'),
            subtitle: Text('${widget.ticket.slaResponse!.inHours}h'),
          ),
        if (widget.ticket.slaResolution != null)
          ListTile(
            title: const Text('Resolution SLA'),
            subtitle: Text('${widget.ticket.slaResolution!.inHours}h'),
          ),
      ],
    );
  }

  Widget _buildTimeline() {
    return TicketTimeline(ticketId: widget.ticket.id);
  }

  Future<void> _sendReply() async {
    setState(() => _sending = true);
    await widget.service.addReply(widget.ticket.id, _replyCtl.text);
    
    // Set first response timestamp if this is the first staff reply
    await widget.service.ensureFirstResponseSet(widget.ticket);
    
    // Send email notification to requester
    await widget.service.notifyRequesterOnReply(
      ticket: widget.ticket,
      replyBody: _replyCtl.text.trim(),
    );
    
    // Log timeline event
    unawaited(widget.service.logTimelineEvent(widget.ticket.id, {
      'ts': DateTime.now().toIso8601String(),
      'kind': 'message',
      'by': 'agent:${_currentAgentId ?? 'unknown'}',
      'text': _replyCtl.text.trim(),
    }));
    
    if (!mounted) return;
    setState(() => _sending = false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    navigator.pop();
    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Reply sent')));
  }
}
