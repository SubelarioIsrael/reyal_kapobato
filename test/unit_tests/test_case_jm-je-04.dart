// JM-JE-04: Student can delete their own journal entry
// Requirement: Students can delete their journal entries with confirmation
// Mirrors logic in `student_journal_entries.dart` (_deleteEntry method)

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

  Future<bool> deleteJournalEntry(int journalId, String userId) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (_shouldThrowError) {
      throw Exception('Error deleting journal entry');
    }

    final userEntries = _userJournals[userId] ?? [];
    final entryIndex = userEntries.indexWhere((entry) => entry['journal_id'] == journalId);

    if (entryIndex == -1) {
      return false;
    }

    // Verify ownership
    if (userEntries[entryIndex]['user_id'] != userId) {
      throw Exception('Unauthorized to delete this entry');
    }

    userEntries.removeAt(entryIndex);
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

// Service class for deleting journal entries
class StudentJournalDeleteService {
  final MockJournalDatabase _database;
  List<MockJournalEntry> _journalEntries = [];
  bool _isDeleting = false;
  String? _errorMessage;
  bool _showConfirmationDialog = false;
  int? _pendingDeleteId;

  StudentJournalDeleteService(this._database);

  List<MockJournalEntry> get journalEntries => _journalEntries;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  bool get showConfirmationDialog => _showConfirmationDialog;
  int? get pendingDeleteId => _pendingDeleteId;

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

  void requestDeleteEntry(int journalId) {
    _pendingDeleteId = journalId;
    _showConfirmationDialog = true;
  }

  void cancelDeleteEntry() {
    _pendingDeleteId = null;
    _showConfirmationDialog = false;
  }

  Future<bool> confirmDeleteEntry(String userId) async {
    if (_pendingDeleteId == null) {
      return false;
    }

    try {
      _isDeleting = true;
      _errorMessage = null;

      final success = await _database.deleteJournalEntry(_pendingDeleteId!, userId);

      if (success) {
        // Reload entries after deletion
        await loadJournalEntries(userId);
      }

      _isDeleting = false;
      _showConfirmationDialog = false;
      _pendingDeleteId = null;

      return success;
    } catch (e) {
      _isDeleting = false;
      _errorMessage = e.toString();
      _showConfirmationDialog = false;
      _pendingDeleteId = null;
      return false;
    }
  }

  bool entryExists(int journalId) {
    return _journalEntries.any((entry) => entry.journalId == journalId);
  }

  MockJournalEntry? findEntryById(int journalId) {
    try {
      return _journalEntries.firstWhere((entry) => entry.journalId == journalId);
    } catch (e) {
      return null;
    }
  }

  int getEntriesCount() {
    return _journalEntries.length;
  }

  bool canDeleteEntry(int journalId, String userId) {
    final entry = findEntryById(journalId);
    if (entry == null) return false;
    return entry.userId == userId;
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _journalEntries.clear();
    _isDeleting = false;
    _errorMessage = null;
    _showConfirmationDialog = false;
    _pendingDeleteId = null;
  }

  String getConfirmationMessage(int journalId) {
    final entry = findEntryById(journalId);
    if (entry == null) {
      return 'Are you sure you want to delete this entry?';
    }
    if (entry.title != null && entry.title!.isNotEmpty) {
      return 'Are you sure you want to delete "${entry.title}"?';
    }
    return 'Are you sure you want to delete this journal entry?';
  }

  Map<String, dynamic> getDeleteStatistics() {
    return {
      'total_entries': _journalEntries.length,
      'is_deleting': _isDeleting,
      'has_error': _errorMessage != null,
      'confirmation_pending': _showConfirmationDialog,
      'pending_delete_id': _pendingDeleteId,
    };
  }
}

