// UMM-UMM-01: Admin can view all of the motivational quotes
// Requirement: Admin can view all existing motivational quotes/uplifts
// Mirrors logic in `admin_daily_uplifts.dart` (load and display uplifts)

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

  int get upliftsCount => _uplifts.length;

  void seedUplifts(List<MockUplift> uplifts) {
    _uplifts = uplifts;
  }

  Future<List<Map<String, dynamic>>> fetchUplifts() async {
    // Simulate database ordering: created_at descending (newest first)
    final sortedUplifts = List<MockUplift>.from(_uplifts);
    sortedUplifts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return sortedUplifts.map((uplift) => uplift.toMap()).toList();
  }
}

// Service class to handle uplifts operations (viewing only)
class UpliftsService {
  final MockDatabase _database;

  UpliftsService(this._database);

  Future<List<Map<String, dynamic>>> loadUplifts() async {
    try {
      return await _database.fetchUplifts();
    } catch (e) {
      throw Exception('Error loading uplifts: $e');
    }
  }
}

void main() {
  group('UMM-UMM-01: Admin can view all of the motivational quotes', () {
    late MockDatabase mockDatabase;
    late UpliftsService upliftsService;

    setUp(() {
      mockDatabase = MockDatabase();
      upliftsService = UpliftsService(mockDatabase);
    });

    test('Should load and display existing motivational quotes', () async {
      // Seed test data
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'The only way to do great work is to love what you do.',
          author: 'Steve Jobs',
          createdAt: DateTime(2025, 10, 20).toIso8601String(),
        ),
        MockUplift(
          upliftId: 2,
          quote: 'Life is what happens to you while you\'re busy making other plans.',
          author: 'John Lennon',
          createdAt: DateTime(2025, 10, 21).toIso8601String(),
        ),
        MockUplift(
          upliftId: 3,
          quote: 'The future belongs to those who believe in the beauty of their dreams.',
          author: 'Eleanor Roosevelt',
          createdAt: DateTime(2025, 10, 22).toIso8601String(),
        ),
      ]);

      // Test loading uplifts
      final uplifts = await upliftsService.loadUplifts();

      // Verify results
      expect(uplifts.length, 3);
      
      // Should be ordered by created_at descending (most recent first)
      expect(uplifts[0]['quote'], 'The future belongs to those who believe in the beauty of their dreams.');
      expect(uplifts[0]['author'], 'Eleanor Roosevelt');
      expect(uplifts[0]['uplift_id'], 3);
      
      expect(uplifts[1]['quote'], 'Life is what happens to you while you\'re busy making other plans.');
      expect(uplifts[1]['author'], 'John Lennon');
      expect(uplifts[1]['uplift_id'], 2);
      
      expect(uplifts[2]['quote'], 'The only way to do great work is to love what you do.');
      expect(uplifts[2]['author'], 'Steve Jobs');
      expect(uplifts[2]['uplift_id'], 1);
    });

    test('Should handle empty uplifts list', () async {
      // No seeded data
      final uplifts = await upliftsService.loadUplifts();
      
      expect(uplifts.length, 0);
      expect(uplifts, isEmpty);
    });

    test('Should display uplifts with proper data structure', () async {
      // Seed test data
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'Be yourself; everyone else is already taken.',
          author: 'Oscar Wilde',
          createdAt: DateTime(2025, 10, 23).toIso8601String(),
        ),
      ]);

      final uplifts = await upliftsService.loadUplifts();

      // Verify data structure and content
      expect(uplifts.length, 1);
      expect(uplifts[0], isA<Map<String, dynamic>>());
      expect(uplifts[0]['uplift_id'], isA<int>());
      expect(uplifts[0]['quote'], isA<String>());
      expect(uplifts[0]['author'], isA<String>());
      expect(uplifts[0]['created_at'], isA<String>());
      
      // Verify content
      expect(uplifts[0]['quote'], 'Be yourself; everyone else is already taken.');
      expect(uplifts[0]['author'], 'Oscar Wilde');
    });

    test('Should maintain proper ordering when viewing multiple quotes', () async {
      // Seed test data with different dates
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'Oldest Quote',
          author: 'First Author',
          createdAt: DateTime(2025, 1, 1).toIso8601String(),
        ),
        MockUplift(
          upliftId: 2,
          quote: 'Middle Quote',
          author: 'Second Author',
          createdAt: DateTime(2025, 6, 15).toIso8601String(),
        ),
        MockUplift(
          upliftId: 3,
          quote: 'Newest Quote',
          author: 'Third Author',
          createdAt: DateTime(2025, 12, 31).toIso8601String(),
        ),
      ]);

      final uplifts = await upliftsService.loadUplifts();

      // Verify ordering (newest first)
      expect(uplifts.length, 3);
      expect(uplifts[0]['quote'], 'Newest Quote');
      expect(uplifts[1]['quote'], 'Middle Quote');
      expect(uplifts[2]['quote'], 'Oldest Quote');
    });
  });
}