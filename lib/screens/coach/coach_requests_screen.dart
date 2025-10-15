import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoachRequestsScreen extends StatefulWidget {
  const CoachRequestsScreen({super.key});

  @override
  State<CoachRequestsScreen> createState() => _CoachRequestsScreenState();
}

class _CoachRequestsScreenState extends State<CoachRequestsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('coach_requests')
          .select()
          .eq('coach_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load requests: $e';
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _getClientProfile(String clientId) async {
    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', clientId)
          .single();

      return profile;
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateStatus(String requestId, String newStatus) async {
    try {
      // 1. Update request status
      await supabase
          .from('coach_requests')
          .update({'status': newStatus})
          .eq('id', requestId);

      // 2. Get full request to extract client/coach ID
      final request = await supabase
          .from('coach_requests')
          .select()
          .eq('id', requestId)
          .single();

      if (newStatus == 'approved') {
        // 3. Insert into user_coach_links (base table) if not already linked
        final existing = await supabase
            .from('user_coach_links')
            .select()
            .eq('client_id', request['client_id'])
            .eq('coach_id', request['coach_id'])
            .maybeSingle();

        if (existing == null) {
          await supabase.from('user_coach_links').insert({
            'client_id': request['client_id'],
            'coach_id': request['coach_id'],
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
          });
        } else {
          // Update existing connection to active
          await supabase.from('user_coach_links')
              .update({'status': 'active'})
              .eq('client_id', request['client_id'])
              .eq('coach_id', request['coach_id']);
        }

        // 4. Ask if they want to send intake form
        if (mounted) {
          unawaited(_showIntakeFormDialog(request['client_id'], request['coach_id']));
        }
      }

      unawaited(_loadRequests()); // refresh UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _showIntakeFormDialog(String clientId, String coachId) async {
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Intake Form?'),
        content: const Text(
          'Would you like to send your intake form to this client? '
          'They will need to fill it out before you can create their nutrition plans.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip for Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Form'),
          ),
        ],
      ),
    );

    if (shouldSend == true && mounted) {
      await _sendIntakeForm(clientId, coachId);
    }
  }

  Future<void> _sendIntakeForm(String clientId, String coachId) async {
    try {
      // Get coach's intake form (active status)
      final formResponse = await supabase
          .from('intake_forms')
          .select()
          .eq('coach_id', coachId)
          .eq('status', 'active')
          .maybeSingle();

      if (formResponse == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No intake form found. Please create one in settings.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Create intake form assignment for client
      await supabase.from('intake_form_assignments').insert({
        'form_id': formResponse['id'],
        'client_id': clientId,
        'coach_id': coachId,
        'status': 'pending',
        'assigned_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Intake form sent to client successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send intake form: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return FutureBuilder(
      future: _getClientProfile(request['client_id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final client = snapshot.data as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: client['avatar_url'] != null
                  ? NetworkImage(client['avatar_url'])
                  : null,
              child: client['avatar_url'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(client['name'] ?? 'No name'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client['email'] ?? ''),
                Text('Status: ${request['status']}'),
              ],
            ),
            trailing: request['status'] == 'pending'
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () =>
                      _updateStatus(request['id'], 'approved'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () =>
                      _updateStatus(request['id'], 'rejected'),
                ),
              ],
            )
                : Text(
              request['status'],
              style: TextStyle(
                color: request['status'] == 'approved'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Requests'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error))
          : ListView(
        children: _requests.map(_buildRequestCard).toList(),
      ),
    );
  }
}
