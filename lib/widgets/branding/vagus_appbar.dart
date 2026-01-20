import 'package:flutter/material.dart';
import 'dart:ui';
import 'vagus_logo.dart';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';

class VagusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? title;
  final double? elevation;
  final bool? centerTitle;

  const VagusAppBar({
    super.key,
    this.leading,
    this.actions,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.title,
    this.elevation,
    this.centerTitle,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(DesignTokens.radius24),
        bottomRight: Radius.circular(DesignTokens.radius24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DesignTokens.blurSm, sigmaY: DesignTokens.blurSm),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? tc.surface,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(DesignTokens.radius24),
              bottomRight: Radius.circular(DesignTokens.radius24),
            ),
            border: Border(
              bottom: BorderSide(color: tc.border, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentBlue.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: foregroundColor ?? tc.icon,
            centerTitle: centerTitle ?? true,
            leading: leading,
            actions: actions,
            bottom: bottom,
            title: title ?? VagusLogo(size: 28, white: tc.isDark),
            titleTextStyle: TextStyle(
              color: tc.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
