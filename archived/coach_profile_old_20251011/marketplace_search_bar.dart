import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class MarketplaceSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final String hintText;

  const MarketplaceSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.hintText = 'Search coaches...',
  });

  @override
  State<MarketplaceSearchBar> createState() => _MarketplaceSearchBarState();
}

class _MarketplaceSearchBarState extends State<MarketplaceSearchBar> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.glassmorphicDecoration(
        borderRadius: DesignTokens.radius16,
        borderColor: _isFocused 
            ? DesignTokens.accentGreen.withValues(alpha: 0.4)
            : DesignTokens.glassBorder,
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onSearch,
        onTap: () => setState(() => _isFocused = true),
        onTapOutside: (_) => setState(() => _isFocused = false),
        style: DesignTokens.bodyMedium.copyWith(
          color: DesignTokens.neutralWhite,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: DesignTokens.bodyMedium.copyWith(
            color: DesignTokens.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: _isFocused 
                ? DesignTokens.accentGreen 
                : DesignTokens.textSecondary,
            size: 20,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: DesignTokens.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space12,
          ),
          filled: false,
        ),
      ),
    );
  }
}
