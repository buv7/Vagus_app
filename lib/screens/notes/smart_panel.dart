import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'coach_note_screen.dart';

class SmartPanel extends StatelessWidget {
  final TextEditingController noteController;
  final String? clientId;

  const SmartPanel({
    super.key, 
    required this.noteController,
    this.clientId,
  });

  void _runAction(BuildContext context, String type) async {
    final currentText = noteController.text.trim();
    if (currentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note is empty.")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Running AI: $type... (simulated)")),
    );

    await Future.delayed(const Duration(seconds: 2));

    switch (type) {
      case 'Improve':
        noteController.text = "🧠 [Improved] $currentText";
        break;
      case 'Summarize':
        noteController.text += "\n\n• Summary: [Simulated bullet summary]";
        break;
      case 'Tags':
        noteController.text += "\n\n🏷 Tags: mindset, recovery";
        break;
      case 'Rewrite Tone':
        noteController.text = "[Friendly Tone]: $currentText";
        break;
      case 'Follow-Up':
        noteController.text += "\n\n📌 Follow-up: Discuss client mindset tomorrow";
        break;
      case 'Duplicate':
        await _detectDuplicate(context, currentText);
        break;
    }
  }

  Future<void> _detectDuplicate(BuildContext context, String currentText) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Fetch recent notes for the same client/coach
      var request = supabase
          .from('coach_notes')
          .select('id, title, body, created_at')
          .eq('coach_id', user.id);
      
      // Only filter by client_id if it's provided
      if (clientId != null) {
        request = request.eq('client_id', clientId!);
      }
      
      final response = await request
          .order('created_at', ascending: false)
          .limit(50);

      final notes = List<Map<String, dynamic>>.from(response);
      
      // Find the best match
      double bestScore = 0.0;
      Map<String, dynamic>? bestMatch;
      String? bestReason;

      for (final note in notes) {
        final noteText = '${note['title'] ?? ''} ${note['body'] ?? ''}'.trim();
        if (noteText.isEmpty) continue;

        final score = _calculateSimilarity(currentText, noteText);
        if (score > bestScore && score > 0.82) {
          bestScore = score;
          bestMatch = note;
          bestReason = _generateSimilarityReason(currentText, noteText, score);
        }
      }

      if (bestMatch != null) {
        _showDuplicateResult(context, bestMatch, bestScore, bestReason!);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ No similar notes found"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error checking for duplicates: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _calculateSimilarity(String text1, String text2) {
    // Simple Jaccard similarity on normalized tokens
    final tokens1 = _normalizeAndTokenize(text1);
    final tokens2 = _normalizeAndTokenize(text2);
    
    if (tokens1.isEmpty && tokens2.isEmpty) return 1.0;
    if (tokens1.isEmpty || tokens2.isEmpty) return 0.0;
    
    final intersection = tokens1.intersection(tokens2).length;
    final union = tokens1.union(tokens2).length;
    
    return intersection / union;
  }

  Set<String> _normalizeAndTokenize(String text) {
    // Simple tokenization: split on whitespace and punctuation
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 2) // Filter out very short tokens
        .toSet();
  }

  String _generateSimilarityReason(String text1, String text2, double score) {
    final tokens1 = _normalizeAndTokenize(text1);
    final tokens2 = _normalizeAndTokenize(text2);
    final commonTokens = tokens1.intersection(tokens2);
    
    if (commonTokens.length > 5) {
      final sampleTokens = commonTokens.take(3).join(', ');
      return "High overlap in keywords: $sampleTokens...";
    } else if (text1.length > 50 && text2.length > 50) {
      return "Similar content structure and length";
    } else {
      return "High text similarity score";
    }
  }

  void _showDuplicateResult(
    BuildContext context, 
    Map<String, dynamic> match, 
    double score, 
    String reason
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Similar Note Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Similarity: ${(score * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Reason: $reason'),
            const SizedBox(height: 16),
            Text(
              'Title: ${match['title'] ?? 'No title'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Content: ${(match['body'] ?? '').toString().substring(0, min(100, (match['body'] ?? '').toString().length))}...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Writing'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to the similar note using existing pattern
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoachNoteScreen(
                    existingNote: match,
                    clientId: match['client_id'],
                  ),
                ),
              );
            },
            child: const Text('View Similar Note'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton(
          onPressed: () => _runAction(context, 'Improve'),
          child: const Text("✨ Improve"),
        ),
        ElevatedButton(
          onPressed: () => _runAction(context, 'Summarize'),
          child: const Text("📄 Summarize"),
        ),
        ElevatedButton(
          onPressed: () => _runAction(context, 'Tags'),
          child: const Text("🏷 Smart Tags"),
        ),
        ElevatedButton(
          onPressed: () => _runAction(context, 'Rewrite Tone'),
          child: const Text("🎭 Rewrite Tone"),
        ),
        ElevatedButton(
          onPressed: () => _runAction(context, 'Follow-Up'),
          child: const Text("📌 Follow-Up Suggestion"),
        ),
        ElevatedButton(
          onPressed: () => _runAction(context, 'Duplicate'),
          child: const Text("🔍 Check Duplicates"),
        ),
      ],
    );
  }
}
