import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import 'audit_log_screen.dart';
import 'admin_analytics_screen.dart';
import 'ai_config_panel.dart';
import 'user_manager_panel.dart';
import 'coach_approval_panel.dart';
import 'global_settings_panel.dart';
import '../auth/login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];

  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final response = await supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: false);

    setState(() {
      _allUsers = response;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase();

    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['name'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        final role = (user['role'] ?? '').toLowerCase();

        final matchesSearch = name.contains(query) || email.contains(query);
        final matchesRole = _roleFilter == 'all' || role == _roleFilter;

        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  Future<void> _changeRole(String userId, String newRole) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    final targetUser = _allUsers.firstWhere((u) => u['id'] == userId);
    final oldRole = targetUser['role'];

    await supabase.from('profiles').update({'role': newRole}).eq('id', userId);

    await supabase.from('audit_logs').insert({
      'action': 'role_change',
      'target_user_id': userId,
      'old_role': oldRole,
      'new_role': newRole,
      'changed_by': currentUser.id,
    });

    unawaited(_fetchUsers());
  }

  Future<void> _toggleDisabled(String userId, bool isDisabled) async {
    await supabase
        .from('profiles')
        .update({'is_disabled': isDisabled})
        .eq('id', userId);

    unawaited(_fetchUsers());
  }

  Future<void> _exportToCSV() async {
    final headers = ['Name', 'Email', 'Role', 'Created At', 'Disabled'];
    final rows = _allUsers.map((user) {
      return [
        user['name'] ?? '',
        user['email'] ?? '',
        user['role'] ?? '',
        user['created_at'] ?? '',
        user['is_disabled'] == true ? 'Yes' : 'No'
      ];
    }).toList();

    final csv = const ListToCsvConverter().convert([headers, ...rows]);

    final directory = await getDownloadsDirectory();
    final file = File('${directory!.path}/vagus_users.csv');
    await file.writeAsString(csv);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Exported to ${file.path}')),
      );
    }
  }

  void _goToAuditLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuditLogScreen()),
    );
  }

  void _goToCoachApprovals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoachApprovalPanel()),
    );
  }

  void _goToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
    );
  }

  void _goToUserManager() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserManagerPanel()),
    );
  }

  void _goToAIConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIConfigPanel()),
    );
  }

  void _goToGlobalSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GlobalSettingsPanel()),
    );
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    // ignore: unawaited_futures
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Widget _buildRoleTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['all', 'client', 'coach', 'admin'].map((role) {
        final isSelected = _roleFilter == role;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(role.toUpperCase()),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _roleFilter = role;
                _applyFilters();
              });
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠️ Admin: User Roles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'User Manager',
            onPressed: _goToUserManager,
          ),
          IconButton(
            icon: const Icon(Icons.verified_user),
            tooltip: 'Coach Approvals',
            onPressed: _goToCoachApprovals,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Analytics',
            onPressed: _goToAnalytics,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Audit Logs',
            onPressed: _goToAuditLogs,
          ),
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI Configuration',
            onPressed: _goToAIConfig,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Global Settings',
            onPressed: _goToGlobalSettings,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Users',
            onPressed: _loading ? null : _exportToCSV,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => unawaited(_logout()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name or email',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
            ),
          ),
          _buildRoleTabs(),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredUsers.isEmpty
                ? const Center(child: Text('No users found.'))
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredUsers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                final isDisabled = user['is_disabled'] == true;
                return Opacity(
                  opacity: isDisabled ? 0.5 : 1.0,
                  child: ListTile(
                    leading: isDisabled
                        ? const Icon(Icons.block, color: Colors.red)
                        : const Icon(Icons.person),
                    title: Text(user['name'] ?? 'No name'),
                    subtitle: Text(
                        "${user['email']} • ${user['role']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<String>(
                          value: user['role'],
                          items: const [
                            DropdownMenuItem(
                                value: 'client', child: Text('Client')),
                            DropdownMenuItem(
                                value: 'coach', child: Text('Coach')),
                            DropdownMenuItem(
                                value: 'admin', child: Text('Admin')),
                          ],
                          onChanged: (value) {
                            if (value != null &&
                                value != user['role']) {
                              _changeRole(user['id'], value);
                            }
                          },
                        ),
                        Switch(
                          value: !isDisabled,
                          onChanged: (val) =>
                              _toggleDisabled(user['id'], !val),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
