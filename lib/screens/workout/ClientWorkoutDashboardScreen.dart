import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vagus_app/screens/workout/WorkoutPlanViewerScreen.dart';

class ClientWorkoutDashboardScreen extends StatefulWidget {
  const ClientWorkoutDashboardScreen({super.key});

  @override
  State<ClientWorkoutDashboardScreen> createState() =>
      _ClientWorkoutDashboardScreenState();
}

class _ClientWorkoutDashboardScreenState
    extends State<ClientWorkoutDashboardScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _plan;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlan();
  }

  Future<void> _loadWorkoutPlan() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('workout_plans')
          .select()
          .eq('client_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      setState(() {
        _plan = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _plan = null;
        _error = '❌ No workout plan found.\nYour coach hasn’t assigned a plan yet.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 My Workout Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkoutPlan,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _plan == null
            ? Center(
          child: Text(
            _error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _plan!['name'] ?? 'Unnamed Plan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text("🗓️ Weeks: ${_plan!['weeks']?.length ?? 0}"),
            const SizedBox(height: 8),
            Text("📅 Assigned At: ${_plan!['created_at'] ?? 'Unknown'}"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.fitness_center),
                label: const Text('View Full Plan'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutPlanViewerScreen(
                        planOverride: _plan!,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
