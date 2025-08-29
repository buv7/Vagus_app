import 'package:intl/intl.dart';

/// Helper service for generating share captions
class ShareCaptionHelper {
  /// Generate a caption for progress sharing
  static String generateProgressCaption({
    required String title,
    required Map<String, dynamic> metrics,
    String? subtitle,
    DateTime? date,
  }) {
    final buffer = StringBuffer();
    
    // Title
    buffer.write(title);
    
    // Subtitle
    if (subtitle != null && subtitle.isNotEmpty) {
      buffer.write('\n$subtitle');
    }
    
    // Metrics
    if (metrics.isNotEmpty) {
      buffer.write('\n\n');
      metrics.forEach((key, value) {
        buffer.write('$key: $value\n');
      });
    }
    
    // Date
    if (date != null) {
      final formatter = DateFormat('MMM dd, yyyy');
      buffer.write('\n${formatter.format(date)}');
    }
    
    // Hashtags
    buffer.write('\n\n#VAGUS #Fitness #Progress');
    
    return buffer.toString();
  }

  /// Generate a caption for workout sharing
  static String generateWorkoutCaption({
    required String workoutName,
    required Map<String, dynamic> stats,
    String? duration,
    DateTime? date,
  }) {
    final buffer = StringBuffer();
    
    buffer.write('💪 $workoutName');
    
    if (duration != null) {
      buffer.write('\n⏱️ $duration');
    }
    
    if (stats.isNotEmpty) {
      buffer.write('\n\n');
      stats.forEach((key, value) {
        buffer.write('$key: $value\n');
      });
    }
    
    if (date != null) {
      final formatter = DateFormat('MMM dd, yyyy');
      buffer.write('\n${formatter.format(date)}');
    }
    
    buffer.write('\n\n#VAGUS #Workout #Fitness');
    
    return buffer.toString();
  }

  /// Generate a caption for nutrition sharing
  static String generateNutritionCaption({
    required String mealName,
    required Map<String, dynamic> macros,
    String? totalCalories,
    DateTime? date,
  }) {
    final buffer = StringBuffer();
    
    buffer.write('🍽️ $mealName');
    
    if (totalCalories != null) {
      buffer.write('\n🔥 $totalCalories calories');
    }
    
    if (macros.isNotEmpty) {
      buffer.write('\n\n');
      macros.forEach((key, value) {
        buffer.write('$key: $value\n');
      });
    }
    
    if (date != null) {
      final formatter = DateFormat('MMM dd, yyyy');
      buffer.write('\n${formatter.format(date)}');
    }
    
    buffer.write('\n\n#VAGUS #Nutrition #HealthyEating');
    
    return buffer.toString();
  }

  /// Generate a caption for streak sharing
  static String generateStreakCaption({
    required int currentStreak,
    required int longestStreak,
    String? activity,
    DateTime? date,
  }) {
    final buffer = StringBuffer();
    
    buffer.write('🔥 $currentStreak day streak!');
    
    if (longestStreak > currentStreak) {
      buffer.write('\n🏆 Longest: $longestStreak days');
    }
    
    if (activity != null) {
      buffer.write('\n📈 $activity');
    }
    
    if (date != null) {
      final formatter = DateFormat('MMM dd, yyyy');
      buffer.write('\n${formatter.format(date)}');
    }
    
    buffer.write('\n\n#VAGUS #Streak #Consistency');
    
    return buffer.toString();
  }

  /// Generate a caption for calendar sharing
  static String generateCalendarCaption({
    required String eventTitle,
    required DateTime eventDate,
    String? eventType,
    String? location,
  }) {
    final buffer = StringBuffer();
    
    buffer.write('📅 $eventTitle');
    
    final formatter = DateFormat('MMM dd, yyyy');
    buffer.write('\n🗓️ ${formatter.format(eventDate)}');
    
    if (eventType != null) {
      buffer.write('\n📋 $eventType');
    }
    
    if (location != null) {
      buffer.write('\n📍 $location');
    }
    
    buffer.write('\n\n#VAGUS #Calendar #Planning');
    
    return buffer.toString();
  }

  /// Generate a caption for health sharing
  static String generateHealthCaption({
    required String metricName,
    required dynamic value,
    String? unit,
    String? goal,
    DateTime? date,
  }) {
    final buffer = StringBuffer();
    
    buffer.write('❤️ $metricName: $value');
    
    if (unit != null) {
      buffer.write(' $unit');
    }
    
    if (goal != null) {
      buffer.write('\n🎯 Goal: $goal');
    }
    
    if (date != null) {
      final formatter = DateFormat('MMM dd, yyyy');
      buffer.write('\n${formatter.format(date)}');
    }
    
    buffer.write('\n\n#VAGUS #Health #Wellness');
    
    return buffer.toString();
  }
}
