
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../../widgets/branding/vagus_appbar.dart';

import 'audit_log_screen.dart';
import 'admin_analytics_screen.dart';
import 'ai_config_panel.dart';
import 'user_manager_panel.dart';
import 'coach_approval_panel.dart';
import 'global_settings_panel.dart';
import '../auth/login_screen.dart';
import '../messaging/admin_support_chat_screen.dart';
import 'admin_hub_screen.dart';
import 'price_editor_screen.dart';
import 'nutrition_diagnostics_screen.dart';
import '../../services/notifications/notification_helper.dart';
import '../../services/navigation/app_navigator.dart';

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

  int _totalSupportRequests = 0;
  int _urgentSupportCount = 0;
  int _needsAttentionCount = 0;
  
  // Track which users need support
  Map<String, Map<String, dynamic>> _userSupportStatus = {};

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchSupportSummary();
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

  Future<void> _fetchSupportSummary() async {
    try {
      // Get support threads for admins (including current user)
      final supportThreads = await supabase
          .from('message_threads')
          .select('client_id, last_message_at')
          .order('last_message_at', ascending: false);

      debugPrint('🔍 Found ${supportThreads.length} support threads');
      
      int urgentCount = 0;
      int attentionCount = 0;
      Map<String, Map<String, dynamic>> userSupportStatus = {};
      
      for (final thread in supportThreads) {
        final clientId = thread['client_id'] as String;
        final lastMessageAt = thread['last_message_at'] as String?;
        
        if (lastMessageAt != null) {
          final lastMessageTime = DateTime.tryParse(lastMessageAt);
          if (lastMessageTime != null) {
            final timeSinceLastMessage = DateTime.now().difference(lastMessageTime);
            
            String urgency = 'recent';
            if (timeSinceLastMessage.inHours < 1) {
              urgency = 'urgent';
              urgentCount++;
            } else if (timeSinceLastMessage.inHours < 6) {
              urgency = 'attention';
              attentionCount++;
            }
            
            userSupportStatus[clientId] = {
              'urgency': urgency,
              'lastMessageAt': lastMessageAt,
              'timeSinceLastMessage': timeSinceLastMessage,
              'unreadCount': 1, // For now, assume 1 unread per thread
            };
          }
        }
      }

      debugPrint('🚨 Urgent: $urgentCount, ⚠️ Needs attention: $attentionCount');
      debugPrint('👥 Users needing support: ${userSupportStatus.keys.toList()}');
      
      setState(() {
        _totalSupportRequests = supportThreads.length;
        _urgentSupportCount = urgentCount;
        _needsAttentionCount = attentionCount;
        _userSupportStatus = userSupportStatus;
      });
    } catch (e) {
      debugPrint('❌ Error fetching support notifications: $e');
    }
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

  void _openSupportInbox() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminHubScreen()),
    );
  }

  void _openChatWithUser(Map<String, dynamic> user) async {
    // Try to send notification to the user that an admin wants to chat with them
    try {
      // ignore: unawaited_futures
      unawaited(NotificationHelper.instance.sendToUser(
        userId: user['id'],
        title: '💬 Admin Support',
        message: 'An admin wants to chat with you. Tap to open the conversation.',
        route: '/support/chat',
        screen: 'AdminSupportChatScreen',
        additionalData: {
          'type': 'admin_initiated_chat',
          'adminId': supabase.auth.currentUser?.id,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ).catchError((e) {
        // Don't block the chat opening if notification fails
        debugPrint('Failed to send notification: $e');
        return false; // Return a value to satisfy the analyzer
      }));
    } catch (e) {
      // If notification helper fails completely, just log it and continue
      debugPrint('Notification helper not available: $e');
      
      // Show a local snackbar instead
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💬 Opening chat with ${user['name'] ?? 'user'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    if (!mounted) return;
    
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminSupportChatScreen(clientId: user['id']),
      ),
    ));
  }

  void _goToUserManager() {
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserManagerPanel()),
    ));
  }

  void _goToAIConfig() {
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIConfigPanel()),
    ));
  }

  void _goToGlobalSettings() {
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GlobalSettingsPanel()),
    ));
  }

  void _goToPriceEditor() {
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PriceEditorScreen()),
    ));
  }

  void _goToNutritionDiagnostics() {
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NutritionDiagnosticsScreen()),
    ));
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

  String _formatTimeAgo(Duration? duration) {
    if (duration == null) return 'unknown';
    
    if (duration.inMinutes < 1) {
      return 'just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    } else {
      return '${duration.inDays}d ago';
    }
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

  Widget _buildSupportSummary() {
    if (_totalSupportRequests == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Support Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_urgentSupportCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_urgentSupportCount urgent',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_needsAttentionCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_needsAttentionCount needs attention',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_totalSupportRequests > _urgentSupportCount + _needsAttentionCount) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_totalSupportRequests - _urgentSupportCount - _needsAttentionCount} recent',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchSupportSummary();
              _fetchUsers();
            },
            tooltip: 'Refresh support status',
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    final isDisabled = user['is_disabled'] == true;
    final userId = user['id'] as String;
    final userNeedsSupport = _userSupportStatus.containsKey(userId);
    final supportStatus = _userSupportStatus[userId];
    
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: ListTile(
        leading: Stack(
          children: [
            if (isDisabled)
              const Icon(Icons.block, color: Colors.red)
            else
              const Icon(Icons.person),
            // Support status indicator
            if (userNeedsSupport && !isDisabled)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: supportStatus?['urgency'] == 'urgent' 
                        ? Colors.red 
                        : supportStatus?['urgency'] == 'attention' 
                            ? Colors.orange 
                            : Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Icon(
                    supportStatus?['urgency'] == 'urgent' 
                        ? Icons.priority_high 
                        : Icons.support_agent,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      user['name'] ?? 'No name',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (userNeedsSupport && !isDisabled) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: supportStatus?['urgency'] == 'urgent' 
                            ? Colors.red 
                            : supportStatus?['urgency'] == 'attention' 
                                ? Colors.orange 
                                : Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        supportStatus?['urgency'] == 'urgent' 
                            ? 'SOS' 
                            : supportStatus?['urgency'] == 'attention' 
                                ? 'HELP' 
                                : 'NEW',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isDisabled) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.support_agent,
                  color: Colors.blue,
                  size: 20,
                ),
                tooltip: userNeedsSupport 
                    ? '${supportStatus?['urgency'] == 'urgent' ? 'URGENT' : 'Needs attention'} - Chat with user' 
                    : 'Chat with user',
                onPressed: () => _openChatWithUser(user),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${user['email']} • ${user['role']}"),
            if (userNeedsSupport && !isDisabled) ...[
              const SizedBox(height: 2),
              Text(
                supportStatus?['urgency'] == 'urgent' 
                    ? '🚨 URGENT: ${_formatTimeAgo(supportStatus?['timeSinceLastMessage'])}' 
                    : supportStatus?['urgency'] == 'attention' 
                        ? '⚠️ NEEDS ATTENTION: ${_formatTimeAgo(supportStatus?['timeSinceLastMessage'])}' 
                        : '💬 RECENT: ${_formatTimeAgo(supportStatus?['timeSinceLastMessage'])}',
                style: TextStyle(
                  fontSize: 10,
                  color: supportStatus?['urgency'] == 'urgent' 
                      ? Colors.red 
                      : supportStatus?['urgency'] == 'attention' 
                          ? Colors.orange 
                          : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
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
        onTap: isDisabled ? null : () => _openChatWithUser(user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VagusAppBar(
        title: const Text('🛠️ Admin: User Roles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => unawaited(_logout()),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Text('Admin Menu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
                         ListTile(
               leading: const Icon(Icons.dashboard),
               title: const Text('Admin Hub'),
               onTap: () { Navigator.pop(context); _openSupportInbox(); },
             ),
             ListTile(
               leading: const Icon(Icons.people),
               title: const Text('User Manager'),
               onTap: () { Navigator.pop(context); _goToUserManager(); },
             ),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Coach Approvals'),
              onTap: () { Navigator.pop(context); _goToCoachApprovals(); },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Analytics'),
              onTap: () { Navigator.pop(context); _goToAnalytics(); },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Audit Logs'),
              onTap: () { Navigator.pop(context); _goToAuditLogs(); },
            ),
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('AI Configuration'),
              onTap: () { Navigator.pop(context); _goToAIConfig(); },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Global Settings'),
              onTap: () { Navigator.pop(context); _goToGlobalSettings(); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Nutrition Prices'),
              onTap: () { Navigator.pop(context); _goToPriceEditor(); },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety),
              title: const Text('Nutrition Diagnostics'),
              onTap: () { Navigator.pop(context); _goToNutritionDiagnostics(); },
            ),
            ListTile(
              leading: Stack(
                children: [
                  const Icon(Icons.support_agent),
                  if (_totalSupportRequests > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _urgentSupportCount > 0 ? Colors.red : Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '$_totalSupportRequests',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
                             title: const Text('Support Inbox (Admin Hub)'),
              subtitle: _totalSupportRequests > 0 
                ? Text('$_totalSupportRequests pending requests', 
                    style: TextStyle(
                      color: _urgentSupportCount > 0 ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ))
                : null,
              onTap: () { Navigator.pop(context); _openSupportInbox(); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Agent Workload'),
              onTap: () { Navigator.pop(context); AppNavigator.adminAgentWorkload(context); },
            ),
            ListTile(
              leading: const Icon(Icons.quickreply_outlined),
              title: const Text('Macros'),
              onTap: () { Navigator.pop(context); AppNavigator.adminMacros(context); },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Root-Cause Trends'),
              onTap: () { Navigator.pop(context); AppNavigator.adminRootCause(context); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('Ticket Queue'),
              onTap: () { Navigator.pop(context); AppNavigator.adminTicketQueue(context); },
            ),
            ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: const Text('Escalation Matrix'),
              onTap: () { Navigator.pop(context); AppNavigator.adminEscalationMatrix(context); },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Playbooks'),
              onTap: () { Navigator.pop(context); AppNavigator.adminPlaybooks(context); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Knowledge Base'),
              onTap: () { Navigator.pop(context); AppNavigator.adminKnowledge(context); },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber),
              title: const Text('Incident Console'),
              onTap: () { Navigator.pop(context); AppNavigator.adminIncidents(context); },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Session Co-Pilot'),
              onTap: () { Navigator.pop(context); AppNavigator.adminCopilotFor(context, 'sample-user-id'); },
            ),
            ListTile(
              leading: const Icon(Icons.live_tv),
              title: const Text('Live Session'),
              onTap: () { Navigator.pop(context); AppNavigator.adminLiveFor(context, 'sample-user-id'); },
            ),
            ListTile(
              leading: const Icon(Icons.rule),
              title: const Text('Auto-Triage Rules'),
              onTap: () { Navigator.pop(context); AppNavigator.adminRules(context); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Users CSV'),
              onTap: _loading ? null : () { Navigator.pop(context); _exportToCSV(); },
            ),
          ],
        ),
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
            _buildSupportSummary(),
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
                return _buildUserRow(user);
              },
            ),
          ),
        ],
      ),
    );
  }
}

