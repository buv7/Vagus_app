import 'package:flutter/material.dart';
import '../../models/workout/cardio_session.dart';
import '../../models/workout/enhanced_exercise.dart';
import '../../theme/design_tokens.dart';

class CardioEditorDialog extends StatefulWidget {
  final CardioSession? cardioSession;
  final Function(CardioSession) onSave;

  const CardioEditorDialog({
    super.key,
    this.cardioSession,
    required this.onSave,
  });

  @override
  State<CardioEditorDialog> createState() => _CardioEditorDialogState();
}

class _CardioEditorDialogState extends State<CardioEditorDialog> {
  // Form controllers
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  // State
  CardioMachineType _selectedMachine = CardioMachineType.treadmill;
  CardioType _cardioType = CardioType.liss;
  String? _customCardioType; // Store custom cardio type string when enum is unknown
  String? _validationError;

  // Machine-specific controllers
  final _speedController = TextEditingController();
  final _inclineController = TextEditingController();
  final _resistanceController = TextEditingController();
  final _rpmController = TextEditingController();
  final _strokeRateController = TextEditingController();
  final _levelController = TextEditingController();
  final _distanceController = TextEditingController();
  final _targetHRController = TextEditingController();

  // Interval settings
  final _workIntervalController = TextEditingController();
  final _restIntervalController = TextEditingController();
  final _intervalsCountController = TextEditingController();

  String _intensityLevel = 'Medium';

  @override
  void initState() {
    super.initState();

    // Initialize with existing cardio session data
    if (widget.cardioSession != null) {
      _durationController.text = widget.cardioSession!.durationMinutes?.toString() ?? '';
      _instructionsController.text = widget.cardioSession!.instructions ?? '';
      _selectedMachine = widget.cardioSession!.machineType ?? CardioMachineType.treadmill;

      // Load machine-specific settings
      _loadMachineSettings();

      // Load cardio type from settings
      final typeStr = widget.cardioSession!.settings['cardio_type'] as String?;
      final parsed = CardioType.fromString(typeStr);
      if (parsed == CardioType.unknown && typeStr != null) {
        // Custom/unknown value - preserve raw string
        _cardioType = CardioType.unknown;
        _customCardioType = typeStr;
      } else {
        _cardioType = parsed;
        _customCardioType = null;
      }

      _intensityLevel = widget.cardioSession!.settings['intensity'] as String? ?? 'Medium';
      _targetHRController.text = widget.cardioSession!.settings['target_hr']?.toString() ?? '';

      // Load interval settings
      _workIntervalController.text = widget.cardioSession!.settings['work_interval']?.toString() ?? '';
      _restIntervalController.text = widget.cardioSession!.settings['rest_interval']?.toString() ?? '';
      _intervalsCountController.text = widget.cardioSession!.settings['intervals_count']?.toString() ?? '';
    }
  }

  void _loadMachineSettings() {
    switch (_selectedMachine) {
      case CardioMachineType.treadmill:
        final settings = widget.cardioSession!.getTreadmillSettings();
        _speedController.text = settings?.speed?.toString() ?? '';
        _inclineController.text = settings?.incline?.toString() ?? '';
        break;
      case CardioMachineType.bike:
        final settings = widget.cardioSession!.getBikeSettings();
        _resistanceController.text = settings?.resistance?.toString() ?? '';
        _rpmController.text = settings?.rpm?.toString() ?? '';
        break;
      case CardioMachineType.rower:
        final settings = widget.cardioSession!.getRowerSettings();
        _resistanceController.text = settings?.resistance?.toString() ?? '';
        _strokeRateController.text = settings?.strokeRate?.toString() ?? '';
        _distanceController.text = settings?.targetDistance?.toString() ?? '';
        break;
      case CardioMachineType.elliptical:
        final settings = widget.cardioSession!.getEllipticalSettings();
        _resistanceController.text = settings?.resistance?.toString() ?? '';
        _inclineController.text = settings?.incline?.toString() ?? '';
        break;
      case CardioMachineType.stairmaster:
        final settings = widget.cardioSession!.getStairmasterSettings();
        _levelController.text = settings?.level?.toString() ?? '';
        break;
    }
  }


