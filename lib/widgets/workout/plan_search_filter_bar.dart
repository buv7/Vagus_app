import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                style: const TextStyle(color: AppTheme.neutralWhite),
                decoration: InputDecoration(
                  hintText: 'Search plans...',
                  hintStyle: const TextStyle(color: AppTheme.lightGrey),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.lightGrey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.cardBackground,
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
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
            child: OutlinedButton.icon(
              onPressed: () {
                // Handle filter
              },
              icon: const Icon(
                Icons.filter_list,
                color: AppTheme.neutralWhite,
                size: 16,
              ),
              label: const Text(
                'Filter',
                style: TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.steelGrey),
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
