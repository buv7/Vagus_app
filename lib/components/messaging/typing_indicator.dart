import 'package:flutter/material.dart';
import '../../theme/theme_index.dart';

/// Animated typing indicator showing someone is typing
class TypingIndicator extends StatefulWidget {
  final String? userName;
  final bool isTyping;

  const TypingIndicator({
    super.key,
    this.userName,
    this.isTyping = true,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTyping) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing3,
        vertical: spacing2,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: spacing3,
              vertical: spacing2,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.cardBackground,
              borderRadius: BorderRadius.circular(radiusL),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.userName != null) ...[
                  Text(
                    widget.userName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DesignTokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: spacing2),
                ],
                _AnimatedDots(controller: _controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    // Stagger the animation for each dot
    final delay = index * 0.15;
    final value = (controller.value + delay) % 1.0;
    
    // Create a bounce effect
    final opacity = value < 0.5
        ? value * 2 // Fade in
        : 2 - (value * 2); // Fade out
    
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: mintAqua.withValues(alpha: opacity.clamp(0.3, 1.0)),
      ),
    );
  }
}

/// Simpler static version
class SimpleTypingIndicator extends StatelessWidget {
  const SimpleTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing3,
        vertical: spacing2,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(radiusL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'typing',
            style: TextStyle(
              fontSize: 12,
              color: DesignTokens.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 4),
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mintAqua.withValues(alpha: 0.6),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}


