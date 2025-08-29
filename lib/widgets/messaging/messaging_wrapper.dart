import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessagingWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onShowBottomNav;
  final VoidCallback? onHideBottomNav;

  const MessagingWrapper({
    super.key,
    required this.child,
    this.onShowBottomNav,
    this.onHideBottomNav,
  });

  @override
  State<MessagingWrapper> createState() => _MessagingWrapperState();
}

class _MessagingWrapperState extends State<MessagingWrapper> {
  bool _isBottomNavVisible = false;
  double _startY = 0.0;
  double _currentY = 0.0;
  static const double _swipeThreshold = 50.0;
  bool _showSwipeHint = false;

  @override
  void initState() {
    super.initState();
    // Hide bottom nav when entering messaging screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHideBottomNav?.call();
      // Show swipe hint after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isBottomNavVisible) {
          setState(() {
            _showSwipeHint = true;
          });
          // Hide hint after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showSwipeHint = false;
              });
            }
          });
        }
      });
    });
  }

  void _handlePanStart(DragStartDetails details) {
    _startY = details.globalPosition.dy;
    _currentY = _startY;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _currentY = details.globalPosition.dy;
    
    // Calculate swipe distance
    final swipeDistance = _startY - _currentY;
    
    // If swiping up and bottom nav is not visible, show it
    if (swipeDistance > _swipeThreshold && !_isBottomNavVisible) {
      _isBottomNavVisible = true;
      widget.onShowBottomNav?.call();
      HapticFeedback.lightImpact();
    }
    // If swiping down and bottom nav is visible, hide it
    else if (swipeDistance < -_swipeThreshold && _isBottomNavVisible) {
      _isBottomNavVisible = false;
      widget.onHideBottomNav?.call();
      HapticFeedback.lightImpact();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    // Reset swipe tracking
    _startY = 0.0;
    _currentY = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: widget.child,
        ),
        // Swipe hint overlay
        if (_showSwipeHint)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Swipe up to show navigation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
