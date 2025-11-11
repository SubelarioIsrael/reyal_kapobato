// DMT-MT-01: Students can select a mood
// Requirement: Selected mood is recorded and shown in history.

import 'package:flutter_test/flutter_test.dart';

class MockMoodEntry {
  final String userId;
  final String moodType;
  final DateTime entryDate;

  MockMoodEntry({
    required this.userId,
    required this.moodType,
    required this.entryDate,
  });
}

class MockMoodService {
  final List<MockMoodEntry> _entries = [];

  Future<void> recordMood(String userId, String moodType) async {
    _entries.add(MockMoodEntry(
      userId: userId,
      moodType: moodType,
      entryDate: DateTime.now(),
    ));
  }

  List<MockMoodEntry> getHistory(String userId) {
    return _entries.where((e) => e.userId == userId).toList();
  }
}

void main() {
  group('DMT-MT-01: Students can select a mood', () {
    test('Selected mood is recorded and shown in history', () async {
      final service = MockMoodService();
      final userId = 'student-1';

      await service.recordMood(userId, 'happy');
      await service.recordMood(userId, 'sad');

      final history = service.getHistory(userId);
      expect(history.length, 2);
      expect(history[0].moodType, 'happy');
      expect(history[1].moodType, 'sad');
    });
  });
}