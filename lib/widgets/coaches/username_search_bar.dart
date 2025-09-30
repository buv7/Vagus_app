import 'package:flutter/material.dart';
import 'dart:async';
import 'package:vagus_app/theme/design_tokens.dart';

class UsernameSearchBar extends StatefulWidget {
  final Function(String query, bool isUsername) onSearchChanged;
  final String? initialQuery;

  const UsernameSearchBar({
    super.key,
    required this.onSearchChanged,
    this.initialQuery,
  });

  @override
  State<UsernameSearchBar> createState() => _UsernameSearchBarState();
}

class _UsernameSearchBarState extends State<UsernameSearchBar> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = value.trim();
      final isUsername = query.startsWith('@');

      if (isUsername) {
        // Username search - exact match
        widget.onSearchChanged(query.substring(1), true);
      } else if (query.isNotEmpty) {
        // General search
        widget.onSearchChanged(query, false);
      } else {
        // Clear search
        widget.onSearchChanged('', false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.glassmorphicDecoration(
        borderRadius: DesignTokens.radius16,
        backgroundColor: DesignTokens.cardBackground,
      ),
      child: DesignTokens.createBackdropFilter(
        sigmaX: DesignTokens.blurSm,
        sigmaY: DesignTokens.blurSm,
        child: TextField(
          controller: _controller,
          onChanged: _onSearchChanged,
          style: DesignTokens.bodyMedium.copyWith(
            color: DesignTokens.neutralWhite,
          ),
          decoration: InputDecoration(
            hintText: 'Search coaches or @username',
            hintStyle: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.textSecondary,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: DesignTokens.textSecondary,
              size: 20,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: DesignTokens.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      _controller.clear();
                      widget.onSearchChanged('', false);
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space16,
              vertical: DesignTokens.space12,
            ),
          ),
        ),
      ),
    );
  }
}