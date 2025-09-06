import 'dart:convert';
import 'package:flutter/services.dart';

class ExerciseCatalogService {
  static final ExerciseCatalogService _instance = ExerciseCatalogService._internal();
  factory ExerciseCatalogService() => _instance;
  ExerciseCatalogService._internal();

  // In-memory cache for session
  final Map<String, Map<String, dynamic>> _cache = {};
  Map<String, dynamic>? _catalog;

  /// Loads the exercise catalog from assets
  Future<void> _loadCatalog() async {
    if (_catalog != null) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/exercises/catalog.json');
      _catalog = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // If catalog is missing, create empty structure
      _catalog = {'exercises': []};
    }
  }

  /// Gets exercise data by name (with caching)
  Future<Map<String, dynamic>?> getByName(String name) async {
    await _loadCatalog();
    
    final normalizedName = name.toLowerCase().trim();
    
    // Check cache first
    if (_cache.containsKey(normalizedName)) {
      return _cache[normalizedName];
    }

    // Search in catalog
    final exercises = _catalog?['exercises'] as List<dynamic>? ?? [];
    for (final exercise in exercises) {
      final exerciseMap = exercise as Map<String, dynamic>;
      final exerciseName = (exerciseMap['name'] as String? ?? '').toLowerCase().trim();
      
      if (exerciseName == normalizedName) {
        _cache[normalizedName] = exerciseMap;
        return exerciseMap;
      }
    }

    // Not found
    _cache.remove(normalizedName);
    return null;
  }

  /// Resolves primary muscles for an exercise
  Future<List<String>> resolvePrimary(String name) async {
    final exercise = await getByName(name);
    if (exercise == null) return [];
    
    final primaryMuscles = exercise['primaryMuscles'] as List<dynamic>? ?? [];
    return primaryMuscles.cast<String>();
  }

  /// Resolves secondary muscles for an exercise
  Future<List<String>> resolveSecondary(String name) async {
    final exercise = await getByName(name);
    if (exercise == null) return [];
    
    final secondaryMuscles = exercise['secondaryMuscles'] as List<dynamic>? ?? [];
    return secondaryMuscles.cast<String>();
  }

  /// Resolves media URLs for an exercise (ordered: mp4→gif→image)
  Future<List<String>> resolveMedia(String name) async {
    final exercise = await getByName(name);
    if (exercise == null) return [];
    
    final media = exercise['media'] as List<dynamic>? ?? [];
    return media.cast<String>();
  }

  /// Gets all available exercise names
  Future<List<String>> getAllExerciseNames() async {
    await _loadCatalog();
    
    final exercises = _catalog?['exercises'] as List<dynamic>? ?? [];
    return exercises.map((e) => e['name'] as String).toList();
  }

  /// Gets all unique muscle groups
  Future<List<String>> getAllMuscleGroups() async {
    await _loadCatalog();
    
    final Set<String> muscles = {};
    final exercises = _catalog?['exercises'] as List<dynamic>? ?? [];
    
    for (final exercise in exercises) {
      final exerciseMap = exercise as Map<String, dynamic>;
      
      final primary = exerciseMap['primaryMuscles'] as List<dynamic>? ?? [];
      final secondary = exerciseMap['secondaryMuscles'] as List<dynamic>? ?? [];
      
      muscles.addAll(primary.cast<String>());
      muscles.addAll(secondary.cast<String>());
    }
    
    return muscles.toList()..sort();
  }

  /// Clears the cache (useful for testing or memory management)
  void clearCache() {
    _cache.clear();
  }
}
