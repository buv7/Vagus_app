import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class ProgressService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // MARK: - Metrics Methods

  /// Fetch metrics for a user
  Future<List<Map<String, dynamic>>> fetchMetrics(String userId) async {
    try {
      final response = await _supabase
          .from('client_metrics')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch metrics: $e');
    }
  }

  /// Add a new metric entry
  Future<void> addMetric({
    required String userId,
    required DateTime date,
    double? weightKg,
    double? bodyFatPercent,
    double? waistCm,
    String? notes,
    int? sodiumMg,
    int? potassiumMg,
  }) async {
    try {
      await _supabase.from('client_metrics').insert({
        'user_id': userId,
        'date': date.toIso8601String().split('T')[0],
        'weight_kg': weightKg,
        'body_fat_percent': bodyFatPercent,
        'waist_cm': waistCm,
        'notes': notes,
        'sodium_mg': sodiumMg,
        'potassium_mg': potassiumMg,
      });
    } catch (e) {
      throw Exception('Failed to add metric: $e');
    }
  }

  /// Update an existing metric entry
  Future<void> updateMetric({
    required String metricId,
    double? weightKg,
    double? bodyFatPercent,
    double? waistCm,
    String? notes,
    int? sodiumMg,
    int? potassiumMg,
  }) async {
    try {
      await _supabase.from('client_metrics').update({
        'weight_kg': weightKg,
        'body_fat_percent': bodyFatPercent,
        'waist_cm': waistCm,
        'notes': notes,
        'sodium_mg': sodiumMg,
        'potassium_mg': potassiumMg,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', metricId);
    } catch (e) {
      throw Exception('Failed to update metric: $e');
    }
  }

  /// Delete a metric entry
  Future<void> deleteMetric(String metricId) async {
    try {
      await _supabase.from('client_metrics').delete().eq('id', metricId);
    } catch (e) {
      throw Exception('Failed to delete metric: $e');
    }
  }

  // MARK: - Progress Photos Methods

  /// Fetch progress photos for a user
  Future<List<Map<String, dynamic>>> fetchProgressPhotos(String userId) async {
    try {
      final response = await _supabase
          .from('progress_photos')
          .select()
          .eq('user_id', userId)
          .order('taken_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch progress photos: $e');
    }
  }

  /// Upload a progress photo
  Future<Map<String, dynamic>> uploadProgressPhoto({
    required String userId,
    required XFile imageFile,
    String? shotType,
    List<String>? tags,
  }) async {
    try {
      final file = File(imageFile.path);
      final fileExtension = imageFile.path.split('.').last;
      final fileName = '${_uuid.v4()}.$fileExtension';
      final storagePath = 'progress-photos/$userId/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage.from('vagus-media').upload(storagePath, file);

      // Get the public URL
      final url = _supabase.storage.from('vagus-media').getPublicUrl(storagePath);

      // Insert record in database
      final response = await _supabase.from('progress_photos').insert({
        'user_id': userId,
        'shot_type': shotType,
        'storage_path': storagePath,
        'url': url,
        'tags': tags ?? [],
      }).select().single();

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to upload progress photo: $e');
    }
  }

  /// Delete a progress photo
  Future<void> deleteProgressPhoto(String photoId) async {
    try {
      // Get the photo record first
      final photo = await _supabase
          .from('progress_photos')
          .select('storage_path')
          .eq('id', photoId)
          .single();

      // Delete from storage
      if (photo['storage_path'] != null) {
        await _supabase.storage
            .from('vagus-media')
            .remove([photo['storage_path']]);
      }

      // Delete from database
      await _supabase.from('progress_photos').delete().eq('id', photoId);
    } catch (e) {
      throw Exception('Failed to delete progress photo: $e');
    }
  }

  // MARK: - Check-ins Methods

  /// Fetch check-ins for a user
  Future<List<Map<String, dynamic>>> fetchCheckins(String userId) async {
    try {
      final response = await _supabase
          .from('checkins')
          .select()
          .eq('client_id', userId)
          .order('checkin_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch check-ins: $e');
    }
  }

  /// Create a new check-in
  Future<void> createCheckin({
    required String clientId,
    required String coachId,
    required DateTime checkinDate,
    required String message,
  }) async {
    try {
      await _supabase.from('checkins').insert({
        'client_id': clientId,
        'coach_id': coachId,
        'checkin_date': checkinDate.toIso8601String().split('T')[0],
        'message': message,
        'status': 'open',
      });
    } catch (e) {
      throw Exception('Failed to create check-in: $e');
    }
  }

  /// Update a check-in message (client only)
  Future<void> updateCheckinMessage({
    required String checkinId,
    required String message,
  }) async {
    try {
      await _supabase.from('checkins').update({
        'message': message,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', checkinId);
    } catch (e) {
      throw Exception('Failed to update check-in: $e');
    }
  }

  /// Get coach's linked clients for check-ins
  Future<List<Map<String, dynamic>>> getCoachClients(String coachId) async {
    try {
      final response = await _supabase
          .from('coach_clients')
          .select('client_id, profiles!inner(*)')
          .eq('coach_id', coachId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch coach clients: $e');
    }
  }

  /// Get check-ins for a coach's clients
  Future<List<Map<String, dynamic>>> getCoachCheckins(String coachId) async {
    try {
      final response = await _supabase
          .from('checkins')
          .select('*, profiles!inner(*)')
          .eq('coach_id', coachId)
          .order('checkin_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch coach check-ins: $e');
    }
  }

  /// Update coach reply to check-in
  Future<void> updateCoachReply({
    required String checkinId,
    required String coachReply,
    String? status,
  }) async {
    try {
      await _supabase.from('checkins').update({
        'coach_reply': coachReply,
        'status': status ?? 'replied',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', checkinId);
    } catch (e) {
      throw Exception('Failed to update coach reply: $e');
    }
  }

  // MARK: - Export Methods

  /// Export metrics to CSV format
  Future<String> exportMetricsToCsv(List<Map<String, dynamic>> metrics) async {
    final csvData = StringBuffer();
    
    // Header
    csvData.writeln('Date,Weight (kg),Body Fat (%),Waist (cm),Notes,Sodium (mg),Potassium (mg)');
    
    // Data rows
    for (final metric in metrics) {
      csvData.writeln([
        metric['date'] ?? '',
        metric['weight_kg']?.toString() ?? '',
        metric['body_fat_percent']?.toString() ?? '',
        metric['waist_cm']?.toString() ?? '',
        '"${(metric['notes'] ?? '').replaceAll('"', '""')}"',
        metric['sodium_mg']?.toString() ?? '',
        metric['potassium_mg']?.toString() ?? '',
      ].join(','));
    }
    
    return csvData.toString();
  }

  /// Get nutrition data for a specific date (for sodium/potassium roll-up)
  Future<Map<String, int>?> getNutritionTotalsForDate(String userId, DateTime date) async {
    try {
      final response = await _supabase
          .from('nutrition_plans')
          .select('meals')
          .eq('client_id', userId)
          .gte('created_at', date.toIso8601String())
          .lt('created_at', date.add(const Duration(days: 1)).toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;

      final plan = response.first as Map<String, dynamic>;
      final meals = plan['meals'] as List<dynamic>? ?? [];
      
      int totalSodium = 0;
      int totalPotassium = 0;

      for (final meal in meals) {
        final mealData = meal as Map<String, dynamic>;
        final mealSummary = mealData['mealSummary'] as Map<String, dynamic>? ?? {};
        
        totalSodium += (mealSummary['totalSodium'] as num?)?.toInt() ?? 0;
        totalPotassium += (mealSummary['totalPotassium'] as num?)?.toInt() ?? 0;
      }

      return {
        'sodium': totalSodium,
        'potassium': totalPotassium,
      };
    } catch (e) {
      // Silently return null if nutrition data can't be fetched
      return null;
    }
  }
}
