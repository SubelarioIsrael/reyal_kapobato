// DMT-MT-02: Student can select a reason and add a note
// Requirement: Mood entry saves with reason and note details.

import 'package:flutter_test/flutter_test.dart';

class MockMoodEntry {
  final String userId;
  final String moodType;
  final String reason;
  final String note;
  final DateTime entryDate;

  MockMoodEntry({
    required this.userId,
    required this.moodType,
    required this.reason,
    required this.note,
    required this.entryDate,
  });
}

class MockMoodService {
  final List<MockMoodEntry> _entries = [];

  Future<void> recordMood(String userId, String moodType, String reason, String note) async {
    _entries.add(MockMoodEntry(
      userId: userId,
      moodType: moodType,
      reason: reason,
      note: note,
      entryDate: DateTime.now(),
    ));
  }

  List<MockMoodEntry> getHistory(String userId) {
    return _entries.where((e) => e.userId == userId).toList();
  }
}

void main() {
  group('DMT-MT-02: Student can select a reason and add a note', () {
    test('Mood entry saves with reason and note details', () async {
      final service = MockMoodService();
      final userId = 'student-2';

      await service.recordMood(userId, 'neutral', 'school', 'Had a test today');
      await service.recordMood(userId, 'happy', 'friends', 'Met my best friend');

      final history = service.getHistory(userId);
      expect(history.length, 2);
      expect(history[0].reason, 'school');
      expect(history[0].note, 'Had a test today');
      expect(history[1].reason, 'friends');
      expect(history[1].note, 'Met my best friend');
    });
  });
}