import 'package:flutter/material.dart';

/// Two-step confirmation dialog for destructive actions
/// Requires typing 'CONFIRM' to proceed
class ConfirmationDialogTwoStep extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialogTwoStep({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
  });

  @override
  State<ConfirmationDialogTwoStep> createState() => _ConfirmationDialogTwoStepState();
}

class _ConfirmationDialogTwoStepState extends State<ConfirmationDialogTwoStep> {
  final TextEditingController _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _canConfirm = _controller.text.trim() == 'CONFIRM';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          const Text(
            'This action cannot be undone. To proceed, type CONFIRM below:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Type CONFIRM',
              errorStyle: TextStyle(color: Colors.red),
            ),
            autofocus: true,
            onSubmitted: (_) {
              if (_canConfirm) {
                _handleConfirm();
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onCancel?.call();
            Navigator.of(context).pop();
          },
          child: Text(widget.cancelText),
        ),
        ElevatedButton(
          onPressed: _canConfirm ? _handleConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }

  void _handleConfirm() {
    widget.onConfirm?.call();
    Navigator.of(context).pop();
  }
}
