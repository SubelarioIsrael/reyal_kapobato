// JM-JE-02: Counselor can view a student's journal entries
// Requirement: Counselors can only view entries where is_shared_with_counselor is true
// Mirrors logic where counselors access student journals with permission filtering

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent a journal entry
class MockJournalEntry {
  final int journalId;
  final String? title;
  final String content;
  final String? sentiment;
  final String? insight;
  final DateTime entryTimestamp;
  final bool isSharedWithCounselor;
  final String userId;

  MockJournalEntry({
    required this.journalId,
    this.title,
    required this.content,
    this.sentiment,
    this.insight,
    required this.entryTimestamp,
    required this.isSharedWithCounselor,
    required this.userId,
  });

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

  factory MockJournalEntry.fromMap(Map<String, dynamic> map) {
    return MockJournalEntry(
      journalId: map['journal_id'],
      title: map['title'],
      content: map['content'],
      sentiment: map['sentiment'],
      insight: map['insight'],
      entryTimestamp: DateTime.parse(map['entry_timestamp']),
      isSharedWithCounselor: map['is_shared_with_counselor'] ?? false,
      userId: map['user_id'],
    );
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

// Mock database for journal entries
class MockJournalDatabase {
  Map<String, List<Map<String, dynamic>>> _userJournals = {};
  bool _shouldThrowError = false;

  void seedJournalEntries(String userId, List<Map<String, dynamic>> entries) {
    _userJournals[userId] = entries;
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  // Get all journal entries for a user (filtered by shared status for counselors)
  Future<List<Map<String, dynamic>>> getJournalEntriesForCounselor(
    String userId, 
    String counselorId
  ) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (_shouldThrowError) {
      throw Exception('Error loading journal entries');
    }

    final allEntries = _userJournals[userId] ?? [];
    
    // Counselors can only view entries where is_shared_with_counselor is true
    return allEntries
        .where((entry) => entry['is_shared_with_counselor'] == true)
        .toList();
  }

  Future<Map<String, int>> getSharedJournalStats(String userId, String counselorId) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (_shouldThrowError) {
      throw Exception('Error loading journal stats');
    }

    final sharedEntries = await getJournalEntriesForCounselor(userId, counselorId);
    
    int totalShared = sharedEntries.length;
    int positiveEntries = sharedEntries
        .where((entry) =>
            (entry['sentiment'] as String?)?.toLowerCase() == 'positive')
        .length;
    int negativeEntries = sharedEntries
        .where((entry) =>
            (entry['sentiment'] as String?)?.toLowerCase() == 'negative')
        .length;
    int neutralEntries = sharedEntries
        .where((entry) =>
            (entry['sentiment'] as String?)?.toLowerCase() == 'neutral')
        .length;

    return {
      'total': totalShared,
      'positive': positiveEntries,
      'negative': negativeEntries,
      'neutral': neutralEntries,
    };
  }

  void clear() {
    _userJournals.clear();
    _shouldThrowError = false;
  }
}

// Service class for counselors to view student journal entries
class CounselorJournalViewService {
  final MockJournalDatabase _database;
  List<MockJournalEntry> _sharedJournalEntries = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  Map<String, int> _stats = {};

  CounselorJournalViewService(this._database);

