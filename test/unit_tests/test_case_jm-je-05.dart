// JM-JE-05: Student can enable journal entry sharing with counselor
// Requirement: Students can toggle counselor sharing status on their journal entries
// Mirrors logic in `student_mood_journal.dart` and `student_journal_entries.dart`

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent a journal entry
class MockJournalEntry {
  final int journalId;
  final String? title;
  final String content;
  final String? sentiment;
  final DateTime entryTimestamp;
  final bool isSharedWithCounselor;
  final String userId;

  MockJournalEntry({
    required this.journalId,
    this.title,
    required this.content,
    this.sentiment,
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
      entryTimestamp: DateTime.parse(map['entry_timestamp']),
      isSharedWithCounselor: map['is_shared_with_counselor'] ?? false,
      userId: map['user_id'],
    );
  }

  MockJournalEntry copyWith({bool? isSharedWithCounselor}) {
    return MockJournalEntry(
      journalId: journalId,
      title: title,
      content: content,
      sentiment: sentiment,
      entryTimestamp: entryTimestamp,
      isSharedWithCounselor: isSharedWithCounselor ?? this.isSharedWithCounselor,
      userId: userId,
    );
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

  Future<bool> updateJournalEntry(int journalId, String userId, Map<String, dynamic> updates) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (_shouldThrowError) {
      throw Exception('Error updating journal entry');
    }

    final userEntries = _userJournals[userId] ?? [];
    final entryIndex = userEntries.indexWhere((entry) => entry['journal_id'] == journalId);

    if (entryIndex == -1) {
      return false;
    }

    // Verify ownership
    if (userEntries[entryIndex]['user_id'] != userId) {
      throw Exception('Unauthorized to update this entry');
    }

    userEntries[entryIndex] = {
      ...userEntries[entryIndex],
      ...updates,
    };

    return true;
  }

  Future<List<Map<String, dynamic>>> getJournalEntries(String userId) async {
    await Future.delayed(Duration(milliseconds: 50));
    return _userJournals[userId] ?? [];
  }

  Map<String, dynamic>? findEntryById(int journalId, String userId) {
    final userEntries = _userJournals[userId] ?? [];
    try {
      return userEntries.firstWhere((entry) => entry['journal_id'] == journalId);
    } catch (e) {
      return null;
    }
  }

  void clear() {
    _userJournals.clear();
    _shouldThrowError = false;
  }
}

// Service class for managing journal entry sharing
class StudentJournalSharingService {
  final MockJournalDatabase _database;
  List<MockJournalEntry> _journalEntries = [];
  bool _isUpdating = false;
  String? _errorMessage;

  StudentJournalSharingService(this._database);

