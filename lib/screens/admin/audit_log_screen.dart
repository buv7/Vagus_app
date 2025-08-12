import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    final response = await supabase
        .from('audit_logs')
        .select('*, changed_by:profiles!audit_logs_changed_by_fkey(name), target:profiles!audit_logs_target_user_id_fkey(name)')
        .order('timestamp', ascending: false);

    setState(() {
      _logs = response;
      _loading = false;
    });
  }

  Future<void> _exportLogsToCSV() async {
    final headers = ['Changed By', 'Target User', 'Old Role', 'New Role', 'Time'];
    final rows = _logs.map((log) {
      return [
        log['changed_by']['name'] ?? '',
        log['target']['name'] ?? '',
        log['old_role'] ?? '',
        log['new_role'] ?? '',
        log['timestamp'] ?? ''
      ];
    }).toList();

    final csv = const ListToCsvConverter().convert([headers, ...rows]);
    final directory = await getDownloadsDirectory();
    final file = File('${directory!.path}/vagus_audit_logs.csv');
    await file.writeAsString(csv);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Logs exported to ${file.path}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🧾 Admin Audit Logs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Export as CSV",
            onPressed: _loading ? null : _exportLogsToCSV,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(child: Text("No audit logs found."))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final log = _logs[index];
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(
              "${log['changed_by']['name']} ➡ ${log['target']['name']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Role: ${log['old_role']} → ${log['new_role']}\nAt: ${log['timestamp']}",
            ),
          );
        },
      ),
    );
  }
}
