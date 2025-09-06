import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart' show DateFormat;
import '../../models/admin/ticket_models.dart';
import '../../services/admin/admin_support_service.dart'; // for macros apply if needed
import '../../services/admin/admin_ticket_service.dart';
import '../../services/admin/admin_knowledge_service.dart';
import '../../models/admin/kb_models.dart';
import '../admin/admin_session_copilot_screen.dart';
import '../admin/admin_live_session_screen.dart';
import '../admin/widgets/incident_timeline.dart';
import '../admin/admin_triage_rules_screen.dart';
import '../../models/admin/incident_models.dart';
import '../../services/admin/admin_incident_service.dart';
import 'admin_ticket_board_screen.dart';
import 'widgets/system_health_panel.dart';

class AdminTicketQueueScreen extends StatefulWidget {
  const AdminTicketQueueScreen({super.key});

  @override
  State<AdminTicketQueueScreen> createState() => _AdminTicketQueueScreenState();
}

class _AdminTicketQueueScreenState extends State<AdminTicketQueueScreen> {
  final _svc = AdminTicketService.instance;
  final _incidentSvc = AdminIncidentService.instance;
  final _macros = AdminSupportService.instance; // reuse macros from v8

  TicketStatus? _status;
  TicketPriority? _priority;
  String? _tag;
  List<TicketSummary> _items = const [];
  bool _loading = false;

  // New v15 features
  final Set<String> _selected = <String>{};
  bool _sortAsc = true;
  Timer? _slaTicker;
  Map<String, SlaMeta> _sla = const {};

  // New v16 features
  bool _dense = false;
  DateTime? _exportFrom, _exportTo;

  // New v17 features
  final _searchCtrl = TextEditingController();

