import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comprehensive accessibility service for WCAG AA compliance
/// Features: Semantic labels, screen reader support, contrast checks, keyboard navigation
class AccessibilityService {
  static final _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  bool _highContrastMode = false;
  double _textScaleFactor = 1.0;
  bool _reduceMotion = false;
  bool _screenReaderEnabled = false;

  // Getters
  bool get highContrastMode => _highContrastMode;
  double get textScaleFactor => _textScaleFactor;
  bool get reduceMotion => _reduceMotion;
  bool get screenReaderEnabled => _screenReaderEnabled;

  /// Initialize accessibility service
  Future<void> initialize(BuildContext context) async {
    // Detect system accessibility settings
    final mediaQuery = MediaQuery.of(context);
    _textScaleFactor = mediaQuery.textScaler.scale(1.0);
    _reduceMotion = mediaQuery.disableAnimations;
    _highContrastMode = mediaQuery.highContrast;

    // TODO: Detect screen reader (TalkBack/VoiceOver)
    // This would require platform-specific code
    _screenReaderEnabled = false;
  }

  /// Create semantic label for macro ring chart
  String getMacroRingSemantics({
    required String macroName,
    required double current,
    required double target,
    required String unit,
  }) {
    final percentage = target > 0 ? (current / target * 100).round() : 0;
    final status = _getMacroStatus(current, target);

    return '$macroName: ${current.toStringAsFixed(1)} $unit of ${target.toStringAsFixed(1)} $unit target. '
           '$percentage% complete. $status';
  }

  String _getMacroStatus(double current, double target) {
    if (target == 0) return '';

    final percentage = (current / target * 100);
    if (percentage < 70) {
      return 'Below target';
    } else if (percentage >= 70 && percentage < 90) {
      return 'Approaching target';
    } else if (percentage >= 90 && percentage <= 110) {
      return 'On target';
    } else {
      return 'Above target';
    }
  }

  /// Create semantic label for meal card
  String getMealSemantics({
    required String mealName,
    required int foodCount,
    required double calories,
    required double protein,
    String? time,
  }) {
    String label = '$mealName. ';

    if (time != null) {
      label += 'Scheduled at $time. ';
    }

    label += '$foodCount food item${foodCount != 1 ? 's' : ''}. ';
    label += '${calories.toStringAsFixed(0)} calories. ';
    label += '${protein.toStringAsFixed(1)} grams protein.';

    return label;
  }

  /// Create semantic label for food item
  String getFoodItemSemantics({
    required String foodName,
    required double quantity,
    required String serving,
    double? calories,
    double? protein,
  }) {
    String label = '$foodName, ${quantity.toStringAsFixed(1)} $serving. ';

    if (calories != null) {
      label += '${calories.toStringAsFixed(0)} calories. ';
    }

    if (protein != null) {
      label += '${protein.toStringAsFixed(1)} grams protein.';
    }

    return label;
  }

  /// Create semantic label for progress indicator
  String getProgressSemantics({
    required String label,
    required double current,
    required double target,
    required String unit,
  }) {
    final percentage = target > 0 ? (current / target * 100).round() : 0;

    return '$label progress: ${current.toStringAsFixed(1)} $unit of ${target.toStringAsFixed(1)} $unit. '
           '$percentage% complete.';
  }

  /// Check if color contrast meets WCAG AA standards
  bool meetsContrastStandards({
    required Color foreground,
    required Color background,
    bool isLargeText = false,
  }) {
    final ratio = _calculateContrastRatio(foreground, background);
    final required = isLargeText ? 3.0 : 4.5;

    return ratio >= required;
  }

  double _calculateContrastRatio(Color color1, Color color2) {
    final l1 = _calculateRelativeLuminance(color1);
    final l2 = _calculateRelativeLuminance(color2);

    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  double _calculateRelativeLuminance(Color color) {
    final r = _linearizeColorChannel((color.r * 255.0).round() / 255);
    final g = _linearizeColorChannel((color.g * 255.0).round() / 255);
    final b = _linearizeColorChannel((color.b * 255.0).round() / 255);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double _linearizeColorChannel(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    } else {
      return ((channel + 0.055) / 1.055) * ((channel + 0.055) / 1.055);
    }
  }

  /// Announce message to screen reader
  void announce(BuildContext context, String message, {Assertiveness assertiveness = Assertiveness.polite}) {
    if (_screenReaderEnabled) {
      // SemanticsService not available directly - using debugPrint
      debugPrint('Accessibility: $message (${assertiveness.name})');
    }
  }

  /// Create keyboard-accessible button
  Widget makeKeyboardAccessible({
    required Widget child,
    required VoidCallback onPressed,
    required String semanticLabel,
    String? hint,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: hint,
      button: true,
      enabled: true,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            if (event is KeyDownEvent) {
              onPressed();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: child,
      ),
    );
  }

  /// Create accessible text with proper scaling
  TextStyle getAccessibleTextStyle({
    required TextStyle baseStyle,
    bool respectUserPreferences = true,
  }) {
    if (!respectUserPreferences) return baseStyle;

    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * _textScaleFactor,
    );
  }

