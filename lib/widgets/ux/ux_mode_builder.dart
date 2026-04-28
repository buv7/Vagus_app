import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/ux_mode_provider.dart';
import '../../services/ux/ux_mode_service.dart';

export '../../services/ux/ux_mode_service.dart' show UxMode, UxModeOps;
export '../../providers/ux_mode_provider.dart' show UxModeProvider;

/// Renders [child] only when the current UX mode is >= [minMode].
/// Falls back to [fallback] (default: invisible SizedBox) otherwise.
///
/// Usage:
/// ```dart
/// UxModeBuilder(
///   minMode: UxMode.default_,
///   child: AdvancedMetricsCard(),
/// )
/// ```
class UxModeBuilder extends StatelessWidget {
  const UxModeBuilder({
    super.key,
    required this.minMode,
    required this.child,
    this.fallback,
  });

  final UxMode minMode;
  final Widget child;

  /// Shown when the mode requirement is not met. Defaults to SizedBox.shrink().
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<UxModeProvider>().mode;
    if (mode >= minMode) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

/// Renders [simpleChild], [defaultChild], or [insaneChild] depending on
/// the current mode, falling back to the nearest simpler variant when
/// a higher-tier widget is not provided.
class UxModeSwitch extends StatelessWidget {
  const UxModeSwitch({
    super.key,
    required this.simpleChild,
    this.defaultChild,
    this.insaneChild,
  });

  final Widget simpleChild;
  final Widget? defaultChild;
  final Widget? insaneChild;

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<UxModeProvider>().mode;
    switch (mode) {
      case UxMode.insane:
        return insaneChild ?? defaultChild ?? simpleChild;
      case UxMode.default_:
        return defaultChild ?? simpleChild;
      case UxMode.simple:
        return simpleChild;
    }
  }
}

/// Convenience extension to read the current UX mode from any BuildContext.
extension UxModeContext on BuildContext {
  UxMode get uxMode => watch<UxModeProvider>().mode;
  UxMode get uxModeRead => read<UxModeProvider>().mode;
}
