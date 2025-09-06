import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vagus_app/services/admin/admin_support_service.dart';
import 'package:vagus_app/models/admin/support_models.dart';
import 'package:vagus_app/screens/admin/support/widgets/ticket_card.dart';
import 'package:vagus_app/screens/admin/support/support_rules_editor_screen.dart';
import 'package:vagus_app/screens/admin/support/support_sla_editor_screen.dart';
import 'package:vagus_app/screens/admin/support/support_canned_replies_screen.dart';
import 'package:vagus_app/services/admin/admin_presence_service.dart';
import 'package:vagus_app/widgets/admin/support/presence_bar.dart';
import 'package:vagus_app/widgets/admin/support/support_copilot_panel.dart';
import 'package:vagus_app/widgets/admin/support/saved_views_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Custom Intent for Select All
class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class SupportInboxScreen extends StatefulWidget {
  const SupportInboxScreen({super.key});
  @override State<SupportInboxScreen> createState() => _SupportInboxScreenState();
}

class _SupportInboxScreenState extends State<SupportInboxScreen> {
  late final AdminSupportService _svc;
  StreamSubscription<SupportEvent>? _sub;
  String _filter = 'urgent';         // current server-side filter
  bool _selectMode = false;
  bool _boardMode = false;           // List / Board view toggle
  final _selected = <String>{};      // ticket ids
  bool _loading = true;
  List<SupportTicket> _tickets = const [];
  

  
  // Selection state
  bool get _hasSelection => _selected.isNotEmpty;
  
  // Search state
  final _searchCtl = TextEditingController();
  Timer? _searchDebounce;
  List<AdminSearchHit> _searchHits = const [];
  bool _searchOpen = false;

  // Right pane state
  String? _previewTicketId;     // selected ticket to preview
  Map<String, SlaPolicy> _sla = const {};



  // Presence state
  final _presence = AdminPresenceService.instance;
  String? _currentTicketId;
  String? _currentAgentId;
  bool _collision = false;
  late final VoidCallback _peersListener;



  @override
  void initState() {
    super.initState();
    _svc = AdminSupportService.instance;
    _svc.subscribeRealtime();
    _svc.startSlaTicker(every: const Duration(minutes: 1));
    _svc.loadSlaPolicy(); // Load SLA policies
    
    // Initialize presence service
    _initializePresence();
    
    _sub = _svc.events.listen((ev) async {
      if (!mounted) return;
      if (ev.action == 'INSERT' && ev.table == 'support_requests') {
        await _svc.applyAutoTriageIfNeeded(ev.row);
        setState(() {});
      } else if (ev.action == 'TICK') {
        setState(() {}); // refresh SLA clocks
      }
    });
    _load();
  }

  void _initializePresence() {
    final user = Supabase.instance.client.auth.currentUser;
    _currentAgentId = user?.id ?? 'unknown';
    
    _peersListener = () {
      if (!mounted) return;
      final peers = _presence.peers.value;
      final othersReplying = peers.where((p) => 
        p['agent_id'] != _currentAgentId && (p['replying'] ?? false) == true
      ).isNotEmpty;
      setState(() => _collision = othersReplying);
    };
    _presence.peers.addListener(_peersListener);
  }

  void _connectToTicketPresence(String ticketId) {
    if (_currentTicketId == ticketId) return; // Already connected
    _currentTicketId = ticketId;
    unawaited(_presence.connect(
      ticketId: ticketId,
      agentId: _currentAgentId ?? 'unknown',
      agentName: _currentAgentId ?? 'Agent',
      avatarUrl: null,
    ));
  }



