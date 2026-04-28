import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ux_mode_provider.dart';
import '../../services/ux/ux_mode_service.dart';

/// Watches [UxModeProvider] for pending promotions or demotion suggestions and
/// shows the appropriate dialog once. Wrap around any subtree that should
/// surface these prompts (typically the app root scaffold).
///
/// Rules:
/// - Never changes mode silently — only prompts.
/// - Shows at most once per threshold crossing.
/// - "Maybe later" snoozes indefinitely (no re-prompt unless mode reloads).
class UxPromotionListener extends StatefulWidget {
  const UxPromotionListener({super.key, required this.child});

  final Widget child;

  @override
  State<UxPromotionListener> createState() => _UxPromotionListenerState();
}

class _UxPromotionListenerState extends State<UxPromotionListener> {
  bool _dialogShowing = false;

  @override
  Widget build(BuildContext context) {
    // Listen for pending promotion or demotion and show the dialog once.
    final provider = context.watch<UxModeProvider>();

    if (!_dialogShowing && provider.isLoaded) {
      if (provider.pendingPromotion != null) {
        _showPromotionDialog(context, provider, provider.pendingPromotion!);
      } else if (provider.pendingDemotion) {
        _showDemotionDialog(context, provider);
      }
    }

    return widget.child;
  }

  void _showPromotionDialog(
    BuildContext context,
    UxModeProvider provider,
    UxMode toMode,
  ) {
    _dialogShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _PromotionDialog(
          fromMode: provider.autoMode,
          toMode: toMode,
        ),
      ).then((accepted) {
        if (!mounted) return;
        provider.dismissPromotion(accepted: accepted ?? false);
        _dialogShowing = false;
      });
    });
  }

  void _showDemotionDialog(BuildContext context, UxModeProvider provider) {
    _dialogShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const _DemotionDialog(),
      ).then((accepted) {
        if (!mounted) return;
        provider.dismissDemotion(accepted: accepted ?? false);
        _dialogShowing = false;
      });
    });
  }
}

// ---------------------------------------------------------------------------
// Internal dialog widgets
// ---------------------------------------------------------------------------

class _PromotionDialog extends StatelessWidget {
  const _PromotionDialog({required this.fromMode, required this.toMode});

  final UxMode fromMode;
  final UxMode toMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _title(toMode),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_body(toMode), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          _ModeChip(mode: toMode),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Maybe later'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Switch to ${toMode.label}'),
        ),
      ],
    );
  }

  String _title(UxMode toMode) {
    switch (toMode) {
      case UxMode.default_:
        return "You're getting the hang of it!";
      case UxMode.insane:
        return "You've unlocked Power Mode!";
      case UxMode.simple:
        return "Interface update available";
    }
  }

  String _body(UxMode toMode) {
    switch (toMode) {
      case UxMode.default_:
        return "Switch to Default for more controls and the full feature set.";
      case UxMode.insane:
        return "You've logged 50+ hours — switch to Insane mode for dense layouts and expert metrics.";
      case UxMode.simple:
        return "A simpler interface is available.";
    }
  }
}

class _DemotionDialog extends StatelessWidget {
  const _DemotionDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Simplify your interface?',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You haven't used advanced features in over 30 days. Would you like to switch to Default mode for a cleaner experience?",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _ModeChip(mode: UxMode.default_),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep Insane'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Switch to Default'),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.mode});

  final UxMode mode;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_icon(mode), size: 16),
      label: Text(
        '${mode.label} — ${mode.description}',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  IconData _icon(UxMode mode) {
    switch (mode) {
      case UxMode.simple:
        return Icons.spa_outlined;
      case UxMode.default_:
        return Icons.tune;
      case UxMode.insane:
        return Icons.bolt;
    }
  }
}
