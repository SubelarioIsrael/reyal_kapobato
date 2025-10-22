// UMM-UMM-04: Admin can delete a motivational quote
// Requirement: Admin can delete existing motivational quotes/uplifts
// Mirrors logic in `admin_daily_uplifts.dart` (delete uplifts)

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

  Future<void> deleteUplift(int upliftId) async {
    final index = _uplifts.indexWhere((uplift) => uplift.upliftId == upliftId);
    if (index == -1) {
      throw Exception('Uplift not found');
    }
    
    _uplifts.removeAt(index);
  }

  Future<List<Map<String, dynamic>>> fetchUplifts() async {
    // Simulate database ordering: created_at descending (newest first)
    final sortedUplifts = List<MockUplift>.from(_uplifts);
    sortedUplifts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return sortedUplifts.map((uplift) => uplift.toMap()).toList();
  }

  bool upliftExists(int upliftId) {
    return _uplifts.any((uplift) => uplift.upliftId == upliftId);
  }
}

// Service class to handle uplifts operations (deleting functionality)
class UpliftsService {
  final MockDatabase _database;

  UpliftsService(this._database);

  Future<void> deleteUplift(int upliftId) async {
    await _database.deleteUplift(upliftId);
  }

  Future<List<Map<String, dynamic>>> loadUplifts() async {
    try {
      return await _database.fetchUplifts();
    } catch (e) {
      throw Exception('Error loading uplifts: $e');
    }
  }

  bool upliftExists(int upliftId) {
    return _database.upliftExists(upliftId);
  }
}

void main() {
  group('UMM-UMM-04: Admin can delete a motivational quote', () {
    late MockDatabase mockDatabase;
    late UpliftsService upliftsService;

    setUp(() {
      mockDatabase = MockDatabase();
      upliftsService = UpliftsService(mockDatabase);
    });

    test('Should delete motivational quote successfully', () async {
      // Seed initial data
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'Quote to be deleted',
          author: 'Author Name',
          createdAt: DateTime(2025, 10, 20).toIso8601String(),
        ),
        MockUplift(
          upliftId: 2,
          quote: 'Quote to keep',
          author: 'Another Author',
          createdAt: DateTime(2025, 10, 21).toIso8601String(),
        ),
      ]);

      await upliftsService.deleteUplift(1);

      expect(mockDatabase.upliftsCount, 1);
      
      final uplifts = await upliftsService.loadUplifts();
      expect(uplifts.length, 1);
      expect(uplifts[0]['uplift_id'], 2);
      expect(uplifts[0]['quote'], 'Quote to keep');
    });

    test('Should throw exception when deleting non-existent uplift', () async {
      expect(
        () async => await upliftsService.deleteUplift(999),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Uplift not found'),
        )),
      );
    });

    test('Should delete specific uplift while preserving others', () async {
      // Seed multiple uplifts
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'First quote to keep',
          author: 'First Author',
          createdAt: DateTime(2025, 10, 20).toIso8601String(),
        ),
        MockUplift(
          upliftId: 2,
          quote: 'Second quote to delete',
          author: 'Second Author',
          createdAt: DateTime(2025, 10, 21).toIso8601String(),
        ),
        MockUplift(
          upliftId: 3,
          quote: 'Third quote to keep',
          author: 'Third Author',
          createdAt: DateTime(2025, 10, 22).toIso8601String(),
        ),
      ]);

      await upliftsService.deleteUplift(2);

      expect(mockDatabase.upliftsCount, 2);
      
      final uplifts = await upliftsService.loadUplifts();
      expect(uplifts.length, 2);
      
      // Verify the correct uplift was deleted
      expect(uplifts.any((u) => u['uplift_id'] == 2), false);
      expect(uplifts.any((u) => u['uplift_id'] == 1), true);
      expect(uplifts.any((u) => u['uplift_id'] == 3), true);
      
      // Verify remaining uplifts content
      final firstUplift = uplifts.firstWhere((u) => u['uplift_id'] == 1);
      expect(firstUplift['quote'], 'First quote to keep');
      
      final thirdUplift = uplifts.firstWhere((u) => u['uplift_id'] == 3);
      expect(thirdUplift['quote'], 'Third quote to keep');
    });

    test('Should handle deleting all uplifts', () async {
      // Seed single uplift
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'Only quote to delete',
          author: 'Only Author',
          createdAt: DateTime(2025, 10, 20).toIso8601String(),
        ),
      ]);

      await upliftsService.deleteUplift(1);

      expect(mockDatabase.upliftsCount, 0);
      
      final uplifts = await upliftsService.loadUplifts();
      expect(uplifts.length, 0);
      expect(uplifts, isEmpty);
    });

    test('Should delete uplifts in any order', () async {
      // Seed multiple uplifts
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'First quote',
          author: 'First Author',
          createdAt: DateTime(2025, 10, 20).toIso8601String(),
        ),
        MockUplift(
          upliftId: 2,
          quote: 'Second quote',
          author: 'Second Author',
          createdAt: DateTime(2025, 10, 21).toIso8601String(),
        ),
        MockUplift(
          upliftId: 3,
          quote: 'Third quote',
          author: 'Third Author',
          createdAt: DateTime(2025, 10, 22).toIso8601String(),
        ),
      ]);

      // Delete middle one first
      await upliftsService.deleteUplift(2);
      expect(mockDatabase.upliftsCount, 2);
      
      // Delete first one
      await upliftsService.deleteUplift(1);
      expect(mockDatabase.upliftsCount, 1);
      
      // Delete last one
      await upliftsService.deleteUplift(3);
      expect(mockDatabase.upliftsCount, 0);
      
      final uplifts = await upliftsService.loadUplifts();
      expect(uplifts, isEmpty);
    });

    test('Should verify uplift existence before deletion', () {
      // Seed initial data
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'Existing quote',
          author: 'Existing Author',
          createdAt: DateTime(2025, 10, 20).toIso8601String(),
        ),
      ]);

      // Test existing uplift
      expect(upliftsService.upliftExists(1), true);
      
      // Test non-existing uplift
      expect(upliftsService.upliftExists(999), false);
    });

    test('Should maintain proper ordering after deletion', () async {
      // Seed uplifts with specific dates
      mockDatabase.seedUplifts([
        MockUplift(
          upliftId: 1,
          quote: 'Oldest quote',
          author: 'First Author',
          createdAt: DateTime(2025, 1, 1).toIso8601String(),
        ),
        MockUplift(
          upliftId: 2,
          quote: 'Middle quote to delete',
          author: 'Second Author',
          createdAt: DateTime(2025, 6, 15).toIso8601String(),
        ),
        MockUplift(
          upliftId: 3,
          quote: 'Newest quote',
          author: 'Third Author',
          createdAt: DateTime(2025, 12, 31).toIso8601String(),
        ),
      ]);

      await upliftsService.deleteUplift(2);

      final uplifts = await upliftsService.loadUplifts();
      expect(uplifts.length, 2);
      
      // Verify ordering is maintained (newest first)
      expect(uplifts[0]['quote'], 'Newest quote');
      expect(uplifts[1]['quote'], 'Oldest quote');
    });
  });
}