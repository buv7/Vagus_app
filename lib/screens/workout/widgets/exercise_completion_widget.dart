import 'package:flutter/material.dart';
import '../../../models/workout/exercise.dart';

/// Exercise completion tracking widget for workout sessions
class ExerciseCompletionWidget extends StatefulWidget {
  final Exercise exercise;
  final ExerciseCompletionData? completionData;
  final VoidCallback onComplete;
  final Function(ExerciseCompletionData) onDataChanged;
  final VoidCallback? onViewHistory;
  final VoidCallback? onRequestSubstitution;
  final VoidCallback? onPlayDemo;
  final bool isSessionActive;

  const ExerciseCompletionWidget({
    super.key,
    required this.exercise,
    this.completionData,
    required this.onComplete,
    required this.onDataChanged,
    this.onViewHistory,
    this.onRequestSubstitution,
    this.onPlayDemo,
    this.isSessionActive = false,
  });

  @override
  State<ExerciseCompletionWidget> createState() =>
      _ExerciseCompletionWidgetState();
}

class _ExerciseCompletionWidgetState extends State<ExerciseCompletionWidget> {
  late List<bool> _completedSets;
  late List<TextEditingController> _weightControllers;
  late List<TextEditingController> _repsControllers;
  int _rpeRating = 5;
  int _formRating = 3;
  int _difficultyRating = 3;
  final TextEditingController _notesController = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final sets = widget.exercise.sets ?? 3;
    _completedSets = List.filled(sets, false);
    _weightControllers = List.generate(
      sets,
      (i) => TextEditingController(
        text: widget.exercise.weight?.toString() ?? '',
      ),
    );
    _repsControllers = List.generate(
      sets,
      (i) => TextEditingController(
        text: widget.exercise.reps ?? '',
      ),
    );

    // Load existing completion data if available
    if (widget.completionData != null) {
      _loadCompletionData(widget.completionData!);
    }

