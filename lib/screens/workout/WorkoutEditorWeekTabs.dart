import 'package:flutter/material.dart';
import 'WorkoutDayEditor.dart';

class WorkoutEditorWeekTabs extends StatefulWidget {
  final int totalWeeks;
  final List<Map<String, dynamic>> weekData;
  final Function(int) onWeekChanged;
  final int currentWeek;

  const WorkoutEditorWeekTabs({
    super.key,
    required this.totalWeeks,
    required this.weekData,
    required this.onWeekChanged,
    required this.currentWeek,
  });

  @override
  State<WorkoutEditorWeekTabs> createState() => _WorkoutEditorWeekTabsState();
}

class _WorkoutEditorWeekTabsState extends State<WorkoutEditorWeekTabs> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.totalWeeks,
            itemBuilder: (context, index) {
              final isSelected = index == widget.currentWeek;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('Week ${index + 1}'),
                  selected: isSelected,
                  onSelected: (_) => widget.onWeekChanged(index),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Editing Week ${widget.currentWeek + 1}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        WorkoutDayEditor(
          days: widget.weekData[widget.currentWeek]['days'],
          onDaysUpdated: (updatedDays) {
            widget.weekData[widget.currentWeek]['days'] = updatedDays;
          },
        ),
      ],
    );
  }
}
