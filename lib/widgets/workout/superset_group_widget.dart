import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/workout/exercise.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../theme/design_tokens.dart';

/// Superset/Circuit group widget for visually grouping exercises
///
/// Shows:
/// - Visual grouping border and badge
/// - Group type indicator (superset, circuit, etc.)
/// - Expandable/collapsible exercises list
/// - Group-level rest period
/// - Reorder exercises within group
///
/// Example:
/// ```dart
/// SupersetGroupWidget(
///   exercises: groupedExercises,
///   groupType: ExerciseGroupType.superset,
///   groupId: 'group-1',
///   groupRest: 120,
///   onReorder: (oldIndex, newIndex) => reorderExercises(),
///   onRemoveFromGroup: (exercise) => removeExercise(),
/// )
/// ```
class SupersetGroupWidget extends StatefulWidget {
  final List<Exercise> exercises;
  final ExerciseGroupType groupType;
  final String groupId;
  final int? groupRest;
  final bool isExpanded;
  final bool isEditable;
  final Function(int oldIndex, int newIndex)? onReorder;
  final Function(Exercise)? onRemoveFromGroup;
  final Function(Exercise)? onEditExercise;
  final VoidCallback? onEditGroup;
  final VoidCallback? onDisbandGroup;

  const SupersetGroupWidget({
    super.key,
    required this.exercises,
    required this.groupType,
    required this.groupId,
    this.groupRest,
    this.isExpanded = true,
    this.isEditable = true,
    this.onReorder,
    this.onRemoveFromGroup,
    this.onEditExercise,
    this.onEditGroup,
    this.onDisbandGroup,
  });

  @override
  State<SupersetGroupWidget> createState() => _SupersetGroupWidgetState();
}

class _SupersetGroupWidgetState extends State<SupersetGroupWidget>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space12,
        vertical: DesignTokens.space8,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getGroupColor(),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: _getGroupColor().withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Group header
              _buildGroupHeader(language),

              // Exercises list
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Column(
                  children: [
                    if (widget.isEditable && widget.onReorder != null)
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.exercises.length,
                        onReorder: widget.onReorder!,
                        itemBuilder: (context, index) {
                          final exercise = widget.exercises[index];
                          return _buildExerciseItem(
                            exercise,
                            index,
                            language,
                            key: ValueKey(exercise.id ?? index),
                          );
                        },
                      )
                    else
                      ...widget.exercises.asMap().entries.map(
                            (entry) => _buildExerciseItem(
                              entry.value,
                              entry.key,
                              language,
                            ),
                          ),

                    // Group rest period
                    if (widget.groupRest != null) _buildGroupRest(language),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String language) {
    return InkWell(
      onTap: _toggleExpanded,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        decoration: BoxDecoration(
          color: _getGroupColor().withValues(alpha: 0.1),
          border: Border(
            bottom: BorderSide(
              color: _getGroupColor().withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Group icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getGroupColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getGroupIcon(),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.space12),

            // Group info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGroupLabel(language),
                    style: DesignTokens.titleMedium.copyWith(
                      color: _getGroupColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.exercises.length} ${LocaleHelper.t('exercises', language)}',
                    style: DesignTokens.labelSmall.copyWith(
                      color: DesignTokens.ink500.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Group actions
            if (widget.isEditable) ...[
              if (widget.onEditGroup != null)
                IconButton(
                  icon: const Icon(Icons.edit),
                  iconSize: 20,
                  onPressed: widget.onEditGroup,
                  color: DesignTokens.ink500,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              if (widget.onDisbandGroup != null)
                IconButton(
                  icon: const Icon(Icons.link_off),
                  iconSize: 20,
                  onPressed: widget.onDisbandGroup,
                  color: DesignTokens.danger,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],

            // Expand/collapse icon
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.expand_more,
                color: _getGroupColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(Exercise exercise, int index, String language,
      {Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space12,
        vertical: DesignTokens.space6,
      ),
      child: Row(
        children: [
          // Exercise number in group
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getGroupColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getGroupColor(),
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.space8),

          // Exercise details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: DesignTokens.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildExerciseDetailsText(exercise, language),
                  style: DesignTokens.labelSmall.copyWith(
                    color: DesignTokens.ink500.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Remove from group button
          if (widget.isEditable && widget.onRemoveFromGroup != null)
            IconButton(
              icon: const Icon(Icons.close),
              iconSize: 18,
              onPressed: () => widget.onRemoveFromGroup!(exercise),
              color: DesignTokens.danger,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),

          // Edit exercise button
          if (widget.isEditable && widget.onEditExercise != null)
            IconButton(
              icon: const Icon(Icons.edit),
              iconSize: 18,
              onPressed: () => widget.onEditExercise!(exercise),
              color: DesignTokens.ink500,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupRest(String language) {
    return Container(
      margin: const EdgeInsets.all(DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: DesignTokens.space8),
          Text(
            '${LocaleHelper.t('group_rest', language)}: ${widget.groupRest}s',
            style: DesignTokens.labelMedium.copyWith(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _buildExerciseDetailsText(Exercise exercise, String language) {
    final parts = <String>[];

    if (exercise.sets != null) {
      parts.add('${exercise.sets} ${LocaleHelper.t('sets', language)}');
    }
    if (exercise.reps != null) {
      parts.add('${exercise.reps} ${LocaleHelper.t('reps', language)}');
    }
    if (exercise.weight != null) {
      parts.add('${exercise.weight} kg');
    }

    return parts.join(' • ');
  }

  String _getGroupLabel(String language) {
    switch (widget.groupType) {
      case ExerciseGroupType.superset:
        return LocaleHelper.t('superset', language);
      case ExerciseGroupType.circuit:
        return LocaleHelper.t('circuit', language);
      case ExerciseGroupType.giantSet:
        return LocaleHelper.t('giant_set', language);
      case ExerciseGroupType.dropSet:
        return LocaleHelper.t('drop_set', language);
      case ExerciseGroupType.restPause:
        return LocaleHelper.t('rest_pause', language);
      default:
        return LocaleHelper.t('exercise_group', language);
    }
  }

  IconData _getGroupIcon() {
    switch (widget.groupType) {
      case ExerciseGroupType.superset:
        return Icons.link;
      case ExerciseGroupType.circuit:
        return Icons.loop;
      case ExerciseGroupType.giantSet:
        return Icons.double_arrow;
      case ExerciseGroupType.dropSet:
        return Icons.trending_down;
      case ExerciseGroupType.restPause:
        return Icons.pause_circle;
      default:
        return Icons.group_work;
    }
  }

  Color _getGroupColor() {
    switch (widget.groupType) {
      case ExerciseGroupType.superset:
        return Colors.blue.shade600;
      case ExerciseGroupType.circuit:
        return Colors.purple.shade600;
      case ExerciseGroupType.giantSet:
        return Colors.orange.shade600;
      case ExerciseGroupType.dropSet:
        return Colors.red.shade600;
      case ExerciseGroupType.restPause:
        return Colors.teal.shade600;
      default:
        return DesignTokens.blue600;
    }
  }
}