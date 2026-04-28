import 'package:flutter/material.dart';
import '../../theme/theme_index.dart';
import '../../services/subscription/trial_service.dart';

/// Three-question anonymous exit survey shown before confirming downgrade.
/// All three questions are optional; only `reason` is required for a valid submit.
class TrialExitSurveySheet extends StatefulWidget {
  final VoidCallback onCompleted;

  const TrialExitSurveySheet({super.key, required this.onCompleted});

  @override
  State<TrialExitSurveySheet> createState() => _TrialExitSurveySheetState();
}

class _TrialExitSurveySheetState extends State<TrialExitSurveySheet> {
  TrialDowngradeReason? _reason;
  final _whatMissingCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  bool _submitting = false;

  static const _reasons = [
    (TrialDowngradeReason.price, 'Price was too high'),
    (TrialDowngradeReason.featuresMissing, "Features I need aren't there yet"),
    (TrialDowngradeReason.didntFit, "Didn't fit my workflow"),
    (TrialDowngradeReason.other, 'Other'),
  ];

  @override
  void dispose() {
    _whatMissingCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await TrialService.instance.submitExitSurvey(
      reason: _reason ?? TrialDowngradeReason.other,
      whatMissing: _whatMissingCtrl.text.trim().isEmpty
          ? null
          : _whatMissingCtrl.text.trim(),
      otherText:
          _otherCtrl.text.trim().isEmpty ? null : _otherCtrl.text.trim(),
    );
    if (mounted) widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: spacing4,
        right: spacing4,
        top: spacing4,
        bottom: MediaQuery.of(context).viewInsets.bottom + spacing4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: spacing4),
              decoration: BoxDecoration(
                color: DesignTokens.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Q1: reason
          const Text('Before you go — why not upgrading?',
              style: TextStyle(
                  color: DesignTokens.neutralWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: spacing1),
          const Text('Optional · takes 30 seconds · fully anonymous',
              style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12)),
          const SizedBox(height: spacing3),

          ..._reasons.map((r) => RadioListTile<TrialDowngradeReason>(
                value: r.$1,
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                title: Text(r.$2,
                    style: const TextStyle(
                        color: DesignTokens.neutralWhite, fontSize: 14)),
                dense: true,
                activeColor: mintAqua,
                contentPadding: EdgeInsets.zero,
              )),

          const SizedBox(height: spacing3),

          // Q2: what would change your mind
          const Text("What feature would change your mind?",
              style: TextStyle(
                  color: DesignTokens.neutralWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: spacing2),
          _buildTextField(_whatMissingCtrl, 'e.g. video calls, AI meal plans…'),

          const SizedBox(height: spacing3),

          // Q3: other feedback
          const Text('Any other feedback?',
              style: TextStyle(
                  color: DesignTokens.neutralWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: spacing2),
          _buildTextField(_otherCtrl, 'Anything else on your mind…'),

          const SizedBox(height: spacing4),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : widget.onCompleted,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DesignTokens.textSecondary,
                    side: const BorderSide(color: DesignTokens.textTertiary),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: spacing3),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mintAqua,
                    foregroundColor: DesignTokens.primaryDark,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit & Continue',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      maxLines: 2,
      style: const TextStyle(color: DesignTokens.neutralWhite, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: DesignTokens.textTertiary),
        filled: true,
        fillColor: DesignTokens.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: DesignTokens.textTertiary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: DesignTokens.textTertiary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: mintAqua),
        ),
        contentPadding: const EdgeInsets.all(spacing3),
      ),
    );
  }
}
