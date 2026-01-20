import 'package:flutter/material.dart';
import '../../models/workout/exercise.dart';
import '../../models/workout/enhanced_exercise.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../services/workout/workout_knowledge_service.dart';
import 'dart:convert';

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
  String? _customTrainingMethod; // Store custom training method string when enum is unknown

  // Group
  String? _groupId;
  ExerciseGroupType _groupType = ExerciseGroupType.none;
  
  // Knowledge base data
  String? _knowledgeExerciseId; // Exercise ID from knowledge base
  String? _knowledgeShortDesc; // Extracted from notes
  String? _selectedIntensifier; // Intensifier name from knowledge base
  String? _selectedIntensifierId; // Intensifier ID (optional)
  
  // Recommended intensifiers
  List<Map<String, dynamic>> _recommendedIntensifiers = [];
  bool _loadingRecommendations = false;
  
  // Full knowledge details
  Map<String, dynamic>? _knowledgeDetails;
  bool _loadingKnowledgeDetails = false;
  
  // Intensifier details (Phase 4.5)
  Map<String, dynamic>? _selectedIntensifierDetails;
  bool _loadingIntensifierDetails = false;
  
  // Phase 4.6B: Intensifier apply scope
  String _intensifierApplyScope = 'last_set'; // 'off' | 'last_set' | 'all_sets'

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
      _rir = ex.rir;
      _percent1RM = ex.percent1RM;
      _groupId = ex.groupId;
      _groupType = ex.groupType;
      
      // Parse notes for knowledge base data
      _parseNotesForKnowledge(ex.notes);
      
      // Load training method (handle custom values)
      if (ex.trainingMethod != null) {
        if (ex.trainingMethod == TrainingMethod.unknown) {
          // Custom value - get raw string from getter
          _trainingMethod = TrainingMethod.unknown;
          _customTrainingMethod = ex.trainingMethodRawForDisplay;
        } else {
          _trainingMethod = ex.trainingMethod!;
          _customTrainingMethod = null;
        }
      }
      
      // Load recommended intensifiers and knowledge details if we have knowledge_exercise_id
      if (_knowledgeExerciseId != null) {
        _loadRecommendedIntensifiers();
        _loadKnowledgeDetails();
      }
      
      // Load intensifier details if we have intensifier_id (Phase 4.5)
      if (_selectedIntensifierId != null) {
        _loadIntensifierDetails();
      } else if (_selectedIntensifier != null) {
        // Try to find by name if ID is missing (best effort)
        _loadIntensifierDetailsByName();
      }
    } else {
      // For new exercises, check if notes already has knowledge_exercise_id
      if (widget.exercise?.notes != null) {
        _parseNotesForKnowledge(widget.exercise!.notes);
        if (_knowledgeExerciseId != null) {
          _loadRecommendedIntensifiers();
          _loadKnowledgeDetails();
        }
      }
    }
  }
  
  /// Parse notes to extract knowledge base data (short_desc, intensifier, knowledge_exercise_id)
  void _parseNotesForKnowledge(String? notes) {
    if (notes == null || notes.isEmpty) {
      _notesController.text = '';
      return;
    }
    
    try {
      // Try to parse as JSON
      final jsonData = jsonDecode(notes) as Map<String, dynamic>;
      _knowledgeExerciseId = jsonData['knowledge_exercise_id'] as String?;
      _knowledgeShortDesc = jsonData['knowledge_short_desc'] as String?;
      _selectedIntensifier = jsonData['intensifier'] as String?;
      _selectedIntensifierId = jsonData['intensifier_id'] as String?;
      
      // Phase 4.5: Load intensifier details if rules are stored
      final intensifierRules = jsonData['intensifier_rules'];
      if (intensifierRules != null && _selectedIntensifierId != null) {
        // Rules exist, load full details to display preview
        _loadIntensifierDetails();
      }
      
      // Phase 4.6B: Load apply scope (default to 'last_set' if missing/invalid)
      final applyScope = jsonData['intensifier_apply_scope'] as String?;
      if (applyScope == 'off' || applyScope == 'last_set' || applyScope == 'all_sets') {
        _intensifierApplyScope = applyScope!;
      } else {
        _intensifierApplyScope = 'last_set'; // Safe default
      }
      
      // Extract user notes (if stored separately)
      final userNotes = jsonData['user_notes'] as String?;
      _notesController.text = userNotes ?? '';
    } catch (e) {
      // Not JSON - treat as plain text notes
      // Preserve plain text as user_notes when converting to JSON later
      _notesController.text = notes;
      _knowledgeExerciseId = null;
      _knowledgeShortDesc = null;
      _selectedIntensifier = null;
      _selectedIntensifierId = null;
      _intensifierApplyScope = 'last_set'; // Reset to default
    }
  }
  
  /// Build notes string with knowledge base data
  String _buildNotesString() {
    final userNotes = _notesController.text.trim();
    
    // If we have knowledge data or user notes, create JSON
    if (_knowledgeExerciseId != null || _knowledgeShortDesc != null || _selectedIntensifier != null || userNotes.isNotEmpty || _selectedIntensifierDetails != null) {
      final jsonData = <String, dynamic>{};
      if (_knowledgeExerciseId != null) {
        jsonData['knowledge_exercise_id'] = _knowledgeExerciseId;
      }
      if (_knowledgeShortDesc != null) {
        jsonData['knowledge_short_desc'] = _knowledgeShortDesc;
      }
      if (_selectedIntensifier != null) {
        jsonData['intensifier'] = _selectedIntensifier;
      }
      if (_selectedIntensifierId != null) {
        jsonData['intensifier_id'] = _selectedIntensifierId;
      }
      if (userNotes.isNotEmpty) {
        jsonData['user_notes'] = userNotes;
      }
      
      // Phase 4.5/4.6B: Store intensifier rules and apply scope if available
      // Only store if intensifier is selected (clear if intensifier is cleared)
      if (_selectedIntensifier != null && _selectedIntensifierDetails != null) {
        final intensityRules = _selectedIntensifierDetails!['intensity_rules'];
        if (intensityRules != null) {
          jsonData['intensifier_rules'] = intensityRules;
        }
        // Phase 4.6B: Store apply scope (always store if intensifier exists)
        jsonData['intensifier_apply_scope'] = _intensifierApplyScope;
      } else if (_selectedIntensifier == null) {
        // Phase 4.6B: If intensifier is cleared, also clear rules and scope
        // (Don't add them to jsonData, effectively removing them)
      }
      
      return jsonEncode(jsonData);
    }
    
    // Otherwise return empty or plain text if user notes exist
    return userNotes;
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
      notes: _buildNotesString().isEmpty ? null : _buildNotesString(),
      groupId: _groupId,
      groupType: _groupType,
      trainingMethod: _customTrainingMethod != null ? TrainingMethod.unknown : _trainingMethod,
      trainingMethodRaw: _customTrainingMethod,
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
          // Knowledge base panel (full details)
          if (_knowledgeExerciseId != null)
            _buildFullKnowledgePanel(),
          
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
            children: [
              // Known enum values (excluding unknown)
              ...TrainingMethod.values.where((method) => method != TrainingMethod.unknown).map((method) {
                final isSelected = _trainingMethod == method && _customTrainingMethod == null;
                return GestureDetector(
                  onTap: () => setState(() {
                    _trainingMethod = method;
                    _customTrainingMethod = null;
                  }),
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
              }),
              // Custom value chip (if exists)
              if (_customTrainingMethod != null)
                GestureDetector(
                  onTap: () => _showCustomTrainingMethodDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space16,
                      vertical: DesignTokens.space8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      borderRadius: BorderRadius.circular(DesignTokens.radius20),
                      border: Border.all(
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    child: Text(
                      'Custom: $_customTrainingMethod',
                      style: const TextStyle(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // "Add Custom" chip
              GestureDetector(
                onTap: () => _showCustomTrainingMethodDialog(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space16,
                    vertical: DesignTokens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(DesignTokens.radius20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Text(
                    'Custom...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space24),
          
          // Recommended Intensifiers Section (if knowledge_exercise_id exists)
          if (_knowledgeExerciseId != null) ...[
            _buildRecommendedIntensifiersSection(),
            const SizedBox(height: DesignTokens.space24),
          ],
          
          // Intensifier Picker (Knowledge Base)
          _buildIntensifierPicker(),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Phase 4.5: Intensifier Rules Preview
          if (_selectedIntensifier != null)
            _buildIntensifierRulesPreview(),
          
          // Phase 4.6B: Apply Scope Toggle (only show if intensifier selected or rules exist)
          if (_selectedIntensifier != null || _selectedIntensifierDetails != null) ...[
            const SizedBox(height: DesignTokens.space16),
            _buildApplyScopeControl(),
          ],
          
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
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF6B4FFF), size: 24),
                const SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: Text(
                    _selectedIntensifier != null
                        ? 'Intensifier: $_selectedIntensifier'
                        : 'Advanced methods (Drop Sets, Rest-Pause, Clusters, etc.) available via Knowledge Base!',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
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

  /// Load full knowledge details for the exercise
  Future<void> _loadKnowledgeDetails() async {
    if (_knowledgeExerciseId == null) {
      setState(() {
        _knowledgeDetails = null;
        _loadingKnowledgeDetails = false;
      });
      return;
    }
    
    setState(() {
      _loadingKnowledgeDetails = true;
    });
    
    try {
      final service = WorkoutKnowledgeService.instance;
      final details = await service.getExerciseKnowledgeById(
        _knowledgeExerciseId!,
        language: 'en',
      );
      
      if (mounted) {
        setState(() {
          _knowledgeDetails = details;
          _loadingKnowledgeDetails = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading knowledge details: $e');
      if (mounted) {
        setState(() {
          _knowledgeDetails = null;
          _loadingKnowledgeDetails = false;
        });
      }
    }
  }
  
  /// Append text to user notes
  void _appendToUserNotes(String text) {
    final currentNotes = _notesController.text.trim();
    final newNotes = currentNotes.isEmpty 
        ? text 
        : '$currentNotes\n\n$text';
    _notesController.text = newNotes.trim();
  }
  
  /// Copy coaching block (how-to + top 3 cues + top 3 mistakes)
  void _copyCoachingBlock() {
    if (_knowledgeDetails == null) return;
    
    final howTo = _knowledgeDetails!['how_to'] as String? ?? '';
    final cues = (_knowledgeDetails!['cues'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final mistakes = (_knowledgeDetails!['common_mistakes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    
    final buffer = StringBuffer();
    buffer.writeln('HOW-TO:');
    if (howTo.isNotEmpty) {
      buffer.writeln(howTo);
    } else {
      buffer.writeln('(No how-to available)');
    }
    
    buffer.writeln('\nCUES:');
    if (cues.isNotEmpty) {
      for (final cue in cues.take(3)) {
        buffer.writeln('- $cue');
      }
    } else {
      buffer.writeln('(No cues available)');
    }
    
    buffer.writeln('\nCOMMON MISTAKES:');
    if (mistakes.isNotEmpty) {
      for (final mistake in mistakes.take(3)) {
        buffer.writeln('- $mistake');
      }
    } else {
      buffer.writeln('(No common mistakes available)');
    }
    
    _appendToUserNotes(buffer.toString());
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coaching block copied to notes'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildFullKnowledgePanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Row(
          children: [
            const Icon(Icons.school, color: AppTheme.accentGreen, size: 20),
            const SizedBox(width: DesignTokens.space8),
            const Text(
              'Knowledge Base',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            if (_loadingKnowledgeDetails) ...[
              const SizedBox(width: DesignTokens.space8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accentGreen,
                ),
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: _loadingKnowledgeDetails
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(DesignTokens.space20),
                      child: CircularProgressIndicator(color: AppTheme.accentGreen),
                    ),
                  )
                : _knowledgeDetails == null
                    ? const Text(
                        'Knowledge details unavailable',
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      )
                    : _buildKnowledgeContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildKnowledgeContent() {
    final howTo = _knowledgeDetails!['how_to'] as String? ?? '';
    final cues = (_knowledgeDetails!['cues'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final mistakes = (_knowledgeDetails!['common_mistakes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final equipment = (_knowledgeDetails!['equipment'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final primaryMuscles = (_knowledgeDetails!['primary_muscles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final difficulty = _knowledgeDetails!['difficulty']?.toString() ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Short description
        if (_knowledgeShortDesc != null && _knowledgeShortDesc!.isNotEmpty) ...[
          Text(
            _knowledgeShortDesc!,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: DesignTokens.space16),
        ],
        
        // How-to section
        if (howTo.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'How-to',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _appendToUserNotes(howTo);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('How-to copied to notes'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space8),
          Container(
            padding: const EdgeInsets.all(DesignTokens.space12),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: Text(
              howTo,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
        ],
        
        // Cues section
        if (cues.isNotEmpty) ...[
          const Text(
            'Cues',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cues.map((cue) {
              return InkWell(
                onTap: () {
                  _appendToUserNotes('Cue: $cue');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cue copied: $cue'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space12,
                    vertical: DesignTokens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    border: Border.all(
                      color: DesignTokens.accentBlue.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cue,
                        style: TextStyle(
                          color: DesignTokens.accentBlue,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.copy,
                        size: 14,
                        color: DesignTokens.accentBlue,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: DesignTokens.space16),
        ],
        
        // Common mistakes section
        if (mistakes.isNotEmpty) ...[
          const Text(
            'Common Mistakes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mistakes.map((mistake) {
              return InkWell(
                onTap: () {
                  _appendToUserNotes('Mistake: $mistake');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mistake copied: $mistake'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space12,
                    vertical: DesignTokens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mistake,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.copy,
                        size: 14,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: DesignTokens.space16),
        ],
        
        // Equipment and muscles (optional, nice to have)
        if (equipment.isNotEmpty || primaryMuscles.isNotEmpty) ...[
          const Text(
            'Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (equipment.isNotEmpty)
                ...equipment.map((eq) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space12,
                        vertical: DesignTokens.space8,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.accentPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                        border: Border.all(
                          color: DesignTokens.accentPurple.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        eq,
                        style: TextStyle(
                          color: DesignTokens.accentPurple,
                          fontSize: 12,
                        ),
                      ),
                    )),
              if (primaryMuscles.isNotEmpty)
                ...primaryMuscles.map((muscle) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space12,
                        vertical: DesignTokens.space8,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                        border: Border.all(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        muscle,
                        style: TextStyle(
                          color: DesignTokens.accentBlue,
                          fontSize: 12,
                        ),
                      ),
                    )),
              if (difficulty.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space12,
                    vertical: DesignTokens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    border: Border.all(
                      color: DesignTokens.accentGreen.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    difficulty,
                    style: TextStyle(
                      color: DesignTokens.accentGreen,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.space16),
        ],
        
        // Copy coaching block button
        if (howTo.isNotEmpty || cues.isNotEmpty || mistakes.isNotEmpty) ...[
          const Divider(color: Colors.white24),
          const SizedBox(height: DesignTokens.space8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _copyCoachingBlock,
              icon: const Icon(Icons.content_copy, size: 18),
              label: const Text('Copy Full Coaching Block'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space16,
                  vertical: DesignTokens.space12,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildRecommendedIntensifiersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.accentGreen, size: 20),
            const SizedBox(width: DesignTokens.space8),
            Text(
              'Recommended Intensifiers',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space12),
        if (_loadingRecommendations)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.space20),
              child: CircularProgressIndicator(color: AppTheme.accentGreen),
            ),
          )
        else if (_recommendedIntensifiers.isEmpty)
          Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Text(
              'No recommendations available',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recommendedIntensifiers.map((intensifier) {
              final name = intensifier['name'] as String? ?? '';
              final shortDesc = intensifier['short_desc'] as String? ?? '';
              final fatigueCost = intensifier['fatigue_cost'] as String? ?? 'medium';
              final isSelected = _selectedIntensifier == name;
              
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DesignTokens.space12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accentGreen.withValues(alpha: 0.2)
                      : AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accentGreen
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.accentGreen : Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getFatigueColor(fatigueCost).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _getFatigueColor(fatigueCost).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  fatigueCost.toUpperCase(),
                                  style: TextStyle(
                                    color: _getFatigueColor(fatigueCost),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (shortDesc.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              shortDesc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    ElevatedButton(
                      onPressed: () => _applyIntensifier(intensifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? AppTheme.accentGreen
                            : AppTheme.accentGreen.withValues(alpha: 0.3),
                        foregroundColor: isSelected
                            ? AppTheme.primaryDark
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.space16,
                          vertical: DesignTokens.space8,
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                      child: Text(
                        isSelected ? 'Applied' : 'Apply',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
  

  Widget _buildIntensifierPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intensifier (Knowledge Base)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DesignTokens.space12),
        InkWell(
          onTap: () => _showIntensifierPicker(),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppTheme.accentGreen),
                const SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: Text(
                    _selectedIntensifier ?? 'Select intensifier (optional)',
                    style: TextStyle(
                      color: _selectedIntensifier != null ? Colors.white : Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_selectedIntensifier != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.white60,
                    onPressed: () {
                      setState(() {
                        _selectedIntensifier = null;
                        _selectedIntensifierId = null;
                        _selectedIntensifierDetails = null; // Phase 4.5: Clear details
                        _intensifierApplyScope = 'last_set'; // Phase 4.6B: Reset to default
                      });
                    },
                  ),
                const Icon(Icons.arrow_drop_down, color: Colors.white60),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _showIntensifierPicker() async {
    List<Map<String, dynamic>> intensifiers = [];
    bool isLoading = true;
    
    // Load initial intensifiers
    final service = WorkoutKnowledgeService.instance;
    try {
      intensifiers = await service.searchIntensifiers(
        status: 'approved',
        language: 'en',
        limit: 100,
      );
    } catch (e) {
      // Handle error
    }
    
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String searchQuery = '';
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(DesignTokens.radius24),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.space20),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: DesignTokens.glassBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: AppTheme.accentGreen),
                        const SizedBox(width: DesignTokens.space12),
                        const Expanded(
                          child: Text(
                            'Select Intensifier',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  // Search
                  Padding(
                    padding: const EdgeInsets.all(DesignTokens.space16),
                    child: TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search intensifiers...',
                        hintStyle: const TextStyle(color: Colors.white60),
                        prefixIcon: const Icon(Icons.search, color: Colors.white60),
                        filled: true,
                        fillColor: AppTheme.primaryDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radius12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      onChanged: (value) async {
                        setDialogState(() => isLoading = true);
                        try {
                          intensifiers = await service.searchIntensifiers(
                            query: value.isEmpty ? null : value,
                            status: 'approved',
                            language: 'en',
                            limit: 100,
                          );
                        } catch (e) {
                          // Handle error
                        }
                        setDialogState(() => isLoading = false);
                      },
                    ),
                  ),
                  // List
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
                        : intensifiers.isEmpty
                            ? const Center(
                                child: Text(
                                  'No intensifiers found',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(DesignTokens.space16),
                                itemCount: intensifiers.length,
                                itemBuilder: (context, index) {
                                  final intensifier = intensifiers[index];
                                  final name = intensifier['name'] as String? ?? '';
                                  final shortDesc = intensifier['short_desc'] as String? ?? '';
                                  
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedIntensifier = name;
                                        _selectedIntensifierId = intensifier['id'] as String?;
                                      });
                                      // Phase 4.5: Load intensifier details when selected
                                      if (_selectedIntensifierId != null) {
                                        _loadIntensifierDetails();
                                      }
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
                                      padding: const EdgeInsets.all(DesignTokens.space16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryDark,
                                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                                        border: Border.all(
                                          color: _selectedIntensifier == name
                                              ? AppTheme.accentGreen
                                              : Colors.white.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              color: _selectedIntensifier == name
                                                  ? AppTheme.accentGreen
                                                  : Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (shortDesc.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              shortDesc,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Load recommended intensifiers for the current exercise
  Future<void> _loadRecommendedIntensifiers() async {
    if (_knowledgeExerciseId == null) {
      setState(() {
        _recommendedIntensifiers = [];
        _loadingRecommendations = false;
      });
      return;
    }
    
    setState(() {
      _loadingRecommendations = true;
    });
    
    try {
      final service = WorkoutKnowledgeService.instance;
      
      // First, try to get linked intensifiers from database
      List<Map<String, dynamic>> linkedIntensifiers = await service.getLinkedIntensifiersForExercise(
        _knowledgeExerciseId!,
        language: 'en',
      );
      
      // If we have linked intensifiers, use those (highest priority)
      if (linkedIntensifiers.isNotEmpty) {
        setState(() {
          _recommendedIntensifiers = linkedIntensifiers.take(8).toList();
          _loadingRecommendations = false;
        });
        return;
      }
      
      // Otherwise, generate heuristic suggestions
      // First, get exercise knowledge to determine movement pattern, equipment, etc.
      final exerciseKnowledge = await service.getExerciseKnowledgeById(
        _knowledgeExerciseId!,
        language: 'en',
      );
      
      if (exerciseKnowledge != null) {
        final suggestions = _generateHeuristicIntensifiers(exerciseKnowledge);
        setState(() {
          _recommendedIntensifiers = suggestions;
          _loadingRecommendations = false;
        });
      } else {
        setState(() {
          _recommendedIntensifiers = [];
          _loadingRecommendations = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recommended intensifiers: $e');
      setState(() {
        _recommendedIntensifiers = [];
        _loadingRecommendations = false;
      });
    }
  }
  
  /// Generate heuristic intensifier suggestions based on exercise characteristics
  List<Map<String, dynamic>> _generateHeuristicIntensifiers(Map<String, dynamic> exerciseKnowledge) {
    final movementPattern = (exerciseKnowledge['movement_pattern'] as List<dynamic>?)
        ?.map((e) => e.toString().toLowerCase())
        .toList() ?? [];
    final equipment = (exerciseKnowledge['equipment'] as List<dynamic>?)
        ?.map((e) => e.toString().toLowerCase())
        .toList() ?? [];
    
    // Determine if it's a compound free weight exercise
    final isFreeWeight = equipment.any((e) => ['barbell', 'dumbbell', 'dumbbells'].contains(e));
    final isMachine = equipment.any((e) => ['machine', 'cable', 'cables'].contains(e));
    final isCompound = movementPattern.any((m) => ['push', 'pull', 'squat', 'hinge'].contains(m));
    
    // Default intensifier pool
    final allIntensifiers = [
      {'name': 'Rest-Pause', 'short_desc': 'Brief rest periods between mini-sets', 'fatigue_cost': 'high'},
      {'name': 'Drop Set', 'short_desc': 'Reduce weight and continue immediately', 'fatigue_cost': 'high'},
      {'name': 'Paused Reps', 'short_desc': 'Hold at bottom/midpoint for 2-3 seconds', 'fatigue_cost': 'medium'},
      {'name': 'Tempo', 'short_desc': 'Control rep speed (e.g., 3-1-2-0)', 'fatigue_cost': 'low'},
      {'name': 'Lengthened Partials', 'short_desc': 'Focus on stretched position', 'fatigue_cost': 'medium'},
      {'name': '1.5 Reps', 'short_desc': 'Full rep + half rep at bottom', 'fatigue_cost': 'high'},
      {'name': 'Myo-Reps', 'short_desc': 'Cluster sets with short rest', 'fatigue_cost': 'medium'},
      {'name': 'Slow Eccentric', 'short_desc': '3-5 second lowering phase', 'fatigue_cost': 'low'},
      {'name': 'Cluster Sets', 'short_desc': 'Short rest between mini-sets', 'fatigue_cost': 'medium'},
      {'name': 'Back-off Sets', 'short_desc': 'Reduce weight after main sets', 'fatigue_cost': 'low'},
      {'name': 'Wave Loading', 'short_desc': 'Progressive weight waves', 'fatigue_cost': 'medium'},
      {'name': 'Partials', 'short_desc': 'Partial range of motion', 'fatigue_cost': 'low'},
      {'name': 'Iso-holds at Stretch', 'short_desc': 'Hold at stretched position', 'fatigue_cost': 'low'},
    ];
    
    // Filter based on movement pattern
    List<Map<String, dynamic>> suggestions = [];
    
    if (movementPattern.any((m) => ['push'].contains(m))) {
      // Push compounds: Rest-Pause, Drop Set, Paused Reps, Tempo, Lengthened Partials, 1.5 Reps
      suggestions = [
        allIntensifiers.firstWhere((i) => i['name'] == 'Rest-Pause'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Drop Set'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Paused Reps'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Tempo'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Lengthened Partials'),
        allIntensifiers.firstWhere((i) => i['name'] == '1.5 Reps'),
      ];
    } else if (movementPattern.any((m) => ['pull'].contains(m))) {
      // Pull/back: Myo-Reps, Drop Set, Rest-Pause, Lengthened Partials, Slow Eccentric
      suggestions = [
        allIntensifiers.firstWhere((i) => i['name'] == 'Myo-Reps'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Drop Set'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Rest-Pause'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Lengthened Partials'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Slow Eccentric'),
      ];
    } else if (movementPattern.any((m) => ['squat', 'hinge'].contains(m))) {
      // Squat/hinge: Paused Reps, Tempo, Cluster Sets, Back-off Sets, Wave Loading
      suggestions = [
        allIntensifiers.firstWhere((i) => i['name'] == 'Paused Reps'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Tempo'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Cluster Sets'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Back-off Sets'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Wave Loading'),
      ];
    } else if (isMachine || !isCompound) {
      // Machines/isolation: Myo-Reps, Drop Set, Rest-Pause, Partials, Iso-holds at stretch
      suggestions = [
        allIntensifiers.firstWhere((i) => i['name'] == 'Myo-Reps'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Drop Set'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Rest-Pause'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Partials'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Iso-holds at Stretch'),
      ];
    } else {
      // Default: mix of common intensifiers
      suggestions = [
        allIntensifiers.firstWhere((i) => i['name'] == 'Rest-Pause'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Drop Set'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Paused Reps'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Tempo'),
        allIntensifiers.firstWhere((i) => i['name'] == 'Myo-Reps'),
      ];
    }
    
    // Filter out high fatigue choices for free weight compounds (limit to 1-2 max)
    if (isFreeWeight && isCompound) {
      final highFatigue = suggestions.where((s) => s['fatigue_cost'] == 'high').toList();
      final lowMediumFatigue = suggestions.where((s) => s['fatigue_cost'] != 'high').toList();
      
      // Keep only 1-2 high fatigue, prioritize low/medium
      suggestions = [
        ...highFatigue.take(2),
        ...lowMediumFatigue.take(6),
      ];
    }
    
    // Limit to top 5-8
    return suggestions.take(8).toList();
  }
  
  /// Apply an intensifier suggestion
  void _applyIntensifier(Map<String, dynamic> intensifier) {
    setState(() {
      _selectedIntensifier = intensifier['name'] as String?;
      _selectedIntensifierId = intensifier['id'] as String?;
    });
    // Phase 4.5: Load intensifier details when applied
    if (_selectedIntensifierId != null) {
      _loadIntensifierDetails();
    } else if (_selectedIntensifier != null) {
      // Try to find by name if ID is missing
      _loadIntensifierDetailsByName();
    }
  }
  
  /// Load intensifier details by ID (Phase 4.5)
  Future<void> _loadIntensifierDetails() async {
    if (_selectedIntensifierId == null) {
      setState(() {
        _selectedIntensifierDetails = null;
        _loadingIntensifierDetails = false;
      });
      return;
    }
    
    setState(() {
      _loadingIntensifierDetails = true;
    });
    
    try {
      final service = WorkoutKnowledgeService.instance;
      final details = await service.getIntensifier(_selectedIntensifierId!);
      
      if (mounted) {
        setState(() {
          _selectedIntensifierDetails = details;
          _loadingIntensifierDetails = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading intensifier details: $e');
      if (mounted) {
        setState(() {
          _selectedIntensifierDetails = null;
          _loadingIntensifierDetails = false;
        });
      }
    }
  }
  
  /// Load intensifier details by name (best effort, Phase 4.5)
  Future<void> _loadIntensifierDetailsByName() async {
    if (_selectedIntensifier == null) return;
    
    setState(() {
      _loadingIntensifierDetails = true;
    });
    
    try {
      final service = WorkoutKnowledgeService.instance;
      final results = await service.searchIntensifiers(
        query: _selectedIntensifier!,
        language: 'en',
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        final match = results.first;
        final matchName = match['name'] as String?;
        // Exact match (case-insensitive)
        if (matchName != null && matchName.toLowerCase() == _selectedIntensifier!.toLowerCase()) {
          setState(() {
            _selectedIntensifierDetails = match;
            _selectedIntensifierId = match['id'] as String?;
            _loadingIntensifierDetails = false;
          });
          return;
        }
      }
      
      if (mounted) {
        setState(() {
          _selectedIntensifierDetails = null;
          _loadingIntensifierDetails = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading intensifier details by name: $e');
      if (mounted) {
        setState(() {
          _selectedIntensifierDetails = null;
          _loadingIntensifierDetails = false;
        });
      }
    }
  }
  
  /// Build intensifier rules preview card (Phase 4.5)
  Widget _buildIntensifierRulesPreview() {
    if (_loadingIntensifierDetails) {
      return Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.space16),
        padding: const EdgeInsets.all(DesignTokens.space16),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.space16),
            child: CircularProgressIndicator(color: AppTheme.accentGreen),
          ),
        ),
      );
    }
    
    if (_selectedIntensifierDetails == null) {
      return const SizedBox.shrink();
    }
    
    final name = _selectedIntensifierDetails!['name'] as String? ?? _selectedIntensifier ?? 'Unknown';
    final fatigueCost = _selectedIntensifierDetails!['fatigue_cost'] as String?;
    final bestFor = _selectedIntensifierDetails!['best_for'] as String?;
    final intensityRules = _selectedIntensifierDetails!['intensity_rules'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Fatigue Cost
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.accentGreen, size: 20),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: Text(
                  'Intensifier Rules: $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (fatigueCost != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space8,
                    vertical: DesignTokens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: _getFatigueColor(fatigueCost).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    border: Border.all(
                      color: _getFatigueColor(fatigueCost).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    fatigueCost.toUpperCase(),
                    style: TextStyle(
                      color: _getFatigueColor(fatigueCost),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          // Best For chips
          if (bestFor != null && bestFor.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                const Text(
                  'Best for:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space8,
                    vertical: DesignTokens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  ),
                  child: Text(
                    bestFor,
                    style: TextStyle(
                      color: DesignTokens.accentBlue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // Intensity Rules
          if (intensityRules != null) ...[
            const SizedBox(height: DesignTokens.space16),
            const Text(
              'Rules:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            _buildIntensityRulesView(intensityRules),
          ] else ...[
            const SizedBox(height: DesignTokens.space12),
            const Text(
              'No rules available',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Get color for fatigue cost
  Color _getFatigueColor(String fatigueCost) {
    switch (fatigueCost.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.white70;
    }
  }
  
  /// Build intensity rules view (pretty render)
  Widget _buildIntensityRulesView(dynamic intensityRules) {
    if (intensityRules is! Map) {
      return const Text(
        'Invalid rules format',
        style: TextStyle(color: Colors.white60, fontSize: 12),
      );
    }
    
    final rulesMap = intensityRules as Map<String, dynamic>;
    final sections = <Widget>[];
    
    for (final entry in rulesMap.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Format key name (e.g., "rest_pause" -> "Rest-Pause")
      final formattedKey = key
          .split('_')
          .map((word) => word.isEmpty 
              ? word 
              : word[0].toUpperCase() + word.substring(1))
          .join(' ');
      
      sections.add(
        Container(
          margin: const EdgeInsets.only(bottom: DesignTokens.space12),
          padding: const EdgeInsets.all(DesignTokens.space12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedKey,
                style: const TextStyle(
                  color: AppTheme.accentGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: DesignTokens.space8),
              if (value is Map) ...[
                ...value.entries.map((kv) {
                  final k = kv.key.toString();
                  final v = kv.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.space4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            k.replaceAll('_', ' ').split(' ').map((w) => 
                              w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)
                            ).join(' '),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            v.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                Text(
                  value.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    if (sections.isEmpty) {
      return const Text(
        'No rules defined',
        style: TextStyle(color: Colors.white60, fontSize: 12),
      );
    }
    
    return Column(children: sections);
  }
  
  /// Build apply scope control (Phase 4.6B)
  Widget _buildApplyScopeControl() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppTheme.accentGreen, size: 18),
              const SizedBox(width: DesignTokens.space8),
              Text(
                'Apply Scope',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'off',
                label: Text('Off'),
                tooltip: 'Do not auto-apply rules',
              ),
              ButtonSegment<String>(
                value: 'last_set',
                label: Text('Last Set'),
                tooltip: 'Apply rules to last set only',
              ),
              ButtonSegment<String>(
                value: 'all_sets',
                label: Text('All Sets'),
                tooltip: 'Apply rules to all sets',
              ),
            ],
            selected: {_intensifierApplyScope},
            onSelectionChanged: (Set<String> selection) {
              setState(() {
                _intensifierApplyScope = selection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppTheme.accentGreen,
              selectedForegroundColor: AppTheme.primaryDark,
              backgroundColor: AppTheme.cardBackground,
              foregroundColor: Colors.white70,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Controls where intensifier rules apply during workout logging.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomTrainingMethodDialog() {
    final controller = TextEditingController(text: _customTrainingMethod ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Custom Training Method',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Enter custom training method',
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: 'e.g., myo_reps, blood_flow_restriction',
            hintStyle: const TextStyle(color: Colors.white54),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim().toLowerCase();
              if (value.isNotEmpty) {
                setState(() {
                  _customTrainingMethod = value;
                  _trainingMethod = TrainingMethod.unknown; // Mark as unknown to use custom
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
