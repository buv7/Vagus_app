// lib/components/workout/rest_timer_inline.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/haptics.dart';

class RestTimerInline extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onComplete;

  const RestTimerInline({
    super.key,
    required this.initialSeconds,
    this.onComplete,
  });

  @override
  State<RestTimerInline> createState() => _RestTimerInlineState();
}

class _RestTimerInlineState extends State<RestTimerInline> {
  late int _remaining;
  bool _running = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_running) return;
      setState(() => _remaining--);
      if (_remaining <= 3 && _remaining > 0) {
        Haptics.selection(); // countdown cues
      }
      if (_remaining <= 0) {
        Haptics.success();
        widget.onComplete?.call();
        t.cancel();
        _running = false;
      }
    });
  }

  void _pause() {
    setState(() => _running = false);
  }

  void _resume() {
    setState(() => _running = true);
  }

  void _add10() {
    setState(() => _remaining += 10);
  }

  void _skip() {
    setState(() => _remaining = 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = Duration(seconds: _remaining);
    final mm = m.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = m.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text('$mm:$ss', style: theme.textTheme.titleLarge),
          const Spacer(),
          IconButton(
            tooltip: _running ? 'Pause' : 'Resume',
            onPressed: _running ? _pause : _resume,
            icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
          IconButton(
            tooltip: '+10s',
            onPressed: _add10,
            icon: const Icon(Icons.add_rounded),
          ),
          IconButton(
            tooltip: 'Skip',
            onPressed: _skip,
            icon: const Icon(Icons.skip_next_rounded),
          ),
        ],
      ),
    );
  }
}
