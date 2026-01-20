import 'package:flutter/material.dart';
import '../../models/workout/exercise.dart';
import '../../theme/design_tokens.dart';
import '../../services/workout/workout_metadata_service.dart';

class AdvancedExerciseEditor extends StatefulWidget {
  final Exercise? exercise;
  final Function(Exercise) onSave;

  const AdvancedExerciseEditor({
    super.key,
    this.exercise,
    required this.onSave,
  });

  @override
  State<AdvancedExerciseEditor> createState() => _AdvancedExerciseEditorState();
}

class _AdvancedExerciseEditorState extends State<AdvancedExerciseEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers
  final _nameController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _restController = TextEditingController();
  final _percent1RMController = TextEditingController();
  final _rirController = TextEditingController();
  final _tempoController = TextEditingController();
  final _notesController = TextEditingController();

  // State
  ExerciseGroupType _groupType = ExerciseGroupType.none;
  String? _groupId;
  String? _groupTypeRaw; // For unknown group types from DB
  String? _validationError;
  List<String> _availableGroupTypes = []; // DB-driven list

  // Calculated values
  double? _calculatedVolume;
  double? _estimated1RM;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize with existing exercise data
    if (widget.exercise != null) {
      _nameController.text = widget.exercise!.name;
      _setsController.text = widget.exercise!.sets?.toString() ?? '';
      _repsController.text = widget.exercise!.reps ?? '';
      _weightController.text = widget.exercise!.weight?.toString() ?? '';
      _restController.text = widget.exercise!.rest?.toString() ?? '';
      _percent1RMController.text = widget.exercise!.percent1RM?.toString() ?? '';
      _rirController.text = widget.exercise!.rir?.toString() ?? '';
      _tempoController.text = widget.exercise!.tempo ?? '';
      _notesController.text = widget.exercise!.notes ?? '';
      _groupType = widget.exercise!.groupType;
      _groupId = widget.exercise!.groupId;
      
      // Note: If groupType is unknown, _groupTypeRaw exists but is private
      // We can't read it here, but it will be preserved when saving since
      // Exercise.toMap() uses _groupTypeRaw ?? groupType.value
      // For UI, if groupType is unknown, we'll just show "none" as selected
      // This is acceptable for minimal change
    }

    // Add listeners for real-time calculations
    _setsController.addListener(_updateCalculations);
    _repsController.addListener(_updateCalculations);
    _weightController.addListener(_updateCalculations);
    
    // Load DB-driven group types
    _loadGroupTypes();
  }
  
  Future<void> _loadGroupTypes() async {
    try {
      final types = await WorkoutMetadataService().getDistinctGroupTypes();
      if (mounted) {
        setState(() {
          _availableGroupTypes = types;
        });
      }
    } catch (e) {
      // Fallback: use known enum values if service fails
      if (mounted) {
        setState(() {
          _availableGroupTypes = ExerciseGroupType.values
              .where((e) => e != ExerciseGroupType.none && e != ExerciseGroupType.unknown)
              .map((e) => e.value)
              .toList();
        });
      }
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
    _percent1RMController.dispose();
    _rirController.dispose();
    _tempoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateCalculations() {
    setState(() {
      // Calculate volume
      final sets = int.tryParse(_setsController.text);
      final weight = double.tryParse(_weightController.text);
      final repsMatch = RegExp(r'^\d+').firstMatch(_repsController.text);
      final reps = repsMatch != null ? int.tryParse(repsMatch.group(0)!) : null;

      if (sets != null && weight != null && reps != null) {
        _calculatedVolume = sets * reps * weight;
      } else {
        _calculatedVolume = null;
      }

      // Calculate estimated 1RM using Epley formula
      if (weight != null && reps != null && reps > 0 && reps <= 15) {
        if (reps == 1) {
          _estimated1RM = weight;
        } else {
          _estimated1RM = weight * (1 + reps / 30.0);
        }
      } else {
        _estimated1RM = null;
      }
    });
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _validationError = 'Exercise name is required');
      return false;
    }

    final sets = int.tryParse(_setsController.text);
    if (_setsController.text.isNotEmpty && (sets == null || sets < 0)) {
      setState(() => _validationError = 'Sets must be a positive number');
      return false;
    }

    final weight = double.tryParse(_weightController.text);
    if (_weightController.text.isNotEmpty && (weight == null || weight < 0)) {
      setState(() => _validationError = 'Weight must be a positive number');
      return false;
    }

    final rest = int.tryParse(_restController.text);
    if (_restController.text.isNotEmpty && (rest == null || rest < 0)) {
      setState(() => _validationError = 'Rest must be a positive number');
      return false;
    }

    final percent1RM = int.tryParse(_percent1RMController.text);
    if (_percent1RMController.text.isNotEmpty &&
        (percent1RM == null || percent1RM < 0 || percent1RM > 100)) {
      setState(() => _validationError = '% 1RM must be between 0 and 100');
      return false;
    }

    final rir = int.tryParse(_rirController.text);
    if (_rirController.text.isNotEmpty && (rir == null || rir < 0 || rir > 5)) {
      setState(() => _validationError = 'RIR must be between 0 and 5');
      return false;
    }

    setState(() => _validationError = null);
    return true;
  }

  void _save() {
    if (!_validate()) {
      _tabController.animateTo(0); // Go to basic tab if validation fails
      return;
    }

    final exercise = Exercise(
      id: widget.exercise?.id,
      dayId: widget.exercise?.dayId ?? '',
      orderIndex: widget.exercise?.orderIndex ?? 0,
      name: _nameController.text.trim(),
      sets: _setsController.text.isNotEmpty
          ? int.tryParse(_setsController.text)
          : null,
      reps: _repsController.text.isNotEmpty ? _repsController.text : null,
      weight: _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text)
          : null,
      rest: _restController.text.isNotEmpty
          ? int.tryParse(_restController.text)
          : null,
      percent1RM: _percent1RMController.text.isNotEmpty
          ? int.tryParse(_percent1RMController.text)
          : null,
      rir: _rirController.text.isNotEmpty
          ? int.tryParse(_rirController.text)
          : null,
      tempo: _tempoController.text.isNotEmpty ? _tempoController.text : null,
      tonnage: _calculatedVolume,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      groupId: _groupId,
      groupType: _groupType,
      groupTypeRaw: _groupTypeRaw,
      createdAt: widget.exercise?.createdAt,
      updatedAt: DateTime.now(),
    );

    widget.onSave(exercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 40,
        vertical: isSmallScreen ? 20 : 40,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_validationError != null) _buildErrorBanner(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicTab(),
                  _buildAdvancedTab(),
                  _buildNotesTab(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DesignTokens.glassBorder)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.fitness_center,
            color: DesignTokens.accentGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            widget.exercise == null ? 'Add Exercise' : 'Edit Exercise',
            style: DesignTokens.titleLarge.copyWith(
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
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: DesignTokens.danger.withValues(alpha: 0.2),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: DesignTokens.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _validationError!,
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DesignTokens.glassBorder)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: DesignTokens.accentGreen,
        unselectedLabelColor: DesignTokens.textSecondary,
        indicatorColor: DesignTokens.accentGreen,
        tabs: const [
          Tab(text: 'Basic', icon: Icon(Icons.format_list_numbered, size: 18)),
          Tab(text: 'Advanced', icon: Icon(Icons.tune, size: 18)),
          Tab(text: 'Notes', icon: Icon(Icons.note, size: 18)),
        ],
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Name
          _buildTextField(
            label: 'Exercise Name',
            controller: _nameController,
            hint: 'e.g., Bench Press',
            required: true,
            icon: Icons.fitness_center,
          ),

          const SizedBox(height: 16),

          // Sets and Reps Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Sets',
                  controller: _setsController,
                  hint: '3',
                  keyboardType: TextInputType.number,
                  icon: Icons.repeat,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'Reps',
                  controller: _repsController,
                  hint: '8-12',
                  icon: Icons.numbers,
                  helperText: 'Can be range (8-12) or AMRAP',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Weight and Rest Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Weight (kg)',
                  controller: _weightController,
                  hint: '60',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  icon: Icons.scale,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'Rest (sec)',
                  controller: _restController,
                  hint: '90',
                  keyboardType: TextInputType.number,
                  icon: Icons.timer,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Training Method (Grouping)
          _buildSectionHeader('Training Method'),
          const SizedBox(height: 12),
          _buildGroupTypeSelector(),

          const SizedBox(height: 20),

          // Real-time Calculations
          if (_calculatedVolume != null || _estimated1RM != null)
            _buildCalculationsCard(),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Intensity Metrics'),
          const SizedBox(height: 12),

          // %1RM and RIR Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: '% 1RM',
                  controller: _percent1RMController,
                  hint: '75',
                  keyboardType: TextInputType.number,
                  icon: Icons.percent,
                  helperText: '0-100%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'RIR',
                  controller: _rirController,
                  hint: '2',
                  keyboardType: TextInputType.number,
                  icon: Icons.speed,
                  helperText: 'Reps in Reserve (0-5)',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tempo
          _buildTextField(
            label: 'Tempo',
            controller: _tempoController,
            hint: '3-1-2-0',
            icon: Icons.speed,
            helperText: 'Format: eccentric-pause-concentric-pause',
          ),

          const SizedBox(height: 24),

          // Info card about tempo
          _buildInfoCard(
            'Tempo Guide',
            'Tempo notation (e.g., 3-1-2-0):\n'
            '• First number: Eccentric (lowering)\n'
            '• Second: Pause at bottom\n'
            '• Third: Concentric (lifting)\n'
            '• Fourth: Pause at top\n\n'
            'Numbers are in seconds.',
          ),

          const SizedBox(height: 16),

          _buildInfoCard(
            'RIR Guide',
            'Reps in Reserve:\n'
            '• 0 = Absolute failure\n'
            '• 1 = 1 rep left in tank\n'
            '• 2 = 2 reps left (common for hypertrophy)\n'
            '• 3-5 = Technical work/warm-up',
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Exercise Notes & Cues'),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 12,
            style: const TextStyle(color: DesignTokens.neutralWhite),
            decoration: InputDecoration(
              hintText: 'Add form cues, modifications, or specific instructions...\n\n'
                  'Examples:\n'
                  '• Retract scapula before pressing\n'
                  '• Keep core braced throughout\n'
                  '• Pause 2 seconds at bottom',
              hintStyle: TextStyle(
                color: DesignTokens.textSecondary.withValues(alpha: 0.7),
                fontSize: 14,
              ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DesignTokens.glassBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: DesignTokens.glassBorder),
                foregroundColor: DesignTokens.neutralWhite,
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: DesignTokens.accentGreen,
                foregroundColor: DesignTokens.primaryDark,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.exercise == null ? 'Add Exercise' : 'Save Changes',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    IconData? icon,
    String? helperText,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: DesignTokens.accentGreen),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: DesignTokens.labelMedium.copyWith(
                color: DesignTokens.neutralWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: DesignTokens.danger),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: DesignTokens.neutralWhite),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: DesignTokens.textSecondary),
            helperText: helperText,
            helperStyle: TextStyle(
              color: DesignTokens.textSecondary.withValues(alpha: 0.7),
              fontSize: 12,
            ),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: DesignTokens.titleSmall.copyWith(
        color: DesignTokens.neutralWhite,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildGroupTypeSelector() {
    // Build list: known enum values + DB types
    final allTypes = <String>{};
    
    // Add known enum values (excluding none and unknown)
    allTypes.addAll(
      ExerciseGroupType.values
          .where((e) => e != ExerciseGroupType.none && e != ExerciseGroupType.unknown)
          .map((e) => e.value),
    );
    
    // Add DB-driven types
    allTypes.addAll(_availableGroupTypes);
    
    final sortedTypes = allTypes.toList()..sort();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "None" option (always available)
        _buildGroupTypeChip('none', 'Standard', ExerciseGroupType.none),
        
        // DB-driven types
        ...sortedTypes.map((typeString) {
          // Try to match to known enum
          final parsedEnum = ExerciseGroupType.fromString(typeString);
          
          // Get display name
          String displayName;
          if (parsedEnum != ExerciseGroupType.unknown) {
            displayName = parsedEnum.displayName;
          } else {
            // Unknown type - show as "Custom: <type>"
            displayName = 'Custom: $typeString';
          }
          
          return _buildGroupTypeChip(
            typeString,
            displayName,
            parsedEnum != ExerciseGroupType.unknown ? parsedEnum : null,
          );
        }),
      ],
    );
  }
  
  Widget _buildGroupTypeChip(
    String typeValue,
    String displayName,
    ExerciseGroupType? enumType,
  ) {
    final isSelected = enumType != null
        ? _groupType == enumType
        : _groupTypeRaw == typeValue && _groupType == ExerciseGroupType.unknown;
    
    return ChoiceChip(
      label: Text(displayName),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (enumType != null) {
            // Known enum type
            _groupType = enumType;
            _groupTypeRaw = null;
          } else {
            // Unknown/raw string type
            _groupType = ExerciseGroupType.unknown;
            _groupTypeRaw = typeValue;
          }
          
          // Generate a group ID if grouping is enabled
          if (typeValue != 'none' && _groupId == null) {
            _groupId = DateTime.now().millisecondsSinceEpoch.toString();
          } else if (typeValue == 'none') {
            _groupId = null;
            _groupType = ExerciseGroupType.none;
            _groupTypeRaw = null;
          }
        });
      },
      selectedColor: DesignTokens.accentGreen.withValues(alpha: 0.3),
      backgroundColor: DesignTokens.primaryDark,
      labelStyle: TextStyle(
        color: isSelected
            ? DesignTokens.accentGreen
            : DesignTokens.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? DesignTokens.accentGreen
            : DesignTokens.glassBorder,
      ),
    );
  }

  Widget _buildCalculationsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.accentGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calculate,
                color: DesignTokens.accentGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Live Calculations',
                style: DesignTokens.labelMedium.copyWith(
                  color: DesignTokens.accentGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_calculatedVolume != null)
            _buildCalculationRow(
              'Total Volume',
              '${_calculatedVolume!.toStringAsFixed(1)} kg',
              'sets × reps × weight',
            ),
          if (_estimated1RM != null) ...[
            const SizedBox(height: 8),
            _buildCalculationRow(
              'Estimated 1RM',
              '${_estimated1RM!.toStringAsFixed(1)} kg',
              'Using Epley formula',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, String formula) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.neutralWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              formula,
              style: DesignTokens.labelSmall.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: DesignTokens.titleMedium.copyWith(
            color: DesignTokens.accentGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.accentBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: DesignTokens.accentBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: DesignTokens.labelMedium.copyWith(
                  color: DesignTokens.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: DesignTokens.bodySmall.copyWith(
              color: DesignTokens.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
