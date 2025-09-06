// lib/services/coach/coach_analytics_service.dart
import 'package:flutter/material.dart';

/// Analytics summary data for coach dashboard
class CoachAnalyticsSummary {
  final int totalClients;
  final int activeClients;
  final int totalSessions;
  final double avgSessionRating;
  final int totalMessages;
  final int unreadMessages;
  final double clientRetentionRate;
  final double avgResponseTime;
  final double avgCompliance;
  final List<double> sparkCompliance;
  final double avgSteps;
  final List<double> sparkSteps;
  final double netEnergyBalance;
  final List<double> sparkEnergy;
  final int checkinsThisWeek;

  const CoachAnalyticsSummary({
    required this.totalClients,
    required this.activeClients,
    required this.totalSessions,
    required this.avgSessionRating,
    required this.totalMessages,
    required this.unreadMessages,
    required this.clientRetentionRate,
    required this.avgResponseTime,
    required this.avgCompliance,
    required this.sparkCompliance,
    required this.avgSteps,
    required this.sparkSteps,
    required this.netEnergyBalance,
    required this.sparkEnergy,
    required this.checkinsThisWeek,
  });

  factory CoachAnalyticsSummary.empty() {
    return const CoachAnalyticsSummary(
      totalClients: 0,
      activeClients: 0,
      totalSessions: 0,
      avgSessionRating: 0.0,
      totalMessages: 0,
      unreadMessages: 0,
      clientRetentionRate: 0.0,
      avgResponseTime: 0.0,
      avgCompliance: 0.0,
      sparkCompliance: const [],
      avgSteps: 0.0,
      sparkSteps: const [],
      netEnergyBalance: 0.0,
      sparkEnergy: const [],
      checkinsThisWeek: 0,
    );
  }
}

/// Service for coach analytics data
class CoachAnalyticsService {
  static final CoachAnalyticsService _instance = CoachAnalyticsService._internal();
  factory CoachAnalyticsService() => _instance;
  CoachAnalyticsService._internal();

  /// Get analytics summary for a date range
  Future<CoachAnalyticsSummary> getSummary({
    required int days,
  }) async {
    // TODO: Implement actual analytics data fetching
    return CoachAnalyticsSummary.empty();
  }
}