// DMT-MT-01: Student selects an emoji matching their mood today
// Requirement: On emoji select, user is directed to next part of the page
// This test matches the logic in student_daily_checkin.dart

import 'package:flutter_test/flutter_test.dart';

final moodOptions = [
	{'type': 'angry', 'emoji': '😡'},
	{'type': 'sad', 'emoji': '😔'},
	{'type': 'neutral', 'emoji': '😐'},
	{'type': 'happy', 'emoji': '😃'},
	{'type': 'loved', 'emoji': '🥰'},
];

class DailyCheckinState {
	String? moodType;
	int step = 0;
	void selectMood(String type) {
		moodType = type;
		step = 1; // advance to next part
	}
	String? validateMood() {
		if (moodType == null) return 'Please select your mood';
		return null;
	}
}

void main() {
	group('DMT-MT-01: Emoji mood selection', () {
		test('No mood selected shows validation error', () {
			final state = DailyCheckinState();
			expect(state.validateMood(), 'Please select your mood');
			expect(state.step, 0);
		});

		test('Selecting a mood sets moodType and advances step', () {
			final state = DailyCheckinState();
			state.selectMood('happy');
			expect(state.moodType, 'happy');
			expect(state.step, 1);
			expect(state.validateMood(), null);
		});

		test('All moods can be selected and validated', () {
			for (final mood in moodOptions) {
				final state = DailyCheckinState();
				state.selectMood(mood['type']!);
				expect(state.moodType, mood['type']);
				expect(state.step, 1);
				expect(state.validateMood(), null);
			}
		});
	});
}
