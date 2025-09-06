import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../models/nutrition/recipe.dart';
import '../../models/nutrition/food_item.dart' as fi;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'recipe_service.dart';

class NutritionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RecipeService _recipeService = RecipeService();

  /// Fetch all nutrition plans for a specific client
  Future<List<NutritionPlan>> fetchPlansForClient(String clientId) async {
    try {
      final response = await _supabase
          .from('nutrition_plans')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((plan) => NutritionPlan.fromMap(plan as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch nutrition plans: $e');
    }
  }

  /// Fetch a specific nutrition plan by ID
  Future<NutritionPlan?> fetchPlan(String planId) async {
    try {
      final response = await _supabase
          .from('nutrition_plans')
          .select()
          .eq('id', planId)
          .single();

      return NutritionPlan.fromMap(response);
    } catch (e) {
      if (e.toString().contains('No rows found')) {
        return null;
      }
      throw Exception('Failed to fetch nutrition plan: $e');
    }
  }

  /// Create a new nutrition plan
  Future<String> createPlan(NutritionPlan plan) async {
    try {
      final response = await _supabase
          .from('nutrition_plans')
          .insert(plan.toMap())
          .select()
          .single();

      return response['id']?.toString() ?? '';
    } catch (e) {
      throw Exception('Failed to create nutrition plan: $e');
    }
  }

  /// Update an existing nutrition plan
  Future<void> updatePlan(NutritionPlan plan) async {
    if (plan.id == null) {
      throw Exception('Cannot update plan without ID');
    }

    try {
      await _supabase
          .from('nutrition_plans')
          .update(plan.toMap())
          .eq('id', plan.id!);
    } catch (e) {
      throw Exception('Failed to update nutrition plan: $e');
    }
  }

  /// Mark a plan as seen by the client (sets unseenUpdate = false)
  Future<void> markPlanSeen(String planId) async {
    try {
      await _supabase
          .from('nutrition_plans')
          .update({'unseen_update': false})
          .eq('id', planId);
    } catch (e) {
      throw Exception('Failed to mark plan as seen: $e');
    }
  }

  /// Delete a nutrition plan
  Future<void> deletePlan(String planId) async {
    try {
      await _supabase
          .from('nutrition_plans')
          .delete()
          .eq('id', planId);
    } catch (e) {
      throw Exception('Failed to delete nutrition plan: $e');
    }
  }

  /// Fetch plans created by a specific coach
  Future<List<NutritionPlan>> fetchPlansByCoach(String coachId) async {
    try {
      final response = await _supabase
          .from('nutrition_plans')
          .select()
          .eq('created_by', coachId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((plan) => NutritionPlan.fromMap(plan as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch coach plans: $e');
    }
  }

  /// Update client comment for a specific meal
  Future<void> updateMealComment(String planId, int mealIndex, String comment) async {
    try {
      final plan = await fetchPlan(planId);
      if (plan == null) {
        throw Exception('Plan not found');
      }

      if (mealIndex >= plan.meals.length) {
        throw Exception('Invalid meal index');
      }

      final updatedMeals = List<Meal>.from(plan.meals);
      updatedMeals[mealIndex] = updatedMeals[mealIndex].copyWith(clientComment: comment);

      final updatedPlan = plan.copyWith(meals: updatedMeals);
      await updatePlan(updatedPlan);
    } catch (e) {
      throw Exception('Failed to update meal comment: $e');
    }
  }

  /// Export nutrition plan to PDF
  Future<void> exportNutritionPlanToPdf(NutritionPlan plan, String coachName, String clientName) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Nutrition Plan',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('MMM dd, yyyy').format(plan.createdAt),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Plan details
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Plan: ${plan.name}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Client: $clientName'),
                  pw.Text('Coach: $coachName'),
                  pw.Text('Type: ${plan.lengthType.toUpperCase()}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Meals
            ...plan.meals.map((meal) => _buildMealSection(meal)),

            // Daily summary
            pw.SizedBox(height: 20),
            _buildDailySummarySection(plan.dailySummary),

            // Footer
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated by VAGUS App',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Nutrition_Plan_${plan.name.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  /// Duplicate nutrition plan for a different client
  Future<void> duplicateNutritionPlan(NutritionPlan plan, String targetClientId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final duplicatedPlan = NutritionPlan(
        id: null, // New plan, no ID
        clientId: targetClientId,
        name: '${plan.name} (Copy)',
        lengthType: plan.lengthType,
        createdBy: user.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        meals: plan.meals,
        dailySummary: plan.dailySummary,
        aiGenerated: plan.aiGenerated,
        unseenUpdate: true, // Notify the new client
      );

      await createPlan(duplicatedPlan);
    } catch (e) {
      throw Exception('Failed to duplicate plan: $e');
    }
  }

  /// Helper method to build meal section for PDF
  pw.Widget _buildMealSection(Meal meal) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            meal.label,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          // Food items table
          if (meal.items.isNotEmpty) ...[
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Food', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Protein', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Carbs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Fat', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Kcal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                // Food items
                ...meal.items.map((item) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(item.name),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${item.amount.toStringAsFixed(1)}g'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${item.protein.toStringAsFixed(1)}g'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${item.carbs.toStringAsFixed(1)}g'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${item.fat.toStringAsFixed(1)}g'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(item.kcal.toStringAsFixed(0)),
                    ),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 10),

            // Meal summary
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green200),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Protein: ${meal.mealSummary.totalProtein.toStringAsFixed(1)}g'),
                  pw.Text('Carbs: ${meal.mealSummary.totalCarbs.toStringAsFixed(1)}g'),
                  pw.Text('Fat: ${meal.mealSummary.totalFat.toStringAsFixed(1)}g'),
                  pw.Text('Calories: ${meal.mealSummary.totalKcal.toStringAsFixed(0)} kcal'),
                ],
              ),
            ),
          ] else ...[
            pw.Text(
              'No food items added',
              style: pw.TextStyle(
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Helper method to build daily summary section for PDF
  pw.Widget _buildDailySummarySection(DailySummary summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Daily Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(
                children: [
                  pw.Text('Protein', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(
                    '${summary.totalProtein.toStringAsFixed(1)}g',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Carbs', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(
                    '${summary.totalCarbs.toStringAsFixed(1)}g',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Fat', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(
                    '${summary.totalFat.toStringAsFixed(1)}g',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Calories', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(
                    summary.totalKcal.toStringAsFixed(0),
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // RECIPE INTEGRATION METHODS
  // ========================================

  /// Create a FoodItem from a recipe with specified servings
  Future<FoodItem> createFoodItemFromRecipe(String recipeId, double servings) async {
    try {
      final recipe = await _recipeService.fetchRecipe(recipeId);
      if (recipe == null) {
        throw Exception('Recipe not found');
      }

      // Calculate nutrition per serving
      final nutritionPerServing = _calculateNutritionPerServing(recipe);
      
      // Scale by servings
      final scaledNutrition = _scaleNutrition(nutritionPerServing, servings);

      return FoodItem(
        name: recipe.title,
        amount: (recipe.servingSize ?? 1.0) * servings,
        protein: scaledNutrition['protein']!,
        carbs: scaledNutrition['carbs']!,
        fat: scaledNutrition['fat']!,
        kcal: scaledNutrition['kcal']!,
        sodium: scaledNutrition['sodium']!,
        potassium: scaledNutrition['potassium']!,
        recipeId: recipeId,
        servings: servings,
      );
    } catch (e) {
      throw Exception('Failed to create food item from recipe: $e');
    }
  }

  /// Calculate nutrition per serving for a recipe
  Map<String, double> _calculateNutritionPerServing(Recipe recipe) {
    final servingSize = recipe.servingSize ?? 1.0;
    return {
      'protein': recipe.protein / servingSize,
      'carbs': recipe.carbs / servingSize,
      'fat': recipe.fat / servingSize,
      'kcal': recipe.calories / servingSize,
      'sodium': recipe.sodiumMg / servingSize,
      'potassium': recipe.potassiumMg / servingSize,
    };
  }

  /// Scale nutrition values by servings
  Map<String, double> _scaleNutrition(Map<String, double> nutritionPerServing, double servings) {
    return {
      'protein': nutritionPerServing['protein']! * servings,
      'carbs': nutritionPerServing['carbs']! * servings,
      'fat': nutritionPerServing['fat']! * servings,
      'kcal': nutritionPerServing['kcal']! * servings,
      'sodium': nutritionPerServing['sodium']! * servings,
      'potassium': nutritionPerServing['potassium']! * servings,
    };
  }

  /// Update a FoodItem's servings and recalculate nutrition
  Future<FoodItem> updateRecipeServings(FoodItem item, double newServings) async {
    if (item.recipeId == null) {
      throw Exception('Cannot update servings for non-recipe item');
    }

    try {
      final recipe = await _recipeService.fetchRecipe(item.recipeId!);
      if (recipe == null) {
        throw Exception('Recipe not found');
      }

      // Calculate nutrition per serving
      final nutritionPerServing = _calculateNutritionPerServing(recipe);
      
      // Scale by new servings
      final scaledNutrition = _scaleNutrition(nutritionPerServing, newServings);

      return item.copyWith(
        servings: newServings,
        amount: (recipe.servingSize ?? 1.0) * newServings,
        protein: scaledNutrition['protein']!,
        carbs: scaledNutrition['carbs']!,
        fat: scaledNutrition['fat']!,
        kcal: scaledNutrition['kcal']!,
        sodium: scaledNutrition['sodium']!,
        potassium: scaledNutrition['potassium']!,
      );
    } catch (e) {
      throw Exception('Failed to update recipe servings: $e');
    }
  }

  /// Get recipe details for a FoodItem
  Future<Recipe?> getRecipeForFoodItem(FoodItem item) async {
    if (item.recipeId == null) return null;
    
    try {
      return await _recipeService.fetchRecipe(item.recipeId!);
    } catch (e) {
      return null;
    }
  }

  /// Check if a FoodItem is a recipe-based item
  bool isRecipeItem(FoodItem item) {
    return item.recipeId != null;
  }

  /// Get recipe photo URL for a FoodItem
  Future<String?> getRecipePhotoUrl(FoodItem item) async {
    if (item.recipeId == null) return null;
    
    try {
      final recipe = await _recipeService.fetchRecipe(item.recipeId!);
      if (recipe?.photoUrl == null || (recipe!.photoUrl?.isEmpty ?? true)) return null;
      
      return await _recipeService.getRecipePhotoUrl(recipe.photoUrl ?? '');
    } catch (e) {
      return null;
    }
  }

  // Compatibility alias for existing code
  Future<void> addItemToMeal({required String mealId, required fi.FoodItem item}) async {
    // Implementation would depend on your meal structure
    // For now, just a placeholder
    print('Adding item ${item.name} to meal $mealId');
  }
}
