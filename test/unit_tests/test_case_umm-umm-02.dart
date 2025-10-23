// UMM-UMM-02: Admin can add a motivational quote
// Requirement: Admin can add new motivational quotes/uplifts
// Mirrors logic in `admin_daily_uplifts.dart` (add uplifts with validation)

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
}

// Mock database class to simulate Supabase operations
class MockDatabase {
  List<MockUplift> _uplifts = [];
  int _nextId = 1;

  int get upliftsCount => _uplifts.length;

  void seedUplifts(List<MockUplift> uplifts) {
    _uplifts = uplifts;
    _nextId = uplifts.isEmpty ? 1 : uplifts.map((u) => u.upliftId).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> addUplift(String quote, String author) async {
    // Add small delay to ensure different timestamps
    await Future.delayed(Duration(milliseconds: 1));
    final newUplift = MockUplift(
      upliftId: _nextId++,
      quote: quote,
      author: author,
      createdAt: DateTime.now().toIso8601String(),
    );
    _uplifts.add(newUplift);
  }

  Future<List<Map<String, dynamic>>> fetchUplifts() async {
    // Simulate database ordering: created_at descending (newest first)
    final sortedUplifts = List<MockUplift>.from(_uplifts);
    sortedUplifts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return sortedUplifts.map((uplift) => uplift.toMap()).toList();
  }
}

// Service class to handle uplifts operations (adding functionality)
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

  Future<void> submitUplift(String quote, String author) async {
    final quoteError = validateQuote(quote);
    if (quoteError != null) throw Exception(quoteError);

    final authorError = validateAuthor(author);
    if (authorError != null) throw Exception(authorError);

    await _database.addUplift(quote.trim(), author.trim());
  }

  Future<List<Map<String, dynamic>>> loadUplifts() async {
    try {
      return await _database.fetchUplifts();
    } catch (e) {
      throw Exception('Error loading uplifts: $e');
    }
  }
}

void main() {
  group('UMM-UMM-02: Admin can add a motivational quote', () {
    late MockDatabase mockDatabase;
    late UpliftsService upliftsService;

    setUp(() {
      mockDatabase = MockDatabase();
      upliftsService = UpliftsService(mockDatabase);
    });

    test('Should validate quote input correctly', () {
      // Test empty quote
      expect(upliftsService.validateQuote(''), 'Please enter a motivational quote');
      expect(upliftsService.validateQuote(null), 'Please enter a motivational quote');
      expect(upliftsService.validateQuote('   '), 'Please enter a motivational quote');
      
      // Test short quote
      expect(upliftsService.validateQuote('Short'), 'Quote must be at least 10 characters long');
      
      // Test valid quote
      expect(upliftsService.validateQuote('This is a valid motivational quote.'), null);
    });

    test('Should validate author input correctly', () {
      // Test empty author
      expect(upliftsService.validateAuthor(''), 'Please enter the author name');
      expect(upliftsService.validateAuthor(null), 'Please enter the author name');
      expect(upliftsService.validateAuthor('   '), 'Please enter the author name');
      
      // Test valid author
      expect(upliftsService.validateAuthor('John Doe'), null);
    });

    test('Should add new motivational quote successfully', () async {
      final quote = 'Success is not final, failure is not fatal: it is the courage to continue that counts.';
      final author = 'Winston Churchill';

      await upliftsService.submitUplift(quote, author);

      expect(mockDatabase.upliftsCount, 1);
      
      final uplifts = await upliftsService.loadUplifts();
      expect(uplifts[0]['quote'], quote);
      expect(uplifts[0]['author'], author);
      expect(uplifts[0]['uplift_id'], 1);
    });

    test('Should add multiple quotes and maintain proper ordering', () async {
      // Add first quote
      await upliftsService.submitUplift(
        'The only impossible journey is the one you never begin.',
        'Tony Robbins'
      );

      // Add second quote
      await upliftsService.submitUplift(
        'In the middle of difficulty lies opportunity.',
        'Albert Einstein'
      );

      expect(mockDatabase.upliftsCount, 2);
      
      final uplifts = await upliftsService.loadUplifts();
      // Newest should be first
      expect(uplifts[0]['quote'], 'In the middle of difficulty lies opportunity.');
      expect(uplifts[0]['author'], 'Albert Einstein');
      expect(uplifts[1]['quote'], 'The only impossible journey is the one you never begin.');
      expect(uplifts[1]['author'], 'Tony Robbins');
    });

    test('Should throw exception for invalid quote during add', () async {
      expect(
        () async => await upliftsService.submitUplift('', 'Valid Author'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Please enter a motivational quote'),
        )),
      );

      expect(
        () async => await upliftsService.submitUplift('Short', 'Valid Author'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Quote must be at least 10 characters long'),
        )),
      );
    });

    test('Should throw exception for invalid author during add', () async {
      expect(
        () async => await upliftsService.submitUplift('This is a valid motivational quote.', ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Please enter the author name'),
        )),
      );
    });

    test('Should trim whitespace from quote and author before adding', () async {
      final quote = '   Believe you can and you are halfway there.   ';
      final author = '   Theodore Roosevelt   ';

      await upliftsService.submitUplift(quote, author);

      final uplifts = await upliftsService.loadUplifts();
      expect(uplifts[0]['quote'], 'Believe you can and you are halfway there.');
      expect(uplifts[0]['author'], 'Theodore Roosevelt');
    });
  });
}