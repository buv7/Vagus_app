import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service for tracking AI usage in the VAGUS app
/// Calls the update-ai-usage Edge Function to record usage
class AIUsageService {
  AIUsageService._();
  static final AIUsageService instance = AIUsageService._();

  final supabase = Supabase.instance.client;

  /// Record AI usage after an AI request is made
  /// This should be called after each AI request to track usage
  Future<bool> recordUsage({
    required int tokensUsed,
    String? userId,
  }) async {
    try {
      // Get current user if not provided
      User? user;
      if (userId != null) {
        final response = await supabase.auth.getUser();
        user = response.user;
      } else {
        user = supabase.auth.currentUser;
      }
      
      if (user == null) {
        debugPrint('⚠️ No authenticated user for AI usage tracking');
        return false;
      }

      // Call the update-ai-usage Edge Function
      final response = await supabase.functions.invoke(
        'update-ai-usage',
        body: {
          'user_id': user.id,
          'tokens_used': tokensUsed,
        },
      );

      if (response.status == 200) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          debugPrint('✅ AI usage recorded successfully: $tokensUsed tokens');
          return true;
        } else {
          debugPrint('❌ AI usage recording failed: ${data?['error']}');
          return false;
        }
      } else {
        debugPrint('❌ AI usage recording failed with status: ${response.status}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error recording AI usage: $e');
      return false;
    }
  }

  /// Record AI usage with additional metadata
  /// Useful for more detailed tracking
  Future<bool> recordUsageWithMetadata({
    required int tokensUsed,
    required String requestType,
    String? requestId,
    Map<String, dynamic>? additionalData,
    String? userId,
  }) async {
    try {
      // Get current user if not provided
      User? user;
      if (userId != null) {
        final response = await supabase.auth.getUser();
        user = response.user;
      } else {
        user = supabase.auth.currentUser;
      }
      
      if (user == null) {
        debugPrint('⚠️ No authenticated user for AI usage tracking');
        return false;
      }

      // Call the update-ai-usage Edge Function
      final response = await supabase.functions.invoke(
        'update-ai-usage',
        body: {
          'user_id': user.id,
          'tokens_used': tokensUsed,
          'request_type': requestType,
          'request_id': requestId,
          'additional_data': additionalData,
        },
      );

      if (response.status == 200) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          debugPrint('✅ AI usage recorded successfully: $tokensUsed tokens for $requestType');
          return true;
        } else {
          debugPrint('❌ AI usage recording failed: ${data?['error']}');
          return false;
        }
      } else {
        debugPrint('❌ AI usage recording failed with status: ${response.status}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error recording AI usage: $e');
      return false;
    }
  }

  /// Get current AI usage for the authenticated user
  Future<Map<String, dynamic>?> getCurrentUsage() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No authenticated user for AI usage query');
        return null;
      }

      // Use the database function to get usage summary
      final response = await supabase.rpc('get_ai_usage_summary', params: {
        'uid': user.id,
      });

      if (response != null && response.isNotEmpty) {
        return response.first;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error getting AI usage: $e');
      return null;
    }
  }

  /// Get current month usage for the authenticated user
  Future<Map<String, dynamic>?> getCurrentMonthUsage() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No authenticated user for AI usage query');
        return null;
      }

      // Use the database function to get current month usage
      final response = await supabase.rpc('get_current_month_usage', params: {
        'uid': user.id,
      });

      if (response != null && response.isNotEmpty) {
        return response.first;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error getting current month AI usage: $e');
      return null;
    }
  }

  /// Check if user has exceeded monthly limit
  Future<bool> hasExceededMonthlyLimit() async {
    try {
      final usage = await getCurrentUsage();
      if (usage == null) return false;

      final requestsThisMonth = usage['requests_this_month'] ?? 0;
      final monthlyLimit = usage['monthly_limit'] ?? 100;

      return requestsThisMonth >= monthlyLimit;
    } catch (e) {
      debugPrint('❌ Error checking monthly limit: $e');
      return false;
    }
  }

  /// Get remaining requests for current month
  Future<int> getRemainingRequests() async {
    try {
      final usage = await getCurrentUsage();
      if (usage == null) return 100; // Default limit

      final requestsThisMonth = usage['requests_this_month'] ?? 0;
      final monthlyLimit = usage['monthly_limit'] ?? 100;

      return (monthlyLimit - requestsThisMonth).clamp(0, monthlyLimit);
    } catch (e) {
      debugPrint('❌ Error getting remaining requests: $e');
      return 100; // Default limit
    }
  }
}
