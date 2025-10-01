import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/workout/workout_plan.dart';
import '../../services/workout/workout_service.dart';
import 'workout_week_editor.dart';

/// Simplified Workout Plan Builder - matches NutritionPlanBuilder pattern
class CoachPlanBuilderScreen extends StatefulWidget {
  final String? clientId;
  final WorkoutPlan? planToEdit;

  const CoachPlanBuilderScreen({
    super.key,
    this.clientId,
    this.planToEdit,
  });

  @override
  State<CoachPlanBuilderScreen> createState() => _CoachPlanBuilderScreenState();
}

class _CoachPlanBuilderScreenState extends State<CoachPlanBuilderScreen> {
  final _supabase = Supabase.instance.client;
  final _workoutService = WorkoutService();
  final _nameController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _clients = [];
  String? _selectedClientId;
  List<WorkoutWeek> _weeks = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
    _initializePlan();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('coach_clients')
          .select('client_id, profiles:client_id (id, name, email)')
          .eq('coach_id', user.id);

      setState(() {
        _clients = (response as List)
            .where((row) => row['profiles'] != null)
            .map((row) {
          final profile = row['profiles'] as Map<String, dynamic>;
          return {
            'id': profile['id'],
            'name': profile['name'],
            'email': profile['email'],
          };
        })
            .toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading clients: $e');
      setState(() => _loading = false);
    }
  }

  void _initializePlan() {
    if (widget.planToEdit != null) {
      // Editing existing plan
      final plan = widget.planToEdit!;
      _nameController.text = plan.name;
      _selectedClientId = plan.clientId;
      _weeks = List<WorkoutWeek>.from(plan.weeks);
    } else {
      // New plan - start with 1 week, 3 days
      _weeks = [
        WorkoutWeek(
          planId: '',
          weekNumber: 1,
          days: [
            WorkoutDay(
              weekId: '',
              dayNumber: 1,
              label: 'Day 1',
              exercises: [],
            ),
            WorkoutDay(
              weekId: '',
              dayNumber: 2,
              label: 'Day 2',
              exercises: [],
            ),
            WorkoutDay(
              weekId: '',
              dayNumber: 3,
              label: 'Day 3',
              exercises: [],
            ),
          ],
        ),
      ];
      _selectedClientId = widget.clientId;
    }
  }

  void _addWeek() {
    setState(() {
      final newWeekNumber = _weeks.length + 1;
      _weeks.add(
        WorkoutWeek(
          planId: '',
          weekNumber: newWeekNumber,
          days: [
            WorkoutDay(
              weekId: '',
              dayNumber: 1,
              label: 'Day 1',
              exercises: [],
            ),
            WorkoutDay(
              weekId: '',
              dayNumber: 2,
              label: 'Day 2',
              exercises: [],
            ),
            WorkoutDay(
              weekId: '',
              dayNumber: 3,
              label: 'Day 3',
              exercises: [],
            ),
          ],
        ),
      );
    });
  }

  void _removeWeek(int index) {
    if (_weeks.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan must have at least one week')),
      );
      return;
    }

    setState(() {
      _weeks.removeAt(index);
      // Renumber remaining weeks
      for (int i = 0; i < _weeks.length; i++) {
        _weeks[i] = _weeks[i].copyWith(weekNumber: i + 1);
      }
    });
  }

  void _updateWeek(int index, WorkoutWeek week) {
    setState(() {
      _weeks[index] = week;
    });
  }

  Future<void> _savePlan() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan name')),
      );
      return;
    }

    if (_selectedClientId == null || _selectedClientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final plan = WorkoutPlan(
        id: widget.planToEdit?.id,
        coachId: user.id,
        clientId: _selectedClientId!,
        name: _nameController.text.trim(),
        durationWeeks: _weeks.length,
        createdBy: user.id,
        createdAt: widget.planToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        weeks: _weeks,
        unseenUpdate: true,
      );

      if (widget.planToEdit == null) {
        await _workoutService.createPlan(plan);
      } else {
        await _workoutService.updatePlan(plan);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Workout plan saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planToEdit == null
            ? 'Create Workout Plan'
            : 'Edit Workout Plan'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePlan,
              tooltip: 'Save Plan',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Plan Name',
                      hintText: 'e.g., 12-Week Strength Program',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Client selector
                  if (_clients.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'No clients available. Please add clients first.',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedClientId,
                      decoration: const InputDecoration(
                        labelText: 'Select Client',
                        border: OutlineInputBorder(),
                      ),
                      items: _clients.map((client) {
                        return DropdownMenuItem<String>(
                          value: client['id'] as String,
                          child: Text('${client['name']} (${client['email']})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedClientId = value);
                      },
                    ),
                  const SizedBox(height: 24),

                  // Weeks section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weeks (${_weeks.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: _addWeek,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Week'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Weeks list
                  ...List.generate(_weeks.length, (index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Week ${_weeks[index].weekNumber}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeWeek(index),
                                  tooltip: 'Remove Week',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            WorkoutWeekEditor(
                              week: _weeks[index],
                              onWeekChanged: (updatedWeek) {
                                _updateWeek(index, updatedWeek);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Save button at bottom
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _savePlan,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save Workout Plan'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
