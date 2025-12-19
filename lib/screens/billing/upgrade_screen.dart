import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme_index.dart';

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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: DesignTokens.neutralWhite,
          ),
        ),
        SizedBox(height: spacing2),
        Text(
          'Unlock the full power of Vagus with premium features',
          style: TextStyle(
            fontSize: 16,
            color: DesignTokens.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPlanBanner() {
    return Container(
      padding: const EdgeInsets.all(spacing3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            mintAqua.withValues(alpha: 0.2),
            mintAqua.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(radiusM),
        border: Border.all(
          color: mintAqua.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: mintAqua,
            size: 24,
          ),
          const SizedBox(width: spacing2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan: ${_getPlanDisplayName(_currentPlan)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.neutralWhite,
                  ),
                ),
                if (_currentPlan == 'free')
                  const Text(
                    'Upgrade to unlock premium features',
                    style: TextStyle(
                      fontSize: 14,
                      color: DesignTokens.textSecondary,
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
    return Container(
      decoration: BoxDecoration(
        gradient: isPopular
            ? LinearGradient(
                colors: [
                  mintAqua.withValues(alpha: 0.1),
                  DesignTokens.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPopular ? null : DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(radiusL),
        border: Border.all(
          color: isPopular
              ? mintAqua
              : primaryAccent.withValues(alpha: 0.2),
          width: isPopular ? 2 : 1,
        ),
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
              decoration: const BoxDecoration(
                color: mintAqua,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radiusL),
                  bottomRight: Radius.circular(radiusM),
                ),
              ),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.primaryDark,
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.neutralWhite,
                  ),
                ),
                const SizedBox(height: spacing2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: mintAqua,
                      ),
                    ),
                    const SizedBox(width: spacing1),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '/ $period',
                        style: const TextStyle(
                          fontSize: 16,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: spacing4),
                ...features.map((feature) => _buildFeatureItem(feature)),
                const SizedBox(height: spacing4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan
                        ? null
                        : () => _handleUpgrade(planId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? steelGrey
                          : mintAqua,
                      foregroundColor: DesignTokens.primaryDark,
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

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: spacing2),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: mintAqua,
          ),
          const SizedBox(width: spacing2),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 14,
                color: DesignTokens.neutralWhite,
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
    // TODO: Integrate with payment gateway (Stripe, RevenueCat, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upgrade to $planId - Payment integration pending'),
        backgroundColor: mintAqua,
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