  List<MockJournalEntry> get sharedJournalEntries => _sharedJournalEntries;
  List<MockJournalEntry> get filteredEntries {
    return _sharedJournalEntries.where((entry) {
      bool matchesSearch = _searchQuery.isEmpty ||
          (entry.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          entry.content.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = true;
      switch (_selectedFilter) {
        case 'positive':
          matchesFilter = entry.sentiment?.toLowerCase() == 'positive';
          break;
        case 'negative':
          matchesFilter = entry.sentiment?.toLowerCase() == 'negative';
          break;
        case 'neutral':
          matchesFilter = entry.sentiment?.toLowerCase() == 'neutral';
          break;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  Map<String, int> get stats => _stats;

  Future<void> loadStudentJournalEntries(String studentId, String counselorId) async {
    try {
      _isLoading = true;
      _errorMessage = null;

      final entriesData = await _database.getJournalEntriesForCounselor(studentId, counselorId);
      final statsData = await _database.getSharedJournalStats(studentId, counselorId);

      _sharedJournalEntries = entriesData.map((data) => MockJournalEntry.fromMap(data)).toList();
      _stats = statsData;

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _sharedJournalEntries = [];
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
  }

  bool hasSharedEntries() {
    return _sharedJournalEntries.isNotEmpty;
  }

  int getSharedEntriesCount() {
    return _sharedJournalEntries.length;
  }

  int getFilteredEntriesCount() {
    return filteredEntries.length;
  }

  List<MockJournalEntry> getEntriesBySentiment(String sentiment) {
    return _sharedJournalEntries
        .where((entry) => entry.sentiment?.toLowerCase() == sentiment.toLowerCase())
        .toList();
  }

  String getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty || _selectedFilter != 'all') {
      return 'No entries match your search';
    }
    return 'This student has not shared any journal entries with you';
  }

  bool canViewEntry(MockJournalEntry entry) {
    return entry.isSharedWithCounselor;
  }

  void reset() {
    _sharedJournalEntries.clear();
    _searchQuery = '';
    _selectedFilter = 'all';
    _stats.clear();
    _isLoading = false;
    _errorMessage = null;
  }

  Map<String, dynamic> getAccessStatistics(String studentId) {
    return {
      'student_id': studentId,
      'shared_entries_count': _sharedJournalEntries.length,
      'filtered_count': filteredEntries.length,
      'positive_count': getEntriesBySentiment('positive').length,
      'negative_count': getEntriesBySentiment('negative').length,
      'neutral_count': getEntriesBySentiment('neutral').length,
      'has_access': hasSharedEntries(),
      'active_filter': _selectedFilter,
      'stats': _stats,
    };
  }

  List<MockJournalEntry> getRecentEntries(int limit) {
    if (_sharedJournalEntries.isEmpty) return [];
    
    final sortedEntries = List<MockJournalEntry>.from(_sharedJournalEntries)
      ..sort((a, b) => b.entryTimestamp.compareTo(a.entryTimestamp));
    
    return sortedEntries.take(limit).toList();
  }

  MockJournalEntry? findEntryById(int journalId) {
    try {
      return _sharedJournalEntries.firstWhere((entry) => entry.journalId == journalId);
    } catch (e) {
      return null;
    }
  }
}

void main() {
  group('JM-JE-02: Counselor can view a student\'s journal entries', () {
    late MockJournalDatabase mockDatabase;
    late CounselorJournalViewService viewService;

    setUp(() {
      mockDatabase = MockJournalDatabase();
      viewService = CounselorJournalViewService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('Should load only shared journal entries for counselor', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Shared Entry',
          'content': 'This is shared with counselor',
          'sentiment': 'positive',
          'insight': 'Feeling good',
          'entry_timestamp': now.subtract(Duration(days: 2)).toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Private Entry',
          'content': 'This is private',
          'sentiment': 'neutral',
          'insight': 'Feeling okay',
          'entry_timestamp': now.subtract(Duration(days: 1)).toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
        {
          'journal_id': 3,
          'title': 'Another Shared Entry',
          'content': 'Another shared one',
          'sentiment': 'negative',
          'insight': 'Feeling down',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, isNull);
      expect(viewService.sharedJournalEntries.length, 2);
      expect(viewService.hasSharedEntries(), true);

      // Verify only shared entries are loaded
      for (var entry in viewService.sharedJournalEntries) {
        expect(entry.isSharedWithCounselor, true);
      }
    });

    test('Should not load private entries for counselor', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Private Entry 1',
          'content': 'This is private',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Private Entry 2',
          'content': 'This is also private',
          'sentiment': 'neutral',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      expect(viewService.sharedJournalEntries.length, 0);
      expect(viewService.hasSharedEntries(), false);
      expect(
        viewService.getEmptyStateMessage(),
        'This student has not shared any journal entries with you',
      );
    });

    test('Should handle student with no entries', () async {
      mockDatabase.seedJournalEntries('student1', []);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, isNull);
      expect(viewService.sharedJournalEntries.length, 0);
      expect(viewService.hasSharedEntries(), false);
    });

    test('Should handle loading errors', () async {
      mockDatabase.setShouldThrowError(true);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, contains('Error loading journal entries'));
      expect(viewService.sharedJournalEntries.length, 0);
    });

    test('Should load shared journal statistics correctly', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Shared Positive',
          'content': 'Great day',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Shared Negative',
          'content': 'Bad day',
          'sentiment': 'negative',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 3,
          'title': 'Private',
          'content': 'Private entry',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      expect(viewService.stats['total'], 2);
      expect(viewService.stats['positive'], 1);
      expect(viewService.stats['negative'], 1);
    });

    test('Should filter shared entries by search query', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Great Day',
          'content': 'Today was amazing',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Tough Day',
          'content': 'Feeling stressed',
          'sentiment': 'negative',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      viewService.setSearchQuery('great');
      expect(viewService.filteredEntries.length, 1);
      expect(viewService.filteredEntries[0].title, 'Great Day');

      viewService.setSearchQuery('stressed');
      expect(viewService.filteredEntries.length, 1);
      expect(viewService.filteredEntries[0].title, 'Tough Day');

      viewService.setSearchQuery('');
      expect(viewService.filteredEntries.length, 2);
    });

    test('Should filter shared entries by sentiment', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Positive Entry',
          'content': 'Great day',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Negative Entry',
          'content': 'Bad day',
          'sentiment': 'negative',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 3,
          'title': 'Neutral Entry',
          'content': 'Normal day',
          'sentiment': 'neutral',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      viewService.setFilter('positive');
      expect(viewService.filteredEntries.length, 1);
      expect(viewService.filteredEntries[0].sentiment, 'positive');

      viewService.setFilter('negative');
      expect(viewService.filteredEntries.length, 1);
      expect(viewService.filteredEntries[0].sentiment, 'negative');

      viewService.setFilter('neutral');
      expect(viewService.filteredEntries.length, 1);
      expect(viewService.filteredEntries[0].sentiment, 'neutral');

      viewService.setFilter('all');
      expect(viewService.filteredEntries.length, 3);
    });

    test('Should verify entry access permissions', () async {
      final now = DateTime.now();
      
      final sharedEntry = MockJournalEntry(
        journalId: 1,
        content: 'Shared content',
        sentiment: 'positive',
        entryTimestamp: now,
        isSharedWithCounselor: true,
        userId: 'student1',
      );

      final privateEntry = MockJournalEntry(
        journalId: 2,
        content: 'Private content',
        sentiment: 'neutral',
        entryTimestamp: now,
        isSharedWithCounselor: false,
        userId: 'student1',
      );

      expect(viewService.canViewEntry(sharedEntry), true);
      expect(viewService.canViewEntry(privateEntry), false);
    });

    test('Should get entries by sentiment', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry 1',
          'content': 'Content 1',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Entry 2',
          'content': 'Content 2',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 3,
          'title': 'Entry 3',
          'content': 'Content 3',
          'sentiment': 'negative',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      final positiveEntries = viewService.getEntriesBySentiment('positive');
      expect(positiveEntries.length, 2);

      final negativeEntries = viewService.getEntriesBySentiment('negative');
      expect(negativeEntries.length, 1);
    });

