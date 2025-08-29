import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin/admin_service.dart';
import '../../components/common/confirmation_dialog_two_step.dart';
import '../../services/billing/billing_service.dart';

class UserManagerPanel extends StatefulWidget {
  const UserManagerPanel({super.key});

  @override
  State<UserManagerPanel> createState() => _UserManagerPanelState();
}

class _UserManagerPanelState extends State<UserManagerPanel> {
  final AdminService _adminService = AdminService.instance;
  final BillingService _billingService = BillingService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _loading = true;
  String _roleFilter = 'all';
  String _statusFilter = 'all';
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    unawaited(_loadUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _hasMore = true;
      });
    }

    if (!_hasMore && !refresh) return;

    setState(() {
      _loading = true;
    });

    try {
      final users = await _adminService.listUsers(
        query: _searchController.text.isEmpty ? null : _searchController.text,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      setState(() {
        if (refresh) {
          _allUsers = users;
        } else {
          _allUsers.addAll(users);
        }
        _loading = false;
        _hasMore = users.length == _pageSize;
        if (!refresh) {
          _currentPage++;
        }
      });
      
      _applyFilters();
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    
    _filteredUsers = _allUsers.where((user) {
      final email = (user['email'] ?? '').toString().toLowerCase();
      final name = (user['name'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toLowerCase();
      final isDisabled = user['is_disabled'] == true || user['is_enabled'] == false;
      
      // Search filter
      final matchesSearch = query.isEmpty || 
          email.contains(query) || 
          name.contains(query);
      
      // Role filter
      final matchesRole = _roleFilter == 'all' || role == _roleFilter;
      
      // Status filter
      bool matchesStatus = true;
      if (_statusFilter == 'enabled') {
        matchesStatus = !isDisabled;
      } else if (_statusFilter == 'disabled') {
        matchesStatus = isDisabled;
      }
      
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
    
    setState(() {});
  }

  Future<void> _changeUserRole(String userId, String newRole) async {
    final success = await _adminService.updateUserRole(
      userId: userId,
      role: newRole,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ User role updated successfully')),
        );
        unawaited(_loadUsers(refresh: true));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to update user role')),
        );
      }
    }
  }

  Future<void> _toggleUserEnabled(String userId, bool enabled) async {
    final success = await _adminService.toggleUserEnabled(
      userId: userId,
      enabled: enabled,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ User ${enabled ? 'enabled' : 'disabled'} successfully')),
        );
        unawaited(_loadUsers(refresh: true));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Enable/disable not supported or failed')),
        );
      }
    }
  }

  Future<void> _resetUserAiUsage(String userId) async {
    final success = await _adminService.resetUserAiUsage(userId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ AI usage reset successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ℹ️ AI usage reset not supported')),
        );
      }
    }
  }

  Widget _buildRoleFilter() {
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
              });
              _applyFilters();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['all', 'enabled', 'disabled'].map((status) {
        final isSelected = _statusFilter == status;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(status.toUpperCase()),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _statusFilter = status;
              });
              _applyFilters();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isDisabled = user['is_disabled'] == true || user['is_enabled'] == false;
    final role = user['role'] ?? 'unknown';
    final email = user['email'] ?? 'No email';
    final createdAt = DateTime.tryParse(user['created_at'] ?? '') ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDisabled ? Colors.red : Colors.blue,
          child: Icon(
            isDisabled ? Icons.block : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          email,
          style: TextStyle(
            decoration: isDisabled ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDisabled ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isDisabled ? 'DISABLED' : 'ENABLED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Created: ${DateFormat('MMM d, yyyy').format(createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'role_client':
                _showRoleChangeDialog(user['id'], 'client');
                break;
              case 'role_coach':
                _showRoleChangeDialog(user['id'], 'coach');
                break;
              case 'role_admin':
                _showRoleChangeDialog(user['id'], 'admin');
                break;
              case 'toggle_enabled':
                unawaited(_toggleUserEnabled(user['id'], isDisabled));
                break;
              case 'reset_ai':
                unawaited(_resetUserAiUsage(user['id']));
                break;
              case 'set_plan':
                unawaited(_showSetPlanDialog(user['id']));
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'role_client',
              child: Row(
                children: [
                  Icon(Icons.person, size: 16),
                  SizedBox(width: 8),
                  Text('Set as Client'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'role_coach',
              child: Row(
                children: [
                  Icon(Icons.sports_gymnastics, size: 16),
                  SizedBox(width: 8),
                  Text('Set as Coach'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'role_admin',
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, size: 16),
                  SizedBox(width: 8),
                  Text('Set as Admin'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'toggle_enabled',
              child: Row(
                children: [
                  Icon(isDisabled ? Icons.check_circle : Icons.block, size: 16),
                  const SizedBox(width: 8),
                  Text(isDisabled ? 'Enable User' : 'Disable User'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reset_ai',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 16),
                  SizedBox(width: 8),
                  Text('Reset AI Usage'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'set_plan',
              child: Row(
                children: [
                  Icon(Icons.card_membership, size: 16),
                  SizedBox(width: 8),
                  Text('Set Plan...'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'coach':
        return Colors.orange;
      case 'client':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showRoleChangeDialog(String userId, String newRole) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialogTwoStep(
        title: 'Change User Role',
        message: 'Are you sure you want to change this user\'s role to $newRole?',
        confirmText: 'Change Role',
        onConfirm: () => _changeUserRole(userId, newRole),
      ),
    );
  }

  Future<void> _showSetPlanDialog(String userId) async {
    try {
      final plans = await _billingService.listPlans();
      if (!mounted) return;
      if (plans.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No billing plans available')),
          );
        }
        return;
      }

      String? selectedPlanCode;
      int trialDays = 0;

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Set User Plan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select a plan:'),
                const SizedBox(height: 16),
                ...plans.map((plan) => RadioListTile<String>(
                  title: Text(plan['name'] ?? 'Unknown'),
                  subtitle: Text('\$${(plan['price_monthly_cents'] ?? 0) / 100}/month'),
                  value: plan['code'],
                  groupValue: selectedPlanCode,
                  onChanged: (value) => setState(() => selectedPlanCode = value),
                )),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Trial Days (optional)',
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => trialDays = int.tryParse(value) ?? 0,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedPlanCode == null ? null : () async {
                  Navigator.of(context).pop();
                  
                  // Create subscription
                  final periodEnd = DateTime.now().add(Duration(days: 30 + trialDays));
                  
                  await _billingService.supabase
                      .from('subscriptions')
                      .upsert({
                        'user_id': userId,
                        'plan_code': selectedPlanCode,
                        'status': 'active',
                        'period_start': DateTime.now().toIso8601String(),
                        'period_end': periodEnd.toIso8601String(),
                        'updated_at': DateTime.now().toIso8601String(),
                      });

                  // Log audit
                  await _adminService.logAdminAction(
                    'plan_set',
                    target: userId,
                    meta: {
                      'plan_code': selectedPlanCode,
                      'trial_days': trialDays,
                    },
                  );

                  if (!mounted || !context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Plan set to $selectedPlanCode')),
                  );
                },
                child: const Text('Set Plan'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting plan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 User Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUsers(refresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by email or name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),

          // Filters
          _buildRoleFilter(),
          const SizedBox(height: 8),
          _buildStatusFilter(),
          const SizedBox(height: 16),

          // User list
          Expanded(
            child: _loading && _allUsers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('No users found'))
                    : RefreshIndicator(
                        onRefresh: () => _loadUsers(refresh: true),
                        child: ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(_filteredUsers[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
