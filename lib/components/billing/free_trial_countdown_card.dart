import 'package:flutter/material.dart';
import '../../theme/theme_index.dart';

/// Countdown card showing remaining free trial days
class FreeTrialCountdownCard extends StatefulWidget {
  final DateTime trialEndsAt;
  final VoidCallback onUpgrade;

  const FreeTrialCountdownCard({
    super.key,
    required this.trialEndsAt,
    required this.onUpgrade,
  });

  @override
  State<FreeTrialCountdownCard> createState() => _FreeTrialCountdownCardState();
}

class _FreeTrialCountdownCardState extends State<FreeTrialCountdownCard> {
  int get _daysRemaining {
    final now = DateTime.now();
    final difference = widget.trialEndsAt.difference(now);
    return difference.inDays.clamp(0, 9999);
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = _daysRemaining;
    final isExpiringSoon = daysLeft <= 3;
    final hasExpired = daysLeft == 0;

    return Container(
      margin: const EdgeInsets.all(spacing3),
      padding: const EdgeInsets.all(spacing4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpiringSoon
              ? [
                  errorRed.withValues(alpha: 0.2),
                  errorRed.withValues(alpha: 0.05),
                ]
              : [
                  softYellow.withValues(alpha: 0.2),
                  softYellow.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(radiusL),
        border: Border.all(
          color: isExpiringSoon ? errorRed : softYellow,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(spacing2),
                decoration: BoxDecoration(
                  color: isExpiringSoon 
                      ? errorRed.withValues(alpha: 0.2)
                      : softYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(radiusM),
                ),
                child: Icon(
                  hasExpired ? Icons.lock : Icons.access_time,
                  color: isExpiringSoon ? errorRed : softYellow,
                  size: 32,
                ),
              ),
              const SizedBox(width: spacing3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasExpired ? 'Free Trial Expired' : 'Free Trial',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DesignTokens.neutralWhite,
                      ),
                    ),
                    const SizedBox(height: spacing1),
                    Text(
                      hasExpired
                          ? 'Upgrade to continue using premium features'
                          : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} remaining',
                      style: TextStyle(
                        fontSize: 14,
                        color: isExpiringSoon 
                            ? errorRed 
                            : DesignTokens.textSecondary,
                        fontWeight: isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!hasExpired) ...[
            const SizedBox(height: spacing3),
            ClipRRect(
              borderRadius: BorderRadius.circular(radiusS),
              child: LinearProgressIndicator(
                value: _getProgressValue(),
                minHeight: 8,
                backgroundColor: DesignTokens.cardBackground,
                valueColor: AlwaysStoppedAnimation(
                  isExpiringSoon ? errorRed : mintAqua,
                ),
              ),
            ),
          ],
          const SizedBox(height: spacing3),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: isExpiringSoon 
                    ? errorRed 
                    : mintAqua,
                foregroundColor: DesignTokens.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: spacing3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusM),
                ),
              ),
              child: Text(
                hasExpired ? 'Upgrade Now' : 'Upgrade Early',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getProgressValue() {
    final totalDays = 30; // Assume 30-day trial
    final daysElapsed = totalDays - _daysRemaining;
    return (daysElapsed / totalDays).clamp(0.0, 1.0);
  }
}

/// Coupon data model
class CouponData {
  final String code;
  final int? percentOff;
  final int? amountOffCents;

  CouponData({
    required this.code,
    this.percentOff,
    this.amountOffCents,
  });

  int calculateDiscount(int originalCents) {
    if (percentOff != null) {
      return (originalCents * percentOff! / 100).round();
    } else if (amountOffCents != null) {
      return amountOffCents!;
    }
    return 0;
  }

  int getFinalPrice(int originalCents) {
    final discount = calculateDiscount(originalCents);
    return (originalCents - discount).clamp(0, originalCents);
  }

  String getDiscountLabel() {
    if (percentOff != null) {
      return '$percentOff% OFF';
    } else if (amountOffCents != null) {
      return '\$${(amountOffCents! / 100).toStringAsFixed(2)} OFF';
    }
    return '';
  }
}