    test('Should get recent shared entries', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Old Entry',
          'content': 'Old content',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.subtract(Duration(days: 5)).toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Recent Entry',
          'content': 'Recent content',
          'sentiment': 'neutral',
          'insight': null,
          'entry_timestamp': now.subtract(Duration(days: 1)).toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 3,
          'title': 'Latest Entry',
          'content': 'Latest content',
          'sentiment': 'negative',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      final recentEntries = viewService.getRecentEntries(2);
      expect(recentEntries.length, 2);
      expect(recentEntries[0].title, 'Latest Entry');
      expect(recentEntries[1].title, 'Recent Entry');
    });

    test('Should find entry by ID', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry 1',
          'content': 'Content 1',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      final found = viewService.findEntryById(1);
      expect(found, isNotNull);
      expect(found!.title, 'Entry 1');

      final notFound = viewService.findEntryById(999);
      expect(notFound, isNull);
    });

    test('Should generate access statistics', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry 1',
          'content': 'Content 1',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Entry 2',
          'content': 'Content 2',
          'sentiment': 'negative',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      final stats = viewService.getAccessStatistics('student1');

      expect(stats['student_id'], 'student1');
      expect(stats['shared_entries_count'], 2);
      expect(stats['positive_count'], 1);
      expect(stats['negative_count'], 1);
      expect(stats['has_access'], true);
    });

    test('Should reset service state', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry 1',
          'content': 'Content 1',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');
      viewService.setSearchQuery('test');
      viewService.setFilter('positive');

      expect(viewService.sharedJournalEntries.length, 1);
      expect(viewService.searchQuery, 'test');
      expect(viewService.selectedFilter, 'positive');

      viewService.reset();

      expect(viewService.sharedJournalEntries.length, 0);
      expect(viewService.searchQuery, '');
      expect(viewService.selectedFilter, 'all');
      expect(viewService.stats, isEmpty);
    });

    test('Should combine search and filter correctly', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Happy Day',
          'content': 'Feeling great',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Happy Morning',
          'content': 'Good start',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 3,
          'title': 'Sad Day',
          'content': 'Not feeling well',
          'sentiment': 'negative',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      viewService.setFilter('positive');
      viewService.setSearchQuery('day');
      expect(viewService.filteredEntries.length, 1);
      expect(viewService.filteredEntries[0].title, 'Happy Day');
    });

    test('Should return correct empty state messages', () async {
      mockDatabase.seedJournalEntries('student1', []);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      expect(
        viewService.getEmptyStateMessage(),
        'This student has not shared any journal entries with you',
      );

      viewService.setSearchQuery('test');
      expect(viewService.getEmptyStateMessage(), 'No entries match your search');

      viewService.setSearchQuery('');
      viewService.setFilter('positive');
      expect(viewService.getEmptyStateMessage(), 'No entries match your search');
    });

    test('Should handle entries without optional fields', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': null,
          'content': 'Just content, no title',
          'sentiment': null,
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadStudentJournalEntries('student1', 'counselor1');

      expect(viewService.sharedJournalEntries.length, 1);
      final entry = viewService.sharedJournalEntries[0];
      expect(entry.title, isNull);
      expect(entry.sentiment, isNull);
      expect(entry.sentimentLabel, 'Unknown');
      expect(entry.sentimentEmoji, '😐');
    });
  });
}
