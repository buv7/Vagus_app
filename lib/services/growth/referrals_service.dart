import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/growth/referrals_models.dart';

/// Service for referrals and affiliates functionality
class ReferralsService {
  static final ReferralsService _instance = ReferralsService._internal();
  factory ReferralsService() => _instance;
  ReferralsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // MARK: - Referrals

  /// Get or create referral code for current user
  Future<String> getOrCreateMyCode() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Call the database function to ensure code exists
      final response = await _supabase.rpc('ensure_referral_code', params: {
        'p_user': userId,
      });

      return response as String;
    } catch (e) {
      debugPrint('Error getting referral code: $e');
      rethrow;
    }
  }

  /// Build share URI for referral code
  Future<Uri> buildShareUri(String code) async {
    // Deep link format: app://invite?c=CODE
    // final deepLink = Uri.parse('app://invite?c=$code');
    
    // Fallback HTTPS URL
    final fallbackUrl = Uri.parse('https://your-app.com/invite?c=$code');
    
    // For now, return fallback URL (in real app, check if deep link is supported)
    return fallbackUrl;
  }

  /// Record attribution when user signs up with referral code
  Future<void> recordAttribution({
    required String code,
    required String deviceFingerprint,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // TODO: call Edge function 'referrals_attrib'
      // For now, simulate attribution recording
      debugPrint('Recording attribution: code=$code, device=$deviceFingerprint');

      // Find referrer by code
      final referrerResponse = await _supabase
          .from('referral_codes')
          .select('user_id')
          .eq('code', code)
          .eq('status', 'active')
          .single();

      final referrerId = referrerResponse['user_id'] as String;
      
      // Create referral record
      await _supabase.from('referrals').insert({
        'referrer_id': referrerId,
        'referee_id': userId,
        'code': code,
        'source': 'app_signup',
      });

      // Log analytics
      _logAnalytics('ref_signup', {
        'code': code,
        'referrer_id': referrerId,
        'referee_id': userId,
      });
        } catch (e) {
      debugPrint('Error recording attribution: $e');
    }
  }

  /// Handle milestone reached (checklist or payment)
  Future<bool> onMilestoneReached({
    required String refereeId,
    required String milestone,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Find referral record
      final referralResponse = await _supabase
          .from('referrals')
          .select()
          .eq('referee_id', refereeId)
          .filter('milestone', 'is', null)
          .maybeSingle();

      if (referralResponse == null) return false;

      final referral = Referral.fromJson(referralResponse);
      final referrerId = referral.referrerId;

      // Check if this is the first milestone for this referee
      if (referral.milestone != null) return false;

      // Check monthly cap
      final currentMonth = DateTime.now();
      final monthStart = DateTime(currentMonth.year, currentMonth.month, 1);
      
      final monthlyCapResponse = await _supabase
          .from('referral_monthly_caps')
          .select('referral_count')
          .eq('referrer_id', referrerId)
          .eq('month', monthStart.toIso8601String())
          .maybeSingle();

      final currentCount = monthlyCapResponse?['referral_count'] as int? ?? 0;
      final isAtCap = currentCount >= 5;

      // Prepare reward values
      final rewardValues = <String, dynamic>{};
      if (isAtCap) {
        rewardValues['queue_month'] = currentMonth.toIso8601String();
      }

      // Update referral with milestone
      await _supabase
          .from('referrals')
          .update({
            'milestone': milestone,
            'rewarded_at': isAtCap ? null : DateTime.now().toIso8601String(),
            'reward_type': isAtCap ? [] : ['pro_days', 'vp', 'shield_check'],
            'reward_values': rewardValues,
          })
          .eq('id', referral.id);

      if (!isAtCap) {
        // Grant rewards
        await _grantRewards(referrerId, refereeId, milestone);
        
        // Log analytics
        _logAnalytics('ref_milestone_met', {
          'milestone': milestone,
          'referrer_id': referrerId,
          'referee_id': refereeId,
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error handling milestone: $e');
      return false;
    }
  }

  /// Grant rewards to referrer and referee
  Future<void> _grantRewards(String referrerId, String refereeId, String milestone) async {
    try {
      // Grant Pro days to both referrer and referee
      // TODO: Use PlanAccessManager.addProDays(7)
      debugPrint('Granting 7 Pro days to referrer $referrerId and referee $refereeId');

      // Grant VP to referrer
      // TODO: Use RankEvents.record('+50', meta:{reason:'referral'})
      debugPrint('Granting 50 VP to referrer $referrerId');

      // Check for Shield eligibility
      await _checkShieldEligibility(referrerId);

      // Send notifications
      await _sendRewardNotifications(referrerId, refereeId, milestone);
    } catch (e) {
      debugPrint('Error granting rewards: $e');
    }
  }

  /// Check if referrer is eligible for Shield
  Future<void> _checkShieldEligibility(String referrerId) async {
    try {
      // Count successful referrals in rolling year
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      
      final successfulReferrals = await _supabase
          .from('referrals')
          .select('id')
          .eq('referrer_id', referrerId)
          .not('rewarded_at', 'is', null)
          .gte('created_at', oneYearAgo.toIso8601String());

      final count = successfulReferrals.length;
      
      // Shield milestones: 3, then +1 each additional 5
      if (count == 3 || (count > 3 && (count - 3) % 5 == 0)) {
        // TODO: Use StreakService.grantShieldIfEligible
        debugPrint('Granting Shield to referrer $referrerId (count: $count)');
        
        _logAnalytics('shield_granted', {
          'referrer_id': referrerId,
          'referral_count': count,
        });
      }
    } catch (e) {
      debugPrint('Error checking Shield eligibility: $e');
    }
  }

  /// Send reward notifications
  Future<void> _sendRewardNotifications(String referrerId, String refereeId, String milestone) async {
    try {
      // TODO: Use NotificationHelper to send push notifications
      debugPrint('Sending reward notifications for milestone: $milestone');
    } catch (e) {
      debugPrint('Error sending notifications: $e');
    }
  }

  /// List user's referrals
  Future<List<Referral>> listMyReferrals() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('referrals')
          .select()
          .eq('referrer_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      return response.map((json) => Referral.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error listing referrals: $e');
      return [];
    }
  }

  /// Get monthly cap info
  Future<ReferralMonthlyCap?> getMonthlyCap() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final currentMonth = DateTime.now();
      final monthStart = DateTime(currentMonth.year, currentMonth.month, 1);

      final response = await _supabase
          .from('referral_monthly_caps')
          .select()
          .eq('referrer_id', userId)
          .eq('month', monthStart.toIso8601String())
          .maybeSingle();

      return response != null ? ReferralMonthlyCap.fromJson(response) : null;
    } catch (e) {
      debugPrint('Error getting monthly cap: $e');
      return null;
    }
  }

  // MARK: - Anti-abuse

  /// Check if referral is likely self-referral
  bool isLikelySelfReferral({
    String? email,
    String? phone,
    String? ipHash,
    String? deviceHash,
  }) {
    // Simple checks for now
    if (email != null && email.contains('test')) return true;
    if (phone != null && phone.contains('123')) return true;
    if (ipHash != null && ipHash == deviceHash) return true;
    
    return false;
  }

  /// Rate limit check
  bool isRateLimited(String deviceHash) {
    // TODO: Implement proper rate limiting
    // For now, just return false
    return false;
  }

  /// Flag suspicious referral
  Future<void> flagSuspiciousReferral(String referralId) async {
    try {
      await _supabase
          .from('referrals')
          .update({'fraud_flag': true})
          .eq('id', referralId);
    } catch (e) {
      debugPrint('Error flagging suspicious referral: $e');
    }
  }

  // MARK: - Affiliates (Coach)

  /// Get or create affiliate link
  Future<AffiliateLink> getOrCreateLink({
    String? customSlug,
    double? bountyUsd,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final slug = customSlug ?? 'coach_${userId.substring(0, 8)}';
      final bounty = bountyUsd ?? 20.00;

      // Call database function
      final linkId = await _supabase.rpc('upsert_affiliate_link', params: {
        'p_coach': userId,
        'p_slug': slug,
        'p_bounty': bounty,
      });

      // Get the link details
      final response = await _supabase
          .from('affiliate_links')
          .select()
          .eq('id', linkId)
          .maybeSingle();

      if (response == null) throw Exception('Failed to create affiliate link');
      return AffiliateLink.fromJson(response);
    } catch (e) {
      debugPrint('Error getting affiliate link: $e');
      rethrow;
    }
  }

  /// List affiliate conversions
  Future<List<AffiliateConversion>> listConversions({String status = 'pending'}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('affiliate_conversions')
          .select('*, affiliate_links!inner(*)')
          .eq('affiliate_links.coach_id', userId)
          .eq('status', status)
          .order('created_at', ascending: false);

      return response.map((json) => AffiliateConversion.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error listing conversions: $e');
      return [];
    }
  }

  /// Approve affiliate conversion
  Future<bool> approveConversion(String id) async {
    try {
      await _supabase
          .from('affiliate_conversions')
          .update({'status': 'approved'})
          .eq('id', id);

      _logAnalytics('aff_approved', {'conversion_id': id});
      return true;
    } catch (e) {
      debugPrint('Error approving conversion: $e');
      return false;
    }
  }

  /// Export payout CSV (admin only)
  Future<Uri?> exportPayoutCsv({List<String> conversionIds = const []}) async {
    try {
      // TODO: call Edge function to generate CSV
      // For now, return a stub URL
      final csvUrl = 'https://your-app.com/admin/payouts/csv_${DateTime.now().millisecondsSinceEpoch}';
      
      _logAnalytics('aff_payout_export', {
        'conversion_count': conversionIds.length,
      });
      
      return Uri.parse(csvUrl);
    } catch (e) {
      debugPrint('Error exporting payout CSV: $e');
      return null;
    }
  }

  // MARK: - Analytics

  /// Log analytics events
  void _logAnalytics(String event, Map<String, dynamic> properties) {
    try {
      // TODO: Implement proper analytics logging
      debugPrint('Analytics: $event - ${jsonEncode(properties)}');
    } catch (e) {
      debugPrint('Error logging analytics: $e');
    }
  }

  /// Copy referral link to clipboard
  Future<void> copyReferralLink(String code) async {
    try {
      final uri = await buildShareUri(code);
      // TODO: Use clipboard service
      debugPrint('Copied referral link: $uri');
      
      _logAnalytics('ref_link_copied', {'code': code});
    } catch (e) {
      debugPrint('Error copying referral link: $e');
    }
  }

  /// Share referral link
  Future<void> shareReferralLink(String code) async {
    try {
      final uri = await buildShareUri(code);
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (success) {
        _logAnalytics('ref_link_shared', {'code': code});
      }
    } catch (e) {
      debugPrint('Error sharing referral link: $e');
    }
  }
}
