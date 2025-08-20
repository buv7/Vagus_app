import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminApprovalPanel extends StatefulWidget {
  const AdminApprovalPanel({super.key});

  @override
  State<AdminApprovalPanel> createState() => _AdminApprovalPanelState();
}

class _AdminApprovalPanelState extends State<AdminApprovalPanel> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _loading = true);
    
    try {
      // Fetch pending coach applications
      final applicationsResponse = await supabase
          .from('coach_applications')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      // Fetch user profiles for the applications
      final applications = List<Map<String, dynamic>>.from(applicationsResponse);
      final userIds = applications.map((app) => app['user_id'] as String).toList();
      
      final profilesResponse = await supabase
          .from('profiles')
          .select('id, name, email, avatar_url')
          .inFilter('id', userIds);

      final profiles = Map<String, Map<String, dynamic>>.fromEntries(
        (profilesResponse as List).map((profile) => MapEntry(profile['id'], profile))
      );

      // Combine applications with profile data
      final applicationsWithProfiles = applications.map((app) {
        final profile = profiles[app['user_id']] ?? {};
        return {
          ...app,
          'profiles': profile,
        };
      }).toList();

      setState(() {
        _applications = applicationsWithProfiles;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load applications: $e';
        _loading = false;
      });
    }
  }

  Future<void> _approveApplication(String applicationId, String userId) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Start a transaction-like operation
      // 1. Update the application status
      await supabase
          .from('coach_applications')
          .update({
            'status': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': currentUser.id,
          })
          .eq('id', applicationId);

      // 2. Update the user's role to coach
      await supabase
          .from('profiles')
          .update({'role': 'coach'})
          .eq('id', userId);

      // 3. Log the action
      await supabase.from('audit_logs').insert({
        'action': 'coach_application_approved',
        'target_user_id': userId,
        'application_id': applicationId,
        'changed_by': currentUser.id,
        'details': 'Coach application approved',
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Application approved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the list
      _loadApplications();
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to approve application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectApplication(String applicationId, String userId) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Update the application status
      await supabase
          .from('coach_applications')
          .update({
            'status': 'rejected',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': currentUser.id,
          })
          .eq('id', applicationId);

      // Log the action
      await supabase.from('audit_logs').insert({
        'action': 'coach_application_rejected',
        'target_user_id': userId,
        'application_id': applicationId,
        'changed_by': currentUser.id,
        'details': 'Coach application rejected',
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Application rejected'),
          backgroundColor: Colors.orange,
        ),
      );

      // Refresh the list
      _loadApplications();
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to reject application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final profile = application['profiles'] as Map<String, dynamic>? ?? {};
    final applicantName = profile['name'] ?? 'Unknown User';
    final applicantEmail = profile['email'] ?? 'No email';
    final avatarUrl = profile['avatar_url'];
    
    final bio = application['bio'] ?? '';
    final specialization = application['specialization'] ?? '';
    final yearsExperience = application['years_experience'] ?? 0;
    final certifications = application['certifications'] ?? '';
    final createdAt = application['created_at'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Applicant Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        applicantEmail,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Applied: ${_formatDate(createdAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Application Details
            _buildDetailRow('Specialization', specialization),
            _buildDetailRow('Years of Experience', '$yearsExperience years'),
            const SizedBox(height: 8),
            
            // Bio
            const Text(
              'Bio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bio,
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Certifications
            const Text(
              'Certifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              certifications,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveApplication(
                      application['id'],
                      application['user_id'],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectApplication(
                      application['id'],
                      application['user_id'],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadApplications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _applications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No pending applications',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'All coach applications have been reviewed',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          return _buildApplicationCard(_applications[index]);
                        },
                      ),
                    ),
    );
  }
}
