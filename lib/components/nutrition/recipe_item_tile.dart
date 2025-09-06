import 'package:flutter/material.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../models/nutrition/recipe.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../services/nutrition/locale_helper.dart';

/// A tile widget for displaying recipe-based food items in meal editor
class RecipeItemTile extends StatefulWidget {
  final FoodItem item;
  final Function(FoodItem) onItemChanged;
  final Function() onRemove;
  final Function(Recipe) onQuickSwap;
  final bool isReadOnly;

  const RecipeItemTile({
    super.key,
    required this.item,
    required this.onItemChanged,
    required this.onRemove,
    required this.onQuickSwap,
    this.isReadOnly = false,
  });

  @override
  State<RecipeItemTile> createState() => _RecipeItemTileState();
}

class _RecipeItemTileState extends State<RecipeItemTile> {
  final NutritionService _nutritionService = NutritionService();
  Recipe? _recipe;
  String? _photoUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipeDetails();
  }

  Future<void> _loadRecipeDetails() async {
    if (widget.item.recipeId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final recipe = await _nutritionService.getRecipeForFoodItem(widget.item);
      final photoUrl = await _nutritionService.getRecipePhotoUrl(widget.item);
      
      setState(() {
        _recipe = recipe;
        _photoUrl = photoUrl;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateServings(double newServings) async {
    if (widget.isReadOnly) return;

    try {
      final updatedItem = await _nutritionService.updateRecipeServings(
        widget.item, 
        newServings,
      );
      widget.onItemChanged(updatedItem);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update servings: $e')),
        );
      }
    }
  }

  void _showServingsDialog() {
    if (widget.isReadOnly) return;

    final controller = TextEditingController(text: widget.item.servings.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleHelper.t('adjust_servings', Localizations.localeOf(context).languageCode)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${LocaleHelper.t('current_servings', Localizations.localeOf(context).languageCode)}: ${widget.item.servings.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: LocaleHelper.t('new_servings', Localizations.localeOf(context).languageCode),
                border: const OutlineInputBorder(),
                suffixText: LocaleHelper.t('servings', Localizations.localeOf(context).languageCode),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleHelper.t('cancel', Localizations.localeOf(context).languageCode)),
          ),
          ElevatedButton(
            onPressed: () {
              final newServings = double.tryParse(controller.text);
              if (newServings != null && newServings > 0) {
                Navigator.pop(context);
                _updateServings(newServings);
              }
            },
            child: Text(LocaleHelper.t('update', Localizations.localeOf(context).languageCode)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading recipe...'),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          // Recipe photo or placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: _photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.restaurant,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : Icon(
                    Icons.restaurant,
                    color: Colors.grey.shade600,
                  ),
          ),
          
          const SizedBox(width: 12),
          
          // Recipe info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.item.servings.toStringAsFixed(1)} ${LocaleHelper.t('servings', language)} • ${widget.item.kcal.toStringAsFixed(0)} ${LocaleHelper.t('kcal', language)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (_recipe != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if ((_recipe!.prepMinutes ?? 0) > 0) ...[
                        Icon(
                          Icons.timer,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${_recipe!.prepMinutes}${LocaleHelper.t('min_prep', language)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_recipe!.halal) ...[
                        Icon(
                          Icons.verified,
                          size: 12,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          LocaleHelper.t('halal', language),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Actions
          if (!widget.isReadOnly) ...[
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'servings':
                    _showServingsDialog();
                    break;
                  case 'swap':
                    if (_recipe != null) {
                      widget.onQuickSwap(_recipe!);
                    }
                    break;
                  case 'view':
                    // TODO: Navigate to recipe details
                    break;
                  case 'remove':
                    widget.onRemove();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'servings',
                  child: Row(
                    children: [
                      const Icon(Icons.tune, size: 16),
                      const SizedBox(width: 8),
                      Text(LocaleHelper.t('adjust_servings', language)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'swap',
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz, size: 16),
                      const SizedBox(width: 8),
                      Text(LocaleHelper.t('quick_swap', language)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'view',
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, size: 16),
                      const SizedBox(width: 8),
                      Text(LocaleHelper.t('view_recipe', language)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        LocaleHelper.t('remove', language),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
