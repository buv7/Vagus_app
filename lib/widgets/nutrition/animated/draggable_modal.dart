import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Draggable modal wrapper with swipe-to-dismiss and resistance
class DraggableModal extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDismiss;

  const DraggableModal({
    super.key,
    required this.child,
    this.onDismiss,
  });

  @override
  State<DraggableModal> createState() => _DraggableModalState();
}

class _DraggableModalState extends State<DraggableModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _dragController;
  double _dragOffset = 0.0;

  static const double _dismissThreshold = 150.0;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    HapticFeedback.selectionClick();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Only allow downward dragging with resistance
      final newOffset = _dragOffset + details.delta.dy;
      if (newOffset > 0) {
        // Apply resistance curve for smoother feel
        _dragOffset = newOffset * 0.7;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {

    // Dismiss if dragged far enough or fast enough
    if (_dragOffset > _dismissThreshold ||
        details.velocity.pixelsPerSecond.dy > 500) {
      _dismissModal();
    } else {
      _snapBack();
    }
  }

  void _dismissModal() {
    HapticFeedback.mediumImpact();
    // Animate to fully off-screen
    final animation = Tween<double>(
      begin: _dragOffset,
      end: 400.0,
    ).animate(CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeInCubic,
    ));

    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });

    _dragController.forward().then((_) {
      widget.onDismiss?.call();
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _snapBack() {
    HapticFeedback.lightImpact();
    // Animate back to 0
    final animation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeOutBack,
    ));

    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });

    _dragController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate opacity based on drag offset
    final opacity = (1.0 - (_dragOffset / 300)).clamp(0.0, 1.0);

    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Opacity(
          opacity: opacity,
          child: widget.child,
        ),
      ),
    );
  }
}