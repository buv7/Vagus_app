import 'package:flutter/material.dart';
import 'vagus_logo.dart';

class VagusAppBar extends AppBar {
  VagusAppBar({
    super.key,
    super.leading,
    super.actions,
    super.bottom,
    super.backgroundColor,
    super.foregroundColor,
    Widget? title,
    double? elevation,
    bool? centerTitle,
  }) : super(
          elevation: elevation ?? 0,
          centerTitle: centerTitle ?? true,
          title: title ?? const VagusLogo(size: 28, white: true),
        );
}
