import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme_index.dart';
import '../../theme/theme_colors.dart';

/// Upgrade screen showing available subscription plans
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  String _currentPlan = 'free';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    setState(() => _loading = true);
    try {
      // Get user's current subscription plan from database
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final result = await Supabase.instance.client.rpc('get_user_plan', params: {'p_user_id': userId});
        final plan = result as String? ?? 'free';
        if (mounted) {
          setState(() {
            _currentPlan = plan;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Upgrade Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(mintAqua),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(spacing4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: spacing4),
                  _buildCurrentPlanBanner(),
                  const SizedBox(height: spacing4),
                  _buildPlanCard(
                    title: 'Free',
                    price: '\$0',
                    period: 'forever',
                    features: [
                      'Basic nutrition tracking',
                      'Basic workout tracking',
                      'Limited AI requests (10/month)',
                      'Community support',
                    ],
                    isCurrentPlan: _currentPlan == 'free',
                    planId: 'free',
                  ),
                  const SizedBox(height: spacing3),
                  _buildPlanCard(
                    title: 'Premium Client',
                    price: '\$9.99',
                    period: 'month',
                    features: [
                      'Unlimited nutrition & workout tracking',
                      'AI meal plan generation (100/month)',
                      'Progress analytics & insights',
                      'Coach messaging',
                      'File attachments',
                      'Priority support',
                    ],
                    isCurrentPlan: _currentPlan == 'premium_client',
                    planId: 'premium_client',
                    isPopular: true,
                  ),
                  const SizedBox(height: spacing3),
                  _buildPlanCard(
                    title: 'Premium Coach',
                    price: '\$19.99',
                    period: 'month',
                    features: [
                      'Everything in Premium Client',
                      'Unlimited clients',
                      'AI workout generation (unlimited)',
                      'Advanced analytics dashboard',
                      'Client management tools',
                      'Coach marketplace profile',
                      'White-label branding',
                      'API access',
                    ],
                    isCurrentPlan: _currentPlan == 'premium_coach',
                    planId: 'premium_coach',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final tc = context.tc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: tc.textPrimary,
          ),
        ),
        const SizedBox(height: spacing2),
        Text(
          'Unlock the full power of Vagus with premium features',
          style: TextStyle(
            fontSize: 16,
            color: tc.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPlanBanner() {
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.all(spacing3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tc.accent.withValues(alpha: 0.2),
            tc.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(radiusM),
        border: Border.all(
          color: tc.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: tc.accent,
            size: 24,
          ),
          const SizedBox(width: spacing2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan: ${_getPlanDisplayName(_currentPlan)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tc.textPrimary,
                  ),
                ),
                if (_currentPlan == 'free')
                  Text(
                    'Upgrade to unlock premium features',
                    style: TextStyle(
                      fontSize: 14,
                      color: tc.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool isCurrentPlan,
    required String planId,
    bool isPopular = false,
  }) {
    final tc = context.tc;
    
    // Popular card uses premium gradient, otherwise regular surface
    return Container(
      decoration: isPopular 
          ? tc.premiumCardDecoration
          : BoxDecoration(
              color: tc.surface,
              borderRadius: BorderRadius.circular(radiusL),
              border: Border.all(
                color: tc.border,
                width: 1,
              ),
              boxShadow: tc.cardShadow,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: spacing2,
                vertical: spacing1,
              ),
              decoration: BoxDecoration(
                color: tc.accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(radiusL),
                  bottomRight: Radius.circular(radiusM),
                ),
              ),
              child: Text(
                'MOST POPULAR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: tc.textOnDark,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(spacing4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    // On premium gradient: use dark text, otherwise theme text
                    color: isPopular ? tc.textOnGradient : tc.textPrimary,
                  ),
                ),
                const SizedBox(height: spacing2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isPopular ? tc.textOnGradient : tc.accent,
                      ),
                    ),
                    const SizedBox(width: spacing1),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '/ $period',
                        style: TextStyle(
                          fontSize: 16,
                          color: isPopular ? tc.textOnGradientSecondary : tc.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: spacing4),
                ...features.map((f) => _buildFeatureItem(f, isPopular: isPopular)),
                const SizedBox(height: spacing4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan
                        ? null
                        : () => _handleUpgrade(planId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? tc.textDisabled
                          : (isPopular ? tc.buttonOnGradient : tc.accent),
                      foregroundColor: isCurrentPlan 
                          ? tc.textSecondary
                          : (isPopular ? tc.buttonTextOnGradient : tc.textOnDark),
                      padding: const EdgeInsets.symmetric(
                        vertical: spacing3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(radiusM),
                      ),
                    ),
                    child: Text(
                      isCurrentPlan ? 'Current Plan' : 'Upgrade Now',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature, {bool isPopular = false}) {
    final tc = context.tc;
    return Padding(
      padding: const EdgeInsets.only(bottom: spacing2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: isPopular ? tc.iconOnGradient : tc.accent,
          ),
          const SizedBox(width: spacing2),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 14,
                color: isPopular ? tc.textOnGradient : tc.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlanDisplayName(String planId) {
    switch (planId) {
      case 'free':
        return 'Free';
      case 'premium_client':
        return 'Premium Client';
      case 'premium_coach':
        return 'Premium Coach';
      default:
        return planId;
    }
  }

  Future<void> _handleUpgrade(String planId) async {
    final tc = context.tc;
    // TODO: Integrate with payment gateway (Stripe, RevenueCat, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upgrade to $planId - Payment integration pending'),
        backgroundColor: tc.accent,
      ),
    );

    // For now, just show success message
    // In production, this would:
    // 1. Navigate to payment screen
    // 2. Process payment
    // 3. Update subscription in database
    // 4. Grant access via PlanAccessManager
  }
}
