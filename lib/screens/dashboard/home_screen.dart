import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/branding/vagus_appbar.dart';
import 'edit_profile_screen.dart';
import '../account_switch_screen.dart';
import '../workout/coach_workout_dashboard_screen.dart';
import '../workout/coach_plan_builder_screen_refactored.dart';
import '../nutrition/coach_nutrition_dashboard.dart';
import '../nutrition/nutrition_plan_builder.dart';

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

  void _goToWorkoutViewer() {
    debugPrint('🏋️ Navigating to Workout Plan Viewer');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          debugPrint('✅ Opening CoachWorkoutDashboardScreen');
          return const CoachWorkoutDashboardScreen();
        },
      ),
    );
  }

  void _goToPlanBuilder() {
    debugPrint('🏋️ Navigating to Workout Plan Builder');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          debugPrint('✅ Opening CoachPlanBuilderScreen');
          return const CoachPlanBuilderScreen();
        },
      ),
    );
  }

  void _goToNutritionBuilder() {
    debugPrint('🥗 Navigating to Nutrition Plan Builder');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          debugPrint('✅ Opening NutritionPlanBuilder');
          return const NutritionPlanBuilder();
        },
      ),
    );
  }

  void _goToNutritionViewer() {
    debugPrint('🥗 Navigating to Nutrition Dashboard');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          debugPrint('✅ Opening CoachNutritionDashboard');
          return const CoachNutritionDashboard();
        },
      ),
    );
  }

  bool get _isCoach => _profile?['role'] == 'coach';

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
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
      appBar: VagusAppBar(
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
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Section
              Center(child: _buildProfilePhoto()),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "🎉 You're logged in!",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              Text("👤 Name: ${_profile!['name'] ?? 'N/A'}"),
              const SizedBox(height: 8),
              Text("📧 Email: ${_profile!['email'] ?? 'N/A'}"),
              const SizedBox(height: 8),
              Text("🛡️ Role: ${_profile!['role'] ?? 'N/A'}"),
              const SizedBox(height: 8),
              Text("🗓️ Created At: ${_profile!['created_at'] ?? 'N/A'}"),

              // Coach-specific sections
              if (_isCoach) ...[
                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const SizedBox(height: 24),

                // Workout Management Section
                _buildSectionHeader('🏋️ Workout Management'),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  icon: const Icon(Icons.fitness_center, size: 24),
                  label: const Text(
                    'Create Workout Plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _goToPlanBuilder,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  icon: const Icon(Icons.visibility, size: 24),
                  label: const Text(
                    'View Client Workout Plans',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _goToWorkoutViewer,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const SizedBox(height: 24),

                // Nutrition Management Section
                _buildSectionHeader('🥗 Nutrition Management'),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  icon: const Icon(Icons.restaurant_menu, size: 24),
                  label: const Text(
                    'Create Nutrition Plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _goToNutritionBuilder,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  icon: const Icon(Icons.visibility, size: 24),
                  label: const Text(
                    'View Nutrition Plans',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _goToNutritionViewer,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
