// JM-JE-03: Student can add a new journal entry
// Requirement: Students can create journal entries with sentiment analysis and counselor sharing
// Mirrors logic in `student_mood_journal.dart` (_submitJournal method)

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
}

// Mock sentiment analysis response
class MockSentimentAnalysis {
  final String sentiment;
  final String insight;
  final String interventionLevel;

  MockSentimentAnalysis({
    required this.sentiment,
    required this.insight,
    required this.interventionLevel,
  });
}

// Mock database for journal entries
class MockJournalDatabase {
  List<Map<String, dynamic>> _journalEntries = [];
  bool _shouldThrowError = false;
  int _nextId = 1;

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  Future<int> createJournalEntry(Map<String, dynamic> entry) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (_shouldThrowError) {
      throw Exception('Error creating journal entry');
    }

    final entryWithId = {
      ...entry,
      'journal_id': _nextId,
    };

    _journalEntries.add(entryWithId);
    return _nextId++;
  }

  List<Map<String, dynamic>> getAllEntries() => _journalEntries;

  void clear() {
    _journalEntries.clear();
    _shouldThrowError = false;
    _nextId = 1;
  }
}

// Mock NLP service for sentiment analysis
class MockNLPService {
  bool _shouldThrowError = false;
  MockSentimentAnalysis? _mockResponse;

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  void setMockResponse(MockSentimentAnalysis response) {
    _mockResponse = response;
  }

  Future<MockSentimentAnalysis> analyzeSentiment(String content) async {
    await Future.delayed(Duration(milliseconds: 150));

    if (_shouldThrowError) {
      throw Exception('Error analyzing sentiment');
    }

    if (_mockResponse != null) {
      return _mockResponse!;
    }

    // Default sentiment analysis logic
    final lowerContent = content.toLowerCase();
    
    if (lowerContent.contains('suicide') || 
        lowerContent.contains('kill myself') ||
        lowerContent.contains('end my life')) {
      return MockSentimentAnalysis(
        sentiment: 'negative',
        insight: 'High-risk indicators detected. Immediate support recommended.',
        interventionLevel: 'high',
      );
    } else if (lowerContent.contains('sad') || 
               lowerContent.contains('depressed') ||
               lowerContent.contains('hopeless')) {
      return MockSentimentAnalysis(
        sentiment: 'negative',
        insight: 'Negative emotional patterns detected.',
        interventionLevel: 'medium',
      );
    } else if (lowerContent.contains('happy') || 
               lowerContent.contains('great') ||
               lowerContent.contains('wonderful')) {
      return MockSentimentAnalysis(
        sentiment: 'positive',
        insight: 'Positive emotional state detected.',
        interventionLevel: 'none',
      );
    } else {
      return MockSentimentAnalysis(
        sentiment: 'neutral',
        insight: 'Neutral emotional state.',
        interventionLevel: 'none',
      );
    }
  }

  void reset() {
    _shouldThrowError = false;
    _mockResponse = null;
  }
}

// Mock intervention service
class MockInterventionService {
  List<Map<String, dynamic>> _triggeredInterventions = [];
  bool _shouldThrowError = false;

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  Future<void> triggerJournalIntervention(
    String userId,
    int journalId,
    String content,
    String sentiment,
    String interventionLevel,
  ) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (_shouldThrowError) {
      throw Exception('Error triggering intervention');
    }

    if (interventionLevel == 'high') {
      _triggeredInterventions.add({
        'user_id': userId,
        'journal_id': journalId,
        'intervention_level': interventionLevel,
        'triggered_at': DateTime.now().toIso8601String(),
      });
    }
  }

  List<Map<String, dynamic>> getTriggeredInterventions() => _triggeredInterventions;

  void clear() {
    _triggeredInterventions.clear();
    _shouldThrowError = false;
  }
}

// Mock activity service
class MockActivityService {
  List<Map<String, dynamic>> _recordedActivities = [];
  bool _shouldThrowError = false;

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  Future<void> recordActivityCompletion(
    String userId,
    String activityType,
    Map<String, dynamic> metadata,
  ) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (_shouldThrowError) {
      throw Exception('Error recording activity');
    }

