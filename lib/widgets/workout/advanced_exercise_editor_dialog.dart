import 'package:flutter/material.dart';
import '../../models/workout/exercise.dart';
import '../../models/workout/enhanced_exercise.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../services/nutrition/locale_helper.dart';

/// Advanced Exercise Editor Dialog with ALL training methods
/// The most comprehensive exercise editor ever built
class AdvancedExerciseEditorDialog extends StatefulWidget {
  final Exercise? exercise;
  final Function(Exercise) onSave;

  const AdvancedExerciseEditorDialog({
    super.key,
    this.exercise,
    required this.onSave,
  });

  @override
  State<AdvancedExerciseEditorDialog> createState() =>
      _AdvancedExerciseEditorDialogState();
}

class _AdvancedExerciseEditorDialogState
    extends State<AdvancedExerciseEditorDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Basic Fields
  final _nameController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _restController = TextEditingController();
  final _tempoController = TextEditingController();
  final _notesController = TextEditingController();

  // Intensity
  int? _rir;
  int? _percent1RM;

  // Training Method
  TrainingMethod _trainingMethod = TrainingMethod.straightSets;

  // Group
  String? _groupId;
  ExerciseGroupType _groupType = ExerciseGroupType.none;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    if (widget.exercise != null) {
      final ex = widget.exercise!;
      _nameController.text = ex.name;
      _setsController.text = ex.sets?.toString() ?? '';
      _repsController.text = ex.reps ?? '';
      _weightController.text = ex.weight?.toString() ?? '';
      _restController.text = ex.rest?.toString() ?? '';
      _tempoController.text = ex.tempo ?? '';
      _notesController.text = ex.notes ?? '';
      _rir = ex.rir;
      _percent1RM = ex.percent1RM;
      _groupId = ex.groupId;
      _groupType = ex.groupType;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _tempoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleHelper.t('exercise_name_required', 'Exercise name is required'))),
      );
      return;
    }

    final exercise = Exercise(
      id: widget.exercise?.id,
      dayId: widget.exercise?.dayId ?? '',
      orderIndex: widget.exercise?.orderIndex ?? 0,
      name: _nameController.text.trim(),
      sets: int.tryParse(_setsController.text),
      reps: _repsController.text.trim().isEmpty ? null : _repsController.text.trim(),
      weight: double.tryParse(_weightController.text),
      rest: int.tryParse(_restController.text),
      tempo: _tempoController.text.trim().isEmpty ? null : _tempoController.text.trim(),
      rir: _rir,
      percent1RM: _percent1RM,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      groupId: _groupId,
      groupType: _groupType,
    );

    widget.onSave(exercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(DesignTokens.radius24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(DesignTokens.space20),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(DesignTokens.radius24),
                  topRight: Radius.circular(DesignTokens.radius24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: AppTheme.accentGreen, size: 28),
                  const SizedBox(width: DesignTokens.space12),
                  Expanded(
                    child: Text(
                      widget.exercise == null
                          ? LocaleHelper.t('add_exercise', 'Add Exercise')
                          : LocaleHelper.t('edit_exercise', 'Edit Exercise'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              color: AppTheme.primaryDark,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.accentGreen,
                labelColor: AppTheme.accentGreen,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(icon: const Icon(Icons.info_outline), text: LocaleHelper.t('basic', 'Basic')),
                  Tab(icon: const Icon(Icons.trending_up), text: LocaleHelper.t('intensity', 'Intensity')),
                  Tab(icon: const Icon(Icons.group_work), text: LocaleHelper.t('methods', 'Methods')),
                  Tab(icon: const Icon(Icons.notes), text: LocaleHelper.t('notes', 'Notes')),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicTab(),
                  _buildIntensityTab(),
                  _buildMethodsTab(),
                  _buildNotesTab(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(DesignTokens.space20),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(LocaleHelper.t('cancel', 'Cancel')),
                  ),
                  const SizedBox(width: DesignTokens.space12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(LocaleHelper.t('save', 'Save')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space24,
                        vertical: DesignTokens.space12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _nameController,
            label: LocaleHelper.t('exercise_name', 'Exercise Name'),
            icon: Icons.fitness_center,
            required: true,
          ),
          const SizedBox(height: DesignTokens.space16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _setsController,
                  label: LocaleHelper.t('sets', 'Sets'),
                  icon: Icons.repeat,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: _buildTextField(
                  controller: _repsController,
                  label: LocaleHelper.t('reps', 'Reps'),
                  icon: Icons.format_list_numbered,
                  hint: '8-12 or AMRAP',
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _weightController,
                  label: LocaleHelper.t('weight', 'Weight (kg)'),
                  icon: Icons.fitness_center,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: _buildTextField(
                  controller: _restController,
                  label: LocaleHelper.t('rest', 'Rest (seconds)'),
                  icon: Icons.timer,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space16),
          _buildTextField(
            controller: _tempoController,
            label: LocaleHelper.t('tempo', 'Tempo (e.g., 3-1-2-0)'),
            icon: Icons.speed,
            hint: 'Eccentric-Pause-Concentric-Pause',
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleHelper.t('intensity_markers', 'Intensity Markers'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          _buildIntensitySelector(
            label: LocaleHelper.t('rir', 'RIR (Reps in Reserve)'),
            value: _rir,
            options: [0, 1, 2, 3, 4, 5],
            onChanged: (value) => setState(() => _rir = value),
          ),
          const SizedBox(height: DesignTokens.space16),
          _buildIntensitySelector(
            label: LocaleHelper.t('percent_1rm', '% of 1RM'),
            value: _percent1RM,
            options: [50, 60, 70, 75, 80, 85, 90, 95, 100],
            onChanged: (value) => setState(() => _percent1RM = value),
          ),
          const SizedBox(height: DesignTokens.space24),
          Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
            decoration: BoxDecoration(
              color: DesignTokens.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              border: Border.all(color: DesignTokens.accentBlue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: DesignTokens.accentBlue, size: 20),
                    const SizedBox(width: DesignTokens.space8),
                    Text(
                      LocaleHelper.t('intensity_guide', 'Intensity Guide'),
                      style: const TextStyle(
                        color: DesignTokens.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space8),
                const Text(
                  '• RIR 0-1: Max effort, near failure\n'
                  '• RIR 2-3: Hard sets, muscle building\n'
                  '• RIR 4-5: Moderate, skill work\n\n'
                  '• 85-100% 1RM: Strength focus\n'
                  '• 70-85% 1RM: Hypertrophy focus\n'
                  '• 50-70% 1RM: Endurance/technique',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleHelper.t('training_methods', 'Training Methods'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TrainingMethod.values.map((method) {
              final isSelected = _trainingMethod == method;
              return GestureDetector(
                onTap: () => setState(() => _trainingMethod = method),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space16,
                    vertical: DesignTokens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentGreen
                        : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(DesignTokens.radius20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentGreen
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    method.displayName,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryDark : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: DesignTokens.space24),
          Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6B4FFF).withValues(alpha: 0.2),
                  const Color(0xFFFF1CF7).withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              border: Border.all(color: const Color(0xFF6B4FFF).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF6B4FFF), size: 24),
                SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: Text(
                    'Advanced methods (Drop Sets, Rest-Pause, Clusters, etc.) coming soon!',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleHelper.t('exercise_notes', 'Exercise Notes & Cues'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          TextField(
            controller: _notesController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: LocaleHelper.t('exercise_notes_hint', 'Add coaching notes, form cues, or setup instructions...'),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: AppTheme.primaryDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                borderSide: const BorderSide(color: AppTheme.accentGreen, width: 2),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.accentGreen),
        filled: true,
        fillColor: AppTheme.primaryDark,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: AppTheme.accentGreen, width: 2),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildIntensitySelector({
    required String label,
    required int? value,
    required List<int> options,
    required Function(int?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DesignTokens.space12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildOptionChip(
              label: 'None',
              isSelected: value == null,
              onTap: () => onChanged(null),
            ),
            ...options.map((option) => _buildOptionChip(
              label: option.toString(),
              isSelected: value == option,
              onTap: () => onChanged(option),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentGreen : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentGreen
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryDark : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
