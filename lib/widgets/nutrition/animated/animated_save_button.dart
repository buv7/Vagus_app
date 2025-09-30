import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated save button with loading and success states
class AnimatedSaveButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final String text;

  const AnimatedSaveButton({
    super.key,
    required this.onPressed,
    this.text = 'Save Food',
  });

  @override
  State<AnimatedSaveButton> createState() => _AnimatedSaveButtonState();
}

class _AnimatedSaveButtonState extends State<AnimatedSaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isLoading || _isSuccess) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // Execute the actual save
      await widget.onPressed().catchError((error) {
        throw error;
      });

      if (!mounted) return;

      // Show success animation
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

      unawaited(_controller.forward());
      unawaited(HapticFeedback.heavyImpact());

      // Wait for animation then close
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        unawaited(Navigator.maybePop(context));
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSuccess = false;
      });

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ElevatedButton(
              onPressed: _isLoading || _isSuccess ? null : _handlePress,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSuccess ? Colors.green : const Color(0xFF00D9A3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildButtonChild(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtonChild() {
    if (_isLoading) {
      return const SizedBox(
        key: ValueKey('loading'),
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_isSuccess) {
      return Transform.scale(
        key: const ValueKey('success'),
        scale: _checkAnimation.value,
        child: const Icon(
          Icons.check_circle,
          size: 28,
        ),
      );
    }

    return Text(
      widget.text,
      key: const ValueKey('text'),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}