import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supplements/supplement_models.dart';
import '../../services/supplements/supplement_service.dart';
import '../../theme/design_tokens.dart';

class SupplementEditorSheet extends StatefulWidget {
  final Supplement? supplement;
  final String? clientId;
  final Function(Supplement) onSaved;

  const SupplementEditorSheet({
    super.key,
    this.supplement,
    this.clientId,
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
  int _intervalMinutes = 0;
  int _intervalSeconds = 0;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  bool _loading = false;

  // Client selection
  String? _selectedClientId;
  List<Map<String, dynamic>> _clients = [];
  bool _loadingClients = true;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.clientId;
    _loadClients();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Load clients linked to the current coach
      final links = await supabase
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', user.id);

      List<Map<String, dynamic>> clients = [];
      if (links.isNotEmpty) {
        final clientIds = links
            .map((row) => row['client_id'] as String)
            .toList();

        final response = await supabase
            .from('profiles')
            .select('id, name, email')
            .inFilter('id', clientIds);

        clients = List<Map<String, dynamic>>.from(response);
      }

      setState(() {
        _clients = clients;
        _loadingClients = false;

        // If no client was pre-selected and we have clients, select the first one
        if (_selectedClientId == null && clients.isNotEmpty) {
          _selectedClientId = clients.first['id'].toString();
        }
      });
    } catch (e) {
      setState(() => _loadingClients = false);
      debugPrint('Failed to load clients: $e');
    }
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

    // Validate client selection
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client first')),
      );
      return;
    }

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
          clientId: _selectedClientId!,
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
    } else if (_scheduleType == 'interval') {
      // Create interval schedule
      // Convert total interval to hours (with decimal precision)
      final totalSeconds = (_intervalHours * 3600) + (_intervalMinutes * 60) + _intervalSeconds;
      final intervalInHours = totalSeconds / 3600.0;

      final schedule = SupplementSchedule.create(
        supplementId: supplementId,
        scheduleType: 'interval',
        frequency: 'daily',
        timesPerDay: intervalInHours > 0 ? (24 / intervalInHours).round() : 1,
        intervalHours: intervalInHours.round(),
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

  Future<void> _showIntervalPicker() async {
    int tempHours = _intervalHours;
    int tempMinutes = _intervalMinutes;
    int tempSeconds = _intervalSeconds;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 350,
          decoration: const BoxDecoration(
            color: DesignTokens.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: DesignTokens.glassBorder),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: DesignTokens.textSecondary),
                      ),
                    ),
                    const Text(
                      'Select Interval',
                      style: TextStyle(
                        color: DesignTokens.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _intervalHours = tempHours;
                          _intervalMinutes = tempMinutes;
                          _intervalSeconds = tempSeconds;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: DesignTokens.accentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Picker
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hours
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _intervalHours,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (int index) {
                          tempHours = index;
                        },
                        selectionOverlay: Container(
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: DesignTokens.accentGreen.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        children: List<Widget>.generate(100, (int index) {
                          return Center(
                            child: Text(
                              '$index',
                              style: const TextStyle(
                                fontSize: 24,
                                color: DesignTokens.neutralWhite,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'h',
                        style: TextStyle(
                          fontSize: 20,
                          color: DesignTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Minutes
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _intervalMinutes,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (int index) {
                          tempMinutes = index;
                        },
                        selectionOverlay: Container(
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: DesignTokens.accentGreen.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        children: List<Widget>.generate(60, (int index) {
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 24,
                                color: DesignTokens.neutralWhite,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'm',
                        style: TextStyle(
                          fontSize: 20,
                          color: DesignTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Seconds
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _intervalSeconds,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (int index) {
                          tempSeconds = index;
                        },
                        selectionOverlay: Container(
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: DesignTokens.accentGreen.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        children: List<Widget>.generate(60, (int index) {
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 24,
                                color: DesignTokens.neutralWhite,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        's',
                        style: TextStyle(
                          fontSize: 20,
                          color: DesignTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.darkBackground,
      appBar: AppBar(
        backgroundColor: DesignTokens.primaryDark,
        foregroundColor: DesignTokens.neutralWhite,
        title: Text(
          widget.supplement != null ? 'Edit Supplement' : 'Add Supplement',
          style: const TextStyle(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.neutralWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client Selection
                    Text(
                      'Client',
                      style: DesignTokens.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space16),

                    if (_loadingClients)
                      const Center(child: CircularProgressIndicator())
                    else if (_clients.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(DesignTokens.space16),
                        decoration: BoxDecoration(
                          color: DesignTokens.blue50,
                          borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          border: Border.all(color: DesignTokens.blue50),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: DesignTokens.blue600),
                            SizedBox(width: DesignTokens.space8),
                            Expanded(
                              child: Text(
                                'No clients available. Please add clients first.',
                                style: TextStyle(color: DesignTokens.blue600),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedClientId,
                        decoration: const InputDecoration(
                          labelText: 'Select Client',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: _clients.map((client) {
                          final clientId = client['id']?.toString() ?? '';
                          final clientName = client['name'] ?? client['email'] ?? 'Unknown';
                          return DropdownMenuItem<String>(
                            value: clientId,
                            child: Text(clientName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedClientId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a client';
                          }
                          return null;
                        },
                      ),

                    const SizedBox(height: DesignTokens.space24),

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
                      segments: const [
                        ButtonSegment(
                          value: 'fixed_times',
                          label: Text('Fixed Times'),
                          icon: Icon(Icons.schedule),
                        ),
                        ButtonSegment(
                          value: 'interval',
                          label: Text('Every N Hours'),
                          icon: Icon(Icons.timer),
                        ),
                      ],
                      selected: {_scheduleType},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() {
                          _scheduleType = selection.first;
                        });
                      },
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
                    ] else if (_scheduleType == 'interval') ...[
                      // Interval Hours Selection
                      Text(
                        'Interval',
                        style: DesignTokens.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space8),

                      InkWell(
                        onTap: _showIntervalPicker,
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space16,
                            vertical: DesignTokens.space16,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.cardBackground,
                            border: Border.all(
                              color: DesignTokens.accentGreen.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.schedule,
                                color: DesignTokens.accentGreen,
                                size: 24,
                              ),
                              const SizedBox(width: DesignTokens.space12),
                              Text(
                                'Every ${_intervalHours}h ${_intervalMinutes.toString().padLeft(2, '0')}m ${_intervalSeconds.toString().padLeft(2, '0')}s',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: DesignTokens.neutralWhite,
                                ),
                              ),
                              const SizedBox(width: DesignTokens.space12),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: DesignTokens.textSecondary,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
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
                    const SizedBox(height: DesignTokens.space32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _saveSupplement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.accentGreen,
                          foregroundColor: DesignTokens.primaryDark,
                          padding: const EdgeInsets.all(DesignTokens.space16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radius12),
                          ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space24),
                  ],
                ),
              ),
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
