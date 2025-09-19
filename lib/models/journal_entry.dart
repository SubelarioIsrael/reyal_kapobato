class JournalEntry {
  final int journalId;
  final String title;
  final String content;
  final double? sentimentScore;
  final DateTime entryTimestamp;
  final bool isSharedWithCounselor;
  final String userId;

  JournalEntry({
    required this.journalId,
    required this.title,
    required this.content,
    this.sentimentScore,
    required this.entryTimestamp,
    required this.isSharedWithCounselor,
    required this.userId,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      journalId: map['journal_id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      sentimentScore: map['sentiment_score'] != null
          ? (map['sentiment_score'] as num).toDouble()
          : null,
      entryTimestamp: DateTime.parse(map['entry_timestamp'] as String),
      isSharedWithCounselor: map['is_shared_with_counselor'] as bool? ?? false,
      userId: map['user_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'journal_id': journalId,
      'title': title,
      'content': content,
      'sentiment_score': sentimentScore,
      'entry_timestamp': entryTimestamp.toIso8601String(),
      'is_shared_with_counselor': isSharedWithCounselor,
      'user_id': userId,
    };
  }

  String get sentimentLabel {
    if (sentimentScore == null) return 'Unknown';
    if (sentimentScore! >= 0.5) return 'Positive';
    if (sentimentScore! >= -0.1) return 'Neutral';
    return 'Negative';
  }

  String get sentimentEmoji {
    if (sentimentScore == null) return '😐';
    if (sentimentScore! >= 0.5) return '😊';
    if (sentimentScore! >= -0.1) return '😐';
    return '😔';
  }
}
