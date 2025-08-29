import 'package:flutter/material.dart';
import 'exercise_entry_block.dart';

class WorkoutDayEditor extends StatefulWidget {
  final List<Map<String, dynamic>> days;
  final Function(List<Map<String, dynamic>>) onDaysUpdated;

  const WorkoutDayEditor({
    super.key,
    required this.days,
    required this.onDaysUpdated,
  });

  @override
  State<WorkoutDayEditor> createState() => _WorkoutDayEditorState();
}

class _WorkoutDayEditorState extends State<WorkoutDayEditor> {
  List<Map<String, dynamic>> _localDays = [];

  @override
  void initState() {
    super.initState();
    _localDays = List.from(widget.days);
  }

  void _addDay() {
    setState(() {
      _localDays.add({
        'label': 'New Day',
        'exercises': [],
      });
    });
    widget.onDaysUpdated(_localDays);
  }

  void _removeDay(int index) {
    setState(() {
      _localDays.removeAt(index);
    });
    widget.onDaysUpdated(_localDays);
  }

  void _updateDayLabel(int index, String label) {
    setState(() {
      _localDays[index]['label'] = label;
    });
    widget.onDaysUpdated(_localDays);
  }

  void _updateExercises(int dayIndex, List<Map<String, dynamic>> updated) {
    setState(() {
      _localDays[dayIndex]['exercises'] = updated;
    });
    widget.onDaysUpdated(_localDays);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _localDays.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Day Label'),
                    onChanged: (val) => _updateDayLabel(i, val),
                    controller: TextEditingController(text: _localDays[i]['label']),
                  ),
                  const SizedBox(height: 6),
                  ExerciseEntryBlock(
                    exercises: _localDays[i]['exercises'],
                    onExercisesUpdated: (exList) => _updateExercises(i, exList),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeDay(i),
                    ),
                  )
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _addDay,
          icon: const Icon(Icons.add),
          label: const Text('Add Day'),
        )
      ],
    );
  }
}
