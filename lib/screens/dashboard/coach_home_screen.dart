import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart';
import '../workout/WorkoutPlanViewerScreen.dart';
import '../workout/CoachPlanBuilderScreen.dart';
import '../nutrition/NutritionPlanBuilder.dart';
import '../nutrition/NutritionPlanViewer.dart';
import '../coach/coach_notes_screen.dart';
import '../messaging/coach_threads_screen.dart';
import '../messaging/coach_messenger_screen.dart';
import '../files/file_manager_screen.dart';
import 'edit_profile_screen.dart'; // ✅ Make sure this exists

// Safe image handling helpers
bool _isValidHttpUrl(String? url) {
  if (url == null) return false;
  final u = url.trim();
  return u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://'));
}

Widget _imagePlaceholder({double? w, double? h}) {
  return Container(
    width: w,
    height: h,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.image_not_supported),
  );
}

Widget safeNetImage(String? url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (_isValidHttpUrl(url)) {
    return Image.network(
      url!.trim(),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _imagePlaceholder(w: width, h: height),
    );
  }
  return _imagePlaceholder(w: width, h: height);
}

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final links = await supabase
          .from('coach_clients')
          .select('client_id, profiles:client_id (id, name, email, avatar_url)')
          .eq('coach_id', user.id);

      final clientIds = links.map((row) => row['client_id'] as String).toList();

      final requests = await supabase
          .from('coach_requests')
          .select('*, client:client_id (id, name, email, avatar_url)')
          .eq('coach_id', user.id)
          .eq('status', 'pending')
          .not('client_id', 'in', clientIds);

      setState(() {
        _profile = profileData;
        _clients = List<Map<String, dynamic>>.from(
            links.map((row) => row['profiles']));
        _requests = List<Map<String, dynamic>>.from(requests);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _loading = false;
      });
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    try {
      final existing = await supabase
          .from('coach_clients')
          .select()
          .eq('coach_id', request['coach_id'])
          .eq('client_id', request['client_id']);

      if (existing.isEmpty) {
        await supabase.from('coach_clients').insert({
          'coach_id': request['coach_id'],
          'client_id': request['client_id'],
        });
      }

      await supabase
          .from('coach_requests')
          .delete()
          .eq('id', request['id']);

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving: $e')),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await supabase
          .from('coach_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId);

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting: $e')),
      );
    }
  }

  void _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _goToWorkoutViewer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutPlanViewerScreen()),
    );
  }

  void _goToPlanBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoachPlanBuilderScreen()),
    );
  }

  void _goToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  void _goToNutritionBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NutritionPlanBuilder()),
    );
  }

  void _goToNutritionViewer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NutritionPlanViewer()),
    );
  }

  void _goToNotes(Map<String, dynamic> client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachNotesScreen(client: client),
      ),
    );
  }

  void _goToMessaging(Map<String, dynamic> client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachMessengerScreen(client: client),
      ),
    );
  }

  void _goToMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CoachThreadsScreen(),
      ),
    );
  }

  void _goToFileManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FileManagerScreen(),
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    final String? imgUrl = client['avatar_url'];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: _isValidHttpUrl(imgUrl)
              ? NetworkImage(imgUrl!.trim())
              : null,
          child: !_isValidHttpUrl(imgUrl) ? const Icon(Icons.person) : null,
        ),
        title: Text(client['name'] ?? 'No name'),
        subtitle: Text(client['email'] ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat),
              tooltip: 'Message Client',
              onPressed: () => _goToMessaging(client),
            ),
            IconButton(
              icon: const Icon(Icons.note),
              tooltip: 'View Notes',
              onPressed: () => _goToNotes(client),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final client = request['client'] ?? {};
    final String? imgUrl = client['avatar_url'];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.yellow[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: _isValidHttpUrl(imgUrl)
              ? NetworkImage(imgUrl!.trim())
              : null,
          child: !_isValidHttpUrl(imgUrl) ? const Icon(Icons.person) : null,
        ),
        title: Text(client['name'] ?? 'No name'),
        subtitle: Text('${client['email'] ?? ''}\n${request['message'] ?? ''}'),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              tooltip: 'Approve',
              onPressed: () => _approveRequest(request),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Reject',
              onPressed: () => _rejectRequest(request['id']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _profile?['name'] ?? 'Unknown';
    final email = _profile?['email'] ?? '';
    final role = _profile?['role'] ?? '';
    final avatarUrl = _profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏋️ Coach Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: _goToEditProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isValidHttpUrl(avatarUrl))
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(avatarUrl!.trim()),
                )
              else
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
              const SizedBox(height: 16),
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              Text(email),
              const SizedBox(height: 8),
              Chip(label: Text(role.toUpperCase())),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text("View Client Workout Plans"),
                onPressed: _goToWorkoutViewer,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Create New Plan"),
                onPressed: _goToPlanBuilder,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.restaurant_menu),
                label: const Text("Nutrition Plan Builder"),
                onPressed: _goToNutritionBuilder,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text("Nutrition Plan Viewer"),
                onPressed: _goToNutritionViewer,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text("Messages"),
                onPressed: _goToMessages,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.folder),
                label: const Text("File Manager"),
                onPressed: _goToFileManager,
              ),
              const SizedBox(height: 32),

              if (_requests.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 12),
                const Text("📥 Pending Requests",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._requests.map(_buildRequestCard),
                const SizedBox(height: 20),
              ],

              const Divider(),
              const SizedBox(height: 12),
              const Text("📋 Your Clients",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_clients.isEmpty)
                const Text("No clients linked yet.")
              else
                Column(children: _clients.map(_buildClientCard).toList()),

              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
