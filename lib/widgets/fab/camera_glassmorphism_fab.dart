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
    if (!_isOpen) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: _toggleFAB, // Dismiss when tapping outside
        child: Container(
          color: Colors.black.withValues(alpha: 0.3), // Semi-transparent backdrop
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent dismissal when tapping on the boxes
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildActionBoxes(),
              ),
            ),
          ),
        ),
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
          
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 12), // Separate each box with margin
            child: Transform.scale(
              scale: animationValue,
              child: Opacity(
                opacity: _animationController.value,
                child: GestureDetector(
                  onTap: () => _onActionTap(action),
                  child: Container(
                    width: 320,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16), // Rounded corners
                      color: AppTheme.mintAqua, // Solid teal background like in the image
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.mintAqua.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          // Icon container with circular background
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: Icon(
                              action.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  action.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  action.description,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
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
