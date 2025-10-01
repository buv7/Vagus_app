import 'package:flutter/material.dart';
import '../../models/workout/workout_plan.dart';
import 'workout_day_editor.dart';

/// Widget for editing a single workout week
class WorkoutWeekEditor extends StatefulWidget {
  final WorkoutWeek week;
  final Function(WorkoutWeek) onWeekChanged;

  const WorkoutWeekEditor({
    super.key,
    required this.week,
    required this.onWeekChanged,
  });

  @override
  State<WorkoutWeekEditor> createState() => _WorkoutWeekEditorState();
}

class _WorkoutWeekEditorState extends State<WorkoutWeekEditor> {
  void _addDay() {
    final updatedDays = [
      ...widget.week.days,
      WorkoutDay(
        weekId: widget.week.id ?? '',
        dayNumber: widget.week.days.length + 1,
        label: 'Day ${widget.week.days.length + 1}',
        exercises: [],
      ),
    ];

    widget.onWeekChanged(widget.week.copyWith(days: updatedDays));
  }

  void _removeDay(int index) {
    if (widget.week.days.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Week must have at least one day')),
      );
      return;
    }

    final updatedDays = List<WorkoutDay>.from(widget.week.days);
    updatedDays.removeAt(index);

    // Renumber days
    for (int i = 0; i < updatedDays.length; i++) {
      updatedDays[i] = updatedDays[i].copyWith(dayNumber: i + 1);
    }

    widget.onWeekChanged(widget.week.copyWith(days: updatedDays));
  }

  void _updateDay(int index, WorkoutDay day) {
    final updatedDays = List<WorkoutDay>.from(widget.week.days);
    updatedDays[index] = day;

    widget.onWeekChanged(widget.week.copyWith(days: updatedDays));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Days list
        ...List.generate(widget.week.days.length, (index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    widget.week.days[index].label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${widget.week.days[index].exercises.length} exercises',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeDay(index),
                    tooltip: 'Remove Day',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: WorkoutDayEditor(
                    day: widget.week.days[index],
                    onDayChanged: (updatedDay) {
                      _updateDay(index, updatedDay);
                    },
                  ),
                ),
              ],
            ),
          );
        }),

        // Add day button
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _addDay,
          icon: const Icon(Icons.add),
          label: const Text('Add Day'),
        ),
      ],
    );
  }
}
