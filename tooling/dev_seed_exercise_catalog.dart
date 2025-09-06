import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Dev tool for exercise catalog statistics
/// Run with: dart tooling/dev_seed_exercise_catalog.dart
Future<void> main() async {
  await printCatalogStats();
}

/// Prints catalog statistics including count and common muscle groups
Future<void> printCatalogStats() async {
  try {
    // Load the catalog JSON
    final String jsonString = await rootBundle.loadString('assets/exercises/catalog.json');
    final Map<String, dynamic> catalog = json.decode(jsonString);
    
    final List<dynamic> exercises = catalog['exercises'] as List<dynamic>? ?? [];
    
    print('📊 Exercise Catalog Statistics');
    print('=' * 40);
    print('Total exercises: ${exercises.length}');
    print('');
    
    // Count muscle groups
    final Map<String, int> muscleCounts = {};
    final Set<String> allMuscles = {};
    
    for (final exercise in exercises) {
      final exerciseMap = exercise as Map<String, dynamic>;
      
      final primary = (exerciseMap['primaryMuscles'] as List<dynamic>? ?? []).cast<String>();
      final secondary = (exerciseMap['secondaryMuscles'] as List<dynamic>? ?? []).cast<String>();
      
      for (final muscle in [...primary, ...secondary]) {
        muscleCounts[muscle] = (muscleCounts[muscle] ?? 0) + 1;
        allMuscles.add(muscle);
      }
    }
    
    // Sort muscles by frequency
    final sortedMuscles = muscleCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    print('Muscle groups (${allMuscles.length} unique):');
    for (final entry in sortedMuscles) {
      print('  ${entry.key}: ${entry.value} exercises');
    }
    
    print('');
    print('Exercise list:');
    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i] as Map<String, dynamic>;
      final name = exercise['name'] as String? ?? 'Unknown';
      final primary = (exercise['primaryMuscles'] as List<dynamic>? ?? []).cast<String>();
      final secondary = (exercise['secondaryMuscles'] as List<dynamic>? ?? []).cast<String>();
      final mediaCount = (exercise['media'] as List<dynamic>? ?? []).length;
      
      print('  ${i + 1}. $name');
      print('     Primary: ${primary.join(', ')}');
      print('     Secondary: ${secondary.join(', ')}');
      print('     Media files: $mediaCount');
      print('');
    }
    
  } catch (e) {
    print('❌ Error loading catalog: $e');
    print('Make sure assets/exercises/catalog.json exists and is valid JSON.');
  }
}
