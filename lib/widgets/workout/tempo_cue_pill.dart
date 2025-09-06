// lib/widgets/workout/tempo_cue_pill.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/haptics.dart';
import '../../utils/tempo_parser.dart';
import '../../services/settings/user_prefs_service.dart';

class TempoCuePill extends StatefulWidget {
  final Tempo tempo;
  final int reps;               // how many reps planned (for haptic loop)
  final bool enableHaptics;     // toggle haptics on/off
  final VoidCallback? onStop;   // callback when sequence finishes
  final bool tempoCuesEnabled;  // global tempo cues preference

  const TempoCuePill({
    super.key,
    required this.tempo,
    this.reps = 1,
    this.enableHaptics = true,
    this.onStop,
    this.tempoCuesEnabled = true,
  });

  @override
  State<TempoCuePill> createState() => _TempoCuePillState();
}

class _TempoCuePillState extends State<TempoCuePill> {
  bool _playing = false;
  int _repIndex = 0;
  Timer? _timer;
  int _phase = 0; // 0=ecc,1=bot,2=con,3=top
  late UserPrefsService _prefsService;
  int _phaseRemaining = 0;

  @override
  void initState() {
    super.initState();
    _prefsService = UserPrefsService.instance;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_playing) return;
    setState(() {
      _playing = true;
      _repIndex = 0;
      _phase = 0;
      _phaseRemaining = _phaseSeconds(0);
    });
    if (widget.enableHaptics) Haptics.selection();
    _tick();
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _playing = false);
    widget.onStop?.call();
  }

  int _phaseSeconds(int phase) {
    switch (phase) {
      case 0: return widget.tempo.eccentric;
      case 1: return widget.tempo.pauseBottom;
      case 2: return widget.tempo.concentric;
      case 3: return widget.tempo.pauseTop;
      default: return 0;
    }
  }

  void _advancePhase() {
    _phase++;
    if (_phase > 3) {
      _phase = 0;
      _repIndex++;
      if (_repIndex >= widget.reps) {
        _stop();
        return;
      }
    }
    _phaseRemaining = _phaseSeconds(_phase);
    if (widget.enableHaptics) {
      // subtle phase marker haptics
      if (_phase == 0) Haptics.selection();       // start eccentric
      else if (_phase == 1) Haptics.tap();        // bottom pause
      else if (_phase == 2) Haptics.selection();  // start concentric
      else if (_phase == 3) Haptics.tap();        // top pause
    }
  }

  void _tick() {
    _timer?.cancel();
    if (_phaseRemaining <= 0) {
      _advancePhase();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_playing) { t.cancel(); return; }
      setState(() => _phaseRemaining--);
      if (_phaseRemaining <= 0) {
        _advancePhase();
      }
    });
  }

  Widget _chip(String label, bool active) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (active ? theme.colorScheme.primary : theme.colorScheme.surface)
            .withValues(alpha: active ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (active ? theme.colorScheme.primary : theme.dividerColor)
              .withValues(alpha: active ? 0.9 : 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active)
            Container(
              width: 6, height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tempo;
    final theme = Theme.of(context);
    
    // Show disabled state if tempo cues are disabled
    if (!widget.tempoCuesEnabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              'Tempo off',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await _prefsService.setTempoCuesEnabled(true);
                if (mounted) setState(() {});
              },
              child: Text(
                'Enable',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _chip('Ecc ${t.eccentric}s', _phase == 0 && _playing),
            _chip('Bot ${t.pauseBottom}s', _phase == 1 && _playing),
            _chip('Con ${t.concentric}s', _phase == 2 && _playing),
            _chip('Top ${t.pauseTop}s', _phase == 3 && _playing),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton(
              onPressed: _playing ? _stop : _start,
              child: Text(_playing ? 'Stop tempo' : 'Play tempo (haptics)'),
            ),
            const SizedBox(width: 8),
            if (_playing)
              Text('Phase: ${_phase+1}/4 • Rep ${_repIndex+1}/${widget.reps}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ],
    );
  }
}
