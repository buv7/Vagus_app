import 'package:flutter/material.dart';
import '../../theme/theme_index.dart';
import '../../services/subscription/trial_service.dart';
import 'trial_downgrade_sheet.dart';

/// Persistent banner shown from day 23 onward (≤ 7 days remaining).
///
/// Place this widget near the top of the coach home scaffold.
/// It self-loads trial status and hides itself when not needed.
class TrialBanner extends StatefulWidget {
  const TrialBanner({super.key});

  @override
  State<TrialBanner> createState() => _TrialBannerState();
}

class _TrialBannerState extends State<TrialBanner> {
  TrialStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await TrialService.instance.getStatus();
    if (mounted) setState(() { _status = status; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final status = _status;
    if (status == null || !status.showBanner) return const SizedBox.shrink();

    final urgent = status.phase == TrialPhase.urgentSoon;
    final accent = urgent ? errorRed : softYellow;
    final days = status.daysRemaining;
    final dayWord = days == 1 ? 'day' : 'days';

    return GestureDetector(
      onTap: () => _openUpgradeOrDowngrade(context, status),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: spacing4, vertical: spacing2),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          border: Border(
            bottom: BorderSide(color: accent.withValues(alpha: 0.4), width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(urgent ? Icons.warning_amber_rounded : Icons.access_time,
                color: accent, size: 18),
            const SizedBox(width: spacing2),
            Expanded(
              child: Text(
                'Your trial ends in $days $dayWord — choose a plan',
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text('See plans →',
                style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _openUpgradeOrDowngrade(BuildContext context, TrialStatus status) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusL)),
      ),
      builder: (_) => TrialDowngradeSheet(trialStatus: status),
    );
  }
}
