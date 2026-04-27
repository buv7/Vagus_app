import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';

/// Simple placeholder shown in place of features that are gated off by a
/// feature flag (service not production-ready, mock data, etc.).
///
/// Use either as a full screen (pushed via [Navigator]) or embedded inline.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.featureName,
    this.supportContact = 'support@vagus.app',
    this.showAppBar = true,
  });

  final String featureName;
  final String supportContact;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final body = Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 72,
              color: AppTheme.accentGreen.withValues(alpha: 0.8),
            ),
            const SizedBox(height: DesignTokens.space20),
            Text(
              featureName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DesignTokens.space12),
            const Text(
              'Coming soon',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.accentGreen,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space16),
            const Text(
              "We're still building this feature. If you need it today, "
              'let us know at:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            SelectableText(
              supportContact,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    if (!showAppBar) return body;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.neutralWhite),
        title: Text(
          featureName,
          style: const TextStyle(color: AppTheme.neutralWhite),
        ),
      ),
      body: body,
    );
  }
}
