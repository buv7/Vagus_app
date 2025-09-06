import 'package:flutter/material.dart';
import '../../models/nutrition/recipe.dart';
import '../../theme/design_tokens.dart';

class RecipeStepTile extends StatelessWidget {
  final RecipeStep step;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool isEditable;
  final bool showReorderHandles;

  const RecipeStepTile({
    super.key,
    required this.step,
    required this.index,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
    this.isEditable = false,
    this.showReorderHandles = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with step number and actions
              Row(
                children: [
                  // Step number
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(DesignTokens.radius16),
                    ),
                    child: Center(
                      child: Text(
                        '${step.stepIndex}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: DesignTokens.space12),
                  
                  // Step instruction
                  Expanded(
                    child: Text(
                      step.instruction,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  
                  // Action buttons
                  if (isEditable) ...[
                    const SizedBox(width: DesignTokens.space8),
                    _buildActionButtons(theme),
                  ],
                ],
              ),
              
              // Step photo
              if (step.photoUrl != null && step.photoUrl!.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.space12),
                _buildStepPhoto(context, theme),
              ],
              
              // Reorder handles
              if (showReorderHandles && isEditable) ...[
                const SizedBox(height: DesignTokens.space8),
                _buildReorderHandles(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit button
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.edit,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        
        // Delete button
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: theme.colorScheme.error,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
      ],
    );
  }

  Widget _buildStepPhoto(BuildContext context, ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radius8),
      child: Container(
        width: double.infinity,
        height: 200,
        child: Image.network(
          step.photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPhotoPlaceholder(theme),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPhotoLoading(theme);
          },
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 200,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Step Photo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoLoading(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 200,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildReorderHandles(ThemeData theme) {
    return Row(
      children: [
        // Move up button
        if (onMoveUp != null)
          IconButton(
            onPressed: onMoveUp,
            icon: Icon(
              Icons.keyboard_arrow_up,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        
        // Move down button
        if (onMoveDown != null)
          IconButton(
            onPressed: onMoveDown,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        
        const Spacer(),
        
        // Drag handle
        Icon(
          Icons.drag_handle,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ],
    );
  }
}

/// Reorderable list wrapper for recipe steps
class ReorderableRecipeStepsList extends StatelessWidget {
  final List<RecipeStep> steps;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(RecipeStep step, int index)? onEdit;
  final Function(RecipeStep step, int index)? onDelete;
  final bool isEditable;

  const ReorderableRecipeStepsList({
    super.key,
    required this.steps,
    required this.onReorder,
    this.onEdit,
    this.onDelete,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return _buildEmptyState(context);
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final step = steps[index];
        return RecipeStepTile(
          key: ValueKey(step.id ?? index),
          step: step,
          index: index,
          isEditable: isEditable,
          showReorderHandles: isEditable,
          onEdit: onEdit != null ? () => onEdit!(step, index) : null,
          onDelete: onDelete != null ? () => onDelete!(step, index) : null,
          onMoveUp: index > 0 ? () => onReorder(index, index - 1) : null,
          onMoveDown: index < steps.length - 1 ? () => onReorder(index, index + 1) : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space32),
      child: Column(
        children: [
          Icon(
            Icons.list_alt,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            'No steps added yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Add cooking steps to create your recipe',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
