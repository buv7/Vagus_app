import 'dart:io';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../models/nutrition/grocery_list.dart';
import '../../models/nutrition/grocery_item.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../models/nutrition/recipe.dart';
import 'recipe_service.dart';
import 'nutrition_service.dart';
import 'text_normalizer.dart';

class GroceryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RecipeService _recipeService = RecipeService();
  final NutritionService _nutritionService = NutritionService();

  // ========================================
  // GROCERY LIST GENERATION
  // ========================================

  /// Generate grocery list for a specific plan week
  Future<GroceryList> generateForPlanWeek({
    required String planId,
    required int weekIndex,
    required String ownerId,
    String? coachId,
  }) async {
    try {
      // Get the nutrition plan
      final plan = await _nutritionService.fetchPlan(planId);
      if (plan == null) {
        throw Exception('Nutrition plan not found');
      }

      // Create grocery list
      final response = await _supabase.rpc('generate_grocery_list_for_week', params: {
        'plan_uuid': planId,
        'week_number': weekIndex,
        'owner_uuid': ownerId,
        'coach_uuid': coachId,
      });

      final groceryListId = response.toString();
      
      // Generate items from plan meals
      await _generateItemsFromPlan(groceryListId, plan, weekIndex);

      // Fetch and return the created list
      final listResponse = await _supabase
          .from('nutrition_grocery_lists')
          .select()
          .eq('id', groceryListId)
          .single();

      return GroceryList.fromMap(listResponse);
    } catch (e) {
      throw Exception('Failed to generate grocery list: $e');
    }
  }

  /// Generate grocery items from nutrition plan
  Future<void> _generateItemsFromPlan(String listId, NutritionPlan plan, int weekIndex) async {
    final Map<String, GroceryItem> itemMap = {};

    // Process each meal in the plan
    for (final meal in plan.meals) {
      for (final item in meal.items) {
        if (item.recipeId != null) {
          // Handle recipe items
          await _processRecipeItem(listId, item, itemMap);
        } else {
          // Handle regular food items
          _processFoodItem(listId, item, itemMap);
        }
      }
    }

    // Insert all items into database
    if (itemMap.isNotEmpty) {
      final itemsData = itemMap.values.map((item) => item.toMap()).toList();
      await _supabase
          .from('nutrition_grocery_items')
          .insert(itemsData);
    }
  }

  /// Process recipe item and extract ingredients
  Future<void> _processRecipeItem(String listId, FoodItem item, Map<String, GroceryItem> itemMap) async {
    try {
      final recipe = await _recipeService.fetchRecipe(item.recipeId!);
      if (recipe == null) return;

      // Scale ingredients by servings
      final scaleFactor = item.servings / (recipe.servingSize ?? 1.0);

      for (final ingredient in recipe.ingredients) {
        final scaledAmount = ingredient.amount * scaleFactor;
        final normalizedAmount = _normalizeAmount(scaledAmount, ingredient.unit);
        final canonicalName = _normalizeItemName(ingredient.name);
        final aisle = _assignAisle(ingredient.name);

        final key = '${canonicalName}_${normalizedAmount.unit}';
        
        if (itemMap.containsKey(key)) {
          // Merge with existing item
          final existing = itemMap[key]!;
          itemMap[key] = existing.copyWith(
            amount: (existing.amount ?? 0) + normalizedAmount.amount,
          );
        } else {
          // Create new item
          final now = DateTime.now();
          itemMap[key] = GroceryItem(
            id: const Uuid().v4(),
            listId: listId,
            name: ingredient.name,
            canonicalKey: TextNormalizer.canonicalKey(ingredient.name),
            amount: normalizedAmount.amount,
            unit: normalizedAmount.unit,
            aisle: aisle,
            checked: false,
            notes: 'From recipe: ${recipe.title}',
            createdAt: now,
            updatedAt: now,
          );
        }
      }
    } catch (e) {
      // If recipe processing fails, treat as regular food item
      _processFoodItem(listId, item, itemMap);
    }
  }

  /// Process regular food item
  void _processFoodItem(String listId, FoodItem item, Map<String, GroceryItem> itemMap) {
    final normalizedAmount = _normalizeAmount(item.amount, 'g');
    final canonicalName = _normalizeItemName(item.name);
    final aisle = _assignAisle(item.name);

    final key = '${canonicalName}_${normalizedAmount.unit}';
    
    if (itemMap.containsKey(key)) {
      // Merge with existing item
      final existing = itemMap[key]!;
      itemMap[key] = existing.copyWith(
        amount: (existing.amount ?? 0) + normalizedAmount.amount,
      );
    } else {
      // Create new item
      final now = DateTime.now();
      itemMap[key] = GroceryItem(
        id: const Uuid().v4(),
        listId: listId,
        name: item.name,
        canonicalKey: TextNormalizer.canonicalKey(item.name),
        amount: normalizedAmount.amount,
        unit: normalizedAmount.unit,
        aisle: aisle,
        checked: false,
        notes: null,
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  // ========================================
  // UNIT NORMALIZATION
  // ========================================

  /// Normalize amount and unit to base units
  ({double amount, String unit}) _normalizeAmount(double amount, String unit) {
    final unitLower = unit.toLowerCase().trim();
    
    switch (unitLower) {
      // Weight conversions (to grams)
      case 'kg':
      case 'kilogram':
      case 'kilograms':
        return (amount: amount * 1000, unit: 'g');
      case 'lb':
      case 'pound':
      case 'pounds':
        return (amount: amount * 453.592, unit: 'g');
      case 'oz':
      case 'ounce':
      case 'ounces':
        return (amount: amount * 28.3495, unit: 'g');
      
      // Volume conversions (to ml)
      case 'l':
      case 'liter':
      case 'liters':
      case 'litre':
      case 'litres':
        return (amount: amount * 1000, unit: 'ml');
      case 'cup':
      case 'cups':
        return (amount: amount * 240, unit: 'ml');
      case 'tbsp':
      case 'tablespoon':
      case 'tablespoons':
        return (amount: amount * 15, unit: 'ml');
      case 'tsp':
      case 'teaspoon':
      case 'teaspoons':
        return (amount: amount * 5, unit: 'ml');
      case 'fl oz':
      case 'fluid ounce':
      case 'fluid ounces':
        return (amount: amount * 29.5735, unit: 'ml');
      
      // Count items (keep as pieces)
      case 'pcs':
      case 'piece':
      case 'pieces':
      case 'item':
      case 'items':
        return (amount: amount, unit: 'pcs');
      
      // Default to original
      default:
        return (amount: amount, unit: unit);
    }
  }

  /// Normalize item name for deduplication
  String _normalizeItemName(String name) {
    return name.toLowerCase().trim();
  }

  // ========================================
  // AISLE CLASSIFICATION
  // ========================================

  /// Assign aisle based on item name keywords
  String _assignAisle(String name) {
    final nameLower = name.toLowerCase();
    
    // Produce
    if (_containsAny(nameLower, ['apple', 'banana', 'orange', 'lettuce', 'tomato', 'onion', 'carrot', 'potato', 'vegetable', 'fruit', 'herb', 'spinach', 'cucumber', 'pepper', 'garlic', 'ginger', 'lemon', 'lime'])) {
      return 'produce';
    }
    
    // Meat
    if (_containsAny(nameLower, ['chicken', 'beef', 'pork', 'lamb', 'turkey', 'fish', 'salmon', 'tuna', 'meat', 'sausage', 'bacon', 'ham', 'steak', 'ground'])) {
      return 'meat';
    }
    
    // Dairy
    if (_containsAny(nameLower, ['milk', 'cheese', 'yogurt', 'butter', 'cream', 'dairy', 'egg', 'eggs', 'mozzarella', 'cheddar', 'parmesan', 'ricotta'])) {
      return 'dairy';
    }
    
    // Bakery
    if (_containsAny(nameLower, ['bread', 'roll', 'bagel', 'croissant', 'muffin', 'cake', 'cookie', 'pastry', 'dough', 'flour', 'yeast'])) {
      return 'bakery';
    }
    
    // Frozen
    if (_containsAny(nameLower, ['frozen', 'ice cream', 'frozen vegetable', 'frozen fruit', 'frozen meat'])) {
      return 'frozen';
    }
    
    // Canned
    if (_containsAny(nameLower, ['canned', 'can', 'jar', 'preserved', 'pickled'])) {
      return 'canned';
    }
    
    // Grains
    if (_containsAny(nameLower, ['rice', 'pasta', 'noodle', 'quinoa', 'barley', 'oats', 'cereal', 'grain', 'wheat', 'breadcrumb'])) {
      return 'grains';
    }
    
    // Spices
    if (_containsAny(nameLower, ['salt', 'pepper', 'spice', 'herb', 'seasoning', 'cumin', 'paprika', 'oregano', 'basil', 'thyme', 'rosemary', 'cinnamon', 'nutmeg', 'vanilla', 'sugar', 'honey', 'syrup'])) {
      return 'spices';
    }
    
    // Beverages
    if (_containsAny(nameLower, ['juice', 'soda', 'water', 'coffee', 'tea', 'wine', 'beer', 'drink', 'beverage', 'smoothie'])) {
      return 'beverages';
    }
    
    // Snacks
    if (_containsAny(nameLower, ['chip', 'cracker', 'nut', 'almond', 'walnut', 'peanut', 'snack', 'candy', 'chocolate', 'popcorn'])) {
      return 'snacks';
    }
    
    return 'other';
  }

  /// Helper to check if string contains any of the keywords
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  // ========================================
  // GROCERY LIST MANAGEMENT
  // ========================================

  /// Get items for a grocery list
  Future<List<GroceryItem>> getItems(String listId) async {
    try {
      final response = await _supabase
          .from('nutrition_grocery_items')
          .select()
          .eq('list_id', listId)
          .order('aisle')
          .order('name');

      return (response as List<dynamic>)
          .map((item) => GroceryItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch grocery items: $e');
    }
  }

  /// Toggle checked status of an item
  Future<void> toggleChecked({required String itemId, required bool value}) async {
    try {
      await _supabase
          .from('nutrition_grocery_items')
          .update({'is_checked': value})
          .eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to toggle item checked status: $e');
    }
  }

  /// Delete a grocery list
  Future<void> deleteList(String listId) async {
    try {
      await _supabase
          .from('nutrition_grocery_lists')
          .delete()
          .eq('id', listId);
    } catch (e) {
      throw Exception('Failed to delete grocery list: $e');
    }
  }

  // ========================================
  // EXPORT FUNCTIONALITY
  // ========================================

  /// Export grocery list to CSV
  Future<String> exportCsv(String listId) async {
    try {
      final items = await getItems(listId);
      final list = await _getGroceryList(listId);
      
      final csvContent = _generateCsvContent(items, list);
      final fileName = 'grocery_list_week_${list.weekIndex}_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      return await _saveFile(csvContent, fileName);
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  /// Export grocery list to PDF
  Future<String> exportPdf(String listId) async {
    try {
      final items = await getItems(listId);
      final list = await _getGroceryList(listId);
      
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildPdfContent(items, list),
        ),
      );
      
      final fileName = 'grocery_list_week_${list.weekIndex}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfBytes = await pdf.save();
      
      return await _saveFile(pdfBytes, fileName);
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  /// Get grocery list details
  Future<GroceryList> _getGroceryList(String listId) async {
    try {
      final response = await _supabase
          .from('nutrition_grocery_lists')
          .select()
          .eq('id', listId)
          .single();

      return GroceryList.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch grocery list: $e');
    }
  }

  /// Generate CSV content
  String _generateCsvContent(List<GroceryItem> items, GroceryList list) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Name,Amount,Unit,Aisle,Notes,Checked');
    
    // Items grouped by aisle
    final itemsByAisle = <String, List<GroceryItem>>{};
    for (final item in items) {
      final aisle = item.aisle ?? 'other';
      itemsByAisle.putIfAbsent(aisle, () => []).add(item);
    }
    
    // Write items by aisle
    for (final aisle in itemsByAisle.keys.toList()..sort()) {
      for (final item in itemsByAisle[aisle]!) {
        buffer.writeln('${_escapeCsv(item.name)},${item.amount ?? ''},${item.unit ?? ''},${item.aisle ?? ''},${_escapeCsv(item.notes ?? '')},${item.isChecked ? 'Yes' : 'No'}');
      }
    }
    
    return buffer.toString();
  }

  /// Escape CSV field
  String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Build PDF content
  List<pw.Widget> _buildPdfContent(List<GroceryItem> items, GroceryList list) {
    final itemsByAisle = <String, List<GroceryItem>>{};
    for (final item in items) {
      final aisle = item.aisle ?? 'other';
      itemsByAisle.putIfAbsent(aisle, () => []).add(item);
    }

    return [
      // Header
      pw.Header(
        level: 0,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Grocery List - Week ${list.weekIndex}',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Generated: ${DateTime.now().toString().split('.')[0]}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
      
      pw.SizedBox(height: 20),
      
      // Items by aisle
      ...(itemsByAisle.keys.toList()..sort()).map((aisle) {
        final aisleItems = itemsByAisle[aisle]!;
        final checkedCount = aisleItems.where((item) => item.isChecked).length;
        
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Aisle header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                '${aisle.toUpperCase()} (${checkedCount}/${aisleItems.length} checked)',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            
            pw.SizedBox(height: 8),
            
            // Items
            ...aisleItems.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 12,
                    height: 12,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black),
                      color: item.isChecked ? PdfColors.green : PdfColors.white,
                    ),
                    child: item.isChecked 
                        ? pw.Center(
                            child: pw.Text(
                              '✓',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          )
                        : null,
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(
                      item.name,
                      style: pw.TextStyle(
                        decoration: item.isChecked ? pw.TextDecoration.lineThrough : null,
                        color: item.isChecked ? PdfColors.grey : PdfColors.black,
                      ),
                    ),
                  ),
                  if (item.amount != null && item.unit != null)
                    pw.Text(
                      '${item.amount!.toStringAsFixed(1)} ${item.unit}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
            )),
            
            pw.SizedBox(height: 16),
          ],
        );
      }),
    ];
  }

  /// Save file to device storage
  Future<String> _saveFile(dynamic content, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      
      if (content is String) {
        await file.writeAsString(content);
      } else if (content is List<int>) {
        await file.writeAsBytes(content);
      } else {
        throw Exception('Unsupported content type');
      }
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }
}
