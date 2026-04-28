import 'package:flutter/material.dart';

import '../../services/periods_service.dart';
import '../../theme/app_theme.dart';

/// First-use opt-in screen for the period tracking feature.
///
/// MUST be shown before any period data is collected. The user must tap
/// "Enable Period Tracking" to proceed; dismissing the screen without
/// confirming leaves the feature disabled.
///
/// coach_share defaults to false and is a separate checkbox — never pre-checked.
class PeriodConsentScreen extends StatefulWidget {
  final VoidCallback onConsented;
  final VoidCallback? onDeclined;

  const PeriodConsentScreen({
    super.key,
    required this.onConsented,
    this.onDeclined,
  });

  @override
  State<PeriodConsentScreen> createState() => _PeriodConsentScreenState();
}

class _PeriodConsentScreenState extends State<PeriodConsentScreen> {
  final _service = PeriodsService();
  bool _coachShare = false;
  bool _loading = false;

  Future<void> _onEnable() async {
    setState(() => _loading = true);
    try {
      await _service.grantPeriodTrackingConsent(coachShare: _coachShare);
      if (mounted) widget.onConsented();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not enable period tracking: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.primaryDark),
          onPressed: () {
            widget.onDeclined?.call();
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    size: 36,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Track your cycle',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Log your period, symptoms, and notes each day. Vagus uses '
                'your cycle history to predict your next period and help you '
                'train smarter across all four phases.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _SectionHeading('What gets collected'),
              const SizedBox(height: 12),
              _DataPoint(
                icon: Icons.water_drop,
                label: 'Flow level',
                detail: 'None, light, medium, or heavy',
              ),
              _DataPoint(
                icon: Icons.sentiment_dissatisfied_outlined,
                label: 'Symptoms',
                detail: 'Cramps, fatigue, mood, and more',
              ),
              _DataPoint(
                icon: Icons.notes,
                label: 'Notes',
                detail: 'Optional free-text — only you can read it',
              ),
              const SizedBox(height: 28),
              _SectionHeading('How it\'s protected'),
              const SizedBox(height: 12),
              _DataPoint(
                icon: Icons.lock_outline,
                label: 'Encrypted at rest',
                detail: 'Symptoms and notes are encrypted before storage',
              ),
              _DataPoint(
                icon: Icons.visibility_off_outlined,
                label: 'Never used for ads',
                detail: 'Cycle data is never shared with advertisers',
              ),
              _DataPoint(
                icon: Icons.delete_outline,
                label: 'Delete any time',
                detail: 'You can turn off tracking or erase all data in Settings',
              ),
              const SizedBox(height: 28),
              _SectionHeading('Coach access (optional)'),
              const SizedBox(height: 8),
              Text(
                'Your coach cannot see your period data unless you explicitly '
                'allow it here. You can change this at any time.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _coachShare,
                    onChanged: (v) => setState(() => _coachShare = v ?? false),
                    activeColor: AppTheme.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _coachShare = !_coachShare),
                      child: const Text(
                        'Let my coach see my cycle data',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _onEnable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enable Period Tracking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    widget.onDeclined?.call();
                    Navigator.of(context).maybePop();
                  },
                  child: Text(
                    'Not now',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryDark,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _DataPoint extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;

  const _DataPoint({
    required this.icon,
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
