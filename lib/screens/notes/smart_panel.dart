import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'coach_note_screen.dart';
import '../../services/ai/embedding_helper.dart';
import '../../services/billing/plan_access_manager.dart';
import '../../widgets/anim/blocking_overlay.dart';
import '../../theme/design_tokens.dart';

class SmartPanel extends StatefulWidget {
  final TextEditingController noteController;
  final String? clientId;

  const SmartPanel({
    super.key, 
    required this.noteController,
    this.clientId,
  });

  @override
  State<SmartPanel> createState() => _SmartPanelState();
}

class _SmartPanelState extends State<SmartPanel> {

  // Module-level toggle for vector-based duplicate detection
  static const bool useVectorDupDetect = true; // default true

  void _runAction(BuildContext context, String type) async {
    // AI gating check
    final remaining = await PlanAccessManager.instance.remainingAICalls();
    if (!mounted || !context.mounted) return;
    if (remaining <= 0) {
      PlanAccessManager.instance.guardOrPaywall(context, feature: 'ai.notes');
      return;
    }

    final currentText = widget.noteController.text.trim();
    if (currentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note is empty.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Running AI: $type... (simulated)')),
    );

    await runWithBlockingLoader(
      context,
      Future.delayed(const Duration(seconds: 2)),
      showSuccess: true,
    );
    if (!mounted || !context.mounted) return;

    switch (type) {
      case 'Improve':
        widget.noteController.text = '🧠 [Improved] $currentText';
        break;
      case 'Summarize':
        widget.noteController.text += '\n\n• Summary: [Simulated bullet summary]';
        break;
      case 'Tags':
        widget.noteController.text += '\n\n🏷 Tags: mindset, recovery';
        break;
      case 'Rewrite Tone':
        widget.noteController.text = '[Friendly Tone]: $currentText';
        break;
      case 'Follow-Up':
        widget.noteController.text += '\n\n📌 Follow-up: Discuss client mindset tomorrow';
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

      // Try vector-based duplicate detection first if enabled
      if (useVectorDupDetect) {
        try {
          final embeddingHelper = EmbeddingHelper();
          
          // First, we need to create a temporary note to get an ID for embedding search
          // This is a simplified approach - in production, you might want to handle this differently
          final tempNoteResult = await supabase
              .from('coach_notes')
              .insert({
                'title': 'Temp for embedding search',
                'body': currentText,
                'coach_id': user.id,
                if (widget.clientId != null) 'client_id': widget.clientId,
              })
              .select('id')
              .single();

          final tempNoteId = tempNoteResult['id'] as String;
          
          // Get similar notes using embeddings
          final similarNotes = await embeddingHelper.similarNotes(noteId: tempNoteId, k: 5);
          
          // Clean up the temporary note
          await supabase
              .from('coach_notes')
              .delete()
              .eq('id', tempNoteId);

          // Check if any similar note has high similarity (≥ 0.85)
          for (final similar in similarNotes) {
            final similarity = similar['similarity'] as double;
            if (similarity >= 0.85) {
              // Fetch the full note details
              final noteResult = await supabase
                  .from('coach_notes')
                  .select('id, title, body, created_at, client_id')
                  .eq('id', similar['note_id'])
                  .single();

              if (!mounted || !context.mounted) return;
              _showDuplicateResult(
                context, 
                noteResult, 
                similarity, 
                'Vector similarity: ${(similarity * 100).toStringAsFixed(1)}%'
              );
              return;
                        }
          }
        } catch (e) {
          // Fall back to Jaccard similarity if vector search fails
          debugPrint('Vector duplicate detection failed, falling back to Jaccard: $e');
        }
      }

      // Fallback to Jaccard similarity (existing implementation)
      // Fetch recent notes for the same client/coach
      var request = supabase
          .from('coach_notes')
          .select('id, title, body, created_at, client_id')
          .eq('coach_id', user.id);
      
      // Only filter by client_id if it's provided
      if (widget.clientId != null) {
        request = request.eq('client_id', widget.clientId!);
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

      if (!mounted || !context.mounted) return;
      if (bestMatch != null) {
        _showDuplicateResult(context, bestMatch, bestScore, bestReason!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ No similar notes found'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error checking for duplicates: $e'),
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
      return 'High overlap in keywords: $sampleTokens...';
    } else if (text1.length > 50 && text2.length > 50) {
      return 'Similar content structure and length';
    } else {
      return 'High text similarity score';
    }
  }

  void _showDuplicateResult(
    BuildContext context, 
    Map<String, dynamic> match, 
    double score, 
    String reason
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? DesignTokens.darkBackground : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
          side: BorderSide(
            color: isDark 
                ? DesignTokens.accentBlue.withValues(alpha: 0.4)
                : DesignTokens.borderColor(context),
            width: isDark ? 2 : 1,
          ),
        ),
        title: Text(
          'Similar Note Found',
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
                border: Border.all(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Similarity: ${(score * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : DesignTokens.accentBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Reason: $reason',
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.8) : DesignTokens.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Title: ${match['title'] ?? 'No title'}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : DesignTokens.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Content: ${(match['body'] ?? '').toString().substring(0, min(100, (match['body'] ?? '').toString().length))}...',
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white.withValues(alpha: 0.8) : DesignTokens.textColorSecondary(context),
            ),
            child: const Text('Continue Writing'),
          ),
          Container(
            decoration: BoxDecoration(
              color: DesignTokens.accentBlue,
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(dialogContext);
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
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'View Similar Note',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicChip({
    required BuildContext context,
    required String label,
    required String emoji,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? (isPrimary 
                ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                : DesignTokens.accentBlue.withValues(alpha: 0.15))
            : (isPrimary 
                ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        border: Border.all(
          color: isDark 
              ? DesignTokens.accentBlue.withValues(alpha: 0.4)
              : DesignTokens.accentBlue.withValues(alpha: 0.3),
          width: isPrimary ? 2 : 1,
        ),
        boxShadow: isDark ? [
          BoxShadow(
            color: DesignTokens.accentBlue.withValues(alpha: isPrimary ? 0.2 : 0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white : DesignTokens.textColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildGlassmorphicChip(
          context: context,
          label: 'Improve',
          emoji: '✨',
          onTap: () => _runAction(context, 'Improve'),
          isPrimary: true,
        ),
        _buildGlassmorphicChip(
          context: context,
          label: 'Summarize',
          emoji: '📄',
          onTap: () => _runAction(context, 'Summarize'),
        ),
        _buildGlassmorphicChip(
          context: context,
          label: 'Smart Tags',
          emoji: '🏷',
          onTap: () => _runAction(context, 'Tags'),
        ),
        _buildGlassmorphicChip(
          context: context,
          label: 'Rewrite Tone',
          emoji: '🎭',
          onTap: () => _runAction(context, 'Rewrite Tone'),
        ),
        _buildGlassmorphicChip(
          context: context,
          label: 'Follow-Up Suggestion',
          emoji: '📌',
          onTap: () => _runAction(context, 'Follow-Up'),
        ),
        _buildGlassmorphicChip(
          context: context,
          label: 'Check Duplicates',
          emoji: '🔍',
          onTap: () => _runAction(context, 'Duplicate'),
        ),
      ],
    );
  }
}
