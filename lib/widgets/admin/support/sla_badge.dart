import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/admin/admin_support_service.dart';
import '../../../theme/design_tokens.dart';

class SlaBadge extends StatefulWidget {
  final String ticketId;
  const SlaBadge({super.key, required this.ticketId});

  @override
  State<SlaBadge> createState() => _SlaBadgeState();
}

class _SlaBadgeState extends State<SlaBadge> {
  SlaSnapshot? _snap;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await AdminSupportService.instance.getSlaSnapshot(widget.ticketId);
    if (!mounted) return;
    setState(() => _snap = s);
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _snap == null) return;
      final now = DateTime.now();
      final remaining = _snap!.deadline.difference(now);
      setState(() {
        _snap = SlaSnapshot(
          now: now,
          deadline: _snap!.deadline,
          breached: remaining.isNegative,
          remaining: remaining.isNegative ? Duration.zero : remaining,
          policyName: _snap!.policyName,
          severity: _snap!.severity,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _snap;
    if (s == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha:.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(children: [SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:2)), SizedBox(width:8), Text('SLA')]),
      );
    }

    final secs = s.remaining.inSeconds;
    final mins = (secs ~/ 60).clamp(0, 9999);
    final sec = (secs % 60).clamp(0, 59);

    // threshold colors
    Color tint;
    if (s.breached) {
      tint = Colors.red;
    } else if (s.remaining <= const Duration(minutes: 5)) {
      tint = Colors.deepOrange;
    } else if (s.remaining <= const Duration(minutes: 15)) {
      tint = Colors.orange;
    } else {
      tint = Colors.green;
    }

    // subtle pulse near breach
    final t = DateTime.now().millisecond / 1000.0;
    final pulse = s.breached ? (0.5 + 0.5*math.sin(t*6.28)).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: tint.withValues(alpha: s.breached ? .14 + .2*pulse : .12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(s.breached ? Icons.timer_off : Icons.timer, size: 16, color: tint),
                const SizedBox(width: 6),
                Text(
                  s.breached ? 'Breached' : '${mins.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: tint),
                ),
                const SizedBox(width: 6),
                Text(s.policyName, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha:.6))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
