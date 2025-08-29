import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Billing service for handling subscriptions, plans, and payments
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  final supabase = Supabase.instance.client;

  /// List all available billing plans
  Future<List<Map<String, dynamic>>> listPlans() async {
    try {
      final response = await supabase
          .from('billing_plans')
          .select('*')
          .eq('is_active', true)
          .order('price_monthly_cents', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error listing plans: $e');
      return [];
    }
  }

  /// Get current user's subscription
  Future<Map<String, dynamic>?> getMySubscription() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return null;

      final response = await supabase
          .from('subscriptions')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint('❌ Error getting subscription: $e');
      return null;
    }
  }

  /// Start checkout process for a plan
  Future<Map<String, dynamic>?> startCheckout({
    required String planCode,
    String? coupon,
  }) async {
    try {
      // Check if Edge Function is configured
      final edgeFunctionUrl = const String.fromEnvironment('STRIPE_CHECKOUT_FUNCTION_URL', defaultValue: '');
      
      if (edgeFunctionUrl.isNotEmpty) {
        // Call Edge Function for checkout
        final response = await supabase.functions.invoke(
          'create-checkout-session',
          body: {
            'plan_code': planCode,
            'coupon': coupon,
          },
        );
        
        if (response.data != null && response.data['checkout_url'] != null) {
          return {'checkout_url': response.data['checkout_url']};
        }
      }
      
      // Fallback: return empty result for manual/admin path
      return {};
    } catch (e) {
      debugPrint('❌ Error starting checkout: $e');
      return {};
    }
  }

  /// Apply a coupon code (validate and track for preview)
  Future<bool> applyCoupon(String code) async {
    try {
      final response = await supabase
          .from('coupons')
          .select('*')
          .eq('code', code)
          .eq('is_active', true)
          .maybeSingle();
      
      if (response == null) return false;
      
      // Check if coupon is expired
      if (response['redeem_by'] != null) {
        final redeemBy = DateTime.parse(response['redeem_by']);
        if (DateTime.now().isAfter(redeemBy)) return false;
      }
      
      // Check max redemptions if set
      if (response['max_redemptions'] != null) {
        final redemptionCount = await supabase
            .from('coupon_redemptions')
            .select('id')
            .eq('coupon_code', code);
        
        if (redemptionCount.length >= response['max_redemptions']) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error applying coupon: $e');
      return false;
    }
  }

  /// Refresh subscription status from external provider
  Future<void> refreshStatus() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // This would typically call an Edge Function to sync with Stripe
      // For now, just re-fetch the subscription
      await getMySubscription();
    } catch (e) {
      debugPrint('❌ Error refreshing status: $e');
    }
  }

  /// Cancel subscription at period end
  Future<void> cancelAtPeriodEnd() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      await supabase
          .from('subscriptions')
          .update({'cancel_at_period_end': true})
          .eq('user_id', currentUser.id)
          .eq('status', 'active');
    } catch (e) {
      debugPrint('❌ Error canceling subscription: $e');
    }
  }

  /// Resume subscription
  Future<void> resume() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      await supabase
          .from('subscriptions')
          .update({'cancel_at_period_end': false})
          .eq('user_id', currentUser.id)
          .eq('status', 'active');
    } catch (e) {
      debugPrint('❌ Error resuming subscription: $e');
    }
  }

  /// List user's invoices
  Future<List<Map<String, dynamic>>> listInvoices() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return [];

      final response = await supabase
          .from('invoices')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error listing invoices: $e');
      return [];
    }
  }
}
