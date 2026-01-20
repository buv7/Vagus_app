import 'package:flutter/material.dart';
import '../../services/ai/messaging_ai.dart';
import '../../services/config/feature_flags.dart';
import '../../theme/theme_index.dart';
import '../../theme/theme_colors.dart';

/// Smart reply suggestions powered by AI
///
/// Suggests contextual quick replies based on message content
class SmartReplyButtons extends StatefulWidget {
  final String messageContent;
  final Function(String) onReplySelected;
  final bool enabled;

  const SmartReplyButtons({
    super.key,
    required this.messageContent,
    required this.onReplySelected,
    this.enabled = true,
  });

  @override
  State<SmartReplyButtons> createState() => _SmartReplyButtonsState();
}

class _SmartReplyButtonsState extends State<SmartReplyButtons> {
  final MessagingAI _messagingAI = MessagingAI.instance;
  List<String> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    if (!widget.enabled) return;

    // Check feature flag
    final enabled = await FeatureFlags.instance.isEnabled(
      FeatureFlags.messagingSmartReplies,
      defaultValue: false,
    );
    if (!enabled) return;

    setState(() => _loading = true);

    try {
      final suggestions = await _messagingAI.generateSmartReplies(
        widget.messageContent,
        maxSuggestions: 3,
      );
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = _getFallbackReplies();
          _loading = false;
        });
      }
    }
  }

  List<String> _getFallbackReplies() {
    // Simple fallback replies
    return [
      'Thanks!',
      'Got it 👍',
      'Will do!',
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || (_suggestions.isEmpty && !_loading)) {
      return const SizedBox.shrink();
    }

    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: tc.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: mintAqua,
              ),
              const SizedBox(width: spacing1),
              Text(
                'Quick replies',
                style: TextStyle(
                  fontSize: 12,
                  color: tc.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          if (_loading)
            const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(mintAqua),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _suggestions.map((suggestion) {
                return _buildReplyChip(suggestion);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyChip(String text) {
    return Builder(
      builder: (context) {
        final tc = ThemeColors.of(context);
        return InkWell(
          onTap: () => widget.onReplySelected(text),
          borderRadius: BorderRadius.circular(radiusL),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: spacing3,
              vertical: spacing2,
            ),
            decoration: BoxDecoration(
              color: tc.surfaceAlt,
              borderRadius: BorderRadius.circular(radiusL),
              border: Border.all(
                color: mintAqua.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: tc.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}

