import 'package:flutter/material.dart';
import '../../models/workout/cardio_session.dart';
import '../../services/cardio/manual_cardio_service.dart';
import '../../theme/design_tokens.dart';

/// Dialog for manual cardio entry
class ManualCardioEntryDialog extends StatefulWidget {
  final ManualCardioEntry? existingEntry;
  final Function(ManualCardioEntry)? onSaved;

  const ManualCardioEntryDialog({
    super.key,
    this.existingEntry,
    this.onSaved,
  });

  @override
  State<ManualCardioEntryDialog> createState() => _ManualCardioEntryDialogState();
}

class _ManualCardioEntryDialogState extends State<ManualCardioEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = ManualCardioService();
  
  // Form controllers
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _avgHRController = TextEditingController();
  final _maxHRController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  String _selectedSport = 'running';
  CardioMachineType? _selectedMachine;
  String _intensity = 'Medium';
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing entry if editing
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _selectedSport = entry.sport;
      _selectedMachine = entry.machineType;
      _intensity = entry.intensity ?? 'Medium';
      _startDate = entry.startAt;
      _startTime = TimeOfDay.fromDateTime(entry.startAt);
      
      if (entry.durationSeconds != null) {
        _durationController.text = (entry.durationSeconds! / 60).round().toString();
      }
      if (entry.distanceMeters != null) {
        _distanceController.text = (entry.distanceMeters! / 1000).toStringAsFixed(2);
      }
      if (entry.caloriesBurned != null) {
        _caloriesController.text = entry.caloriesBurned!.round().toString();
      }
      if (entry.avgHeartRate != null) {
        _avgHRController.text = entry.avgHeartRate!.round().toString();
      }
      if (entry.maxHeartRate != null) {
        _maxHRController.text = entry.maxHeartRate!.round().toString();
      }
      if (entry.notes != null) {
        _notesController.text = entry.notes!;
      }
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _caloriesController.dispose();
    _avgHRController.dispose();
    _maxHRController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Parse duration
      final durationMinutes = int.tryParse(_durationController.text) ?? 0;
      final durationSeconds = durationMinutes * 60;
      
      // Parse distance (km to meters)
      final distanceKm = double.tryParse(_distanceController.text);
      final distanceMeters = distanceKm != null ? distanceKm * 1000 : null;
      
      // Parse other fields
      final calories = double.tryParse(_caloriesController.text);
      final avgHR = double.tryParse(_avgHRController.text);
      final maxHR = double.tryParse(_maxHRController.text);
      
      // Build start datetime
      final startAt = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      // Calculate end time
      final endAt = startAt.add(Duration(seconds: durationSeconds));
      
      final entry = ManualCardioEntry(
        id: widget.existingEntry?.id,
        sport: _selectedSport,
        startAt: startAt,
        endAt: endAt,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        avgHeartRate: avgHR,
        maxHeartRate: maxHR,
        caloriesBurned: calories,
        machineType: _selectedMachine,
        intensity: _intensity,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      ManualCardioEntry? savedEntry;
      if (widget.existingEntry?.id != null) {
        savedEntry = await _service.updateEntry(widget.existingEntry!.id!, entry);
      } else {
        savedEntry = await _service.saveManualEntry(entry);
      }

      if (savedEntry != null) {
        widget.onSaved?.call(savedEntry);
        if (mounted) {
          Navigator.of(context).pop(savedEntry);
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to save cardio entry. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DesignTokens.accentBlue,
              surface: DesignTokens.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DesignTokens.accentBlue,
              surface: DesignTokens.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 40,
        vertical: isSmallScreen ? 20 : 40,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkBackground : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.3) : DesignTokens.borderColor(context),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isDark),
            if (_errorMessage != null) _buildErrorBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSportSelector(isDark),
                      const SizedBox(height: 20),
                      _buildDateTimeSection(isDark),
                      const SizedBox(height: 20),
                      _buildMainMetrics(isDark),
                      const SizedBox(height: 20),
                      _buildHeartRateSection(isDark),
                      const SizedBox(height: 20),
                      _buildIntensitySection(isDark),
                      const SizedBox(height: 20),
                      _buildMachineSection(isDark),
                      const SizedBox(height: 20),
                      _buildNotesSection(isDark),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.2) : DesignTokens.borderColor(context),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DesignTokens.accentBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_note,
              color: DesignTokens.accentBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.existingEntry == null ? 'Log Cardio Workout' : 'Edit Cardio Workout',
            style: TextStyle(
              color: isDark ? Colors.white : DesignTokens.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white.withValues(alpha: 0.7) : DesignTokens.iconColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.red.withValues(alpha: 0.2),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Type',
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ManualCardioService.availableSports.map((sport) {
            final isSelected = _selectedSport == sport;
            return ChoiceChip(
              label: Text(ManualCardioService.getSportDisplayName(sport)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedSport = sport);
              },
              selectedColor: DesignTokens.accentBlue.withValues(alpha: 0.3),
              backgroundColor: isDark ? DesignTokens.darkBackground : Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected 
                    ? DesignTokens.accentBlue 
                    : (isDark ? Colors.white.withValues(alpha: 0.7) : DesignTokens.textColorSecondary(context)),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected 
                    ? DesignTokens.accentBlue 
                    : (isDark ? DesignTokens.accentBlue.withValues(alpha: 0.2) : DesignTokens.borderColor(context)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time',
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.3) : DesignTokens.borderColor(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: DesignTokens.accentBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        style: TextStyle(
                          color: isDark ? Colors.white : DesignTokens.textColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.3) : DesignTokens.borderColor(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: DesignTokens.accentBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _startTime.format(context),
                        style: TextStyle(
                          color: isDark ? Colors.white : DesignTokens.textColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainMetrics(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workout Details',
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _durationController,
                label: 'Duration',
                hint: '30',
                suffix: 'min',
                icon: Icons.timer,
                isDark: isDark,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _distanceController,
                label: 'Distance',
                hint: '5.0',
                suffix: 'km',
                icon: Icons.straighten,
                isDark: isDark,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _caloriesController,
                label: 'Calories',
                hint: '300',
                suffix: 'kcal',
                icon: Icons.local_fire_department,
                isDark: isDark,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeartRateSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Heart Rate (Optional)',
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _avgHRController,
                label: 'Avg HR',
                hint: '140',
                suffix: 'bpm',
                icon: Icons.favorite,
                isDark: isDark,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _maxHRController,
                label: 'Max HR',
                hint: '170',
                suffix: 'bpm',
                icon: Icons.favorite_border,
                isDark: isDark,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntensitySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intensity',
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: ['Low', 'Medium', 'High'].map((intensity) {
            final isSelected = _intensity == intensity;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: intensity != 'High' ? 8 : 0,
                ),
                child: InkWell(
                  onTap: () => setState(() => _intensity = intensity),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? _getIntensityColor(intensity).withValues(alpha: 0.2)
                          : (isDark ? DesignTokens.accentBlue.withValues(alpha: 0.05) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? _getIntensityColor(intensity)
                            : (isDark ? DesignTokens.accentBlue.withValues(alpha: 0.2) : DesignTokens.borderColor(context)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        intensity,
                        style: TextStyle(
                          color: isSelected 
                              ? _getIntensityColor(intensity)
                              : (isDark ? Colors.white.withValues(alpha: 0.7) : DesignTokens.textColor(context)),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return DesignTokens.accentOrange;
      case 'High':
        return Colors.red;
      default:
        return DesignTokens.accentBlue;
    }
  }

  Widget _buildMachineSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Machine Type (Optional)',
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMachineChip(null, 'None', isDark),
            ...CardioMachineType.values.map((machine) =>
              _buildMachineChip(machine, machine.displayName, isDark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMachineChip(CardioMachineType? machine, String label, bool isDark) {
    final isSelected = _selectedMachine == machine;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedMachine = selected ? machine : null);
      },
      selectedColor: DesignTokens.accentOrange.withValues(alpha: 0.3),
      backgroundColor: isDark ? DesignTokens.darkBackground : Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected 
            ? DesignTokens.accentOrange 
            : (isDark ? Colors.white.withValues(alpha: 0.7) : DesignTokens.textColorSecondary(context)),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected 
            ? DesignTokens.accentOrange 
            : (isDark ? DesignTokens.accentBlue.withValues(alpha: 0.2) : DesignTokens.borderColor(context)),
      ),
    );
  }

  Widget _buildNotesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textColor(context),
          ),
          decoration: InputDecoration(
            hintText: 'How did the workout feel? Any notes...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.4) : DesignTokens.textColorSecondary(context),
            ),
            filled: true,
            fillColor: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.1) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.3) : DesignTokens.borderColor(context),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.3) : DesignTokens.borderColor(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DesignTokens.accentBlue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: DesignTokens.accentBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.8) : DesignTokens.textColor(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textColor(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.4) : DesignTokens.textColorSecondary(context),
            ),
            suffixText: suffix,
            suffixStyle: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.5) : DesignTokens.textColorSecondary(context),
            ),
            filled: true,
            fillColor: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.1) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.3) : DesignTokens.borderColor(context),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.3) : DesignTokens.borderColor(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DesignTokens.accentBlue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.2) : DesignTokens.borderColor(context),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.3) : DesignTokens.borderColor(context),
                ),
                foregroundColor: isDark ? Colors.white : DesignTokens.textColor(context),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: DesignTokens.accentBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: DesignTokens.accentBlue.withValues(alpha: 0.5),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.existingEntry == null ? 'Save Workout' : 'Update Workout',
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
}