void main() {
  group('JM-JE-04: Student can delete their own journal entry', () {
    late MockJournalDatabase mockDatabase;
    late StudentJournalDeleteService deleteService;

    setUp(() {
      mockDatabase = MockJournalDatabase();
      deleteService = StudentJournalDeleteService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('Should delete journal entry successfully', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry to Delete',
          'content': 'This entry will be deleted',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
        {
          'journal_id': 2,
          'title': 'Entry to Keep',
          'content': 'This entry will remain',
          'sentiment': 'neutral',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await deleteService.loadJournalEntries('student1');
      expect(deleteService.journalEntries.length, 2);

      deleteService.requestDeleteEntry(1);
      expect(deleteService.showConfirmationDialog, true);
      expect(deleteService.pendingDeleteId, 1);

      final result = await deleteService.confirmDeleteEntry('student1');

      expect(result, true);
      expect(deleteService.isDeleting, false);
      expect(deleteService.errorMessage, isNull);
      expect(deleteService.journalEntries.length, 1);
      expect(deleteService.journalEntries[0].journalId, 2);
      expect(deleteService.showConfirmationDialog, false);
      expect(deleteService.pendingDeleteId, isNull);
    });

    test('Should show confirmation dialog before deleting', () async {
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

      await deleteService.loadJournalEntries('student1');

      deleteService.requestDeleteEntry(1);

      expect(deleteService.showConfirmationDialog, true);
      expect(deleteService.pendingDeleteId, 1);
      expect(deleteService.journalEntries.length, 1); // Not deleted yet
    });

    test('Should cancel delete request', () async {
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

      await deleteService.loadJournalEntries('student1');

      deleteService.requestDeleteEntry(1);
      expect(deleteService.showConfirmationDialog, true);

      deleteService.cancelDeleteEntry();

      expect(deleteService.showConfirmationDialog, false);
      expect(deleteService.pendingDeleteId, isNull);
      expect(deleteService.journalEntries.length, 1); // Entry still exists
    });

    test('Should handle deletion of non-existent entry', () async {
      mockDatabase.seedJournalEntries('student1', []);

      await deleteService.loadJournalEntries('student1');

      deleteService.requestDeleteEntry(999);
      final result = await deleteService.confirmDeleteEntry('student1');

      expect(result, false);
    });

    test('Should handle database errors', () async {
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

      await deleteService.loadJournalEntries('student1');
      mockDatabase.setShouldThrowError(true);

      deleteService.requestDeleteEntry(1);
      final result = await deleteService.confirmDeleteEntry('student1');

      expect(result, false);
      expect(deleteService.errorMessage, contains('Error deleting journal entry'));
    });

    test('Should verify entry exists before deletion', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Existing Entry',
          'content': 'Content',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await deleteService.loadJournalEntries('student1');

      expect(deleteService.entryExists(1), true);
      expect(deleteService.entryExists(999), false);
    });

    test('Should find entry by ID', () async {
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

      await deleteService.loadJournalEntries('student1');

      final found = deleteService.findEntryById(1);
      expect(found, isNotNull);
      expect(found!.title, 'Test Entry');

      final notFound = deleteService.findEntryById(999);
      expect(notFound, isNull);
    });

    test('Should verify user can delete their own entries', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'My Entry',
          'content': 'My content',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await deleteService.loadJournalEntries('student1');

      expect(deleteService.canDeleteEntry(1, 'student1'), true);
      expect(deleteService.canDeleteEntry(999, 'student1'), false);
    });

    test('Should get confirmation message with title', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'My Journal Entry',
          'content': 'Content',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await deleteService.loadJournalEntries('student1');

      final message = deleteService.getConfirmationMessage(1);
      expect(message, contains('My Journal Entry'));
    });

    test('Should get generic confirmation message without title', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': null,
          'content': 'Content',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await deleteService.loadJournalEntries('student1');

      final message = deleteService.getConfirmationMessage(1);
      expect(message, contains('journal entry'));
      expect(message, isNot(contains('null')));
    });

    test('Should delete shared entries', () async {
      final now = DateTime.now();
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Shared Entry',
          'content': 'This is shared with counselor',
          'sentiment': 'positive',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': true,
          'user_id': 'student1',
        },
      ]);

      await deleteService.loadJournalEntries('student1');

      deleteService.requestDeleteEntry(1);
      final result = await deleteService.confirmDeleteEntry('student1');

      expect(result, true);
      expect(deleteService.journalEntries.length, 0);
    });

    test('Should delete multiple entries sequentially', () async {
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
        {
          'journal_id': 3,
          'title': 'Entry 3',
          'content': 'Content 3',
          'sentiment': 'negative',
          'entry_timestamp': now.toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await deleteService.loadJournalEntries('student1');
      expect(deleteService.journalEntries.length, 3);

      deleteService.requestDeleteEntry(1);
      await deleteService.confirmDeleteEntry('student1');
      expect(deleteService.journalEntries.length, 2);

      deleteService.requestDeleteEntry(3);
      await deleteService.confirmDeleteEntry('student1');
      expect(deleteService.journalEntries.length, 1);
      expect(deleteService.journalEntries[0].journalId, 2);
    });

    test('Should get entries count', () async {
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

      await deleteService.loadJournalEntries('student1');

      expect(deleteService.getEntriesCount(), 2);

      deleteService.requestDeleteEntry(1);
      await deleteService.confirmDeleteEntry('student1');

      expect(deleteService.getEntriesCount(), 1);
    });

    test('Should generate delete statistics', () async {
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

      await deleteService.loadJournalEntries('student1');
      deleteService.requestDeleteEntry(1);

      final stats = deleteService.getDeleteStatistics();

      expect(stats['total_entries'], 1);
      expect(stats['confirmation_pending'], true);
      expect(stats['pending_delete_id'], 1);
    });

    test('Should clear error message', () async {
      mockDatabase.setShouldThrowError(true);
      mockDatabase.seedJournalEntries('student1', [
        {
          'journal_id': 1,
          'title': 'Entry',
          'content': 'Content',
          'sentiment': 'positive',
          'entry_timestamp': DateTime.now().toIso8601String(),
          'is_shared_with_counselor': false,
          'user_id': 'student1',
        },
      ]);

      await deleteService.loadJournalEntries('student1');
      deleteService.requestDeleteEntry(1);
      await deleteService.confirmDeleteEntry('student1');

      expect(deleteService.errorMessage, isNotNull);

      deleteService.clearError();
      expect(deleteService.errorMessage, isNull);
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

      await deleteService.loadJournalEntries('student1');
      deleteService.requestDeleteEntry(1);

      expect(deleteService.journalEntries.length, 1);
      expect(deleteService.showConfirmationDialog, true);

      deleteService.reset();

      expect(deleteService.journalEntries.length, 0);
      expect(deleteService.showConfirmationDialog, false);
      expect(deleteService.pendingDeleteId, isNull);
      expect(deleteService.isDeleting, false);
    });

    test('Should not delete without confirmation', () async {
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

      await deleteService.loadJournalEntries('student1');

      // Try to delete without requesting
      final result = await deleteService.confirmDeleteEntry('student1');

      expect(result, false);
      expect(deleteService.journalEntries.length, 1);
    });
  });
}
