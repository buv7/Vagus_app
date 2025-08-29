import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cardio workout data parsed from OCR
class CardioWorkoutData {
  final String? sport;
  final double? distance;
  final String? distanceUnit;
  final int? durationMinutes;
  final double? calories;
  final double? avgHeartRate;
  final double? maxHeartRate;
  final double? avgPace;
  final String? paceUnit;
  final DateTime? startTime;
  final DateTime? endTime;
  final double confidence;

  CardioWorkoutData({
    this.sport,
    this.distance,
    this.distanceUnit,
    this.durationMinutes,
    this.calories,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgPace,
    this.paceUnit,
    this.startTime,
    this.endTime,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'sport': sport,
      'distance': distance,
      'distance_unit': distanceUnit,
      'duration_minutes': durationMinutes,
      'calories': calories,
      'avg_heart_rate': avgHeartRate,
      'max_heart_rate': maxHeartRate,
      'avg_pace': avgPace,
      'pace_unit': paceUnit,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'confidence': confidence,
    };
  }

  factory CardioWorkoutData.fromJson(Map<String, dynamic> json) {
    return CardioWorkoutData(
      sport: json['sport'],
      distance: json['distance']?.toDouble(),
      distanceUnit: json['distance_unit'],
      durationMinutes: json['duration_minutes'],
      calories: json['calories']?.toDouble(),
      avgHeartRate: json['avg_heart_rate']?.toDouble(),
      maxHeartRate: json['max_heart_rate']?.toDouble(),
      avgPace: json['avg_pace']?.toDouble(),
      paceUnit: json['pace_unit'],
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      confidence: json['confidence']?.toDouble() ?? 0.0,
    );
  }
}

