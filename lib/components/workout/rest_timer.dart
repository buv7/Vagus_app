import 'dart:async';
import 'package:flutter/material.dart';

class RestTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback? onFinish;
  final VoidCallback? onCancel;
  final bool autoStart;
  final String? label;
  final String? nextHint;

  const RestTimer({
    super.key,
    required this.seconds,
    this.onFinish,
    this.onCancel,
    this.autoStart = true,
    this.label,
    this.nextHint,
  });

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _ticker;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    if (widget.autoStart) _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining = (_remaining - 1).clamp(0, 86400);
      });
      if (_remaining <= 0) {
        t.cancel();
        setState(() => _running = false);
        widget.onFinish?.call();
      }
    });
  }

  void _pause() {
    setState(() => _running = false);
    _ticker?.cancel();
  }

  void _resume() {
    if (_running || _remaining <= 0) return;
    _start();
  }

  void _add10() {
    setState(() => _remaining += 10);
  }

  String _format(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: Text(widget.label ?? 'Rest between sets', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text(_format(_remaining), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2)),
            if ((widget.nextHint ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.nextHint!, style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _running ? _pause : _resume,
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running ? 'Pause' : 'Resume'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _add10,
                  icon: const Icon(Icons.add),
                  label: const Text('+10s'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _ticker?.cancel();
                    widget.onCancel?.call();
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
                  child: const Text('Skip'),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}


