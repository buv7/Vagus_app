import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../screens/notes/coach_note_screen.dart';
import '../../screens/files/upload_photos_screen.dart';
import '../../screens/nutrition/meal_editor.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../screens/workout/revolutionary_plan_builder_screen.dart';
import '../../screens/workout/cardio_log_screen.dart';
import '../../screens/calling/call_management_screen.dart';
import '../../screens/dashboard/notes/note_list_screen.dart';
import '../../widgets/calling/schedule_call_dialog.dart';

class GlassmorphismFAB extends StatefulWidget {
  final bool isCoach;
  
  const GlassmorphismFAB({
    super.key,
    this.isCoach = false,
  });

  @override
  State<GlassmorphismFAB> createState() => _GlassmorphismFABState();
}

class _GlassmorphismFABState extends State<GlassmorphismFAB>
    with TickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  // Action items configuration
  final List<FABAction> _actions = const [
    FABAction(
      icon: Icons.fitness_center,
      label: 'Add Workout',
      route: '/workouts/add',
      dx: 0,
      dy: 0,
    ),
    FABAction(
      icon: Icons.restaurant,
      label: 'Add Meal',
      route: '/nutrition/add',
      dx: -8,
      dy: -8,
    ),
    FABAction(
      icon: Icons.camera_alt,
      label: 'Add Progress Photo',
      route: '/progress/photo',
      dx: -8,
      dy: 0,
    ),
    FABAction(
      icon: Icons.note_add,
      label: 'Add Note',
      route: '/notes/add',
      dx: 0,
      dy: 8,
    ),
    FABAction(
      icon: Icons.phone,
      label: 'Schedule Call',
      isModal: true,
      dx: 12,
      dy: 12,
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
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UploadPhotosScreen()),
        );
        break;
      case '/notes/add':
        _handleNoteTap();
        break;
    }
  }

  void _handleWorkoutTap() {
    // Show bottom sheet with workout options - matching side menu glassmorphism style
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: DesignTokens.darkBackground,
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -4),
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
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Add Workout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Option: Create New Workout Plan
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: DesignTokens.accentBlue,
                  ),
                ),
                title: const Text(
                  'Create Workout Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Build a new workout plan from scratch',
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
              // Option: Log Cardio Session
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DesignTokens.accentOrange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_run,
                    color: DesignTokens.accentOrange,
                  ),
                ),
                title: const Text(
                  'Log Cardio Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Track running, cycling, or other cardio',
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
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
    // Show bottom sheet with call options - matching side menu glassmorphism style
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: DesignTokens.darkBackground,
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -4),
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
                  color: Colors.white.withValues(alpha: 0.3),
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
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: DesignTokens.accentBlue,
                  ),
                ),
                title: const Text(
                  'Quick Schedule',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Schedule a new call session',
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
                        content: Text('✅ Call scheduled successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
              // Option: View All Calls
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DesignTokens.accentPurple.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.call,
                    color: DesignTokens.accentPurple,
                  ),
                ),
                title: const Text(
                  'Manage Calls',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'View scheduled, active & recent calls',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Backdrop overlay
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeFAB,
              child: Container(
                color: Colors.black.withValues(alpha: 0.1),
              ),
            ),
          ),
        
        // Action buttons container
        if (_isOpen)
          Positioned(
            bottom: 0,
            right: 0,
            child: SizedBox(
              width: 300, // Large enough to contain all action buttons
              height: 300,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Action buttons
                  ..._actions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final action = entry.value;
                    return _buildActionButton(index, action, isMobile);
                  }),
                ],
              ),
            ),
          ),
        
        // Main FAB
        Positioned(
          bottom: 0,
          right: 0,
          child: _buildMainFAB(isMobile),
        ),
      ],
    );
  }

  Widget _buildMainFAB(bool isMobile) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * math.pi,
          child: Container(
            width: isMobile ? 56 : 64,
            height: isMobile ? 56 : 64,
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
                    borderRadius: BorderRadius.circular(isMobile ? 28 : 32),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        size: isMobile ? 24 : 28,
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

  Widget _buildActionButton(int index, FABAction action, bool isMobile) {
    final position = _calculatePosition(index, isMobile);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animationValue = Curves.easeOut.transform(
          math.max(0.0, _animationController.value - (index * 0.12)),
        );
        
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value * animationValue,
            child: Opacity(
              opacity: animationValue,
              child: Container(
                width: isMobile ? 48 : 56,
                height: isMobile ? 48 : 56,
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
                        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
                        child: Center(
                          child: Icon(
                            action.icon,
                            size: isMobile ? 20 : 24,
                            color: Colors.white,
                          ),
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

  Offset _calculatePosition(int index, bool isMobile) {
    // Mathematical positioning system - quarter arc from bottom-right
    const baseRadius = 80.0; // Distance from main FAB center
    const perItemSpread = 12.0; // Additional spacing per item
    
    final radius = baseRadius + (index * perItemSpread);
    final stepDeg = 90.0 / (_actions.length - 1); // 90 degrees divided by 4 steps
    final angleDeg = 270.0 + (index * stepDeg); // Start from top (270°) and go left
    final angleRad = angleDeg * math.pi / 180.0;
    
    // Calculate position relative to main FAB (which is at bottom-right of container)
    final mainFabSize = isMobile ? 56.0 : 64.0;
    final mainFabCenter = mainFabSize / 2;
    
    var x = mainFabCenter + math.cos(angleRad) * radius;
    var y = mainFabCenter + math.sin(angleRad) * radius;
    
    // Apply fine-tuning offsets
    final action = _actions[index];
    x += action.dx;
    y += action.dy;
    
    // Adjust for action button size
    final actionSize = isMobile ? 48.0 : 56.0;
    x -= actionSize / 2;
    y -= actionSize / 2;
    
    return Offset(x, y);
  }
}

class FABAction {
  final IconData icon;
  final String label;
  final String? route;
  final bool isModal;
  final double dx;
  final double dy;

  const FABAction({
    required this.icon,
    required this.label,
    this.route,
    this.isModal = false,
    this.dx = 0,
    this.dy = 0,
  });
}
