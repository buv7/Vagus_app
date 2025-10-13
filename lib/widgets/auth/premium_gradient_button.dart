import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;

  const PremiumGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  State<PremiumGradientButton> createState() => _PremiumGradientButtonState();
}

class _PremiumGradientButtonState extends State<PremiumGradientButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.enabled || widget.isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) {
          setState(() => _isPressed = true);
          HapticFeedback.lightImpact();
        },
        onTapUp: isDisabled ? null : (_) {
          setState(() => _isPressed = false);
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
        },
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDisabled
                    ? [
                        Colors.grey.withValues(alpha: 0.3),
                        Colors.grey.withValues(alpha: 0.2),
                      ]
                    : const [
                        Color(0xFF00C8FF),
                        Color(0xFF0080FF),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isHovered && !isDisabled
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00C8FF).withValues(alpha: 0.4),
                        blurRadius: 32,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF00C8FF).withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDisabled
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
