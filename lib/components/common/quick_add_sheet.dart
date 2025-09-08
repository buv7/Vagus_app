import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../screens/notes/coach_note_screen.dart';
import '../../screens/progress/progress_entry_form.dart';
import '../../screens/files/upload_photos_screen.dart';
import '../../screens/calendar/event_editor.dart';
import '../../screens/nutrition/meal_editor.dart';
import '../../screens/nutrition/nutrition_plan_builder.dart';
import '../../screens/calling/calling_demo_screen.dart';
import '../../models/nutrition/nutrition_plan.dart';

class QuickAddSheet extends StatelessWidget {
  final bool isCoach;
  
  const QuickAddSheet({
    super.key,
    this.isCoach = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Title
            Text(
              'Quick Add',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _QuickAddItem(
                    icon: Icons.note_add_rounded,
                    label: 'Note',
                    onTap: () => _handleNoteTap(context),
                  ),
                  _QuickAddItem(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Check-in',
                    onTap: () => _handleCheckinTap(context),
                  ),
                  _QuickAddItem(
                    icon: Icons.track_changes_rounded,
                    label: 'Metric',
                    onTap: () => _handleMetricTap(context),
                  ),
                  _QuickAddItem(
                    icon: Icons.photo_camera_rounded,
                    label: 'Photo',
                    onTap: () => _handlePhotoTap(context),
                  ),
                  _QuickAddItem(
                    icon: Icons.event_rounded,
                    label: 'Event',
                    onTap: () => _handleEventTap(context),
                  ),
                  _QuickAddItem(
                    icon: Icons.restaurant_rounded,
                    label: 'Meal',
                    onTap: () => _handleMealTap(context),
                  ),
                  _QuickAddItem(
                    icon: Icons.videocam_rounded,
                    label: 'Call',
                    onTap: () => _handleCallTap(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _handleNoteTap(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    if (isCoach) {
      // Coach: Show "Coming soon" since notes require client context
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coach notes coming soon!')),
      );
    } else {
      // Client: Navigate to existing note screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CoachNoteScreen()),
      );
    }
  }

  void _handleCheckinTap(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    if (isCoach) {
      // Coach: Show "Coming soon" for coach check-ins
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coach check-ins coming soon!')),
      );
    } else {
      // Client: Navigate to existing check-in form
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProgressEntryForm(userId: '')),
      );
    }
  }

  void _handleMetricTap(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    // Both roles: Navigate to metrics entry
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProgressEntryForm(userId: '')),
    );
  }

  void _handlePhotoTap(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    // Both roles: Navigate to photo upload
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadPhotosScreen()),
    );
  }

  void _handleEventTap(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    // Both roles: Navigate to calendar event editor
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EventEditor()),
    );
  }

  void _handleMealTap(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    if (isCoach) {
      // Coach: Navigate to nutrition plan builder
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NutritionPlanBuilder()),
      );
    } else {
      // Client: Navigate to meal editor
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

  void _handleCallTap(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    // Navigate to calling demo screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CallingDemoScreen()),
    );
  }
}

class _QuickAddItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAddItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
