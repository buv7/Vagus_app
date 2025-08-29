import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin/admin_service.dart';

class CoachApprovalPanel extends StatefulWidget {
  const CoachApprovalPanel({super.key});

  @override
  State<CoachApprovalPanel> createState() => _CoachApprovalPanelState();
}

class _CoachApprovalPanelState extends State<CoachApprovalPanel>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService.instance;
  late TabController _tabController;
  
  List<Map<String, dynamic>> _pendingApplications = [];
  List<Map<String, dynamic>> _approvedApplications = [];
  List<Map<String, dynamic>> _rejectedApplications = [];
  
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _loading = true;
    });

    try {
      final pending = await _adminService.listCoachRequests(status: 'pending');
      final approved = await _adminService.listCoachRequests(status: 'approved');
      final rejected = await _adminService.listCoachRequests(status: 'rejected');

      setState(() {
        _pendingApplications = pending;
        _approvedApplications = approved;
        _rejectedApplications = rejected;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    }
  }

  Future<void> _approveApplication(String requestId) async {
    final success = await _adminService.approveCoach(requestId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Coach application approved')),
        );
        unawaited(_loadApplications());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to approve application')),
        );
      }
    }
  }

  Future<void> _declineApplication(String requestId) async {
    final reason = await _showDeclineReasonDialog();
    if (reason == null) return; // User cancelled

    final success = await _adminService.declineCoach(requestId, reason: reason);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Coach application declined')),
        );
        unawaited(_loadApplications());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to decline application')),
        );
      }
    }
  }

  Future<String?> _showDeclineReasonDialog() async {
    final TextEditingController reasonController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for declining this application:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter reason...',
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.of(context).pop(reason);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application, bool showActions) {
    final user = application['user'] as Map<String, dynamic>? ?? {};
    final email = user['email'] ?? 'No email';
    final specialization = application['specialization'] ?? 'No specialization';
    final yearsExperience = application['years_experience'] ?? 0;
    final certifications = application['certifications'] ?? 'No certifications';
    final bio = application['bio'] ?? 'No bio provided';
    final createdAt = DateTime.tryParse(application['created_at'] ?? '') ?? DateTime.now();
    final status = application['status'] ?? 'unknown';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Text(
          email,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specialization: $specialization'),
            Text('Experience: $yearsExperience years'),
            Text('Status: ${status.toUpperCase()}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bio:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(bio),
                const SizedBox(height: 16),
                const Text(
                  'Certifications:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(certifications),
                const SizedBox(height: 16),
                Text(
                  'Applied: ${DateFormat('MMM d, yyyy HH:mm').format(createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (showActions) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveApplication(application['id']),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _declineApplication(application['id']),
                          icon: const Icon(Icons.close),
                          label: const Text('Decline'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<Map<String, dynamic>> applications, bool showActions) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (applications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_gymnastics, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No applications found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        itemCount: applications.length,
        itemBuilder: (context, index) {
          return _buildApplicationCard(applications[index], showActions);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏋️ Coach Approvals'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Pending\n(${_pendingApplications.length})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Approved\n(${_approvedApplications.length})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cancel, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Rejected\n(${_rejectedApplications.length})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(_pendingApplications, true),
          _buildTabContent(_approvedApplications, false),
          _buildTabContent(_rejectedApplications, false),
        ],
      ),
    );
  }
}
