import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../screens/notes/coach_note_screen.dart';
import '../../screens/files/upload_photos_screen.dart';
import '../../screens/nutrition/meal_editor.dart';
import '../../models/nutrition/nutrition_plan.dart';

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
        // Navigate to workout add screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout add feature coming soon!')),
        );
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

  void _handleNoteTap() {
    if (widget.isCoach) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coach notes coming soon!')),
      );
    } else {
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
        MaterialPageRoute(builder: (context) => MealEditor(
          meal: newMeal,
          onMealChanged: (meal) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Meal saved: ${meal.label}')),
            );
          },
        )),
      );
    }
  }

  void _showScheduleCallModal() {
    setState(() {
    });
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Call'),
        content: const Text('Call scheduling feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      setState(() {
      });
    });
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
              color: AppTheme.accentGreen.withValues(alpha: 0.9),
              border: Border.all(
                color: AppTheme.accentGreen.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
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
                        color: AppTheme.primaryDark,
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
                  color: AppTheme.cardBackground.withValues(alpha: 0.85),
                  border: Border.all(
                    color: AppTheme.accentGreen.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                            color: AppTheme.accentGreen,
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
