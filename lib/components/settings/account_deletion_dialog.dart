import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme_index.dart';
import '../../theme/theme_colors.dart';
import '../../services/core/logger.dart';

/// Dialog for requesting account deletion
///
/// Initiates a 72-hour deletion process
class AccountDeletionDialog extends StatefulWidget {
  const AccountDeletionDialog({super.key});

  @override
  State<AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<AccountDeletionDialog> {
  final _reasonController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _loading = false;
  bool _confirmed = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _requestDeletion() async {
    setState(() => _loading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;

      Logger.warning('Account deletion requested', data: {
        'userId': userId,
        'reason': _reasonController.text.trim(),
      });

      // Call database function to create deletion request
      final result = await _supabase.rpc('request_account_deletion', params: {
        'p_user_id': userId,
        'p_reason': _reasonController.text.trim(),
      });

      final requestId = result as String;

      Logger.info('Deletion request created', data: {'requestId': requestId});

      if (mounted) {
        Navigator.of(context).pop(true); // Close dialog with success

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ã¢Å¡Â Ã¯Â¸Â Account deletion requested. You have 72 hours to cancel.',
            ),
            backgroundColor: errorRed,
            duration: Duration(seconds: 8),
          ),
        );
      }
    } catch (e, st) {
      Logger.error('Account deletion request failed', error: e, stackTrace: st);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request deletion: $e'),
            backgroundColor: errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: errorRed,
            size: 28,
          ),
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
              'This action will permanently delete your account and all associated data.',
              style: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: spacing3),
            Container(
              padding: const EdgeInsets.all(spacing3),
              decoration: BoxDecoration(
                color: errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(radiusM),
                border: Border.all(
                  color: errorRed.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What will be deleted:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: spacing2),
                  ...[
                    'Profile information',
                    'Nutrition and workout plans',
                    'Progress photos and metrics',
                    'Messages and conversations',
                    'Files and documents',
                    'Check-ins and coach notes',
                  ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: spacing1),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.close,
                          size: 16,
                          color: errorRed,
                        ),
                        const SizedBox(width: spacing1),
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: spacing3),
            Container(
              padding: const EdgeInsets.all(spacing3),
              decoration: BoxDecoration(
                color: mintAqua.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(radiusM),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: mintAqua,
                    size: 20,
                  ),
                  const SizedBox(width: spacing2),
                  Expanded(
                    child: Text(
                      'You have 72 hours to cancel this request before deletion is processed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: spacing3),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for leaving (optional)',
                hintStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radiusM),
                  borderSide: BorderSide(color: primaryAccent.withValues(alpha: 0.3)),
                ),
              ),
              maxLines: 3,
              style: TextStyle(color: colors.textPrimary),
            ),
            const SizedBox(height: spacing3),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (value) => setState(() => _confirmed = value ?? false),
              title: Text(
                'I understand this action cannot be undone',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: errorRed,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: (_loading || !_confirmed) ? null : _requestDeletion,
          style: ElevatedButton.styleFrom(
            backgroundColor: errorRed,
            foregroundColor: colors.textPrimary,
            disabledBackgroundColor: steelGrey,
          ),
          child: _loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(colors.textPrimary),
                  ),
                )
              : const Text('Delete My Account'),
        ),
      ],
    );
  }
}

/// Helper to show the account deletion dialog
Future<bool?> showAccountDeletionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AccountDeletionDialog(),
  );
}


