import 'package:flutter/material.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../services/nutrition/meal_photo_integration.dart';
import '../../services/nutrition/locale_helper.dart';

/// Reusable button for adding food items via photo
class AddViaPhotoButton extends StatelessWidget {
  final NutritionPlan plan;
  final int dayIndex;
  final int mealIndex;
  final VoidCallback? onItemAdded; // optional: to trigger local refresh
  final bool isCompact; // for different button styles

  const AddViaPhotoButton({
    super.key,
    required this.plan,
    required this.dayIndex,
    required this.mealIndex,
    this.onItemAdded,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    
    if (isCompact) {
      return IconButton(
        onPressed: () => _handlePhotoCapture(context, language),
        icon: const Icon(Icons.camera_alt_outlined),
        tooltip: LocaleHelper.t('add_via_photo', language),
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    
    return FilledButton.icon(
      icon: const Icon(Icons.camera_alt_outlined),
      onPressed: () => _handlePhotoCapture(context, language),
      label: Text(LocaleHelper.t('add_via_photo', language)),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Future<void> _handlePhotoCapture(BuildContext context, String language) async {
    try {
      final added = await MealPhotoIntegration.addViaPhoto(
        context: context,
        plan: plan,
        dayIndex: dayIndex,
        mealIndex: mealIndex,
      );
      
      if (added && context.mounted) {
        onItemAdded?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleHelper.t('added_via_photo', language)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocaleHelper.t('failed_to_add_photo', language)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Compact version for tight spaces
class AddViaPhotoIconButton extends StatelessWidget {
  final NutritionPlan plan;
  final int dayIndex;
  final int mealIndex;
  final VoidCallback? onItemAdded;

  const AddViaPhotoIconButton({
    super.key,
    required this.plan,
    required this.dayIndex,
    required this.mealIndex,
    this.onItemAdded,
  });

  @override
  Widget build(BuildContext context) {
    return AddViaPhotoButton(
      plan: plan,
      dayIndex: dayIndex,
      mealIndex: mealIndex,
      onItemAdded: onItemAdded,
      isCompact: true,
    );
  }
}
