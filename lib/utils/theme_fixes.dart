import 'package:flutter/material.dart';

class ThemeFixes {
  static ThemeData fixDarkTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      // Fix chip theme for dark mode
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[800],
        selectedColor: baseTheme.primaryColor.withValues(alpha: 0.3),
        disabledColor: Colors.grey[700],
        labelStyle: const TextStyle(color: Colors.white70),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Fix card theme
      cardTheme: baseTheme.cardTheme.copyWith(
        color: Colors.grey[900],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[800]!),
        ),
      ),

      // Fix input decoration theme
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        fillColor: Colors.grey[900],
        filled: true,
        hintStyle: const TextStyle(color: Colors.white38),
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseTheme.primaryColor, width: 2),
        ),
      ),

      // Fix text theme
      textTheme: baseTheme.textTheme.copyWith(
        bodyLarge: const TextStyle(color: Colors.white),
        bodyMedium: const TextStyle(color: Colors.white70),
        bodySmall: const TextStyle(color: Colors.white60),
      ),
    );
  }

  static ThemeData fixLightTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200],
        selectedColor: baseTheme.primaryColor.withValues(alpha: 0.2),
        disabledColor: Colors.grey[400],
        labelStyle: const TextStyle(color: Colors.black87),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
