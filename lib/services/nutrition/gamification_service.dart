import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Achievement and gamification system for nutrition tracking
/// Features: Badges, challenges, streaks, leaderboards, social sharing
class GamificationService extends ChangeNotifier {
  static final _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final _supabase = Supabase.instance.client;

  // State
  List<Achievement> _achievements = [];
  List<Challenge> _activeChallenges = [];
  StreakData? _currentStreak;
  List<LeaderboardEntry> _leaderboard = [];

  List<Achievement> get achievements => _achievements;
  List<Challenge> get activeChallenges => _activeChallenges;
  StreakData? get currentStreak => _currentStreak;
  List<LeaderboardEntry> get leaderboard => _leaderboard;

  /// Initialize achievements system
  Future<void> initialize(String userId) async {
    await Future.wait([
      _loadAchievements(userId),
      _loadChallenges(userId),
      _loadStreak(userId),
    ]);
  }

  /// Define all available achievements
  static List<AchievementDefinition> get achievementDefinitions => [
        // Streak Achievements
        AchievementDefinition(
          id: 'streak_7',
          name: '7-Day Streak',
          description: 'Log all meals for 7 consecutive days',
          icon: '🔥',
          category: AchievementCategory.streak,
          requirement: 7,
          points: 50,
        ),
        AchievementDefinition(
          id: 'streak_30',
          name: '30-Day Warrior',
          description: 'Log all meals for 30 consecutive days',
          icon: '🔥',
          category: AchievementCategory.streak,
          requirement: 30,
          points: 200,
        ),
        AchievementDefinition(
          id: 'streak_100',
          name: 'Century Streak',
          description: 'Log all meals for 100 consecutive days',
          icon: '💯',
          category: AchievementCategory.streak,
          requirement: 100,
          points: 1000,
        ),

        // Protein Achievements
        AchievementDefinition(
          id: 'protein_crusher_7',
          name: 'Protein Crusher',
          description: 'Hit protein goal 7 days in a row',
          icon: '💪',
          category: AchievementCategory.nutrition,
          requirement: 7,
          points: 75,
        ),
        AchievementDefinition(
          id: 'protein_crusher_30',
          name: 'Protein Master',
          description: 'Hit protein goal 30 days straight',
          icon: '💪',
          category: AchievementCategory.nutrition,
          requirement: 30,
          points: 250,
        ),

        // Nutrition Variety
        AchievementDefinition(
          id: 'veggie_lover',
          name: 'Veggie Lover',
          description: 'Eat 5+ servings of vegetables daily for a week',
          icon: '🥗',
          category: AchievementCategory.nutrition,
          requirement: 7,
          points: 100,
        ),
        AchievementDefinition(
          id: 'rainbow_eater',
          name: 'Eat the Rainbow',
          description: 'Eat 5 different colored foods in one day',
          icon: '🌈',
          category: AchievementCategory.nutrition,
          requirement: 1,
          points: 50,
        ),

        // Hydration
        AchievementDefinition(
          id: 'hydration_hero',
          name: 'Hydration Hero',
          description: 'Drink 3L water daily for a week',
          icon: '💧',
          category: AchievementCategory.nutrition,
          requirement: 7,
          points: 75,
        ),

        // Meal Prep
        AchievementDefinition(
          id: 'meal_prep_master',
          name: 'Meal Prep Master',
          description: 'Complete 10 meal prep sessions',
          icon: '👨‍🍳',
          category: AchievementCategory.preparation,
          requirement: 10,
          points: 150,
        ),
        AchievementDefinition(
          id: 'batch_cooking_pro',
          name: 'Batch Cooking Pro',
          description: 'Cook 50+ servings in one prep session',
          icon: '🍲',
          category: AchievementCategory.preparation,
          requirement: 1,
          points: 200,
        ),

        // Tracking
        AchievementDefinition(
          id: 'meal_photographer',
          name: 'Meal Photographer',
          description: 'Upload photos for 100 meals',
          icon: '📸',
          category: AchievementCategory.tracking,
          requirement: 100,
          points: 150,
        ),
        AchievementDefinition(
          id: 'perfect_logger',
          name: 'Perfect Logger',
          description: 'Log all macros with 100% accuracy for 30 days',
          icon: '✅',
          category: AchievementCategory.tracking,
          requirement: 30,
          points: 300,
        ),

        // Recipe Mastery
        AchievementDefinition(
          id: 'master_chef',
          name: 'Master Chef',
          description: 'Cook 50 different recipes',
          icon: '👨‍🍳',
          category: AchievementCategory.cooking,
          requirement: 50,
          points: 250,
        ),
        AchievementDefinition(
          id: 'recipe_creator',
          name: 'Recipe Creator',
          description: 'Create 10 custom recipes',
          icon: '📝',
          category: AchievementCategory.cooking,
          requirement: 10,
          points: 100,
        ),

        // Goal Achievement
        AchievementDefinition(
          id: 'goal_achiever',
          name: 'Goal Achiever',
          description: 'Reach your weight/body composition goal',
          icon: '🎯',
          category: AchievementCategory.goals,
          requirement: 1,
          points: 500,
        ),
        AchievementDefinition(
          id: 'macro_perfectionist',
          name: 'Macro Perfectionist',
          description: 'Hit all macro targets within 5g for 7 days',
          icon: '🎯',
          category: AchievementCategory.goals,
          requirement: 7,
          points: 200,
        ),

        // Social
        AchievementDefinition(
          id: 'inspiration_guru',
          name: 'Inspiration Guru',
          description: 'Share 50 meals that inspire others',
          icon: '✨',
          category: AchievementCategory.social,
          requirement: 50,
          points: 150,
        ),
        AchievementDefinition(
          id: 'community_champion',
          name: 'Community Champion',
          description: 'Help 10 other members with tips/advice',
          icon: '🤝',
          category: AchievementCategory.social,
          requirement: 10,
          points: 200,
        ),
      ];

