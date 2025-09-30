import 'dart:math';
import 'package:intl/intl.dart';
import 'weekly_review_service.dart';

/// Optional AI text function signature:
/// Provide a function that takes a prompt and returns model text.
/// If null, we'll return heuristic-only insights.
/// Example gateway (if you have one):
///   final ai = (String p) => AiGateway.instance.generateText(prompt: p);
typedef AiTextFn = Future<String> Function(String prompt);

class WeeklyAIInsights {
  final List<String> wins;
  final List<String> risks;
  final List<String> suggestions;
  final String rationale; // short paragraph
  final bool usedAI;
  final String? aiModel;

  WeeklyAIInsights({
    required this.wins,
    required this.risks,
    required this.suggestions,
    required this.rationale,
    required this.usedAI,
    this.aiModel,
  });
}

class WeeklyAIInsightsService {
  /// Main entry. If [ai] is provided, we enrich with AI; otherwise we ship heuristic-only.
  Future<WeeklyAIInsights> analyze({
    required WeeklyReviewData data,
    AiTextFn? ai,
    String? aiModelHint,
  }) async {
    final heur = _heuristics(data);

    if (ai == null) {
      return heur.copyWith(usedAI: false);
    }

    try {
      final prompt = _buildPrompt(data, heur);
      final txt = await ai(prompt);
      final parsed = _parseAiText(txt, fallback: heur);
      return parsed.copyWith(usedAI: true, aiModel: aiModelHint);
    } catch (_) {
      // Any error → return heuristics gracefully
      return heur.copyWith(usedAI: false);
    }
  }

  /// Build a compact, structured prompt for LLM.
  String _buildPrompt(WeeklyReviewData d, WeeklyAIInsights h) {
    final df = DateFormat('yyyy-MM-dd');
    String series(String label, List<DailyPoint> xs, {int decimals = 0}) {
      final values = xs.map((p) => p.value.toStringAsFixed(decimals)).join(',');
      return '$label=[$values]';
    }

    return [
      'You are an elite bodybuilding coach AI. Produce concise, actionable weekly insights.',
      'Client week: ${df.format(d.weekStart)} to ${df.format(d.weekEnd)}.',
      series('sleep_h', d.trends.sleepHours, decimals: 1),
      series('steps', d.trends.steps),
      series('kcal_in', d.trends.caloriesIn),
      series('kcal_out', d.trends.caloriesOut),
      'summary: compliance=${d.summary.compliancePercent.toStringAsFixed(1)}%,'
          ' sessions_done=${d.summary.sessionsDone}, sessions_skipped=${d.summary.sessionsSkipped},'
          ' tonnage=${d.summary.totalTonnage.toStringAsFixed(0)}kg, cardio_min=${d.summary.cardioMinutes}',
      'energy_balance: total_in=${d.energyBalance.totalIn.toStringAsFixed(0)},'
          ' total_out=${d.energyBalance.totalOut.toStringAsFixed(0)}, net=${d.energyBalance.net.toStringAsFixed(0)}',
      'Return JSON with keys: wins[], risks[], suggestions[], rationale.',
      'Be brief, clear, and coach-like. No medical claims.',
    ].join('\n');
  }