  List<MockJournalEntry> get journalEntries => _journalEntries;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  Future<void> loadJournalEntries(String userId) async {
    try {
      final entriesData = await _database.getJournalEntries(userId);
      _journalEntries = entriesData.map((data) => MockJournalEntry.fromMap(data)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _journalEntries = [];
    }
  }

  Future<bool> toggleSharingStatus(int journalId, String userId) async {
    try {
      _isUpdating = true;
      _errorMessage = null;

      final entry = findEntryById(journalId);
      if (entry == null) {
        throw Exception('Journal entry not found');
      }

      final newSharingStatus = !entry.isSharedWithCounselor;

      final success = await _database.updateJournalEntry(
        journalId,
        userId,
        {'is_shared_with_counselor': newSharingStatus},
      );

      if (success) {
        // Reload entries after update
        await loadJournalEntries(userId);
      }

      _isUpdating = false;
      return success;
    } catch (e) {
      _isUpdating = false;
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> enableSharing(int journalId, String userId) async {
    try {
      _isUpdating = true;
      _errorMessage = null;

      final success = await _database.updateJournalEntry(
        journalId,
        userId,
        {'is_shared_with_counselor': true},
      );

      if (success) {
        await loadJournalEntries(userId);
      }

      _isUpdating = false;
      return success;
    } catch (e) {
      _isUpdating = false;
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> disableSharing(int journalId, String userId) async {
    try {
      _isUpdating = true;
      _errorMessage = null;

      final success = await _database.updateJournalEntry(
        journalId,
        userId,
        {'is_shared_with_counselor': false},
      );

      if (success) {
        await loadJournalEntries(userId);
      }

      _isUpdating = false;
      return success;
    } catch (e) {
      _isUpdating = false;
      _errorMessage = e.toString();
      return false;
    }
  }

  MockJournalEntry? findEntryById(int journalId) {
    try {
      return _journalEntries.firstWhere((entry) => entry.journalId == journalId);
    } catch (e) {
      return null;
    }
  }

  bool isEntryShared(int journalId) {
    final entry = findEntryById(journalId);
    return entry?.isSharedWithCounselor ?? false;
  }

  List<MockJournalEntry> getSharedEntries() {
    return _journalEntries.where((entry) => entry.isSharedWithCounselor).toList();
  }

  List<MockJournalEntry> getPrivateEntries() {
    return _journalEntries.where((entry) => !entry.isSharedWithCounselor).toList();
  }

  int getSharedEntriesCount() {
    return getSharedEntries().length;
  }

  int getPrivateEntriesCount() {
    return getPrivateEntries().length;
  }

  bool canToggleSharing(int journalId, String userId) {
    final entry = findEntryById(journalId);
    return entry != null && entry.userId == userId;
  }

  String getSharingStatusLabel(int journalId) {
    return isEntryShared(journalId) ? 'Shared with counselor' : 'Private';
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _journalEntries.clear();
    _isUpdating = false;
    _errorMessage = null;
  }

  Map<String, dynamic> getSharingStatistics() {
    return {
      'total_entries': _journalEntries.length,
      'shared_entries': getSharedEntriesCount(),
      'private_entries': getPrivateEntriesCount(),
      'is_updating': _isUpdating,
      'has_error': _errorMessage != null,
    };
  }
}

void main() {
  group('JM-JE-05: Student can enable journal entry sharing with counselor', () {
    late MockJournalDatabase mockDatabase;
    late StudentJournalSharingService sharingService;

    setUp(() {
      mockDatabase = MockJournalDatabase();
      sharingService = StudentJournalSharingService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('Should toggle sharing from private to shared', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Private Entry',
          'content': 'This is currently private',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');
      expect(sharingService.isEntryShared(1), false);

      final result = await sharingService.toggleSharingStatus(1, 'student1');

      expect(result, true);
      expect(sharingService.isUpdating, false);
      expect(sharingService.errorMessage, isNull);
      expect(sharingService.isEntryShared(1), true);
    });

    test('Should toggle sharing from shared to private', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Shared Entry',
          'content': 'This is currently shared',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');
      expect(sharingService.isEntryShared(1), true);

      final result = await sharingService.toggleSharingStatus(1, 'student1');

      expect(result, true);
      expect(sharingService.isEntryShared(1), false);
    });

    test('Should enable sharing for private entry', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry',
          'content': 'Content',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');

      final result = await sharingService.enableSharing(1, 'student1');

      expect(result, true);
      expect(sharingService.isEntryShared(1), true);
    });

    test('Should disable sharing for shared entry', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry',
          'content': 'Content',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');

      final result = await sharingService.disableSharing(1, 'student1');

      expect(result, true);
      expect(sharingService.isEntryShared(1), false);
    });

    test('Should get shared entries', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Shared 1',
          'content': 'Content 1',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Private 1',
          'content': 'Content 2',
          'sentiment': 'neutral',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
        {
          'journal_id': 3,
          'title': 'Shared 2',
          'content': 'Content 3',
          'sentiment': 'negative',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');

      final sharedEntries = sharingService.getSharedEntries();
      expect(sharedEntries.length, 2);
      expect(sharedEntries[0].journalId, 1);
      expect(sharedEntries[1].journalId, 3);
    });

    test('Should get private entries', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Shared 1',
          'content': 'Content 1',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Private 1',
          'content': 'Content 2',
          'sentiment': 'neutral',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');

      final privateEntries = sharingService.getPrivateEntries();
      expect(privateEntries.length, 1);
      expect(privateEntries[0].journalId, 2);
    });

    test('Should count shared and private entries', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Shared 1',
          'content': 'Content 1',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Shared 2',
          'content': 'Content 2',
          'sentiment': 'neutral',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 3,
          'title': 'Private 1',
          'content': 'Content 3',
          'sentiment': 'negative',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');

      expect(sharingService.getSharedEntriesCount(), 2);
      expect(sharingService.getPrivateEntriesCount(), 1);
    });

    test('Should get sharing status label', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Shared',
          'content': 'Content',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Private',
          'content': 'Content',
          'sentiment': 'neutral',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');

      expect(sharingService.getSharingStatusLabel(1), 'Shared with counselor');
      expect(sharingService.getSharingStatusLabel(2), 'Private');
    });

    test('Should verify user can toggle sharing', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry',
          'content': 'Content',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');

      expect(sharingService.canToggleSharing(1, 'student1'), true);
      expect(sharingService.canToggleSharing(999, 'student1'), false);
    });

    test('Should handle non-existent entry', () async {
      mockDatabase.seedJournalEntries('student1', []);

      await sharingService.loadJournalEntries('student1');

      final result = await sharingService.toggleSharingStatus(999, 'student1');

      expect(result, false);
      expect(sharingService.errorMessage, contains('not found'));
    });

    test('Should handle database errors', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry',
          'content': 'Content',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');
      mockDatabase.setShouldThrowError(true);

      final result = await sharingService.toggleSharingStatus(1, 'student1');

      expect(result, false);
      expect(sharingService.errorMessage, contains('Error updating journal entry'));
    });

