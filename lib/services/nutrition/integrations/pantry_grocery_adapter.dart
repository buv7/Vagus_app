import 'package:flutter/foundation.dart';
import '../pantry_service.dart';
import '../grocery_service.dart';
import 'package:vagus_app/models/nutrition/grocery_list.dart';
import 'package:vagus_app/services/nutrition/pantry_service.dart' as ps;
typedef PantrySummary = ps.PantrySummary;

// PantrySummary is now aliased to ps.PantrySummary above

/// Non-invasive adapter for pantry-aware grocery generation
class PantryGroceryAdapter {
  final PantryService _pantry;
  final GroceryService _grocery;
  
  PantryGroceryAdapter(this._pantry, this._grocery);

  /// Non-invasive wrapper that first computes pantry coverage and then calls the existing grocery generation,
  /// returning the original GroceryList alongside a PantrySummary.
  Future<(GroceryList, PantrySummary?)> generateWithPantry({
    required String planId,
    required int weekIndex,
    required String ownerId,
    String? coachId,
    bool usePantry = true,
  }) async {
    try {
      // Call existing grocery generation as-is
      final list = await _grocery.generateForPlanWeek(
        planId: planId,
        weekIndex: weekIndex,
        ownerId: ownerId,
        coachId: coachId,
      );
      
      if (!usePantry) {
        return (list, null);
      }
      
      // Compute lightweight summary by sampling top items vs pantry
      final pantryItems = await _pantry.list(ownerId);
      final groceryItems = await _grocery.getItems(list.id);
      
      int covered = 0;
      final coveredIngredients = <String>[];
      
      for (final groceryItem in groceryItems) {
        // Simple name matching (could be enhanced with fuzzy matching)
        final hit = pantryItems.any((pantryItem) {
          final pantryName = pantryItem.name.toLowerCase().trim();
          final groceryName = groceryItem.name.toLowerCase().trim();
          
          // Check for exact match or contains match
          return pantryName == groceryName || 
                 pantryName.contains(groceryName) || 
                 groceryName.contains(pantryName);
        });
        
        if (hit) {
          covered++;
          coveredIngredients.add(groceryItem.name);
        }
      }
      
      final summary = PantrySummary(
        coveragePercent: groceryItems.isEmpty ? 0.0 : (covered / groceryItems.length) * 100.0,
        itemsCovered: covered,
        coveredIngredients: coveredIngredients,
      );
      
      return (list, summary);
    } catch (e) {
      debugPrint('Failed to generate grocery list with pantry: $e');
      // Fallback to regular generation
      final list = await _grocery.generateForPlanWeek(
        planId: planId,
        weekIndex: weekIndex,
        ownerId: ownerId,
        coachId: coachId,
      );
      return (list, null);
    }
  }

  /// Get pantry coverage for a specific grocery list
  Future<PantrySummary> getPantryCoverage({
    required String listId,
    required String userId,
  }) async {
    try {
      final pantryItems = await _pantry.list(userId);
      final groceryItems = await _grocery.getItems(listId);
      
      int covered = 0;
      final coveredIngredients = <String>[];
      
      for (final groceryItem in groceryItems) {
        final hit = pantryItems.any((pantryItem) {
          final pantryName = pantryItem.name.toLowerCase().trim();
          final groceryName = groceryItem.name.toLowerCase().trim();
          
          return pantryName == groceryName || 
                 pantryName.contains(groceryName) || 
                 groceryName.contains(pantryName);
        });
        
        if (hit) {
          covered++;
          coveredIngredients.add(groceryItem.name);
        }
      }
      
      return PantrySummary(
        coveragePercent: groceryItems.isEmpty ? 0.0 : (covered / groceryItems.length) * 100.0,
        itemsCovered: covered,
        coveredIngredients: coveredIngredients,
      );
    } catch (e) {
      debugPrint('Failed to get pantry coverage: $e');
      return const PantrySummary(
        coveragePercent: 0.0,
        itemsCovered: 0,
        coveredIngredients: [],
      );
    }
  }
}
