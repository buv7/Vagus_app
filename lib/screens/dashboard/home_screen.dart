import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';
import '../account_switch_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    setState(() {
      _profile = response;
      _loading = false;
    });
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
  }

  Widget _buildProfilePhoto() {
    final photoUrl = _profile?['avatar_url'];
    if (photoUrl != null && photoUrl.toString().isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(photoUrl),
      );
    } else {
      return const CircleAvatar(
        radius: 40,
        child: Icon(Icons.person, size: 40),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to VAGUS'),
        actions: [
          // append-only: quick access to account switcher
          IconButton(
            icon: const Icon(Icons.switch_account),
            tooltip: 'Switch Account',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountSwitchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ).then((updated) {
                if (updated == true) {
                  unawaited(_loadProfile()); // reload on update
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? const Center(child: Text('No profile found'))
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildProfilePhoto()),
            const SizedBox(height: 16),
            Text(
              "🎉 You're logged in!",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text("👤 Name: ${_profile!['name'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            Text("📧 Email: ${_profile!['email'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            Text("🛡️ Role: ${_profile!['role'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            Text("🗓️ Created At: ${_profile!['created_at'] ?? 'N/A'}"),
          ],
        ),
      ),
    );
  }
}
