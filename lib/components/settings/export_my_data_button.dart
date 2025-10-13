import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/theme_index.dart';
import '../../services/core/logger.dart';

/// Button to export all user data (GDPR compliance)
class ExportMyDataButton extends StatefulWidget {
  const ExportMyDataButton({super.key});

  @override
  State<ExportMyDataButton> createState() => _ExportMyDataButtonState();
}

class _ExportMyDataButtonState extends State<ExportMyDataButton> {
  final _supabase = Supabase.instance.client;
  bool _loading = false;

  Future<void> _exportData() async {
    setState(() => _loading = true);

    try {
      Logger.info('Requesting data export');

      // Call the export-user-data edge function
      final response = await _supabase.functions.invoke(
        'export-user-data',
        body: {
          'userId': _supabase.auth.currentUser!.id,
        },
      );

      if (response.status != 200) {
        throw Exception('Export failed: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      final exportUrl = data['url'] as String?;

      if (exportUrl != null && exportUrl.isNotEmpty) {
        // Open the download URL
        final uri = Uri.parse(exportUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ã¢Å“â€¦ Your data export is ready! Download started.'),
              backgroundColor: mintAqua,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        // No URL returned, might be processing
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export requested. You\'ll receive an email when ready.'),
              backgroundColor: mintAqua,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }

      Logger.info('Data export successful');
    } catch (e, st) {
      Logger.error('Data export failed', error: e, stackTrace: st);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(spacing2),
        decoration: BoxDecoration(
          color: mintAqua.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(radiusM),
        ),
        child: const Icon(
          Icons.download,
          color: mintAqua,
        ),
      ),
      title: const Text(
        'Export My Data',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: DesignTokens.neutralWhite,
        ),
      ),
      subtitle: const Text(
        'Download all your data (GDPR)',
        style: TextStyle(
          fontSize: 14,
          color: DesignTokens.textSecondary,
        ),
      ),
      trailing: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(mintAqua),
              ),
            )
          : const Icon(
              Icons.chevron_right,
              color: DesignTokens.textSecondary,
            ),
      onTap: _loading ? null : _exportData,
    );
  }
}