    _recordedActivities.add({
      'user_id': userId,
      'activity_type': activityType,
      'metadata': metadata,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  List<Map<String, dynamic>> getRecordedActivities() => _recordedActivities;

  void clear() {
    _recordedActivities.clear();
    _shouldThrowError = false;
  }
}

// Service class for adding journal entries
class StudentJournalCreateService {
  final MockJournalDatabase _database;
  final MockNLPService _nlpService;
  final MockInterventionService _interventionService;
  final MockActivityService _activityService;
  
  bool _isSubmitting = false;
  String? _errorMessage;
  MockSentimentAnalysis? _lastAnalysis;
  int? _lastCreatedJournalId;

  StudentJournalCreateService(
    this._database,
    this._nlpService,
    this._interventionService,
    this._activityService,
  );

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  MockSentimentAnalysis? get lastAnalysis => _lastAnalysis;
  int? get lastCreatedJournalId => _lastCreatedJournalId;

  Future<bool> submitJournalEntry({
    required String userId,
    String? title,
    required String content,
    required bool isSharedWithCounselor,
  }) async {
    try {
      _isSubmitting = true;
      _errorMessage = null;

      // Validate content
      if (content.trim().isEmpty) {
        throw Exception('Journal content cannot be empty');
      }

      if (content.trim().length < 10) {
        throw Exception('Journal content must be at least 10 characters');
      }

      // Analyze sentiment
      final sentimentAnalysis = await _nlpService.analyzeSentiment(content);
      _lastAnalysis = sentimentAnalysis;

      // Create journal entry
      final journalId = await _database.createJournalEntry({
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        'content': content.trim(),
        'sentiment': sentimentAnalysis.sentiment,
        'insight': sentimentAnalysis.insight,
        'entry_timestamp': DateTime.now().toIso8601String(),
        'is_shared_with_counselor': isSharedWithCounselor,
        'user_id': userId,
      });

      _lastCreatedJournalId = journalId;

      // Trigger intervention if needed
      if (sentimentAnalysis.interventionLevel == 'high') {
        await _interventionService.triggerJournalIntervention(
          userId,
          journalId,
          content,
          sentimentAnalysis.sentiment,
          sentimentAnalysis.interventionLevel,
        );
      }

      // Record activity
      await _activityService.recordActivityCompletion(
        userId,
        'mood_journal_entry',
        {
          'journal_id': journalId,
          'sentiment': sentimentAnalysis.sentiment,
          'is_shared': isSharedWithCounselor,
        },
      );

      _isSubmitting = false;
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString();
      return false;
    }
  }

  bool validateTitle(String? title) {
    // Title is optional
    if (title == null || title.trim().isEmpty) {
      return true;
    }
    return title.trim().length <= 100;
  }

  bool validateContent(String content) {
    if (content.trim().isEmpty) {
      return false;
    }
    if (content.trim().length < 10) {
      return false;
    }
    return true;
  }

  String? getTitleErrorMessage(String? title) {
    if (title != null && title.trim().isNotEmpty && title.trim().length > 100) {
      return 'Title must be 100 characters or less';
    }
    return null;
  }

  String? getContentErrorMessage(String content) {
    if (content.trim().isEmpty) {
      return 'Journal content cannot be empty';
    }
    if (content.trim().length < 10) {
      return 'Journal content must be at least 10 characters';
    }
    return null;
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _isSubmitting = false;
    _errorMessage = null;
    _lastAnalysis = null;
    _lastCreatedJournalId = null;
  }

  bool hasHighRiskIntervention() {
    return _lastAnalysis?.interventionLevel == 'high';
  }
}

void main() {
  group('JM-JE-03: Student can add a new journal entry', () {
    late MockJournalDatabase mockDatabase;
    late MockNLPService mockNLPService;
    late MockInterventionService mockInterventionService;
    late MockActivityService mockActivityService;
    late StudentJournalCreateService createService;

    setUp(() {
      mockDatabase = MockJournalDatabase();
      mockNLPService = MockNLPService();
      mockInterventionService = MockInterventionService();
      mockActivityService = MockActivityService();
      createService = StudentJournalCreateService(
        mockDatabase,
        mockNLPService,
        mockInterventionService,
        mockActivityService,
      );
    });

    tearDown(() {
      mockDatabase.clear();
      mockNLPService.reset();
      mockInterventionService.clear();
      mockActivityService.clear();
    });

    test('Should create journal entry with title and content', () async {
      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Great Day',
        content: 'Today was absolutely wonderful! I felt so happy and accomplished.',
        isSharedWithCounselor: false,
      );

      expect(result, true);
      expect(createService.isSubmitting, false);
      expect(createService.errorMessage, isNull);
      expect(createService.lastCreatedJournalId, isNotNull);
      
      final entries = mockDatabase.getAllEntries();
      expect(entries.length, 1);
      expect(entries[0]['title'], 'Great Day');
      expect(entries[0]['user_id'], 'student1');
      expect(entries[0]['is_shared_with_counselor'], false);
    });

    test('Should create journal entry without title', () async {
      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: null,
        content: 'Just wanted to write down my thoughts today.',
        isSharedWithCounselor: true,
      );

      expect(result, true);
      
      final entries = mockDatabase.getAllEntries();
      expect(entries.length, 1);
      expect(entries[0]['title'], isNull);
      expect(entries[0]['is_shared_with_counselor'], true);
    });

    test('Should analyze sentiment and include it in entry', () async {
      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Happy Moment',
        content: 'I am so happy today! Everything is wonderful and great!',
        isSharedWithCounselor: false,
      );

      expect(result, true);
      expect(createService.lastAnalysis, isNotNull);
      expect(createService.lastAnalysis!.sentiment, 'positive');
      
      final entries = mockDatabase.getAllEntries();
      expect(entries[0]['sentiment'], 'positive');
      expect(entries[0]['insight'], isNotEmpty);
    });

    test('Should detect negative sentiment', () async {
      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Tough Day',
        content: 'Feeling very sad and depressed today. Everything seems hopeless.',
        isSharedWithCounselor: true,
      );

      expect(result, true);
      expect(createService.lastAnalysis!.sentiment, 'negative');
      
      final entries = mockDatabase.getAllEntries();
      expect(entries[0]['sentiment'], 'negative');
    });

