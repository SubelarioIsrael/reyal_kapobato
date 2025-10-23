// JM-JE-01: Student can view all of their journal entries
// Requirement: Students can view their journal entries with search, filter, and statistics
// Mirrors logic in `student_journal_entries.dart` (load, display, filter journal entries)

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

  Future<List<Map<String, dynamic>>> getJournalEntries(String userId) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (_shouldThrowError) {
      throw Exception('Error loading journal entries');
    }

    return _userJournals[userId] ?? [];
  }

  Future<Map<String, int>> getJournalStats(String userId) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (_shouldThrowError) {
      throw Exception('Error loading journal stats');
    }

    final entries = _userJournals[userId] ?? [];
    
    int totalEntries = entries.length;
    int sharedEntries = entries
        .where((entry) => entry['is_shared_with_counselor'] == true)
        .length;
    int positiveEntries = entries
        .where((entry) =>
            (entry['sentiment'] as String?)?.toLowerCase() == 'positive')
        .length;

    return {
      'total': totalEntries,
      'shared': sharedEntries,
      'positive': positiveEntries,
    };
  }

  void clear() {
    _userJournals.clear();
    _shouldThrowError = false;
  }
}

// Service class for viewing journal entries
class StudentJournalViewService {
  final MockJournalDatabase _database;
  List<MockJournalEntry> _journalEntries = [];
  List<MockJournalEntry> _filteredEntries = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  Map<String, int> _stats = {};

  StudentJournalViewService(this._database);

  List<MockJournalEntry> get journalEntries => _journalEntries;
  List<MockJournalEntry> get filteredEntries => _filteredEntries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  Map<String, int> get stats => _stats;

  Future<void> loadJournalEntries(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;

      final entriesData = await _database.getJournalEntries(userId);
      final statsData = await _database.getJournalStats(userId);

      _journalEntries = entriesData.map((data) => MockJournalEntry.fromMap(data)).toList();
      _filteredEntries = List.from(_journalEntries);
      _stats = statsData;

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _journalEntries = [];
      _filteredEntries = [];
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterEntries();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    _filterEntries();
  }

