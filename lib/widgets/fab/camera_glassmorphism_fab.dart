import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../screens/progress/progress_gallery.dart';
import '../../screens/nutrition/food_snap_screen.dart';
import '../../services/ocr/ocr_cardio_service.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../models/nutrition/food_item.dart';
import '../../widgets/ocr/ocr_cardio_preview_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Image source type for OCR capture
enum ImageSourceType { camera, gallery }

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

  // Camera action items configuration
  final List<CameraFABAction> _actions = const [
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
      // Show source selection dialog
      final source = await _showImageSourceDialog();
      if (source == null || !mounted) return;
      
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
              Text('Capturing and analyzing workout...'),
            ],
          ),
          backgroundColor: AppTheme.accentGreen,
          duration: Duration(seconds: 10),
        ),
      );

      // Import the OCR service
      final ocrService = OCRCardioService();
      
      // Capture and process the image (without saving yet)
      final workoutData = await ocrService.captureAndProcess(
        fromCamera: source == ImageSourceType.camera,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (workoutData != null) {
        // Show preview dialog for user to verify/edit data
        final savedData = await showOCRCardioPreviewDialog(
          context: context,
          data: workoutData,
          onRetake: () => _handleOCRCardio(), // Recursive call to retake
        );
        
        if (savedData != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${savedData.sport ?? 'Cardio'} workout logged! '
                '${savedData.distance?.toStringAsFixed(1) ?? ''} ${savedData.distanceUnit ?? ''} '
                '${savedData.durationMinutes ?? 0}min ${savedData.calories?.toStringAsFixed(0) ?? ''} kcal',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Capture cancelled or failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error processing cardio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Show dialog to select image source (camera or gallery)
  Future<ImageSourceType?> _showImageSourceDialog() async {
    return showDialog<ImageSourceType>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? DesignTokens.darkBackground : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Capture Cardio Display',
            style: TextStyle(
              color: isDark ? Colors.white : DesignTokens.textColor(context),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Take a photo of your cardio machine display or select an existing photo.',
                style: TextStyle(
                  color: isDark ? Colors.white70 : DesignTokens.textColorSecondary(context),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceOption(
                      context: context,
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => Navigator.pop(context, ImageSourceType.camera),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSourceOption(
                      context: context,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () => Navigator.pop(context, ImageSourceType.gallery),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: DesignTokens.accentBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: DesignTokens.accentBlue,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : DesignTokens.textColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleOCRMeal() async {
    // Navigate to FoodSnapScreen for AI-powered meal photo analysis
    final result = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute(
        builder: (context) => FoodSnapScreen(
          onFoodItemCreated: (foodItem) {
            // This callback is used when the user wants to save the food item
            Navigator.of(context).pop(foodItem);
          },
        ),
      ),
    );
    
    if (!mounted) return;
    
    if (result != null) {
      // Food item was captured and returned
      // Show success and offer to add to a meal
      _showFoodItemCapturedDialog(result);
    }
  }
  
  void _showFoodItemCapturedDialog(FoodItem foodItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Food Captured!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              foodItem.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroChip('Calories', foodItem.kcal.toStringAsFixed(0)),
                _buildMacroChip('Protein', '${foodItem.protein.toStringAsFixed(1)}g'),
                _buildMacroChip('Carbs', '${foodItem.carbs.toStringAsFixed(1)}g'),
                _buildMacroChip('Fat', '${foodItem.fat.toStringAsFixed(1)}g'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to add this to your nutrition log?',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _addFoodToNutritionLog(foodItem);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add to Log'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMacroChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Future<void> _addFoodToNutritionLog(FoodItem foodItem) async {
    try {
      final nutritionService = NutritionService();
      
      // Get today's date
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // Add to nutrition log (this will create or update the daily entry)
      await nutritionService.logFoodItem(
        foodItem: foodItem,
        date: dateKey,
        mealType: _determineMealType(),
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${foodItem.name} added to your nutrition log!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to add food: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  String _determineMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'breakfast';
    if (hour < 14) return 'lunch';
    if (hour < 17) return 'snack';
    return 'dinner';
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
        behavior: HitTestBehavior.translucent, // Allow taps to reach this detector
        child: Container(
          color: Colors.transparent, // Completely transparent backdrop
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25), // Push down more from top
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildActionBoxes(),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.10), // Smaller bottom spacing
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionBoxes() {
    return _actions.asMap().entries.map((entry) {
      // final index = entry.key;
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
                  behavior: HitTestBehavior.opaque, // Prevent tap from bubbling up
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 280,
                      maxWidth: 360,
                      minHeight: 80,
                      maxHeight: 80,
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85, // 85% of screen width
                      height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16), // Rounded corners
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DesignTokens.accentBlue.withValues(alpha: 0.3),
                          DesignTokens.accentBlue.withValues(alpha: 0.15),
                        ],
                      ),
                      border: Border.all(
                        color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                        width: 1,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
