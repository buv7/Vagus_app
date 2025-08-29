import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supplements/supplement_models.dart';
import '../../services/supplements/supplement_service.dart';
import '../../services/billing/plan_access_manager.dart';
import '../../theme/design_tokens.dart';

class SupplementEditorSheet extends StatefulWidget {
  final Supplement? supplement;
  final String clientId;
  final Function(Supplement) onSaved;

  const SupplementEditorSheet({
    super.key,
    this.supplement,
    required this.clientId,
    required this.onSaved,
  });

  @override
  State<SupplementEditorSheet> createState() => _SupplementEditorSheetState();
}

class _SupplementEditorSheetState extends State<SupplementEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  String _selectedCategory = 'general';
  String _selectedIcon = 'medication';
  String _selectedColor = '#6C83F7';
  
  // Schedule fields
  String _scheduleType = 'fixed_times';
  final List<int> _selectedDaysOfWeek = [];
  final List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
  int _intervalHours = 12;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  
  bool _loading = false;
  bool _isProUser = false;

  @override
  void initState() {
    super.initState();
    _loadProStatus();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadProStatus() async {
    final isPro = await PlanAccessManager.instance.isProUser();
    setState(() => _isProUser = isPro);
  }

  void _initializeForm() {
    if (widget.supplement != null) {
      final supplement = widget.supplement!;
      _nameController.text = supplement.name;
      _dosageController.text = supplement.dosage;
      _instructionsController.text = supplement.instructions ?? '';
      _selectedCategory = supplement.category;
      _selectedIcon = supplement.icon;
      _selectedColor = supplement.color;
    }
  }

  Future<void> _saveSupplement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      Supplement supplement;
      if (widget.supplement != null) {
        // Update existing supplement
        supplement = widget.supplement!.copyWith(
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          instructions: _instructionsController.text.trim().isEmpty 
              ? null 
              : _instructionsController.text.trim(),
          category: _selectedCategory,
          icon: _selectedIcon,
          color: _selectedColor,
          updatedAt: DateTime.now(),
        );
        await SupplementService.instance.updateSupplement(supplement);
      } else {
        // Create new supplement
        supplement = Supplement.create(
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          instructions: _instructionsController.text.trim().isEmpty 
              ? null 
              : _instructionsController.text.trim(),
          category: _selectedCategory,
          icon: _selectedIcon,
          color: _selectedColor,
          createdBy: currentUser.id,
          clientId: widget.clientId,
        );
        supplement = await SupplementService.instance.createSupplement(supplement);
      }

      // Create or update schedule
      await _saveSchedule(supplement.id);

      if (!context.mounted) return;
      widget.onSaved(supplement);
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save supplement: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
    if (!mounted) return;
  }

  Future<void> _saveSchedule(String supplementId) async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    // Delete existing schedules for this supplement
    await supabase
        .from('supplement_schedules')
        .delete()
        .eq('supplement_id', supplementId);

    if (_scheduleType == 'fixed_times' && _selectedDaysOfWeek.isNotEmpty && _selectedTimes.isNotEmpty) {
      // Create fixed times schedule
      final schedule = SupplementSchedule.create(
        supplementId: supplementId,
        scheduleType: 'fixed_times',
        frequency: 'weekly',
        timesPerDay: _selectedTimes.length,
        specificTimes: _selectedTimes.map((time) => 
          DateTime(2024, 1, 1, time.hour, time.minute)
        ).toList(),
        daysOfWeek: _selectedDaysOfWeek,
        startDate: _startDate,
        endDate: _endDate,
        createdBy: currentUser.id,
      );
      await SupplementService.instance.createSchedule(schedule);
    } else if (_scheduleType == 'interval' && _isProUser) {
      // Create interval schedule (Pro only)
      final schedule = SupplementSchedule.create(
        supplementId: supplementId,
        scheduleType: 'interval',
        frequency: 'daily',
        timesPerDay: (24 / _intervalHours).round(),
        intervalHours: _intervalHours,
        startDate: _startDate,
        endDate: _endDate,
        createdBy: currentUser.id,
      );
      await SupplementService.instance.createSchedule(schedule);
    }
  }

  void _addTime() {
    setState(() {
      _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
    });
  }

  void _removeTime(int index) {
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  void _updateTime(int index, TimeOfDay time) {
    setState(() {
      _selectedTimes[index] = time;
    });
  }

  void _toggleDayOfWeek(int day) {
    setState(() {
      if (_selectedDaysOfWeek.contains(day)) {
        _selectedDaysOfWeek.remove(day);
      } else {
        _selectedDaysOfWeek.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
            decoration: const BoxDecoration(
              color: DesignTokens.ink50,
                           border: Border(
               bottom: BorderSide(color: DesignTokens.ink100),
             ),
            ),
            child: Row(
              children: [
                Text(
                  widget.supplement != null ? 'Edit Supplement' : 'Add Supplement',
                  style: DesignTokens.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info
                    Text(
                      'Basic Information',
                      style: DesignTokens.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space16),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Supplement Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a supplement name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: DesignTokens.space16),
                    
                    TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 500mg, 1 capsule',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter dosage information';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: DesignTokens.space16),
                    
                    TextFormField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Take with food, Avoid dairy',
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: DesignTokens.space24),
                    
                    // Schedule Section
                    Text(
                      'Schedule',
                      style: DesignTokens.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space16),
                    
                    // Schedule Type Selection
                    SegmentedButton<String>(
                      segments: [
                        const ButtonSegment(
                          value: 'fixed_times',
                          label: Text('Fixed Times'),
                          icon: Icon(Icons.schedule),
                        ),
                        ButtonSegment(
                          value: 'interval',
                          label: const Text('Every N Hours'),
                          icon: const Icon(Icons.timer),
                          enabled: _isProUser,
                        ),
                      ],
                      selected: {_scheduleType},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() {
                          _scheduleType = selection.first;
                        });
                      },
                    ),
                    
                    if (!_isProUser && _scheduleType == 'interval')
                      Container(
                        margin: const EdgeInsets.only(top: DesignTokens.space8),
                        padding: const EdgeInsets.all(DesignTokens.space8),
                        decoration: BoxDecoration(
                          color: DesignTokens.blue50,
                          borderRadius: BorderRadius.circular(DesignTokens.radius4),
                          border: Border.all(color: DesignTokens.blue50),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, 
                              color: DesignTokens.blue600, size: 16),
                            const SizedBox(width: DesignTokens.space4),
                            Expanded(
                              child: Text(
                                'Every N hours schedules are available for Pro users only',
                                style: DesignTokens.bodySmall.copyWith(
                                  color: DesignTokens.blue600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: DesignTokens.space16),
                    
                    if (_scheduleType == 'fixed_times') ...[
                      // Days of Week Selection
                      Text(
                        'Days of Week',
                        style: DesignTokens.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space8),
                      
                      Wrap(
                        spacing: DesignTokens.space8,
                        children: [
                          for (int i = 1; i <= 7; i++)
                            FilterChip(
                              label: Text(_getDayName(i)),
                              selected: _selectedDaysOfWeek.contains(i),
                              onSelected: (_) => _toggleDayOfWeek(i),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: DesignTokens.space16),
                      
                      // Times Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Times',
                            style: DesignTokens.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addTime,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Time'),
                          ),
                        ],
                      ),
                      
                      ...List.generate(_selectedTimes.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: DesignTokens.space8),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: _selectedTimes[index],
                                    );
                                    if (time != null) {
                                      _updateTime(index, time);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(DesignTokens.space12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: DesignTokens.ink500),
                                      borderRadius: BorderRadius.circular(DesignTokens.radius4),
                                    ),
                                    child: Text(
                                      _selectedTimes[index].format(context),
                                      style: DesignTokens.bodyMedium,
                                    ),
                                  ),
                                ),
                              ),
                              if (_selectedTimes.length > 1) ...[
                                const SizedBox(width: DesignTokens.space8),
                                IconButton(
                                  onPressed: () => _removeTime(index),
                                                                   icon: const Icon(Icons.remove_circle_outline),
                                 color: DesignTokens.danger,
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ] else if (_scheduleType == 'interval' && _isProUser) ...[
                      // Interval Hours Selection
                      Text(
                        'Interval (hours)',
                        style: DesignTokens.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space8),
                      
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_intervalHours > 1) {
                                setState(() => _intervalHours--);
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Expanded(
                            child: Text(
                              'Every $_intervalHours hours',
                              textAlign: TextAlign.center,
                              style: DesignTokens.titleMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_intervalHours < 24) {
                                setState(() => _intervalHours++);
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: DesignTokens.space16),
                    
                    // Date Range
                    Text(
                      'Date Range',
                      style: DesignTokens.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => _startDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(DesignTokens.space12),
                              decoration: BoxDecoration(
                                border: Border.all(color: DesignTokens.ink500),
                                borderRadius: BorderRadius.circular(DesignTokens.radius4),
                              ),
                              child: Text(
                                'Start: ${DateFormat('MMM dd, yyyy').format(_startDate)}',
                                style: DesignTokens.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: DesignTokens.space16),
                        
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                                firstDate: _startDate,
                                lastDate: _startDate.add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => _endDate = date);
                              }
                            },
                                                          child: Container(
                                padding: const EdgeInsets.all(DesignTokens.space12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: DesignTokens.ink500),
                                  borderRadius: BorderRadius.circular(DesignTokens.radius4),
                                ),
                                child: Text(
                                  _endDate != null 
                                      ? 'End: ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                                      : 'End: No end date',
                                  style: DesignTokens.bodyMedium,
                                ),
                              ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: DesignTokens.space24),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _saveSupplement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.blue600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(DesignTokens.space16),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                widget.supplement != null ? 'Update Supplement' : 'Create Supplement',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}
