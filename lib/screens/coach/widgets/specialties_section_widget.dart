import 'package:flutter/material.dart';
import '../../../models/coach_profile.dart';
import '../../../theme/design_tokens.dart';

class SpecialtiesSectionWidget extends StatefulWidget {
  final CoachProfile? profile;
  final bool isEditMode;
  final Function(List<String>) onSpecialtiesChanged;

  const SpecialtiesSectionWidget({
    super.key,
    required this.profile,
    required this.isEditMode,
    required this.onSpecialtiesChanged,
  });

  @override
  State<SpecialtiesSectionWidget> createState() => _SpecialtiesSectionWidgetState();
}

class _SpecialtiesSectionWidgetState extends State<SpecialtiesSectionWidget>
    with TickerProviderStateMixin {
  late List<String> _selectedSpecialties;
  final TextEditingController _customSpecialtyController = TextEditingController();
  bool _showCustomInput = false;

  late AnimationController _chipAnimationController;
  late AnimationController _addAnimationController;

  // Predefined specialties with icons and colors
  static const List<SpecialtyCategory> _predefinedSpecialties = [
    SpecialtyCategory(
      name: 'Fitness & Training',
      specialties: [
        SpecialtyItem('Weight Loss', Icons.fitness_center, DesignTokens.accentPink),
        SpecialtyItem('Muscle Building', Icons.sports_gymnastics, DesignTokens.accentGreen),
        SpecialtyItem('Cardio Training', Icons.directions_run, DesignTokens.accentBlue),
        SpecialtyItem('Strength Training', Icons.sports_martial_arts, DesignTokens.accentOrange),
        SpecialtyItem('HIIT', Icons.flash_on, DesignTokens.accentPink),
        SpecialtyItem('Functional Training', Icons.sports_handball, DesignTokens.accentGreen),
      ],
    ),
    SpecialtyCategory(
      name: 'Nutrition & Wellness',
      specialties: [
        SpecialtyItem('Nutrition Planning', Icons.restaurant, DesignTokens.accentGreen),
        SpecialtyItem('Weight Management', Icons.monitor_weight, DesignTokens.accentBlue),
        SpecialtyItem('Sports Nutrition', Icons.sports_soccer, DesignTokens.accentOrange),
        SpecialtyItem('Meal Prep', Icons.lunch_dining, DesignTokens.accentPink),
        SpecialtyItem('Supplements', Icons.medication, DesignTokens.accentBlue),
        SpecialtyItem('Hydration', Icons.local_drink, DesignTokens.accentGreen),
      ],
    ),
    SpecialtyCategory(
      name: 'Mental Health & Lifestyle',
      specialties: [
        SpecialtyItem('Stress Management', Icons.psychology, DesignTokens.accentBlue),
        SpecialtyItem('Sleep Optimization', Icons.bedtime, DesignTokens.accentPink),
        SpecialtyItem('Mindfulness', Icons.self_improvement, DesignTokens.accentOrange),
        SpecialtyItem('Habit Formation', Icons.check_circle, DesignTokens.accentGreen),
        SpecialtyItem('Goal Setting', Icons.flag, DesignTokens.accentBlue),
        SpecialtyItem('Motivation', Icons.emoji_events, DesignTokens.accentOrange),
      ],
    ),
    SpecialtyCategory(
      name: 'Specialized Programs',
      specialties: [
        SpecialtyItem('Youth Training', Icons.child_care, DesignTokens.accentGreen),
        SpecialtyItem('Senior Fitness', Icons.elderly, DesignTokens.accentBlue),
        SpecialtyItem('Injury Recovery', Icons.healing, DesignTokens.accentPink),
        SpecialtyItem('Pregnancy Fitness', Icons.pregnant_woman, DesignTokens.accentOrange),
        SpecialtyItem('Athletic Performance', Icons.sports, DesignTokens.accentGreen),
        SpecialtyItem('Bodybuilding', Icons.fitness_center, DesignTokens.accentBlue),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedSpecialties = List.from(widget.profile?.specialties ?? []);

    _chipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _addAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _chipAnimationController.forward();
  }

  @override
  void dispose() {
    _chipAnimationController.dispose();
    _addAnimationController.dispose();
    _customSpecialtyController.dispose();
    super.dispose();
  }

  void _toggleSpecialty(String specialty) {
    setState(() {
      if (_selectedSpecialties.contains(specialty)) {
        _selectedSpecialties.remove(specialty);
      } else {
        _selectedSpecialties.add(specialty);
      }
    });
    widget.onSpecialtiesChanged(_selectedSpecialties);
  }

  void _addCustomSpecialty() {
    final custom = _customSpecialtyController.text.trim();
    if (custom.isNotEmpty && !_selectedSpecialties.contains(custom)) {
      setState(() {
        _selectedSpecialties.add(custom);
        _customSpecialtyController.clear();
        _showCustomInput = false;
      });
      widget.onSpecialtiesChanged(_selectedSpecialties);
    }
  }

  void _removeSpecialty(String specialty) {
    setState(() {
      _selectedSpecialties.remove(specialty);
    });
    widget.onSpecialtiesChanged(_selectedSpecialties);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        boxShadow: DesignTokens.cardShadow,
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: DesignTokens.space16),

          if (widget.isEditMode)
            _buildEditMode()
          else
            _buildViewMode(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.space8),
          decoration: BoxDecoration(
            color: DesignTokens.accentOrange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: const Icon(
            Icons.star,
            size: 20,
            color: DesignTokens.accentOrange,
          ),
        ),
        const SizedBox(width: DesignTokens.space12),
        Text(
          'Specialties',
          style: DesignTokens.titleMedium.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (widget.isEditMode)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space8,
              vertical: DesignTokens.space4,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.accentGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
            child: Text(
              '${_selectedSpecialties.length}/8',
              style: DesignTokens.labelSmall.copyWith(
                color: _selectedSpecialties.length >= 8
                    ? DesignTokens.accentPink
                    : DesignTokens.accentGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected specialties
        if (_selectedSpecialties.isNotEmpty) ...[
          _buildSelectedSpecialties(),
          const SizedBox(height: DesignTokens.space20),
        ],

        // Categories
        ..._buildCategories(),

        const SizedBox(height: DesignTokens.space16),

        // Custom specialty input
        _buildCustomSpecialtySection(),
      ],
    );
  }

  Widget _buildViewMode() {
    if (_selectedSpecialties.isEmpty) {
      return _buildEmptyState();
    }

    return Wrap(
      spacing: DesignTokens.space8,
      runSpacing: DesignTokens.space8,
      children: _selectedSpecialties.map((specialty) {
        final specialtyItem = _findSpecialtyItem(specialty);
        return _buildSpecialtyChip(
          specialty,
          specialtyItem?.icon ?? Icons.star,
          specialtyItem?.color ?? DesignTokens.accentGreen,
          isSelected: false,
          isReadOnly: true,
        );
      }).toList(),
    );
  }

  Widget _buildSelectedSpecialties() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected (${_selectedSpecialties.length}/8)',
          style: DesignTokens.labelMedium.copyWith(
            color: DesignTokens.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DesignTokens.space8),
        Wrap(
          spacing: DesignTokens.space8,
          runSpacing: DesignTokens.space8,
          children: _selectedSpecialties.map((specialty) {
            final specialtyItem = _findSpecialtyItem(specialty);
            return _buildRemovableChip(
              specialty,
              specialtyItem?.icon ?? Icons.star,
              specialtyItem?.color ?? DesignTokens.accentGreen,
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildCategories() {
    return _predefinedSpecialties.map((category) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.name,
            style: DesignTokens.labelMedium.copyWith(
              color: DesignTokens.neutralWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Wrap(
            spacing: DesignTokens.space8,
            runSpacing: DesignTokens.space8,
            children: category.specialties.map((item) {
              final isSelected = _selectedSpecialties.contains(item.name);
              return _buildSpecialtyChip(
                item.name,
                item.icon,
                item.color,
                isSelected: isSelected,
                isReadOnly: false,
              );
            }).toList(),
          ),
          const SizedBox(height: DesignTokens.space16),
        ],
      );
    }).toList();
  }

  Widget _buildSpecialtyChip(
    String specialty,
    IconData icon,
    Color color, {
    required bool isSelected,
    required bool isReadOnly,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isReadOnly ? null : () => _toggleSpecialty(specialty),
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space12,
              vertical: DesignTokens.space8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : (isReadOnly
                      ? color.withValues(alpha: 0.1)
                      : DesignTokens.primaryDark),
              borderRadius: BorderRadius.circular(DesignTokens.radius20),
              border: Border.all(
                color: isSelected
                    ? color
                    : (isReadOnly
                        ? color.withValues(alpha: 0.5)
                        : DesignTokens.glassBorder),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? color
                      : (isReadOnly
                          ? color
                          : DesignTokens.textSecondary),
                ),
                const SizedBox(width: DesignTokens.space6),
                Text(
                  specialty,
                  style: DesignTokens.labelSmall.copyWith(
                    color: isSelected
                        ? color
                        : (isReadOnly
                            ? DesignTokens.neutralWhite
                            : DesignTokens.textSecondary),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemovableChip(String specialty, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space12,
        vertical: DesignTokens.space8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: DesignTokens.space6),
          Text(
            specialty,
            style: DesignTokens.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: DesignTokens.space6),
          GestureDetector(
            onTap: () => _removeSpecialty(specialty),
            child: Icon(
              Icons.close,
              size: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSpecialtySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_showCustomInput)
          GestureDetector(
            onTap: () {
              if (_selectedSpecialties.length < 8) {
                setState(() => _showCustomInput = true);
                _addAnimationController.forward();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space12,
                vertical: DesignTokens.space8,
              ),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radius20),
                border: Border.all(
                  color: DesignTokens.accentGreen,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add,
                    size: 16,
                    color: DesignTokens.accentGreen,
                  ),
                  const SizedBox(width: DesignTokens.space6),
                  Text(
                    'Add Custom Specialty',
                    style: DesignTokens.labelSmall.copyWith(
                      color: DesignTokens.accentGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customSpecialtyController,
                  style: DesignTokens.bodyMedium.copyWith(color: DesignTokens.neutralWhite),
                  decoration: InputDecoration(
                    hintText: 'Enter custom specialty...',
                    hintStyle: DesignTokens.bodyMedium.copyWith(color: DesignTokens.textSecondary),
                    filled: true,
                    fillColor: DesignTokens.primaryDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space12,
                      vertical: DesignTokens.space8,
                    ),
                  ),
                  onSubmitted: (_) => _addCustomSpecialty(),
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              IconButton(
                onPressed: _addCustomSpecialty,
                icon: const Icon(Icons.check, color: DesignTokens.accentGreen),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showCustomInput = false;
                    _customSpecialtyController.clear();
                  });
                  _addAnimationController.reverse();
                },
                icon: const Icon(Icons.close, color: DesignTokens.accentPink),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space24),
      decoration: BoxDecoration(
        color: DesignTokens.primaryDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.star_border,
              size: 32,
              color: DesignTokens.textSecondary,
            ),
            SizedBox(height: DesignTokens.space8),
            Text(
              'No specialties selected',
              style: TextStyle(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: DesignTokens.space4),
            Text(
              'Add specialties to help clients find you',
              style: TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  SpecialtyItem? _findSpecialtyItem(String specialty) {
    for (final category in _predefinedSpecialties) {
      for (final item in category.specialties) {
        if (item.name == specialty) {
          return item;
        }
      }
    }
    return null;
  }
}

class SpecialtyCategory {
  final String name;
  final List<SpecialtyItem> specialties;

  const SpecialtyCategory({
    required this.name,
    required this.specialties,
  });
}

class SpecialtyItem {
  final String name;
  final IconData icon;
  final Color color;

  const SpecialtyItem(this.name, this.icon, this.color);
}