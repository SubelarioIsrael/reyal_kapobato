class JournalEntry {
  final int journalId;
  final String? title; // Optional: table may not have a title column anymore
  final String content;
  // Only use text label from NLP service
  final String? sentiment; // new: 'positive' | 'neutral' | 'negative'
  final String? insight; // optional explanatory text
  final DateTime entryTimestamp;
  final bool isSharedWithCounselor;
  final String userId;

  JournalEntry({
    required this.journalId,
    this.title,
    required this.content,
    this.sentiment,
    this.insight,
    required this.entryTimestamp,
    required this.isSharedWithCounselor,
    required this.userId,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      journalId: map['journal_id'] as int,
      title: map.containsKey('title') ? map['title'] as String? : null,
      content: map['content'] as String,
      sentiment: map['sentiment'] as String?,
      insight: map['insight'] as String?,
      entryTimestamp: DateTime.parse(map['entry_timestamp'] as String),
      isSharedWithCounselor: map['is_shared_with_counselor'] as bool? ?? false,
      userId: map['user_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'journal_id': journalId,
      if (title != null) 'title': title,
      'content': content,
      if (sentiment != null) 'sentiment': sentiment,
      if (insight != null) 'insight': insight,
      'entry_timestamp': entryTimestamp.toIso8601String(),
      'is_shared_with_counselor': isSharedWithCounselor,
      'user_id': userId,
    };
  }

  String get sentimentLabel {
    if (sentiment != null) {
      final normalized = sentiment!.toLowerCase().trim();
      if (normalized == 'positive') return 'Positive';
      if (normalized == 'neutral') return 'Neutral';
      if (normalized == 'negative') return 'Negative';
    }
    return 'Unknown';
  }

  String get sentimentEmoji {
    if (sentiment != null) {
      final normalized = sentiment!.toLowerCase().trim();
      if (normalized == 'positive') return '😊';
      if (normalized == 'neutral') return '😐';
      if (normalized == 'negative') return '😔';
    }
    return '😐';
  }
}
