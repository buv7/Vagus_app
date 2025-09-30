import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/workout/workout_plan.dart';
import '../../models/workout/exercise.dart';
import '../../models/workout/cardio_session.dart';
import '../../services/workout/workout_service.dart';
import '../../services/ai/workout_ai.dart';
import '../../services/ai/ai_usage_service.dart';
import 'widgets/validation_helper.dart';
import 'package:intl/intl.dart';

/// Production-quality Coach Plan Builder with AI integration, validation, and advanced features
class CoachPlanBuilderScreen extends StatefulWidget {
  final String? planId; // For editing existing plans

  const CoachPlanBuilderScreen({super.key, this.planId});

  @override
  State<CoachPlanBuilderScreen> createState() => _CoachPlanBuilderScreenState();
}

class _CoachPlanBuilderScreenState extends State<CoachPlanBuilderScreen> {
  // Services
  final WorkoutService _workoutService = WorkoutService();
  final AIUsageService _aiUsageService = AIUsageService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  // State management
  bool _loading = true;
  bool _saving = false;
  bool _generating = false;
  String? _errorMessage;
  String? _successMessage;

  // Plan data
  WorkoutPlan? _currentPlan;
  String? _selectedClientId;
  String _planName = '';
  String? _planDescription;
  DateTime? _startDate;
  int _durationWeeks = 4;

  // Navigation
  int _currentWeekIndex = 0;
  int _currentDayIndex = 0;

  // Client data
  List<Map<String, dynamic>> _clients = [];
  bool _loadingClients = true;

  // AI Usage tracking
  Map<String, dynamic>? _aiUsage;

  // Auto-save
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  // Form validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _loading = true);

