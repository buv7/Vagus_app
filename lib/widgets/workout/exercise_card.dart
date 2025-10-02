import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/workout/exercise.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../theme/design_tokens.dart';

/// Exercise card widget displaying exercise details with quick actions
///
/// Shows:
/// - Exercise name with demo video thumbnail
/// - Set/rep/rest display
/// - Weight progression indicator
/// - Group badge (if in superset/circuit)
/// - Quick actions (edit, delete, reorder)
/// - History preview
/// - Comment section
///
/// Example:
/// ```dart
/// ExerciseCard(
///   exercise: exercise,
///   showGroupBadge: true,
///   onEdit: () => editExercise(),
///   onDelete: () => deleteExercise(),
///   onViewHistory: () => showHistory(),
///   onPlayDemo: () => playDemoVideo(),
/// )
/// ```
class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final bool showGroupBadge;
  final bool isEditable;
  final bool isDraggable;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewHistory;
  final VoidCallback? onPlayDemo;
  final VoidCallback? onReorder;
  final String? previousWeight;
  final String? comment;
  final Function(String)? onCommentChanged;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.showGroupBadge = false,
    this.isEditable = true,
    this.isDraggable = false,
    this.onEdit,
    this.onDelete,
    this.onViewHistory,
    this.onPlayDemo,
    this.onReorder,
    this.previousWeight,
    this.comment,
    this.onCommentChanged,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  bool _isExpanded = false;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment != widget.comment &&
        _commentController.text != widget.comment) {
      _commentController.text = widget.comment ?? '';
    }
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getGroupColor().withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Main card content
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          // Drag handle
                          if (widget.isDraggable)
                            Icon(
                              Icons.drag_handle,
                              color: DesignTokens.ink500.withValues(alpha: 0.4),
                              size: 20,
                            ),
                          if (widget.isDraggable)
                            const SizedBox(width: DesignTokens.space8),

                          // Group badge
                          if (widget.showGroupBadge &&
                              widget.exercise.groupType != ExerciseGroupType.none)
                            _buildGroupBadge(language),

                          // Exercise name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.exercise.name,
                                  style: DesignTokens.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.previousWeight != null)
                                  _buildProgressIndicator(language),
                              ],
                            ),
                          ),

                          // Quick actions
                          if (widget.isEditable) _buildQuickActions(),
                        ],
                      ),

                      const SizedBox(height: DesignTokens.space12),

                      // Exercise details
                      _buildExerciseDetails(language),

                      // Expanded details
                      if (_isExpanded) ...[
                        const SizedBox(height: DesignTokens.space12),
                        _buildExpandedDetails(language),
                      ],
                    ],
                  ),
                ),
              ),

              // Comment section
              if (_isExpanded && widget.onCommentChanged != null)
                _buildCommentSection(language),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupBadge(String language) {
    final groupType = widget.exercise.groupType;
    String label;
    IconData icon;

    switch (groupType) {
      case ExerciseGroupType.superset:
        label = LocaleHelper.t('superset', language);
        icon = Icons.link;
        break;
      case ExerciseGroupType.circuit:
        label = LocaleHelper.t('circuit', language);
        icon = Icons.loop;
        break;
      case ExerciseGroupType.giantSet:
        label = LocaleHelper.t('giant_set', language);
        icon = Icons.double_arrow;
        break;
      case ExerciseGroupType.dropSet:
        label = LocaleHelper.t('drop_set', language);
        icon = Icons.trending_down;
        break;
      case ExerciseGroupType.restPause:
        label = LocaleHelper.t('rest_pause', language);
        icon = Icons.pause_circle;
        break;
      default:
        return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(right: DesignTokens.space8),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space8,
        vertical: DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: _getGroupColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(
          color: _getGroupColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _getGroupColor()),
          const SizedBox(width: 4),
          Text(
            label,
            style: DesignTokens.labelSmall.copyWith(
              color: _getGroupColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String language) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            size: 12,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            '${LocaleHelper.t('last', language)}: ${widget.previousWeight}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Demo video
        if (widget.onPlayDemo != null)
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            iconSize: 20,
            onPressed: widget.onPlayDemo,
            tooltip: 'Play demo',
            color: DesignTokens.blue600,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

        // History
        if (widget.onViewHistory != null)
          IconButton(
            icon: const Icon(Icons.history),
            iconSize: 20,
            onPressed: widget.onViewHistory,
            tooltip: 'View history',
            color: DesignTokens.ink500,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

        // Edit
        if (widget.onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit),
            iconSize: 20,
            onPressed: widget.onEdit,
            tooltip: 'Edit',
            color: DesignTokens.ink500,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

        // Delete
        if (widget.onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete),
            iconSize: 20,
            onPressed: widget.onDelete,
            tooltip: 'Delete',
            color: DesignTokens.danger,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }

  Widget _buildExerciseDetails(String language) {
    return Wrap(
      spacing: DesignTokens.space12,
      runSpacing: DesignTokens.space8,
      children: [
        if (widget.exercise.sets != null)
          _buildDetailChip(
            Icons.numbers,
            '${widget.exercise.sets} ${LocaleHelper.t('sets', language)}',
            Colors.blue.shade600,
          ),
        if (widget.exercise.reps != null)
          _buildDetailChip(
            Icons.refresh,
            '${widget.exercise.reps} ${LocaleHelper.t('reps', language)}',
            Colors.green.shade600,
          ),
        if (widget.exercise.weight != null)
          _buildDetailChip(
            Icons.fitness_center,
            '${widget.exercise.weight} kg',
            Colors.purple.shade600,
          ),
        if (widget.exercise.rest != null)
          _buildDetailChip(
            Icons.timer,
            '${widget.exercise.rest}s ${LocaleHelper.t('rest', language)}',
            Colors.orange.shade600,
          ),
        if (widget.exercise.tempo != null)
          _buildDetailChip(
            Icons.speed,
            widget.exercise.tempo!,
            Colors.teal.shade600,
          ),
        if (widget.exercise.rir != null)
          _buildDetailChip(
            Icons.battery_charging_full,
            'RIR: ${widget.exercise.rir}',
            Colors.red.shade600,
          ),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: DesignTokens.space8),

        // Additional details
        if (widget.exercise.percent1RM != null)
          _buildDetailRow(
            LocaleHelper.t('percent_1rm', language),
            '${widget.exercise.percent1RM}%',
            Icons.analytics,
          ),

        if (widget.exercise.notes != null &&
            widget.exercise.notes!.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.space8),
          _buildDetailRow(
            LocaleHelper.t('notes', language),
            widget.exercise.notes!,
            Icons.note,
          ),
        ],

        // Calculated metrics
        if (widget.exercise.calculateVolume() != null) ...[
          const SizedBox(height: DesignTokens.space8),
          _buildDetailRow(
            LocaleHelper.t('volume', language),
            '${widget.exercise.calculateVolume()!.toStringAsFixed(0)} kg',
            Icons.bar_chart,
          ),
        ],

        if (widget.exercise.calculateEstimated1RM() != null) ...[
          const SizedBox(height: DesignTokens.space8),
          _buildDetailRow(
            LocaleHelper.t('estimated_1rm', language),
            '${widget.exercise.calculateEstimated1RM()!.toStringAsFixed(1)} kg',
            Icons.trending_up,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: DesignTokens.ink500.withValues(alpha: 0.6),
        ),
        const SizedBox(width: DesignTokens.space8),
        Text(
          '$label: ',
          style: DesignTokens.labelMedium.copyWith(
            color: DesignTokens.ink500.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: DesignTokens.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection(String language) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: DesignTokens.ink500.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(
            color: DesignTokens.ink500.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.comment,
                size: 16,
                color: DesignTokens.ink500.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                LocaleHelper.t('exercise_notes', language),
                style: DesignTokens.labelMedium.copyWith(
                  color: DesignTokens.ink500.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space8),
          TextField(
            controller: _commentController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: LocaleHelper.t('add_exercise_notes', language),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: DesignTokens.ink500.withValues(alpha: 0.2),
                ),
              ),
              contentPadding: const EdgeInsets.all(8),
              isDense: true,
            ),
            style: DesignTokens.bodySmall,
            onChanged: widget.onCommentChanged,
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (widget.exercise.groupType != ExerciseGroupType.none) {
      return _getGroupColor();
    }
    return Colors.white.withValues(alpha: 0.1);
  }

  Color _getGroupColor() {
    switch (widget.exercise.groupType) {
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
        return DesignTokens.ink500;
    }
  }
}