import 'package:flutter/material.dart';
import '../../theme/theme_index.dart';
import '../../services/subscription/trial_service.dart';
import '../../screens/billing/upgrade_screen.dart';
import 'trial_exit_survey_sheet.dart';

/// Bottom sheet shown when a coach's trial is expiring or has expired.
///
/// Flow:
///   1. "Choose a plan" → UpgradeScreen (IAP/Stripe flow — handled by IAP agents)
///   2. "Downgrade to Free" → if coach > 2 clients, show client selection first
///   3. After selection → exit survey → confirm downgrade
class TrialDowngradeSheet extends StatefulWidget {
  final TrialStatus trialStatus;

  const TrialDowngradeSheet({super.key, required this.trialStatus});

  @override
  State<TrialDowngradeSheet> createState() => _TrialDowngradeSheetState();
}

enum _Step { choosePath, selectClients, processing, done }

class _TrialDowngradeSheetState extends State<TrialDowngradeSheet> {
  _Step _step = _Step.choosePath;
  List<Map<String, dynamic>> _allClients = [];
  final Set<String> _selectedForRemoval = {};
  bool _loadingClients = false;
  String? _error;

  // ── Step 1: path chooser ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: spacing4,
        right: spacing4,
        top: spacing4,
        bottom: MediaQuery.of(context).viewInsets.bottom + spacing4,
      ),
      child: switch (_step) {
        _Step.choosePath => _buildChoosePath(context),
        _Step.selectClients => _buildSelectClients(context),
        _Step.processing => _buildProcessing(),
        _Step.done => _buildDone(context),
      },
    );
  }

  Widget _buildChoosePath(BuildContext context) {
    final days = widget.trialStatus.daysRemaining;
    final expired = widget.trialStatus.phase == TrialPhase.expired;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        const SizedBox(height: spacing3),

        Text(
          expired ? 'Your trial has ended' : 'Trial ends in $days ${days == 1 ? "day" : "days"}',
          style: const TextStyle(
            color: DesignTokens.neutralWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: spacing2),
        Text(
          expired
              ? 'Choose to upgrade and keep Pro, or move to the Free plan.'
              : 'Lock in your Pro access now, or move to Free when the trial ends.',
          style: const TextStyle(
              color: DesignTokens.textSecondary, fontSize: 14),
        ),

        const SizedBox(height: spacing4),

        // Upgrade CTA (primary)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UpgradeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: mintAqua,
              foregroundColor: DesignTokens.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: spacing3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusM)),
            ),
            child: const Text('Choose a plan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: spacing2),

        // Downgrade option (secondary)
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _loadingClients ? null : _startDowngradeFlow,
            child: _loadingClients
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Move to Free plan',
                    style: TextStyle(
                        color: DesignTokens.textSecondary, fontSize: 14)),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: spacing2),
          Text(_error!,
              style: const TextStyle(color: errorRed, fontSize: 13)),
        ],
      ],
    );
  }

  // ── Step 2: client selection ───────────────────────────────────────────────

  Widget _buildSelectClients(BuildContext context) {
    final overLimit = _allClients.length - 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        const SizedBox(height: spacing3),

        const Text('Release some clients first',
            style: TextStyle(
                color: DesignTokens.neutralWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: spacing2),
        Text(
          'The Free plan includes up to 2 clients. '
          'You have ${_allClients.length} — please select $overLimit or more to release before continuing.',
          style: const TextStyle(
              color: DesignTokens.textSecondary, fontSize: 14),
        ),

        const SizedBox(height: spacing3),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _allClients.length,
          itemBuilder: (_, i) {
            final row = _allClients[i];
            final profile = row['profiles'] as Map<String, dynamic>? ?? row;
            final cid = (profile['id'] as String?) ?? (row['client_id'] as String);
            final name = profile['name'] as String? ?? 'Client';
            final email = profile['email'] as String? ?? '';
            final selected = _selectedForRemoval.contains(cid);

            return CheckboxListTile(
              value: selected,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selectedForRemoval.add(cid);
                } else {
                  _selectedForRemoval.remove(cid);
                }
              }),
              title: Text(name,
                  style: const TextStyle(
                      color: DesignTokens.neutralWhite, fontSize: 14)),
              subtitle: email.isNotEmpty
                  ? Text(email,
                      style: const TextStyle(
                          color: DesignTokens.textSecondary, fontSize: 12))
                  : null,
              activeColor: errorRed,
              checkColor: DesignTokens.neutralWhite,
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          },
        ),

        const SizedBox(height: spacing3),

        if (_error != null) ...[
          Text(_error!,
              style: const TextStyle(color: errorRed, fontSize: 13)),
          const SizedBox(height: spacing2),
        ],

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canProceedFromClientSelection ? _showSurvey : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              foregroundColor: DesignTokens.neutralWhite,
              disabledBackgroundColor: errorRed.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: spacing3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusM)),
            ),
            child: Text(
              _selectedForRemoval.isEmpty
                  ? 'Select clients to release'
                  : 'Release ${_selectedForRemoval.length} ${_selectedForRemoval.length == 1 ? "client" : "clients"} & continue',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  bool get _canProceedFromClientSelection =>
      (_allClients.length - _selectedForRemoval.length) <= 2 &&
      _selectedForRemoval.isNotEmpty;

  // ── Processing / done ─────────────────────────────────────────────────────

  Widget _buildProcessing() {
    return const Padding(
      padding: EdgeInsets.all(spacing6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: spacing3),
            Text('Moving you to Free…',
                style: TextStyle(color: DesignTokens.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildDone(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(spacing4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(),
          const SizedBox(height: spacing4),
          const Icon(Icons.check_circle_outline,
              color: mintAqua, size: 48),
          const SizedBox(height: spacing3),
          const Text("You're now on Free",
              style: TextStyle(
                  color: DesignTokens.neutralWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: spacing2),
          const Text(
            'You can upgrade anytime from Billing Settings to get your Pro features back.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: DesignTokens.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: spacing4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: mintAqua,
                foregroundColor: DesignTokens.primaryDark,
              ),
              child: const Text('Got it',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _handle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: DesignTokens.textTertiary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Future<void> _startDowngradeFlow() async {
    setState(() { _loadingClients = true; _error = null; });
    final over = await TrialService.instance.getClientsExceedingFreeLimit();
    setState(() => _loadingClients = false);

    if (over.isEmpty) {
      // Within limit — go straight to survey.
      _showSurvey();
    } else {
      setState(() { _allClients = over; _step = _Step.selectClients; });
    }
  }

  void _showSurvey() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusL)),
      ),
      builder: (_) => TrialExitSurveySheet(onCompleted: _performDowngrade),
    );
  }

  Future<void> _performDowngrade() async {
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst == false || r.settings.name != null);
    setState(() => _step = _Step.processing);

    final ok = await TrialService.instance.downgradeToFree(
      clientIdsToRemove: _selectedForRemoval.toList(),
    );

    if (mounted) {
      if (ok) {
        setState(() => _step = _Step.done);
      } else {
        setState(() {
          _step = _Step.choosePath;
          _error = 'Something went wrong. Please try again.';
        });
      }
    }
  }
}
