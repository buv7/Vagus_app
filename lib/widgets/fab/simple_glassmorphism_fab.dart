import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../screens/notes/coach_note_screen.dart';
import '../../screens/files/upload_photos_screen.dart';
import '../../screens/nutrition/meal_editor.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../screens/workout/revolutionary_plan_builder_screen.dart';
import '../../screens/workout/cardio_log_screen.dart';
import '../../screens/workout/fatigue_recovery_screen.dart';
import '../../screens/workouts/modern_workout_plan_viewer.dart';
import '../../screens/calling/call_management_screen.dart';
import '../../screens/dashboard/notes/note_list_screen.dart';
import '../../widgets/calling/schedule_call_dialog.dart';

class SimpleGlassmorphismFAB extends StatefulWidget {
  final bool isCoach;
  final VoidCallback? onOpenCameraFAB;
  
  const SimpleGlassmorphismFAB({
    super.key,
    this.isCoach = false,
    this.onOpenCameraFAB,
  });

  @override
  State<SimpleGlassmorphismFAB> createState() => _SimpleGlassmorphismFABState();
}

class _SimpleGlassmorphismFABState extends State<SimpleGlassmorphismFAB>
    with TickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  // Action items configuration
  final List<FABAction> _actions = const [
    FABAction(
      icon: Icons.fitness_center,
      label: 'Add Workout',
      route: '/workouts/add',
    ),
    FABAction(
      icon: Icons.restaurant,
      label: 'Add Meal',
      route: '/nutrition/add',
    ),
    FABAction(
      icon: Icons.camera_alt,
      label: 'Add Progress Photo',
      route: '/progress/photo',
    ),
    FABAction(
      icon: Icons.note_add,
      label: 'Add Note',
      route: '/notes/add',
    ),
    FABAction(
      icon: Icons.phone,
      label: 'Schedule Call',
      isModal: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees in turns
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFAB() {
    setState(() {
      _isOpen = !_isOpen;
    });
    
    if (_isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    
    HapticFeedback.lightImpact();
  }

  void _closeFAB() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
      });
      _animationController.reverse();
    }
  }

  void _handleAction(FABAction action) {
    _closeFAB();
    HapticFeedback.lightImpact();
    
    if (action.isModal) {
      _showScheduleCallModal();
    } else {
      _navigateToAction(action);
    }
  }

  void _navigateToAction(FABAction action) {
    switch (action.route) {
      case '/workouts/add':
        _handleWorkoutTap();
        break;
      case '/nutrition/add':
        _handleMealTap();
        break;
      case '/progress/photo':
        // Open camera FAB instead of navigating directly
        if (widget.onOpenCameraFAB != null) {
          widget.onOpenCameraFAB!();
        } else {
          // Fallback to original behavior if no callback provided
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadPhotosScreen()),
          );
        }
        break;
      case '/notes/add':
        _handleNoteTap();
        break;
    }
  }

  void _handleWorkoutTap() {
    // Show bottom sheet with workout options - different for coach vs client
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              // Glassmorphism style matching side menu
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 2.0,
                colors: [
                  DesignTokens.accentBlue.withValues(alpha: 0.3),
                  DesignTokens.accentBlue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    widget.isCoach ? 'Workout Options' : 'My Workout',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Different options based on coach vs client
                  if (widget.isCoach) ...[
                    // COACH OPTIONS
                    _buildSheetMenuItem(
                      icon: Icons.fitness_center,
                      iconColor: DesignTokens.accentBlue,
                      title: 'Create Workout Plan',
                      subtitle: 'Build a new workout plan from scratch',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RevolutionaryPlanBuilderScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSheetMenuItem(
                      icon: Icons.directions_run,
                      iconColor: DesignTokens.accentOrange,
                      title: 'Log Cardio Session',
                      subtitle: 'Track running, cycling, or other cardio',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CardioLogScreen(),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    // CLIENT OPTIONS
                    _buildSheetMenuItem(
                      icon: Icons.fitness_center,
                      iconColor: DesignTokens.accentBlue,
                      title: 'View My Workout',
                      subtitle: 'See your coach-assigned workout plan',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ModernWorkoutPlanViewer(),
                          ),
                        );
                      },
                    ),
                    _buildSheetMenuItem(
                      icon: Icons.directions_run,
                      iconColor: DesignTokens.accentOrange,
                      title: 'Log Cardio Session',
                      subtitle: 'Track running, cycling, or other cardio',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CardioLogScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSheetMenuItem(
                      icon: Icons.health_and_safety,
                      iconColor: DesignTokens.accentGreen,
                      title: 'Log Recovery Status',
                      subtitle: 'Track fatigue, sleep & readiness',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FatigueRecoveryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      hoverColor: DesignTokens.accentBlue.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
  }

  void _handleNoteTap() {
    if (widget.isCoach) {
      // Coach: Navigate to notes list screen where they can create new notes
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NoteListScreen()),
      );
    } else {
      // Client: Navigate to create a new note
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CoachNoteScreen()),
      );
    }
  }

  void _handleMealTap() {
    if (widget.isCoach) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coach meal planning coming soon!')),
      );
    } else {
      final newMeal = Meal(
        label: 'New Meal',
        items: [],
        mealSummary: MealSummary(
          totalProtein: 0,
          totalCarbs: 0,
          totalFat: 0,
          totalKcal: 0,
          totalSodium: 0,
          totalPotassium: 0,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MealEditorScreen(
          meal: newMeal,
          onMealSaved: (meal) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Meal saved: ${meal.label}')),
            );
          },
        )),
      );
    }
  }

  void _showScheduleCallModal() {
    // Show bottom sheet with call options - glassmorphic style
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              // Glassmorphism style matching side menu
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 2.0,
                colors: [
                  DesignTokens.accentBlue.withValues(alpha: 0.3),
                  DesignTokens.accentBlue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    'Schedule Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Option: Quick Schedule
                  _buildSheetMenuItem(
                    icon: Icons.schedule,
                    iconColor: DesignTokens.accentBlue,
                    title: 'Quick Schedule',
                    subtitle: 'Schedule a new call session',
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      navigator.pop();
                      // Show the schedule call dialog
                      final result = await showDialog(
                        context: this.context,
                        builder: (ctx) => const ScheduleCallDialog(),
                      );
                      if (result != null && mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Call scheduled successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                  // Option: View All Calls
                  _buildSheetMenuItem(
                    icon: Icons.call,
                    iconColor: Colors.purple,
                    title: 'Manage Calls',
                    subtitle: 'View scheduled, active & recent calls',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CallManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220, // Container for radius = 60 with 110° arc span
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main FAB positioned at bottom-right of container
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildMainFAB(),
          ),
          
          // Action buttons - only show when open
          if (_isOpen)
            ..._actions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              final position = _calculatePosition(index);
              return Positioned(
                left: position.dx,
                top: position.dy,
                child: _buildActionButton(index, action),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMainFAB() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * math.pi,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  DesignTokens.accentBlue.withValues(alpha: 0.3),
                  DesignTokens.accentBlue.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleFAB,
                    borderRadius: BorderRadius.circular(32),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(int index, FABAction action) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animationValue = Curves.easeOut.transform(
          math.max(0.0, _animationController.value - (index * 0.12)),
        );
        
        return Transform.scale(
          scale: animationValue,
          child: Opacity(
            opacity: animationValue,
            child: Container(
              width: 48, // Decreased from 56 to 48
              height: 48, // Decreased from 56 to 48
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DesignTokens.accentBlue.withValues(alpha: 0.25),
                    DesignTokens.accentBlue.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.25),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleAction(action),
                      borderRadius: BorderRadius.circular(24), // Updated for 48px button
                        child: Center(
                          child: Icon(
                            action.icon,
                            size: 24, // Increased from 20 to 24
                            color: Colors.white,
                          ),
                        ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Offset> _calculatePositions() {
    const Offset fabCenter = Offset(148, 148);
    const double radius = 70; // Increased radius for more spacing
    const double miniDiameter = 48; // Updated to match new button size
    const int miniCount = 5;

    // Semi-circle arc positioning (quarter-arc from top to left)
    final centers = _semiCircleArcPositions(
      center: fabCenter,
      radius: radius,
      count: miniCount,
    );

    // Convert to widget positions (subtract half button size)
    final positions = centers.map((center) => Offset(
      center.dx - (miniDiameter / 2),
      center.dy - (miniDiameter / 2),
    )).toList();

    // DEBUG: print integer centers
    final rounded = centers
        .map((p) => Offset(p.dx.roundToDouble(), p.dy.roundToDouble()))
        .toList();
    for (int i = 0; i < rounded.length; i++) {
      debugPrint('B$i -> (${rounded[i].dx.toInt()}, ${rounded[i].dy.toInt()})');
    }

    return positions;
  }

  /// Semi-circle arc positioning - quarter-arc from 270° to 180°
  /// Keeps buttons in a nice curve without going all around the FAB
  List<Offset> _semiCircleArcPositions({
    required Offset center,
    required double radius,
    required int count,
  }) {
    // Quarter-arc from 270° (top) to 180° (left)
    const double startAngle = 320.0;
    const double endAngle = 120.0;
    final double totalAngle = startAngle - endAngle; // 90 degrees
    final double angleStep = totalAngle / (count - 1); // Divide by number of buttons
    
    return List<Offset>.generate(count, (index) {
      final double angle = startAngle - (index * angleStep);
      final double angleRad = angle * math.pi / 180.0;
      
      return Offset(
        center.dx + radius * math.cos(angleRad),
        center.dy + radius * math.sin(angleRad),
      );
    });
  }

  Offset _calculatePosition(int index) {
    final positions = _calculatePositions();
    if (index < positions.length) {
      return positions[index];
    }
    // Fallback
    return const Offset(114, 182);
  }
}

/// Computes button centers along an arbitrary Path with equal center spacing.
/// - Keeps a safe gap so icons never overlap.
/// - Start offset lets you keep the first mini a bit away from the FAB bubble.
class CurvedFabLayout {
  /// Sample a path into evenly spaced center positions.
  static List<Offset> positionsOnPath({
    required Path path,
    required int count,
    required double miniDiameter, // e.g. 32–40
    double gap = 8,               // min center-to-center extra gap
    double startOffset = 10,      // px to skip from path start
  }) {
    assert(count >= 1);
    final PathMetrics metrics = path.computeMetrics();
    final PathMetric m = metrics.first; // one continuous curve
    final double length = m.length;

    // Desired spacing between centers along the curve
    final double step = miniDiameter + gap;
    // Fit as many as requested; clamp if the curve is too short
    final double usable = (length - startOffset).clamp(0, length);
    final int n = math.min(count, math.max(1, (usable / step).floor() + 1));

    // If the curve is short, distribute across available length
    final double actualStep = (n == 1) ? 0 : usable / (n - 1);

    final List<Offset> centers = [];
    for (int i = 0; i < n; i++) {
      final double d = (startOffset + i * actualStep).clamp(0, length);
      final Tangent? t = m.getTangentForOffset(d);
      centers.add(t!.position);
    }
    return centers;
  }

  /// A red-line–like curve near the FAB: tweak C1/C2 to match exactly.
  /// Start at the FAB edge, then sweep outward/up like your sketch.
  static Path redLineLikePath({
    required Offset fabCenter,
    required double fabRadius, // e.g. 32 (for a 64px FAB)
  }) {
    // Start slightly outside the FAB at ~300° so minis don't clip the FAB glow
    final double startAngle = 300 * math.pi / 180;
    final Offset start = Offset(
      fabCenter.dx + (fabRadius + 8) * math.cos(startAngle),
      fabCenter.dy + (fabRadius + 8) * math.sin(startAngle),
    );

    // CONTROL POINTS — tune these to match your red arc visually.
    final Offset c1 = Offset(fabCenter.dx - 40, fabCenter.dy - 40);   // pull up-left
    final Offset c2 = Offset(fabCenter.dx + 120, fabCenter.dy - 80);  // push outward
    final Offset end = Offset(fabCenter.dx + 190, fabCenter.dy - 50); // end near your red tip

    final path = Path()..moveTo(start.dx, start.dy)..cubicTo(
      c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy,
    );
    return path;
  }
}

class FABAction {
  final IconData icon;
  final String label;
  final String? route;
  final bool isModal;

  const FABAction({
    required this.icon,
    required this.label,
    this.route,
    this.isModal = false,
  });
}
