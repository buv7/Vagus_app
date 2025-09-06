enum KbVisibility { public, internal }

class KbArticle {
  final String id;
  final String title;
  final String body;         // markdown/plain
  final List<String> tags;   // e.g., billing, ios, export
  final KbVisibility vis;
  final DateTime updatedAt;
  final String updatedBy;
  
  const KbArticle({
    required this.id,
    required this.title,
    required this.body,
    this.tags = const [],
    this.vis = KbVisibility.public,
    required this.updatedAt,
    required this.updatedBy,
  });

  KbArticle copyWith({
    String? title,
    String? body,
    List<String>? tags,
    KbVisibility? vis,
    DateTime? updatedAt,
    String? updatedBy,
  }) =>
      KbArticle(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        tags: tags ?? this.tags,
        vis: vis ?? this.vis,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedBy: updatedBy ?? this.updatedBy,
      );
}

class KbSuggestion {
  final String articleId;
  final String title;
  final String snippet;   // short excerpt to preview
  final double confidence; // 0..1
  
  const KbSuggestion({
    required this.articleId,
    required this.title,
    required this.snippet,
    required this.confidence,
  });
}
