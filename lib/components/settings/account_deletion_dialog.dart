import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme_index.dart';
import '../../theme/theme_colors.dart';
import '../../services/core/logger.dart';
import '../../services/account_lifecycle_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Deactivate Account Dialog
//
// • Confirms with password only.
// • Schedules a 30-day grace period; user disappears from coach lists.
// • User can restore by signing in and tapping "Cancel deactivation".
// ─────────────────────────────────────────────────────────────────────────────

class DeactivateAccountDialog extends StatefulWidget {
  const DeactivateAccountDialog({super.key});

  @override
  State<DeactivateAccountDialog> createState() => _DeactivateAccountDialogState();
}

class _DeactivateAccountDialogState extends State<DeactivateAccountDialog> {
  final _passwordController = TextEditingController();
  final _service = AccountLifecycleService();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Enter your password to confirm.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      await _service.verifyPassword(_passwordController.text);
      await _service.requestDeactivation();

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account deactivation scheduled. You have 30 days to change your mind.',
            ),
            backgroundColor: DesignTokens.warn,
            duration: Duration(seconds: 8),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = 'Incorrect password. Please try again.');
      Logger.warning('Deactivate: wrong password', data: {'msg': e.message});
    } catch (e, st) {
      Logger.error('Deactivate account failed', error: e, stackTrace: st);
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusL)),
      title: Row(
        children: [
          const Icon(Icons.pause_circle_outline, color: DesignTokens.warn, size: 28),
          const SizedBox(width: spacing2),
          Text(
            'Deactivate Account',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Deactivating hides your profile from coaches and other users for up to 30 days.',
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
            ),
            const SizedBox(height: spacing3),
            _InfoBox(
              color: DesignTokens.warn,
              icon: Icons.info_outline,
              text: 'You have 30 days to sign back in and cancel. '
                  'On day 30, your account and all data will be permanently deleted.',
            ),
            const SizedBox(height: spacing3),
            _PasswordField(
              controller: _passwordController,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              colors: colors,
            ),
            if (_error != null) ...[
              const SizedBox(height: spacing2),
              Text(_error!, style: const TextStyle(color: DesignTokens.danger, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.warn,
            foregroundColor: Colors.black,
            disabledBackgroundColor: DesignTokens.mediumGrey,
          ),
          child: _loading
              ? const _LoadingIndicator(color: Colors.black)
              : const Text('Deactivate My Account'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete Account Dialog
//
// • Confirms with password + typed phrase "DELETE".
// • Schedules a 7-day grace period, then full cascading purge.
// • User can restore by signing in during grace period.
// ─────────────────────────────────────────────────────────────────────────────

class AccountDeletionDialog extends StatefulWidget {
  const AccountDeletionDialog({super.key});

  @override
  State<AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<AccountDeletionDialog> {
  final _passwordController   = TextEditingController();
  final _confirmationController = TextEditingController();
  final _service              = AccountLifecycleService();
  bool _loading  = false;
  bool _obscure  = true;
  String? _error;

  static const _requiredPhrase = 'DELETE';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  bool get _phraseMatch =>
      _confirmationController.text.trim() == _requiredPhrase;

  Future<void> _submit() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Enter your password to confirm.');
      return;
    }
    if (!_phraseMatch) {
      setState(() => _error = 'Type DELETE in capitals to confirm.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      await _service.verifyPassword(_passwordController.text);
      await _service.requestDeletion();

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Deletion scheduled. You have 7 days to sign in and cancel.',
            ),
            backgroundColor: DesignTokens.danger,
            duration: Duration(seconds: 8),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = 'Incorrect password. Please try again.');
      Logger.warning('Delete: wrong password', data: {'msg': e.message});
    } catch (e, st) {
      Logger.error('Delete account failed', error: e, stackTrace: st);
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusL)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: DesignTokens.danger, size: 28),
          const SizedBox(width: spacing2),
          Text(
            'Delete Account',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will permanently delete your account and all associated data after a 7-day grace period.',
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
            ),
            const SizedBox(height: spacing3),
            _DeletionScopeBox(colors: colors),
            const SizedBox(height: spacing3),
            _InfoBox(
              color: mintAqua,
              icon: Icons.info_outline,
              text: 'You have 7 days to sign back in and cancel this request.',
            ),
            const SizedBox(height: spacing3),
            _PasswordField(
              controller: _passwordController,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              colors: colors,
            ),
            const SizedBox(height: spacing3),
            Text(
              'Type DELETE to confirm',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: spacing1),
            TextField(
              controller: _confirmationController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'DELETE',
                hintStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radiusM),
                  borderSide: BorderSide(color: DesignTokens.danger.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radiusM),
                  borderSide: const BorderSide(color: DesignTokens.danger),
                ),
              ),
              style: TextStyle(
                color: _phraseMatch ? DesignTokens.danger : colors.textPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: spacing2),
              Text(_error!, style: const TextStyle(color: DesignTokens.danger, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: (_loading || !_phraseMatch) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.danger,
            foregroundColor: Colors.white,
            disabledBackgroundColor: DesignTokens.mediumGrey,
          ),
          child: _loading
              ? const _LoadingIndicator(color: Colors.white)
              : const Text('Delete My Account'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grace Period Countdown Banner
//
// Show this on the home screen / dashboard immediately after sign-in
// whenever the user has a pending lifecycle action.
// ─────────────────────────────────────────────────────────────────────────────

class AccountGraceCountdownBanner extends StatefulWidget {
  const AccountGraceCountdownBanner({super.key});

  @override
  State<AccountGraceCountdownBanner> createState() =>
      _AccountGraceCountdownBannerState();
}

class _AccountGraceCountdownBannerState
    extends State<AccountGraceCountdownBanner> {
  final _service = AccountLifecycleService();
  AccountLifecycleStatus? _status;
  bool _loading = true;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _service.getStatus();
    if (mounted) setState(() { _status = status; _loading = false; });
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      final cancelled = await _service.restore();
      if (mounted) {
        setState(() { _status = null; _restoring = false; });
        if (cancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been restored.'),
              backgroundColor: DesignTokens.accentGreen,
            ),
          );
        }
      }
    } catch (e, st) {
      Logger.error('Restore account failed', error: e, stackTrace: st);
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _status == null) return const SizedBox.shrink();

    final isDelete = _status!.isDeletion;
    final bannerColor = isDelete ? DesignTokens.danger : DesignTokens.warn;
    final label = isDelete
        ? 'Account deletion in ${_status!.daysRemaining} day${_status!.daysRemaining == 1 ? '' : 's'}'
        : 'Account deactivation in ${_status!.daysRemaining} day${_status!.daysRemaining == 1 ? '' : 's'}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: spacing4, vertical: spacing2),
      padding: const EdgeInsets.all(spacing3),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radiusM),
        border: Border.all(color: bannerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isDelete ? Icons.delete_forever : Icons.pause_circle_outline,
            color: bannerColor,
          ),
          const SizedBox(width: spacing2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: bannerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Tap "Cancel" to keep your account.',
                  style: TextStyle(
                    color: ThemeColors.of(context).textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _restoring
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(bannerColor),
                  ),
                )
              : TextButton(
                  onPressed: _restore,
                  style: TextButton.styleFrom(
                    foregroundColor: bannerColor,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<bool?> showAccountDeletionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AccountDeletionDialog(),
  );
}

Future<bool?> showDeactivateAccountDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const DeactivateAccountDialog(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _InfoBox({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(spacing3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: spacing2),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletionScopeBox extends StatelessWidget {
  final ThemeColors colors;
  const _DeletionScopeBox({required this.colors});

  @override
  Widget build(BuildContext context) {
    const items = [
      'Profile and account information',
      'Messages you sent',
      'Posts and check-ins',
      'Lab work and period data',
      'Progress photos and metrics',
      'Nutrition and workout plans',
      'Files and documents',
    ];

    return Container(
      padding: const EdgeInsets.all(spacing3),
      decoration: BoxDecoration(
        color: DesignTokens.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusM),
        border: Border.all(color: DesignTokens.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permanently deleted:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: spacing2),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: spacing1),
              child: Row(
                children: [
                  const Icon(Icons.close, size: 16, color: DesignTokens.danger),
                  const SizedBox(width: spacing1),
                  Text(item, style: TextStyle(fontSize: 13, color: colors.textPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final ThemeColors colors;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: 'Enter your password',
        hintStyle: TextStyle(color: colors.textSecondary),
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: DesignTokens.accentGreen.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: DesignTokens.accentGreen),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility : Icons.visibility_off,
            color: colors.textSecondary,
            size: 20,
          ),
          onPressed: onToggleObscure,
        ),
      ),
      style: TextStyle(color: colors.textPrimary),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final Color color;
  const _LoadingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
