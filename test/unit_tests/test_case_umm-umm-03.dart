// UMM-UMM-03: Admin can update all of the motivational quotes
// Requirement: Admin can update existing motivational quotes/uplifts
// Mirrors logic in `admin_daily_uplifts.dart` (update uplifts with validation)

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent an uplift/motivational quote
class MockUplift {
  final int upliftId;
  final String quote;
  final String author;
  final String createdAt;

  MockUplift({
    required this.upliftId,
    required this.quote,
    required this.author,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uplift_id': upliftId,
      'quote': quote,
      'author': author,
      'created_at': createdAt,
    };
  }

  MockUplift copyWith({
    String? quote,
    String? author,
  }) {
    return MockUplift(
      upliftId: upliftId,
      quote: quote ?? this.quote,
      author: author ?? this.author,
      createdAt: createdAt,
    );
  }
}

// Mock database class to simulate Supabase operations
class MockDatabase {
  List<MockUplift> _uplifts = [];

  int get upliftsCount => _uplifts.length;

  void seedUplifts(List<MockUplift> uplifts) {
    _uplifts = uplifts;
  }

  Future<void> updateUplift(int upliftId, String quote, String author) async {
    final index = _uplifts.indexWhere((uplift) => uplift.upliftId == upliftId);
    if (index == -1) {
      throw Exception('Uplift not found');
    }
    
    _uplifts[index] = _uplifts[index].copyWith(
      quote: quote,
      author: author,
    );
  }

  Future<List<Map<String, dynamic>>> fetchUplifts() async {
    // Simulate database ordering: created_at descending (newest first)
    final sortedUplifts = List<MockUplift>.from(_uplifts);
    sortedUplifts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return sortedUplifts.map((uplift) => uplift.toMap()).toList();
  }

  MockUplift? findUpliftById(int upliftId) {
    try {
      return _uplifts.firstWhere((uplift) => uplift.upliftId == upliftId);
    } catch (e) {
      return null;
    }
  }
}

// Service class to handle uplifts operations (updating functionality)
class UpliftsService {
  final MockDatabase _database;

  UpliftsService(this._database);

  String? validateQuote(String? quote) {
    if (quote == null || quote.trim().isEmpty) {
      return 'Please enter a motivational quote';
    }
    if (quote.trim().length < 10) {
      return 'Quote must be at least 10 characters long';
    }
    return null;
  }

  String? validateAuthor(String? author) {
    if (author == null || author.trim().isEmpty) {
      return 'Please enter the author name';
    }
    return null;
  }

  Future<void> updateUplift(int upliftId, String quote, String author) async {
    final quoteError = validateQuote(quote);
    if (quoteError != null) throw Exception(quoteError);

    final authorError = validateAuthor(author);
    if (authorError != null) throw Exception(authorError);

    await _database.updateUplift(upliftId, quote.trim(), author.trim());
  }

  Future<List<Map<String, dynamic>>> loadUplifts() async {
    try {
      return await _database.fetchUplifts();
    } catch (e) {
      throw Exception('Error loading uplifts: $e');
    }
  }

  MockUplift? findUpliftById(int upliftId) {
    return _database.findUpliftById(upliftId);
  }
}

