import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../models/nutrition/nutrition_plan.dart';

class MealDetailSheet extends StatelessWidget {
  final Meal meal;
  final Widget coachNotes;
  final Widget foodItems;     // list of items for the meal
  final VoidCallback onAddFood;
  final Widget mealSummary;   // kcal/macros summary
  final Widget attachments;   // existing attachments list
  final VoidCallback onAddFile;
  final Widget clientComment; // text field (bound outside)

  const MealDetailSheet({
    super.key,
    required this.meal,
    required this.coachNotes,
    required this.foodItems,
    required this.onAddFood,
    required this.mealSummary,
    required this.attachments,
    required this.onAddFile,
    required this.clientComment,
  });

  @override
  Widget build(BuildContext context) {
    // Extract meal name safely
    final mealName = _mealName();

    return Stack(
      children: [
        // Blur the nutrition screen behind
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.15)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.66, // ~2/3 height
            widthFactor: 1,
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              elevation: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radius12)),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Grab handle + title row
                          Center(
                            child: Container(
                              width: 40, height: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: DesignTokens.ink100,
                                borderRadius: BorderRadius.circular(DesignTokens.radius8),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(mealName, style: Theme.of(context).textTheme.titleLarge),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.close),
                                tooltip: 'Close',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Coach notes
                          _Section(title: 'Coach notes', child: coachNotes),
                          const SizedBox(height: 12),

                          // Food items
                          _Section(
                            title: 'Food items',
                                                            trailing: TextButton.icon(onPressed: onAddFood, icon: const Icon(Icons.add), label: const Text('Add food')),
                            child: foodItems,
                          ),
                          const SizedBox(height: 12),

                          // Meal summary
                          _Section(title: 'Meal summary', child: mealSummary),
                          const SizedBox(height: 12),

                          // Attachments
                          _Section(
                            title: 'Attachments',
                            trailing: TextButton.icon(onPressed: onAddFile, icon: const Icon(Icons.attach_file), label: const Text('Add files')),
                            child: attachments,
                          ),
                          const SizedBox(height: 16),

                          // Client comment pinned to bottom of content
                          _Section(title: 'Client comment', child: clientComment),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _mealName() {
    return meal.label;
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: DesignTokens.ink500),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
            border: Border.all(color: DesignTokens.ink100),
          ),
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ],
    );
  }
}
