import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vagus_app/models/sheetify/sheet_sync_models.dart';
import 'package:vagus_app/services/sheetify/sheetify_service.dart';

/// Screen where a coach can connect or disconnect Google Drive for Sheets sync.
///
/// Shows:
///  - Connection status (email if connected)
///  - List of client sheets with open-in-Drive links
///  - Unresolved conflict count with a "Review" button
///  - Connect / Disconnect button
class SheetifyConnectScreen extends StatefulWidget {
  const SheetifyConnectScreen({super.key});

  @override
  State<SheetifyConnectScreen> createState() => _SheetifyConnectScreenState();
}

class _SheetifyConnectScreenState extends State<SheetifyConnectScreen> {
  final _service = SheetifyService.instance;
  final _sb = Supabase.instance.client;

  bool _loading = true;
  bool _connected = false;
  String? _googleEmail;
  List<Map<String, dynamic>> _sheets = [];
  int _conflictCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _service.syncStateStream.listen(_onSyncState);
  }

  void _onSyncState(SheetSyncState state) {
    if (!mounted) return;
    setState(() => _conflictCount = state.pendingConflicts);
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final status = await _service.getConnectionStatus();
      if (!mounted) return;
      setState(() {
        _connected = status['connected'] as bool? ?? false;
        _googleEmail = status['email'] as String?;
        _sheets = List<Map<String, dynamic>>.from(
          (status['sheets'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
        );
        _error = null;
      });

      // Count unresolved conflicts
      final coachId = _sb.auth.currentUser?.id;
      if (coachId != null && _connected) {
        final conflicts = await _service.getConflicts(coachId);
        if (mounted) setState(() => _conflictCount = conflicts.length);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connectGoogle() async {
    final coachId = _sb.auth.currentUser?.id;
    if (coachId == null) return;
    try {
      await _service.connectGoogle(coachId);
      // UI updates via handleOAuthCallback deep link; refresh after a short delay
      await Future.delayed(const Duration(seconds: 2));
      await _loadStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    final coachId = _sb.auth.currentUser?.id;
    if (coachId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Google Drive?'),
        content: const Text(
          'Your sheets will remain in Google Drive. '
          'Check-in, workout, and nutrition logs will no longer sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.disconnectGoogle(coachId);
      await _loadStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disconnect failed: $e')),
        );
      }
    }
  }

  Future<void> _openSheet(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sheets Sync'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ConnectionCard(
                    connected: _connected,
                    email: _googleEmail,
                    onConnect: _connectGoogle,
                    onDisconnect: _disconnect,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: _error!),
                  ],
                  if (_connected && _conflictCount > 0) ...[
                    const SizedBox(height: 16),
                    _ConflictBanner(
                      count: _conflictCount,
                      onReview: () => Navigator.pushNamed(
                        context,
                        '/sheetify/conflicts',
                      ),
                    ),
                  ],
                  if (_connected && _sheets.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Client Sheets',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._sheets.map((sheet) => _SheetTile(
                          sheet: sheet,
                          onOpen: () => _openSheet(sheet['sheet_url'] as String),
                        )),
                  ],
                  const SizedBox(height: 32),
                  _SchemaDocs(),
                ],
              ),
            ),
    );
  }
}

// ============================================================================
// Sub-widgets
// ============================================================================

class _ConnectionCard extends StatelessWidget {
  final bool connected;
  final String? email;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _ConnectionCard({
    required this.connected,
    this.email,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  color: connected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  connected ? 'Connected' : 'Not connected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: connected ? Colors.green : Colors.grey,
                      ),
                ),
              ],
            ),
            if (email != null) ...[
              const SizedBox(height: 4),
              Text(email!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            if (!connected)
              ElevatedButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.add_link),
                label: const Text('Connect Google Drive'),
              )
            else
              OutlinedButton.icon(
                onPressed: onDisconnect,
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  final int count;
  final VoidCallback onReview;

  const _ConflictBanner({required this.count, required this.onReview});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: ListTile(
        leading: const Icon(Icons.warning_amber, color: Colors.orange),
        title: Text(
          '$count sync ${count == 1 ? 'conflict' : 'conflicts'} need review',
        ),
        subtitle: const Text('Sheet edits differ from app data'),
        trailing: TextButton(
          onPressed: onReview,
          child: const Text('Review'),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final Map<String, dynamic> sheet;
  final VoidCallback onOpen;

  const _SheetTile({required this.sheet, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final lastSync = sheet['last_synced_at'] as String?;
    final subtitle = lastSync != null
        ? 'Last synced ${_formatDate(lastSync)}'
        : 'Not yet synced';

    return ListTile(
      leading: const Icon(Icons.table_chart_outlined),
      title: Text(sheet['client_id'] as String? ?? 'Unknown client',
          overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle),
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new),
        tooltip: 'Open in Drive',
        onPressed: onOpen,
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.red),
        title: Text(message, style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

/// Read-only documentation of the sheet tab schema for coaches.
class _SchemaDocs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Sheet schema'),
      children: [
        _SchemaSection(
          title: 'Check-ins',
          columns: const [
            'Date',
            'Weight (kg)',
            'Body Fat %',
            'Mood',
            'Notes',
            'Photo URLs',
          ],
        ),
        _SchemaSection(
          title: 'Workout',
          columns: const [
            'Date',
            'Exercise',
            'Sets',
            'Reps',
            'Weight (kg)',
            'RPE',
            'Notes',
          ],
        ),
        _SchemaSection(
          title: 'Nutrition',
          columns: const [
            'Date',
            'Meal',
            'Food',
            'Calories',
            'Protein (g)',
            'Carbs (g)',
            'Fat (g)',
          ],
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'App data is always the source of truth. '
            'If you edit a sheet directly, a conflict will be flagged for your review.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class _SchemaSection extends StatelessWidget {
  final String title;
  final List<String> columns;

  const _SchemaSection({required this.title, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: columns
                .map((c) => Chip(
                      label: Text(c, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