  // New v18 features
  final Map<String,String> _views = {'All':'', 'Payments':'invoice OR charge', 'Auth':'login OR otp'};
  String _view = 'All';
  Timer? _debounceTimer;
  int _page = 0;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _startSlaTicker();
  }

  void _startSlaTicker() {
    _slaTicker?.cancel();
    _slaTicker = Timer.periodic(const Duration(seconds: 30), (_) async {
      final ids = _items.map((t) => t.id).toList();
      final map = await _incidentSvc.getSlaForTickets(ids);
      if (!mounted) return;
      setState(() => _sla = map);
    });
  }

  @override
  void dispose() {
    _slaTicker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _svc.listTickets(
      status: _status,
      priority: _priority,
      query: _searchCtrl.text.trim(),
      tagFilter: _tag,
    );
    if (!mounted) return;
    setState(() {
      _items = res;
      _loading = false;
    });
  }

  Future<void> _openDetail(TicketSummary t) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TicketDetailSheet(ticket: t, svc: _incidentSvc),
    );
    if (!mounted) return;
    unawaited(_load());
  }

  Widget _chip<T>({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.keyS): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyB): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyR): const ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(onInvoke: (i) { _openBulkActions(); return null; }),
        },
        child: Focus(
          autofocus: true,
          child: _buildScaffold(context),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => unawaited(_load()),
          ),
        ],
      ),
      body: Column(
          children: [
      Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search subject…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => unawaited(_load()),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => unawaited(_load()),
            child: const Text('Search'),
          ),
        ],
      ),
    ),
    // Enhanced toolbar with system health, bulk actions, and sorting
    Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    child: Column(
    children: [
    const SystemHealthPanel(),
    const SizedBox(height: 8),
    Row(
    children: [
    OutlinedButton.icon(
    onPressed: _openSavedViews,
    icon: const Icon(Icons.visibility),
    label: const Text('Saved views'),
    ),
    const SizedBox(width: 8),
    FilledButton.icon(
    onPressed: _openBulkActions,
    icon: const Icon(Icons.auto_fix_high),
    label: const Text('Bulk actions'),
    ),
    const SizedBox(width: 8),
    OutlinedButton.icon(
    onPressed: () => Navigator.of(context).pushNamed('/admin/canned-replies'),
    icon: const Icon(Icons.quickreply),
    label: const Text('Canned replies'),
    ),
    const SizedBox(width: 8),
    OutlinedButton.icon(
    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminTicketBoardScreen())),
    icon: const Icon(Icons.view_kanban),
    label: const Text('Board'),
    ),
    const Spacer(),
    IconButton(
    tooltip: _sortAsc ? 'Sort desc' : 'Sort asc',
    onPressed: () {
    setState(() => _sortAsc = !_sortAsc);
    _applySort();
    },
    icon: Icon(_sortAsc ? Icons.south : Icons.north),
    ),
    const SizedBox(width: 8),
    OutlinedButton.icon(
    onPressed: _toggleDensity,
    icon: Icon(_dense ? Icons.view_agenda : Icons.density_small),
    label: Text(_dense ? 'Cozy' : 'Compact'),
    ),
    const SizedBox(width: 8),
    OutlinedButton.icon(
    onPressed: _openExportRange,
    icon: const Icon(Icons.date_range),
    label: const Text('Export range'),
    ),
    ],
    ),
    ],
    ),
    ),
    SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
    children: [
    _chip(
    label: 'All',
    selected: _status == null,
    onTap: () {
    setState(() => _status = null);
    unawaited(_load());
    },
    ),
    const SizedBox(width: 6),
    _chip(
    label: 'Open',
    selected: _status == TicketStatus.open,
    onTap: () {
    setState(() => _status = TicketStatus.open);
    unawaited(_load());
    },
    ),
    const SizedBox(width: 6),
    _chip(
    label: 'Pending',
    selected: _status == TicketStatus.pending,
    onTap: () {
    setState(() => _status = TicketStatus.pending);
    unawaited(_load());
    },
    ),
    const SizedBox(width: 6),
    _chip(
    label: 'Solved',
    selected: _status == TicketStatus.solved,
    onTap: () {
    setState(() => _status = TicketStatus.solved);
    unawaited(_load());
    },
    ),
    const SizedBox(width: 6),
    _chip(
    label: 'Archived',
    selected: _status == TicketStatus.archived,
    onTap: () {
    setState(() => _status = TicketStatus.archived);
    unawaited(_load());
    },
    ),
    const SizedBox(width: 16),
    _chip(
    label: 'P: Any',
    selected: _priority == null,
    onTap: () {
    setState(() => _priority = null);
    unawaited(_load());
    },
    ),
    const SizedBox(width: 6),
    _chip(
    label: 'Low',
    selected: _priority == TicketPriority.low,
    onTap: () {
    setState(() => _priority = TicketPriority.low);
    unawaited(_load());
    },
    ),
    const SizedBox(width: 6),
    _chip(
    label: 'Normal',
    selected: _priority == TicketPriority.normal,
    onTap: () {
    setState(() => _priority = TicketPriority.normal);
    unawaited(_load());
    },
    ),
    const SizedBox(width: 6),
    _chip(
    label: 'High',
    selected: _priority == TicketPriority.high,
    onTap: () {
    setState(() => _priority = TicketPriority.high);
    unawaited(_load());
    },
    ),
    const SizedBox(width: 6),
    _chip(
    label: 'Urgent',
    selected: _priority == TicketPriority.urgent,
    onTap: () {
    setState(() => _priority = TicketPriority.urgent);
    unawaited(_load());
    },
    ),
    ],
    ),
    ),
    const SizedBox(height: 6),
    // Saved views and bulk actions toolbar
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
    children: [
    OutlinedButton.icon(
    onPressed: _openSavedViews,
    icon: const Icon(Icons.view_cozy),
    label: const Text('Saved views'),
    ),
    const SizedBox(width: 8),
    FilledButton.icon(
    onPressed: _openBulkActions,
    icon: const Icon(Icons.playlist_add_check),
    label: const Text('Bulk actions'),
    ),
    const Spacer(),
    OutlinedButton.icon(
    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => const AdminTriageRulesScreen(),
    )),
    icon: const Icon(Icons.rule),
    label: const Text('Auto-triage'),
    ),
    ],
    ),
    ),
    if (_loading) const LinearProgressIndicator(minHeight: 2),

    // Selection bar
    if (_selected.isNotEmpty)
    Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
    child: Row(
    children: [
    Text(
    '${_selected.length} selected',
    style: Theme.of(context).textTheme.titleMedium,
    ),
    const Spacer(),
    Wrap(
    spacing: 8,
    children: [
    OutlinedButton.icon(
    onPressed: () async {
    final ids = _selected.toList();
    for (final id in ids) {
    await _incidentSvc.escalate(id);
    }
    if (!mounted) return;
    setState(() => _selected.clear());
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Escalated ${ids.length} tickets'))
    );
    },
    icon: const Icon(Icons.upgrade),
    label: const Text('Escalate'),
    ),
    OutlinedButton.icon(
    onPressed: () async {
    final ids = _selected.toList();
    for (final id in ids) {
    await _svc.setStatus(id, TicketStatus.solved);
    }
    if (!mounted) return;
    setState(() => _selected.clear());
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Resolved ${ids.length} tickets'))
    );
    },
    icon: const Icon(Icons.check_circle),
    label: const Text('Resolve'),
    ),
    OutlinedButton.icon(
    onPressed: () async {
    final ids = _selected.toList();
    final csv = StringBuffer();
    csv.writeln('id,subject,requester,status,priority,created');
    for (final id in ids) {
    final t = _items.firstWhere((t) => t.id == id);
    csv.writeln('${t.id},"${t.subject}","${t.requesterName}",${t.status.name},${t.priority.name},${t.createdAt}');
    }
    await Clipboard.setData(ClipboardData(text: csv.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Exported ${ids.length} tickets to clipboard'))
    );
    },
    icon: const Icon(Icons.download),
    label: const Text('Export CSV'),
    ),
    TextButton.icon(
    onPressed: () => setState(() => _selected.clear()),
    icon: const Icon(Icons.clear),
    label: const Text('Clear'),
    ),
    ],
    ),
    ],
    ),
    ),

    // Saved views and search
    Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: Row(
    children: [
    Expanded(
    child: DropdownButtonFormField<String>(
    value: _view,
    decoration: const InputDecoration(
    labelText: 'Saved Views',
    border: OutlineInputBorder(),
    ),
    items: _views.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
    onChanged: (v) {
    if (v != null) {
    setState(() {
    _view = v;
    _searchCtrl.text = _views[v] ?? '';
    });
    }
    },
    ),
    ),
    const SizedBox(width: 12),
    Expanded(
    flex: 2,
    child: TextField(
    controller: _searchCtrl,
    onChanged: (v) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
    setState(() {});
    });
    },
    decoration: const InputDecoration(
    prefixIcon: Icon(Icons.search),
    hintText: 'Search tickets…',
    ),
    ),
    ),
    ],
    ),
    ),
    Expanded(
    child: Shortcuts(
    shortcuts: <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.slash): const ActivateIntent(), // focus search
    LogicalKeySet(LogicalKeyboardKey.keyE): const ActivateIntent(), // escalate
    LogicalKeySet(LogicalKeyboardKey.keyA): const ActivateIntent(), // open AI
    },
    child: Actions(
    actions: <Type, Action<Intent>>{
    ActivateAction: CallbackAction<Intent>(onInvoke: (_){
    // focus search
    FocusScope.of(context).requestFocus(_searchCtrl.selection.isValid ? null : FocusNode());
    return null;
    }),
    },
    child: ListView.separated(
    itemCount: _items.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (_, i) {
    final t = _items[i];
    final id = t.id;

    // Search filtering
    final matches = _searchCtrl.text.isEmpty ||
    t.subject.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
    id.toLowerCase().contains(_searchCtrl.text.toLowerCase());
    if (!matches) return const SizedBox.shrink();
    final sla = _sla[id];
    final breached = sla?.breached == true;
    final rem = sla?.remaining;
    final remText = rem == null ? '' : (rem.isNegative ? 'overdue' : '${rem.inHours}h ${rem.inMinutes.remainder(60)}m');

    final color = switch (t.priority) {
    TicketPriority.low => Colors.blueGrey,
    TicketPriority.normal => Colors.blue,
    TicketPriority.high => Colors.orange,
    TicketPriority.urgent => Colors.red,
    };

    // Risk calculation for Smart Triage
    final ageHours = t.age.inHours.clamp(0, 72);
    final prioWeight = switch (t.priority) {
    TicketPriority.low => 0.1,
    TicketPriority.normal => 0.3,
    TicketPriority.high => 0.6,
    TicketPriority.urgent => 1.0,
    };
    final risk = (ageHours / 72) * 0.6 + prioWeight; // 0..1
    final riskColor = Color.lerp(Colors.green, Colors.red, risk.clamp(0, 1)) ?? Colors.orange;

    final presCount = _incidentSvc.presenceCount(id);
    final densePad = _dense ? const EdgeInsets.symmetric(horizontal: 8, vertical: 0) : const EdgeInsets.symmetric(horizontal: 16, vertical: 4);

    return Container(
    decoration: BoxDecoration(
    border: Border(left: BorderSide(color: riskColor, width: 4)),
    ),
    child: ListTile(
    contentPadding: densePad,
    onTap: () {
    _incidentSvc.pingPresence(id);
    _openDetail(t);
    },
    leading: Checkbox(
    value: _selected.contains(id),
    onChanged: (v) {
    setState(() => v == true ? _selected.add(id) : _selected.remove(id));
    },
    ),
    title: Text(t.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: _dense ? 13.5 : 15)),
    subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text('#$id • ${t.requesterName} • ${t.tags.join(", ")}'),
    Row(children: [
    if (sla != null) ...[
    Icon(
    breached ? Icons.warning_amber_rounded : Icons.schedule,
    size: 16,
    color: breached ? Colors.red : Colors.green,
    ),
    const SizedBox(width: 6),
    Text(
    breached ? 'SLA breached' : 'SLA $remText',
    style: TextStyle(
    color: breached ? Colors.red : Colors.green,
    fontWeight: FontWeight.w500,
    ),
    ),
    const SizedBox(width: 12),
    ],
    const Icon(Icons.group, size: 16),
    const SizedBox(width: 4),
    Text('${presCount} online'),
    ]),
    ],
    ),
    trailing: Wrap(
    spacing: 4,
    children: [
    OutlinedButton.icon(
    icon: const Icon(Icons.auto_awesome, size: 16),
    label: const Text('AI'),
    onPressed: () => _openAiAssist(t),
    ),
    PopupMenuButton<String>(
    itemBuilder: (_) => [
    const PopupMenuItem(
    value: 'export',
    child: Text('Export timeline CSV'),
    ),
    const PopupMenuItem(
    value: 'copy',
    child: Text('Copy timeline CSV'),
    ),
    const PopupMenuItem(
    value: 'imp',
    child: Text('Impersonate user (dev)'),
    ),
    const PopupMenuItem(
    value: 'pb',
    child: Text('Run playbook…'),
    ),
    const PopupMenuItem(
    value: 'esc',
    child: Text('Escalate T2'),
    ),
    ],
    onSelected: (v) async {
    if (v == 'copy' || v == 'export') {
    final csv = await _incidentSvc.buildTimelineCsvRange(id, from: _exportFrom, to: _exportTo);
    if (v == 'copy') {
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Timeline CSV copied')),
    );
    } else if (v == 'export') {
    if (kIsWeb) {
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Web: CSV copied (download not available)')),
    );
    } else {
    final path = await _incidentSvc.writeTextTemp('timeline_$id.csv', csv);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Saved: $path')),
    );
    }
    }
    } else if (v == 'imp') {
    if (!_incidentSvc.canImpersonate) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Impersonation disabled in release builds')),
    );
    } else {
    await _incidentSvc.impersonateUser(t.requesterName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Impersonating ${t.requesterName} (dev-only)')),
    );
    }
    } else if (v == 'pb') {
    final pbs = await _incidentSvc.listPlaybooks();
    if (!mounted) return;
    final pb = await showModalBottomSheet<AdminPlaybook>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
    child: ListView(
    children: [
    const ListTile(title: Text('Choose playbook')),
    ...pbs.map((p) => ListTile(
    leading: const Icon(Icons.checklist),
    title: Text(p.name),
    subtitle: Text(p.steps.join(' → '), maxLines: 2, overflow: TextOverflow.ellipsis),
    onTap: () => Navigator.of(c).pop(p),
    )),
    ],
    ),
    ),
    );
    if (pb != null) {
    await _incidentSvc.addEvent(IncidentEvent(
    id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
    ticketId: id,
    kind: IncidentKind.note,
    title: 'Playbook started: ${pb.name}',
    details: pb.steps.join('\n• '),
    at: DateTime.now(),
    by: 'admin',
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Playbook "${pb.name}" added to #$id'))
    );
    }
    } else if (v == 'esc') {
    await _incidentSvc.escalate(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Escalated #$id'))
    );
    } else if (v.startsWith('macro:')) {
    await _macros.applyMacroToTicket(
    ticketId: t.id,
    macroId: v.split(':')[1],
    );
    } else if (v.startsWith('status:')) {
    await _svc.setStatus(
    t.id,
    TicketStatus.values.firstWhere((s) => s.name == v.split(':')[1]),
    );
    }
    if (mounted) {
    unawaited(_load());
    }
    },
    ),
    ],
    ),
    ),
    );
    },
    ),
    ),
    ),
    ),
    ],
    ),
    );
  }

  // Lazy cached macros list for menu (simple)
  List<Macro>? awaitingMacros;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (awaitingMacros == null) {
      _macros.listMacros().then((m) {
        if (!mounted) return;
        setState(() => awaitingMacros = m);
      });
    }
  }



  // ---- Helper methods for v15 features ----

  void _toggleDensity() { setState(() => _dense = !_dense); }

  Future<void> _openExportRange() async {
    final now = DateTime.now();
    final from = await showDatePicker(context: context, firstDate: DateTime(now.year-2), lastDate: now, initialDate: _exportFrom ?? now);
    if (!mounted) return;
    final to   = await showDatePicker(context: context, firstDate: DateTime(now.year-2), lastDate: now, initialDate: _exportTo ?? now);
    if (!mounted) return;
    if (from!=null && to!=null) {
      setState(()=> {_exportFrom = from, _exportTo = to});
      // uses per-row menu "Export timeline CSV" to honor range
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Range set: ${DateFormat.yMMMd().format(from)} → ${DateFormat.yMMMd().format(to)}')));
    }
  }

  void _applySort() {
    setState(() {
      _items.sort((a, b) {
        int c;
        c = a.createdAt.compareTo(b.createdAt); // Sort by creation time
        return _sortAsc ? c : -c;
      });
    });
  }

  Future<void> _openSavedViews() async {
    // Placeholder for saved views functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved Views - feature placeholder')),
    );
  }

  Future<void> _openBulkActions() async {
    final selected = _selected.toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tickets selected')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) {
        return SafeArea(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.select_all),
                title: Text('Selected: ${selected.length}'),
                subtitle: const Text('Choose an action to apply'),
              ),
              const Divider(),

              // Canned reply picker
              ListTile(
                leading: const Icon(Icons.quickreply),
                title: const Text('Send canned reply…'),
                onTap: () async {
                  final replies = await _macros.listCannedReplies();
                  if (!mounted) return;
                  final r = await showModalBottomSheet<CannedReply>(
                    context: context,
                    showDragHandle: true,
                    builder: (c) => SafeArea(
                      child: ListView(
                        children: [
                          const ListTile(title: Text('Choose a reply')),
                          ...replies.map((x) => ListTile(
                            leading: const Icon(Icons.quickreply),
                            title: Text(x.name),
                            subtitle: Text(x.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () => Navigator.of(c).pop(x),
                          )),
                        ],
                      ),
                    ),
                  );
                  if (r != null) {
                    Navigator.of(context).pop(); // close sheet
                    await _incidentSvc.bulkApply(
                        ticketIds: selected,
                        reply: {'name': r.name, 'content': r.content}
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Applied "${r.name}" to ${selected.length} tickets')),
                    );
                  }
                },
              ),

              // Auto-triage simulation
              ListTile(
                leading: const Icon(Icons.auto_fix_high),
                title: const Text('Simulate auto-triage'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final actions = await _incidentSvc.evaluate(const ['network', 'login']);
                  if (!mounted) return;
                  await showDialog<void>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Triage simulation'),
                      content: Text(actions.isEmpty ? 'No rules matched' : 'Would apply: ${actions.map((e) => e.name).join(', ')}'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
                      ],
                    ),
                  );
                },
              ),

              // Run Macro option
              ListTile(
                leading: const Icon(Icons.playlist_add_check),
                title: const Text('Run macro…'),
                onTap: () async {
                  final selected = _selected.toList();
                  final macros = await _incidentSvc.listMacros();
                  if (!mounted) return;
                  final chosen = await showModalBottomSheet<AdminMacro>(
                    context: context, showDragHandle: true,
                    builder: (c)=> SafeArea(
                      child: ListView(
                        children: [
                          const ListTile(title: Text('Choose a macro')),
                          ...macros.map((m)=> ListTile(
                            leading: const Icon(Icons.bolt),
                            title: Text(m.name),
                            subtitle: Text(m.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: ()=> Navigator.of(c).pop(m),
                          )),
                        ],
                      ),
                    ),
                  );
                  if (chosen == null) return;
                  if (!mounted) return;

                  // Collect variables present in body
                  final vars = <String>{};
                  final re = RegExp(r'\{\{([a-zA-Z0-9_]+)\}\}');
                  for (final m in re.allMatches(chosen.body)) { vars.add(m.group(1)!); }

                  final values = <String,String>{};
                  for (final v in vars) {
                    final ctrl = TextEditingController();
                    final res = await showDialog<String>(
                      context: context,
                      builder: (c)=> AlertDialog(
                        title: Text('Set "$v"'),
                        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: v)),
                        actions: [
                          TextButton(onPressed: ()=> Navigator.of(c).pop(), child: const Text('Cancel')),
                          FilledButton(onPressed: ()=> Navigator.of(c).pop(ctrl.text), child: const Text('OK')),
                        ],
                      ),
                    );
                    if (res == null) return; // canceled
                    values[v] = res;
                  }

                  final preview = _incidentSvc.applyMacro(chosen, values);
                  if (!mounted) return;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c)=> AlertDialog(
                      title: const Text('Preview'),
                      content: SingleChildScrollView(child: Text(preview)),
                      actions: [
                        TextButton(onPressed: ()=> Navigator.of(c).pop(false), child: const Text('Back')),
                        FilledButton(onPressed: ()=> Navigator.of(c).pop(true), child: Text('Send to ${selected.length}')),
                      ],
                    ),
                  );
                  if (confirm != true) return;

                  await _incidentSvc.bulkApply(ticketIds: selected, reply: {'name': 'Macro: ${chosen.name}', 'content': preview});
                  if (!mounted) return;
                  Navigator.of(context).pop(); // close bulk sheet
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Macro "${chosen.name}" applied to ${selected.length} tickets')));
                },
              ),

              // Escalate selected option
              ListTile(
                leading: const Icon(Icons.upgrade),
                title: const Text('Escalate selected (T2)'),
                onTap: () async {
                  final ids = _selected.toList();
                  for (final id in ids) {
                    await _incidentSvc.escalate(id);
                  }
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Escalated ${ids.length} tickets'))
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- AI Assist helper method ----
  Future<void> _openAiAssist(TicketSummary t) async {
    final hintCtrl = TextEditingController();
    final suggestion = await _incidentSvc.suggestReply(t.id);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      builder: (c){
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('AI Assist for #${t.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: hintCtrl,
                  decoration: const InputDecoration(labelText: 'Optional hint to refine'),
                ),
                const SizedBox(height: 12),
                const Text('Suggested reply:'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(suggestion),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final refined = await _incidentSvc.suggestReply(t.id, hint: hintCtrl.text.trim());
                        if (!mounted) return;
                        // naive update – reopen with refined text
                        Navigator.of(c).pop();
                        await _openAiAssist(t);
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Refine'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () async {
                        // send as note
                        await _incidentSvc.addEvent(IncidentEvent(
                          id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
                          ticketId: t.id,
                          kind: IncidentKind.note,
                          title: 'AI reply',
                          details: suggestion,
                          at: DateTime.now(),
                          by: 'admin',
                        ));
                        if (!mounted) return;
                        Navigator.of(c).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI suggestion added as note')));
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Insert'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// KeepAlive wrapper for list items
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive(this.child);
  @override _KeepAliveState createState()=> _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive=> true;
  @override Widget build(BuildContext c){
    super.build(c);
    return widget.child;
  }
}

class _TicketDetailSheet extends StatefulWidget {
  final TicketSummary ticket;
  final AdminIncidentService svc;
  const _TicketDetailSheet({required this.ticket, required this.svc});

  @override
  State<_TicketDetailSheet> createState() => _TicketDetailSheetState();
}

class _TicketDetailSheetState extends State<_TicketDetailSheet> {
  final _kb = AdminKnowledgeService.instance;
  List<KbSuggestion> _sugs = const [];
  final _reply = TextEditingController();
  bool _internal = false;
  List<IncidentEvent> _events = const [];
  PlaybookRun? _playbookRun;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final events = await widget.svc.getEvents(widget.ticket.id);
    final playbookRun = await widget.svc.getPlaybookRun(widget.ticket.id);
    final sg = await _kb.suggestForTicket(widget.ticket);
    if (!mounted) return;
    setState(() {
      _events = events;
      _playbookRun = playbookRun;
      _sugs = sg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              widget.ticket.subject,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Profile Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User Profile', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('Name: ${widget.ticket.requesterName}'),
                            Text('ID: ${widget.ticket.id}'),
                            Text('Created: ${widget.ticket.createdAt}'),
                            Text('Status: ${widget.ticket.status.name}'),
                            Text('Priority: ${widget.ticket.priority.name}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick Actions
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await widget.svc.addEvent(IncidentEvent(
                                      id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
                                      ticketId: widget.ticket.id,
                                      kind: IncidentKind.note,
                                      title: 'Resolved',
                                      details: 'Ticket resolved by admin',
                                      at: DateTime.now(),
                                      by: 'admin',
                                    ));
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Resolve'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await widget.svc.addEvent(IncidentEvent(
                                      id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
                                      ticketId: widget.ticket.id,
                                      kind: IncidentKind.note,
                                      title: 'Blocked',
                                      details: 'Ticket blocked - waiting for user',
                                      at: DateTime.now(),
                                      by: 'admin',
                                    ));
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.block),
                                  label: const Text('Block'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await widget.svc.escalate(widget.ticket.id);
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.upgrade),
                                  label: const Text('Escalate'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Timeline
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            if (_events.isEmpty)
                              const Text('No events yet')
                            else
                              ..._events.map((e) => ListTile(
                                leading: Icon(_getEventIcon(e.kind)),
                                title: Text(e.title),
                                subtitle: Text('${e.at} • ${e.by}'),
                                trailing: Text(e.details, maxLines: 2, overflow: TextOverflow.ellipsis),
                              )),
                          ],
                        ),
                      ),
                    ),

                    // Playbook Progress (if active)
                    if (_playbookRun != null) ...[
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Playbook Progress', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              ..._playbookRun!.done.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final done = entry.value;
                                return CheckboxListTile(
                                  title: Text('Step ${idx + 1}'),
                                  value: done,
                                  onChanged: (v) async {
                                    if (v != null) {
                                      await widget.svc.toggleStep(_playbookRun!.id, idx);
                                      if (!mounted) return;
                                      setState(() {});
                                    }
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(IncidentKind kind) {
    switch (kind) {
      case IncidentKind.note: return Icons.note;
      case IncidentKind.auth: return Icons.security;
      case IncidentKind.network: return Icons.wifi;
      case IncidentKind.system: return Icons.computer;
      case IncidentKind.push: return Icons.notifications;
      case IncidentKind.deeplink: return Icons.link;
      case IncidentKind.banner: return Icons.campaign;
      default: return Icons.info;
    }
  }
}