import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

/// Cardio workout data parsed from OCR
class CardioWorkoutData {
  final String? sport;
  final double? distance;
  final String? distanceUnit;
  final int? durationMinutes;
  final int? durationSeconds;
  final double? calories;
  final double? avgHeartRate;
  final double? maxHeartRate;
  final double? avgPace;
  final String? paceUnit;
  final double? avgSpeed;
  final String? speedUnit;
  final DateTime? startTime;
  final DateTime? endTime;
  final double confidence;
  final String? rawOcrText;
  final String? imagePath;

  CardioWorkoutData({
    this.sport,
    this.distance,
    this.distanceUnit,
    this.durationMinutes,
    this.durationSeconds,
    this.calories,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgPace,
    this.paceUnit,
    this.avgSpeed,
    this.speedUnit,
    this.startTime,
    this.endTime,
    required this.confidence,
    this.rawOcrText,
    this.imagePath,
  });

  /// Get total duration in seconds
  int get totalDurationSeconds {
    int total = 0;
    if (durationMinutes != null) total += durationMinutes! * 60;
    if (durationSeconds != null) total += durationSeconds!;
    return total;
  }

  /// Get distance in meters
  double? get distanceMeters {
    if (distance == null) return null;
    switch (distanceUnit?.toLowerCase()) {
      case 'km':
        return distance! * 1000;
      case 'mi':
      case 'miles':
        return distance! * 1609.34;
      case 'm':
      case 'meters':
        return distance;
      default:
        // Assume km by default
        return distance! * 1000;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'sport': sport,
      'distance': distance,
      'distance_unit': distanceUnit,
      'duration_minutes': durationMinutes,
      'duration_seconds': durationSeconds,
      'calories': calories,
      'avg_heart_rate': avgHeartRate,
      'max_heart_rate': maxHeartRate,
      'avg_pace': avgPace,
      'pace_unit': paceUnit,
      'avg_speed': avgSpeed,
      'speed_unit': speedUnit,
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
      durationSeconds: json['duration_seconds'],
      calories: json['calories']?.toDouble(),
      avgHeartRate: json['avg_heart_rate']?.toDouble(),
      maxHeartRate: json['max_heart_rate']?.toDouble(),
      avgPace: json['avg_pace']?.toDouble(),
      paceUnit: json['pace_unit'],
      avgSpeed: json['avg_speed']?.toDouble(),
      speedUnit: json['speed_unit'],
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      confidence: json['confidence']?.toDouble() ?? 0.0,
    );
  }

