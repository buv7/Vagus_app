import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Installs a global [ErrorWidget.builder] replacement so widget build errors
/// show a friendly fallback instead of the red-screen-of-death in
/// release/profile builds.  In debug mode the default red screen is preserved
/// so developers see the real stack trace.
void installGlobalErrorBoundary() {
  if (kDebugMode) return;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Fire-and-forget: builder must return synchronously, so we can't await.
    Sentry.captureException(details.exception, stackTrace: details.stack)
        .ignore();
    return const _FallbackWidget();
  };
}

class _FallbackWidget extends StatelessWidget {
  const _FallbackWidget();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Color(0xFF0A0A14),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Color(0xFF0080FF), size: 56),
              SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'We\'ve been notified and are looking into it.\nPlease restart the app.',
                style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that can be placed around subtrees to provide an explicit error
/// state with a friendly fallback.  Call [ErrorBoundary.of(context).reportError]
/// from async operations or [initState] to transition to the fallback UI.
///
/// Unlike React, Flutter does not allow catching build-time child errors at the
/// widget level — use [installGlobalErrorBoundary] for that.  This widget is
/// useful when you need scoped error state (e.g., a screen whose data fetch
/// failed and you want to show an inline retry rather than the global fallback).
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  /// Shown when an error has been reported via [ErrorBoundaryState.reportError].
  final Widget? fallback;

  const ErrorBoundary({super.key, required this.child, this.fallback});

  static ErrorBoundaryState? of(BuildContext context) =>
      context.findAncestorStateOfType<ErrorBoundaryState>();

  @override
  State<ErrorBoundary> createState() => ErrorBoundaryState();
}

class ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  /// Call this to transition the boundary into its error state.  Reports to
  /// Sentry in release/profile; rethrows in debug so the debugger sees it.
  void reportError(Object error, StackTrace stack) {
    if (kDebugMode) {
      Error.throwWithStackTrace(error, stack);
    }
    Sentry.captureException(error, stackTrace: stack);
    if (mounted) setState(() => _error = error);
  }

  void reset() {
    if (mounted) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ??
          _BoundaryFallback(error: _error!, onRetry: reset);
    }
    return widget.child;
  }
}

class _BoundaryFallback extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _BoundaryFallback({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFF0080FF), size: 48),
            const SizedBox(height: 12),
            const Text(
              'Unable to load this section',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'The error has been reported.',
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Color(0xFF0080FF)),
              label: const Text('Retry',
                  style: TextStyle(color: Color(0xFF0080FF))),
            ),
          ],
        ),
      ),
    );
  }
}
