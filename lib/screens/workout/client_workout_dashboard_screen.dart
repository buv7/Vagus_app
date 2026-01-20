import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vagus_app/screens/workouts/modern_workout_plan_viewer.dart';
import '../../widgets/ai/ai_usage_meter.dart';
import '../../models/workout/fatigue_models.dart';
import '../../services/workout/fatigue_recovery_service.dart';
import '../../services/workout/psychology_service.dart';
import '../../widgets/workout/session_mode_selector.dart';
import '../../services/config/feature_flags.dart';
import '../../widgets/common/fatigue_recovery_icon.dart';
import 'fatigue_recovery_screen.dart';

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
  TransformationMode _mode = TransformationMode.defaultMode;
  ReadinessIndicator? _readiness;

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
            // AI Usage Meter at top
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: AIUsageMeter(isCompact: true),
            ),

            Text(
              _plan!['name'] ?? 'Unnamed Plan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text("🗓️ Weeks: ${_plan!['weeks']?.length ?? 0}"),
            const SizedBox(height: 8),
            Text("📅 Assigned At: ${_plan!['created_at'] ?? 'Unknown'}"),
            const SizedBox(height: 16),
            // ✅ VAGUS ADD: session-transformation-modes START
            FutureBuilder<bool>(
              future: FeatureFlags.instance.isEnabled(FeatureFlags.workoutTransformationModes),
              builder: (context, snapshot) {
                if (!(snapshot.data ?? false)) return const SizedBox.shrink();
                return SessionModeSelector(
                  value: _mode,
                  onChanged: (m) async {
                    setState(() => _mode = m);
                    // If you already have an active session object/id, update it here.
                    // If not, it will be saved when session is created (workout_service patch).
                  },
                );
              },
            ),
            // ✅ VAGUS ADD: session-transformation-modes END
            const SizedBox(height: 12),
            // ✅ VAGUS ADD: fatigue-recovery-readiness START
            FutureBuilder<bool>(
              future: FeatureFlags.instance.isEnabled(FeatureFlags.workoutReadinessIndicators),
              builder: (context, flagSnapshot) {
                if (!(flagSnapshot.data ?? false)) return const SizedBox.shrink();
                return FutureBuilder<ReadinessIndicator>(
                  future: () async {
                    final user = Supabase.instance.client.auth.currentUser!;
                    final ind = await FatigueRecoveryService.I.getReadinessIndicator(userId: user.id);
                    _readiness = ind;
                    return ind;
                  }(),
                  builder: (context, snap) {
                    final ind = snap.data ?? _readiness;
                    if (ind == null) return const SizedBox.shrink();

                    return Card(
                      child: ListTile(
                        leading: FatigueRecoveryIcon(size: 24),
                        title: Text('Readiness: ${ind.score.toStringAsFixed(1)} / 10  (${ind.label})'),
                        subtitle: Text(ind.hint),
                        trailing: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FatigueRecoveryScreen()),
                            );
                          },
                          child: const Text('Log'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // ✅ VAGUS ADD: fatigue-recovery-readiness END
            const SizedBox(height: 12),
            // ✅ VAGUS ADD: client-psychology START
            FutureBuilder<bool>(
              future: FeatureFlags.instance.isEnabled(FeatureFlags.workoutPsychology),
              builder: (context, flagSnapshot) {
                if (!(flagSnapshot.data ?? false)) return const SizedBox.shrink();
                return Builder(
                  builder: (context) {
                    final ind = _readiness ?? ReadinessIndicator.fromScore(6.0);
                    final msg = WorkoutPsychologyService.I.getMotivationalMessage(
                      readiness: ind,
                      mode: _mode,
                    );
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.psychology),
                            const SizedBox(width: 10),
                            Expanded(child: Text(msg)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // ✅ VAGUS ADD: client-psychology END
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
                      builder: (_) => ModernWorkoutPlanViewer(
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