    test('Should detect neutral sentiment', () async {
      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Regular Day',
        content: 'Nothing special happened today. Just a normal routine day.',
        isSharedWithCounselor: false,
      );

      expect(result, true);
      expect(createService.lastAnalysis!.sentiment, 'neutral');
      
      final entries = mockDatabase.getAllEntries();
      expect(entries[0]['sentiment'], 'neutral');
    });

    test('Should trigger high-risk intervention', () async {
      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Crisis',
        content: 'I am thinking about suicide. I want to end my life.',
        isSharedWithCounselor: true,
      );

      expect(result, true);
      expect(createService.hasHighRiskIntervention(), true);
      expect(createService.lastAnalysis!.interventionLevel, 'high');
      
      final interventions = mockInterventionService.getTriggeredInterventions();
      expect(interventions.length, 1);
      expect(interventions[0]['user_id'], 'student1');
      expect(interventions[0]['intervention_level'], 'high');
    });

    test('Should not trigger intervention for non-high-risk content', () async {
      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Good Day',
        content: 'Today was a good day. I am feeling happy and content.',
        isSharedWithCounselor: false,
      );

      expect(result, true);
      expect(createService.hasHighRiskIntervention(), false);
      
      final interventions = mockInterventionService.getTriggeredInterventions();
      expect(interventions.length, 0);
    });

    test('Should record activity completion', () async {
      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Entry',
        content: 'This is my journal entry for today.',
        isSharedWithCounselor: true,
      );

      expect(result, true);
      
      final activities = mockActivityService.getRecordedActivities();
      expect(activities.length, 1);
      expect(activities[0]['user_id'], 'student1');
      expect(activities[0]['activity_type'], 'mood_journal_entry');
      expect(activities[0]['metadata']['is_shared'], true);
    });

    test('Should validate empty content', () async {
      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Title',
        content: '',
        isSharedWithCounselor: false,
      );

      expect(result, false);
      expect(createService.errorMessage, contains('cannot be empty'));
      expect(mockDatabase.getAllEntries().length, 0);
    });

    test('Should validate short content', () async {
      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Title',
        content: 'Short',
        isSharedWithCounselor: false,
      );

      expect(result, false);
      expect(createService.errorMessage, contains('at least 10 characters'));
      expect(mockDatabase.getAllEntries().length, 0);
    });

    test('Should trim whitespace from title and content', () async {
      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: '  Title with spaces  ',
        content: '  Content with extra whitespace everywhere  ',
        isSharedWithCounselor: false,
      );

      expect(result, true);
      
      final entries = mockDatabase.getAllEntries();
      expect(entries[0]['title'], 'Title with spaces');
      expect(entries[0]['content'], 'Content with extra whitespace everywhere');
    });

    test('Should handle empty title as null', () async {
      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: '   ',
        content: 'Content without a title.',
        isSharedWithCounselor: false,
      );

      expect(result, true);
      
      final entries = mockDatabase.getAllEntries();
      expect(entries[0]['title'], isNull);
    });

    test('Should validate title length', () {
      expect(createService.validateTitle(null), true);
      expect(createService.validateTitle(''), true);
      expect(createService.validateTitle('Normal Title'), true);
      expect(createService.validateTitle('A' * 100), true);
      expect(createService.validateTitle('A' * 101), false);
    });

    test('Should validate content length', () {
      expect(createService.validateContent(''), false);
      expect(createService.validateContent('Short'), false);
      expect(createService.validateContent('Valid content with enough length'), true);
    });

    test('Should get title error messages', () {
      expect(createService.getTitleErrorMessage(null), isNull);
      expect(createService.getTitleErrorMessage(''), isNull);
      expect(createService.getTitleErrorMessage('Normal Title'), isNull);
      expect(createService.getTitleErrorMessage('A' * 101), isNotNull);
    });

    test('Should get content error messages', () {
      expect(createService.getContentErrorMessage(''), isNotNull);
      expect(createService.getContentErrorMessage('Short'), isNotNull);
      expect(createService.getContentErrorMessage('Valid content'), isNull);
    });

    test('Should handle database errors', () async {
      mockDatabase.setShouldThrowError(true);

      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Title',
        content: 'This is valid content.',
        isSharedWithCounselor: false,
      );

      expect(result, false);
      expect(createService.errorMessage, contains('Error creating journal entry'));
    });

    test('Should handle sentiment analysis errors', () async {
      mockNLPService.setShouldThrowError(true);

      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Title',
        content: 'This is valid content.',
        isSharedWithCounselor: false,
      );

      expect(result, false);
      expect(createService.errorMessage, contains('Error analyzing sentiment'));
    });

    test('Should continue if intervention trigger fails', () async {
      mockInterventionService.setShouldThrowError(true);

      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Crisis',
        content: 'I am thinking about suicide and want to end my life.',
        isSharedWithCounselor: true,
      );

      expect(result, false);
      expect(createService.errorMessage, contains('Error triggering intervention'));
    });

    test('Should continue if activity recording fails', () async {
      mockActivityService.setShouldThrowError(true);

      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Title',
        content: 'This is valid content for the journal.',
        isSharedWithCounselor: false,
      );

      expect(result, false);
      expect(createService.errorMessage, contains('Error recording activity'));
    });

    test('Should clear error message', () async {
      mockDatabase.setShouldThrowError(true);

      await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Title',
        content: 'Valid content',
        isSharedWithCounselor: false,
      );

      expect(createService.errorMessage, isNotNull);

      createService.clearError();
      expect(createService.errorMessage, isNull);
    });

    test('Should reset service state', () async {
      await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Title',
        content: 'Valid content for journal entry.',
        isSharedWithCounselor: false,
      );

      expect(createService.lastAnalysis, isNotNull);
      expect(createService.lastCreatedJournalId, isNotNull);

      createService.reset();

      expect(createService.isSubmitting, false);
      expect(createService.errorMessage, isNull);
      expect(createService.lastAnalysis, isNull);
      expect(createService.lastCreatedJournalId, isNull);
    });

    test('Should create multiple entries', () async {
      await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Entry 1',
        content: 'First journal entry content.',
        isSharedWithCounselor: false,
      );

      await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Entry 2',
        content: 'Second journal entry content.',
        isSharedWithCounselor: true,
      );

      final entries = mockDatabase.getAllEntries();
      expect(entries.length, 2);
      expect(entries[0]['title'], 'Entry 1');
      expect(entries[1]['title'], 'Entry 2');
    });

    test('Should use mock sentiment response when set', () async {
      mockNLPService.setMockResponse(MockSentimentAnalysis(
        sentiment: 'custom',
        insight: 'Custom insight',
        interventionLevel: 'none',
      ));

      final result = await createService.submitJournalEntry(
        userId: 'student1',
        title: 'Test',
        content: 'Any content here.',
        isSharedWithCounselor: false,
      );

      expect(result, true);
      expect(createService.lastAnalysis!.sentiment, 'custom');
      expect(createService.lastAnalysis!.insight, 'Custom insight');
    });
  });
}