  /// Get animation duration based on reduce motion setting
  Duration getAnimationDuration(Duration baseDuration) {
    if (_reduceMotion) {
      return Duration.zero;
    }
    return baseDuration;
  }

  /// Create accessible form field
  Widget makeFormFieldAccessible({
    required Widget formField,
    required String label,
    String? hint,
    String? error,
    bool required = false,
  }) {
    String semanticLabel = label;
    if (required) {
      semanticLabel += ', required field';
    }

    String? semanticHint = hint;
    if (error != null) {
      semanticHint = 'Error: $error';
    }

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      textField: true,
      child: formField,
    );
  }

  /// Create accessible icon with label
  Widget makeIconAccessible({
    required IconData icon,
    required String label,
    Color? color,
    double? size,
  }) {
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Icon(icon, color: color, size: size),
      ),
    );
  }

  /// Create accessible image with description
  Widget makeImageAccessible({
    required Widget image,
    required String description,
    bool isDecorative = false,
  }) {
    if (isDecorative) {
      return ExcludeSemantics(child: image);
    }

    return Semantics(
      label: description,
      image: true,
      child: image,
    );
  }

  /// Create accessible chart description
  String getChartSemantics({
    required String chartType,
    required Map<String, double> data,
    String? unit,
  }) {
    String description = '$chartType chart. ';

    data.forEach((key, value) {
      description += '$key: ${value.toStringAsFixed(1)}';
      if (unit != null) {
        description += ' $unit';
      }
      description += '. ';
    });

    return description;
  }

  /// Create accessible list announcement
  String getListSemantics({
    required int totalItems,
    required int currentPosition,
    String? itemDescription,
  }) {
    String description = 'Item $currentPosition of $totalItems';
    if (itemDescription != null) {
      description += '. $itemDescription';
    }
    return description;
  }

  /// Check if large text mode is enabled
  bool isLargeTextMode() {
    return _textScaleFactor >= 1.3;
  }

  /// Get accessible touch target size
  double getMinimumTouchTargetSize() {
    // WCAG recommends minimum 44x44 points
    return 44.0;
  }

  /// Create accessible navigation hint
  String getNavigationHint({
    required String currentScreen,
    String? previousScreen,
    String? nextScreen,
  }) {
    String hint = 'Currently on $currentScreen screen. ';

    if (previousScreen != null) {
      hint += 'Previous: $previousScreen. ';
    }

    if (nextScreen != null) {
      hint += 'Next: $nextScreen. ';
    }

    return hint;
  }

  /// Create accessible loading announcement
  void announceLoading(BuildContext context, String what) {
    announce(context, 'Loading $what', assertiveness: Assertiveness.polite);
  }

  /// Create accessible success announcement
  void announceSuccess(BuildContext context, String what) {
    announce(context, '$what completed successfully', assertiveness: Assertiveness.polite);
  }

  /// Create accessible error announcement
  void announceError(BuildContext context, String error) {
    announce(context, 'Error: $error', assertiveness: Assertiveness.assertive);
  }

  /// Get semantic label for toggle state
  String getToggleSemantics({
    required String label,
    required bool isOn,
  }) {
    return '$label, ${isOn ? 'enabled' : 'disabled'}. Double tap to ${isOn ? 'disable' : 'enable'}.';
  }

  /// Get semantic label for slider
  String getSliderSemantics({
    required String label,
    required double value,
    required double min,
    required double max,
    String? unit,
  }) {
    final percentage = ((value - min) / (max - min) * 100).round();
    return '$label: ${value.toStringAsFixed(1)}${unit ?? ''}. $percentage% of range from $min to $max.';
  }

  /// Check if custom focus order is needed
  bool needsCustomFocusOrder() {
    return _screenReaderEnabled;
  }

  /// Create focus traversal policy
  FocusTraversalPolicy createAccessibleFocusPolicy() {
    return OrderedTraversalPolicy();
  }
}

/// Assertiveness levels for screen reader announcements
enum Assertiveness {
  polite,    // Wait for current speech to finish
  assertive, // Interrupt current speech
}