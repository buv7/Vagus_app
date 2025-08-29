import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyCoachScreen extends StatefulWidget {
  const MyCoachScreen({super.key});

  @override
  State<MyCoachScreen> createState() => _MyCoachScreenState();
}

class _MyCoachScreenState extends State<MyCoachScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _coachProfile;
  String? _status;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadCoachStatus();
  }

  Future<void> _loadCoachStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch the latest coach request for this client
      final response = await supabase
          .from('coach_requests')
          .select()
          .eq('client_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      _status = response['status'];
      final coachId = response['coach_id'];

      // Fetch coach profile
      final coach = await supabase
          .from('profiles')
          .select()
          .eq('id', coachId)
          .single();

      setState(() {
        _coachProfile = coach;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No request found or failed to load coach.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _coachProfile?['name'] ?? '';
    final email = _coachProfile?['email'] ?? '';
    final avatar = _coachProfile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Coach'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage:
              avatar != null ? NetworkImage(avatar) : null,
              child:
              avatar == null ? const Icon(Icons.person, size: 40) : null,
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(email),
            const SizedBox(height: 16),
            Chip(
              label: Text(
                _status == 'approved'
                    ? 'Approved'
                    : _status == 'pending'
                    ? 'Pending'
                    : 'Rejected',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: _status == 'approved'
                  ? Colors.green
                  : _status == 'pending'
                  ? Colors.orange
                  : Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
