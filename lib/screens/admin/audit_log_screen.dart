import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../../services/config/feature_flags.dart';
import '../../services/admin/safety_layer_service.dart';
import '../../models/admin/admin_models.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _logs = [];
  List<SafetyLayerAudit> _safetyLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _fetchSafetyLogs();
  }

  Future<void> _fetchSafetyLogs() async {
    try {
      final isEnabled = await FeatureFlags.instance.isEnabled(FeatureFlags.adminSafetyLayer);
      if (!isEnabled) return;

      final logs = await SafetyLayerService.I.getRecentAuditLogs(limit: 10);
      setState(() {
        _safetyLogs = logs;
      });
    } catch (e) {
      debugPrint('Failed to fetch safety logs: $e');
    }
  }

  Future<void> _fetchLogs() async {
    final response = await supabase
        .from('admin_audit_log')
        .select('*, actor:profiles!admin_audit_log_actor_id_fkey(id, email, name)')
        .order('created_at', ascending: false);

    setState(() {
      _logs = response;
      _loading = false;
    });
  }

  Future<void> _exportLogsToCSV() async {
    final headers = ['Actor', 'Action', 'Target', 'Time'];
    final rows = _logs.map((log) {
      return [
        log['actor']['name'] ?? log['actor']['email'] ?? '',
        log['action'] ?? '',
        log['target'] ?? '',
        log['created_at'] ?? ''
      ];
    }).toList();

    final csv = const ListToCsvConverter().convert([headers, ...rows]);
    final directory = await getDownloadsDirectory();
    final file = File('${directory!.path}/vagus_audit_logs.csv');
    await file.writeAsString(csv);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Logs exported to ${file.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧾 Admin Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export as CSV',
            onPressed: _loading ? null : _exportLogsToCSV,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ✅ VAGUS ADD: final-safety-layer START
                FutureBuilder<bool>(
                  future: FeatureFlags.instance.isEnabled(FeatureFlags.adminSafetyLayer),
                  builder: (context, flagSnapshot) {
                    if (!(flagSnapshot.data ?? false)) return const SizedBox.shrink();
                    if (_safetyLogs.isEmpty) return const SizedBox.shrink();

                    return Card(
                      color: Colors.orange.shade50,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.shield, color: Colors.orange),
                                SizedBox(width: 8),
                                Text(
                                  'Safety Layer Triggers (Last 10)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._safetyLogs.take(10).map((log) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        log.result == SafetyAuditResult.blocked
                                            ? Icons.block
                                            : log.result == SafetyAuditResult.requiresApproval
                                                ? Icons.warning
                                                : Icons.check_circle,
                                        size: 16,
                                        color: log.result == SafetyAuditResult.blocked
                                            ? Colors.red
                                            : log.result == SafetyAuditResult.requiresApproval
                                                ? Colors.orange
                                                : Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              log.action,
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              log.reason ?? 'No reason',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // ✅ VAGUS ADD: final-safety-layer END

                if (_logs.isEmpty)
                  const Center(child: Text('No audit logs found.'))
                else
                  ...List.generate(_logs.length, (index) {
                    final log = _logs[index];
                    final actor = log['actor'] as Map<String, dynamic>? ?? {};
                    final actorName = actor['name'] ?? actor['email'] ?? 'Unknown';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(
                          actorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Action: ${log['action']}"),
                            if (log['target'] != null) Text("Target: ${log['target']}"),
                            Text("At: ${log['created_at']}"),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
