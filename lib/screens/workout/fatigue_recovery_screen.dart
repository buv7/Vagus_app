import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/workout/fatigue_models.dart';
import '../../services/workout/fatigue_recovery_service.dart';
import '../../widgets/common/save_icon.dart';
import '../../widgets/common/fatigue_recovery_icon.dart';

class FatigueRecoveryScreen extends StatefulWidget {
  const FatigueRecoveryScreen({super.key});

  @override
  State<FatigueRecoveryScreen> createState() => _FatigueRecoveryScreenState();
}

class _FatigueRecoveryScreenState extends State<FatigueRecoveryScreen> {
  int fatigue = 5, recovery = 5, readiness = 5, sleep = 5, stress = 5, energy = 5;
  final notes = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            FatigueRecoveryIcon(size: 20),
            const SizedBox(width: 8),
            const Text('Fatigue / Recovery'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _slider('Fatigue', fatigue, (v) => setState(() => fatigue = v)),
          _slider('Recovery', recovery, (v) => setState(() => recovery = v)),
          _slider('Readiness', readiness, (v) => setState(() => readiness = v)),
          _slider('Sleep Quality', sleep, (v) => setState(() => sleep = v)),
          _slider('Stress', stress, (v) => setState(() => stress = v)),
          _slider('Energy', energy, (v) => setState(() => energy = v)),
          const SizedBox(height: 10),
          TextField(
            controller: notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: loading
                ? null
                : () async {
                    if (!mounted) return;
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => loading = true);
                    try {
                      final log = FatigueLog(
                        id: 'temp',
                        userId: user.id,
                        workoutSessionId: null,
                        fatigueScore: fatigue,
                        recoveryScore: recovery,
                        readinessScore: readiness,
                        sleepQuality: sleep,
                        stressLevel: stress,
                        energyLevel: energy,
                        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                        loggedAt: DateTime.now(),
                        createdAt: DateTime.now(),
                      );

                      await FatigueRecoveryService.I.logFatigue(log);

                      final computed = await FatigueRecoveryService.I.calculateRecoveryFromLogs(userId: user.id);
                      await FatigueRecoveryService.I.upsertTodayRecoveryScore(userId: user.id, overallRecovery: computed);

                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Saved ✅')),
                        );
                        navigator.pop();
                      }
                    } finally {
                      if (mounted) setState(() => loading = false);
                    }
                  },
            icon: SaveIcon(),
            label: const Text('Save Log'),
          ),
        ],
      ),
    );
  }

  Widget _slider(String title, int value, ValueChanged<int> onChanged) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title: $value', style: const TextStyle(fontWeight: FontWeight.w700)),
            Slider(
              value: value.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$value',
              onChanged: (v) => onChanged(v.round()),
            ),
          ],
        ),
      ),
    );
  }
}
