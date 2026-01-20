import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/retention/mission_models.dart';
import '../../services/retention/daily_missions_service.dart';

class DailyMissionsScreen extends StatefulWidget {
  const DailyMissionsScreen({super.key});

  @override
  State<DailyMissionsScreen> createState() => _DailyMissionsScreenState();
}

class _DailyMissionsScreenState extends State<DailyMissionsScreen> {
  List<DailyMission> _missions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final missions = await DailyMissionsService.I.getTodayMissions(userId: user.id);
      if (missions.isEmpty) {
        // Generate missions if none exist
        await DailyMissionsService.I.generateDailyMissions(userId: user.id);
        final newMissions = await DailyMissionsService.I.getTodayMissions(userId: user.id);
        setState(() {
          _missions = newMissions;
          _loading = false;
        });
      } else {
        setState(() {
          _missions = missions;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _completeMission(String missionId) async {
    try {
      await DailyMissionsService.I.completeMission(missionId);
      await _loadMissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission completed! ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
      appBar: AppBar(title: const Text('Daily Missions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_missions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No missions for today. Check back tomorrow!'),
              ),
            )
          else
            ..._missions.map((mission) => _buildMissionCard(mission)),
        ],
      ),
    );
  }

  Widget _buildMissionCard(DailyMission mission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          mission.completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: mission.completed ? Colors.green : Colors.grey,
        ),
        title: Text(
          mission.missionTitle,
          style: TextStyle(
            decoration: mission.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mission.missionDescription != null)
              Text(mission.missionDescription!),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(mission.missionType.label),
                  labelStyle: const TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 8),
                Text(
                  '+${mission.xpReward} XP',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: mission.completed
            ? const Icon(Icons.check, color: Colors.green)
            : ElevatedButton(
                onPressed: () => _completeMission(mission.id),
                child: const Text('Complete'),
              ),
      ),
    );
  }
}