    _notesController.text = widget.completionData?.notes ?? '';
    _rpeRating = widget.completionData?.rpeRating ?? 5;
    _formRating = widget.completionData?.formRating ?? 3;
    _difficultyRating = widget.completionData?.difficultyRating ?? 3;
  }

  void _loadCompletionData(ExerciseCompletionData data) {
    // Parse completed sets from data
    final completedCount = data.completedSets;
    for (int i = 0; i < completedCount && i < _completedSets.length; i++) {
      _completedSets[i] = true;
    }

    // Load weight and reps data if available
    if (data.weightUsed > 0) {
      for (var controller in _weightControllers) {
        controller.text = data.weightUsed.toString();
      }
    }

    if (data.completedReps.isNotEmpty) {
      for (var controller in _repsControllers) {
        controller.text = data.completedReps;
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _weightControllers) {
      controller.dispose();
    }
    for (var controller in _repsControllers) {
      controller.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  void _toggleSetCompletion(int setIndex) {
    setState(() {
      _completedSets[setIndex] = !_completedSets[setIndex];
    });
    _emitDataChange();
  }

  void _emitDataChange() {
    final completedCount = _completedSets.where((c) => c).length;
    final avgWeight = _calculateAverageWeight();
    final avgReps = _calculateAverageReps();

    final data = ExerciseCompletionData(
      exerciseId: widget.exercise.id!,
      completedSets: completedCount,
      completedReps: avgReps,
      weightUsed: avgWeight,
      rpeRating: _rpeRating,
      formRating: _formRating,
      difficultyRating: _difficultyRating,
      notes: _notesController.text.trim(),
      synced: false,
      completedAt: DateTime.now(),
    );

    widget.onDataChanged(data);

    // Check if exercise is fully complete
    if (completedCount == widget.exercise.sets) {
      widget.onComplete();
    }
  }

  double _calculateAverageWeight() {
    final weights = _weightControllers
        .map((c) => double.tryParse(c.text) ?? 0)
        .where((w) => w > 0)
        .toList();

    if (weights.isEmpty) return 0;
    return weights.reduce((a, b) => a + b) / weights.length;
  }

  String _calculateAverageReps() {
    final reps = _repsControllers
        .map((c) => int.tryParse(c.text) ?? 0)
        .where((r) => r > 0)
        .toList();

    if (reps.isEmpty) return '0';
    final avg = reps.reduce((a, b) => a + b) / reps.length;
    return avg.round().toString();
  }

  bool get _isComplete {
    return _completedSets.where((c) => c).length == widget.exercise.sets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = _isComplete;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isComplete ? 1 : 2,
      color: isComplete
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: Column(
        children: [
          // Exercise header
          _buildHeader(theme, isComplete),

          // Set tracking
          if (widget.isSessionActive) _buildSetTracking(theme),

          // Expanded details
          if (_isExpanded && widget.isSessionActive) _buildExpandedDetails(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isComplete) {
    return InkWell(
      onTap: widget.isSessionActive
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Completion indicator
            if (widget.isSessionActive)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isComplete
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  isComplete ? Icons.check : Icons.fitness_center,
                  color: isComplete
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (widget.isSessionActive) const SizedBox(width: 16),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exercise.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration:
                          isComplete ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildExerciseDetails(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Quick actions
            if (widget.isSessionActive) _buildQuickActions(theme),
          ],
        ),
      ),
    );
  }

  String _buildExerciseDetails() {
    final parts = <String>[];

    if (widget.exercise.sets != null) {
      parts.add('${widget.exercise.sets} sets');
    }
    if (widget.exercise.reps != null) {
      parts.add('${widget.exercise.reps} reps');
    }
    if (widget.exercise.weight != null) {
      parts.add('${widget.exercise.weight} kg');
    }
    if (widget.exercise.rest != null) {
      parts.add('${widget.exercise.rest}s rest');
    }
    if (widget.exercise.tempo != null) {
      parts.add('Tempo: ${widget.exercise.tempo}');
    }
    if (widget.exercise.rir != null) {
      parts.add('RIR: ${widget.exercise.rir}');
    }

    return parts.join(' • ');
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Demo video
        if (widget.onPlayDemo != null)
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Play demo',
            onPressed: widget.onPlayDemo,
            color: theme.colorScheme.primary,
          ),

        // History
        if (widget.onViewHistory != null)
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View history',
            onPressed: widget.onViewHistory,
            color: theme.colorScheme.secondary,
          ),

        // Expand/collapse
        IconButton(
          icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
        ),
      ],
    );
  }

  Widget _buildSetTracking(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sets',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            widget.exercise.sets ?? 0,
            (index) => _buildSetRow(index, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int setIndex, ThemeData theme) {
    final isCompleted = _completedSets[setIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Set checkbox
          Checkbox(
            value: isCompleted,
            onChanged: (value) => _toggleSetCompletion(setIndex),
          ),
          Text('Set ${setIndex + 1}'),
          const SizedBox(width: 16),

          // Weight input
          SizedBox(
            width: 80,
            child: TextField(
              controller: _weightControllers[setIndex],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (value) => _emitDataChange(),
            ),
          ),
          const SizedBox(width: 16),

          // Reps input
          SizedBox(
            width: 80,
            child: TextField(
              controller: _repsControllers[setIndex],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (value) => _emitDataChange(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),

          // RPE Rating
          _buildRatingSlider(
            label: 'RPE (Rate of Perceived Exertion)',
            value: _rpeRating,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) {
              setState(() => _rpeRating = value.round());
              _emitDataChange();
            },
            theme: theme,
          ),

          const SizedBox(height: 16),

          // Form Rating
          _buildRatingSlider(
            label: 'Form Quality',
            value: _formRating,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) {
              setState(() => _formRating = value.round());
              _emitDataChange();
            },
            theme: theme,
          ),

          const SizedBox(height: 16),

          // Difficulty Rating
          _buildRatingSlider(
            label: 'Difficulty',
            value: _difficultyRating,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) {
              setState(() => _difficultyRating = value.round());
              _emitDataChange();
            },
            theme: theme,
          ),

          const SizedBox(height: 16),

          // Notes
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'How did this exercise feel?',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _emitDataChange(),
          ),

          const SizedBox(height: 16),

          // Request substitution button
          if (widget.onRequestSubstitution != null)
            TextButton.icon(
              onPressed: widget.onRequestSubstitution,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Request substitution'),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              '$value/$max',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Exercise completion data model
class ExerciseCompletionData {
  final String exerciseId;
  final int completedSets;
  final String completedReps;
  final double weightUsed;
  final int? rpeRating;
  final int? formRating;
  final int? difficultyRating;
  final String? notes;
  final bool synced;
  final DateTime completedAt;

  ExerciseCompletionData({
    required this.exerciseId,
    required this.completedSets,
    required this.completedReps,
    required this.weightUsed,
    this.rpeRating,
    this.formRating,
    this.difficultyRating,
    this.notes,
    required this.synced,
    required this.completedAt,
  });

  ExerciseCompletionData copyWith({
    String? exerciseId,
    int? completedSets,
    String? completedReps,
    double? weightUsed,
    int? rpeRating,
    int? formRating,
    int? difficultyRating,
    String? notes,
    bool? synced,
    DateTime? completedAt,
  }) {
    return ExerciseCompletionData(
      exerciseId: exerciseId ?? this.exerciseId,
      completedSets: completedSets ?? this.completedSets,
      completedReps: completedReps ?? this.completedReps,
      weightUsed: weightUsed ?? this.weightUsed,
      rpeRating: rpeRating ?? this.rpeRating,
      formRating: formRating ?? this.formRating,
      difficultyRating: difficultyRating ?? this.difficultyRating,
      notes: notes ?? this.notes,
      synced: synced ?? this.synced,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exercise_id': exerciseId,
      'completed_sets': completedSets,
      'completed_reps': completedReps,
      'weight_used': weightUsed,
      'rpe_rating': rpeRating,
      'form_rating': formRating,
      'difficulty_rating': difficultyRating,
      'notes': notes,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  factory ExerciseCompletionData.fromMap(Map<String, dynamic> map) {
    return ExerciseCompletionData(
      exerciseId: map['exercise_id'] as String,
      completedSets: map['completed_sets'] as int,
      completedReps: map['completed_reps'] as String,
      weightUsed: (map['weight_used'] as num).toDouble(),
      rpeRating: map['rpe_rating'] as int?,
      formRating: map['form_rating'] as int?,
      difficultyRating: map['difficulty_rating'] as int?,
      notes: map['notes'] as String?,
      synced: false,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }

  /// Create initial empty completion data for an exercise
  factory ExerciseCompletionData.initial(dynamic exercise) {
    return ExerciseCompletionData(
      exerciseId: exercise.id ?? '',
      completedSets: 0,
      completedReps: '',
      weightUsed: 0,
      synced: false,
      completedAt: DateTime.now(),
    );
  }
}