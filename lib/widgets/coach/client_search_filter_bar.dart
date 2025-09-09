import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class ClientSearchFilterBar extends StatelessWidget {
  final String searchQuery;
  final String statusFilter;
  final String sortBy;
  final Function(String) onSearchChanged;
  final Function(String) onStatusFilterChanged;
  final Function(String) onSortChanged;

  const ClientSearchFilterBar({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              style: const TextStyle(color: AppTheme.neutralWhite),
              decoration: InputDecoration(
                hintText: 'Search clients by name or email...',
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
          
          const SizedBox(height: DesignTokens.space16),
          
          // Filter Dropdowns
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  value: statusFilter,
                  items: ['All Status', 'Active', 'Paused', 'Inactive'],
                  onChanged: onStatusFilterChanged,
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: _buildFilterDropdown(
                  value: sortBy,
                  items: ['Name', 'Status', 'Join Date', 'Compliance'],
                  onChanged: onSortChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        style: const TextStyle(color: AppTheme.neutralWhite),
        decoration: InputDecoration(
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
        dropdownColor: AppTheme.cardBackground,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: AppTheme.lightGrey,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(color: AppTheme.neutralWhite),
            ),
          );
        }).toList(),
      ),
    );
  }
}
