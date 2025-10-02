import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// Notification badge widget for displaying notification counts
/// Can be used on navigation items, chat icons, etc.
class NotificationBadge extends StatelessWidget {
  final int count;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.count,
    this.size = 20.0,
    this.backgroundColor,
    this.textColor,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show badge if count is 0 and showZero is false
    if (count <= 0 && !showZero) {
      return const SizedBox.shrink();
    }

    // Use theme colors if not specified
    final badgeColor = backgroundColor ?? Theme.of(context).colorScheme.error;
    final badgeTextColor = textColor ?? Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated notification badge that shows/hides with animation
class AnimatedNotificationBadge extends StatefulWidget {
  final int count;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showZero;
  final Duration animationDuration;

  const AnimatedNotificationBadge({
    super.key,
    required this.count,
    this.size = 20.0,
    this.backgroundColor,
    this.textColor,
    this.showZero = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedNotificationBadge> createState() => _AnimatedNotificationBadgeState();
}

class _AnimatedNotificationBadgeState extends State<AnimatedNotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Start animation if count > 0
    if (widget.count > 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedNotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.count != oldWidget.count) {
      if (widget.count > 0) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: NotificationBadge(
              count: widget.count,
              size: widget.size,
              backgroundColor: widget.backgroundColor,
              textColor: widget.textColor,
              showZero: widget.showZero,
            ),
          ),
        );
      },
    );
  }
}

/// Notification badge that can be positioned over other widgets
class PositionedNotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showZero;
  final Alignment alignment;

  const PositionedNotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.size = 20.0,
    this.backgroundColor,
    this.textColor,
    this.showZero = false,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 0 : null,
          left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 0 : null,
          top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? 0 : null,
          bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? 0 : null,
          child: Transform.translate(
            offset: Offset(
              alignment == Alignment.topRight || alignment == Alignment.bottomRight ? size * 0.3 : -size * 0.3,
              alignment == Alignment.topLeft || alignment == Alignment.topRight ? -size * 0.3 : size * 0.3,
            ),
            child: NotificationBadge(
              count: count,
              size: size,
              backgroundColor: backgroundColor,
              textColor: textColor,
              showZero: showZero,
            ),
          ),
        ),
      ],
    );
  }
}