  Future<void> _exportCsv() async {
    final csv = _svc.ticketsToCsv(_tickets);
    // For now, just copy to clipboard since we don't have a file sharing utility
    await Clipboard.setData(ClipboardData(text: csv));
    _toast('Exported ${_tickets.length} tickets to clipboard');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtl.dispose();
    try { _sub?.cancel(); } catch (_) {}
    _svc.stopSlaTicker();
    _svc.dispose();
    _presence.peers.removeListener(_peersListener);
    unawaited(_presence.setTyping(false));
    unawaited(_presence.setReplying(false));
    unawaited(_presence.dispose());
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      if (v.trim().isEmpty) {
        setState(() => _searchHits = const []);
        return;
      }
      final res = await _svc.searchEverything(v);
      if (!mounted) return;
      setState(() {
        _searchHits = res;
        _searchOpen = true;
      });
    });
  }

  void _closeSearchOverlay() {
    setState(() {
      _searchOpen = false;
      _searchHits = const [];
    });
    _searchCtl.clear();
  }

  void _tapSearchHit(AdminSearchHit h) {
    _closeSearchOverlay();
    switch (h.kind) {
      case 'ticket':
        _openTicketId(h.id); // implement: calls your detail route
        break;
      case 'user':
        // navigate to User Manager and prefilter by id/email
        // AppNavigator.adminUsers(context, prefill: h.id); // or pushNamed
        break;
      case 'payment':
        // AppNavigator.adminBilling(context, focusPaymentId: h.id);
        break;
    }
  }

  void _openTicketId(String id) {
    // Find ticket by ID and open it
    final ticket = _tickets.firstWhere((t) => t.id == id, orElse: () => _tickets.first);
    _openTicket(ticket);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tickets = await _svc.listTickets(filter: _filter);
    // bring breached on top client-side
    tickets.sort((a, b) {
      final ab = (a.responseBreached || a.resolutionBreached) ? 1 : 0;
      final bb = (b.responseBreached || b.resolutionBreached) ? 1 : 0;
      if (ab != bb) return bb.compareTo(ab);
      return b.updatedAt.compareTo(a.updatedAt);
    });
    if (!mounted) return;
    setState(() { _tickets = tickets; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA): const SelectAllIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) => _clearSelection(),
          ),
          SelectAllIntent: CallbackAction<SelectAllIntent>(
            onInvoke: (intent) => _selectAllVisible(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: const Text('Support'),
                  actions: [
                    if (_hasSelection) ...[
                      Text('${_selected.length} selected'),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: Icon(_selectMode ? Icons.close : Icons.check_box),
                      onPressed: _toggleSelect,
                      tooltip: _selectMode ? 'Exit Selection' : 'Select Mode',
                    ),
                    IconButton(
                      tooltip: 'Escalate breached',
                      icon: const Icon(Icons.trending_up),
                      onPressed: () async {
                        final list = await _svc.listTickets(filter: _filter);
                        for (final t in list) { await _svc.escalateIfNeeded(t); }
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escalations applied')));
                        setState(() {});
                      },
                    ),
                    IconButton(
                      tooltip: _selectMode ? 'Cancel selection' : 'Select',
                      icon: Icon(_selectMode ? Icons.check_box : Icons.check_box_outline_blank),
                      onPressed: () => setState(() => _selectMode = !_selectMode),
                    ),
                    IconButton(
                      tooltip: 'Copy CSV (current filter)',
                      icon: const Icon(Icons.table_view),
                      onPressed: () async {
                        final count = await _svc.copyCsvToClipboard(filter: _filter);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('CSV copied ($count rows)')),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Export CSV',
                      icon: const Icon(Icons.download),
                      onPressed: _exportCsv,
                    ),
                    IconButton(
                      tooltip: _boardMode ? 'Switch to List view' : 'Switch to Board view',
                      icon: Icon(_boardMode ? Icons.view_list : Icons.view_column),
                      onPressed: () => setState(() => _boardMode = !_boardMode),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (s) {
                        if (s=='rules') Navigator.of(context).push(MaterialPageRoute(builder: (_)=>const SupportRulesEditorScreen()));
                        if (s=='sla') Navigator.of(context).push(MaterialPageRoute(builder: (_)=>const SupportSlaEditorScreen()));
                        if (s=='canned') Navigator.of(context).push(MaterialPageRoute(builder: (_)=>const SupportCannedRepliesScreen()));
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value:'rules', child: Text('Auto-Triage Rules')),
                        PopupMenuItem(value:'sla', child: Text('SLA Policies')),
                        PopupMenuItem(value:'canned', child: Text('Canned Replies')),
                      ],
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(54),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: TextField(
                        controller: _searchCtl,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search tickets, users, payments…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchCtl.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _closeSearchOverlay,
                                ),
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                      ),
                    ),
                  ),
                ),
                                 body: _buildScaffoldWithListAndRail(),
              ),
              if (_searchOpen) Positioned.fill(child: _buildSearchOverlay()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget buildChip(String k, String label, IconData icon) => ChoiceChip(
      selected: _filter == k,
      label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)]),
      onSelected: (v) {
        if (!v) return;
        setState(() {
          _filter = k;
        });
        _load();
      },
    );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            buildChip('urgent', 'Urgent', Icons.sos_rounded),
            buildChip('open', 'Open', Icons.inbox_outlined),
            buildChip('mine', 'Assigned to me', Icons.assignment_ind_outlined),
            buildChip('closed', 'Closed', Icons.check_circle_outline),
          ]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Escalate breached',
                icon: const Icon(Icons.trending_up),
                onPressed: () async {
                  final list = await _svc.listTickets(filter: _filter);
                  for (final t in list) { await _svc.escalateIfNeeded(t); }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escalations applied')));
                  setState(() {});
                },
              ),
              IconButton(
                tooltip: _selectMode ? 'Cancel selection' : 'Select',
                icon: Icon(_selectMode ? Icons.check_box : Icons.check_box_outline_blank),
                onPressed: () => setState(() => _selectMode = !_selectMode),
              ),
              IconButton(
                tooltip: 'Copy CSV (current filter)',
                icon: const Icon(Icons.table_view),
                onPressed: () async {
                  final count = await _svc.copyCsvToClipboard(filter: _filter);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('CSV copied ($count rows)')),
                  );
                },
              ),
              IconButton(
                tooltip: _boardMode ? 'Switch to List view' : 'Switch to Board view',
                icon: Icon(_boardMode ? Icons.view_list : Icons.view_column),
                onPressed: () => setState(() => _boardMode = !_boardMode),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedViews() {
    final currentFilters = {'state': _filter};
    return SavedViewsBar(
      currentFilters: currentFilters,
      onSelect: (view) {
        setState(() {
          // Apply the selected view's filters
          if (view.filters.containsKey('state')) {
            _filter = view.filters['state'] as String? ?? 'urgent';
          }
        });
        _load(); // Reload tickets with new filters
      },
    );
  }



  Widget _buildTicketTile(SupportTicket ticket) {
    final selected = _selected.contains(ticket.id);
    return ListTile(
      leading: _selectMode
          ? Checkbox(
              value: selected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selected.add(ticket.id);
                  } else {
                    _selected.remove(ticket.id);
                  }
                });
              },
            )
          : const Icon(Icons.support_agent, color: Colors.grey),
      title: Text(ticket.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${ticket.requesterEmail} • ${ticket.status.toUpperCase()}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (ticket.priority == 'urgent') const Icon(Icons.priority_high, color: Colors.red),
          _slaBadge(ticket),
        ],
      ),
             onTap: _selectMode
           ? () => setState(() {
                 if (selected) {
                   _selected.remove(ticket.id);
                 } else {
                   _selected.add(ticket.id);
                 }
               })
           : () {
                 setState(() => _previewTicketId = '${ticket.id}');
                 _openTicket(ticket);
               },
    );
  }

  void _openTicket(SupportTicket t) {
    _connectToTicketPresence(t.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TicketDetailsSheet(ticket: t, service: _svc),
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '${_selected.length} tickets selected',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          _chip('Status', Icons.flag, () => _bulkSetStatus()),
          _chip('Priority', Icons.priority_high, () => _bulkSetPriority()),
          _chip('Assign', Icons.person, () => _bulkAssign()),
          _chip('Tags', Icons.label, () => _bulkAddTags()),
          _chip('Reply', Icons.reply, () => _bulkCannedReply()),
          _chip('Merge', Icons.merge, () => _bulkMerge()),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _clearSelection,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: Colors.white),
        onPressed: onTap,
      ),
    );
  }

  // Bulk Action Handlers
  void _bulkSetStatus() async {
    final status = await showDialog<String>(
      context: context,
      builder: (context) => _SimplePicker(
        title: 'Set Status',
        options: ['open', 'replied', 'resolved', 'closed'],
        currentValue: null,
      ),
    );
    if (status != null) {
      await _bulkUpdate(BulkUpdateRequest(status: status));
    }
  }

  void _bulkSetPriority() async {
    final priority = await showDialog<String>(
      context: context,
      builder: (context) => _SimplePicker(
        title: 'Set Priority',
        options: ['low', 'normal', 'high', 'urgent'],
        currentValue: null,
      ),
    );
    if (priority != null) {
      await _bulkUpdate(BulkUpdateRequest(priority: priority));
    }
  }

  void _bulkAssign() async {
    final assignedTo = await showDialog<String>(
      context: context,
      builder: (context) => _SimplePicker(
        title: 'Assign To',
        options: ['admin1', 'admin2', 'admin3'], // TODO: Get from service
        currentValue: null,
      ),
    );
    if (assignedTo != null) {
      await _bulkUpdate(BulkUpdateRequest(assignedTo: assignedTo));
    }
  }

  void _bulkAddTags() async {
    final tags = await showDialog<List<String>>(
      context: context,
      builder: (context) => _SimplePicker(
        title: 'Add Tags',
        options: ['bug', 'feature', 'urgent', 'documentation'],
        currentValue: null,
        multiSelect: true,
      ),
    );
    if (tags != null) {
      await _bulkUpdate(BulkUpdateRequest(tags: tags));
    }
  }

  void _bulkCannedReply() async {
    final replyId = await showDialog<String>(
      context: context,
      builder: (context) => _CannedReplyPicker(),
    );
    if (replyId != null) {
      try {
        await _svc.applyCannedReplyToTickets(_selected.toList(), replyId);
        _toast('Applied canned reply to ${_selected.length} tickets');
        _afterBulkRefresh();
      } catch (e) {
        _toast('Failed to apply canned reply: $e');
      }
    }
  }

  void _bulkMerge() async {
    if (_selected.length < 2) {
      _toast('Select at least 2 tickets to merge');
      return;
    }

    final primaryId = await showDialog<String>(
      context: context,
      builder: (context) => _SimplePicker(
        title: 'Select Primary Ticket',
        options: _selected.toList(),
        currentValue: _selected.first,
      ),
    );
    if (primaryId != null) {
      final secondaryIds = _selected.where((id) => id != primaryId).toList();
      try {
        await _svc.mergeTickets(primaryId, secondaryIds);
        _toast('Merged ${secondaryIds.length} tickets into primary');
        _afterBulkRefresh();
      } catch (e) {
        _toast('Failed to merge tickets: $e');
      }
    }
  }

  Future<void> _bulkUpdate(BulkUpdateRequest request) async {
    try {
      await _svc.bulkUpdateTickets(_selected.toList(), request);
      _toast('Updated ${_selected.length} tickets');
      _afterBulkRefresh();
    } catch (e) {
      _toast('Failed to update tickets: $e');
    }
  }

  void _afterBulkRefresh() {
    _clearSelection();
    _load();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _toggleSelect() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selected.clear();
    });
  }

  void _clearSelection() {
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
  }

  void _selectAllVisible() {
    setState(() {
      _selected.clear();
      _selected.addAll(_tickets.map((t) => t.id));
    });
  }



  // Single-item action handlers
  void _bulkSetPrioritySingle() => _applySingle((id) async {
    final prios = ['urgent', 'high', 'normal', 'low'];
    final sel = await showModalBottomSheet<String>(context: context, builder: (_) => _SimplePicker(title: 'Priority', options: prios));
    if (!mounted || sel == null) return;
    await _svc.bulkUpdateTickets([id], BulkUpdateRequest(priority: sel));
    if (!mounted) return; _toast('Priority updated'); unawaited(_load());
  });

  void _bulkSetStatusSingle() => _applySingle((id) async {
    final statuses = ['open', 'pending', 'resolved', 'closed'];
    final sel = await showModalBottomSheet<String>(context: context, builder: (_) => _SimplePicker(title: 'Status', options: statuses));
    if (!mounted || sel == null) return;
    await _svc.bulkUpdateTickets([id], BulkUpdateRequest(status: sel));
    if (!mounted) return; _toast('Status updated'); unawaited(_load());
  });

  void _assignSingle() => _applySingle((id) async {
    final assignee = await _pickAgent(); if (!mounted || assignee == null) return;
    await _svc.bulkUpdateTickets([id], BulkUpdateRequest(assignedTo: assignee));
    if (!mounted) return; _toast('Assigned'); unawaited(_load());
  });

  void _replyWithCanned() => _applySingle((id) async {
    final picked = await showModalBottomSheet<CannedReply>(context: context, builder: (_) => _CannedReplyPicker());
    if (!mounted || picked == null) return;
    await _svc.applyCannedReplyToTickets([id], picked.id);
    if (!mounted) return; _toast('Reply posted'); unawaited(_load());
  });

  void _applySingle(Future<void> Function(String id) fn) {
    final id = _previewTicketId; if (id == null) return; unawaited(fn(id));
  }

  Future<String?> _pickAgent() async {
    // TODO: Get from service
    final agents = ['admin1', 'admin2', 'admin3'];
    return await showModalBottomSheet<String>(context: context, builder: (_) => _SimplePicker(title: 'Assign To', options: agents));
  }

  Widget _slaBadge(SupportTicket t) {
    if (t.isClosedLike) return const SizedBox.shrink();
    final now = DateTime.now();
    // choose the nearest due among configured SLAs
    DateTime? due;
    String label = '';
    if (!t.responded && t.responseDue != null) {
      due = t.responseDue;
      label = 'Resp';
    }
    if (t.resolutionDue != null) {
      if (due == null || t.resolutionDue!.isBefore(due)) {
        due = t.resolutionDue;
        label = 'Resolve';
      }
    }
    if (due == null) return const SizedBox.shrink();

    final remaining = due.difference(now);
    final breached = remaining.isNegative;
    final text = breached
        ? '⏱ $label -${remaining.abs().inMinutes}m'
        : '⏱ $label ${remaining.inMinutes}m';

    final color = breached ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: _tickets.length,
      itemBuilder: (_, i) => _buildTicketTile(_tickets[i]),
    );
  }

  Widget _buildBoard() {
    const lanes = ['open', 'pending', 'resolved', 'closed'];
    const laneColors = [Colors.blue, Colors.orange, Colors.green, Colors.grey];
    const laneIcons = [Icons.inbox_outlined, Icons.pending_outlined, Icons.check_circle_outline, Icons.close];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lanes.asMap().entries.map((entry) {
          final i = entry.key;
          final status = entry.value;
          final tickets = _tickets.where((t) => t.status == status).toList();
          
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lane header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: laneColors[i].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(laneIcons[i], color: laneColors[i], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: laneColors[i],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: laneColors[i],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${tickets.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Lane content
                ...tickets.map((ticket) => _boardCard(ticket)),
                if (tickets.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                    ),
                    child: const Center(
                      child: Text(
                        'No tickets',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _boardCard(SupportTicket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildPriorityIcon(ticket.priority),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _slaBadge(ticket)),
                const Spacer(),
                Text(
                  ticket.requesterEmail,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Created ${_formatTimeAgo(ticket.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Open ticket',
                  icon: const Icon(Icons.open_in_new, size: 16),
                  onPressed: () => _openTicket(ticket),
                ),
                IconButton(
                  tooltip: 'Move ticket',
                  icon: const Icon(Icons.drag_indicator, size: 16),
                  onPressed: () => _moveTicketStatus(ticket),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIcon(String priority) {
    final colors = {
      'urgent': Colors.red,
      'high': Colors.orange,
      'normal': Colors.blue,
      'low': Colors.green,
    };
    final icons = {
      'urgent': Icons.sos_rounded,
      'high': Icons.priority_high,
      'normal': Icons.remove,
      'low': Icons.low_priority,
    };
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors[priority]?.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icons[priority] ?? Icons.remove,
        color: colors[priority],
        size: 16,
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }



  void _moveTicketStatus(SupportTicket ticket) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Move ticket to:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('Open'),
              onTap: () async {
                await _svc.updateTicket(id: ticket.id, status: 'open');
                Navigator.pop(context);
                unawaited(_load());
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending_outlined),
              title: const Text('Pending'),
              onTap: () async {
                await _svc.updateTicket(id: ticket.id, status: 'pending');
                Navigator.pop(context);
                unawaited(_load());
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Resolved'),
              onTap: () async {
                await _svc.updateTicket(id: ticket.id, status: 'resolved');
                Navigator.pop(context);
                unawaited(_load());
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Closed'),
              onTap: () async {
                await _svc.updateTicket(id: ticket.id, status: 'closed');
                Navigator.pop(context);
                unawaited(_load());
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isWide(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 1100;

  Widget _buildScaffoldWithListAndRail() {
    final wide = MediaQuery.of(context).size.width >= 1000;
    if (!wide) return _buildScaffoldMobile();
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildFilterChips(),
              _buildSavedViews(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                          onRefresh: _load,
                          child: _boardMode ? _buildBoard() : _buildList(),
                        ),
              ),
              if (_selectMode && _hasSelection) _buildBulkActionsBar(),
            ],
          ),
        ),
        Container(width: 1, color: Colors.black.withValues(alpha: .06)),
        SizedBox(
          width: 380,
          child: _buildRightPane(),
        ),
      ],
    );
  }

  Widget _buildScaffoldMobile() {
    return Column(
      children: [
        _buildFilterChips(),
        _buildSavedViews(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                    onRefresh: _load,
                    child: _boardMode ? _buildBoard() : _buildList(),
                  ),
        ),
        if (_selectMode && _hasSelection) _buildBulkActionsBar(),
        if (_isWide(context)) SizedBox(height: 200, child: _buildMetricsRail()),
      ],
    );
  }

  Widget _buildSearchOverlay() {
    return GestureDetector(
      onTap: _closeSearchOverlay,
      child: Container(
        color: Colors.black.withValues(alpha: .25),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 520),
            child: Material(
              elevation: 10, borderRadius: BorderRadius.circular(12), color: Colors.white,
              child: _searchHits.isEmpty
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No results'),
                    ))
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _searchHits.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final h = _searchHits[i];
                        final icon = h.kind == 'ticket'
                            ? Icons.confirmation_number
                            : h.kind == 'user'
                                ? Icons.person
                                : Icons.receipt_long;
                        return ListTile(
                          leading: Icon(icon),
                          title: Text(h.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(h.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: h.time != null ? Text(_fmtTime(h.time!)) : null,
                          onTap: () => _tapSearchHit(h),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtTime(DateTime d) {
    final now = DateTime.now();
    final isToday = now.year == d.year && now.month == d.month && now.day == d.day;
    if (isToday) {
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  Widget _buildRightPane() {
    SupportTicket? t;
    try {
      t = _tickets.firstWhere((x) => '${x.id}' == _previewTicketId);
    } catch (e) {
      t = _tickets.isNotEmpty ? _tickets.first : null;
    }
    if (t == null) {
      return Center(child: Text('Select a ticket', style: TextStyle(color: Colors.black.withValues(alpha: .5))));
    }

    // After null check, t is guaranteed to be non-null
    final ticket = t!;
    final due = ticket.createdAt == null ? null : _svc.computeResolutionDue(ticket.createdAt, ticket.priority, _sla);
    final isBreaching = due != null && DateTime.now().toUtc().isAfter(due);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Expanded(child: Text('#${ticket.id} • ${ticket.title ?? '(untitled)'}', maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w700))),
            IconButton(
              tooltip: 'Co-Pilot',
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => _openCopilotPanel(ticket.id),
            ),
            IconButton(icon: const Icon(Icons.open_in_new), onPressed: () => _openTicket(ticket)),
          ]),
        ),
        // Meta row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            _pill(icon: Icons.flag, text: ticket.priority ?? 'normal', danger: ticket.priority == 'urgent' || ticket.priority == 'high'),
            _pill(icon: Icons.timelapse, text: ticket.status ?? 'open'),
            if (due != null) _pill(icon: Icons.schedule, text: 'Due ${_relative(due)}', danger: isBreaching),
          ]),
        ),
        const Divider(height: 24),

        // Quick actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(spacing: 8, children: [
            _miniBtn(Icons.low_priority, 'Priority', () => _bulkSetPrioritySingle()),
            _miniBtn(Icons.sync_alt, 'Status', () => _bulkSetStatusSingle()),
            _miniBtn(Icons.person_add, 'Assign', () => _assignSingle()),
            _miniBtn(Icons.quickreply, 'Reply', () => _replyWithCanned()),
          ]),
        ),

        const Divider(height: 24),

        // Presence bar
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: _presence.peers,
          builder: (_, agents, __) => Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: SupportPresenceBar(
              agents: agents,
              selfAgentId: _currentAgentId ?? 'unknown',
              showCollisionBanner: _collision,
            ),
          ),
        ),
        const Divider(height: 1),

        // Conversation preview
        Expanded(child: _buildMiniThread(ticket)),

        // Inline reply
        _inlineReplyComposer(ticketId: '${ticket.id}'),
      ],
    );
  }

  Widget _pill({required IconData icon, required String text, bool danger = false}) {
    final bg = danger ? Colors.red.withValues(alpha: .10) : Colors.black.withValues(alpha: .06);
    final fg = danger ? Colors.red : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: fg), const SizedBox(width: 6), Text(text, style: TextStyle(color: fg))]),
    );
  }

  Widget _miniBtn(IconData i, String t, VoidCallback onTap) {
    return OutlinedButton.icon(onPressed: onTap, icon: Icon(i, size: 16), label: Text(t));
  }

  String _relative(DateTime d) {
    final diff = d.difference(DateTime.now().toUtc());
    final mins = diff.inMinutes;
    if (mins < 0) return '${mins.abs()}m ago';
    if (mins < 60) return 'in ${mins}m';
    if (diff.inHours < 24) return 'in ${diff.inHours}h';
    return 'in ${diff.inDays}d';
  }

  Widget _buildMiniThread(SupportTicket ticket) {
    return FutureBuilder<List<SupportReply>>(
      future: _svc.listReplies(ticket.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final replies = snapshot.data ?? [];
        if (replies.isEmpty) {
          return const Center(child: Text('No replies yet'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: replies.length,
          itemBuilder: (context, index) {
            final reply = replies[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reply.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${reply.authorId} • ${_formatTimeAgo(reply.createdAt)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _inlineReplyComposer({required String ticketId}) {
    final ctrl = TextEditingController();
    
    // Add presence signals for typing and replying
    ctrl.addListener(() {
      unawaited(_presence.setTyping(ctrl.text.isNotEmpty));
    });
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Column(
          children: [
            if (_collision)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: .25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Another agent is replying. Coordinate before sending.',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            Row(children: [
              Expanded(child: TextField(
                controller: ctrl, 
                minLines: 1, 
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Type a reply…'),
                onTap: () => unawaited(_presence.setReplying(true)),
              )),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) return;
                  unawaited(_presence.setReplying(false));
                  await _svc.addReply(ticketId, text);
                  if (!mounted) return;
                  ctrl.clear(); 
                  _toast('Reply sent'); 
                  unawaited(_load());
                },
                icon: const Icon(Icons.send), 
                label: const Text('Send'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _openCopilotPanel(String ticketId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final height = MediaQuery.of(context).size.height;
        return SizedBox(
          height: height * 0.85,
          child: SupportCopilotPanel(
            ticketId: ticketId,
            userId: 'unknown', // TODO: get actual user ID from ticket
            onInsertText: (text) {
              // TODO: insert text into reply composer
              _toast('Text inserted: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
            },
            onApplyAction: (action, args) async {
              // Wire to AdminSupportService actions
              switch (action) {
                case 'set_priority':
                  final ok = await _svc.updateTicketPriority(ticketId, args['priority'] as String);
                  return ok;
                case 'add_tag':
                  final ok2 = await _svc.addTicketTag(ticketId, args['tag'] as String);
                  return ok2;
                case 'escalate':
                  final ok3 = await _svc.escalateTicket(ticketId);
                  return ok3;
                case 'request_logs':
                  final ok4 = await _svc.requestUserLogs(ticketId);
                  return ok4;
              }
              return false;
            },
          ),
        );
      },
    );
  }

  Widget _buildMetricsRail() {
    return FutureBuilder(
      future: Future.wait([
        _svc.countOpenByPriority(),
        _svc.countBreachesToday(),
        _svc.medianTimeToFirstResponseHours(),
        _svc.firstContactResolutionRate(),
        _svc.ticketsCreatedCounts(),
      ]),
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = (snap.data ?? const []) as List;
        final byP = (data.isNotEmpty ? data[0] : const {'urgent':0,'high':0,'normal':0,'low':0}) as Map<String,int>;
        final breaches = (data.length>1 ? data[1] : 0) as int;
        final mttr = (data.length>2 ? data[2] : 0.0) as double;
        final fcr = (data.length>3 ? data[3] : 0.0) as double;
        final created = (data.length>4 ? data[4] : const {'24h':0,'7d':0}) as Map<String,int>;

        Widget statCard(String title, String value, {IconData icon = Icons.insights}) {
          return Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:.05), blurRadius: 8, offset: const Offset(0,2))],
              border: Border.all(color: Colors.black.withValues(alpha:.06)),
            ),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.blue.withValues(alpha:.1), child: Icon(icon, color: Colors.blue)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ])),
              ],
            ),
          );
        }

        Widget bar(String label, int v, int max, Color c) {
          final pct = max == 0 ? 0.0 : (v / max).clamp(0.0, 1.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('$label  ($v)'),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: pct, minHeight: 8, color: c, backgroundColor: c.withValues(alpha:.15)),
              ),
            ],
          );
        }

        final maxLane = [byP['urgent']??0, byP['high']??0, byP['normal']??0, byP['low']??0].fold<int>(0, (m, e) => e>m?e:m);

        return RefreshIndicator(
          onRefresh: () async => setState((){}),
          child: ListView(
            children: [
              statCard('Breaches today', '$breaches', icon: Icons.warning_amber),
              statCard('Median TTF Response (7d)', '${mttr.toStringAsFixed(1)} h', icon: Icons.timer),
              statCard('First Contact Resolution', '${(fcr*100).toStringAsFixed(0)}%', icon: Icons.task_alt),
              statCard('Tickets created', '${created['24h'] ?? 0} (24h) • ${created['7d'] ?? 0} (7d)', icon: Icons.add_chart),
              Container(
                margin: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:.05), blurRadius: 8, offset: const Offset(0,2))],
                  border: Border.all(color: Colors.black.withValues(alpha:.06)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Open by Priority', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  bar('Urgent', byP['urgent'] ?? 0, maxLane, Colors.red),
                  const SizedBox(height: 10),
                  bar('High', byP['high'] ?? 0, maxLane, Colors.orange),
                  const SizedBox(height: 10),
                  bar('Normal', byP['normal'] ?? 0, maxLane, Colors.blue),
                  const SizedBox(height: 10),
                  bar('Low', byP['low'] ?? 0, maxLane, Colors.grey),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Helper Widgets
class _SimplePicker extends StatefulWidget {
  final String title;
  final List<String> options;
  final String? currentValue;
  final bool multiSelect;

  const _SimplePicker({
    required this.title,
    required this.options,
    this.currentValue,
    this.multiSelect = false,
  });

  @override
  State<_SimplePicker> createState() => _SimplePickerState();
}

class _SimplePickerState extends State<_SimplePicker> {
  String? _selectedValue;
  Set<String> _selectedValues = {};

  @override
  void initState() {
    super.initState();
    if (widget.multiSelect) {
      _selectedValues = widget.currentValue != null ? {widget.currentValue!} : {};
    } else {
      _selectedValue = widget.currentValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 300,
        child: widget.multiSelect
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  return CheckboxListTile(
                    title: Text(option),
                    value: _selectedValues.contains(option),
                    onChanged: (checked) {
                      setState(() {
                        if (checked!) {
                          _selectedValues.add(option);
                        } else {
                          _selectedValues.remove(option);
                        }
                      });
                    },
                  );
                },
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  return RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue: _selectedValue,
                    onChanged: (value) {
                      setState(() => _selectedValue = value);
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.multiSelect) {
              Navigator.of(context).pop(_selectedValues.toList());
            } else {
              Navigator.of(context).pop(_selectedValue);
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _CannedReplyPicker extends StatefulWidget {
  @override
  State<_CannedReplyPicker> createState() => _CannedReplyPickerState();
}

class _CannedReplyPickerState extends State<_CannedReplyPicker> {
  List<CannedReply> _replies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  Future<void> _loadReplies() async {
    try {
      final replies = await AdminSupportService.instance.listCannedReplies();
      setState(() {
        _replies = replies;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Canned Reply'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _replies.length,
                itemBuilder: (context, index) {
                  final reply = _replies[index];
                  return ListTile(
                    title: Text(reply.name),
                    subtitle: Text(
                      reply.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Chip(label: Text(reply.category)),
                    onTap: () => Navigator.of(context).pop(reply.id),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
