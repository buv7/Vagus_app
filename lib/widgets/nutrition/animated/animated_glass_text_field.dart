import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated text field with focus effects and glow
class AnimatedGlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? suffixText;
  final Color? borderColor;
  final TextCapitalization textCapitalization;
  final GlobalKey? fieldKey;

  const AnimatedGlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.onChanged,
    this.suffixText,
    this.borderColor,
    this.textCapitalization = TextCapitalization.none,
    this.fieldKey,
  });

  @override
  State<AnimatedGlassTextField> createState() => _AnimatedGlassTextFieldState();
}

class _AnimatedGlassTextFieldState extends State<AnimatedGlassTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _borderColorAnimation;

  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeOut,
    ));

    _borderColorAnimation = ColorTween(
      begin: widget.borderColor ?? Colors.white.withValues(alpha: 0.1),
      end: const Color(0xFF00D9A3).withValues(alpha: 0.5),
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeOut,
    ));

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });

      if (_isFocused) {
        _focusController.forward();
        HapticFeedback.selectionClick();
      } else {
        _focusController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.fieldKey,
      child: AnimatedBuilder(
        animation: _focusController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D9A3).withValues(alpha: _glowAnimation.value / 100),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                textCapitalization: widget.textCapitalization,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 16,
                  ),
                  prefixIcon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      color: _isFocused
                          ? const Color(0xFF00D9A3)
                          : Colors.white54,
                      size: 20,
                    ),
                  ),
                  suffixText: widget.suffixText,
                  suffixStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _borderColorAnimation.value!,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.borderColor ?? Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _borderColorAnimation.value!,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: widget.onChanged,
              ),
            ),
          );
        },
      ),
    );
  }
}