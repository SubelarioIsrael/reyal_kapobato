// DMT-MT-03: Student views all mood checkins (history)
// Requirement: Student can view all mood checkins, ordered by date
// This test matches the logic in student_checkin_history.dart

import 'package:flutter_test/flutter_test.dart';


class MockUser {
	final String id;
	final String name;
	MockUser(this.id, this.name);
}

class MockDatabase {
	final List<Map<String, dynamic>> moodEntries;
	MockDatabase(this.moodEntries);

	List<Map<String, dynamic>> fetchCheckInHistory(String userId) {
		final entries = moodEntries
				.where((entry) => entry['user_id'] == userId)
				.toList();
		entries.sort((a, b) => b['entry_date'].compareTo(a['entry_date']));
		if (entries.length > 30) {
			return entries.sublist(0, 30);
		}
		return entries;
	}
}

void main() {
		group('DMT-MT-03: Mood checkin history', () {
			final mockUser = MockUser('user-123', 'Test User');
				final mockDb = MockDatabase([
					{'user_id': mockUser.id, 'entry_date': DateTime(2025, 10, 20).toIso8601String(), 'mood_type': 'happy', 'notes': 'Had a great day!'},
					{'user_id': mockUser.id, 'entry_date': DateTime(2025, 10, 19).toIso8601String(), 'mood_type': 'sad', 'notes': 'Felt a bit down.'},
					{'user_id': 'other', 'entry_date': DateTime(2025, 10, 18).toIso8601String(), 'mood_type': 'angry', 'notes': 'Not my entry.'},
					{'user_id': mockUser.id, 'entry_date': DateTime(2025, 10, 18).toIso8601String(), 'mood_type': 'neutral', 'notes': ''},
				]);

			test('Fetches only current user checkins, ordered by date', () {
				final history = mockDb.fetchCheckInHistory(mockUser.id);
				expect(history.length, 3);
				expect(history[0]['mood_type'], 'happy');
				expect(history[0]['notes'], 'Had a great day!');
				expect(history[1]['mood_type'], 'sad');
				expect(history[1]['notes'], 'Felt a bit down.');
				expect(history[2]['mood_type'], 'neutral');
				expect(history[2]['notes'], '');
				expect(history.every((entry) => entry['user_id'] == mockUser.id), isTrue);
			});

			test('Returns empty if no checkins for user', () {
				final history = mockDb.fetchCheckInHistory('no-user');
				expect(history, isEmpty);
			});

			test('Limits to 30 entries', () {
						final bigDb = MockDatabase(List.generate(50, (i) => {
							'user_id': mockUser.id,
							'entry_date': DateTime(2025, 10, 1).add(Duration(days: i)).toIso8601String(),
							'mood_type': 'happy',
							'notes': 'Note $i',
						}));
				final history = bigDb.fetchCheckInHistory(mockUser.id);
				expect(history.length, 30);
			});
		});
}
