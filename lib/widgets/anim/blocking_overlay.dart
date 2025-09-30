import 'package:flutter/material.dart';
import 'vagus_loader.dart';
import 'vagus_success.dart';

Future<T> runWithBlockingLoader<T>(
  BuildContext context,
  Future<T> future, {
  bool showSuccess = false,
}) async {
  final overlayManager = Overlay.of(context, rootOverlay: true);
  final overlay = OverlayEntry(
    builder: (_) => Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: const Center(child: VagusLoader(size: 72)),
    ),
  );
  overlayManager.insert(overlay);
  try {
    final result = await future;
    if (showSuccess) {
      overlay.remove();
      final ok = OverlayEntry(
        builder: (_) => Container(
          color: Colors.black.withValues(alpha: 0.25),
          child: const Center(child: VagusSuccess(size: 84)),
        ),
      );
      try {
        overlayManager.insert(ok);
        await Future.delayed(const Duration(milliseconds: 700));
        if (ok.mounted) {
          ok.remove();
        }
      } catch (_) {
        // Widget disposed, ignore
      }
    }
    return result;
  } finally {
    try {
      if (overlay.mounted) overlay.remove();
    } catch (_) {
      // Already removed or overlay disposed
    }
  }
}
