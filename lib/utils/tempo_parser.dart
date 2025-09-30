// lib/utils/tempo_parser.dart
import 'package:flutter/foundation.dart';

@immutable
class Tempo {
  final int eccentric;      // down
  final int pauseBottom;    // bottom pause
  final int concentric;     // up
  final int pauseTop;       // top pause

  const Tempo(this.eccentric, this.pauseBottom, this.concentric, this.pauseTop);

  int get singleRepSeconds => eccentric + pauseBottom + concentric + pauseTop;

  static Tempo? parseFromString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final s = raw.toLowerCase();
    // Extract if present inside notes as "tempo: 3-1-1-0" (or similar)
    final tempoLine = RegExp(r'tempo\s*:\s*([0-9:\- ]{3,})').firstMatch(s)?.group(1) ?? s;

    final String digitsOnly = tempoLine.replaceAll(RegExp(r'[^0-9]'), '');
    // Accept "3110" form
    if (digitsOnly.length == 4) {
      final a = int.tryParse(digitsOnly[0]);
      final b = int.tryParse(digitsOnly[1]);
      final c = int.tryParse(digitsOnly[2]);
      final d = int.tryParse(digitsOnly[3]);
      if ([a,b,c,d].every((e) => e != null)) return Tempo(a!, b!, c!, d!);
    }

    // Accept "3-1-1-0" or "3:1:1:0"
    final parts = tempoLine.split(RegExp(r'[\-:\s]+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 4) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);
      final d = int.tryParse(parts[3]);
      if ([a,b,c,d].every((e) => e != null)) return Tempo(a!, b!, c!, d!);
    }

    return null;
  }

  static Tempo? fromExercise(Map<String, dynamic> exercise) {
    // Prefer explicit field if present, else parse from notes
    final explicit = exercise['tempo'] as String?;
    final notes = exercise['notes'] as String?;
    return parseFromString(explicit ?? notes);
  }
}
