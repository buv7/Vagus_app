import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vagus_app/screens/workout/workout_plan_viewer_screen.dart';

class CoachWorkoutDashboardScreen extends StatefulWidget {
  const CoachWorkoutDashboardScreen({super.key});

  @override
  State<CoachWorkoutDashboardScreen> createState() =>
      _CoachWorkoutDashboardScreenState();
}

class _CoachWorkoutDashboardScreenState
    extends State<CoachWorkoutDashboardScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _clients = [];
  String? _selectedClientId;

  Map<String, dynamic>? _plan;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await supabase
          .from('profiles')
          .select('id, name')
          .eq('role', 'client')
          .order('name');

      setState(() {
        _clients = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '❌ Failed to load clients.';
        _loading = false;
      });
    }
  }

  Future<void> _loadWorkoutPlanForClient(String clientId) async {
    setState(() {
      _loading = true;
      _plan = null;
      _error = '';
    });

    try {
      final response = await supabase
          .from('workout_plans')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      setState(() {
        _plan = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '❌ No workout plan found for selected client.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('👨‍🏫 Coach Workout Viewer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedClientId,
              hint: const Text('Select a client'),
              decoration: const InputDecoration(
                labelText: 'Client',
                border: OutlineInputBorder(),
              ),
              items: _clients.map((client) {
                return DropdownMenuItem<String>(
                  value: client['id'],
                  child: Text(client['name'] ?? 'Unnamed'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedClientId = val;
                  });
                  _loadWorkoutPlanForClient(val);
                }
              },
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(fontSize: 16))
            else if (_plan != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plan!['name'] ?? 'Unnamed Plan',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text("Weeks: ${_plan!['weeks'].length}"),
                    const SizedBox(height: 8),
                    Text("Assigned At: ${_plan!['created_at'] ?? 'Unknown'}"),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Full Plan'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkoutPlanViewerScreen(
                                planOverride: _plan,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
