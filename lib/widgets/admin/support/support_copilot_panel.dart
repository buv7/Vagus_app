import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/admin/admin_support_service.dart';

typedef InsertTextCallback = void Function(String text);
typedef ApplyActionCallback = Future<bool> Function(String action, Map<String, dynamic> args);

class SupportCopilotPanel extends StatefulWidget {
  final String ticketId;
  final String userId;
  final InsertTextCallback onInsertText;
  final ApplyActionCallback onApplyAction;

  const SupportCopilotPanel({
    super.key,
    required this.ticketId,
    required this.userId,
    required this.onInsertText,
    required this.onApplyAction,
  });

  @override
  State<SupportCopilotPanel> createState() => _SupportCopilotPanelState();
}

class _SupportCopilotPanelState extends State<SupportCopilotPanel>
    with SingleTickerProviderStateMixin {
  final _svc = AdminSupportService.instance;
  final _search = TextEditingController();
  List<Map<String, dynamic>> _canned = const [];
  bool _loadingCanned = true;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    unawaited(_loadCanned());
  }

  Future<void> _loadCanned() async {
    final r = await _svc.listCannedRepliesRaw();
    if (!mounted) return;
    setState(() {
      _canned = r;
      _loadingCanned = false;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0;
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Co-Pilot',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            labelColor: Colors.black,
            tabs: const [
              Tab(icon: Icon(Icons.person_outline), text: 'Context'),
              Tab(icon: Icon(Icons.message_outlined), text: 'Replies'),
              Tab(icon: Icon(Icons.build_outlined), text: 'Actions'),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildContext(),
                  _buildReplies(),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContext() {
    // Lightweight summary – pull what you already have; fallback placeholders
    return ListView(
      children: [
        _kv('Ticket', widget.ticketId),
        _kv('User', widget.userId),
        const Divider(),
        const Text('Signals', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _pill('New customer', Colors.blue),
            _pill('Mobile • Android', Colors.green),
            _pill('Pro trial', Colors.deepPurple),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Recent activity', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...[
          'Login • 2h ago',
          'Completed intake • 1d ago',
          'Upgraded to Pro • 3d ago',
        ].map((e) => ListTile(leading: const Icon(Icons.history), title: Text(e))),
      ],
    );
  }

  Widget _buildReplies() {
    final filtered = _search.text.trim().isEmpty
        ? _canned
        : _canned.where((e) =>
            (e['title'] ?? '').toString().toLowerCase().contains(_search.text.toLowerCase()) ||
            (e['body'] ?? '').toString().toLowerCase().contains(_search.text.toLowerCase())).toList();

    return Column(
      children: [
        TextField(
          controller: _search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search canned replies…',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loadingCanned
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = filtered[i];
                    return Card(
                      child: ListTile(
                        title: Text(
                          r['title'] ?? '(untitled)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          (r['body'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.input),
                          tooltip: 'Insert into reply',
                          onPressed: () => widget.onInsertText((r['body'] ?? '').toString()),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return ListView(
      children: [
        const Text('Quick actions', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _actionChip('Set priority: urgent', Icons.priority_high,
                () => widget.onApplyAction('set_priority', {'priority': 'urgent'})),
            _actionChip('Add tag: billing', Icons.local_offer_outlined,
                () => widget.onApplyAction('add_tag', {'tag': 'billing'})),
            _actionChip('Escalate', Icons.trending_up,
                () => widget.onApplyAction('escalate', const {})),
            _actionChip('Request logs', Icons.description_outlined,
                () => widget.onApplyAction('request_logs', const {})),
          ],
        ),
        const Divider(height: 24),
        const Text('Macros', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.auto_fix_high_outlined),
          title: const Text('Apologize + SLA explain + link to help'),
          onTap: () => widget.onInsertText(
              'Sorry about the trouble! Our SLA for your priority is … Here\'s a guide: https://…'),
        ),
        ListTile(
          leading: const Icon(Icons.auto_fix_high_outlined),
          title: const Text('Collect diagnostics template'),
          onTap: () => widget.onInsertText(
              'Could you share steps to reproduce, screenshots, and your app version (Settings → About)?'),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(k, style: TextStyle(color: Colors.black.withValues(alpha: .6))),
            ),
            Expanded(child: Text(v)),
          ],
        ),
      );

  Widget _pill(String label, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: .25)),
        ),
        child: Text(label),
      );

  Widget _actionChip(String label, IconData icon, Future<bool> Function() run) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () async {
        final ok = await run();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Done' : 'Failed')),
        );
      },
    );
  }
}