  /// Create a copy with updated values
  CardioWorkoutData copyWith({
    String? sport,
    double? distance,
    String? distanceUnit,
    int? durationMinutes,
    int? durationSeconds,
    double? calories,
    double? avgHeartRate,
    double? maxHeartRate,
    double? avgPace,
    String? paceUnit,
    double? avgSpeed,
    String? speedUnit,
    DateTime? startTime,
    DateTime? endTime,
    double? confidence,
    String? rawOcrText,
    String? imagePath,
  }) {
    return CardioWorkoutData(
      sport: sport ?? this.sport,
      distance: distance ?? this.distance,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      calories: calories ?? this.calories,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      avgPace: avgPace ?? this.avgPace,
      paceUnit: paceUnit ?? this.paceUnit,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      speedUnit: speedUnit ?? this.speedUnit,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      confidence: confidence ?? this.confidence,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

/// OCR Cardio Service for processing workout images using AI Vision
class OCRCardioService {
  static final OCRCardioService _instance = OCRCardioService._internal();
  factory OCRCardioService() => _instance;
  OCRCardioService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  
  // OpenRouter API configuration
  final String _apiKey = const String.fromEnvironment('OPENROUTER_API_KEY');
  final String _baseUrl = const String.fromEnvironment(
    'OPENROUTER_BASE_URL',
    defaultValue: 'https://openrouter.ai/api/v1',
  );
  
  // Vision model that supports image input
  static const String _visionModel = 'google/gemini-2.0-flash-001';

  /// Capture image from camera
  Future<String?> captureFromCamera() async {
    try {
      debugPrint('OCR: Opening camera...');
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) {
        debugPrint('OCR: Camera capture cancelled');
        return null;
      }
      
      // Save to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'ocr_cardio_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${directory.path}/$fileName';
      
      await File(image.path).copy(savedPath);
      debugPrint('OCR: Image saved to $savedPath');
      
      return savedPath;
    } catch (e) {
      debugPrint('OCR: Error capturing from camera: $e');
      return null;
    }
  }

  /// Pick image from gallery
  Future<String?> pickFromGallery() async {
    try {
      debugPrint('OCR: Opening gallery...');
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) {
        debugPrint('OCR: Gallery pick cancelled');
        return null;
      }
      
      // Save to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'ocr_cardio_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${directory.path}/$fileName';
      
      await File(image.path).copy(savedPath);
      debugPrint('OCR: Image saved to $savedPath');
      
      return savedPath;
    } catch (e) {
      debugPrint('OCR: Error picking from gallery: $e');
      return null;
    }
  }

  /// Perform OCR on the captured image using AI Vision API
  Future<String?> performOCR(String imagePath) async {
    try {
      debugPrint('OCR: Performing AI Vision OCR on $imagePath');
      
      // Check if API key is configured
      if (_apiKey.isEmpty) {
        debugPrint('OCR: API key not configured, using fallback parsing');
        return _fallbackOCR(imagePath);
      }
      
      // Read and encode image to base64
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('OCR: Image file not found');
        return null;
      }
      
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Determine image type
      String mimeType = 'image/jpeg';
      if (imagePath.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      }
      
      // Create the vision request
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://vagus-app.com',
          'X-Title': 'VAGUS App OCR',
        },
        body: json.encode({
          'model': _visionModel,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a fitness cardio machine display OCR expert. Extract workout data from cardio machine displays (treadmills, ellipticals, bikes, rowers, etc.).

IMPORTANT: Return ONLY a valid JSON object with these fields (use null for missing values):
{
  "sport": "running|cycling|rowing|elliptical|walking|swimming|stairmaster|other",
  "distance": <number>,
  "distance_unit": "km|mi|m",
  "duration_minutes": <integer>,
  "duration_seconds": <integer>,
  "calories": <number>,
  "avg_heart_rate": <number>,
  "max_heart_rate": <number>,
  "avg_pace": <number in minutes>,
  "pace_unit": "km|mi",
  "avg_speed": <number>,
  "speed_unit": "km/h|mph",
  "confidence": <0.0-1.0 based on how clearly you could read the data>
}

Parse common fitness display formats:
- Time formats: HH:MM:SS, MM:SS, or just minutes
- Distance: look for km, mi, m, miles indicators
- Calories: kcal, cal, Cal
- Heart rate: bpm, HR, heart icons
- Speed: km/h, mph, kph
- Pace: min/km, min/mi, /km, /mi

Be smart about inferring the sport from the machine type shown in the image.'''
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Extract all workout data from this cardio machine display. Return ONLY the JSON object, no other text.'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'max_tokens': 500,
          'temperature': 0.1,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        debugPrint('OCR: AI Vision response: $content');
        return content;
      } else {
        debugPrint('OCR: AI Vision API error: ${response.statusCode} - ${response.body}');
        return _fallbackOCR(imagePath);
      }
    } catch (e) {
      debugPrint('OCR: Error performing AI OCR: $e');
      return _fallbackOCR(imagePath);
    }
  }

  /// Fallback OCR when API is not available - returns a prompt for manual entry
  String _fallbackOCR(String imagePath) {
    debugPrint('OCR: Using fallback - manual entry required');
    return json.encode({
      'sport': null,
      'distance': null,
      'distance_unit': null,
      'duration_minutes': null,
      'duration_seconds': null,
      'calories': null,
      'avg_heart_rate': null,
      'max_heart_rate': null,
      'avg_pace': null,
      'pace_unit': null,
      'avg_speed': null,
      'speed_unit': null,
      'confidence': 0.0,
      'requires_manual_entry': true,
    });
  }

  /// Parse OCR text (JSON) into structured workout data
  Future<CardioWorkoutData?> parseOCRText(String ocrText, {String? imagePath}) async {
    try {
      debugPrint('OCR: Parsing OCR text...');
      
      // Try to extract JSON from the response
      String jsonStr = ocrText.trim();
      
      // Handle markdown code blocks
      if (jsonStr.contains('```json')) {
        final startIndex = jsonStr.indexOf('```json') + 7;
        final endIndex = jsonStr.indexOf('```', startIndex);
        if (endIndex > startIndex) {
          jsonStr = jsonStr.substring(startIndex, endIndex).trim();
        }
      } else if (jsonStr.contains('```')) {
        final startIndex = jsonStr.indexOf('```') + 3;
        final endIndex = jsonStr.indexOf('```', startIndex);
        if (endIndex > startIndex) {
          jsonStr = jsonStr.substring(startIndex, endIndex).trim();
        }
      }
      
      // Try to find JSON object in the text
      final jsonMatch = RegExp(r'\{[^{}]*\}', dotAll: true).firstMatch(jsonStr);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }
      
      final Map<String, dynamic> parsed = json.decode(jsonStr);
      
      // Calculate confidence based on how many fields we got
      double confidence = parsed['confidence']?.toDouble() ?? 0.0;
      if (confidence == 0.0) {
        int parsedFields = 0;
        int totalFields = 7; // sport, distance, duration, calories, hr, pace, speed
        
        if (parsed['sport'] != null) parsedFields++;
        if (parsed['distance'] != null) parsedFields++;
        if (parsed['duration_minutes'] != null || parsed['duration_seconds'] != null) parsedFields++;
        if (parsed['calories'] != null) parsedFields++;
        if (parsed['avg_heart_rate'] != null) parsedFields++;
        if (parsed['avg_pace'] != null) parsedFields++;
        if (parsed['avg_speed'] != null) parsedFields++;
        
        confidence = parsedFields / totalFields;
      }
      
      return CardioWorkoutData(
        sport: parsed['sport'],
        distance: parsed['distance']?.toDouble(),
        distanceUnit: parsed['distance_unit'] ?? 'km',
        durationMinutes: parsed['duration_minutes'],
        durationSeconds: parsed['duration_seconds'],
        calories: parsed['calories']?.toDouble(),
        avgHeartRate: parsed['avg_heart_rate']?.toDouble(),
        maxHeartRate: parsed['max_heart_rate']?.toDouble(),
        avgPace: parsed['avg_pace']?.toDouble(),
        paceUnit: parsed['pace_unit'],
        avgSpeed: parsed['avg_speed']?.toDouble(),
        speedUnit: parsed['speed_unit'],
        confidence: confidence,
        rawOcrText: ocrText,
        imagePath: imagePath,
      );
    } catch (e) {
      debugPrint('OCR: Error parsing OCR JSON: $e');
      debugPrint('OCR: Raw text was: $ocrText');
      
      // Try legacy text parsing as fallback
      return _legacyParseOCRText(ocrText, imagePath: imagePath);
    }
  }

  /// Legacy text parsing for backwards compatibility
  CardioWorkoutData? _legacyParseOCRText(String ocrText, {String? imagePath}) {
    try {
      final lines = ocrText.split('\n');
      String? sport;
      double? distance;
      String? distanceUnit;
      int? durationMinutes;
      int? durationSeconds;
      double? calories;
      double? avgHeartRate;
      double? maxHeartRate;
      double? avgPace;
      String? paceUnit;
      
      for (final line in lines) {
        final trimmed = line.trim().toLowerCase();
        
        // Sport detection
        if (trimmed.contains('running') || trimmed.contains('run') || trimmed.contains('treadmill')) {
          sport = 'running';
        } else if (trimmed.contains('cycling') || trimmed.contains('bike') || trimmed.contains('cycle')) {
          sport = 'cycling';
        } else if (trimmed.contains('swimming') || trimmed.contains('swim')) {
          sport = 'swimming';
        } else if (trimmed.contains('walking') || trimmed.contains('walk')) {
          sport = 'walking';
        } else if (trimmed.contains('elliptical')) {
          sport = 'elliptical';
        } else if (trimmed.contains('rowing') || trimmed.contains('row')) {
          sport = 'rowing';
        } else if (trimmed.contains('stair')) {
          sport = 'stairmaster';
        }
        
        // Distance parsing
        final distanceMatch = RegExp(r'(\d+\.?\d*)\s*(km|mi|m|meters?|miles?)', caseSensitive: false).firstMatch(trimmed);
        if (distanceMatch != null) {
          distance = double.tryParse(distanceMatch.group(1) ?? '');
          distanceUnit = distanceMatch.group(2)?.replaceAll(RegExp(r's$'), '');
        }
        
        // Duration parsing (HH:MM:SS or MM:SS)
        final durationMatch = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?').firstMatch(trimmed);
        if (durationMatch != null && (trimmed.contains('duration') || trimmed.contains('time') || trimmed.contains(':') && !trimmed.contains('pace'))) {
          if (durationMatch.group(3) != null) {
            // HH:MM:SS format
            final hours = int.tryParse(durationMatch.group(1) ?? '') ?? 0;
            final minutes = int.tryParse(durationMatch.group(2) ?? '') ?? 0;
            durationSeconds = int.tryParse(durationMatch.group(3) ?? '');
            durationMinutes = hours * 60 + minutes;
          } else {
            // MM:SS format
            durationMinutes = int.tryParse(durationMatch.group(1) ?? '');
            durationSeconds = int.tryParse(durationMatch.group(2) ?? '');
          }
        }
        
        // Calories parsing
        final caloriesMatch = RegExp(r'(\d+)\s*(?:kcal|cal|calories?)', caseSensitive: false).firstMatch(trimmed);
        if (caloriesMatch != null) {
          calories = double.tryParse(caloriesMatch.group(1) ?? '');
        }
        
        // Heart rate parsing
        if (trimmed.contains('avg') && (trimmed.contains('hr') || trimmed.contains('heart'))) {
          final hrMatch = RegExp(r'(\d+)').firstMatch(trimmed);
          if (hrMatch != null) {
            avgHeartRate = double.tryParse(hrMatch.group(1) ?? '');
          }
        }
        
        if (trimmed.contains('max') && (trimmed.contains('hr') || trimmed.contains('heart'))) {
          final hrMatch = RegExp(r'(\d+)').firstMatch(trimmed);
          if (hrMatch != null) {
            maxHeartRate = double.tryParse(hrMatch.group(1) ?? '');
          }
        }
        
        // Pace parsing
        final paceMatch = RegExp(r'(\d+):(\d+)\s*/\s*(km|mi)', caseSensitive: false).firstMatch(trimmed);
        if (paceMatch != null) {
          final minutes = int.tryParse(paceMatch.group(1) ?? '') ?? 0;
          final seconds = int.tryParse(paceMatch.group(2) ?? '') ?? 0;
          avgPace = minutes + (seconds / 60);
          paceUnit = paceMatch.group(3);
        }
      }
      
      // Calculate confidence
      int parsedFields = 0;
      if (sport != null) parsedFields++;
      if (distance != null) parsedFields++;
      if (durationMinutes != null) parsedFields++;
      if (calories != null) parsedFields++;
      if (avgHeartRate != null) parsedFields++;
      if (avgPace != null) parsedFields++;
      
      final confidence = parsedFields > 0 ? parsedFields / 6 : 0.0;
      
      return CardioWorkoutData(
        sport: sport,
        distance: distance,
        distanceUnit: distanceUnit ?? 'km',
        durationMinutes: durationMinutes,
        durationSeconds: durationSeconds,
        calories: calories,
        avgHeartRate: avgHeartRate,
        maxHeartRate: maxHeartRate,
        avgPace: avgPace,
        paceUnit: paceUnit,
        confidence: confidence,
        rawOcrText: ocrText,
        imagePath: imagePath,
      );
    } catch (e) {
      debugPrint('OCR: Error in legacy parsing: $e');
      return null;
    }
  }

  /// Save workout data to both ocr_cardio_logs AND health_workouts tables
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
      
      // Step 1: Save to health_workouts for dashboard integration
      final healthWorkoutData = {
        'user_id': userId,
        'sport': parsedData.sport ?? 'cardio',
        'start_at': DateTime.now().subtract(Duration(seconds: parsedData.totalDurationSeconds)).toIso8601String(),
        'end_at': DateTime.now().toIso8601String(),
        'duration_s': parsedData.totalDurationSeconds,
        'distance_m': parsedData.distanceMeters,
        'avg_hr': parsedData.avgHeartRate,
        'kcal': parsedData.calories,
        'source': 'ocr_capture',
        'meta': {
          'max_hr': parsedData.maxHeartRate,
          'avg_pace': parsedData.avgPace,
          'pace_unit': parsedData.paceUnit,
          'avg_speed': parsedData.avgSpeed,
          'speed_unit': parsedData.speedUnit,
          'confidence': parsedData.confidence,
          'photo_path': imagePath,
        },
      };
      
      final healthWorkoutResponse = await _supabase
          .from('health_workouts')
          .insert(healthWorkoutData)
          .select()
          .single();
      
      final healthWorkoutId = healthWorkoutResponse['id'];
      debugPrint('OCR: Saved to health_workouts with ID: $healthWorkoutId');
      
      // Step 2: Save OCR log
      final ocrLogResponse = await _supabase
          .from('ocr_cardio_logs')
          .insert({
            'user_id': userId,
            'photo_path': imagePath,
            'parsed': parsedData.toJson(),
            'workout_id': healthWorkoutId,
            'confirmed': false,
          })
          .select()
          .single();
      
      debugPrint('OCR: Saved OCR log with ID: ${ocrLogResponse['id']}');
      
      // Step 3: Create merge record linking OCR log to health workout
      await _supabase
          .from('health_merges')
          .insert({
            'user_id': userId,
            'ocr_log_id': ocrLogResponse['id'],
            'workout_id': healthWorkoutId,
            'strategy': 'ocr_capture',
          });
      
      debugPrint('OCR: Created merge record');
      
      return true;
    } catch (e) {
      debugPrint('OCR: Error saving workout data: $e');
      return false;
    }
  }

  /// Complete OCR workflow: capture → OCR → parse → show preview → save
  /// Returns the parsed data for preview, caller should then call saveWorkoutData
  Future<CardioWorkoutData?> captureAndProcess({bool fromCamera = true}) async {
    try {
      debugPrint('OCR: Starting capture and process workflow');
      
      // Step 1: Capture image
      final imagePath = fromCamera 
          ? await captureFromCamera() 
          : await pickFromGallery();
          
      if (imagePath == null) {
        debugPrint('OCR: Image capture cancelled');
        return null;
      }
      
      // Step 2: Perform OCR
      final ocrText = await performOCR(imagePath);
      if (ocrText == null) {
        debugPrint('OCR: Failed to perform OCR');
        return null;
      }
      
      // Step 3: Parse OCR text
      final parsedData = await parseOCRText(ocrText, imagePath: imagePath);
      if (parsedData == null) {
        debugPrint('OCR: Failed to parse OCR text');
        return null;
      }
      
      debugPrint('OCR: Capture and process complete - confidence: ${parsedData.confidence}');
      return parsedData;
    } catch (e) {
      debugPrint('OCR: Error in capture and process: $e');
      return null;
    }
  }

  /// Quick process - capture, OCR, parse, and save in one call
  Future<CardioWorkoutData?> processWorkoutImage({bool fromCamera = true}) async {
    try {
      debugPrint('OCR: Starting quick process workflow');
      
      // Step 1: Capture and process
      final parsedData = await captureAndProcess(fromCamera: fromCamera);
      if (parsedData == null) {
        return null;
      }
      
      // Step 2: Save to database
      final saved = await saveWorkoutData(
        imagePath: parsedData.imagePath ?? '',
        ocrText: parsedData.rawOcrText ?? '',
        parsedData: parsedData,
      );
      
      if (!saved) {
        debugPrint('OCR: Failed to save workout data');
        return null;
      }
      
      debugPrint('OCR: Quick process complete');
      return parsedData;
    } catch (e) {
      debugPrint('OCR: Error in quick process: $e');
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
      debugPrint('OCR: Error getting OCR logs: $e');
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
      debugPrint('OCR: Error confirming OCR log: $e');
      return false;
    }
  }

  /// Delete OCR log and associated health workout
  Future<bool> deleteOCRLog(String logId) async {
    try {
      // Get the workout_id first
      final log = await _supabase
          .from('ocr_cardio_logs')
          .select('workout_id')
          .eq('id', logId)
          .single();
      
      final workoutId = log['workout_id'];
      
      // Delete merge record
      await _supabase
          .from('health_merges')
          .delete()
          .eq('ocr_log_id', logId);
      
      // Delete OCR log
      await _supabase
          .from('ocr_cardio_logs')
          .delete()
          .eq('id', logId);
      
      // Delete health workout if it was created by OCR
      if (workoutId != null) {
        await _supabase
            .from('health_workouts')
            .delete()
            .eq('id', workoutId)
            .eq('source', 'ocr_capture');
      }
      
      debugPrint('OCR: Deleted log $logId and associated records');
      return true;
    } catch (e) {
      debugPrint('OCR: Error deleting OCR log: $e');
      return false;
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
      debugPrint('OCR: Error getting OCR stats: $e');
      return {};
    }
  }

  /// Get health workouts created via OCR
  Future<List<Map<String, dynamic>>> getOCRWorkouts({int limit = 20}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      
      final response = await _supabase
          .from('health_workouts')
          .select()
          .eq('user_id', userId)
          .eq('source', 'ocr_capture')
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('OCR: Error getting OCR workouts: $e');
      return [];
    }
  }
}
