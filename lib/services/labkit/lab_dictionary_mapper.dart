import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/labkit/biomarker_result.dart';
import '../../models/labkit/biomarker_dictionary_entry.dart';

/// Maps extracted biomarker names to dictionary entries via fuzzy token matching.
///
/// Matching strategy (in order):
///   1. Exact match on canonical name (case-insensitive).
///   2. Exact match on any alias.
///   3. Starts-with match on name or any alias.
///   4. Token overlap: all tokens of the extracted name appear in the target.
///
/// Results with no match are flagged [BiomarkerResult.needsReview] = true
/// for the manual review queue.
class LabDictionaryMapper {
  static final LabDictionaryMapper _instance = LabDictionaryMapper._();
  factory LabDictionaryMapper() => _instance;
  LabDictionaryMapper._();

  final _supabase = Supabase.instance.client;

  List<BiomarkerDictionaryEntry>? _cache;

  Future<List<BiomarkerDictionaryEntry>> _loadDictionary() async {
    if (_cache != null) return _cache!;
    final rows = await _supabase
        .from('biomarkers_dictionary')
        .select()
        .order('name');
    _cache = (rows as List)
        .map((r) =>
            BiomarkerDictionaryEntry.fromJson(r as Map<String, dynamic>))
        .toList();
    developer.log(
      'LabDictionaryMapper: loaded ${_cache!.length} entries',
      name: 'labkit.mapper',
    );
    return _cache!;
  }

  /// Invalidates the in-memory cache (call after seeding new dictionary rows).
  void invalidateCache() => _cache = null;

  /// Maps [results] to dictionary entries, enriching each with [dictionaryId]
  /// and the dictionary's reference range for the given [sex] ('male' or 'female').
  Future<List<BiomarkerResult>> map(
    List<BiomarkerResult> results, {
    String sex = 'male',
  }) async {
    if (results.isEmpty) return results;
    final dict = await _loadDictionary();
    return results.map((r) => _mapSingle(r, dict, sex)).toList();
  }

  BiomarkerResult _mapSingle(
    BiomarkerResult result,
    List<BiomarkerDictionaryEntry> dict,
    String sex,
  ) {
    final entry = _findBestMatch(result.name, dict);
    if (entry == null) {
      return result.copyWith(needsReview: true);
    }

    final refRange = sex == 'female'
        ? (entry.referenceRangeFemale ?? entry.referenceRangeMale)
        : entry.referenceRangeMale;

    return result.copyWith(
      dictionaryId: entry.id,
      referenceRange: refRange ?? result.referenceRange,
      needsReview: false,
    );
  }

  BiomarkerDictionaryEntry? _findBestMatch(
    String extractedName,
    List<BiomarkerDictionaryEntry> dict,
  ) {
    final query = extractedName.toLowerCase().trim();
    if (query.isEmpty) return null;

    // 1. Exact name match
    for (final e in dict) {
      if (e.name.toLowerCase() == query) return e;
    }

    // 2. Exact alias match
    for (final e in dict) {
      if (e.aliases.any((a) => a.toLowerCase() == query)) return e;
    }

    // 3. Starts-with on name or alias
    for (final e in dict) {
      if (e.name.toLowerCase().startsWith(query) ||
          e.aliases.any((a) => a.toLowerCase().startsWith(query))) {
        return e;
      }
    }

    // 4. Token overlap: every token in query appears somewhere in the target terms
    final queryTokens =
        query.split(RegExp(r'[\s\-/()]+'))..removeWhere((t) => t.length < 2);
    if (queryTokens.isEmpty) return null;

    for (final e in dict) {
      final targetText = e.allSearchTerms.join(' ');
      if (queryTokens.every((t) => targetText.contains(t))) return e;
    }

    return null;
  }
}
