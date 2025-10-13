import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../data/exercise_library_data.dart';
import '../../models/workout/exercise.dart';

class ExercisePickerDialog extends StatefulWidget {
  final Function(Exercise) onExerciseSelected;

  const ExercisePickerDialog({
    super.key,
    required this.onExerciseSelected,
  });

  @override
  State<ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends State<ExercisePickerDialog> {
  String _searchQuery = '';
  String _selectedEquipment = 'All';
  String? _selectedMuscleGroup;

  List<ExerciseTemplate> get _filteredExercises {
    List<ExerciseTemplate> exercises = ExerciseLibraryData.getAllExercises();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      exercises = ExerciseLibraryData.searchExercises(_searchQuery);
    }

    // Apply equipment filter
    if (_selectedEquipment != 'All') {
      exercises = exercises.where((e) => e.equipment == _selectedEquipment).toList();
    }

    // Apply muscle group filter
    if (_selectedMuscleGroup != null) {
      exercises = exercises.where((e) => e.muscleGroup == _selectedMuscleGroup).toList();
    }

    return exercises;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        height: 700,
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: DesignTokens.glassBorder),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: DesignTokens.accentGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Exercise',
                    style: TextStyle(
                      fontSize: 20,
                      color: DesignTokens.neutralWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: DesignTokens.textSecondary),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                style: const TextStyle(color: DesignTokens.neutralWhite),
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  hintStyle: const TextStyle(color: DesignTokens.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: DesignTokens.textSecondary),
                  filled: true,
                  fillColor: DesignTokens.primaryDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DesignTokens.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DesignTokens.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DesignTokens.accentGreen),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),

            // Equipment Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ExerciseLibraryData.equipmentTypes.map((equipment) {
                  final isSelected = _selectedEquipment == equipment;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(equipment),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedEquipment = equipment);
                      },
                      backgroundColor: DesignTokens.primaryDark,
                      selectedColor: DesignTokens.accentGreen.withValues(alpha: 0.3),
                      labelStyle: TextStyle(
                        color: isSelected ? DesignTokens.accentGreen : DesignTokens.textSecondary,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: isSelected ? DesignTokens.accentGreen : DesignTokens.glassBorder,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Muscle Group Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // "All" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All Groups'),
                      selected: _selectedMuscleGroup == null,
                      onSelected: (selected) {
                        setState(() => _selectedMuscleGroup = null);
                      },
                      backgroundColor: DesignTokens.primaryDark,
                      selectedColor: DesignTokens.accentBlue.withValues(alpha: 0.3),
                      labelStyle: TextStyle(
                        color: _selectedMuscleGroup == null ? DesignTokens.accentBlue : DesignTokens.textSecondary,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: _selectedMuscleGroup == null ? DesignTokens.accentBlue : DesignTokens.glassBorder,
                      ),
                    ),
                  ),
                  ...ExerciseLibraryData.muscleGroups.map((group) {
                    final isSelected = _selectedMuscleGroup == group;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(group),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedMuscleGroup = group);
                        },
                        backgroundColor: DesignTokens.primaryDark,
                        selectedColor: DesignTokens.accentBlue.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          color: isSelected ? DesignTokens.accentBlue : DesignTokens.textSecondary,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: isSelected ? DesignTokens.accentBlue : DesignTokens.glassBorder,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Exercise count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredExercises.length} exercises',
                  style: const TextStyle(
                    fontSize: 13,
                    color: DesignTokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Exercise List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredExercises.length,
                itemBuilder: (context, index) {
                  final exerciseTemplate = _filteredExercises[index];
                  return _buildExerciseCard(exerciseTemplate);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseTemplate template) {
    return InkWell(
      onTap: () {
        // Create Exercise from template
        final exercise = Exercise(
          id: null,
          dayId: '', // Will be set by the caller
          name: template.name,
          sets: template.defaultSets,
          reps: template.defaultReps,
          weight: null,
          rest: 60,
          notes: '',
          orderIndex: 0,
        );

        widget.onExerciseSelected(exercise);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Row(
          children: [
            // Icon based on equipment
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getEquipmentColor(template.equipment).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getEquipmentIcon(template.equipment),
                color: _getEquipmentColor(template.equipment),
                size: 20,
              ),
            ),

            const SizedBox(width: 16),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 15,
                      color: DesignTokens.neutralWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildTag(template.muscleGroup, DesignTokens.accentBlue),
                      _buildTag(template.equipment, DesignTokens.textSecondary),
                    ],
                  ),
                ],
              ),
            ),

            // Default values
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${template.defaultSets} sets',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DesignTokens.textSecondary,
                  ),
                ),
                Text(
                  '${template.defaultReps} reps',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Add icon
            const Icon(
              Icons.add_circle,
              color: DesignTokens.accentGreen,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment) {
      case 'Barbell':
        return Icons.fitness_center;
      case 'Dumbbell':
        return Icons.fitness_center;
      case 'Cable':
        return Icons.settings_input_hdmi;
      case 'Machine':
        return Icons.settings;
      case 'Bodyweight':
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getEquipmentColor(String equipment) {
    switch (equipment) {
      case 'Barbell':
        return DesignTokens.accentOrange;
      case 'Dumbbell':
        return DesignTokens.accentGreen;
      case 'Cable':
        return DesignTokens.accentPurple;
      case 'Machine':
        return DesignTokens.accentBlue;
      case 'Bodyweight':
        return const Color(0xFFFFD700); // Gold
      default:
        return DesignTokens.textSecondary;
    }
  }
}
