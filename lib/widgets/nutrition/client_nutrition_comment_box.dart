import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isClientView ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isClientView ? Colors.blue.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.isClientView ? Icons.comment : Icons.feedback,
                size: 16,
                color: widget.isClientView ? Colors.blue.shade600 : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                widget.isClientView ? 'Client Comment' : 'Coach Notes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.isClientView ? Colors.blue.shade600 : Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              if (widget.isClientView && !widget.isReadOnly && _hasChanges && widget.onSave != null)
                IconButton(
                  icon: const Icon(Icons.save, size: 16),
                  onPressed: widget.onSave,
                  tooltip: 'Save comment',
                  color: Colors.blue.shade600,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controller,
            enabled: !widget.isReadOnly,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: widget.isClientView 
                  ? 'Add your comment or feedback...'
                  : 'Add notes for the client...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            style: TextStyle(
              fontSize: 14,
              color: widget.isReadOnly ? Colors.grey.shade600 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
