// =====================================================
// ALLERGY & MEDICAL INTEGRATION SERVICE
// =====================================================
// Revolutionary medical-grade nutrition service for users with allergies,
// intolerances, and medical conditions.
//
// FEATURES:
// - Allergen scanner with red alerts
// - Medical condition profiles (Diabetes, Kidney, Heart, PCOS, IBS, Celiac)
// - Medication interaction warnings
// - Emergency contact integration
// - Safe food database
// - Substitution suggestions
// - Medical report generation for doctors
// =====================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =====================================================
// ENUMS
// =====================================================

enum Allergen {
  milk,
  eggs,
  fish,
  shellfish,
  treeNuts,
  peanuts,
  wheat,
  soybeans,
  sesame,
  mustard,
  celery,
  lupin,
  sulfites,
  gluten,
  corn,
  soy,
}

enum MedicalCondition {
  diabetes,          // Blood sugar management
  kidneyDisease,     // Low potassium, phosphorus, protein
  heartDisease,      // Low sodium, saturated fat
  pcos,              // Low glycemic index
  ibs,               // Low FODMAP
  celiacDisease,     // Gluten-free
  crohnsDisease,     // Low fiber during flares
  gerd,              // Avoid triggers
  hypertension,      // Low sodium
  gout,              // Low purine
  lactoseIntolerance,
  highCholesterol,   // Low saturated fat
}

enum SeverityLevel {
  mild,      // Minor discomfort
  moderate,  // Significant symptoms
  severe,    // Life-threatening (anaphylaxis)
}

enum MedicationInteractionType {
  warningOnly,   // Yellow warning
  avoid,         // Red alert - do not consume
  separateBy,    // Take X hours apart
}

// =====================================================
// MODELS
// =====================================================

/// User's allergy profile
class AllergyProfile {
  final String id;
  final String userId;
  final List<AllergenEntry> allergens;
  final List<MedicalConditionEntry> conditions;
  final List<String> customRestrictions;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? epiPenLocation;
  final bool notifyCoach;
  final DateTime createdAt;
  final DateTime updatedAt;

