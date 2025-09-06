import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/admin/kb_models.dart';
import '../../models/admin/ticket_models.dart';

class AdminKnowledgeService {
  AdminKnowledgeService._();
  static final AdminKnowledgeService instance = AdminKnowledgeService._();

  // In-memory seed (replace with Supabase later)
  final List<KbArticle> _store = [
    KbArticle(
      id: 'a1',
      title: 'Payment failed — common causes',
      body: 'If Stripe shows card_declined… Steps: 1) Verify card 2) Retry 3) Update billing address',
      tags: ['billing', 'payment', 'stripe'],
      vis: KbVisibility.public,
      updatedAt: DateTime.now(),
      updatedBy: 'System',
    ),
    KbArticle(
      id: 'a2',
      title: 'iOS export stuck at 0%',
      body: 'Check Files permission, free space, and try re-login. Collect logs via Settings → Diagnostics.',
      tags: ['ios', 'export'],
      vis: KbVisibility.internal,
      updatedAt: DateTime.now(),
      updatedBy: 'System',
    ),
  ];

  Future<List<KbArticle>> search({
    String q = '',
    List<String> tags = const [],
    bool includeInternal = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final lq = q.toLowerCase();
    return _store.where((a) {
      final matchText = lq.isEmpty ||
          a.title.toLowerCase().contains(lq) ||
          a.body.toLowerCase().contains(lq);
      final matchTags = tags.isEmpty ||
          tags.any((t) => a.tags.contains(t));
      final visOk = includeInternal || a.vis == KbVisibility.public;
      return matchText && matchTags && visOk;
    }).toList();
  }

  Future<KbArticle?> getById(String id) async {
    try {
      return _store.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<KbArticle> upsert(KbArticle a) async {
    final i = _store.indexWhere((x) => x.id == a.id);
    if (i >= 0) {
      _store[i] = a;
    } else {
      _store.add(a);
    }
    return a;
  }

  Future<bool> remove(String id) async {
    _store.removeWhere((a) => a.id == id);
    return true;
  }

  // Naive suggestor: match by tags/subject keywords
  Future<List<KbSuggestion>> suggestForTicket(TicketSummary t) async {
    final keyset = <String>{
      ...t.tags.map((x) => x.toLowerCase()),
      ...t.subject.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((s) => s.length > 3),
    };
    final res = <KbSuggestion>[];
    for (final a in _store) {
      final overlap = a.tags.where((tg) => keyset.contains(tg.toLowerCase())).length;
      final titleHit = keyset.any((k) => a.title.toLowerCase().contains(k));
      final conf = (overlap * 0.2) + (titleHit ? 0.3 : 0.0);
      if (conf > 0.25) {
        final snippet = a.body.length > 140 ? '${a.body.substring(0, 140)}…' : a.body;
        res.add(KbSuggestion(
          articleId: a.id,
          title: a.title,
          snippet: snippet,
          confidence: conf.clamp(0, 1),
        ));
      }
    }
    res.sort((a, b) => b.confidence.compareTo(a.confidence));
    return res.take(5).toList();
  }
}