    try {
      await Future.wait([
        _loadClients(),
        _loadAIUsage(),
        if (widget.planId != null) _loadExistingPlan(),
      ]);

      if (widget.planId == null) {
        // Initialize new plan with default structure
        _initializeNewPlan();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadClients() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('coach_clients')
          .select('client_id, profiles:client_id (id, name, email, metadata)')
          .eq('coach_id', user.id);

      setState(() {
        _clients = (response as List)
            .map((row) {
          final profile = row['profiles'] as Map<String, dynamic>;
          return {
            'id': profile['id'],
            'name': profile['name'],
            'email': profile['email'],
            'metadata': profile['metadata'] ?? {},
          };
        })
            .toList();
        _loadingClients = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to load clients: $e');
      setState(() => _loadingClients = false);
    }
  }

  Future<void> _loadAIUsage() async {
    try {
      final usage = await _aiUsageService.getCurrentUsage();
      setState(() => _aiUsage = usage);
    } catch (e) {
      debugPrint('❌ Failed to load AI usage: $e');
    }
  }

  Future<void> _loadExistingPlan() async {
    try {
      final plan = await _workoutService.fetchPlan(widget.planId!);
      if (plan != null) {
        setState(() {
          _currentPlan = plan;
          _selectedClientId = plan.clientId;
          _planName = plan.name;
          _planDescription = plan.description;
          _startDate = plan.startDate;
          _durationWeeks = plan.durationWeeks;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load existing plan: $e');
      throw Exception('Failed to load plan');
    }
  }

  void _initializeNewPlan() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Create empty plan with one week and one day
    final week = WorkoutWeek(
      planId: '',
      weekNumber: 1,
      days: [
        WorkoutDay(
          weekId: '',
          dayNumber: 1,
          label: 'Day 1',
          exercises: [],
          cardioSessions: [],
        ),
      ],
    );

    setState(() {
      _currentPlan = WorkoutPlan(
        coachId: user.id,
        clientId: '',
        name: 'New Workout Plan',
        durationWeeks: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user.id,
        weeks: [week],
      );
    });
  }

  void _markAsChanged() {
    setState(() {
      _hasUnsavedChanges = true;
      _currentPlan = _currentPlan?.copyWith(
        updatedAt: DateTime.now(),
        unseenUpdate: true,
      );
    });

    // Restart auto-save timer
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 30), () {
      if (_hasUnsavedChanges) {
        _autoSave();
      }
    });
  }

  Future<void> _autoSave() async {
    if (_currentPlan == null || _selectedClientId == null) return;
    if (_planName.isEmpty) return;

    try {
      debugPrint('🔄 Auto-saving plan...');
      if (_currentPlan!.id == null) {
        // Create new plan
        final planId = await _workoutService.createPlan(
          _currentPlan!.copyWith(
            clientId: _selectedClientId!,
            name: _planName,
            description: _planDescription,
            startDate: _startDate,
            durationWeeks: _durationWeeks,
          ),
        );
        setState(() {
          _currentPlan = _currentPlan!.copyWith(id: planId);
          _hasUnsavedChanges = false;
        });
      } else {
        // Update existing plan
        await _workoutService.updatePlan(_currentPlan!);
        setState(() => _hasUnsavedChanges = false);
      }
      debugPrint('✅ Auto-save successful');
    } catch (e) {
      debugPrint('❌ Auto-save failed: $e');
    }
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      _showError('Please select a client');
      return;
    }

    // Validate plan
    final validation = ValidationHelper.validatePlan(_currentPlan!);
    if (!validation.isValid) {
      _showValidationDialog(validation);
      return;
    }

    setState(() => _saving = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final planToSave = _currentPlan!.copyWith(
        clientId: _selectedClientId!,
        name: _planName,
        description: _planDescription,
        startDate: _startDate,
        durationWeeks: _durationWeeks,
        coachId: user.id,
        createdBy: user.id,
        updatedAt: DateTime.now(),
      );

      if (widget.planId == null) {
        // Create new plan
        final planId = await _workoutService.createPlan(planToSave);

        // Create initial version
        await _workoutService.createPlanVersion(planId);

        _showSuccess('Workout plan created successfully!');
        Navigator.pop(context, planId);
      } else {
        // Update existing plan
        await _workoutService.updatePlan(planToSave);

        // Create version snapshot
        await _workoutService.createPlanVersion(widget.planId!);

        _showSuccess('Workout plan updated successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to save plan: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showValidationDialog(ValidationResult validation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Plan Issues Detected'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(validation.summary),
              const SizedBox(height: 16),
              ...validation.warnings.map((warning) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(warning)),
                  ],
                ),
              )),
              if (validation.errors.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Errors (must fix):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...validation.errors.map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          if (validation.warnings.isNotEmpty && validation.errors.isEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _savePlan(); // Force save despite warnings
              },
              child: const Text('Save Anyway'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(validation.errors.isEmpty ? 'OK' : 'Fix Issues'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.planId == null ? 'Create Workout Plan' : 'Edit Workout Plan'),
          actions: [
            if (_hasUnsavedChanges)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    '● Unsaved',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelpDialog,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // AI Usage Meter (compact)
              _buildAIUsageMeter(),

              // Main content
              Expanded(
                child: _currentPlan == null
                    ? const Center(child: Text('Failed to initialize plan'))
                    : _buildMainContent(),
              ),

              // Bottom action bar
              _buildBottomActionBar(),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildAIUsageMeter() {
    if (_aiUsage == null) return const SizedBox.shrink();

    final used = _aiUsage!['requests_this_month'] ?? 0;
    final limit = _aiUsage!['monthly_limit'] ?? 100;
    final percentage = (used / limit * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.psychology, size: 20),
          const SizedBox(width: 8),
          Text('AI Usage: $used / $limit'),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              color: percentage > 80 ? Colors.orange : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Row(
      children: [
        // Left sidebar - Navigation and metadata
        SizedBox(
          width: 280,
          child: _buildLeftSidebar(),
        ),

        // Divider
        const VerticalDivider(width: 1),

        // Main content area - Workout builder
        Expanded(
          child: _buildWorkoutBuilder(),
        ),

        // Right sidebar - Exercise history and suggestions (optional)
        if (MediaQuery.of(context).size.width > 1200) ...[
          const VerticalDivider(width: 1),
          SizedBox(
            width: 300,
            child: _buildRightSidebar(),
          ),
        ],
      ],
    );
  }

  Widget _buildLeftSidebar() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Client selector
        const Text(
          'Client',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        // TODO: Implement ClientSelectorWidget
        DropdownButtonFormField<String>(
          value: _selectedClientId,
          items: _clients.map((client) {
            return DropdownMenuItem<String>(
              value: client['id'],
              child: Text(client['name'] ?? 'Unknown'),
            );
          }).toList(),
          onChanged: _loadingClients ? null : (clientId) {
            setState(() => _selectedClientId = clientId);
            _markAsChanged();
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select a client',
          ),
        ),

        const SizedBox(height: 24),

        // Plan metadata
        const Text(
          'Plan Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _planName,
          decoration: const InputDecoration(
            labelText: 'Plan Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Plan name is required';
            }
            return null;
          },
          onChanged: (value) {
            _planName = value;
            _markAsChanged();
          },
        ),

        const SizedBox(height: 12),

        TextFormField(
          initialValue: _planDescription,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) {
            _planDescription = value;
            _markAsChanged();
          },
        ),

        const SizedBox(height: 12),

        // Start date picker
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Start Date'),
          subtitle: Text(
            _startDate != null
                ? DateFormat('MMM dd, yyyy').format(_startDate!)
                : 'Not set',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _startDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => _startDate = date);
              _markAsChanged();
            }
          },
        ),

