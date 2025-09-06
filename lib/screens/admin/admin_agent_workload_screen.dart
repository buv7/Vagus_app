// ignore_for_file: file_names
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/admin/admin_support_service.dart';

class AdminAgentWorkloadScreen extends StatefulWidget {
  const AdminAgentWorkloadScreen({super.key});
  @override
  State<AdminAgentWorkloadScreen> createState() => _AdminAgentWorkloadScreenState();
}

class _AdminAgentWorkloadScreenState extends State<AdminAgentWorkloadScreen> {
  final _svc = AdminSupportService.instance;
  List<AgentWorkload> _agents = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final list = await _svc.listAgentWorkload();
    if (!mounted) return;
    setState(()=> _agents = list);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'online': return Colors.green;
      case 'busy': return Colors.orange;
      case 'away': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Workload'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> unawaited(_load())),
      ]),
      body: ListView.separated(
        itemCount: _agents.length,
        separatorBuilder: (_, __)=> const Divider(height: 1),
        itemBuilder: (_, i) {
          final a = _agents[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _statusColor(a.status).withValues(alpha:.12),
              child: Icon(Icons.support_agent, color: _statusColor(a.status)),
            ),
            title: Text('${a.displayName} • ${(a.occupancy*100).toStringAsFixed(0)}%'),
            subtitle: Text('Active ${a.activeTickets} • Waiting ${a.waitingReplies}'),
            trailing: PopupMenuButton<String>(
              onSelected: (s) async {
                await _svc.setAgentStatus(a.agentId, s);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status set to $s')));
                unawaited(_load());
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value:'online', child: Text('Online')),
                PopupMenuItem(value:'busy', child: Text('Busy')),
                PopupMenuItem(value:'away', child: Text('Away')),
                PopupMenuItem(value:'offline', child: Text('Offline')),
              ],
            ),
          );
        },
      ),
    );
  }
}
