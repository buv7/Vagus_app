import 'dart:math' as math;
import 'dart:ui';
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
        final glowIntensity = t * 0.4 + 0.1; // Animate glow intensity
        return Container(
          decoration: BoxDecoration(
            color: DesignTokens.cardBackground,
            borderRadius: _r8,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentBlue.withValues(alpha: glowIntensity),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: _r8,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: _r8,
                  onTap: widget.onTap,
                  child: Container(
                    padding: _pad,
                    child: Center(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: DesignTokens.titleMedium.copyWith(
                          color: DesignTokens.neutralWhite,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
