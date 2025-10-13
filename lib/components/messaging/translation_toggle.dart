import 'package:flutter/material.dart';
import '../../services/ai/messaging_ai.dart';
import '../../services/config/feature_flags.dart';
import '../../theme/theme_index.dart';

/// Toggle to translate message to user's preferred language
class TranslationToggle extends StatefulWidget {
  final String originalText;
  final String originalLanguage;
  final String targetLanguage;
  final Function(String translatedText) onTranslated;

  const TranslationToggle({
    super.key,
    required this.originalText,
    required this.originalLanguage,
    required this.targetLanguage,
    required this.onTranslated,
  });

  @override
  State<TranslationToggle> createState() => _TranslationToggleState();
}

class _TranslationToggleState extends State<TranslationToggle> {
  final MessagingAI _messagingAI = MessagingAI.instance;
  bool _isTranslated = false;
  bool _loading = false;
  String? _error;
  // ignore: unused_field
  String? _translatedText; // Used in _toggleTranslation setState

  Future<void> _toggleTranslation() async {
    // Check feature flag
    final enabled = await FeatureFlags.instance.isEnabled(
      FeatureFlags.messagingTranslation,
      defaultValue: false,
    );
    
    if (!enabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Translation feature is not available'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_isTranslated) {
      // Toggle back to original
      setState(() {
        _isTranslated = false;
        _error = null;
      });
      return;
    }

    // Translate to target language
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final translated = await _messagingAI.translateMessage(
        text: widget.originalText,
        fromLanguage: widget.originalLanguage,
        toLanguage: widget.targetLanguage,
      );
      
      if (mounted) {
        setState(() {
          _translatedText = translated;
          _isTranslated = true;
          _loading = false;
        });
        widget.onTranslated(translated);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Translation failed';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _loading ? null : _toggleTranslation,
      borderRadius: BorderRadius.circular(radiusL),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: spacing2,
          vertical: spacing1,
        ),
        decoration: BoxDecoration(
          color: _isTranslated
              ? mintAqua.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(radiusL),
          border: Border.all(
            color: _isTranslated
                ? mintAqua
                : steelGrey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(mintAqua),
                ),
              )
            else
              Icon(
                _isTranslated ? Icons.translate : Icons.translate_outlined,
                size: 14,
                color: _isTranslated
                    ? mintAqua
                    : DesignTokens.textSecondary,
              ),
            const SizedBox(width: 4),
            Text(
              _isTranslated ? 'Original' : _getLanguageLabel(widget.targetLanguage),
              style: TextStyle(
                fontSize: 11,
                color: _isTranslated
                    ? mintAqua
                    : DesignTokens.textSecondary,
                fontWeight: _isTranslated ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.error_outline,
                size: 12,
                color: errorRed,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLanguageLabel(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return 'EN';
      case 'ar':
        return 'AR';
      case 'ku':
        return 'KU';
      case 'es':
        return 'ES';
      case 'fr':
        return 'FR';
      default:
        return languageCode.toUpperCase();
    }
  }
}

/// Automatic translation banner
class AutoTranslationBanner extends StatelessWidget {
  final String fromLanguage;
  final String toLanguage;
  final VoidCallback onDismiss;

  const AutoTranslationBanner({
    super.key,
    required this.fromLanguage,
    required this.toLanguage,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: spacing3,
        vertical: spacing2,
      ),
      padding: const EdgeInsets.all(spacing2),
      decoration: BoxDecoration(
        color: mintAqua.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusM),
        border: Border.all(
          color: mintAqua.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.translate,
            size: 16,
            color: mintAqua,
          ),
          const SizedBox(width: spacing2),
          Expanded(
            child: Text(
              'Translated from ${_getLanguageName(fromLanguage)} to ${_getLanguageName(toLanguage)}',
              style: const TextStyle(
                fontSize: 12,
                color: textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code.toLowerCase()) {
      case 'en':
        return 'English';
      case 'ar':
        return 'Arabic';
      case 'ku':
        return 'Kurdish';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      default:
        return code;
    }
  }
}


