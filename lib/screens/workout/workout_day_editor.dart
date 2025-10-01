import 'package:flutter/material.dart';
import '../../models/workout/workout_plan.dart';
import '../../models/workout/exercise.dart';

/// Widget for editing a single workout day
class WorkoutDayEditor extends StatefulWidget {
  final WorkoutDay day;
  final Function(WorkoutDay) onDayChanged;

  const WorkoutDayEditor({
    super.key,
    required this.day,
    required this.onDayChanged,
  });

  @override
  State<WorkoutDayEditor> createState() => _WorkoutDayEditorState();
}

class _WorkoutDayEditorState extends State<WorkoutDayEditor> {
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.day.label);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _addExercise() {
    final updatedExercises = [
      ...widget.day.exercises,
      Exercise(
        dayId: widget.day.id ?? '',
        name: '',
        sets: 3,
        reps: '10',
        orderIndex: widget.day.exercises.length,
      ),
    ];

    widget.onDayChanged(widget.day.copyWith(exercises: updatedExercises));
  }

  void _removeExercise(int index) {
    final updatedExercises = List<Exercise>.from(widget.day.exercises);
    updatedExercises.removeAt(index);

    // Re-index exercises
    for (int i = 0; i < updatedExercises.length; i++) {
      updatedExercises[i] = updatedExercises[i].copyWith(orderIndex: i);
    }

    widget.onDayChanged(widget.day.copyWith(exercises: updatedExercises));
  }

  void _updateExercise(int index, Exercise exercise) {
    final updatedExercises = List<Exercise>.from(widget.day.exercises);
    updatedExercises[index] = exercise;

    widget.onDayChanged(widget.day.copyWith(exercises: updatedExercises));
  }

  void _updateLabel() {
    widget.onDayChanged(widget.day.copyWith(label: _labelController.text));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day label
        TextField(
          controller: _labelController,
          decoration: const InputDecoration(
            labelText: 'Day Label',
            hintText: 'e.g., Upper Body, Legs, Rest',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => _updateLabel(),
        ),
        const SizedBox(height: 16),

        // Exercises section
        if (widget.day.exercises.isNotEmpty) ...[
          Text(
            'Exercises',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
        ],

        // Exercises list
        ...List.generate(widget.day.exercises.length, (index) {
          final exercise = widget.day.exercises[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Exercise ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.red,
                        onPressed: () => _removeExercise(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Exercise name
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Exercise Name',
                      hintText: 'e.g., Bench Press, Squats',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    controller: TextEditingController(text: exercise.name),
                    onChanged: (value) {
                      _updateExercise(
                        index,
                        exercise.copyWith(name: value),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Sets, Reps, Weight
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Sets',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                              text: exercise.sets.toString()),
                          onChanged: (value) {
                            _updateExercise(
                              index,
                              exercise.copyWith(
                                  sets: int.tryParse(value) ?? exercise.sets),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Reps',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.text,
                          controller: TextEditingController(
                              text: exercise.reps ?? ''),
                          onChanged: (value) {
                            _updateExercise(
                              index,
                              exercise.copyWith(reps: value),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          controller: TextEditingController(
                            text: exercise.weight?.toStringAsFixed(1) ?? '',
                          ),
                          onChanged: (value) {
                            _updateExercise(
                              index,
                              exercise.copyWith(
                                weight: double.tryParse(value) ?? exercise.weight,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // RIR and Rest
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'RIR (Reps in Reserve)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                            text: exercise.rir?.toString() ?? '',
                          ),
                          onChanged: (value) {
                            _updateExercise(
                              index,
                              exercise.copyWith(
                                rir: int.tryParse(value),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Rest (sec)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                            text: exercise.rest?.toString() ?? '',
                          ),
                          onChanged: (value) {
                            _updateExercise(
                              index,
                              exercise.copyWith(
                                rest: int.tryParse(value),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Notes
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional notes or instructions',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                    controller: TextEditingController(text: exercise.notes ?? ''),
                    onChanged: (value) {
                      _updateExercise(
                        index,
                        exercise.copyWith(notes: value.isEmpty ? null : value),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }),

        // Add exercise button
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }
}