/// OCR Cardio Service for processing workout images
class OCRCardioService {
  static final OCRCardioService _instance = OCRCardioService._internal();
  factory OCRCardioService() => _instance;
  OCRCardioService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Capture image from camera or gallery
  Future<String?> captureImage() async {
    try {
      // TODO: Implement actual image capture when camera package is approved
      // For now, create a placeholder image
      debugPrint('OCR: captureImage() - stubbed, creating placeholder');
      
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/ocr_placeholder_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Create a simple placeholder image (this is just for testing)
      // In real implementation, this would come from camera/gallery
      final file = File(imagePath);
      await file.writeAsBytes(Uint8List(100)); // Minimal placeholder
      
      return imagePath;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  /// Perform OCR on the captured image
  Future<String?> performOCR(String imagePath) async {
    try {
      // TODO: Implement actual OCR when google_mlkit_text_recognition is approved
      // For now, return mock OCR text
      debugPrint('OCR: performOCR() - stubbed, returning mock text');
      
      // Simulate OCR processing delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Return mock OCR text that looks like a workout summary
      return '''
Cardio Workout Summary
Running
Distance: 5.2 km
Duration: 28:15
Calories: 342
Avg HR: 142 bpm
Max HR: 168 bpm
Pace: 5:26 /km
      ''';
    } catch (e) {
      debugPrint('Error performing OCR: $e');
      return null;
    }
  }

  /// Parse OCR text into structured workout data
  Future<CardioWorkoutData?> parseOCRText(String ocrText) async {
    try {
      debugPrint('OCR: parseOCRText() - parsing: ${ocrText.substring(0, ocrText.length > 50 ? 50 : ocrText.length)}...');
      
      // Basic regex parsing for common workout metrics
      final lines = ocrText.split('\n');
      String? sport;
      double? distance;
      String? distanceUnit;
      int? durationMinutes;
      double? calories;
      double? avgHeartRate;
      double? maxHeartRate;
      double? avgPace;
      String? paceUnit;
      
      for (final line in lines) {
        final trimmed = line.trim().toLowerCase();
        
        // Sport detection
        if (trimmed.contains('running') || trimmed.contains('run')) {
          sport = 'running';
        } else if (trimmed.contains('cycling') || trimmed.contains('bike')) {
          sport = 'cycling';
        } else if (trimmed.contains('swimming') || trimmed.contains('swim')) {
          sport = 'swimming';
        } else if (trimmed.contains('walking') || trimmed.contains('walk')) {
          sport = 'walking';
        }
        
        // Distance parsing
        if (trimmed.contains('distance:')) {
          final distanceMatch = RegExp(r'(\d+\.?\d*)\s*(km|mi|m|meters?)').firstMatch(trimmed);
          if (distanceMatch != null) {
            distance = double.tryParse(distanceMatch.group(1) ?? '');
            distanceUnit = distanceMatch.group(2);
          }
        }
        
        // Duration parsing
        if (trimmed.contains('duration:') || trimmed.contains('time:')) {
          final durationMatch = RegExp(r'(\d+):(\d+)').firstMatch(trimmed);
          if (durationMatch != null) {
            final minutes = int.tryParse(durationMatch.group(1) ?? '');
            final seconds = int.tryParse(durationMatch.group(2) ?? '');
            if (minutes != null && seconds != null) {
              durationMinutes = minutes + (seconds / 60).round();
            }
          }
        }
        
        // Calories parsing
        if (trimmed.contains('calories:') || trimmed.contains('cal:')) {
          final caloriesMatch = RegExp(r'(\d+)').firstMatch(trimmed);
          if (caloriesMatch != null) {
            calories = double.tryParse(caloriesMatch.group(1) ?? '');
          }
        }
        
        // Heart rate parsing
        if (trimmed.contains('avg hr:') || trimmed.contains('average heart rate:')) {
          final hrMatch = RegExp(r'(\d+)').firstMatch(trimmed);
          if (hrMatch != null) {
            avgHeartRate = double.tryParse(hrMatch.group(1) ?? '');
          }
        }
        
        if (trimmed.contains('max hr:') || trimmed.contains('max heart rate:')) {
          final hrMatch = RegExp(r'(\d+)').firstMatch(trimmed);
          if (hrMatch != null) {
            maxHeartRate = double.tryParse(hrMatch.group(1) ?? '');
          }
        }
        
        // Pace parsing
        if (trimmed.contains('pace:') || trimmed.contains('avg pace:')) {
          final paceMatch = RegExp(r'(\d+):(\d+)\s*/(\w+)').firstMatch(trimmed);
          if (paceMatch != null) {
            final minutes = int.tryParse(paceMatch.group(1) ?? '');
            final seconds = int.tryParse(paceMatch.group(2) ?? '');
            if (minutes != null && seconds != null) {
              avgPace = minutes + (seconds / 60);
              paceUnit = paceMatch.group(3);
            }
          }
        }
      }
      
      // Calculate confidence based on how many fields we successfully parsed
      int parsedFields = 0;
      int totalFields = 0;
      
      if (sport != null) parsedFields++;
      totalFields++;
      if (distance != null) parsedFields++;
      totalFields++;
      if (durationMinutes != null) parsedFields++;
      totalFields++;
      if (calories != null) parsedFields++;
      totalFields++;
      if (avgHeartRate != null) parsedFields++;
      totalFields++;
      if (maxHeartRate != null) parsedFields++;
      totalFields++;
      if (avgPace != null) parsedFields++;
      totalFields++;
      
      final confidence = totalFields > 0 ? parsedFields / totalFields : 0.0;
      
      return CardioWorkoutData(
        sport: sport,
        distance: distance,
        distanceUnit: distanceUnit,
        durationMinutes: durationMinutes,
        calories: calories,
        avgHeartRate: avgHeartRate,
        maxHeartRate: maxHeartRate,
        avgPace: avgPace,
        paceUnit: paceUnit,
        confidence: confidence,
      );
    } catch (e) {
      debugPrint('Error parsing OCR text: $e');
      return null;
    }
  }

  /// Save workout data to database
  Future<bool> saveWorkoutData({
    required String imagePath,
    required String ocrText,
    required CardioWorkoutData parsedData,
    String? workoutId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('OCR: No authenticated user');
        return false;
      }
      
      // Save OCR log
      final ocrLogResponse = await _supabase
          .from('ocr_cardio_logs')
          .insert({
            'user_id': userId,
            'photo_path': imagePath,
            'parsed': parsedData.toJson(),
            'workout_id': workoutId,
          })
          .select()
          .single();
      
      debugPrint('OCR: Saved OCR log with ID: ${ocrLogResponse['id']}');
      
      // If we have a workout ID, create a merge record
      if (workoutId != null) {
        await _supabase
            .from('health_merges')
            .insert({
              'user_id': userId,
              'ocr_log_id': ocrLogResponse['id'],
              'workout_id': workoutId,
              'strategy': 'manual',
            });
        
        debugPrint('OCR: Created merge record for workout $workoutId');
      }
      
      return true;
    } catch (e) {
      debugPrint('Error saving workout data: $e');
      return false;
    }
  }

  /// Complete OCR workflow: capture → OCR → parse → save
  Future<CardioWorkoutData?> processWorkoutImage() async {
    try {
      debugPrint('OCR: Starting complete workflow');
      
      // Step 1: Capture image
      final imagePath = await captureImage();
      if (imagePath == null) {
        debugPrint('OCR: Failed to capture image');
        return null;
      }
      
      // Step 2: Perform OCR
      final ocrText = await performOCR(imagePath);
      if (ocrText == null) {
        debugPrint('OCR: Failed to perform OCR');
        return null;
      }
      
      // Step 3: Parse OCR text
      final parsedData = await parseOCRText(ocrText);
      if (parsedData == null) {
        debugPrint('OCR: Failed to parse OCR text');
        return null;
      }
      
      // Step 4: Save to database
      final saved = await saveWorkoutData(
        imagePath: imagePath,
        ocrText: ocrText,
        parsedData: parsedData,
      );
      
      if (!saved) {
        debugPrint('OCR: Failed to save workout data');
        return null;
      }
      
      debugPrint('OCR: Complete workflow successful');
      return parsedData;
    } catch (e) {
      debugPrint('Error in complete OCR workflow: $e');
      return null;
    }
  }

  /// Get OCR logs for the current user
  Future<List<Map<String, dynamic>>> getOCRLogs() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      
      final response = await _supabase
          .from('ocr_cardio_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting OCR logs: $e');
      return [];
    }
  }

  /// Confirm OCR log (mark as verified)
  Future<bool> confirmOCRLog(String logId) async {
    try {
      await _supabase
          .from('ocr_cardio_logs')
          .update({'confirmed': true})
          .eq('id', logId);
      
      debugPrint('OCR: Confirmed log $logId');
      return true;
    } catch (e) {
      debugPrint('Error confirming OCR log: $e');
      return false;
    }
  }

  /// Delete OCR log
  Future<bool> deleteOCRLog(String logId) async {
    try {
      await _supabase
          .from('ocr_cardio_logs')
          .delete()
          .eq('id', logId);
      
      debugPrint('OCR: Deleted log $logId');
      return true;
    } catch (e) {
      debugPrint('Error deleting OCR log: $e');
      return false;
    }
  }

  /// Find overlapping watch workouts for automatic merge
  Future<String?> findOverlappingWorkout({
    required DateTime windowStart,
    required DateTime windowEnd,
  }) async {
    try {
      // TODO: Implement when health service is connected
      // This would query health_workouts table for overlapping time windows
      debugPrint('OCR: findOverlappingWorkout - stubbed');
      return null;
    } catch (e) {
      debugPrint('Error finding overlapping workout: $e');
      return null;
    }
  }

  /// Get OCR statistics for the current user
  Future<Map<String, dynamic>> getOCRStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      
      final response = await _supabase
          .from('ocr_cardio_logs')
          .select('confirmed, created_at')
          .eq('user_id', userId);
      
      final total = response.length;
      final confirmed = response.where((log) => log['confirmed'] == true).length;
      final pending = total - confirmed;
      
      return {
        'total': total,
        'confirmed': confirmed,
        'pending': pending,
        'success_rate': total > 0 ? (confirmed / total * 100).roundToDouble() : 0.0,
      };
    } catch (e) {
      debugPrint('Error getting OCR stats: $e');
      return {};
    }
  }
}
