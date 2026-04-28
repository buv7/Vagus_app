import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';
import '../../services/account_lifecycle_service.dart';
import '../../components/settings/account_deletion_dialog.dart';
import '../../components/settings/export_my_data_button.dart';

/// Settings → Account
///
/// Contains: export data, deactivate account, delete account permanently.
/// Uses the same glassmorphic card style as UserSettingsScreen.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _service = AccountLifecycleService();
  AccountLifecycleStatus? _lifecycleStatus;
  bool _loading = true;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await _service.getStatus();
    if (mounted) setState(() { _lifecycleStatus = status; _loading = false; });
  }

  Future<void> _onDeactivate() async {
    final confirmed = await showDeactivateAccountDialog(context);
    if (confirmed == true) _loadStatus();
  }

  Future<void> _onDelete() async {
    final confirmed = await showAccountDeletionDialog(context);
    if (confirmed == true) _loadStatus();
  }

  Future<void> _onRestore() async {
    setState(() => _restoring = true);
    try {
      final cancelled = await _service.restore();
      if (mounted) {
        await _loadStatus();
        if (cancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been restored.'),
              backgroundColor: DesignTokens.accentGreen,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not restore account. Please try again.'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0B1220),
              DesignTokens.accentBlue.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _AppBar(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(DesignTokens.accentBlue),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(DesignTokens.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── Grace period banner ───
                            if (_lifecycleStatus != null)
                              _GracePeriodCard(
                                status:     _lifecycleStatus!,
                                restoring:  _restoring,
                                onRestore:  _onRestore,
                              ),

                            // ─── Data export ───
                            _SectionCard(
                              icon:  Icons.download,
                              title: 'Your Data',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Download a copy of everything Vagus holds about you.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: DesignTokens.space12),
                                  const ExportMyDataButton(),
                                ],
                              ),
                            ),

                            const SizedBox(height: DesignTokens.space8),

                            // ─── Deactivate / Delete ─── (only when no pending action)
                            if (_lifecycleStatus == null) ...[
                              _SectionCard(
                                icon:  Icons.manage_accounts,
                                title: 'Account Lifecycle',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Deactivating hides your profile for up to 30 days. '
                                      'Permanent deletion is irreversible after a 7-day grace period.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: DesignTokens.space16),
                                    _ActionButton(
                                      icon:    Icons.pause_circle_outline,
                                      label:   'Deactivate Account',
                                      color:   DesignTokens.warn,
                                      onTap:   _onDeactivate,
                                    ),
                                    const SizedBox(height: DesignTokens.space12),
                                    _ActionButton(
                                      icon:    Icons.delete_forever,
                                      label:   'Delete Account Permanently',
                                      color:   DesignTokens.danger,
                                      onTap:   _onDelete,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grace Period Card
// ─────────────────────────────────────────────────────────────────────────────

class _GracePeriodCard extends StatelessWidget {
  final AccountLifecycleStatus status;
  final bool restoring;
  final VoidCallback onRestore;

  const _GracePeriodCard({
    required this.status,
    required this.restoring,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isDelete  = status.isDeletion;
    final accent    = isDelete ? DesignTokens.danger : DesignTokens.warn;
    final days      = status.daysRemaining;
    final noun      = isDelete ? 'deletion' : 'deactivation';
    final dayLabel  = days == 1 ? '1 day' : '$days days';

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDelete ? Icons.delete_forever : Icons.pause_circle_outline,
                color: accent,
                size: 22,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                'Account $noun in $dayLabel',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            isDelete
                ? 'Your account and all data will be permanently deleted in $dayLabel. Tap below to cancel.'
                : 'Your profile is hidden. Your account will be deleted in $dayLabel unless you cancel.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: DesignTokens.space12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: restoring ? null : onRestore,
              icon: restoring
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.undo),
              label: Text('Cancel ${isDelete ? 'Deletion' : 'Deactivation'}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDelete ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(DesignTokens.space16),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical:   DesignTokens.space12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 2.0,
          colors: [
            DesignTokens.accentBlue.withValues(alpha: 0.25),
            DesignTokens.accentBlue.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: DesignTokens.accentBlue.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DesignTokens.accentBlue.withValues(alpha: 0.2),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Text(
              'Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 2.0,
          colors: [
            DesignTokens.accentBlue.withValues(alpha: 0.25),
            DesignTokens.accentBlue.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: DesignTokens.accentBlue.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: DesignTokens.space12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: color.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
        ),
      ),
    );
  }
}
