import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/recipe.dart';

class RecipeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========================================
  // RECIPE CRUD OPERATIONS
  // ========================================

  /// Create a new recipe
  Future<String> createRecipe(Recipe recipe) async {
    try {
      final response = await _supabase
          .from('nutrition_recipes')
          .insert(recipe.toMap())
          .select()
          .single();

      final recipeId = response['id']?.toString() ?? '';
      
      // Create steps and ingredients if provided
      if (recipe.steps.isNotEmpty) {
        await _createRecipeSteps(recipeId, recipe.steps);
      }
      
      if (recipe.ingredients.isNotEmpty) {
        await _createRecipeIngredients(recipeId, recipe.ingredients);
      }

      return recipeId;
    } catch (e) {
      throw Exception('Failed to create recipe: $e');
    }
  }

  /// Fetch a recipe by ID with steps and ingredients
  Future<Recipe?> fetchRecipe(String recipeId) async {
    try {
      final response = await _supabase
          .from('nutrition_recipes')
          .select()
          .eq('id', recipeId)
          .single();

      final recipe = Recipe.fromMap(response);
      
      // Fetch steps and ingredients
      final steps = await _fetchRecipeSteps(recipeId);
      final ingredients = await _fetchRecipeIngredients(recipeId);
      
      return recipe.copyWith(
        steps: steps,
        ingredients: ingredients,
      );
    } catch (e) {
      if (e.toString().contains('No rows found')) {
        return null;
      }
      throw Exception('Failed to fetch recipe: $e');
    }
  }

  /// Update an existing recipe
  Future<void> updateRecipe(Recipe recipe) async {
    // Recipe ID is guaranteed to be non-null

    try {
      await _supabase
          .from('nutrition_recipes')
          .update(recipe.toMap())
          .eq('id', recipe.id);

      // Update steps and ingredients
      if (recipe.steps.isNotEmpty) {
        await _updateRecipeSteps(recipe.id, recipe.steps);
      }
      
      if (recipe.ingredients.isNotEmpty) {
        await _updateRecipeIngredients(recipe.id, recipe.ingredients);
      }
    } catch (e) {
      throw Exception('Failed to update recipe: $e');
    }
  }

  /// Delete a recipe
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _supabase
          .from('nutrition_recipes')
          .delete()
          .eq('id', recipeId);
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }

  // ========================================
  // RECIPE QUERYING AND FILTERING
  // ========================================

  /// Fetch recipes with filters
  Future<List<Recipe>> fetchRecipes({
    String? owner,
    String? coachId,
    RecipeVisibility? visibility,
    List<String>? cuisineTags,
    List<String>? dietTags,
    List<String>? allergens,
    bool? halal,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase
          .from('nutrition_recipes')
          .select()
          .order('created_at', ascending: false);

      // Apply filters - using basic query for now
      // Note: Filter methods may need to be adjusted based on Supabase version
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await query;
      
      return (response as List<dynamic>)
          .map((recipe) => Recipe.fromMap(recipe as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recipes: $e');
    }
  }

  /// Fetch public recipes
  Future<List<Recipe>> fetchPublicRecipes({
    String? searchQuery,
    List<String>? cuisineTags,
    List<String>? dietTags,
    bool? halal,
    int? limit,
  }) async {
    return fetchRecipes(
      visibility: RecipeVisibility.public,
      searchQuery: searchQuery,
      cuisineTags: cuisineTags,
      dietTags: dietTags,
      halal: halal,
      limit: limit,
    );
  }

  /// Fetch user's own recipes
  Future<List<Recipe>> fetchUserRecipes(String userId) async {
    return fetchRecipes(owner: userId);
  }

  /// Fetch recipes assigned to a coach
  Future<List<Recipe>> fetchCoachRecipes(String coachId) async {
    return fetchRecipes(coachId: coachId);
  }

  // ========================================
  // RECIPE STEPS OPERATIONS
  // ========================================

  /// Create recipe steps
  Future<void> _createRecipeSteps(String recipeId, List<RecipeStep> steps) async {
    try {
      final stepsData = steps.map((step) => step.copyWith(recipeId: recipeId).toMap()).toList();
      
      await _supabase
          .from('nutrition_recipe_steps')
          .insert(stepsData);
    } catch (e) {
      throw Exception('Failed to create recipe steps: $e');
    }
  }

  /// Fetch recipe steps
  Future<List<RecipeStep>> _fetchRecipeSteps(String recipeId) async {
    try {
      final response = await _supabase
          .from('nutrition_recipe_steps')
          .select()
          .eq('recipe_id', recipeId)
          .order('step_index');

      return (response as List<dynamic>)
          .map((step) => RecipeStep.fromMap(step as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recipe steps: $e');
    }
  }

  /// Update recipe steps
  Future<void> _updateRecipeSteps(String recipeId, List<RecipeStep> steps) async {
    try {
      // Delete existing steps
      await _supabase
          .from('nutrition_recipe_steps')
          .delete()
          .eq('recipe_id', recipeId);

      // Insert new steps
      if (steps.isNotEmpty) {
        await _createRecipeSteps(recipeId, steps);
      }
    } catch (e) {
      throw Exception('Failed to update recipe steps: $e');
    }
  }

  /// Add a single step to a recipe
  Future<String> addRecipeStep(String recipeId, RecipeStep step) async {
    try {
      final response = await _supabase
          .from('nutrition_recipe_steps')
          .insert(step.copyWith(recipeId: recipeId).toMap())
          .select()
          .single();

      return response['id']?.toString() ?? '';
    } catch (e) {
      throw Exception('Failed to add recipe step: $e');
    }
  }

  /// Update a single recipe step
  Future<void> updateRecipeStep(RecipeStep step) async {
    // Step ID is guaranteed to be non-null

    try {
      await _supabase
          .from('nutrition_recipe_steps')
          .update(step.toMap())
          .eq('id', step.id);
    } catch (e) {
      throw Exception('Failed to update recipe step: $e');
    }
  }

  /// Delete a recipe step
  Future<void> deleteRecipeStep(String stepId) async {
    try {
      await _supabase
          .from('nutrition_recipe_steps')
          .delete()
          .eq('id', stepId);
    } catch (e) {
      throw Exception('Failed to delete recipe step: $e');
    }
  }

  // ========================================
  // RECIPE INGREDIENTS OPERATIONS
  // ========================================

  /// Create recipe ingredients
  Future<void> _createRecipeIngredients(String recipeId, List<RecipeIngredient> ingredients) async {
    try {
      final ingredientsData = ingredients
          .map((ingredient) => ingredient.copyWith(recipeId: recipeId).toMap())
          .toList();
      
      await _supabase
          .from('nutrition_recipe_ingredients')
          .insert(ingredientsData);
    } catch (e) {
      throw Exception('Failed to create recipe ingredients: $e');
    }
  }

  /// Fetch recipe ingredients
  Future<List<RecipeIngredient>> _fetchRecipeIngredients(String recipeId) async {
    try {
      final response = await _supabase
          .from('nutrition_recipe_ingredients')
          .select()
          .eq('recipe_id', recipeId)
          .order('order_index');

      return (response as List<dynamic>)
          .map((ingredient) => RecipeIngredient.fromMap(ingredient as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recipe ingredients: $e');
    }
  }

  /// Update recipe ingredients
  Future<void> _updateRecipeIngredients(String recipeId, List<RecipeIngredient> ingredients) async {
    try {
      // Delete existing ingredients
      await _supabase
          .from('nutrition_recipe_ingredients')
          .delete()
          .eq('recipe_id', recipeId);

      // Insert new ingredients
      if (ingredients.isNotEmpty) {
        await _createRecipeIngredients(recipeId, ingredients);
      }
    } catch (e) {
      throw Exception('Failed to update recipe ingredients: $e');
    }
  }

  /// Add a single ingredient to a recipe
  Future<String> addRecipeIngredient(String recipeId, RecipeIngredient ingredient) async {
    try {
      final response = await _supabase
          .from('nutrition_recipe_ingredients')
          .insert(ingredient.copyWith(recipeId: recipeId).toMap())
          .select()
          .single();

      return response['id']?.toString() ?? '';
    } catch (e) {
      throw Exception('Failed to add recipe ingredient: $e');
    }
  }

  /// Update a single recipe ingredient
  Future<void> updateRecipeIngredient(RecipeIngredient ingredient) async {
    if (ingredient.id == null) {
      throw Exception('Cannot update ingredient without ID');
    }

    try {
      await _supabase
          .from('nutrition_recipe_ingredients')
          .update(ingredient.toMap())
          .eq('id', ingredient.id!);
    } catch (e) {
      throw Exception('Failed to update recipe ingredient: $e');
    }
  }

  /// Delete a recipe ingredient
  Future<void> deleteRecipeIngredient(String ingredientId) async {
    try {
      await _supabase
          .from('nutrition_recipe_ingredients')
          .delete()
          .eq('id', ingredientId);
    } catch (e) {
      throw Exception('Failed to delete recipe ingredient: $e');
    }
  }

  // ========================================
  // RECIPE SCALING AND NUTRITION
  // ========================================

  /// Scale recipe to different serving size
  Future<Recipe> scaleRecipe(String recipeId, double targetServings) async {
    try {
      final recipe = await fetchRecipe(recipeId);
      if (recipe == null) {
        throw Exception('Recipe not found');
      }

      return recipe.scaleToServings(targetServings);
    } catch (e) {
      throw Exception('Failed to scale recipe: $e');
    }
  }

  /// Recalculate recipe nutrition from ingredients
  Future<void> recalculateRecipeNutrition(String recipeId) async {
    try {
      // This will trigger the database function to recalculate nutrition
      await _supabase.rpc('calculate_recipe_nutrition', params: {
        'recipe_uuid': recipeId,
      });
    } catch (e) {
      throw Exception('Failed to recalculate recipe nutrition: $e');
    }
  }

  // ========================================
  // PHOTO UPLOAD AND SIGNED URLS
  // ========================================

  /// Upload recipe photo
  Future<String> uploadRecipePhoto(String recipeId, Uint8List photoBytes, String fileName) async {
    try {
      final filePath = 'recipes/$recipeId/$fileName';
      
      await _supabase.storage
          .from('vagus-media')
          .uploadBinary(filePath, photoBytes);

      return filePath;
    } catch (e) {
      throw Exception('Failed to upload recipe photo: $e');
    }
  }

  /// Upload step photo
  Future<String> uploadStepPhoto(String recipeId, String stepId, Uint8List photoBytes, String fileName) async {
    try {
      final filePath = 'recipes/$recipeId/steps/$stepId/$fileName';
      
      await _supabase.storage
          .from('vagus-media')
          .uploadBinary(filePath, photoBytes);

      return filePath;
    } catch (e) {
      throw Exception('Failed to upload step photo: $e');
    }
  }

  /// Get signed URL for recipe photo
  Future<String?> getRecipePhotoUrl(String photoPath) async {
    try {
      if (photoPath.isEmpty) return null;
      
      final response = await _supabase.storage
          .from('vagus-media')
          .createSignedUrl(photoPath, 3600); // 1 hour expiry

      return response;
    } catch (e) {
      throw Exception('Failed to get recipe photo URL: $e');
    }
  }

  /// Get signed URL for step photo
  Future<String?> getStepPhotoUrl(String photoPath) async {
    try {
      if (photoPath.isEmpty) return null;
      
      final response = await _supabase.storage
          .from('vagus-media')
          .createSignedUrl(photoPath, 3600); // 1 hour expiry

      return response;
    } catch (e) {
      throw Exception('Failed to get step photo URL: $e');
    }
  }

  // ========================================
  // RECIPE SUGGESTIONS AND SIMILARITY
  // ========================================

  /// Find similar recipes based on protein content and cuisine
  Future<List<Recipe>> findSimilarRecipes(String recipeId, {int limit = 3}) async {
    try {
      final recipe = await fetchRecipe(recipeId);
      if (recipe == null) {
        throw Exception('Recipe not found');
      }

      // Find recipes with similar protein content (±15%) and same cuisine tags
      final proteinMin = recipe.protein * 0.85;
      final proteinMax = recipe.protein * 1.15;

      final query = _supabase
          .from('nutrition_recipes')
          .select()
          .neq('id', recipeId)
          .gte('protein', proteinMin)
          .lte('protein', proteinMax)
          .limit(limit);

      // Filter by cuisine tags if available
      // Note: overlaps method may need to be adjusted based on Supabase version
      // if (recipe.cuisineTags.isNotEmpty) {
      //   query = query.overlaps('cuisine_tags', recipe.cuisineTags);
      // }

      final response = await query;
      
      return (response as List<dynamic>)
          .map((recipe) => Recipe.fromMap(recipe as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to find similar recipes: $e');
    }
  }

  /// Get quick recipes (prep + cook time < 20 minutes)
  Future<List<Recipe>> getQuickRecipes({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('nutrition_recipes')
          .select()
          .lt('total_minutes', 20)
          .eq('visibility', 'public')
          .order('total_minutes')
          .limit(limit);

      return (response as List<dynamic>)
          .map((recipe) => Recipe.fromMap(recipe as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch quick recipes: $e');
    }
  }

  /// Get budget-friendly recipes (based on ingredient count and complexity)
  Future<List<Recipe>> getBudgetRecipes({int limit = 10}) async {
    try {
      // Simple heuristic: recipes with fewer ingredients and lower total time
      final response = await _supabase
          .from('nutrition_recipes')
          .select()
          .eq('visibility', 'public')
          .lt('total_minutes', 45)
          .order('total_minutes')
          .limit(limit);

      return (response as List<dynamic>)
          .map((recipe) => Recipe.fromMap(recipe as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch budget recipes: $e');
    }
  }

  // ========================================
  // RECIPE VALIDATION AND HELPERS
  // ========================================

  /// Validate recipe data before saving
  bool validateRecipe(Recipe recipe) {
    if (recipe.title.isEmpty) return false;
    if ((recipe.servingSize ?? 0) <= 0) return false;
    if ((recipe.prepMinutes ?? 0) < 0 || (recipe.cookMinutes ?? 0) < 0) return false;
    if (recipe.steps.isEmpty) return false;
    if (recipe.ingredients.isEmpty) return false;
    
    return true;
  }

  /// Get recipe difficulty based on prep time and ingredient count
  String getRecipeDifficulty(Recipe recipe) {
    final totalTime = recipe.totalMinutes;
    final ingredientCount = recipe.ingredients.length;
    
    if (totalTime <= 15 && ingredientCount <= 5) {
      return 'easy';
    } else if (totalTime <= 45 && ingredientCount <= 10) {
      return 'medium';
    } else {
      return 'hard';
    }
  }

  /// Calculate estimated cost based on ingredient complexity
  double estimateRecipeCost(Recipe recipe) {
    // Simple heuristic: base cost + time factor + ingredient factor
    final baseCost = 5.0; // Base cost per serving
    final timeFactor = recipe.totalMinutes * 0.1; // $0.10 per minute
    final ingredientFactor = recipe.ingredients.length * 0.5; // $0.50 per ingredient
    
    return (baseCost + timeFactor + ingredientFactor) * (recipe.servingSize ?? 1.0);
  }

  // Compatibility aliases for existing code
  Future<Recipe?> getRecipe(String id) => fetchRecipe(id);
  Future<List<Recipe>> getRecipesByIds(List<String> ids) async {
    final recipes = <Recipe>[];
    for (final id in ids) {
      final recipe = await fetchRecipe(id);
      if (recipe != null) recipes.add(recipe);
    }
    return recipes;
  }
  // findSimilarRecipes is already defined above
}