  @override
  void dispose() {
    _durationController.dispose();
    _instructionsController.dispose();
    _speedController.dispose();
    _inclineController.dispose();
    _resistanceController.dispose();
    _rpmController.dispose();
    _strokeRateController.dispose();
    _levelController.dispose();
    _distanceController.dispose();
    _targetHRController.dispose();
    _workIntervalController.dispose();
    _restIntervalController.dispose();
    _intervalsCountController.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_durationController.text.isEmpty) {
      setState(() => _validationError = 'Duration is required');
      return false;
    }

    final duration = int.tryParse(_durationController.text);
    if (duration == null || duration <= 0) {
      setState(() => _validationError = 'Duration must be a positive number');
      return false;
    }

    setState(() => _validationError = null);
    return true;
  }

  void _save() {
    if (!_validate()) return;

    // Build machine-specific settings
    Map<String, dynamic> machineSettings = {};

    switch (_selectedMachine) {
      case CardioMachineType.treadmill:
        machineSettings = TreadmillSettings(
          speed: _speedController.text.isNotEmpty
              ? double.tryParse(_speedController.text)
              : null,
          incline: _inclineController.text.isNotEmpty
              ? double.tryParse(_inclineController.text)
              : null,
        ).toMap();
        break;
      case CardioMachineType.bike:
        machineSettings = BikeSettings(
          resistance: _resistanceController.text.isNotEmpty
              ? int.tryParse(_resistanceController.text)
              : null,
          rpm: _rpmController.text.isNotEmpty
              ? int.tryParse(_rpmController.text)
              : null,
        ).toMap();
        break;
      case CardioMachineType.rower:
        machineSettings = RowerSettings(
          resistance: _resistanceController.text.isNotEmpty
              ? int.tryParse(_resistanceController.text)
              : null,
          strokeRate: _strokeRateController.text.isNotEmpty
              ? int.tryParse(_strokeRateController.text)
              : null,
          targetDistance: _distanceController.text.isNotEmpty
              ? int.tryParse(_distanceController.text)
              : null,
        ).toMap();
        break;
      case CardioMachineType.elliptical:
        machineSettings = EllipticalSettings(
          resistance: _resistanceController.text.isNotEmpty
              ? int.tryParse(_resistanceController.text)
              : null,
          incline: _inclineController.text.isNotEmpty
              ? double.tryParse(_inclineController.text)
              : null,
        ).toMap();
        break;
      case CardioMachineType.stairmaster:
        machineSettings = StairmasterSettings(
          level: _levelController.text.isNotEmpty
              ? int.tryParse(_levelController.text)
              : null,
        ).toMap();
        break;
    }

    // Add cardio type and general settings (preserve custom string if present)
    machineSettings['cardio_type'] = _customCardioType ?? _cardioType.value;
    machineSettings['intensity'] = _intensityLevel;

    if (_targetHRController.text.isNotEmpty) {
      machineSettings['target_hr'] = int.tryParse(_targetHRController.text);
    }

    // Add interval settings if applicable
    final cardioTypeValue = _customCardioType ?? _cardioType.value;
    if (_cardioType == CardioType.hiit || 
        _cardioType == CardioType.sprintIntervals ||
        cardioTypeValue.toLowerCase().contains('hiit') ||
        cardioTypeValue.toLowerCase().contains('interval')) {
      if (_workIntervalController.text.isNotEmpty) {
        machineSettings['work_interval'] = int.tryParse(_workIntervalController.text);
      }
      if (_restIntervalController.text.isNotEmpty) {
        machineSettings['rest_interval'] = int.tryParse(_restIntervalController.text);
      }
      if (_intervalsCountController.text.isNotEmpty) {
        machineSettings['intervals_count'] = int.tryParse(_intervalsCountController.text);
      }
    }

    final cardioSession = CardioSession(
      id: widget.cardioSession?.id,
      dayId: widget.cardioSession?.dayId ?? '',
      orderIndex: widget.cardioSession?.orderIndex ?? 0,
      machineType: _selectedMachine,
      settings: machineSettings,
      instructions: _instructionsController.text.isNotEmpty
          ? _instructionsController.text
          : null,
      durationMinutes: int.parse(_durationController.text),
      createdAt: widget.cardioSession?.createdAt,
      updatedAt: DateTime.now(),
    );

    widget.onSave(cardioSession);
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardioTypeSection(),
                    const SizedBox(height: 20),
                    _buildMachineSelector(),
                    const SizedBox(height: 20),
                    _buildBasicSettings(),
                    const SizedBox(height: 20),
                    _buildMachineSpecificSettings(),
                    if (_cardioType == CardioType.hiit ||
                        _cardioType == CardioType.sprintIntervals ||
                        (_customCardioType != null && (
                          _customCardioType!.toLowerCase().contains('hiit') ||
                          _customCardioType!.toLowerCase().contains('interval')))) ...[
                      const SizedBox(height: 20),
                      _buildIntervalSettings(),
                    ],
                    const SizedBox(height: 20),
                    _buildNotesSection(),
                  ],
                ),
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
            Icons.directions_run,
            color: DesignTokens.accentOrange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            widget.cardioSession == null ? 'Add Cardio' : 'Edit Cardio',
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

  Widget _buildCardioTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cardio Type',
          style: DesignTokens.titleSmall.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Known enum values (excluding unknown)
            ...CardioType.values.where((type) => type != CardioType.unknown).map((type) {
              final isSelected = _cardioType == type && _customCardioType == null;
              return ChoiceChip(
                label: Text(type.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _cardioType = type;
                    _customCardioType = null;
                  });
                },
                selectedColor: DesignTokens.accentOrange.withValues(alpha: 0.3),
                backgroundColor: DesignTokens.primaryDark,
                labelStyle: TextStyle(
                  color: isSelected
                      ? DesignTokens.accentOrange
                      : DesignTokens.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? DesignTokens.accentOrange
                      : DesignTokens.glassBorder,
                ),
              );
            }),
            // Custom value chip (if exists)
            if (_customCardioType != null)
              ChoiceChip(
                label: Text('Custom: $_customCardioType'),
                selected: true,
                onSelected: (selected) {
                  // Keep selected, allow editing via custom dialog
                  _showCustomCardioTypeDialog();
                },
                selectedColor: DesignTokens.accentOrange.withValues(alpha: 0.3),
                backgroundColor: DesignTokens.primaryDark,
                labelStyle: const TextStyle(
                  color: DesignTokens.accentOrange,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(
                  color: DesignTokens.accentOrange,
                ),
              ),
            // "Add Custom" chip
            ChoiceChip(
              label: const Text('Custom...'),
              selected: false,
              onSelected: (selected) {
                _showCustomCardioTypeDialog();
              },
              selectedColor: DesignTokens.accentOrange.withValues(alpha: 0.3),
              backgroundColor: DesignTokens.primaryDark,
              labelStyle: const TextStyle(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.normal,
              ),
              side: const BorderSide(
                color: DesignTokens.glassBorder,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMachineSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Machine',
          style: DesignTokens.titleSmall.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CardioMachineType.values.map((machine) {
            final isSelected = _selectedMachine == machine;
            return ChoiceChip(
              label: Text(machine.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedMachine = machine);
              },
              selectedColor: DesignTokens.accentBlue.withValues(alpha: 0.3),
              backgroundColor: DesignTokens.primaryDark,
              labelStyle: TextStyle(
                color: isSelected
                    ? DesignTokens.accentBlue
                    : DesignTokens.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? DesignTokens.accentBlue
                    : DesignTokens.glassBorder,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBasicSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Settings',
          style: DesignTokens.titleSmall.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Duration (min)',
                controller: _durationController,
                hint: '30',
                keyboardType: TextInputType.number,
                icon: Icons.timer,
                required: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed, size: 16, color: DesignTokens.accentGreen),
                      const SizedBox(width: 6),
                      Text(
                        'Intensity',
                        style: DesignTokens.labelMedium.copyWith(
                          color: DesignTokens.neutralWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _intensityLevel,
                    items: ['Low', 'Medium', 'High'].map((intensity) {
                      return DropdownMenuItem(
                        value: intensity,
                        child: Text(intensity),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _intensityLevel = value!);
                    },
                    style: const TextStyle(color: DesignTokens.neutralWhite),
                    dropdownColor: DesignTokens.cardBackground,
                    decoration: InputDecoration(
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Target Heart Rate (optional)',
          controller: _targetHRController,
          hint: '140',
          keyboardType: TextInputType.number,
          icon: Icons.favorite,
          helperText: 'Target HR in BPM',
        ),
      ],
    );
  }

  Widget _buildMachineSpecificSettings() {
    switch (_selectedMachine) {
      case CardioMachineType.treadmill:
        return _buildTreadmillSettings();
      case CardioMachineType.bike:
        return _buildBikeSettings();
      case CardioMachineType.rower:
        return _buildRowerSettings();
      case CardioMachineType.elliptical:
        return _buildEllipticalSettings();
      case CardioMachineType.stairmaster:
        return _buildStairmasterSettings();
    }
  }

  Widget _buildTreadmillSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Treadmill Settings',
          style: DesignTokens.titleSmall.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Speed (km/h)',
                controller: _speedController,
                hint: '10',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                icon: Icons.speed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Incline (%)',
                controller: _inclineController,
                hint: '5',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBikeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bike Settings',
          style: DesignTokens.titleSmall.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Resistance (1-20)',
                controller: _resistanceController,
                hint: '10',
                keyboardType: TextInputType.number,
                icon: Icons.fitness_center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'RPM',
                controller: _rpmController,
                hint: '80',
                keyboardType: TextInputType.number,
                icon: Icons.rotate_right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRowerSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rower Settings',
          style: DesignTokens.titleSmall.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Resistance (1-10)',
                controller: _resistanceController,
                hint: '5',
                keyboardType: TextInputType.number,
                icon: Icons.fitness_center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Stroke Rate (SPM)',
                controller: _strokeRateController,
                hint: '24',
                keyboardType: TextInputType.number,
                icon: Icons.rowing,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Target Distance (m)',
          controller: _distanceController,
          hint: '5000',
          keyboardType: TextInputType.number,
          icon: Icons.straighten,
        ),
      ],
    );
  }

  Widget _buildEllipticalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elliptical Settings',
          style: DesignTokens.titleSmall.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Resistance (1-20)',
                controller: _resistanceController,
                hint: '10',
                keyboardType: TextInputType.number,
                icon: Icons.fitness_center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Incline (%)',
                controller: _inclineController,
                hint: '5',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStairmasterSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stairmaster Settings',
          style: DesignTokens.titleSmall.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Level (1-20)',
          controller: _levelController,
          hint: '10',
          keyboardType: TextInputType.number,
          icon: Icons.stairs,
        ),
      ],
    );
  }

  Widget _buildIntervalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interval Settings',
          style: DesignTokens.titleSmall.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Work (sec)',
                controller: _workIntervalController,
                hint: '30',
                keyboardType: TextInputType.number,
                icon: Icons.play_arrow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Rest (sec)',
                controller: _restIntervalController,
                hint: '30',
                keyboardType: TextInputType.number,
                icon: Icons.pause,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Rounds',
                controller: _intervalsCountController,
                hint: '8',
                keyboardType: TextInputType.number,
                icon: Icons.repeat,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions & Notes',
          style: DesignTokens.titleSmall.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _instructionsController,
          maxLines: 4,
          style: const TextStyle(color: DesignTokens.neutralWhite),
          decoration: InputDecoration(
            hintText: 'Add instructions, warm-up notes, or specific guidelines...',
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
              borderSide: const BorderSide(color: DesignTokens.accentOrange),
            ),
          ),
        ),
      ],
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
                backgroundColor: DesignTokens.accentOrange,
                foregroundColor: DesignTokens.primaryDark,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.cardioSession == null ? 'Add Cardio' : 'Save Changes',
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
              Icon(icon, size: 16, color: DesignTokens.accentOrange),
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
              borderSide: const BorderSide(color: DesignTokens.accentOrange),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showCustomCardioTypeDialog() {
    final controller = TextEditingController(text: _customCardioType ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.cardBackground,
        title: const Text(
          'Custom Cardio Type',
          style: TextStyle(color: DesignTokens.neutralWhite),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: DesignTokens.neutralWhite),
          decoration: InputDecoration(
            labelText: 'Enter custom cardio type',
            labelStyle: const TextStyle(color: DesignTokens.textSecondary),
            hintText: 'e.g., myo_cardio, blood_flow_restriction',
            hintStyle: const TextStyle(color: DesignTokens.textSecondary),
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
              borderSide: const BorderSide(color: DesignTokens.accentOrange),
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
                  _customCardioType = value;
                  _cardioType = CardioType.unknown; // Mark as unknown to use custom
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
