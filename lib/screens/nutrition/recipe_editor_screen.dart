import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../models/nutrition/recipe.dart';
import '../../models/nutrition/preferences.dart';
import '../../services/nutrition/recipe_service.dart';
import '../../services/nutrition/preferences_service.dart';
import '../../components/nutrition/recipe_step_tile.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../services/nutrition/locale_helper.dart';

class RecipeEditorScreen extends StatefulWidget {
  final Recipe? recipe;
  final bool isEditing;
  final String? clientContextUserId; // For coach context awareness

  const RecipeEditorScreen({
    super.key,
    this.recipe,
    this.isEditing = false,
    this.clientContextUserId,
  });

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final RecipeService _recipeService = RecipeService();
  final PreferencesService _preferencesService = PreferencesService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _servingSizeController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _cookTimeController = TextEditingController();
  
  // Recipe data
  Recipe? _recipe;
  List<RecipeStep> _steps = [];
  List<RecipeIngredient> _ingredients = [];
  String? _photoUrl;
  RecipeVisibility _visibility = RecipeVisibility.private;
  
  // Client context for warnings
  Preferences? _clientPreferences;
  List<String> _clientAllergies = [];
  PreferencesWarnings? _recipeWarnings;
  
  // UI state
  bool _isLoading = false;
  bool _isSaving = false;
  int _currentTab = 0;
  
  // Available options
  final List<String> _cuisineOptions = [
    'Italian', 'Mexican', 'Asian', 'Mediterranean', 'Middle Eastern',
    'Indian', 'Chinese', 'Japanese', 'Thai', 'French', 'American'
  ];
  
  final List<String> _dietOptions = [
    'Vegetarian', 'Vegan', 'Keto', 'Paleo', 'Gluten-Free',
    'Dairy-Free', 'Low-Carb', 'High-Protein', 'Low-Fat'
  ];
  
  final List<String> _allergenOptions = [
    'Nuts', 'Dairy', 'Eggs', 'Soy', 'Gluten', 'Shellfish', 'Fish'
  ];

  @override
  void initState() {
    super.initState();
    _initializeRecipe();
    _loadClientContext();
  }

  Future<void> _loadClientContext() async {
    if (widget.clientContextUserId == null) return;
    
    try {
      final preferences = await _preferencesService.getPrefs(widget.clientContextUserId!);
      final allergies = await _preferencesService.getAllergies(widget.clientContextUserId!);
      
      setState(() {
        _clientPreferences = preferences;
        _clientAllergies = allergies;
      });
      
      _checkRecipeWarnings();
    } catch (e) {
      // Handle error silently - client context is optional
    }
  }

