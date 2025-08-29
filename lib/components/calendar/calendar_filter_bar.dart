import 'package:flutter/material.dart';
import '../../services/motion_service.dart';

class CalendarFilterBar extends StatelessWidget {
  final Set<String> selectedCategories;
  final bool showMyEventsOnly;
  final Function(Set<String>) onCategoriesChanged;
  final Function(bool) onMyEventsToggle;

  const CalendarFilterBar({
    super.key,
    required this.selectedCategories,
    required this.showMyEventsOnly,
    required this.onCategoriesChanged,
    required this.onMyEventsToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Category filters
          Row(
            children: [
              const Text(
                'Categories: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: _buildCategoryChips(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // My/All toggle
          Row(
            children: [
              const Text(
                'Show: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('All Events'),
                selected: !showMyEventsOnly,
                onSelected: (selected) {
                                     if (selected) {
                     MotionService.hapticFeedback();
                     onMyEventsToggle(false);
                   }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('My Events'),
                selected: showMyEventsOnly,
                onSelected: (selected) {
                                   if (selected) {
                   MotionService.hapticFeedback();
                   onMyEventsToggle(true);
                 }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryChips() {
    const categories = {
      'workout': {'label': 'Workout', 'color': Colors.blue},
      'nutrition': {'label': 'Nutrition', 'color': Colors.green},
      'session': {'label': 'Session', 'color': Colors.orange},
      'other': {'label': 'Other', 'color': Colors.purple},
    };

    return categories.entries.map((entry) {
      final category = entry.key;
      final config = entry.value;
      final isSelected = selectedCategories.contains(category);

      return FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: config['color'] as Color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(config['label'] as String),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
                     MotionService.hapticFeedback();
          final newCategories = Set<String>.from(selectedCategories);
          if (selected) {
            newCategories.add(category);
          } else {
            newCategories.remove(category);
          }
          onCategoriesChanged(newCategories);
        },
      );
    }).toList();
  }
}
