import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import '../coach/CoachSearchScreen.dart';
import '../nutrition/NutritionPlanViewer.dart';
import '../messaging/client_threads_screen.dart';
import '../files/file_manager_screen.dart';
import '../../services/progress/progress_service.dart';
import '../../widgets/progress/metrics_card.dart';
import '../../widgets/progress/photos_card.dart';
import '../../widgets/progress/checkins_card.dart';
import '../../widgets/progress/export_card.dart';

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

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final supabase = Supabase.instance.client;
  final ProgressService _progressService = ProgressService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _coaches = [];
  List<Map<String, dynamic>> _metrics = [];
  List<Map<String, dynamic>> _photos = [];
  List<Map<String, dynamic>> _checkins = [];
  bool _loading = true;
  String _error = '';
  bool _coachFoundViaFallback = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload coach data when page is re-entered to avoid stale cache
    if (!_loading && _coaches.isEmpty) {
      _loadCoach();
    }
  }

  Future<void> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _profile = profile;
      });

      // Load coach data with robust fallback
      await _loadCoach();

      // Load progress data
      await _loadProgressData();
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadCoach() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final role = _profile?['role'] ?? '';
    if (kDebugMode) {
      debugPrint('Loading coach for user ${user.id} with role: $role');
    }

    try {
      List<String> coachIds = [];

      // Primary lookup via link table for clients
      if (role == 'client') {
        // First try coach_clients table
        final links = await supabase
            .from('coach_clients')
            .select('coach_id')
            .eq('client_id', user.id);

        if (links.isNotEmpty) {
          coachIds = links.map((link) => link['coach_id'] as String).toList();
          _coachFoundViaFallback = false;
          if (kDebugMode) {
            debugPrint('Found ${coachIds.length} coach(es) via coach_clients table');
          }
        } else {
          // Second try coach_client_links table
          final links2 = await supabase
              .from('coach_client_links')
              .select('coach_id')
              .eq('client_id', user.id);

          if (links2.isNotEmpty) {
            coachIds = links2.map((link) => link['coach_id'] as String).toList();
            _coachFoundViaFallback = false;
            if (kDebugMode) {
              debugPrint('Found ${coachIds.length} coach(es) via coach_client_links table');
            }
          } else {
            // Fallback: Check workout plans for this client's coach_id
            final workoutPlans = await supabase
                .from('workout_plans')
                .select('coach_id')
                .eq('client_id', user.id)
                .not('coach_id', 'is', null);

            if (workoutPlans.isNotEmpty) {
              final workoutCoachIds = workoutPlans
                  .map((plan) => plan['coach_id'] as String)
                  .where((id) => id.isNotEmpty)
                  .toSet()
                  .toList();

              if (workoutCoachIds.isNotEmpty) {
                coachIds = workoutCoachIds;
                _coachFoundViaFallback = true;
                if (kDebugMode) {
                  debugPrint('Found ${coachIds.length} coach(es) via workout_plans fallback');
                }
              }
            }

            // If still no coaches found, check nutrition plans
            if (coachIds.isEmpty) {
              final nutritionPlans = await supabase
                  .from('nutrition_plans')
                  .select('created_by')
                  .eq('client_id', user.id)
                  .not('created_by', 'is', null);

              if (nutritionPlans.isNotEmpty) {
                final nutritionCoachIds = nutritionPlans
                    .map((plan) => plan['created_by'] as String)
                    .where((id) => id.isNotEmpty)
                    .toSet()
                    .toList();

                if (nutritionCoachIds.isNotEmpty) {
                  coachIds = nutritionCoachIds;
                  _coachFoundViaFallback = true;
                  if (kDebugMode) {
                    debugPrint('Found ${coachIds.length} coach(es) via nutrition_plans fallback');
                  }
                }
              }
            }
          }
        }
      } else if (role == 'coach') {
        // For coaches, fetch their linked clients (existing logic)
        final links = await supabase
            .from('coach_clients')
            .select('client_id')
            .eq('coach_id', user.id);

        if (links.isNotEmpty) {
          final clientIds = links.map((link) => link['client_id'] as String).toList();
          final clients = await supabase
              .from('profiles')
              .select()
              .inFilter('id', clientIds);

          setState(() {
            _coaches = List<Map<String, dynamic>>.from(clients);
            _loading = false;
          });
          return;
        }
      }

      // Fetch coach profiles if we found any coach IDs
      if (coachIds.isNotEmpty) {
        final coaches = await supabase
            .from('profiles')
            .select()
            .inFilter('id', coachIds);

        setState(() {
          _coaches = List<Map<String, dynamic>>.from(coaches);
          _loading = false;
        });

        // If we found coaches via fallback and there's exactly one, offer to create the link
        if (role == 'client' && coachIds.length == 1 && _coachFoundViaFallback) {
          if (kDebugMode) {
            debugPrint('Found single coach via fallback, offering to create link');
          }
        }
      } else {
        setState(() {
          _coaches = [];
          _loading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading coach: $e');
      }
      setState(() {
        _coaches = [];
        _loading = false;
      });
    }
  }

  Future<void> _loadProgressData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final metrics = await _progressService.fetchMetrics(user.id);
      final photos = await _progressService.fetchProgressPhotos(user.id);
      final checkins = await _progressService.fetchCheckins(user.id);

      setState(() {
        _metrics = metrics;
        _photos = photos;
        _checkins = checkins;
      });
    } catch (e) {
      // Silently handle progress data loading errors
      debugPrint('Failed to load progress data: $e');
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

  void _goToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  void _goToCoachSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoachSearchScreen()),
    );
  }

  Future<void> _connectCoach(String coachId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('coach_clients')
          .upsert({
            'coach_id': coachId,
            'client_id': user.id,
            'created_at': DateTime.now().toIso8601String(),
          }, onConflict: 'coach_id,client_id');

      if (kDebugMode) {
        debugPrint('Successfully connected coach $coachId to client ${user.id}');
      }

      // Reload coach data to refresh the UI
      await _loadCoach();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Coach connected successfully!')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error connecting coach: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to connect coach: $e')),
        );
      }
    }
  }

  Widget _buildCoachCard(Map<String, dynamic> coach) {
    final String? imgUrl = coach['avatar_url'];
    final String coachId = coach['id'] as String;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: _isValidHttpUrl(imgUrl)
              ? NetworkImage(imgUrl!.trim())
              : null,
          child: !_isValidHttpUrl(imgUrl) ? const Icon(Icons.person) : null,
        ),
        title: Text(coach['name'] ?? 'No name'),
        subtitle: Text(coach['email'] ?? ''),
        trailing: _coachFoundViaFallback && _profile?['role'] == 'client'
            ? OutlinedButton(
                onPressed: () => _connectCoach(coachId),
                child: const Text('Connect'),
              )
            : null,
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
        title: const Text('📋 Client Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Coaches',
            onPressed: _goToCoachSearch,
          ),
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
              const Text(
                'Welcome, Client! Your plans and check-ins will appear here.',
              ),
              const SizedBox(height: 32),
              const Divider(),
              const Text(
                "👨‍🏫 Your Coach",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_coaches.isEmpty)
                const Text("No coach connected yet.")
              else
                Column(children: _coaches.map(_buildCoachCard).toList()),

              const SizedBox(height: 32),

              // ✅ WORKOUT PLAN BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/client-workout');
                },
                icon: const Icon(Icons.fitness_center),
                label: const Text('View Workout Plan'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

              const SizedBox(height: 16),

              // ✅ NUTRITION PLAN BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NutritionPlanViewer(),
                    ),
                  );
                },
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('View Nutrition Plan'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

              const SizedBox(height: 16),

              // ✅ MESSAGING BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClientThreadsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Messages'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

              const SizedBox(height: 16),

              // ✅ FILE MANAGER BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FileManagerScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.folder),
                label: const Text('File Manager'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Progress System Section
              const Text(
                "📊 Progress Tracking",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Metrics Card
              MetricsCard(
                userId: _profile?['id'] ?? '',
                metrics: _metrics,
                onRefresh: _loadProgressData,
              ),

              const SizedBox(height: 16),

              // Photos Card
              PhotosCard(
                userId: _profile?['id'] ?? '',
                photos: _photos,
                onRefresh: _loadProgressData,
              ),

              const SizedBox(height: 16),

              // Check-ins Card
              CheckinsCard(
                userId: _profile?['id'] ?? '',
                checkins: _checkins,
                coaches: _coaches,
                onRefresh: _loadProgressData,
              ),

              const SizedBox(height: 16),

              // Export Card
              ExportCard(
                userId: _profile?['id'] ?? '',
                metrics: _metrics,
                photos: _photos,
                checkins: _checkins,
                userName: _profile?['name'] ?? 'Unknown',
              ),

              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
