import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/common/save_icon.dart';

class ClientNutritionCommentBox extends StatefulWidget {
  final String comment;
  final Function(String) onCommentChanged;
  final bool isReadOnly;
  final bool isClientView;
  final VoidCallback? onSave;

  const ClientNutritionCommentBox({
    super.key,
    required this.comment,
    required this.onCommentChanged,
    this.isReadOnly = false,
    this.isClientView = false,
    this.onSave,
  });

  @override
  State<ClientNutritionCommentBox> createState() => _ClientNutritionCommentBoxState();
}

class _ClientNutritionCommentBoxState extends State<ClientNutritionCommentBox> {
  late TextEditingController _controller;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.comment);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasChanges = _controller.text != widget.comment;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
    widget.onCommentChanged(_controller.text);
  }

  @override
  void didUpdateWidget(ClientNutritionCommentBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment != widget.comment && _controller.text != widget.comment) {
      _controller.text = widget.comment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isClient = widget.isClientView;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isClient
            ? DesignTokens.accentGreen.withValues(alpha: isDark ? 0.1 : 0.08)
            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClient
              ? DesignTokens.accentGreen.withValues(alpha: 0.2)
              : (isDark ? DesignTokens.glassBorder : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isClient ? Icons.comment_rounded : Icons.note_rounded,
                size: 16,
                color: isClient
                    ? DesignTokens.accentGreen
                    : (isDark ? DesignTokens.textSecondary : Colors.grey.shade600),
              ),
              const SizedBox(width: 6),
              Text(
                isClient ? 'Your Comment' : 'Coach Notes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isClient
                      ? DesignTokens.accentGreen
                      : (isDark ? DesignTokens.textSecondary : Colors.grey.shade700),
                ),
              ),
              const Spacer(),
              if (isClient && !widget.isReadOnly && _hasChanges && widget.onSave != null)
                TextButton.icon(
                  onPressed: widget.onSave,
                  icon: SaveIcon(size: 14),
                  label: const Text(
                    'Save',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: DesignTokens.accentGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    backgroundColor: DesignTokens.accentGreen.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controller,
            enabled: !widget.isReadOnly,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: isClient
                  ? 'Add your comment or feedback...'
                  : 'Add notes for the client...',
              hintStyle: TextStyle(
                color: isDark ? DesignTokens.textTertiary : Colors.grey.shade400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            style: TextStyle(
              fontSize: 14,
              color: widget.isReadOnly
                  ? (isDark ? DesignTokens.textSecondary : Colors.grey.shade500)
                  : (isDark ? DesignTokens.neutralWhite : Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
