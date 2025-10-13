import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/navigation/vagus_side_menu.dart';

class ModernWorkoutPlanViewer extends StatefulWidget {
  final Map<String, dynamic>? planOverride;

  const ModernWorkoutPlanViewer({super.key, this.planOverride});

  @override
  State<ModernWorkoutPlanViewer> createState() => _ModernWorkoutPlanViewerState();
}

class _ModernWorkoutPlanViewerState extends State<ModernWorkoutPlanViewer> {
  String _selectedPlan = 'strength-building';
  
  // Real data from Supabase
  List<Map<String, dynamic>> _workoutPlans = [];
  Map<String, dynamic>? _currentPlan;
  bool _isLoading = true;
  String? _error;
  String _role = 'client';
  
  // Progress tracking
  final int _currentProgress = 45;
  final int _targetProgress = 60;
  final int _currentWeek = 1;
  int _totalWeeks = 8;
  final double _completionPercentage = 0.75;
  
  // Services

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlans();
  }

  Future<void> _loadWorkoutPlans() async {
    if (!mounted) return;

    try {
      // If planOverride is provided, use it directly
      if (widget.planOverride != null) {
        if (mounted) {
          setState(() {
            _currentPlan = widget.planOverride;
            _workoutPlans = [widget.planOverride!];
            _selectedPlan = widget.planOverride!['id']?.toString() ?? '';
            _totalWeeks = (widget.planOverride!['weeks'] as List<dynamic>?)?.length ?? 8;
            _isLoading = false;
            _error = null;
          });
        }
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get user role
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      _role = (profile['role'] ?? 'client').toString();

      // Load workout plans based on role
      List<dynamic> plans;
      if (_role == 'coach') {
        plans = await Supabase.instance.client
            .from('workout_plans')
            .select()
            .eq('created_by', user.id)
            .order('created_at', ascending: false);
      } else {
        plans = await Supabase.instance.client
            .from('workout_plans')
            .select()
            .eq('client_id', user.id)
            .order('created_at', ascending: false);
      }

      if (mounted) {
        setState(() {
          _workoutPlans = plans.map((p) => Map<String, dynamic>.from(p)).toList();
          if (_workoutPlans.isNotEmpty) {
            _currentPlan = _workoutPlans.first;
            _selectedPlan = _currentPlan!['id']?.toString() ?? '';
            _totalWeeks = (_currentPlan!['weeks'] as List<dynamic>?)?.length ?? 8;
          }
          _isLoading = false;
          _error = null;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showPlanSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Workout Plan',
              style: DesignTokens.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DesignTokens.space16),
            ..._workoutPlans.map((plan) => ListTile(
              title: Text(
                plan['name'] ?? 'Unnamed Plan',
                style: DesignTokens.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                '${(plan['weeks'] as List<dynamic>?)?.length ?? 0} weeks',
                style: DesignTokens.bodySmall.copyWith(
                  color: Colors.white70,
                ),
              ),
              trailing: _selectedPlan == plan['id']?.toString()
                  ? const Icon(Icons.check, color: AppTheme.accentGreen)
                  : null,
              onTap: () {
                setState(() {
                  _currentPlan = plan;
                  _selectedPlan = plan['id']?.toString() ?? '';
                  _totalWeeks = (plan['weeks'] as List<dynamic>?)?.length ?? 8;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      drawerEdgeDragWidth: 24,
      drawer: const VagusSideMenu(isClient: true),
      body: SafeArea(
        child: _isLoading 
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentGreen,
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        const Text(
                          'Error loading workout plans',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        ElevatedButton(
                          onPressed: _loadWorkoutPlans,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: AppTheme.primaryDark,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _workoutPlans.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center_outlined,
                              color: Colors.white70,
                              size: 48,
                            ),
                            SizedBox(height: DesignTokens.space16),
                            Text(
                              'No workout plans found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: DesignTokens.space8),
                            Text(
                              'Your coach will create workout plans for you',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with hamburger menu
                            _buildHeader(),

                            const SizedBox(height: 12),

                            // Plan Selector and Search
                            _buildPlanSelectorAndSearch(),

                            const SizedBox(height: 16),
                            
                            // Program Overview Card
                            _buildProgramOverviewCard(),

                            const SizedBox(height: 16),

                            // Workout List
                            _buildWorkoutList(),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Hamburger menu
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),

          const SizedBox(width: 8),

          // Title
          Expanded(
            child: Text(
              'Workouts',
              style: DesignTokens.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelectorAndSearch() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 90),
      child: Column(
        children: [
          // Plan Selector
          GestureDetector(
            onTap: _workoutPlans.length > 1 ? _showPlanSelector : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentPlan?['name'] ?? 'No workout plan',
                      style: DesignTokens.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_workoutPlans.length > 1)
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Search Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search exercises...',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Week Tag
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentPlan?['name'] ?? 'No workout plan',
                  style: DesignTokens.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Week $_currentWeek',
                  style: DesignTokens.bodySmall.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Program Info
          Text(
            '$_totalWeeks week program • Created by Coach',
            style: DesignTokens.bodySmall.copyWith(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 8),
          
          // Circular Progress (smaller for mobile)
          Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  // Background circle
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 6,
                      ),
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: _completionPercentage,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                    ),
                  ),
                  // Center text
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_currentProgress',
                          style: DesignTokens.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          '/$_targetProgress',
                          style: DesignTokens.bodySmall.copyWith(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          
          // Week Navigation
          _buildWeekNavigation(),

          const SizedBox(height: 10),

          // Progress Info
          Center(
            child: Text(
              'Week $_currentWeek of $_totalWeeks • ${(_completionPercentage * 100).round()}% Complete',
              style: DesignTokens.bodySmall.copyWith(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ),

          const SizedBox(height: 12),
          
          // Action Buttons (compact grid)
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Share',
                  Icons.share,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionButton(
                  'Edit',
                  Icons.edit,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionButton(
                  'PDF',
                  Icons.description,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.chevron_left,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final weekNumber = index + 1;
          final isSelected = weekNumber == _currentWeek;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'W$weekNumber',
                style: DesignTokens.bodySmall.copyWith(
                  color: isSelected ? AppTheme.primaryDark : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right,
          color: Colors.white70,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, IconData icon) {
    // Map compact button names to full action names
    String action = text;
    if (text == 'PDF') action = 'Export PDF';
    if (text == 'Edit') action = 'Edit Plan';

    return GestureDetector(
      onTap: () => _handleActionButton(action),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: DesignTokens.bodySmall.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutList() {
    // Get workouts from current plan
    List<Map<String, dynamic>> workouts = [];
    
    if (_currentPlan != null) {
      final weeks = _currentPlan!['weeks'] as List<dynamic>? ?? [];
      if (weeks.isNotEmpty && _currentWeek <= weeks.length) {
        final currentWeekData = weeks[_currentWeek - 1] as Map<String, dynamic>?;
        final days = currentWeekData?['days'] as List<dynamic>? ?? [];
        
        final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        
        for (int i = 0; i < days.length; i++) {
          final day = days[i] as Map<String, dynamic>?;
          if (day != null) {
            final exercises = day['exercises'] as List<dynamic>? ?? [];
            if (exercises.isNotEmpty) {
              workouts.add({
                'name': day['name'] ?? 'Workout ${i + 1}',
                'day': dayNames[i % 7],
                'sets': '${exercises.length} exercises',
                'duration': '45 min',
                'attachments': 0,
                'exercises': exercises,
              });
            }
          }
        }
      }
    }
    
    // Fallback to mock data if no real data
    if (workouts.isEmpty) {
      workouts = [
        {
          'name': 'Upper Body Strength',
          'day': 'Monday',
          'sets': '12 sets',
          'duration': '45 min',
          'attachments': 2,
        },
        {
          'name': 'Lower Body Power',
          'day': 'Wednesday',
          'sets': '10 sets',
          'duration': '40 min',
          'attachments': 1,
        },
        {
          'name': 'Upper Body Hypertrophy',
          'day': 'Friday',
          'sets': '15 sets',
          'duration': '50 min',
          'attachments': 0,
        },
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...workouts.map((workout) => _buildWorkoutCard(workout)),
      ],
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Arrow icon
          const Icon(
            Icons.chevron_right,
            color: Colors.white70,
            size: 20,
          ),
          
          const SizedBox(width: DesignTokens.space12),
          
          // Workout details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout['name'],
                  style: DesignTokens.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white70,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      workout['day'],
                      style: DesignTokens.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${workout['sets']} • ${workout['duration']}',
                      style: DesignTokens.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Attachments and Add button
          Row(
            children: [
              if (workout['attachments'] > 0) ...[
                const Icon(
                  Icons.attach_file,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${workout['attachments']}',
                  style: DesignTokens.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: AppTheme.primaryDark,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Action button handler
  void _handleActionButton(String action) {
    switch (action) {
      case 'Cardio Log':
        _openCardioLog();
        break;
      case 'Share':
        _shareWorkoutPlan();
        break;
      case 'Edit Plan':
        _editWorkoutPlan();
        break;
      case 'Export PDF':
        _exportWorkoutPlanToPDF();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$action feature coming soon!'),
            backgroundColor: AppTheme.accentGreen,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  // Open cardio log
  void _openCardioLog() {
    // Navigate to cardio log screen
    Navigator.pushNamed(context, '/cardio-log');
  }

  // Share workout plan
  Future<void> _shareWorkoutPlan() async {
    if (_currentPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No workout plan available to share'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final planText = _generateWorkoutPlanText(_currentPlan!);
      
      await Share.share(
        planText,
        subject: 'My Workout Plan - ${_currentPlan!['name'] ?? 'Workout Plan'}',
      );
    } catch (e) {
      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to share workout plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Edit workout plan
  void _editWorkoutPlan() {
    if (_currentPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No workout plan available to edit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to workout plan editor
    Navigator.pushNamed(context, '/workout-editor', arguments: _currentPlan);
  }

  // Export workout plan to PDF
  Future<void> _exportWorkoutPlanToPDF() async {
    if (_currentPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No workout plan available to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      unawaited(showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      ));

      // Generate PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          build: (context) => _buildWorkoutPlanPDFContent(_currentPlan!),
        ),
      );

      // Save and open PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Workout_Plan_${_currentPlan!['name']?.toString().replaceAll(' ', '_') ?? 'Workout_Plan'}.pdf',
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Generate workout plan text for sharing
  String _generateWorkoutPlanText(Map<String, dynamic> plan) {
    final buffer = StringBuffer();
    buffer.writeln('🏋️ Workout Plan: ${plan['name'] ?? 'My Workout Plan'}');
    buffer.writeln('');
    
    if (plan['weeks'] != null) {
      for (int weekIndex = 0; weekIndex < plan['weeks'].length; weekIndex++) {
        final week = plan['weeks'][weekIndex];
        buffer.writeln('📅 Week ${weekIndex + 1}');
        
        if (week['days'] != null) {
          for (int dayIndex = 0; dayIndex < week['days'].length; dayIndex++) {
            final day = week['days'][dayIndex];
            buffer.writeln('  ${day['label'] ?? 'Day ${dayIndex + 1}'}');
            
            if (day['exercises'] != null) {
              for (final exercise in day['exercises']) {
                buffer.writeln('    • ${exercise['name']} - ${exercise['sets']} sets x ${exercise['reps']} reps');
              }
            }
            buffer.writeln('');
          }
        }
      }
    }
    
    buffer.writeln('Generated by VAGUS App');
    return buffer.toString();
  }

  // Build PDF content for workout plan
  List<pw.Widget> _buildWorkoutPlanPDFContent(Map<String, dynamic> plan) {
    final content = <pw.Widget>[];
    
    // Title
    content.add(
      pw.Text(
        plan['name'] ?? 'Workout Plan',
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    
    content.add(pw.SizedBox(height: 20));
    
    // Plan details
    content.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Plan: ${plan['name'] ?? 'Unnamed'}'),
            pw.Text('Type: ${plan['type'] ?? 'Strength Training'}'),
            pw.Text('Duration: ${plan['duration'] ?? '8 weeks'}'),
          ],
        ),
      ),
    );
    
    content.add(pw.SizedBox(height: 20));
    
    // Weeks
    if (plan['weeks'] != null) {
      for (int weekIndex = 0; weekIndex < plan['weeks'].length; weekIndex++) {
        final week = plan['weeks'][weekIndex];
        content.add(
          pw.Text(
            'Week ${weekIndex + 1}',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );
        
        content.add(pw.SizedBox(height: 10));
        
        if (week['days'] != null) {
          for (int dayIndex = 0; dayIndex < week['days'].length; dayIndex++) {
            final day = week['days'][dayIndex];
            content.add(
              pw.Text(
                day['label'] ?? 'Day ${dayIndex + 1}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
            
            if (day['exercises'] != null) {
              for (final exercise in day['exercises']) {
                content.add(
                  pw.Text(
                    '• ${exercise['name']} - ${exercise['sets']} sets x ${exercise['reps']} reps',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                );
              }
            }
            
            content.add(pw.SizedBox(height: 10));
          }
        }
        
        content.add(pw.SizedBox(height: 20));
      }
    }
    
    // Footer
    content.add(pw.Divider());
    content.add(pw.SizedBox(height: 10));
    content.add(
      pw.Text(
        'Generated by VAGUS App',
        style: const pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
    
    return content;
  }
}