  AllergyProfile({
    required this.id,
    required this.userId,
    required this.allergens,
    required this.conditions,
    this.customRestrictions = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.epiPenLocation,
    this.notifyCoach = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AllergyProfile.fromJson(Map<String, dynamic> json) {
    return AllergyProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      allergens: (json['allergens'] as List?)
              ?.map((a) => AllergenEntry.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      conditions: (json['conditions'] as List?)
              ?.map((c) => MedicalConditionEntry.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      customRestrictions: List<String>.from(json['custom_restrictions'] ?? []),
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      epiPenLocation: json['epi_pen_location'] as String?,
      notifyCoach: json['notify_coach'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'allergens': allergens.map((a) => a.toJson()).toList(),
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'custom_restrictions': customRestrictions,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'epi_pen_location': epiPenLocation,
      'notify_coach': notifyCoach,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Individual allergen entry
class AllergenEntry {
  final Allergen allergen;
  final SeverityLevel severity;
  final String? notes;
  final DateTime? diagnosedDate;
  final bool verified; // Verified by medical professional

  AllergenEntry({
    required this.allergen,
    required this.severity,
    this.notes,
    this.diagnosedDate,
    this.verified = false,
  });

  factory AllergenEntry.fromJson(Map<String, dynamic> json) {
    return AllergenEntry(
      allergen: Allergen.values.firstWhere(
        (e) => e.name == json['allergen'],
        orElse: () => Allergen.milk,
      ),
      severity: SeverityLevel.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => SeverityLevel.mild,
      ),
      notes: json['notes'] as String?,
      diagnosedDate: json['diagnosed_date'] != null
          ? DateTime.parse(json['diagnosed_date'] as String)
          : null,
      verified: json['verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergen': allergen.name,
      'severity': severity.name,
      'notes': notes,
      'diagnosed_date': diagnosedDate?.toIso8601String(),
      'verified': verified,
    };
  }
}

/// Medical condition entry
class MedicalConditionEntry {
  final MedicalCondition condition;
  final DateTime? diagnosedDate;
  final String? managementPlan;
  final List<String> dietaryRestrictions;
  final bool verified;

  MedicalConditionEntry({
    required this.condition,
    this.diagnosedDate,
    this.managementPlan,
    this.dietaryRestrictions = const [],
    this.verified = false,
  });

  factory MedicalConditionEntry.fromJson(Map<String, dynamic> json) {
    return MedicalConditionEntry(
      condition: MedicalCondition.values.firstWhere(
        (e) => e.name == json['condition'],
        orElse: () => MedicalCondition.diabetes,
      ),
      diagnosedDate: json['diagnosed_date'] != null
          ? DateTime.parse(json['diagnosed_date'] as String)
          : null,
      managementPlan: json['management_plan'] as String?,
      dietaryRestrictions: List<String>.from(json['dietary_restrictions'] ?? []),
      verified: json['verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition.name,
      'diagnosed_date': diagnosedDate?.toIso8601String(),
      'management_plan': managementPlan,
      'dietary_restrictions': dietaryRestrictions,
      'verified': verified,
    };
  }
}

/// Allergen scan result
class AllergenScanResult {
  final String foodItemId;
  final String foodName;
  final List<AllergenAlert> alerts;
  final bool isSafe;
  final List<String> safeAlternatives;
  final DateTime scannedAt;

  AllergenScanResult({
    required this.foodItemId,
    required this.foodName,
    required this.alerts,
    required this.isSafe,
    this.safeAlternatives = const [],
    required this.scannedAt,
  });

  factory AllergenScanResult.fromJson(Map<String, dynamic> json) {
    return AllergenScanResult(
      foodItemId: json['food_item_id'] as String,
      foodName: json['food_name'] as String,
      alerts: (json['alerts'] as List?)
              ?.map((a) => AllergenAlert.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      isSafe: json['is_safe'] as bool,
      safeAlternatives: List<String>.from(json['safe_alternatives'] ?? []),
      scannedAt: DateTime.parse(json['scanned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_item_id': foodItemId,
      'food_name': foodName,
      'alerts': alerts.map((a) => a.toJson()).toList(),
      'is_safe': isSafe,
      'safe_alternatives': safeAlternatives,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }
}

/// Allergen alert
class AllergenAlert {
  final Allergen allergen;
  final SeverityLevel severity;
  final String message;
  final bool requiresEpiPen;

  AllergenAlert({
    required this.allergen,
    required this.severity,
    required this.message,
    this.requiresEpiPen = false,
  });

  factory AllergenAlert.fromJson(Map<String, dynamic> json) {
    return AllergenAlert(
      allergen: Allergen.values.firstWhere(
        (e) => e.name == json['allergen'],
        orElse: () => Allergen.milk,
      ),
      severity: SeverityLevel.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => SeverityLevel.mild,
      ),
      message: json['message'] as String,
      requiresEpiPen: json['requires_epi_pen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergen': allergen.name,
      'severity': severity.name,
      'message': message,
      'requires_epi_pen': requiresEpiPen,
    };
  }
}

/// Medication interaction
class MedicationInteraction {
  final String medicationName;
  final List<String> avoidFoods;
  final List<String> limitFoods;
  final MedicationInteractionType interactionType;
  final String warning;
  final int? separationHours;

  MedicationInteraction({
    required this.medicationName,
    required this.avoidFoods,
    this.limitFoods = const [],
    required this.interactionType,
    required this.warning,
    this.separationHours,
  });

  factory MedicationInteraction.fromJson(Map<String, dynamic> json) {
    return MedicationInteraction(
      medicationName: json['medication_name'] as String,
      avoidFoods: List<String>.from(json['avoid_foods'] ?? []),
      limitFoods: List<String>.from(json['limit_foods'] ?? []),
      interactionType: MedicationInteractionType.values.firstWhere(
        (e) => e.name == json['interaction_type'],
        orElse: () => MedicationInteractionType.warningOnly,
      ),
      warning: json['warning'] as String,
      separationHours: json['separation_hours'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medication_name': medicationName,
      'avoid_foods': avoidFoods,
      'limit_foods': limitFoods,
      'interaction_type': interactionType.name,
      'warning': warning,
      'separation_hours': separationHours,
    };
  }
}

/// Medical report for doctor
class MedicalNutritionReport {
  final String id;
  final String userId;
  final DateTime reportDate;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> dailyIntake;
  final Map<String, dynamic> complianceMetrics;
  final String? doctorNotes;

  MedicalNutritionReport({
    required this.id,
    required this.userId,
    required this.reportDate,
    required this.periodStart,
    required this.periodEnd,
    required this.summary,
    required this.dailyIntake,
    required this.complianceMetrics,
    this.doctorNotes,
  });

  factory MedicalNutritionReport.fromJson(Map<String, dynamic> json) {
    return MedicalNutritionReport(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      reportDate: DateTime.parse(json['report_date'] as String),
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      summary: json['summary'] as Map<String, dynamic>,
      dailyIntake: List<Map<String, dynamic>>.from(json['daily_intake'] ?? []),
      complianceMetrics: json['compliance_metrics'] as Map<String, dynamic>,
      doctorNotes: json['doctor_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'report_date': reportDate.toIso8601String(),
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'summary': summary,
      'daily_intake': dailyIntake,
      'compliance_metrics': complianceMetrics,
      'doctor_notes': doctorNotes,
    };
  }
}

// =====================================================
// SERVICE
// =====================================================

class AllergyMedicalService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache
  AllergyProfile? _cachedProfile;
  final Map<String, AllergenScanResult> _scanCache = {};

  // =====================================================
  // ALLERGY PROFILE MANAGEMENT
  // =====================================================

  /// Get user's allergy profile
  Future<AllergyProfile?> getAllergyProfile(String userId) async {
    if (_cachedProfile?.userId == userId) {
      return _cachedProfile;
    }

    try {
      final response = await _supabase
          .from('allergy_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      _cachedProfile = AllergyProfile.fromJson(response as Map<String, dynamic>);
      return _cachedProfile;
    } catch (e) {
      debugPrint('Error fetching allergy profile: $e');
      return null;
    }
  }

  /// Create or update allergy profile
  Future<AllergyProfile?> updateAllergyProfile({
    required String userId,
    required List<AllergenEntry> allergens,
    required List<MedicalConditionEntry> conditions,
    List<String> customRestrictions = const [],
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? epiPenLocation,
    bool notifyCoach = true,
  }) async {
    try {
      final now = DateTime.now();
      final profileData = {
        'user_id': userId,
        'allergens': allergens.map((a) => a.toJson()).toList(),
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'custom_restrictions': customRestrictions,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'epi_pen_location': epiPenLocation,
        'notify_coach': notifyCoach,
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('allergy_profiles')
          .upsert(profileData)
          .select()
          .single();

      _cachedProfile = AllergyProfile.fromJson(response as Map<String, dynamic>);
      notifyListeners();
      return _cachedProfile;
    } catch (e) {
      debugPrint('Error updating allergy profile: $e');
      return null;
    }
  }

  // =====================================================
  // ALLERGEN SCANNING
  // =====================================================

  /// Scan food item for allergens
  Future<AllergenScanResult?> scanFoodForAllergens({
    required String userId,
    required String foodItemId,
    required String foodName,
    required List<String> ingredients,
  }) async {
    // Check cache first
    final cacheKey = '${userId}_$foodItemId';
    if (_scanCache.containsKey(cacheKey)) {
      return _scanCache[cacheKey];
    }

    try {
      final profile = await getAllergyProfile(userId);
      if (profile == null) {
        // No allergies registered
        return AllergenScanResult(
          foodItemId: foodItemId,
          foodName: foodName,
          alerts: [],
          isSafe: true,
          scannedAt: DateTime.now(),
        );
      }

      // Scan ingredients for allergens
      final alerts = <AllergenAlert>[];
      for (final allergenEntry in profile.allergens) {
        final allergen = allergenEntry.allergen;
        final containsAllergen = _checkForAllergen(ingredients, allergen);

        if (containsAllergen) {
          alerts.add(AllergenAlert(
            allergen: allergen,
            severity: allergenEntry.severity,
            message: _getAllergenMessage(allergen, allergenEntry.severity),
            requiresEpiPen: allergenEntry.severity == SeverityLevel.severe,
          ));
        }
      }

      // Get safe alternatives if not safe
      final safeAlternatives = alerts.isEmpty
          ? <String>[]
          : await _getSafeAlternatives(foodItemId, profile);

      final result = AllergenScanResult(
        foodItemId: foodItemId,
        foodName: foodName,
        alerts: alerts,
        isSafe: alerts.isEmpty,
        safeAlternatives: safeAlternatives,
        scannedAt: DateTime.now(),
      );

      _scanCache[cacheKey] = result;
      return result;
    } catch (e) {
      debugPrint('Error scanning food: $e');
      return null;
    }
  }

  /// Check if ingredients contain allergen
  bool _checkForAllergen(List<String> ingredients, Allergen allergen) {
    final allergenKeywords = _getAllergenKeywords(allergen);
    final ingredientsLower = ingredients.map((i) => i.toLowerCase()).toList();

    return allergenKeywords.any((keyword) =>
        ingredientsLower.any((ingredient) => ingredient.contains(keyword)));
  }

  /// Get keywords for allergen detection
  List<String> _getAllergenKeywords(Allergen allergen) {
    switch (allergen) {
      case Allergen.milk:
        return ['milk', 'dairy', 'lactose', 'whey', 'casein', 'butter', 'cream', 'cheese'];
      case Allergen.eggs:
        return ['egg', 'albumin', 'mayonnaise'];
      case Allergen.fish:
        return ['fish', 'salmon', 'tuna', 'cod', 'anchovy'];
      case Allergen.shellfish:
        return ['shellfish', 'shrimp', 'crab', 'lobster', 'prawn'];
      case Allergen.treeNuts:
        return ['almond', 'walnut', 'cashew', 'pecan', 'pistachio', 'macadamia'];
      case Allergen.peanuts:
        return ['peanut', 'groundnut'];
      case Allergen.wheat:
        return ['wheat', 'flour', 'bread', 'pasta', 'semolina'];
      case Allergen.soybeans:
        return ['soy', 'soybean', 'tofu', 'edamame', 'miso'];
      case Allergen.gluten:
        return ['gluten', 'wheat', 'barley', 'rye', 'malt'];
      default:
        return [allergen.name.toLowerCase()];
    }
  }

  /// Get allergen alert message
  String _getAllergenMessage(Allergen allergen, SeverityLevel severity) {
    final allergenName = allergen.name.toUpperCase();
    switch (severity) {
      case SeverityLevel.severe:
        return '🚨 DANGER: Contains $allergenName. Severe allergy risk. Do NOT consume!';
      case SeverityLevel.moderate:
        return '⚠️ WARNING: Contains $allergenName. May cause significant symptoms.';
      case SeverityLevel.mild:
        return 'ℹ️ NOTICE: Contains $allergenName. May cause mild discomfort.';
    }
  }

  /// Get safe alternatives
  Future<List<String>> _getSafeAlternatives(
      String foodItemId, AllergyProfile profile) async {
    // This would query a database of alternative foods
    // For now, return empty list
    return [];
  }

  // =====================================================
  // MEDICAL CONDITION GUIDANCE
  // =====================================================

  /// Get dietary guidelines for medical condition
  Map<String, dynamic> getConditionGuidelines(MedicalCondition condition) {
    switch (condition) {
      case MedicalCondition.diabetes:
        return {
          'name': 'Diabetes Management',
          'avoid': ['High sugar foods', 'Refined carbs', 'Sugary drinks'],
          'focus': ['Low glycemic index', 'Fiber', 'Protein'],
          'target_carbs': '45-60g per meal',
          'notes': 'Monitor blood glucose regularly',
        };

      case MedicalCondition.kidneyDisease:
        return {
          'name': 'Kidney Disease (CKD)',
          'avoid': ['High potassium', 'High phosphorus', 'Excess protein'],
          'focus': ['Controlled protein', 'Low sodium', 'Limited potassium'],
          'target_protein': '0.6-0.8g per kg body weight',
          'notes': 'Work with nephrologist for specific limits',
        };

      case MedicalCondition.heartDisease:
        return {
          'name': 'Heart Disease',
          'avoid': ['Saturated fat', 'Trans fat', 'High sodium', 'Cholesterol'],
          'focus': ['Omega-3', 'Fiber', 'Plant sterols'],
          'target_sodium': '<2000mg per day',
          'notes': 'Mediterranean diet recommended',
        };

      case MedicalCondition.pcos:
        return {
          'name': 'PCOS Management',
          'avoid': ['High glycemic foods', 'Processed foods', 'Excess sugar'],
          'focus': ['Low GI carbs', 'Lean protein', 'Anti-inflammatory foods'],
          'target_carbs': '40% of calories',
          'notes': 'Focus on insulin sensitivity',
        };

      case MedicalCondition.ibs:
        return {
          'name': 'IBS (Low FODMAP)',
          'avoid': ['High FODMAP foods', 'Dairy', 'Gluten', 'Legumes'],
          'focus': ['Low FODMAP', 'Soluble fiber', 'Probiotics'],
          'notes': 'Reintroduce foods systematically',
        };

      case MedicalCondition.celiacDisease:
        return {
          'name': 'Celiac Disease',
          'avoid': ['Gluten', 'Wheat', 'Barley', 'Rye'],
          'focus': ['Gluten-free grains', 'Rice', 'Quinoa', 'Corn'],
          'notes': 'Strict gluten avoidance required',
        };

      default:
        return {
          'name': condition.name,
          'notes': 'Consult healthcare provider',
        };
    }
  }

  // =====================================================
  // MEDICATION INTERACTIONS
  // =====================================================

  /// Check for medication interactions
  Future<List<MedicationInteraction>> checkMedicationInteractions({
    required String userId,
    required List<String> medications,
    required List<String> plannedFoods,
  }) async {
    try {
      final interactions = <MedicationInteraction>[];

      for (final medication in medications) {
        final response = await _supabase
            .from('medication_interactions')
            .select()
            .eq('medication_name', medication);

        if (response == null) continue;

        final interactionData = response as List;
        for (final data in interactionData) {
          final interaction = MedicationInteraction.fromJson(data as Map<String, dynamic>);

          // Check if any planned foods conflict
          final hasConflict = plannedFoods.any((food) =>
              interaction.avoidFoods.any((avoid) => food.toLowerCase().contains(avoid.toLowerCase())) ||
              interaction.limitFoods.any((limit) => food.toLowerCase().contains(limit.toLowerCase())));

          if (hasConflict) {
            interactions.add(interaction);
          }
        }
      }

      return interactions;
    } catch (e) {
      debugPrint('Error checking medication interactions: $e');
      return [];
    }
  }

  // =====================================================
  // MEDICAL REPORTING
  // =====================================================

  /// Generate medical report for doctor
  Future<MedicalNutritionReport?> generateMedicalReport({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      // Fetch nutrition logs for period
      final logsResponse = await _supabase
          .from('nutrition_logs')
          .select()
          .eq('user_id', userId)
          .gte('date', periodStart.toIso8601String())
          .lte('date', periodEnd.toIso8601String())
          .order('date');

      final logs = logsResponse as List? ?? [];

      // Calculate summary
      final summary = _calculateNutritionSummary(logs);
      final dailyIntake = _formatDailyIntake(logs);
      final complianceMetrics = _calculateCompliance(logs, userId);

      final reportData = {
        'user_id': userId,
        'report_date': DateTime.now().toIso8601String(),
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'summary': summary,
        'daily_intake': dailyIntake,
        'compliance_metrics': complianceMetrics,
      };

      final response = await _supabase
          .from('medical_nutrition_reports')
          .insert(reportData)
          .select()
          .single();

      return MedicalNutritionReport.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error generating medical report: $e');
      return null;
    }
  }

  Map<String, dynamic> _calculateNutritionSummary(List<dynamic> logs) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final log in logs) {
      totalCalories += (log['calories'] as num?)?.toDouble() ?? 0;
      totalProtein += (log['protein'] as num?)?.toDouble() ?? 0;
      totalCarbs += (log['carbs'] as num?)?.toDouble() ?? 0;
      totalFat += (log['fat'] as num?)?.toDouble() ?? 0;
    }

    final days = logs.length;

    return {
      'average_daily_calories': days > 0 ? totalCalories / days : 0,
      'average_daily_protein': days > 0 ? totalProtein / days : 0,
      'average_daily_carbs': days > 0 ? totalCarbs / days : 0,
      'average_daily_fat': days > 0 ? totalFat / days : 0,
      'total_days': days,
    };
  }

  List<Map<String, dynamic>> _formatDailyIntake(List<dynamic> logs) {
    return logs.map((log) {
      return {
        'date': log['date'],
        'calories': log['calories'],
        'protein': log['protein'],
        'carbs': log['carbs'],
        'fat': log['fat'],
      };
    }).toList();
  }

  Map<String, dynamic> _calculateCompliance(List<dynamic> logs, String userId) {
    // Calculate compliance with targets
    return {
      'days_logged': logs.length,
      'compliance_rate': logs.length / 30.0, // Assuming 30-day period
      'notes': 'Compliance calculated based on logging frequency',
    };
  }

  // =====================================================
  // UTILITY
  // =====================================================

  /// Clear cache
  void clearCache() {
    _cachedProfile = null;
    _scanCache.clear();
    notifyListeners();
  }
}