  void _filterEntries() {
    _filteredEntries = _journalEntries.where((entry) {
      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          (entry.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          entry.content.toLowerCase().contains(_searchQuery.toLowerCase());

      // Category filter
      bool matchesFilter = true;
      switch (_selectedFilter) {
        case 'shared':
          matchesFilter = entry.isSharedWithCounselor;
          break;
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

  bool hasJournalEntries() {
    return _journalEntries.isNotEmpty;
  }

  bool hasFilteredEntries() {
    return _filteredEntries.isNotEmpty;
  }

  int getJournalEntriesCount() {
    return _journalEntries.length;
  }

  int getFilteredEntriesCount() {
    return _filteredEntries.length;
  }

  List<MockJournalEntry> getSharedEntries() {
    return _journalEntries.where((entry) => entry.isSharedWithCounselor).toList();
  }

  List<MockJournalEntry> getEntriesBySentiment(String sentiment) {
    return _journalEntries
        .where((entry) => entry.sentiment?.toLowerCase() == sentiment.toLowerCase())
        .toList();
  }

  String getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty || _selectedFilter != 'all') {
      return 'No entries match your search';
    }
    return 'No mood journal entries yet';
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _journalEntries.clear();
    _filteredEntries.clear();
    _searchQuery = '';
    _selectedFilter = 'all';
    _stats.clear();
    _isLoading = false;
    _errorMessage = null;
  }

  MockJournalEntry? findEntryById(int journalId) {
    try {
      return _journalEntries.firstWhere((entry) => entry.journalId == journalId);
    } catch (e) {
      return null;
    }
  }

  List<String> getAvailableFilters() {
    return ['all', 'shared', 'positive', 'neutral', 'negative'];
  }

  Map<String, dynamic> getViewStatistics() {
    return {
      'total_entries': _journalEntries.length,
      'filtered_entries': _filteredEntries.length,
      'shared_entries': getSharedEntries().length,
      'positive_entries': getEntriesBySentiment('positive').length,
      'neutral_entries': getEntriesBySentiment('neutral').length,
      'negative_entries': getEntriesBySentiment('negative').length,
      'has_search_query': _searchQuery.isNotEmpty,
      'active_filter': _selectedFilter,
      'is_loaded': !_isLoading && _errorMessage == null,
      'stats': _stats,
    };
  }
}

void main() {
  group('JM-JE-01: Student can view all of their journal entries', () {
    late MockJournalDatabase mockDatabase;
    late StudentJournalViewService viewService;

    setUp(() {
      mockDatabase = MockJournalDatabase();
      viewService = StudentJournalViewService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('Should load journal entries successfully', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'First Entry',
          'content': 'Today was a great day!',
          'sentiment': 'positive',
          'insight': 'Feeling optimistic',
          'entry_timestamp': now.subtract(Duration(days: 2)).toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Second Entry',
          'content': 'Had some challenges today.',
          'sentiment': 'negative',
          'insight': 'Feeling stressed',
          'entry_timestamp': now.subtract(Duration(days: 1)).toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
        {
          'journal_id': 3,
          'title': null,
          'content': 'Just a regular day.',
          'sentiment': 'neutral',
          'insight': 'Feeling okay',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadJournalEntries('student1');

      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, isNull);
      expect(viewService.journalEntries.length, 3);
      expect(viewService.filteredEntries.length, 3);
      expect(viewService.hasJournalEntries(), true);
    });

    test('Should handle empty journal entries', () async {
      mockDatabase.seedJournalEntries('student1', []);

      await viewService.loadJournalEntries('student1');

      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, isNull);
      expect(viewService.journalEntries.length, 0);
      expect(viewService.hasJournalEntries(), false);
      expect(viewService.getEmptyStateMessage(), 'No mood journal entries yet');
    });

    test('Should handle loading errors', () async {
      mockDatabase.setShouldThrowError(true);

      await viewService.loadJournalEntries('student1');

      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, contains('Error loading journal entries'));
      expect(viewService.journalEntries.length, 0);
    });

    test('Should load journal statistics correctly', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry 1',
          'content': 'Content 1',
          'sentiment': 'positive',
          'insight': 'Insight 1',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Entry 2',
          'content': 'Content 2',
          'sentiment': 'positive',
          'insight': 'Insight 2',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 3,
          'title': 'Entry 3',
          'content': 'Content 3',
          'sentiment': 'negative',
          'insight': 'Insight 3',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadJournalEntries('student1');

      expect(viewService.stats['total'], 3);
      expect(viewService.stats['shared'], 2);
      expect(viewService.stats['positive'], 2);
    });

    test('Should filter entries by search query', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Great Day',
          'content': 'Today was amazing',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Tough Day',
          'content': 'Feeling stressed',
          'sentiment': 'negative',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadJournalEntries('student1');

      viewService.setSearchQuery('great');
      expect(viewService.filteredEntries.length, 1);
      expect(viewService.filteredEntries[0].title, 'Great Day');

      viewService.setSearchQuery('stressed');
      expect(viewService.filteredEntries.length, 1);
      expect(viewService.filteredEntries[0].title, 'Tough Day');

      viewService.setSearchQuery('day');
      expect(viewService.filteredEntries.length, 2);

      viewService.setSearchQuery('');
      expect(viewService.filteredEntries.length, 2);
    });

    test('Should filter entries by sentiment', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Positive Entry',
          'content': 'Great day',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Negative Entry',
          'content': 'Bad day',
          'sentiment': 'negative',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
        {
          'journal_id': 3,
          'title': 'Neutral Entry',
          'content': 'Normal day',
          'sentiment': 'neutral',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadJournalEntries('student1');

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

    test('Should filter entries by shared status', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Shared Entry',
          'content': 'Content 1',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Private Entry',
          'content': 'Content 2',
          'sentiment': 'neutral',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadJournalEntries('student1');

      viewService.setFilter('shared');
      expect(viewService.filteredEntries.length, 1);
      expect(viewService.filteredEntries[0].isSharedWithCounselor, true);
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
          'is_shared_with_counselor': false,
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

      await viewService.loadJournalEntries('student1');

      viewService.setFilter('positive');
      viewService.setSearchQuery('day');
      expect(viewService.filteredEntries.length, 1);
      expect(viewService.filteredEntries[0].title, 'Happy Day');

      viewService.setFilter('shared');
      viewService.setSearchQuery('day');
      expect(viewService.filteredEntries.length, 2);
    });

    test('Should get sentiment labels and emojis correctly', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Test',
          'content': 'Test',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadJournalEntries('student1');
      final entry = viewService.journalEntries[0];

      expect(entry.sentimentLabel, 'Positive');
      expect(entry.sentimentEmoji, '😊');

      // Test different sentiments
      final negativeEntry = MockJournalEntry(
        journalId: 2,
        content: 'Test',
        sentiment: 'negative',
        entryTimestamp: now,
        isSharedWithCounselor: false,
        userId: 'student1',
      );
      expect(negativeEntry.sentimentLabel, 'Negative');
      expect(negativeEntry.sentimentEmoji, '😔');

      final neutralEntry = MockJournalEntry(
        journalId: 3,
        content: 'Test',
        sentiment: 'neutral',
        entryTimestamp: now,
        isSharedWithCounselor: false,
        userId: 'student1',
      );
      expect(neutralEntry.sentimentLabel, 'Neutral');
      expect(neutralEntry.sentimentEmoji, '😐');
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
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Entry 2',
          'content': 'Content 2',
          'sentiment': 'neutral',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadJournalEntries('student1');

      final found = viewService.findEntryById(1);
      expect(found, isNotNull);
      expect(found!.title, 'Entry 1');

      final notFound = viewService.findEntryById(999);
      expect(notFound, isNull);
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
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Entry 2',
          'content': 'Content 2',
          'sentiment': 'positive',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
        {
          'journal_id': 3,
          'title': 'Entry 3',
          'content': 'Content 3',
          'sentiment': 'negative',
          'insight': null,
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadJournalEntries('student1');

      final positiveEntries = viewService.getEntriesBySentiment('positive');
      expect(positiveEntries.length, 2);

      final negativeEntries = viewService.getEntriesBySentiment('negative');
      expect(negativeEntries.length, 1);
    });

    test('Should generate view statistics', () async {
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
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadJournalEntries('student1');
      viewService.setFilter('positive');

      final stats = viewService.getViewStatistics();

      expect(stats['total_entries'], 2);
      expect(stats['filtered_entries'], 1);
      expect(stats['shared_entries'], 1);
      expect(stats['positive_entries'], 1);
      expect(stats['negative_entries'], 1);
      expect(stats['active_filter'], 'positive');
      expect(stats['is_loaded'], true);
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
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadJournalEntries('student1');
      viewService.setSearchQuery('test');
      viewService.setFilter('positive');

      expect(viewService.journalEntries.length, 1);
      expect(viewService.searchQuery, 'test');
      expect(viewService.selectedFilter, 'positive');

      viewService.reset();

      expect(viewService.journalEntries.length, 0);
      expect(viewService.searchQuery, '');
      expect(viewService.selectedFilter, 'all');
      expect(viewService.stats, isEmpty);
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
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await viewService.loadJournalEntries('student1');

      expect(viewService.journalEntries.length, 1);
      final entry = viewService.journalEntries[0];
      expect(entry.title, isNull);
      expect(entry.sentiment, isNull);
      expect(entry.sentimentLabel, 'Unknown');
      expect(entry.sentimentEmoji, '😐');
    });

    test('Should get available filters', () {
      final filters = viewService.getAvailableFilters();
      expect(filters, containsAll(['all', 'shared', 'positive', 'neutral', 'negative']));
    });

    test('Should return correct empty state messages', () async {
      mockDatabase.seedJournalEntries('student1', []);

      await viewService.loadJournalEntries('student1');

      expect(viewService.getEmptyStateMessage(), 'No mood journal entries yet');

      viewService.setSearchQuery('test');
      expect(viewService.getEmptyStateMessage(), 'No entries match your search');

      viewService.setSearchQuery('');
      viewService.setFilter('positive');
      expect(viewService.getEmptyStateMessage(), 'No entries match your search');
    });
  });
}