void main() {
  group('UMM-UMM-03: Admin can update all of the motivational quotes', () {
    late MockDatabase mockDatabase;
    late UpliftsService upliftsService;

    setUp(() {
      mockDatabase = MockDatabase();
      upliftsService = UpliftsService(mockDatabase);
    });

    test('Should update existing motivational quote successfully', () async {
      // Seed initial data
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'Old quote that needs updating',
          author: 'Old Author',
          createdAt: DateTime(2025, 10, 20).toIso8601String(),
        ),
      ]);

      final newQuote = 'Updated motivational quote that inspires everyone to achieve greatness.';
      final newAuthor = 'Updated Author';

      await upliftsService.updateUplift(1, newQuote, newAuthor);

      final uplifts = await upliftsService.loadUplifts();
      expect(uplifts.length, 1);
      expect(uplifts[0]['quote'], newQuote);
      expect(uplifts[0]['author'], newAuthor);
      expect(uplifts[0]['uplift_id'], 1);
    });

    test('Should validate quote input before updating', () async {
      // Seed initial data
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'Existing quote',
          author: 'Existing Author',
          createdAt: DateTime(2025, 10, 20).toIso8601String(),
        ),
      ]);

      // Test invalid quote
      expect(
        () async => await upliftsService.updateUplift(1, '', 'Valid Author'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Please enter a motivational quote'),
        )),
      );

      expect(
        () async => await upliftsService.updateUplift(1, 'Short', 'Valid Author'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Quote must be at least 10 characters long'),
        )),
      );
    });

    test('Should validate author input before updating', () async {
      // Seed initial data
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'Existing quote',
          author: 'Existing Author',
          createdAt: DateTime(2025, 10, 20).toIso8601String(),
        ),
      ]);

      // Test invalid author
      expect(
        () async => await upliftsService.updateUplift(1, 'This is a valid motivational quote.', ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Please enter the author name'),
        )),
      );
    });

    test('Should throw exception when updating non-existent uplift', () async {
      expect(
        () async => await upliftsService.updateUplift(999, 'Valid quote with enough characters', 'Valid Author'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Uplift not found'),
        )),
      );
    });

    test('Should update specific uplift while preserving others', () async {
      // Seed multiple uplifts
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'First quote to keep unchanged',
          author: 'First Author',
          createdAt: DateTime(2025, 10, 20).toIso8601String(),
        ),
        MockUplift(
          upliftId: 2,
          quote: 'Second quote to be updated',
          author: 'Second Author',
          createdAt: DateTime(2025, 10, 21).toIso8601String(),
        ),
        MockUplift(
          upliftId: 3,
          quote: 'Third quote to keep unchanged',
          author: 'Third Author',
          createdAt: DateTime(2025, 10, 22).toIso8601String(),
        ),
      ]);

      // Update only the second uplift
      await upliftsService.updateUplift(2, 'Updated second quote with new inspirational message', 'Updated Second Author');

      final uplifts = await upliftsService.loadUplifts();
      expect(uplifts.length, 3);

      // Find the updated uplift
      final updatedUplift = uplifts.firstWhere((u) => u['uplift_id'] == 2);
      expect(updatedUplift['quote'], 'Updated second quote with new inspirational message');
      expect(updatedUplift['author'], 'Updated Second Author');

      // Verify others remained unchanged
      final firstUplift = uplifts.firstWhere((u) => u['uplift_id'] == 1);
      expect(firstUplift['quote'], 'First quote to keep unchanged');
      expect(firstUplift['author'], 'First Author');

      final thirdUplift = uplifts.firstWhere((u) => u['uplift_id'] == 3);
      expect(thirdUplift['quote'], 'Third quote to keep unchanged');
      expect(thirdUplift['author'], 'Third Author');
    });

    test('Should trim whitespace from quote and author before updating', () async {
      // Seed initial data
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'Original quote',
          author: 'Original Author',
          createdAt: DateTime(2025, 10, 20).toIso8601String(),
        ),
      ]);

      final quotewithWhitespace = '   The way to get started is to quit talking and begin doing.   ';
      final authorWithWhitespace = '   Walt Disney   ';

      await upliftsService.updateUplift(1, quotewithWhitespace, authorWithWhitespace);

      final uplifts = await upliftsService.loadUplifts();
      expect(uplifts[0]['quote'], 'The way to get started is to quit talking and begin doing.');
      expect(uplifts[0]['author'], 'Walt Disney');
    });

    test('Should find uplift by ID for editing purposes', () {
      // Seed initial data
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'Findable quote',
          author: 'Findable Author',
          createdAt: DateTime(2025, 10, 20).toIso8601String(),
        ),
      ]);

      final foundUplift = upliftsService.findUpliftById(1);
      expect(foundUplift, isNotNull);
      expect(foundUplift!.quote, 'Findable quote');
      expect(foundUplift.author, 'Findable Author');

      final notFoundUplift = upliftsService.findUpliftById(999);
      expect(notFoundUplift, isNull);
    });
  });
}