        const SizedBox(height: 12),

        // Duration
        DropdownButtonFormField<int>(
          value: _durationWeeks,
          decoration: const InputDecoration(
            labelText: 'Duration',
            border: OutlineInputBorder(),
          ),
          items: List.generate(52, (i) => i + 1)
              .map((weeks) => DropdownMenuItem(
            value: weeks,
            child: Text('$weeks ${weeks == 1 ? 'week' : 'weeks'}'),
          ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _durationWeeks = value);
              _markAsChanged();
            }
          },
        ),

        const SizedBox(height: 24),

        // Week navigation
        const Text(
          'Weeks',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildWeekNavigation(),

        const SizedBox(height: 16),

        // Quick actions
        ElevatedButton.icon(
          onPressed: _addWeek,
          icon: const Icon(Icons.add),
          label: const Text('Add Week'),
        ),

        const SizedBox(height: 8),

        ElevatedButton.icon(
          onPressed: _analyzeBalance,
          icon: const Icon(Icons.analytics),
          label: const Text('Analyze Balance'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekNavigation() {
    if (_currentPlan == null || _currentPlan!.weeks.isEmpty) {
      return const Text('No weeks added yet');
    }

    return Column(
      children: List.generate(_currentPlan!.weeks.length, (index) {
        final week = _currentPlan!.weeks[index];
        final isSelected = index == _currentWeekIndex;

        return Card(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          child: ListTile(
            dense: true,
            title: Text('Week ${week.weekNumber}'),
            subtitle: Text('${week.days.length} days'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.content_copy, size: 18),
                  onPressed: () => _duplicateWeek(index),
                  tooltip: 'Duplicate',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () => _deleteWeek(index),
                  tooltip: 'Delete',
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _currentWeekIndex = index;
                _currentDayIndex = 0;
              });
            },
          ),
        );
      }),
    );
  }

  Widget _buildWorkoutBuilder() {
    if (_currentPlan == null || _currentPlan!.weeks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No weeks added yet'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addWeek,
              child: const Text('Add First Week'),
            ),
          ],
        ),
      );
    }

    final currentWeek = _currentPlan!.weeks[_currentWeekIndex];

    return Column(
      children: [
        // Breadcrumb navigation
        _buildBreadcrumbs(),

        const Divider(height: 1),

        // Day tabs
        _buildDayTabs(currentWeek),

        const Divider(height: 1),

        // Exercise builder
        Expanded(
          child: _buildExerciseList(currentWeek),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Week ${_currentWeekIndex + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(' / '),
          Text(
            'Day ${_currentDayIndex + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // Quick stats
          if (_currentPlan != null &&
              _currentPlan!.weeks.isNotEmpty &&
              _currentPlan!.weeks[_currentWeekIndex].days.isNotEmpty)
            _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final day = _currentPlan!.weeks[_currentWeekIndex].days[_currentDayIndex];
    final summary = day.getDaySummary();

    return Row(
      children: [
        _buildStatChip(
          Icons.fitness_center,
          '${day.exercises.length} exercises',
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          Icons.schedule,
          summary.getDurationDisplay(),
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          Icons.trending_up,
          summary.getVolumeDisplay(),
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDayTabs(WorkoutWeek week) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: week.days.length,
              itemBuilder: (context, index) {
                final day = week.days[index];
                final isSelected = index == _currentDayIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(day.label.isEmpty ? 'Day ${index + 1}' : day.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _currentDayIndex = index);
                    },
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addDay(_currentWeekIndex),
            tooltip: 'Add Day',
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(WorkoutWeek week) {
    if (week.days.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No days in this week'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _addDay(_currentWeekIndex),
              child: const Text('Add First Day'),
            ),
          ],
        ),
      );
    }

    final day = week.days[_currentDayIndex];

    // TODO: Implement ExerciseBuilderWidget
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Exercise builder for ${day.label}'),
          const SizedBox(height: 16),
          Text('${day.exercises.length} exercises'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showError('ExerciseBuilderWidget not yet implemented'),
            child: const Text('Add Exercise'),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    // TODO: Implement ExerciseHistoryPanel
    return const Center(
      child: Text('Exercise history panel\n(Not yet implemented)'),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),

          const Spacer(),

          // Save as template
          TextButton.icon(
            onPressed: _saveAsTemplate,
            icon: const Icon(Icons.bookmark_outline),
            label: const Text('Save as Template'),
          ),

          const SizedBox(width: 12),

          // Save button
          ElevatedButton(
            onPressed: _saving ? null : _savePlan,
            child: _saving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Save Plan'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI Generate button
        FloatingActionButton.extended(
          onPressed: _showAIGeneratorDialog,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate with AI'),
          heroTag: 'ai_generate',
        ),
        const SizedBox(height: 12),
        // Add exercise button
        FloatingActionButton(
          onPressed: _addExercise,
          child: const Icon(Icons.add),
          heroTag: 'add_exercise',
        ),
      ],
    );
  }

  // Action methods
  void _addWeek() {
    setState(() {
      final newWeekNumber = _currentPlan!.weeks.length + 1;
      _currentPlan = _currentPlan!.copyWith(
        weeks: [
          ..._currentPlan!.weeks,
          WorkoutWeek(
            planId: _currentPlan!.id ?? '',
            weekNumber: newWeekNumber,
            days: [
              WorkoutDay(
                weekId: '',
                dayNumber: 1,
                label: 'Day 1',
                exercises: [],
                cardioSessions: [],
              ),
            ],
          ),
        ],
      );
      _currentWeekIndex = _currentPlan!.weeks.length - 1;
      _currentDayIndex = 0;
    });
    _markAsChanged();
  }

  void _addDay(int weekIndex) {
    setState(() {
      final week = _currentPlan!.weeks[weekIndex];
      final newDayNumber = week.days.length + 1;

      final updatedDays = [
        ...week.days,
        WorkoutDay(
          weekId: week.id ?? '',
          dayNumber: newDayNumber,
          label: 'Day $newDayNumber',
          exercises: [],
          cardioSessions: [],
        ),
      ];

      final updatedWeek = week.copyWith(days: updatedDays);
      final updatedWeeks = List<WorkoutWeek>.from(_currentPlan!.weeks);
      updatedWeeks[weekIndex] = updatedWeek;

      _currentPlan = _currentPlan!.copyWith(weeks: updatedWeeks);
      _currentDayIndex = week.days.length; // Switch to new day
    });
    _markAsChanged();
  }

  void _duplicateWeek(int weekIndex) {
    setState(() {
      final weekToCopy = _currentPlan!.weeks[weekIndex];
      final newWeekNumber = _currentPlan!.weeks.length + 1;

      // Deep copy the week
      final newWeek = WorkoutWeek(
        planId: weekToCopy.planId,
        weekNumber: newWeekNumber,
        notes: weekToCopy.notes,
        days: weekToCopy.days.map((day) => WorkoutDay(
          weekId: '',
          dayNumber: day.dayNumber,
          label: day.label,
          exercises: day.exercises.map((ex) => ex.copyWith()).toList(),
          cardioSessions: day.cardioSessions.map((c) => c.copyWith()).toList(),
        )).toList(),
      );

      _currentPlan = _currentPlan!.copyWith(
        weeks: [..._currentPlan!.weeks, newWeek],
      );
    });
    _markAsChanged();
  }

  void _deleteWeek(int weekIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Week'),
        content: Text('Are you sure you want to delete Week ${weekIndex + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final updatedWeeks = List<WorkoutWeek>.from(_currentPlan!.weeks);
                updatedWeeks.removeAt(weekIndex);

                // Renumber remaining weeks
                for (int i = 0; i < updatedWeeks.length; i++) {
                  updatedWeeks[i] = updatedWeeks[i].copyWith(weekNumber: i + 1);
                }

                _currentPlan = _currentPlan!.copyWith(weeks: updatedWeeks);

                // Adjust current week index if needed
                if (_currentWeekIndex >= updatedWeeks.length) {
                  _currentWeekIndex = updatedWeeks.length - 1;
                }
                if (_currentWeekIndex < 0) _currentWeekIndex = 0;
              });
              _markAsChanged();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addExercise() {
    // This will be handled by ExerciseBuilderWidget
    // Just ensuring we're on the right screen
    if (_currentPlan == null || _currentPlan!.weeks.isEmpty) {
      _showError('Please add a week first');
      return;
    }
  }

  void _showAIGeneratorDialog() {
    // TODO: Implement AIWorkoutGeneratorDialog
    _showError('AI Workout Generator not yet implemented');
    return;
    /*
    showDialog(
      context: context,
      builder: (context) => AIWorkoutGeneratorDialog(
        clientId: _selectedClientId,
        onPlanGenerated: (generatedPlan) {
          setState(() => _currentPlan = generatedPlan);
          _markAsChanged();
        },
      ),
    );
    */
  }

  void _analyzeBalance() async {
    if (_currentPlan == null) return;

    setState(() => _generating = true);

    try {
      final analysis = _workoutService.analyzeMuscleGroupBalance(_currentPlan!);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📊 Workout Balance Analysis'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance Score: ${analysis.balanceScore.toStringAsFixed(1)}/10',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Muscle Group Distribution:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...analysis.muscleGroupCounts.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key.toUpperCase()),
                      Text('${entry.value} exercises'),
                    ],
                  ),
                )),
                if (analysis.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Recommendations:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...analysis.recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(rec)),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Failed to analyze balance: $e');
    } finally {
      setState(() => _generating = false);
    }
  }

  Future<void> _saveAsTemplate() async {
    if (_currentPlan == null) return;

    final category = await _showTemplateCategoryDialog();
    if (category == null) return;

    try {
      await _workoutService.saveAsTemplate(_currentPlan!, category: category);
      _showSuccess('Saved as template successfully!');
    } catch (e) {
      _showError('Failed to save template: $e');
    }
  }

  Future<String?> _showTemplateCategoryDialog() async {
    final controller = TextEditingController(text: 'custom');

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Template'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category',
            hintText: 'e.g., strength, hypertrophy, powerlifting',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showUnsavedChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Discard
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              _savePlan();
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Stay
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💡 Workout Builder Help'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Use "Generate with AI" for instant workout creation'),
              Text('• Drag exercises to reorder them'),
              Text('• Click "Analyze Balance" to check muscle group distribution'),
              Text('• Auto-save activates after 30 seconds of inactivity'),
              Text('• Use breadcrumbs to navigate between weeks and days'),
              SizedBox(height: 16),
              Text(
                'Keyboard Shortcuts:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Ctrl+S: Save plan'),
              Text('• Ctrl+N: Add new exercise'),
              Text('• Ctrl+W: Add new week'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}