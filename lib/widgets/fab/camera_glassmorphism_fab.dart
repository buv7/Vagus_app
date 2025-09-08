import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../screens/nutrition/meal_editor.dart';
import '../../screens/progress/progress_gallery.dart';
import '../../screens/files/upload_photos_screen.dart';
import '../../services/ocr/ocr_cardio_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CameraGlassmorphismFAB extends StatefulWidget {
  final bool isCoach;
  
  const CameraGlassmorphismFAB({
    super.key,
    this.isCoach = false,
  });

  @override
  State<CameraGlassmorphismFAB> createState() => CameraGlassmorphismFABState();
}

class CameraGlassmorphismFABState extends State<CameraGlassmorphismFAB>
    with TickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  // Camera action items configuration
  final List<CameraFABAction> _actions = [
    CameraFABAction(
      icon: Icons.favorite,
      label: 'OCR Cardio',
      description: 'Add cardio log by photo',
      action: 'ocr_cardio',
    ),
    CameraFABAction(
      icon: Icons.restaurant,
      label: 'OCR Meal',
      description: 'Quick add meal by photo',
      action: 'ocr_meal',
    ),
    CameraFABAction(
      icon: Icons.camera_alt,
      label: 'Progress Photo',
      description: 'Add progress photo',
      action: 'progress_photo',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
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
  }

  void openCameraFAB() {
    if (!_isOpen) {
      _toggleFAB();
    }
  }

  void _onActionTap(CameraFABAction action) {
    _toggleFAB();
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    // Handle different actions
    switch (action.action) {
      case 'ocr_cardio':
        _handleOCRCardio();
        break;
      case 'ocr_meal':
        _handleOCRMeal();
        break;
      case 'progress_photo':
        _handleProgressPhoto();
        break;
    }
  }

  void _handleOCRCardio() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Processing cardio workout...'),
            ],
          ),
          backgroundColor: AppTheme.mintAqua,
          duration: Duration(seconds: 3),
        ),
      );

      // Import the OCR service
      final ocrService = OCRCardioService();
      
      // Process the workout image
      final workoutData = await ocrService.processWorkoutImage();
      
      if (workoutData != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cardio workout logged successfully! ${workoutData.sport} - ${workoutData.distance}${workoutData.distanceUnit}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to process workout image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error processing cardio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleOCRMeal() {
    // Navigate to upload photos screen for meal photo
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UploadPhotosScreen(),
      ),
    );
  }

  void _handleProgressPhoto() {
    // Navigate to progress gallery
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProgressGallery(userId: user.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300, // Fixed width to prevent infinite constraints
      height: 400, // Fixed height to prevent infinite constraints
      child: Stack(
        children: [
          // Animated action boxes
          if (_isOpen) ..._buildActionBoxes(),
          
          // Main FAB - Hidden but still functional for positioning
          Positioned(
            right: 20,
            bottom: 100, // Position above the main FAB
            child: Container(
              width: 56,
              height: 56,
              // Invisible container to maintain positioning
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionBoxes() {
    return _actions.asMap().entries.map((entry) {
      final index = entry.key;
      final action = entry.value;
      
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final animationValue = Curves.easeOutBack.transform(
            _animationController.value,
          );
          
          return Positioned(
            right: 20,
            bottom: 180 + (index * 120), // Stack vertically with spacing
            child: Transform.scale(
              scale: animationValue,
              child: Opacity(
                opacity: _animationController.value,
                child: GestureDetector(
                  onTap: () => _onActionTap(action),
                  child: Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.mintAqua.withValues(alpha: 0.3),
                          AppTheme.mintAqua.withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.mintAqua.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.mintAqua.withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: AppTheme.mintAqua.withValues(alpha: 0.5),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    action.icon,
                                    color: AppTheme.mintAqua,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        action.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        action.description,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
    }).toList();
  }
}

class CameraFABAction {
  final IconData icon;
  final String label;
  final String description;
  final String action;

  const CameraFABAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.action,
  });
}
