import 'package:flutter/material.dart';
import '../../../../services/nutrition/locale_helper.dart';

/// Wrapper widget that provides i18n context for nutrition screens
/// Features: Automatic locale detection, RTL support, text directionality
class I18nNutritionWrapper extends StatefulWidget {
  final Widget child;
  final String? initialLocale;

  const I18nNutritionWrapper({
    super.key,
    required this.child,
    this.initialLocale,
  });

  @override
  State<I18nNutritionWrapper> createState() => _I18nNutritionWrapperState();

  /// Get current locale from context
  static String localeOf(BuildContext context) {
    final state = context.findAncestorStateOfType<_I18nNutritionWrapperState>();
    return state?._locale ?? 'en';
  }

  /// Update locale
  static void updateLocale(BuildContext context, String newLocale) {
    final state = context.findAncestorStateOfType<_I18nNutritionWrapperState>();
    state?._updateLocale(newLocale);
  }

  /// Translate key using current locale
  static String t(BuildContext context, String key) {
    final locale = localeOf(context);
    return LocaleHelper.t(key, locale);
  }

  /// Check if current locale is RTL
  static bool isRTL(BuildContext context) {
    final locale = localeOf(context);
    return LocaleHelper.isRTL(locale);
  }
}

class _I18nNutritionWrapperState extends State<I18nNutritionWrapper> {
  late String _locale;

  @override
  void initState() {
    super.initState();
    // Initialize with provided locale or detect from system
    _locale = widget.initialLocale ?? _detectSystemLocale();
  }

  String _detectSystemLocale() {
    // Try to detect locale from device settings
    final deviceLocale = WidgetsBinding.instance.window.locale;
    final languageCode = deviceLocale.languageCode;

    // Check if we support this locale
    if (LocaleHelper.getSupportedLanguages().contains(languageCode)) {
      return languageCode;
    }

    // Default to English
    return 'en';
  }

  void _updateLocale(String newLocale) {
    if (LocaleHelper.getSupportedLanguages().contains(newLocale)) {
      setState(() {
        _locale = newLocale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply RTL directionality if needed
    return Directionality(
      textDirection: LocaleHelper.isRTL(_locale)
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: widget.child,
    );
  }
}

/// Extension for easy translation access
extension I18nContext on BuildContext {
  /// Translate a key using current locale from wrapper
  String t(String key) {
    return I18nNutritionWrapper.t(this, key);
  }

  /// Get current locale
  String get locale => I18nNutritionWrapper.localeOf(this);

  /// Check if RTL
  bool get isRTL => I18nNutritionWrapper.isRTL(this);

  /// Update locale
  void updateLocale(String newLocale) {
    I18nNutritionWrapper.updateLocale(this, newLocale);
  }
}

/// Language selector dropdown widget
class LanguageSelectorDropdown extends StatelessWidget {
  final String currentLocale;
  final ValueChanged<String>? onLocaleChanged;

  const LanguageSelectorDropdown({
    super.key,
    required this.currentLocale,
    this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: currentLocale,
      onChanged: (String? newLocale) {
        if (newLocale != null && onLocaleChanged != null) {
          onLocaleChanged!(newLocale);
        }
      },
      items: LocaleHelper.getSupportedLanguages().map((String locale) {
        return DropdownMenuItem<String>(
          value: locale,
          child: Row(
            children: [
              // Flag or locale icon could go here
              const SizedBox(width: 8),
              Text(
                LocaleHelper.getLanguageDisplayName(locale),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Localized text widget that automatically updates on locale change
class LocalizedText extends StatelessWidget {
  final String translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LocalizedText(
    this.translationKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      context.t(translationKey),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Localized number formatter
class LocalizedNumber extends StatelessWidget {
  final num value;
  final int decimalPlaces;
  final TextStyle? style;

  const LocalizedNumber(
    this.value, {
    super.key,
    this.decimalPlaces = 1,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleHelper.formatNumber(value, decimalPlaces: decimalPlaces),
      style: style,
    );
  }
}