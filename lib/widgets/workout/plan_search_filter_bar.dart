import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';

class PlanSearchFilterBar extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;

  const PlanSearchFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: tc.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                style: TextStyle(color: tc.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search plans...',
                  hintStyle: TextStyle(color: tc.textSecondary),
                  prefixIcon: Icon(
                    Icons.search,
                    color: tc.icon,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: tc.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space16,
                    vertical: DesignTokens.space12,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: DesignTokens.space12),
          
          // Filter Button
          Container(
            decoration: BoxDecoration(
              color: tc.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
            child: OutlinedButton.icon(
              onPressed: () {
                // Handle filter
              },
              icon: Icon(
                Icons.filter_list,
                color: tc.icon,
                size: 16,
              ),
              label: Text(
                'Filter',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tc.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space16,
                  vertical: DesignTokens.space12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
