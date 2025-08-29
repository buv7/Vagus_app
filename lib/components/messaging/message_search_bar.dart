import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/design_tokens.dart';

class MessageSearchBar extends StatefulWidget {
  final Function(String) onQuery;
  final VoidCallback onClear;
  final String? initialQuery;
  final List<String> recentSearches;
  final List<String> popularSearches;
  final List<String> personalSuggestions;

  const MessageSearchBar({
    super.key,
    required this.onQuery,
    required this.onClear,
    this.initialQuery,
    this.recentSearches = const [],
    this.popularSearches = const [],
    this.personalSuggestions = const [],
  });

  @override
  State<MessageSearchBar> createState() => _MessageSearchBarState();
}

class _MessageSearchBarState extends State<MessageSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearching = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
      _isSearching = true;
    }
    
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _controller.text.isEmpty;
    });
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    
    setState(() {
      _isSearching = query.isNotEmpty;
      _showSuggestions = _focusNode.hasFocus && query.isEmpty;
    });

    if (query.isEmpty) {
      widget.onClear();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onQuery(query);
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _isSearching = false;
      _showSuggestions = _focusNode.hasFocus;
    });
    widget.onClear();
  }

  void _onSuggestionTapped(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    widget.onQuery(suggestion);
  }

  Widget _buildSuggestions() {
    if (!_showSuggestions) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.space4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.ink900.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recent Searches
          if (widget.recentSearches.isNotEmpty) ...[
            _buildSuggestionSection(
              'Recent Searches',
              widget.recentSearches,
              Icons.history,
              DesignTokens.ink500,
            ),
          ],
          
          // Popular Searches
          if (widget.popularSearches.isNotEmpty) ...[
            _buildSuggestionSection(
              'Popular Searches',
              widget.popularSearches,
              Icons.trending_up,
              DesignTokens.blue600,
            ),
          ],
          
          // Personal Suggestions
          if (widget.personalSuggestions.isNotEmpty) ...[
            _buildSuggestionSection(
              'For You',
              widget.personalSuggestions,
              Icons.person,
              DesignTokens.purple500,
            ),
          ],
          
          // Empty State
          if (widget.recentSearches.isEmpty && 
              widget.popularSearches.isEmpty && 
              widget.personalSuggestions.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(DesignTokens.space16),
              child: Column(
                children: [
                  Icon(
                    Icons.search,
                    size: 32,
                    color: DesignTokens.ink500.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Text(
                    'Start typing to search messages',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: DesignTokens.ink500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionSection(String title, List<String> suggestions, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space16,
            DesignTokens.space12,
            DesignTokens.space16,
            DesignTokens.space8,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: DesignTokens.space8),
              Text(
                title,
                style: DesignTokens.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.ink700,
                ),
              ),
            ],
          ),
        ),
        ...suggestions.map((suggestion) => _buildSuggestionTile(suggestion)),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSuggestionTile(String suggestion) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical: DesignTokens.space4,
      ),
      leading: const Icon(
        Icons.search,
        size: 16,
        color: DesignTokens.ink500,
      ),
      title: Text(
        suggestion,
        style: DesignTokens.bodyMedium.copyWith(
          color: DesignTokens.ink900,
        ),
      ),
      onTap: () => _onSuggestionTapped(suggestion),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16, vertical: DesignTokens.space8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: const Border(
              bottom: BorderSide(
                color: DesignTokens.ink100,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: DesignTokens.ink500,
                    ),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: DesignTokens.ink500,
                            ),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius24),
                      borderSide: const BorderSide(
                        color: DesignTokens.ink100,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius24),
                      borderSide: const BorderSide(
                        color: DesignTokens.ink100,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius24),
                      borderSide: const BorderSide(
                        color: DesignTokens.blue600,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: DesignTokens.ink50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space16,
                      vertical: DesignTokens.space12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildSuggestions(),
      ],
    );
  }
}