  /// Check and award achievements based on user action
  Future<List<Achievement>> checkAchievements(String userId, UserAction action) async {
    final newAchievements = <Achievement>[];

    for (final def in achievementDefinitions) {
      // Check if already earned
      if (_achievements.any((a) => a.definitionId == def.id)) continue;

      // Check if requirement met
      if (await _meetsRequirement(userId, def, action)) {
        final achievement = Achievement(
          id: 'ach_${DateTime.now().millisecondsSinceEpoch}',
          definitionId: def.id,
          userId: userId,
          earnedAt: DateTime.now(),
          progress: def.requirement,
        );

        newAchievements.add(achievement);

        // Save to database
        await _supabase.from('achievements').insert(achievement.toJson());
      }
    }

    if (newAchievements.isNotEmpty) {
      _achievements.addAll(newAchievements);
      notifyListeners();
    }

    return newAchievements;
  }

  /// Create a new challenge (coach)
  Future<Challenge> createChallenge({
    required String coachId,
    required String name,
    required String description,
    required ChallengeType type,
    required int durationDays,
    required int targetValue,
    String? rewardDescription,
    List<String>? participantIds,
  }) async {
    final challenge = Challenge(
      id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
      coachId: coachId,
      name: name,
      description: description,
      type: type,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: durationDays)),
      targetValue: targetValue,
      rewardDescription: rewardDescription,
      participantIds: participantIds ?? [],
      leaderboard: [],
      isActive: true,
    );

    await _supabase.from('challenges').insert(challenge.toJson());

    _activeChallenges.add(challenge);
    notifyListeners();

    return challenge;
  }

  /// Join a challenge
  Future<void> joinChallenge(String userId, String challengeId) async {
    await _supabase.from('challenge_participants').insert({
      'challenge_id': challengeId,
      'user_id': userId,
      'joined_at': DateTime.now().toIso8601String(),
    });

    notifyListeners();
  }

  /// Update challenge progress
  Future<void> updateChallengeProgress(
    String userId,
    String challengeId,
    double progress,
  ) async {
    await _supabase.from('challenge_progress').upsert({
      'challenge_id': challengeId,
      'user_id': userId,
      'progress': progress,
      'updated_at': DateTime.now().toIso8601String(),
    });

    notifyListeners();
  }

  /// Get challenge leaderboard
  Future<List<LeaderboardEntry>> getChallengeLeaderboard(String challengeId) async {
    final response = await _supabase
        .from('challenge_progress')
        .select('*, profiles(name)')
        .eq('challenge_id', challengeId)
        .order('progress', ascending: false)
        .limit(100);

    return response.map<LeaderboardEntry>((json) => LeaderboardEntry.fromJson(json)).toList();
  }

  /// Track streak data
  Future<void> updateStreak(String userId, DateTime date) async {
    _currentStreak = await _calculateStreak(userId, date);
    notifyListeners();
  }

  /// Generate shareable achievement card
  Future<String> generateAchievementCard(Achievement achievement) async {
    // Generate beautiful shareable image
    // Returns URL to generated image
    return 'https://placeholder.com/achievement.png';
  }

  /// Generate shareable meal card
  Future<String> generateMealCard({
    required String mealName,
    required String photoUrl,
    required Map<String, double> macros,
    required String coachName,
  }) async {
    // Generate beautiful shareable meal card
    // Returns URL to generated image
    return 'https://placeholder.com/meal.png';
  }

  /// Award custom badge (coach)
  Future<Achievement> awardCustomBadge({
    required String coachId,
    required String userId,
    required String name,
    required String description,
    required String icon,
  }) async {
    final customDef = AchievementDefinition(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      icon: icon,
      category: AchievementCategory.custom,
      requirement: 1,
      points: 100,
    );

    final achievement = Achievement(
      id: 'ach_${DateTime.now().millisecondsSinceEpoch}',
      definitionId: customDef.id,
      userId: userId,
      earnedAt: DateTime.now(),
      progress: 1,
      awardedBy: coachId,
    );

    await _supabase.from('achievements').insert(achievement.toJson());

    _achievements.add(achievement);
    notifyListeners();

    return achievement;
  }

  /// Get user's total points
  int getTotalPoints(String userId) {
    int total = 0;
    for (final achievement in _achievements.where((a) => a.userId == userId)) {
      final def = achievementDefinitions.firstWhere((d) => d.id == achievement.definitionId);
      total += def.points;
    }
    return total;
  }

  /// Get achievement progress
  AchievementProgress getProgress(String userId, String achievementId) {
    final def = achievementDefinitions.firstWhere((d) => d.id == achievementId);

    // Calculate current progress
    // This would query actual user data
    final currentProgress = 0; // Placeholder

    return AchievementProgress(
      definition: def,
      currentProgress: currentProgress,
      isCompleted: _achievements.any((a) => a.definitionId == achievementId),
      percentComplete: (currentProgress / def.requirement * 100).clamp(0, 100),
    );
  }

  // Private helpers

  Future<void> _loadAchievements(String userId) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('user_id', userId);

      _achievements = response.map<Achievement>((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }

  Future<void> _loadChallenges(String userId) async {
    try {
      final response = await _supabase
          .from('challenges')
          .select()
          .eq('is_active', true)
          .or('coach_id.eq.$userId,participant_ids.cs.{$userId}');

      _activeChallenges = response.map<Challenge>((json) => Challenge.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading challenges: $e');
    }
  }

  Future<void> _loadStreak(String userId) async {
    _currentStreak = await _calculateStreak(userId, DateTime.now());
  }

  Future<bool> _meetsRequirement(
    String userId,
    AchievementDefinition def,
    UserAction action,
  ) async {
    // Implementation would check actual user data
    // For now, return false
    return false;
  }

  Future<StreakData> _calculateStreak(String userId, DateTime date) async {
    // Calculate streak from database
    // Placeholder implementation
    return StreakData(
      currentStreak: 0,
      longestStreak: 0,
      lastLogDate: DateTime.now(),
      streakProtectionAvailable: true,
    );
  }
}

// Models

enum AchievementCategory {
  streak,
  nutrition,
  preparation,
  tracking,
  cooking,
  goals,
  social,
  custom,
}

enum ChallengeType {
  noSugar,
  eatTheRainbow,
  hydration,
  proteinGoal,
  mealPrep,
  custom,
}

class AchievementDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementCategory category;
  final int requirement;
  final int points;

  AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.requirement,
    required this.points,
  });
}

