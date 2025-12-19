import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'dart:async';

// Models
import '../../models/workout/workout_plan.dart';
import '../../models/workout/exercise.dart';
import '../../models/workout/cardio_session.dart';

// Services
import '../../services/workout/workout_service.dart';
import '../../services/nutrition/locale_helper.dart';

// Theme
import '../../theme/design_tokens.dart';

// Data

// Widgets
import '../../widgets/workout/exercise_picker_dialog.dart';
import '../../widgets/workout/advanced_exercise_editor.dart';
import '../../widgets/workout/cardio_editor_dialog.dart';

// Screens
import 'weekly_volume_detail_screen.dart';

/// Revolutionary Workout Plan Builder - The centerpiece of VAGUS
/// A premium, feature-rich workout plan creation and editing experience
class RevolutionaryPlanBuilderScreen extends StatefulWidget {
  final String? planId;
  final String? clientId;
  final bool isTemplate;

  const RevolutionaryPlanBuilderScreen({
    super.key,
    this.planId,
    this.clientId,
    this.isTemplate = false,
  });

  @override
  State<RevolutionaryPlanBuilderScreen> createState() =>
      _RevolutionaryPlanBuilderScreenState();
}

class _RevolutionaryPlanBuilderScreenState
    extends State<RevolutionaryPlanBuilderScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  // ==================== SERVICES ====================
  final _workoutService = WorkoutService();
  final _supabase = Supabase.instance.client;

  // ==================== STATE MANAGEMENT ====================

  // Plan Data
  WorkoutPlan? _currentPlan;
  String _planName = '';
  String? _planDescription;
  int _durationWeeks = 4;
  DateTime? _startDate;
  String? _selectedClientId;

  // UI State
  int _selectedWeekIndex = 0;
  int _selectedDayIndex = 0;
  bool _loading = true;
  String? _error;

  // Layout State
  bool _leftSidebarCollapsed = false;
  bool _rightSidebarCollapsed = false;
  bool _analyticsPanelExpanded = false;
  bool _fabExpanded = false;

  // Undo/Redo
  final List<WorkoutPlan?> _undoHistory = [];
  int _historyIndex = -1;

  // Auto-save
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  DateTime? _lastSaved;

  // Data
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _exerciseLibrary = [];

  // Animation Controllers
  late AnimationController _mainAnimController;
  late AnimationController _sidebarAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Focus
  final FocusNode _planNameFocus = FocusNode();

  // Keyboard shortcuts (removed - requires Flutter 3.19+ Intent system)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _loadInitialData();
    _startAutoSave();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _mainAnimController.dispose();
    _sidebarAnimController.dispose();
    _planNameFocus.dispose();
    super.dispose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeAnimations() {
    _mainAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _sidebarAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainAnimController, curve: Curves.easeOutCubic),
    );

    _mainAnimController.forward();
  }

  // Keyboard shortcuts removed - requires Flutter 3.19+ Intent system
  // Users can still use buttons in UI for Save, Undo, Redo actions
  // TODO: Implement Intent-based shortcuts when Flutter 3.19+ is available

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Load in parallel
      await Future.wait([
        _loadClients(),
        _loadExerciseLibrary(),
        if (widget.planId != null) _loadExistingPlan(),
      ]);

      // Initialize empty plan if needed
      if (widget.planId == null && _currentPlan == null) {
        _initializeEmptyPlan();
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadClients() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final response = await _supabase
        .from('profiles')
        .select('id, full_name, email')
        .eq('role', 'client')
        .order('full_name');

    setState(() {
      _clients = List<Map<String, dynamic>>.from(response as List);
    });
  }

  Future<void> _loadExerciseLibrary() async {
    // TODO: Load from exercise_library table
    // Placeholder data for now
    setState(() {
      _exerciseLibrary = [
        {'name': 'Bench Press', 'category': 'chest', 'equipment': 'barbell'},
        {'name': 'Squat', 'category': 'legs', 'equipment': 'barbell'},
        {'name': 'Deadlift', 'category': 'back', 'equipment': 'barbell'},
        {'name': 'Pull-up', 'category': 'back', 'equipment': 'bodyweight'},
        {'name': 'Shoulder Press', 'category': 'shoulders', 'equipment': 'dumbbell'},
      ];
    });
  }

  Future<void> _loadExistingPlan() async {
    if (widget.planId == null) return;

    final plan = await _workoutService.fetchPlan(widget.planId!);
    if (plan != null) {
      setState(() {
        _currentPlan = plan;
        _planName = plan.name;
        _planDescription = plan.description;
        _durationWeeks = plan.durationWeeks;
        _startDate = plan.startDate;
        _selectedClientId = plan.clientId;
        _saveToHistory();
      });
    }
  }

  void _initializeEmptyPlan() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final weeks = List.generate(
      _durationWeeks,
      (weekIndex) => WorkoutWeek(
        planId: '',
        weekNumber: weekIndex + 1,
        days: List.generate(
          7,
          (dayIndex) => WorkoutDay(
            weekId: '',
            dayNumber: dayIndex + 1,
            label: _getDayLabel(dayIndex),
          ),
        ),
      ),
    );

    _currentPlan = WorkoutPlan(
      coachId: user.id,
      clientId: widget.clientId ?? _selectedClientId ?? '',
      name: _planName.isEmpty ? 'Untitled Plan' : _planName,
      description: _planDescription,
      durationWeeks: _durationWeeks,
      startDate: _startDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: user.id,
      isTemplate: widget.isTemplate,
      weeks: weeks,
    );

    _saveToHistory();
  }

  String _getDayLabel(int dayIndex) {
    const labels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return labels[dayIndex];
  }

  // ==================== UNDO/REDO ====================

  void _saveToHistory() {
    if (_currentPlan == null) return;

    // Remove any history after current index
    if (_historyIndex < _undoHistory.length - 1) {
      _undoHistory.removeRange(_historyIndex + 1, _undoHistory.length);
    }

    // Add current state
    _undoHistory.add(_clonePlan(_currentPlan!));
    _historyIndex = _undoHistory.length - 1;

    // Limit history size
    if (_undoHistory.length > 50) {
      _undoHistory.removeAt(0);
      _historyIndex--;
    }

    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  WorkoutPlan _clonePlan(WorkoutPlan plan) {
    return WorkoutPlan.fromMap(plan.toMap());
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _currentPlan = _clonePlan(_undoHistory[_historyIndex]!);
        _hasUnsavedChanges = true;
      });
    }
  }

  void _redo() {
    if (_historyIndex < _undoHistory.length - 1) {
      setState(() {
        _historyIndex++;
        _currentPlan = _clonePlan(_undoHistory[_historyIndex]!);
        _hasUnsavedChanges = true;
      });
    }
  }

  // ==================== AUTO-SAVE ====================

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasUnsavedChanges) {
        _autoSave();
      }
    });
  }

  Future<void> _autoSave() async {
    if (_currentPlan == null) return;

    try {
      await _savePlan(showSnackbar: false);
      setState(() {
        _lastSaved = DateTime.now();
      });
    } catch (e) {
      debugPrint('Auto-save failed: $e');
    }
  }

  Future<void> _saveManually() async {
    await _savePlan(showSnackbar: true);
  }

  Future<void> _savePlan({bool showSnackbar = true}) async {
    if (_currentPlan == null) return;

    final validationError = _currentPlan!.validate();
    if (validationError != null) {
      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation error: $validationError'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
      return;
    }

    try {
      final updatedPlan = _currentPlan!.copyWith(
        name: _planName,
        description: _planDescription,
        durationWeeks: _durationWeeks,
        startDate: _startDate,
        clientId: _selectedClientId ?? '',
        updatedAt: DateTime.now(),
      );

      if (_currentPlan!.id == null) {
        final planId = await _workoutService.createPlan(updatedPlan);
        setState(() {
          _currentPlan = updatedPlan.copyWith(id: planId);
          _hasUnsavedChanges = false;
        });
      } else {
        await _workoutService.updatePlan(updatedPlan);
        setState(() {
          _currentPlan = updatedPlan;
          _hasUnsavedChanges = false;
        });
      }

      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(LocaleHelper.t('save', 'en')),
              ],
            ),
            backgroundColor: DesignTokens.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  // ==================== PLAN OPERATIONS ====================

  void _createNewWeek() {
    if (_currentPlan == null) return;

    final newWeek = WorkoutWeek(
      planId: _currentPlan!.id ?? '',
      weekNumber: _currentPlan!.weeks.length + 1,
      days: List.generate(
        7,
        (dayIndex) => WorkoutDay(
          weekId: '',
          dayNumber: dayIndex + 1,
          label: _getDayLabel(dayIndex),
        ),
      ),
    );

    setState(() {
      _currentPlan = _currentPlan!.copyWith(
        weeks: [..._currentPlan!.weeks, newWeek],
        durationWeeks: _currentPlan!.weeks.length + 1,
      );
      _durationWeeks = _currentPlan!.weeks.length;
      _saveToHistory();
    });
  }

  void _deleteWeek(int weekIndex) async {
    if (_currentPlan == null || _currentPlan!.weeks.length <= 1) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmationDialog(
        title: 'Delete Week ${weekIndex + 1}?',
        message: 'This will permanently delete this week and all its exercises. This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDangerous: true,
      ),
    );

    if (confirmed != true) return;

    setState(() {
      final weeks = List<WorkoutWeek>.from(_currentPlan!.weeks);
      weeks.removeAt(weekIndex);

      // Renumber weeks
      for (int i = 0; i < weeks.length; i++) {
        weeks[i] = weeks[i].copyWith(weekNumber: i + 1);
      }

      _currentPlan = _currentPlan!.copyWith(
        weeks: weeks,
        durationWeeks: weeks.length,
      );
      _durationWeeks = weeks.length;

      if (_selectedWeekIndex >= weeks.length) {
        _selectedWeekIndex = weeks.length - 1;
      }

      _saveToHistory();
    });
  }

  void _duplicateWeek(int weekIndex) {
    if (_currentPlan == null) return;

    final weekToDuplicate = _currentPlan!.weeks[weekIndex];
    final newWeek = WorkoutWeek(
      planId: _currentPlan!.id ?? '',
      weekNumber: _currentPlan!.weeks.length + 1,
      notes: weekToDuplicate.notes,
      days: weekToDuplicate.days.map((day) {
        return WorkoutDay(
          weekId: '',
          dayNumber: day.dayNumber,
          label: day.label,
          exercises: day.exercises.map((ex) {
            return ex.copyWith(id: null, dayId: '');
          }).toList(),
          cardioSessions: day.cardioSessions.map((cardio) {
            return cardio.copyWith(id: null, dayId: '');
          }).toList(),
        );
      }).toList(),
    );

    setState(() {
      _currentPlan = _currentPlan!.copyWith(
        weeks: [..._currentPlan!.weeks, newWeek],
        durationWeeks: _currentPlan!.weeks.length + 1,
      );
      _durationWeeks = _currentPlan!.weeks.length;
      _saveToHistory();
    });
  }

  void _addExercise(String exerciseName) {
    if (_currentPlan == null) return;

    final week = _currentPlan!.weeks[_selectedWeekIndex];
    final day = week.days[_selectedDayIndex];

    final newExercise = Exercise(
      dayId: day.id ?? '',
      orderIndex: day.exercises.length,
      name: exerciseName,
      sets: 3,
      reps: '8-12',
      rest: 90,
    );

    final updatedDay = day.copyWith(
      exercises: [...day.exercises, newExercise],
    );

    _updateDay(updatedDay);
  }

  void _updateDay(WorkoutDay updatedDay) {
    if (_currentPlan == null) return;

    final week = _currentPlan!.weeks[_selectedWeekIndex];
    final days = List<WorkoutDay>.from(week.days);
    days[_selectedDayIndex] = updatedDay;

    final updatedWeek = week.copyWith(days: days);
    final weeks = List<WorkoutWeek>.from(_currentPlan!.weeks);
    weeks[_selectedWeekIndex] = updatedWeek;

    setState(() {
      _currentPlan = _currentPlan!.copyWith(weeks: weeks);
      _saveToHistory();
    });
  }

  void _editExercise(int exerciseIndex) {
    if (_currentPlan == null) return;

    final week = _currentPlan!.weeks[_selectedWeekIndex];
    final day = week.days[_selectedDayIndex];
    final exercise = day.exercises[exerciseIndex];

    showDialog(
      context: context,
      builder: (context) => AdvancedExerciseEditor(
        exercise: exercise,
        onSave: (updatedExercise) {
          final exercises = List<Exercise>.from(day.exercises);
          exercises[exerciseIndex] = updatedExercise;
          final updatedDay = day.copyWith(exercises: exercises);
          _updateDay(updatedDay);
        },
      ),
    );
  }

  void _deleteExercise(int exerciseIndex) async {
    if (_currentPlan == null) return;

    final week = _currentPlan!.weeks[_selectedWeekIndex];
    final day = week.days[_selectedDayIndex];
    final exercise = day.exercises[exerciseIndex];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmationDialog(
        title: 'Delete ${exercise.name}?',
        message: 'This will permanently remove this exercise from the workout.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDangerous: true,
      ),
    );

    if (confirmed != true) return;

    final exercises = List<Exercise>.from(day.exercises);
    exercises.removeAt(exerciseIndex);

    // Reorder
    for (int i = 0; i < exercises.length; i++) {
      exercises[i] = exercises[i].copyWith(orderIndex: i);
    }

    final updatedDay = day.copyWith(exercises: exercises);
    _updateDay(updatedDay);
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildMainLayout(),
              ),
            ),

            // Analytics Panel Overlay
            if (_analyticsPanelExpanded) _buildAnalyticsPanel(),

            // Backdrop for FAB (closes when tapped)
            if (_fabExpanded)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _fabExpanded = false);
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),

            // FAB - Must be AFTER backdrop to appear on top
            _buildExpandableFab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: DesignTokens.accentGreen,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading plan builder...',
              style: DesignTokens.bodyLarge.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: DesignTokens.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading plan',
              style: DesignTokens.titleLarge.copyWith(
                color: DesignTokens.neutralWhite,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: DesignTokens.bodyMedium.copyWith(
                  color: DesignTokens.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadInitialData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accentGreen,
                foregroundColor: DesignTokens.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Auto-collapse sidebars on small screens
        final screenWidth = constraints.maxWidth;
        final showLeftSidebar = !_leftSidebarCollapsed && screenWidth > 800;
        final showRightSidebar = !_rightSidebarCollapsed && screenWidth > 1200;

        return Column(
          children: [
            _buildAppBar(),
            _buildSubBar(),
            Expanded(
              child: Row(
                children: [
                  // Left Sidebar - Week Overview
                  if (showLeftSidebar) _buildLeftSidebar(),

                  // Main Content - Active Day Editor
                  Expanded(child: _buildMainContent()),

                  // Right Sidebar - Exercise Library
                  if (showRightSidebar) _buildRightSidebar(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ==================== APP BAR ====================

  Widget _buildAppBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          height: 70,
          decoration: const BoxDecoration(
            color: DesignTokens.cardBackground,
            border: Border(
              bottom: BorderSide(
                color: DesignTokens.glassBorder,
                width: 1,
              ),
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
                child: Row(
                  children: [
                    // Back Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      color: DesignTokens.neutralWhite,
                      tooltip: 'Back',
                    ),

                    const SizedBox(width: 8),

                    // Plan Name Editor
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: _planName),
                        focusNode: _planNameFocus,
                        style: DesignTokens.titleMedium.copyWith(
                          color: DesignTokens.neutralWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 16 : 18,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Plan name...',
                          hintStyle: DesignTokens.titleMedium.copyWith(
                            color: DesignTokens.textSecondary,
                            fontSize: isMobile ? 16 : 18,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _planName = value;
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Save Status Indicator (compact on mobile)
                    if (_hasUnsavedChanges)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: DesignTokens.warn,
                          shape: BoxShape.circle,
                        ),
                      ),

                    if (!_hasUnsavedChanges && _lastSaved != null && !isMobile)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: DesignTokens.success,
                        ),
                      ),

                    const SizedBox(width: 8),

                    // Primary Action: Save Button
                    IconButton(
                      onPressed: _saveManually,
                      icon: const Icon(Icons.save),
                      color: DesignTokens.accentGreen,
                      tooltip: 'Save',
                      iconSize: 24,
                    ),

                    // More Options Menu (consolidated on mobile)
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: DesignTokens.neutralWhite),
                      color: DesignTokens.cardBackground,
                      tooltip: 'More options',
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'preview',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 18, color: DesignTokens.neutralWhite),
                              SizedBox(width: 12),
                              Text('Preview'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 18, color: DesignTokens.neutralWhite),
                              SizedBox(width: 12),
                              Text('Export'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'ai',
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 18, color: DesignTokens.accentPurple),
                              SizedBox(width: 12),
                              Text('AI Generate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.content_copy, size: 18, color: DesignTokens.neutralWhite),
                              SizedBox(width: 12),
                              Text('Duplicate Plan'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'template',
                          child: Row(
                            children: [
                              Icon(Icons.bookmark, size: 18, color: DesignTokens.neutralWhite),
                              SizedBox(width: 12),
                              Text('Save as Template'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: DesignTokens.danger),
                              SizedBox(width: 12),
                              Text('Delete Plan'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        // TODO: Handle menu actions
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== SUB BAR ====================

  Widget _buildSubBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: DesignTokens.primaryDark.withValues(alpha: 0.5),
        border: const Border(
          bottom: BorderSide(
            color: DesignTokens.glassBorder,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Plan Info Chip
              _buildInfoChip(
                icon: Icons.person,
                label: _selectedClientId != null
                    ? _clients.firstWhere(
                        (c) => c['id'] == _selectedClientId,
                        orElse: () => {'full_name': 'Select Client'},
                      )['full_name']
                    : 'Select Client',
                onTap: () => _showClientSelector(),
              ),

              const SizedBox(width: 12),

              _buildInfoChip(
                icon: Icons.calendar_today,
                label: '$_durationWeeks weeks',
                onTap: () => _showDurationPicker(),
              ),

              const SizedBox(width: 12),

              _buildInfoChip(
                icon: Icons.event,
                label: _startDate != null
                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                    : 'Start Date',
                onTap: () => _showStartDatePicker(),
              ),

              const SizedBox(width: 12),

              // Quick Actions
              _buildGlassButton(
              icon: Icons.library_books,
              label: 'Templates',
              onPressed: () {
                // TODO: Show templates
              },
              compact: true,
            ),

            const SizedBox(width: 8),

            _buildGlassButton(
              icon: Icons.settings,
              label: 'Settings',
              onPressed: () {
                // TODO: Show settings
              },
              compact: true,
            ),

            const SizedBox(width: 8),

            // Undo/Redo
            IconButton(
              onPressed: _historyIndex > 0 ? _undo : null,
              icon: const Icon(Icons.undo),
              color: _historyIndex > 0
                  ? DesignTokens.neutralWhite
                  : DesignTokens.textSecondary,
              tooltip: 'Undo (Ctrl+Z)',
            ),

            IconButton(
              onPressed: _historyIndex < _undoHistory.length - 1 ? _redo : null,
              icon: const Icon(Icons.redo),
              color: _historyIndex < _undoHistory.length - 1
                  ? DesignTokens.neutralWhite
                  : DesignTokens.textSecondary,
              tooltip: 'Redo (Ctrl+Y)',
            ),
          ],
        ),
        ),
      ),
    );
  }

  // ==================== LEFT SIDEBAR ====================

  Widget _buildLeftSidebar() {
    return AnimatedContainer(
      duration: DesignTokens.durationNormal,
      width: 280,
      decoration: const BoxDecoration(
        color: DesignTokens.cardBackground,
        border: Border(
          right: BorderSide(color: DesignTokens.glassBorder),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: DesignTokens.glassBorder),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Weeks',
                  style: DesignTokens.titleSmall.copyWith(
                    color: DesignTokens.neutralWhite,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  color: DesignTokens.accentGreen,
                  onPressed: _createNewWeek,
                  tooltip: 'Add Week (Ctrl+N)',
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: DesignTokens.textSecondary,
                  onPressed: () {
                    setState(() {
                      _leftSidebarCollapsed = true;
                    });
                  },
                ),
              ],
            ),
          ),

          // Week List
          Expanded(
            child: _currentPlan == null
                ? const Center(child: Text('No plan loaded'))
                : ListView.builder(
                    itemCount: _currentPlan!.weeks.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      return _buildWeekCard(index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCard(int weekIndex) {
    final week = _currentPlan!.weeks[weekIndex];
    final isSelected = weekIndex == _selectedWeekIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedWeekIndex = weekIndex;
          _selectedDayIndex = 0;
        });
      },
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.accentGreen.withValues(alpha: 0.1)
              : DesignTokens.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? DesignTokens.accentGreen
                : DesignTokens.glassBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? DesignTokens.accentGreen
                        : DesignTokens.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${week.weekNumber}',
                      style: DesignTokens.labelMedium.copyWith(
                        color: isSelected
                            ? DesignTokens.primaryDark
                            : DesignTokens.neutralWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Week ${week.weekNumber}',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: DesignTokens.neutralWhite,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 16,
                    color: DesignTokens.textSecondary,
                  ),
                  color: DesignTokens.cardBackground,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'duplicate',
                      onTap: () => _duplicateWeek(weekIndex),
                      child: const Text('Duplicate'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      onTap: () => _deleteWeek(weekIndex),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Training days indicator
            Wrap(
              spacing: 4,
              children: week.days.map((day) {
                final hasWorkout = day.exercises.isNotEmpty || day.cardioSessions.isNotEmpty;
                return Container(
                  width: 24,
                  height: 4,
                  decoration: BoxDecoration(
                    color: hasWorkout
                        ? DesignTokens.accentGreen
                        : DesignTokens.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MAIN CONTENT ====================

  Widget _buildMainContent() {
    if (_currentPlan == null) {
      return const Center(
        child: Text('No plan loaded'),
      );
    }

    if (_currentPlan!.weeks.isEmpty) {
      return const Center(
        child: Text('No weeks in this plan. Add a week to get started.'),
      );
    }

    if (_selectedWeekIndex >= _currentPlan!.weeks.length) {
      return const Center(
        child: Text('Selected week not found'),
      );
    }

    final week = _currentPlan!.weeks[_selectedWeekIndex];

    if (week.days.isEmpty) {
      return const Center(
        child: Text('No days in this week. Add a day to get started.'),
      );
    }

    if (_selectedDayIndex >= week.days.length) {
      return const Center(
        child: Text('Selected day not found'),
      );
    }

    final day = week.days[_selectedDayIndex];

    return Container(
      color: DesignTokens.primaryDark,
      child: Column(
        children: [
          // Day Selector
          _buildDaySelector(week),

          // Day Content
          Expanded(
            child: _buildDayContent(day),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(WorkoutWeek week) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DesignTokens.glassBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: week.days.length,
              itemBuilder: (context, index) {
                final day = week.days[index];
                final isSelected = index == _selectedDayIndex;
                final hasWorkout = day.exercises.isNotEmpty || day.cardioSessions.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: DesignTokens.durationFast,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? DesignTokens.accentGreen
                          : DesignTokens.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? DesignTokens.accentGreen
                            : (hasWorkout
                                ? DesignTokens.accentBlue
                                : DesignTokens.glassBorder),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.label.substring(0, 3),
                          style: DesignTokens.labelMedium.copyWith(
                            color: isSelected
                                ? DesignTokens.primaryDark
                                : DesignTokens.neutralWhite,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: hasWorkout
                                ? (isSelected
                                    ? DesignTokens.primaryDark
                                    : DesignTokens.accentGreen)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayContent(WorkoutDay day) {
    // Calculate estimated duration
    final estimatedDuration = _calculateDayDuration(day);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main content
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day header
              Row(
                children: [
                  Text(
                    day.label,
                    style: DesignTokens.titleLarge.copyWith(
                      color: DesignTokens.neutralWhite,
                    ),
                  ),
                  const Spacer(),
                  if (day.isRestDay)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.infoBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DesignTokens.info),
                      ),
                      child: Text(
                        'Rest Day',
                        style: DesignTokens.labelSmall.copyWith(
                          color: DesignTokens.info,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Day Settings Panel
              _buildDaySettingsPanel(day, estimatedDuration),

              const SizedBox(height: 24),

              // Exercises Section
              if (day.exercises.isEmpty && day.cardioSessions.isEmpty)
                _buildEmptyDayState()
              else ...[
                if (day.exercises.isNotEmpty) ...[
                  Text(
                    'Exercises',
                    style: DesignTokens.titleMedium.copyWith(
                      color: DesignTokens.neutralWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...day.exercises.asMap().entries.map((entry) {
                    return _buildExerciseCard(entry.value, entry.key);
                  }),
                ],

                // Cardio Section
                if (day.cardioSessions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Cardio',
                    style: DesignTokens.titleMedium.copyWith(
                      color: DesignTokens.neutralWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...day.cardioSessions.asMap().entries.map((entry) {
                    return _buildCardioCard(entry.value, entry.key);
                  }),
                ],
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  int _calculateDayDuration(WorkoutDay day) {
    int totalMinutes = 0;

    // Calculate exercise time
    for (final exercise in day.exercises) {
      final sets = exercise.sets ?? 0;
      final rest = exercise.rest ?? 60;

      // Estimate ~30 seconds per set + rest periods
      final workTime = sets * 30; // 30 sec per set
      final restTime = sets > 0 ? (sets - 1) * rest : 0;

      totalMinutes += ((workTime + restTime) / 60).round();
    }

    // Add cardio time
    for (final cardio in day.cardioSessions) {
      totalMinutes += cardio.durationMinutes ?? 0;
    }

    return totalMinutes;
  }

  Widget _buildDaySettingsPanel(WorkoutDay day, int estimatedDuration) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: [
              _buildDayStatChip(
                Icons.timer_outlined,
                '$estimatedDuration min',
                'Estimated Duration',
              ),
              const SizedBox(width: 12),
              _buildDayStatChip(
                Icons.fitness_center,
                '${day.exercises.length}',
                'Exercises',
              ),
              if (day.cardioSessions.isNotEmpty) ...[
                const SizedBox(width: 12),
                _buildDayStatChip(
                  Icons.directions_run,
                  '${day.cardioSessions.length}',
                  'Cardio',
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Notes Section
          TextField(
            controller: TextEditingController(text: day.clientComment ?? ''),
            maxLines: 3,
            style: const TextStyle(color: DesignTokens.neutralWhite, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Add day notes or instructions...',
              hintStyle: const TextStyle(color: DesignTokens.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.notes, color: DesignTokens.accentBlue, size: 20),
              filled: true,
              fillColor: DesignTokens.primaryDark.withValues(alpha: 0.5),
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
                borderSide: const BorderSide(color: DesignTokens.accentBlue),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              final updatedDay = day.copyWith(clientComment: value);
              _updateDay(updatedDay);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: DesignTokens.primaryDark.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DesignTokens.glassBorder.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: DesignTokens.accentGreen),
            const SizedBox(height: 4),
            Text(
              value,
              style: DesignTokens.titleSmall.copyWith(
                color: DesignTokens.neutralWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: DesignTokens.labelSmall.copyWith(
                color: DesignTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDayState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Icon(
            Icons.fitness_center,
            size: 64,
            color: DesignTokens.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises yet',
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add exercises to build your workout',
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, int index) {
    // Determine grouping color and label
    Color? groupColor;
    IconData? groupIcon;
    String? groupLabel;

    if (exercise.groupType != ExerciseGroupType.none) {
      switch (exercise.groupType) {
        case ExerciseGroupType.superset:
          groupColor = DesignTokens.accentBlue;
          groupIcon = Icons.link;
          groupLabel = 'Superset';
          break;
        case ExerciseGroupType.circuit:
          groupColor = DesignTokens.accentOrange;
          groupIcon = Icons.all_inclusive;
          groupLabel = 'Circuit';
          break;
        case ExerciseGroupType.giantSet:
          groupColor = DesignTokens.accentPurple;
          groupIcon = Icons.hub;
          groupLabel = 'Giant Set';
          break;
        case ExerciseGroupType.dropSet:
          groupColor = DesignTokens.accentPink;
          groupIcon = Icons.trending_down;
          groupLabel = 'Drop Set';
          break;
        case ExerciseGroupType.restPause:
          groupColor = DesignTokens.accentGreen;
          groupIcon = Icons.pause_circle;
          groupLabel = 'Rest-Pause';
          break;
        default:
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: groupColor ?? DesignTokens.glassBorder,
          width: groupColor != null ? 2 : 1,
        ),
        boxShadow: groupColor != null
            ? [
                BoxShadow(
                  color: groupColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Grouping badge (if grouped)
          if (groupColor != null && groupLabel != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: groupColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: groupColor.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    groupIcon,
                    size: 14,
                    color: groupColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    groupLabel,
                    style: DesignTokens.labelSmall.copyWith(
                      color: groupColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Main exercise content
          Row(
            children: [
              // Drag handle
              Icon(
                Icons.drag_indicator,
                color: groupColor ?? DesignTokens.textSecondary,
                size: 20,
              ),

              const SizedBox(width: 12),

              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: DesignTokens.bodyLarge.copyWith(
                        color: DesignTokens.neutralWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.getVolumeDisplay(),
                      style: DesignTokens.bodySmall.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                    if (exercise.getIntensityDisplay().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        exercise.getIntensityDisplay(),
                        style: DesignTokens.labelSmall.copyWith(
                          color: DesignTokens.accentGreen,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                color: DesignTokens.accentBlue,
                onPressed: () => _editExercise(index),
              ),

              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                color: DesignTokens.danger,
                onPressed: () => _deleteExercise(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== RIGHT SIDEBAR ====================

  Widget _buildRightSidebar() {
    return AnimatedContainer(
      duration: DesignTokens.durationNormal,
      width: 320,
      decoration: const BoxDecoration(
        color: DesignTokens.cardBackground,
        border: Border(
          left: BorderSide(color: DesignTokens.glassBorder),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: DesignTokens.glassBorder),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Exercise Library',
                  style: DesignTokens.titleSmall.copyWith(
                    color: DesignTokens.neutralWhite,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: DesignTokens.textSecondary,
                  onPressed: () {
                    setState(() {
                      _rightSidebarCollapsed = true;
                    });
                  },
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
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
              ),
            ),
          ),

          // Exercise list
          Expanded(
            child: ListView.builder(
              itemCount: _exerciseLibrary.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final exercise = _exerciseLibrary[index];
                return _buildExerciseLibraryItem(exercise);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseLibraryItem(Map<String, dynamic> exercise) {
    return GestureDetector(
      onTap: () => _addExercise(exercise['name']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignTokens.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.fitness_center,
              color: DesignTokens.accentGreen,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['name'],
                    style: DesignTokens.bodyMedium.copyWith(
                      color: DesignTokens.neutralWhite,
                    ),
                  ),
                  Text(
                    exercise['category'],
                    style: DesignTokens.labelSmall.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.add_circle_outline,
              color: DesignTokens.accentGreen,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CARDIO ====================

  Widget _buildCardioCard(CardioSession cardio, int index) {
    // Get machine icon and color
    IconData machineIcon;
    final Color iconColor = DesignTokens.accentOrange;

    switch (cardio.machineType) {
      case CardioMachineType.treadmill:
        machineIcon = Icons.directions_walk;
        break;
      case CardioMachineType.bike:
        machineIcon = Icons.directions_bike;
        break;
      case CardioMachineType.rower:
        machineIcon = Icons.rowing;
        break;
      case CardioMachineType.elliptical:
        machineIcon = Icons.circle_outlined;
        break;
      case CardioMachineType.stairmaster:
        machineIcon = Icons.stairs;
        break;
      default:
        machineIcon = Icons.directions_run;
    }

    // Get intensity color
    final intensity = cardio.settings['intensity'] as String? ?? 'Medium';
    Color intensityColor;
    switch (intensity) {
      case 'Low':
        intensityColor = DesignTokens.accentBlue;
        break;
      case 'High':
        intensityColor = DesignTokens.danger;
        break;
      default:
        intensityColor = DesignTokens.warn;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.accentOrange,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentOrange.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Cardio type badge
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: DesignTokens.accentOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DesignTokens.accentOrange.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_run,
                  size: 14,
                  color: DesignTokens.accentOrange,
                ),
                const SizedBox(width: 6),
                Text(
                  cardio.settings['cardio_type']?.toString().toUpperCase() ?? 'CARDIO',
                  style: DesignTokens.labelSmall.copyWith(
                    color: DesignTokens.accentOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Main cardio content
          Row(
            children: [
              // Machine icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  machineIcon,
                  color: iconColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Cardio info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardio.machineType?.displayName ?? 'Cardio',
                      style: DesignTokens.bodyLarge.copyWith(
                        color: DesignTokens.neutralWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cardio.getDisplaySummary(),
                      style: DesignTokens.bodySmall.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Intensity indicator
                    Row(
                      children: [
                        Icon(Icons.speed, size: 14, color: intensityColor),
                        const SizedBox(width: 4),
                        Text(
                          '$intensity Intensity',
                          style: DesignTokens.labelSmall.copyWith(
                            color: intensityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                color: DesignTokens.accentBlue,
                onPressed: () => _editCardio(index),
              ),

              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                color: DesignTokens.danger,
                onPressed: () => _deleteCardio(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCardioEditor() {
    if (_currentPlan == null) return;

    final week = _currentPlan!.weeks[_selectedWeekIndex];
    final day = week.days[_selectedDayIndex];

    showDialog(
      context: context,
      builder: (context) => CardioEditorDialog(
        onSave: (cardioSession) {
          final newCardio = cardioSession.copyWith(
            dayId: day.id ?? '',
            orderIndex: day.cardioSessions.length,
          );

          final updatedDay = day.copyWith(
            cardioSessions: [...day.cardioSessions, newCardio],
          );

          _updateDay(updatedDay);
        },
      ),
    );
  }

  void _editCardio(int cardioIndex) {
    if (_currentPlan == null) return;

    final week = _currentPlan!.weeks[_selectedWeekIndex];
    final day = week.days[_selectedDayIndex];
    final cardio = day.cardioSessions[cardioIndex];

    showDialog(
      context: context,
      builder: (context) => CardioEditorDialog(
        cardioSession: cardio,
        onSave: (updatedCardio) {
          final cardioSessions = List<CardioSession>.from(day.cardioSessions);
          cardioSessions[cardioIndex] = updatedCardio;
          final updatedDay = day.copyWith(cardioSessions: cardioSessions);
          _updateDay(updatedDay);
        },
      ),
    );
  }

  void _deleteCardio(int cardioIndex) async {
    if (_currentPlan == null) return;

    final week = _currentPlan!.weeks[_selectedWeekIndex];
    final day = week.days[_selectedDayIndex];
    final cardio = day.cardioSessions[cardioIndex];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmationDialog(
        title: 'Delete ${cardio.machineType?.displayName ?? 'Cardio'}?',
        message: 'This will permanently remove this cardio session.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDangerous: true,
      ),
    );

    if (confirmed != true) return;

    final cardioSessions = List<CardioSession>.from(day.cardioSessions);
    cardioSessions.removeAt(cardioIndex);

    // Reorder
    for (int i = 0; i < cardioSessions.length; i++) {
      cardioSessions[i] = cardioSessions[i].copyWith(orderIndex: i);
    }

    final updatedDay = day.copyWith(cardioSessions: cardioSessions);
    _updateDay(updatedDay);
  }

  // ==================== ANALYTICS PANEL ====================

  Widget _buildExpandableFab() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Option 1: Add Exercise
          if (_fabExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    // Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: DesignTokens.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DesignTokens.glassBorder),
                      ),
                      child: const Text(
                        'Add Exercise',
                        style: TextStyle(
                          color: DesignTokens.neutralWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // FAB
                    FloatingActionButton(
                      onPressed: () {
                        setState(() => _fabExpanded = false);
                        _showExerciseSelector();
                      },
                      heroTag: 'add_exercise',
                      backgroundColor: DesignTokens.accentGreen,
                      child: const Icon(Icons.fitness_center, color: DesignTokens.primaryDark),
                    ),
                  ],
                ),
              ),

          // Option 2: Add Cardio
          if (_fabExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    // Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: DesignTokens.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DesignTokens.glassBorder),
                      ),
                      child: const Text(
                        'Add Cardio',
                        style: TextStyle(
                          color: DesignTokens.neutralWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // FAB
                    FloatingActionButton(
                      onPressed: () {
                        setState(() => _fabExpanded = false);
                        _showCardioEditor();
                      },
                      heroTag: 'add_cardio',
                      backgroundColor: DesignTokens.accentOrange,
                      child: const Icon(Icons.directions_run, color: DesignTokens.primaryDark),
                    ),
                  ],
                ),
              ),

          // Option 3: Weekly Volume
          if (_fabExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    // Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: DesignTokens.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DesignTokens.glassBorder),
                      ),
                      child: const Text(
                        'Weekly Volume',
                        style: TextStyle(
                          color: DesignTokens.neutralWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // FAB
                    FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          _fabExpanded = false;
                          _analyticsPanelExpanded = !_analyticsPanelExpanded;
                        });
                      },
                      heroTag: 'weekly_volume',
                      backgroundColor: DesignTokens.accentPurple,
                      child: const Icon(Icons.analytics, color: DesignTokens.neutralWhite),
                    ),
                  ],
                ),
              ),

          // Main FAB
          FloatingActionButton(
            onPressed: () {
              setState(() => _fabExpanded = !_fabExpanded);
            },
            heroTag: 'main_fab',
            backgroundColor: DesignTokens.accentBlue,
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _fabExpanded ? 0.125 : 0.0, // 45 degree rotation (1/8 turn)
              child: Icon(
                _fabExpanded ? Icons.close : Icons.add,
                color: DesignTokens.neutralWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPanel() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragEnd: isMobile ? (details) {
          if (details.primaryVelocity! > 300) {
            setState(() {
              _analyticsPanelExpanded = false;
            });
          }
        } : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          height: isMobile ? MediaQuery.of(context).size.height * 0.5 : 350.0,
          decoration: BoxDecoration(
            color: DesignTokens.cardBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(color: DesignTokens.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle (mobile only)
              if (isMobile)
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.analytics,
                      color: DesignTokens.accentPurple,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Weekly Analytics',
                      style: DesignTokens.titleMedium.copyWith(
                        color: DesignTokens.neutralWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: DesignTokens.textSecondary,
                      onPressed: () {
                        setState(() {
                          _analyticsPanelExpanded = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const Divider(color: DesignTokens.glassBorder, height: 1),

              // Analytics Content
              Expanded(
                child: _buildAnalyticsContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    if (_currentPlan == null) {
      return Center(
        child: Text(
          'No plan data available',
          style: DesignTokens.bodyMedium.copyWith(
            color: DesignTokens.textSecondary,
          ),
        ),
      );
    }

    // Calculate analytics data
    final analytics = _calculateWeeklyAnalytics();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // Weekly Volume Card
              _buildAnalyticsCard(
                title: 'Weekly Volume',
                icon: Icons.fitness_center,
                color: DesignTokens.accentGreen,
                width: isMobile ? constraints.maxWidth : (constraints.maxWidth / 2) - 8,
                child: _buildVolumeDisplay(analytics),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeeklyVolumeDetailScreen(
                        analytics: analytics,
                        weekNumber: _selectedWeekIndex + 1,
                        totalWeeks: _currentPlan?.weeks.length ?? 0,
                        planName: _currentPlan?.name,
                        weekData: _currentPlan?.weeks[_selectedWeekIndex],
                        plan: _currentPlan, // Pass full plan for comparison
                      ),
                    ),
                  );
                },
              ),

              // Muscle Groups Card
              _buildAnalyticsCard(
                title: 'Muscle Groups',
                icon: Icons.radar,
                color: DesignTokens.accentBlue,
                width: isMobile ? constraints.maxWidth : (constraints.maxWidth / 2) - 8,
                child: _buildMuscleGroupsDisplay(analytics),
              ),

              // Tonnage Card
              _buildAnalyticsCard(
                title: 'Total Tonnage',
                icon: Icons.scale,
                color: DesignTokens.accentOrange,
                width: isMobile ? constraints.maxWidth : (constraints.maxWidth / 2) - 8,
                child: _buildTonnageDisplay(analytics),
              ),

              // Time Commitment Card
              _buildAnalyticsCard(
                title: 'Time Commitment',
                icon: Icons.schedule,
                color: DesignTokens.accentPurple,
                width: isMobile ? constraints.maxWidth : (constraints.maxWidth / 2) - 8,
                child: _buildTimeCommitmentDisplay(analytics),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, dynamic> _calculateWeeklyAnalytics() {
    if (_currentPlan == null) return {};

    final week = _currentPlan!.weeks[_selectedWeekIndex];
    double totalVolume = 0;
    double totalTonnage = 0;
    int totalMinutes = 0;
    int totalSets = 0;
    int totalReps = 0;
    int activeDays = 0;
    final Map<String, double> muscleGroupVolumes = {};
    final List<double> dailyVolumes = [];
    final List<Map<String, dynamic>> dailyDetails = [];

    for (final day in week.days) {
      double dayVolume = 0;
      int daySets = 0;
      int dayReps = 0;
      final List<Map<String, dynamic>> dayExercises = [];

      for (final exercise in day.exercises) {
        final volume = exercise.calculateVolume();
        if (volume != null) {
          dayVolume += volume;
          totalVolume += volume;
          totalTonnage += volume;
        }

        if (exercise.sets != null) {
          daySets += exercise.sets!;
          totalSets += exercise.sets!;
        }

        final repsNumeric = exercise.getRepsNumeric();
        if (repsNumeric != null && exercise.sets != null) {
          final exerciseReps = repsNumeric * exercise.sets!;
          dayReps += exerciseReps;
          totalReps += exerciseReps;
        }

        // Track exercise details
        dayExercises.add({
          'name': exercise.name,
          'sets': exercise.sets,
          'reps': exercise.reps,
          'volume': volume ?? 0.0,
        });

        // Extract muscle groups from exercise name
        final muscleGroups = _extractMuscleGroups(exercise.name);
        if (muscleGroups.isEmpty) {
          muscleGroupVolumes['Other'] =
              (muscleGroupVolumes['Other'] ?? 0.0) + (volume ?? 0.0);
        } else {
          for (final muscle in muscleGroups) {
            muscleGroupVolumes[muscle] =
                (muscleGroupVolumes[muscle] ?? 0.0) + (volume ?? 0.0);
          }
        }
      }

      dailyVolumes.add(dayVolume);
      dailyDetails.add({
        'exercises': dayExercises,
        'sets': daySets,
        'reps': dayReps,
        'volume': dayVolume,
        'duration': _calculateDayDuration(day),
      });

      if (day.exercises.isNotEmpty || day.cardioSessions.isNotEmpty) {
        activeDays++;
        totalMinutes += _calculateDayDuration(day);
      }
    }

    return {
      'totalVolume': totalVolume,
      'totalTonnage': totalTonnage,
      'totalMinutes': totalMinutes,
      'totalSets': totalSets,
      'totalReps': totalReps,
      'activeDays': activeDays,
      'muscleGroups': muscleGroupVolumes.keys.length, // Count for compatibility
      'muscleGroupVolumes': muscleGroupVolumes, // Enhanced: volume per muscle group
      'dailyVolumes': dailyVolumes,
      'dailyDetails': dailyDetails, // Enhanced: detailed daily breakdown
      'avgSessionDuration': activeDays > 0 ? totalMinutes / activeDays : 0,
    };
  }

  Widget _buildAnalyticsCard({
    required String title,
    required IconData icon,
    required Color color,
    required double width,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final cardContent = Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.primaryDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onTap != null
              ? color.withValues(alpha: 0.3)
              : DesignTokens.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: DesignTokens.titleSmall.copyWith(
                    color: DesignTokens.neutralWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null) ...[
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildVolumeDisplay(Map<String, dynamic> analytics) {
    final dailyVolumes = analytics['dailyVolumes'] as List<double>? ?? [];
    final totalVolume = analytics['totalVolume'] as double? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${totalVolume.toStringAsFixed(0)} kg',
          style: DesignTokens.displaySmall.copyWith(
            color: DesignTokens.accentGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Total weekly volume',
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        // Simple bar representation
        ...dailyVolumes.asMap().entries.map((entry) {
          final dayIndex = entry.key;
          final volume = entry.value;
          final maxVolume = dailyVolumes.reduce((a, b) => a > b ? a : b);
          final percentage = maxVolume > 0 ? volume / maxVolume : 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dayIndex],
                    style: DesignTokens.labelSmall.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: DesignTokens.glassBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage.toDouble(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: DesignTokens.accentGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${volume.toStringAsFixed(0)}kg',
                    style: DesignTokens.labelSmall.copyWith(
                      color: DesignTokens.neutralWhite,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMuscleGroupsDisplay(Map<String, dynamic> analytics) {
    final muscleGroups = analytics['muscleGroups'] as Map<String, int>? ?? {};
    final total = muscleGroups.values.fold(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$total',
          style: DesignTokens.displaySmall.copyWith(
            color: DesignTokens.accentBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Total exercises',
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        if (muscleGroups.isEmpty)
          Text(
            'No exercises yet',
            style: DesignTokens.bodySmall.copyWith(
              color: DesignTokens.textSecondary,
            ),
          )
        else
          ...muscleGroups.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100) : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: DesignTokens.bodySmall.copyWith(
                      color: DesignTokens.neutralWhite,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: DesignTokens.labelSmall.copyWith(
                      color: DesignTokens.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTonnageDisplay(Map<String, dynamic> analytics) {
    final tonnage = analytics['totalTonnage'] as double? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${(tonnage / 1000).toStringAsFixed(2)} t',
          style: DesignTokens.displaySmall.copyWith(
            color: DesignTokens.accentOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Total weight moved',
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: DesignTokens.textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tonnage = Total volume lifted across all exercises',
                style: DesignTokens.labelSmall.copyWith(
                  color: DesignTokens.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeCommitmentDisplay(Map<String, dynamic> analytics) {
    final totalMinutes = analytics['totalMinutes'] as int? ?? 0;
    final activeDays = analytics['activeDays'] as int? ?? 0;
    final avgDuration = analytics['avgSessionDuration'] as double? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${(totalMinutes / 60).toStringAsFixed(1)} hrs',
          style: DesignTokens.displaySmall.copyWith(
            color: DesignTokens.accentPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Total weekly time',
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _buildTimeMetric('Sessions/week', '$activeDays'),
        const SizedBox(height: 8),
        _buildTimeMetric('Avg session', '${avgDuration.toStringAsFixed(0)} min'),
        const SizedBox(height: 8),
        _buildTimeMetric('Total time', '$totalMinutes min'),
      ],
    );
  }

  Widget _buildTimeMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.textSecondary,
          ),
        ),
        Text(
          value,
          style: DesignTokens.bodyMedium.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==================== DIALOGS ====================

  void _showClientSelector() {
    showDialog(
      context: context,
      builder: (context) => _ClientSelectorDialog(
        clients: _clients,
        selectedId: _selectedClientId,
        onSelected: (id) {
          setState(() {
            _selectedClientId = id;
            _hasUnsavedChanges = true;
          });
        },
      ),
    );
  }

  void _showDurationPicker() {
    showDialog(
      context: context,
      builder: (context) => _DurationPickerDialog(
        initialWeeks: _durationWeeks,
        onChanged: (weeks) {
          setState(() {
            _durationWeeks = weeks;
            _hasUnsavedChanges = true;
            _initializeEmptyPlan();
          });
        },
      ),
    );
  }

  void _showStartDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DesignTokens.accentGreen,
              surface: DesignTokens.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _startDate = date;
        _hasUnsavedChanges = true;
      });
    }
  }

  void _showExerciseSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return ExercisePickerDialog(
          onExerciseSelected: (exercise) {
            if (_currentPlan == null) return;

            final week = _currentPlan!.weeks[_selectedWeekIndex];
            final day = week.days[_selectedDayIndex];

            final newExercise = exercise.copyWith(
              dayId: day.id ?? '',
              orderIndex: day.exercises.length,
            );

            final updatedDay = day.copyWith(
              exercises: [...day.exercises, newExercise],
            );

            _updateDay(updatedDay);
          },
        );
      },
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
    Gradient? gradient,
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? (color?.withValues(alpha: 0.1) ?? DesignTokens.cardBackground)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color ?? DesignTokens.glassBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: compact ? 16 : 18,
                color: gradient != null
                    ? DesignTokens.neutralWhite
                    : (color ?? DesignTokens.neutralWhite),
              ),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: DesignTokens.labelMedium.copyWith(
                    color: gradient != null
                        ? DesignTokens.neutralWhite
                        : (color ?? DesignTokens.neutralWhite),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: DesignTokens.accentGreen),
            const SizedBox(width: 8),
            Text(
              label,
              style: DesignTokens.labelMedium.copyWith(
                color: DesignTokens.neutralWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Extract muscle groups from exercise name using keyword matching
  /// Similar to WorkoutMetricsService._pluckMuscles
  List<String> _extractMuscleGroups(String exerciseName) {
    final name = exerciseName.toLowerCase();
    final Set<String> muscles = {};

    // Common compound lifts
    if (name.contains('bench')) {
      muscles.addAll(['Chest', 'Triceps', 'Shoulders']);
    }
    if (name.contains('squat')) {
      muscles.addAll(['Quads', 'Glutes', 'Hamstrings', 'Core']);
    }
    if (name.contains('deadlift')) {
      muscles.addAll(['Back', 'Glutes', 'Hamstrings']);
    }
    if (name.contains('row')) {
      muscles.addAll(['Back', 'Biceps']);
    }
    if (name.contains('pull-up') ||
        name.contains('pull up') ||
        name.contains('chin')) {
      muscles.addAll(['Back', 'Biceps']);
    }
    if (name.contains('press') && !name.contains('bench')) {
      muscles.addAll(['Shoulders', 'Chest', 'Triceps']);
    }
    if (name.contains('overhead')) {
      muscles.add('Shoulders');
    }
    if (name.contains('ohp')) {
      muscles.add('Shoulders');
    }
    if (name.contains('lunge')) {
      muscles.addAll(['Quads', 'Glutes']);
    }
    if (name.contains('calf')) {
      muscles.add('Calves');
    }
    if (name.contains('curl')) {
      muscles.add('Biceps');
    }
    if (name.contains('extension') && name.contains('tricep')) {
      muscles.add('Triceps');
    }
    if (name.contains('dip')) {
      muscles.add('Triceps');
    }
    if (name.contains('crunch') ||
        name.contains('plank') ||
        name.contains('sit-up') ||
        name.contains('sit up')) {
      muscles.add('Core');
    }
    if (name.contains('lat pulldown') || name.contains('pulldown')) {
      muscles.addAll(['Back', 'Biceps']);
    }
    if (name.contains('fly')) {
      muscles.add('Chest');
    }
    if (name.contains('shoulder') || name.contains('deltoid')) {
      muscles.add('Shoulders');
    }
    if (name.contains('leg press')) {
      muscles.addAll(['Quads', 'Glutes']);
    }
    if (name.contains('hamstring') || name.contains('leg curl')) {
      muscles.add('Hamstrings');
    }
    if (name.contains('quad') || name.contains('leg extension')) {
      muscles.add('Quads');
    }
    if (name.contains('glute')) {
      muscles.add('Glutes');
    }
    if (name.contains('back') && !name.contains('deadlift')) {
      muscles.add('Back');
    }
    if (name.contains('chest')) {
      muscles.add('Chest');
    }
    if (name.contains('tricep')) {
      muscles.add('Triceps');
    }
    if (name.contains('bicep')) {
      muscles.add('Biceps');
    }

    return muscles.toList();
  }
}

// ==================== DIALOGS ====================

class _ClientSelectorDialog extends StatelessWidget {
  final List<Map<String, dynamic>> clients;
  final String? selectedId;
  final Function(String) onSelected;

  const _ClientSelectorDialog({
    required this.clients,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DesignTokens.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Client',
              style: DesignTokens.titleLarge.copyWith(
                color: DesignTokens.neutralWhite,
              ),
            ),
            const SizedBox(height: 16),
            ...clients.map((client) {
              final isSelected = client['id'] == selectedId;
              return ListTile(
                title: Text(
                  client['full_name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: DesignTokens.neutralWhite,
                  ),
                ),
                subtitle: Text(
                  client['email'] ?? '',
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: DesignTokens.accentGreen)
                    : null,
                onTap: () {
                  onSelected(client['id']);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DurationPickerDialog extends StatefulWidget {
  final int initialWeeks;
  final Function(int) onChanged;

  const _DurationPickerDialog({
    required this.initialWeeks,
    required this.onChanged,
  });

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  late int _weeks;

  @override
  void initState() {
    super.initState();
    _weeks = widget.initialWeeks;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DesignTokens.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Plan Duration',
              style: DesignTokens.titleLarge.copyWith(
                color: DesignTokens.neutralWhite,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _weeks > 1
                      ? () => setState(() => _weeks--)
                      : null,
                  icon: const Icon(Icons.remove),
                  color: DesignTokens.neutralWhite,
                ),
                const SizedBox(width: 24),
                Text(
                  '$_weeks',
                  style: DesignTokens.displayMedium.copyWith(
                    color: DesignTokens.accentGreen,
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: _weeks < 52
                      ? () => setState(() => _weeks++)
                      : null,
                  icon: const Icon(Icons.add),
                  color: DesignTokens.neutralWhite,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'weeks',
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onChanged(_weeks);
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDangerous;

  const _ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DesignTokens.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDangerous ? Icons.warning_amber_rounded : Icons.help_outline,
              size: 48,
              color: isDangerous ? DesignTokens.danger : DesignTokens.warn,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: DesignTokens.titleLarge.copyWith(
                color: DesignTokens.neutralWhite,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: DesignTokens.glassBorder),
                      foregroundColor: DesignTokens.neutralWhite,
                    ),
                    child: Text(cancelText),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor:
                          isDangerous ? DesignTokens.danger : DesignTokens.accentGreen,
                      foregroundColor: DesignTokens.neutralWhite,
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
