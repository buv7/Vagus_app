import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/theme_colors.dart';

/// Theme-aware pill icon widget using SVG asset
/// Automatically adapts to light and dark themes
class PillIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const PillIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    
    // Use provided color, or theme-aware icon color
    final iconColor = color ?? tc.icon;

    return SvgPicture.asset(
      'assets/icons/icon_pill.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        iconColor,
        BlendMode.srcIn,
      ),
    );
  }
}