class Achievement {
  final String id;
  final String definitionId;
  final String userId;
  final DateTime earnedAt;
  final int progress;
  final String? awardedBy;

  Achievement({
    required this.id,
    required this.definitionId,
    required this.userId,
    required this.earnedAt,
    required this.progress,
    this.awardedBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'definition_id': definitionId,
        'user_id': userId,
        'earned_at': earnedAt.toIso8601String(),
        'progress': progress,
        'awarded_by': awardedBy,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'],
        definitionId: json['definition_id'],
        userId: json['user_id'],
        earnedAt: DateTime.parse(json['earned_at']),
        progress: json['progress'],
        awardedBy: json['awarded_by'],
      );
}

class Challenge {
  final String id;
  final String coachId;
  final String name;
  final String description;
  final ChallengeType type;
  final DateTime startDate;
  final DateTime endDate;
  final int targetValue;
  final String? rewardDescription;
  final List<String> participantIds;
  final List<LeaderboardEntry> leaderboard;
  final bool isActive;

  Challenge({
    required this.id,
    required this.coachId,
    required this.name,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.targetValue,
    this.rewardDescription,
    required this.participantIds,
    required this.leaderboard,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'coach_id': coachId,
        'name': name,
        'description': description,
        'type': type.toString(),
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'target_value': targetValue,
        'reward_description': rewardDescription,
        'participant_ids': participantIds,
        'is_active': isActive,
      };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'],
        coachId: json['coach_id'],
        name: json['name'],
        description: json['description'],
        type: ChallengeType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => ChallengeType.custom,
        ),
        startDate: DateTime.parse(json['start_date']),
        endDate: DateTime.parse(json['end_date']),
        targetValue: json['target_value'],
        rewardDescription: json['reward_description'],
        participantIds: List<String>.from(json['participant_ids'] ?? []),
        leaderboard: [],
        isActive: json['is_active'] ?? true,
      );
}

class LeaderboardEntry {
  final String userId;
  final String userName;
  final double progress;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.progress,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        userId: json['user_id'],
        userName: json['profiles']?['name'] ?? 'Unknown',
        progress: (json['progress'] as num).toDouble(),
        rank: json['rank'] ?? 0,
      );
}

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastLogDate;
  final bool streakProtectionAvailable;

  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastLogDate,
    required this.streakProtectionAvailable,
  });

  bool get isActive => currentStreak > 0;
}

class AchievementProgress {
  final AchievementDefinition definition;
  final int currentProgress;
  final bool isCompleted;
  final double percentComplete;

  AchievementProgress({
    required this.definition,
    required this.currentProgress,
    required this.isCompleted,
    required this.percentComplete,
  });
}

class UserAction {
  final String type; // 'meal_logged', 'photo_uploaded', 'streak_continued', etc.
  final Map<String, dynamic> data;

  UserAction({
    required this.type,
    required this.data,
  });
}