  WeeklyAIInsights _parseAiText(String txt, {required WeeklyAIInsights fallback}) {
    // Very light parser: try to pull simple lists from a JSON-ish response.
    // If parsing fails, fallback to heuristics.
    try {
      // Extremely simple approach to avoid new deps:
      Map<String, dynamic> pick(String key) {
        final i = txt.indexOf('"$key"');
        if (i < 0) return {};
        final s = txt.indexOf('[', i);
        final e = txt.indexOf(']', s);
        if (s < 0 || e < 0) return {};
        final raw = txt.substring(s + 1, e);
        final items = raw.split(',').map((x) {
          final t = x.trim();
          return t.replaceAll('"', '').replaceAll("'", '');
        }).where((x) => x.isNotEmpty).toList();
        return {key: items};
      }

      List<String> getList(String key) {
        final m = pick(key);
        final v = m[key];
        if (v is List) return v.cast<String>();
        return <String>[];
      }

      String getRationale() {
        final i = txt.indexOf('"rationale"');
        if (i < 0) return fallback.rationale;
        // naive quote-to-quote slice
        final q1 = txt.indexOf('"', i + 10);
        final q2 = txt.indexOf('"', q1 + 1);
        if (q1 < 0 || q2 < 0) return fallback.rationale;
        final r = txt.substring(q1 + 1, q2).trim();
        return r.isEmpty ? fallback.rationale : r;
      }

      final wins = getList('wins');
      final risks = getList('risks');
      final suggestions = getList('suggestions');
      final rationale = getRationale();

      if (wins.isEmpty && risks.isEmpty && suggestions.isEmpty) return fallback;
      return WeeklyAIInsights(
        wins: wins.isEmpty ? fallback.wins : wins,
        risks: risks.isEmpty ? fallback.risks : risks,
        suggestions: suggestions.isEmpty ? fallback.suggestions : suggestions,
        rationale: rationale,
        usedAI: true,
      );
    } catch (_) {
      return fallback;
    }
  }

  WeeklyAIInsights _heuristics(WeeklyReviewData d) {
    final avgSleep = _avg(d.trends.sleepHours);
    final totalSteps = d.trends.steps.fold<double>(0, (s, p) => s + p.value);
    final avgSteps = totalSteps / max(1, d.trends.steps.length);
    final net = d.energyBalance.net;
    final comp = d.summary.compliancePercent;

    final wins = <String>[];
    final risks = <String>[];
    final suggestions = <String>[];

    if (comp >= 85) wins.add('Strong weekly compliance (${comp.toStringAsFixed(0)}%).');
    if (avgSleep >= 7.0) wins.add('Sleep on target (~${avgSleep.toStringAsFixed(1)}h).');
    if (d.summary.cardioMinutes >= 90) wins.add('Solid cardio volume (${d.summary.cardioMinutes} min).');
    if (d.summary.totalTonnage > 0) wins.add('Resistance training logged (${d.summary.totalTonnage.toStringAsFixed(0)} kg total).');

    if (avgSleep < 6.5) risks.add('Low average sleep (${avgSleep.toStringAsFixed(1)}h).');
    if (avgSteps < 6000) risks.add('Low average steps (${avgSteps.toStringAsFixed(0)}).');
    if (comp < 60) risks.add('Low weekly compliance (${comp.toStringAsFixed(0)}%).');

    // Energy balance sanity
    if (net > 1200) risks.add('High positive energy balance (+${net.toStringAsFixed(0)} kcal).');
    if (net < -1200) risks.add('High negative energy balance (${net.toStringAsFixed(0)} kcal).');

    // Suggestions
    if (avgSleep < 7) suggestions.add('Target 7–8h sleep; set a consistent wind-down time.');
    if (avgSteps < 8000) suggestions.add('Add 1–2 short walks to reach 8–10k steps.');
    if (comp < 80) suggestions.add('Identify 1–2 simple habits to raise compliance (prep meals, fixed training slot).');
    if (net > 800 && d.summary.sessionsSkipped > 0) {
      suggestions.add('Tighten calorie intake or increase activity to balance energy.');
    }
    if (net < -800 && d.summary.totalTonnage > 0) {
      suggestions.add('Ensure recovery: add a refeed or deload signals if fatigue rises.');
    }

    final rationale = 'Heuristic insights derived from sleep, steps, energy balance, and compliance trends.';

    return WeeklyAIInsights(
      wins: wins,
      risks: risks,
      suggestions: suggestions,
      rationale: rationale,
      usedAI: false,
    );
  }

  double _avg(List<DailyPoint> xs) =>
      xs.isEmpty ? 0 : xs.fold<double>(0, (s, p) => s + p.value) / xs.length;
}

extension _Copy on WeeklyAIInsights {
  WeeklyAIInsights copyWith({bool? usedAI, String? aiModel}) {
    return WeeklyAIInsights(
      wins: wins,
      risks: risks,
      suggestions: suggestions,
      rationale: rationale,
      usedAI: usedAI ?? this.usedAI,
      aiModel: aiModel ?? this.aiModel,
    );
  }
}