  void _checkRecipeWarnings() {
    if (_recipe == null || _clientPreferences == null) return;
    
    final warnings = _preferencesService.validateRecipeAgainstPrefs(
      _recipe!,
      _clientPreferences!,
      _clientAllergies,
    );
    
    setState(() {
      _recipeWarnings = warnings;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _servingSizeController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    super.dispose();
  }

  void _initializeRecipe() {
    if (widget.recipe != null) {
      _recipe = widget.recipe!;
      _titleController.text = _recipe!.title;
      _summaryController.text = _recipe!.summary ?? '';
      _servingSizeController.text = _recipe!.servingSize.toString();
      _prepTimeController.text = _recipe!.prepMinutes.toString();
      _cookTimeController.text = _recipe!.cookMinutes.toString();
      _photoUrl = _recipe!.photoUrl;
      _visibility = _recipe!.visibility;
      _steps = List.from(_recipe!.steps);
      _ingredients = List.from(_recipe!.ingredients);
    } else {
      _servingSizeController.text = '1';
      _prepTimeController.text = '0';
      _cookTimeController.text = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Recipe' : 'Create Recipe'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(DesignTokens.space16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveRecipe,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Client context warning banner
            if (_recipeWarnings?.hasWarnings == true) _buildWarningBanner(theme),
            
            // Tab bar
            _buildTabBar(theme),
            
            // Content
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildBasicInfoTab(theme),
                  _buildIngredientsTab(theme),
                  _buildStepsTab(theme),
                  _buildNutritionTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner(ThemeData theme) {
    final language = Localizations.localeOf(context).languageCode;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: DesignTokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocaleHelper.t('recipe_warnings_for_client', language),
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                if (_recipeWarnings!.notHalal)
                  Text(
                    LocaleHelper.t('not_halal', language),
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 11,
                    ),
                  ),
                if (_recipeWarnings!.allergens.isNotEmpty)
                  Text(
                    '${LocaleHelper.t('contains', language)}: ${_recipeWarnings!.allergens.join(', ')}',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 11,
                    ),
                  ),
                if (_recipeWarnings!.sodiumExceeded)
                  Text(
                    LocaleHelper.t('high_sodium_content', language),
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showWarningDetails,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              LocaleHelper.t('learn_more', language),
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWarningDetails() {
    final language = Localizations.localeOf(context).languageCode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleHelper.t('recipe_warnings', language)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocaleHelper.t('recipe_warnings_explanation', language)),
            const SizedBox(height: DesignTokens.space16),
            if (_recipeWarnings!.notHalal)
              _buildWarningDetailItem(
                LocaleHelper.t('not_halal', language),
                LocaleHelper.t('not_halal_explanation', language),
                Icons.restaurant,
              ),
            if (_recipeWarnings!.allergens.isNotEmpty)
              _buildWarningDetailItem(
                '${LocaleHelper.t('contains', language)}: ${_recipeWarnings!.allergens.join(', ')}',
                LocaleHelper.t('allergen_explanation', language),
                Icons.warning,
              ),
            if (_recipeWarnings!.sodiumExceeded)
              _buildWarningDetailItem(
                LocaleHelper.t('high_sodium_content', language),
                LocaleHelper.t('sodium_explanation', language),
                Icons.restaurant,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleHelper.t('close', language)),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningDetailItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: DesignTokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: TabBar(
        onTap: (index) => setState(() => _currentTab = index),
        tabs: const [
          Tab(text: 'Basic Info'),
          Tab(text: 'Ingredients'),
          Tab(text: 'Steps'),
          Tab(text: 'Nutrition'),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero photo
          _buildPhotoSection(theme),
          
          const SizedBox(height: DesignTokens.space24),
          
          // Basic information
          _buildBasicInfoSection(theme),
          
          const SizedBox(height: DesignTokens.space24),
          
          // Tags and preferences
          _buildTagsSection(theme),
          
          const SizedBox(height: DesignTokens.space24),
          
          // Visibility
          _buildVisibilitySection(theme),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recipe Photo',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: DesignTokens.space8),
        GestureDetector(
          onTap: _pickPhoto,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: _photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    child: Image.network(
                      _photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPhotoPlaceholder(theme),
                    ),
                  )
                : _buildPhotoPlaceholder(theme),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Tap to add photo',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: DesignTokens.space16),
        
        // Title
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Recipe Title',
            hintText: 'Enter recipe name',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a recipe title';
            }
            return null;
          },
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Summary
        TextFormField(
          controller: _summaryController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Brief description of the recipe',
          ),
          maxLines: 3,
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Serving size and time
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _servingSizeController,
                decoration: const InputDecoration(
                  labelText: 'Servings',
                  hintText: '1',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final serving = double.tryParse(value);
                  if (serving == null || serving <= 0) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: DesignTokens.space16),
            Expanded(
              child: TextFormField(
                controller: _prepTimeController,
                decoration: const InputDecoration(
                  labelText: 'Prep Time (min)',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final time = int.tryParse(value);
                  if (time == null || time < 0) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: DesignTokens.space16),
            Expanded(
              child: TextFormField(
                controller: _cookTimeController,
                decoration: const InputDecoration(
                  labelText: 'Cook Time (min)',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final time = int.tryParse(value);
                  if (time == null || time < 0) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags & Preferences',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: DesignTokens.space16),
        
        // Cuisine tags
        _buildTagSelector(
          theme,
          'Cuisine',
          _cuisineOptions,
          _recipe?.cuisineTags ?? [],
          (tags) => setState(() => _recipe = _recipe?.copyWith(cuisineTags: tags)),
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Diet tags
        _buildTagSelector(
          theme,
          'Diet',
          _dietOptions,
          _recipe?.dietTags ?? [],
          (tags) => setState(() => _recipe = _recipe?.copyWith(dietTags: tags)),
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Allergens
        _buildTagSelector(
          theme,
          'Allergens',
          _allergenOptions,
          _recipe?.allergens ?? [],
          (allergens) {
            setState(() => _recipe = _recipe?.copyWith(allergens: allergens));
            _checkRecipeWarnings();
          },
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Halal checkbox
        CheckboxListTile(
          title: const Text('Halal'),
          value: _recipe?.halal ?? false,
          onChanged: (value) {
            setState(() => _recipe = _recipe?.copyWith(halal: value ?? false));
            _checkRecipeWarnings();
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildTagSelector(
    ThemeData theme,
    String title,
    List<String> options,
    List<String> selected,
    Function(List<String>) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: DesignTokens.space8),
        Wrap(
          spacing: DesignTokens.space8,
          runSpacing: DesignTokens.space8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (isSelected) {
                final newTags = List<String>.from(selected);
                if (isSelected) {
                  newTags.add(option);
                } else {
                  newTags.remove(option);
                }
                onChanged(newTags);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVisibilitySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visibility',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: DesignTokens.space8),
        ...RecipeVisibility.values.map((visibility) {
          return RadioListTile<RecipeVisibility>(
            title: Text(visibility.value.toUpperCase()),
            subtitle: Text(_getVisibilityDescription(visibility)),
            value: visibility,
            groupValue: _visibility,
            onChanged: (value) => setState(() => _visibility = value!),
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }

  String _getVisibilityDescription(RecipeVisibility visibility) {
    switch (visibility) {
      case RecipeVisibility.private:
        return 'Only you can see this recipe';
      case RecipeVisibility.client:
        return 'Visible to your clients';
      case RecipeVisibility.team:
        return 'Visible to your team members';
      case RecipeVisibility.public:
        return 'Visible to everyone';
    }
  }

  Widget _buildIngredientsTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        children: [
          // Add ingredient button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
              label: const Text('Add Ingredient'),
            ),
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Ingredients list
          Expanded(
            child: _ingredients.isEmpty
                ? _buildEmptyIngredientsState(theme)
                : ListView.builder(
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = _ingredients[index];
                      return _buildIngredientTile(theme, ingredient, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyIngredientsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            'No ingredients added yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Add ingredients to build your recipe',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientTile(ThemeData theme, RecipeIngredient ingredient, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.space8),
      child: ListTile(
        title: Text(ingredient.name),
        subtitle: Text('${ingredient.amount} ${ingredient.unit ?? 'g'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editIngredient(ingredient, index),
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              onPressed: () => _removeIngredient(index),
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        children: [
          // Add step button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addStep,
              icon: const Icon(Icons.add),
              label: const Text('Add Step'),
            ),
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Steps list
          Expanded(
            child: ReorderableRecipeStepsList(
              steps: _steps,
              onReorder: _reorderSteps,
              onEdit: _editStep,
              onDelete: _removeStep,
              isEditable: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTab(ThemeData theme) {
    // Calculate total nutrition from ingredients
    final totalNutrition = _calculateTotalNutrition();
    
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Summary',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: DesignTokens.space16),
          
          // Nutrition cards
          _buildNutritionCards(theme, totalNutrition),
          
          const SizedBox(height: DesignTokens.space24),
          
          Text(
            'Per Serving',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: DesignTokens.space16),
          
          // Per serving nutrition
          _buildPerServingNutrition(theme, totalNutrition),
        ],
      ),
    );
  }

  Widget _buildNutritionCards(ThemeData theme, Map<String, double> nutrition) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: DesignTokens.space16,
      mainAxisSpacing: DesignTokens.space16,
      children: [
        _buildNutritionCard(theme, 'Calories', '${nutrition['calories']?.round() ?? 0}', Icons.local_fire_department, Colors.orange),
        _buildNutritionCard(theme, 'Protein', '${nutrition['protein']?.toStringAsFixed(1) ?? '0'}g', Icons.fitness_center, Colors.blue),
        _buildNutritionCard(theme, 'Carbs', '${nutrition['carbs']?.toStringAsFixed(1) ?? '0'}g', Icons.grain, Colors.green),
        _buildNutritionCard(theme, 'Fat', '${nutrition['fat']?.toStringAsFixed(1) ?? '0'}g', Icons.opacity, Colors.purple),
      ],
    );
  }

  Widget _buildNutritionCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: DesignTokens.space4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerServingNutrition(ThemeData theme, Map<String, double> nutrition) {
    final servingSize = double.tryParse(_servingSizeController.text) ?? 1.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          children: [
            _buildNutritionRow(theme, 'Calories', (nutrition['calories'] ?? 0) / servingSize),
            _buildNutritionRow(theme, 'Protein', (nutrition['protein'] ?? 0) / servingSize),
            _buildNutritionRow(theme, 'Carbs', (nutrition['carbs'] ?? 0) / servingSize),
            _buildNutritionRow(theme, 'Fat', (nutrition['fat'] ?? 0) / servingSize),
            _buildNutritionRow(theme, 'Sodium', (nutrition['sodium'] ?? 0) / servingSize),
            _buildNutritionRow(theme, 'Potassium', (nutrition['potassium'] ?? 0) / servingSize),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(ThemeData theme, String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.space4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            label == 'Calories' 
                ? '${value.round()}'
                : '${value.toStringAsFixed(1)}g',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateTotalNutrition() {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double sodium = 0;
    double potassium = 0;

    for (final ingredient in _ingredients) {
      calories += ingredient.calories;
      protein += ingredient.protein;
      carbs += ingredient.carbs;
      fat += ingredient.fat;
      sodium += ingredient.sodiumMg;
      potassium += ingredient.potassiumMg;
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sodium': sodium,
      'potassium': potassium,
    };
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      // TODO: Upload photo to Supabase Storage
      setState(() {
        _photoUrl = 'placeholder_url'; // Replace with actual uploaded URL
      });
    }
  }

  void _addIngredient() {
    // TODO: Show ingredient editor dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add ingredient dialog coming soon')),
    );
  }

  void _editIngredient(RecipeIngredient ingredient, int index) {
    // TODO: Show ingredient editor dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit ingredient dialog coming soon')),
    );
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addStep() {
    // TODO: Show step editor dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add step dialog coming soon')),
    );
  }

  void _editStep(RecipeStep step, int index) {
    // TODO: Show step editor dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit step dialog coming soon')),
    );
  }

  void _removeStep(RecipeStep step, int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _reorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
      
      // Update step indices
      for (int i = 0; i < _steps.length; i++) {
        _steps[i] = _steps[i].copyWith(stepIndex: i + 1);
      }
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final servingSize = double.parse(_servingSizeController.text);
      final prepMinutes = int.parse(_prepTimeController.text);
      final cookMinutes = int.parse(_cookTimeController.text);
      final totalMinutes = prepMinutes + cookMinutes;

      final recipe = Recipe(
        id: _recipe?.id ?? '',
        owner: _recipe?.owner ?? 'current_user_id', // TODO: Get from auth
        coachId: _recipe?.coachId,
        title: _titleController.text,
        summary: _summaryController.text,
        servings: servingSize,
        servingUnit: 'serving',
        prepMinutes: prepMinutes,
        cookMinutes: cookMinutes,
        heroPhotoPath: _photoUrl,
        visibility: _visibility,
        createdAt: _recipe?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        steps: _steps,
        ingredients: _ingredients,
        cuisineTags: _recipe?.cuisineTags ?? [],
        dietTags: _recipe?.dietTags ?? [],
        allergens: _recipe?.allergens ?? [],
        halal: _recipe?.halal ?? false,
        calories: _recipe?.calories ?? 0,
        protein: _recipe?.protein ?? 0,
        carbs: _recipe?.carbs ?? 0,
        fat: _recipe?.fat ?? 0,
        sodiumMg: _recipe?.sodiumMg ?? 0,
        potassiumMg: _recipe?.potassiumMg ?? 0,
        micros: _recipe?.micros ?? const Micros({}),
      );

      if (widget.isEditing) {
        await _recipeService.updateRecipe(recipe);
      } else {
        await _recipeService.createRecipe(recipe);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEditing ? 'Recipe updated!' : 'Recipe created!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save recipe: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
