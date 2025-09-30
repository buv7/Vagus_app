import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated macro input with +/- buttons and pulse effects
class AnimatedMacroInput extends StatefulWidget {
  final TextEditingController controller;
  final String emoji;
  final String label;
  final String unit;
  final Color color;
  final bool enabled;
  final Function(String)? onChanged;

  const AnimatedMacroInput({
    super.key,
    required this.controller,
    required this.emoji,
    required this.label,
    required this.unit,
    required this.color,
    this.enabled = true,
    this.onChanged,
  });

  @override
  State<AnimatedMacroInput> createState() => _AnimatedMacroInputState();
}

class _AnimatedMacroInputState extends State<AnimatedMacroInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _showButtons = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));

    _focusNode.addListener(() {
      setState(() {
        _showButtons = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _incrementValue() {
    final current = double.tryParse(widget.controller.text) ?? 0;
    widget.controller.text = (current + 1).toStringAsFixed(1);
    widget.onChanged?.call(widget.controller.text);
    _animatePulse();
    HapticFeedback.lightImpact();
  }

  void _decrementValue() {
    final current = double.tryParse(widget.controller.text) ?? 0;
    if (current > 0) {
      widget.controller.text = (current - 1).toStringAsFixed(1);
      widget.onChanged?.call(widget.controller.text);
      _animatePulse();
      HapticFeedback.lightImpact();
    }
  }

  void _animatePulse() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  Row(
                    children: [
                      Text(
                        widget.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Input row with +/- buttons
                  Row(
                    children: [
                      // Minus button (animated in)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _showButtons ? 32 : 0,
                        child: _showButtons
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.white54,
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: widget.enabled ? _decrementValue : null,
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Text input
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: TextField(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            enabled: widget.enabled,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: '0',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            onChanged: widget.onChanged,
                          ),
                        ),
                      ),

                      // Unit text
                      Text(
                        widget.unit,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(width: 4),

                      // Plus button (animated in)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _showButtons ? 32 : 0,
                        child: _showButtons
                            ? IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: widget.color,
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: widget.enabled ? _incrementValue : null,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}