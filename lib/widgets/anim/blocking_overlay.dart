import 'package:flutter/material.dart';
import 'vagus_loader.dart';
import 'vagus_success.dart';

Future<T> runWithBlockingLoader<T>(
  BuildContext context,
  Future<T> future, {
  bool showSuccess = false,
}) async {
  final overlay = OverlayEntry(
    builder: (_) => Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: const Center(child: VagusLoader(size: 72)),
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(overlay);
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
      Overlay.of(context, rootOverlay: true).insert(ok);
      await Future.delayed(const Duration(milliseconds: 700));
      ok.remove();
    }
    return result;
  } finally {
    if (overlay.mounted) overlay.remove();
  }
}
