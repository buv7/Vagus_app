import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class MealTileCard extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  const MealTileCard({super.key, required this.title, required this.onTap});

  @override
  State<MealTileCard> createState() => _MealTileCardState();
}

class _MealTileCardState extends State<MealTileCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _pulse;
  
  static const _pad = EdgeInsets.all(12);
  static final _r8 = BorderRadius.circular(DesignTokens.radius8);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulse = Tween<double>(begin: 0, end: 2 * math.pi).animate(CurvedAnimation(parent: _c, curve: Curves.linear));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tickerEnabled = TickerMode.of(context);
    if (tickerEnabled && !_c.isAnimating) _c.repeat();
    if (!tickerEnabled && _c.isAnimating) _c.stop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = (math.sin(_pulse.value) + 1) / 2; // 0..1
        final borderColor = Color.lerp(DesignTokens.ink100, DesignTokens.blue500, t)!.withValues(alpha: 0.5);
        return Material(
          color: Theme.of(context).cardColor,
          borderRadius: _r8,
          child: InkWell(
            borderRadius: _r8,
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: _r8,
                border: Border.all(width: 1.5, color: borderColor),
              ),
              padding: _pad,
              child: Center(
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: DesignTokens.ink500),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