    test('Should toggle multiple entries', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry 1',
          'content': 'Content 1',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Entry 2',
          'content': 'Content 2',
          'sentiment': 'neutral',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');

      await sharingService.toggleSharingStatus(1, 'student1');
      expect(sharingService.isEntryShared(1), true);
      expect(sharingService.isEntryShared(2), false);

      await sharingService.toggleSharingStatus(2, 'student1');
      expect(sharingService.isEntryShared(1), true);
      expect(sharingService.isEntryShared(2), true);
    });

    test('Should generate sharing statistics', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Shared',
          'content': 'Content',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Private',
          'content': 'Content',
          'sentiment': 'neutral',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');

      final stats = sharingService.getSharingStatistics();

      expect(stats['total_entries'], 2);
      expect(stats['shared_entries'], 1);
      expect(stats['private_entries'], 1);
      expect(stats['is_updating'], false);
    });

    test('Should clear error message', () async {
      mockDatabase.setShouldThrowError(true);

      await sharingService.toggleSharingStatus(1, 'student1');

      expect(sharingService.errorMessage, isNotNull);

      sharingService.clearError();
      expect(sharingService.errorMessage, isNull);
    });

    test('Should reset service state', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry',
          'content': 'Content',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');

      expect(sharingService.journalEntries.length, 1);

      sharingService.reset();

      expect(sharingService.journalEntries.length, 0);
      expect(sharingService.isUpdating, false);
      expect(sharingService.errorMessage, isNull);
    });

    test('Should maintain other entry fields when toggling sharing', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Test Entry',
          'content': 'Test content',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await sharingService.loadJournalEntries('student1');

      final originalEntry = sharingService.findEntryById(1);
      expect(originalEntry!.title, 'Test Entry');
      expect(originalEntry.content, 'Test content');

      await sharingService.toggleSharingStatus(1, 'student1');

      final updatedEntry = sharingService.findEntryById(1);
      expect(updatedEntry!.title, 'Test Entry');
      expect(updatedEntry.content, 'Test content');
      expect(updatedEntry.isSharedWithCounselor, true);
    });
  });
}
