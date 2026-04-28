import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vagus_app/models/sheetify/sheet_sync_models.dart';
import 'package:vagus_app/services/sheetify/sheetify_service.dart';

/// Screen showing all unresolved sync conflicts for the coach.
/// App is source of truth — coach can keep app value or accept the sheet edit.
class SheetifyConflictsScreen extends StatefulWidget {
  const SheetifyConflictsScreen({super.key});

  @override
  State<SheetifyConflictsScreen> createState() => _SheetifyConflictsScreenState();
}

class _SheetifyConflictsScreenState extends State<SheetifyConflictsScreen> {
  final _service = SheetifyService.instance;
  final _sb = Supabase.instance.client;

  List<SyncConflict> _conflicts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final coachId = _sb.auth.currentUser?.id;
    if (coachId == null) return;
    setState(() => _loading = true);
    try {
      final conflicts = await _service.getConflicts(coachId);
      if (mounted) setState(() => _conflicts = conflicts);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _keepApp(SyncConflict conflict) async {
    await _service.keepAppValue(conflict.id);
    await _load();
  }

  Future<void> _keepSheet(SyncConflict conflict) async {
    await _service.keepSheetValue(conflict.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Conflicts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conflicts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                      SizedBox(height: 8),
                      Text('No conflicts — all clear'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conflicts.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) => _ConflictCard(
                      conflict: _conflicts[i],
                      onKeepApp: () => _keepApp(_conflicts[i]),
                      onKeepSheet: () => _keepSheet(_conflicts[i]),
                    ),
                  ),
                ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  final SyncConflict conflict;
  final VoidCallback onKeepApp;
  final VoidCallback onKeepSheet;

  const _ConflictCard({
    required this.conflict,
    required this.onKeepApp,
    required this.onKeepSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync_problem, color: Colors.orange, size: 18),
                const SizedBox(width: 6),
                Text(
                  conflict.tab.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  _formatDate(conflict.detectedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ValueRow(label: 'App (source of truth)', value: conflict.localValue),
            const SizedBox(height: 4),
            _ValueRow(label: 'Sheet edit', value: conflict.sheetValue),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onKeepApp,
                    child: const Text('Keep app value'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onKeepSheet,
                    child: const Text('Accept sheet edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final Map<String, dynamic> value;

  const _ValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final display = value.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) => '${e.key}: ${e.value}')
        .join('  ·  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(display.isEmpty ? '(empty)' : display, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
