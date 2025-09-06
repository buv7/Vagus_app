// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'support/support_inbox_screen.dart';
import 'support/widgets/sla_policies_editor.dart';
import 'coach_approval_panel.dart';
import 'user_manager_panel.dart';
import 'admin_analytics_screen.dart';
import 'admin_ops_screen.dart';
import 'admin_sla_policies_screen.dart';
import 'audit_log_screen.dart';
import '../../widgets/admin/admin_command_palette.dart';
import '../../services/admin/admin_support_service.dart';

class AdminHubScreen extends StatefulWidget {
  const AdminHubScreen({super.key});
  @override State<AdminHubScreen> createState() => _AdminHubScreenState();
}

class _AdminHubScreenState extends State<AdminHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Map<String, int>? _counts;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 7, vsync: this);
    _loadCounts();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCounts(); // refresh when screen re-enters
  }

  Future<void> _loadCounts() async {
    final svc = AdminSupportService.instance;
    final c = await svc.counts();
    if (!mounted) return;
    setState(() => _counts = c);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Hub'),
        actions: [
          if (_tab.index == 1) // Support tab
            PopupMenuButton<String>(
              tooltip: 'Support tools',
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'sla_policies') {
                  _openSlaPoliciesEditor(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'sla_policies',
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 18),
                      SizedBox(width: 8),
                      Text('SLA Policies'),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: [
            const Tab(icon: Icon(Icons.people_alt), text: 'Users'),
            Tab(
              icon: Stack(children: [
                const Icon(Icons.mail_outline),
                if ((_counts?['urgent_open'] ?? 0) > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_counts?['urgent_open'] ?? 0}',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ]),
              text: 'Support',
            ),
            const Tab(icon: Icon(Icons.verified_user), text: 'Approvals'),
            const Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
            const Tab(icon: Icon(Icons.dashboard), text: 'Live Ops'),
            const Tab(icon: Icon(Icons.policy), text: 'SLA Policies'),
            const Tab(icon: Icon(Icons.article_outlined), text: 'Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          UserManagerPanel(),
          SupportInboxScreen(),
          CoachApprovalPanel(),
          AdminAnalyticsScreen(),
          AdminOpsScreen(),
          AdminSlaPoliciesScreen(),
          AuditLogScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCommandPalette(context),
        child: const Icon(Icons.search),
      ),
    );
  }

  void _openCommandPalette(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AdminCommandPalette(),
    );
  }

  void _openSlaPoliciesEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SlaPoliciesEditor(),
    );
  }
}
