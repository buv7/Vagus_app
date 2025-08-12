import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      _showMessage("User not signed in");
      return;
    }

    try {
      final result = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        _profile = result;
        _loading = false;
      });
    } catch (e) {
      _showMessage("Error loading profile: $e");
      setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return const Scaffold(
        body: Center(child: Text("No profile found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Your Profile")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👤 Name: ${_profile!['name']}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("📧 Email: ${_profile!['email']}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("🧩 Role: ${_profile!['role']}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("🕒 Created At: ${_profile!['created_at']}", style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
