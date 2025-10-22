// DMT-MT-02: Student selects a reason for their mood, can select 'Other' and add a note
// Requirement: 1:1 ratio for reason selection, 'Other' shows textbox, note is optional
// This test matches the logic in student_daily_checkin.dart

import 'package:flutter_test/flutter_test.dart';

final reasonOptions = ['Relationship', 'School', 'Friend', 'Work', 'Family', 'Other'];

class DailyCheckinReasonState {
	List<String> reasons = [];
	String? otherReason;
	String? note;
	void selectReason(String reason) {
		if (reasons.contains(reason)) {
			reasons.remove(reason);
		} else {
			reasons.add(reason);
		}
		if (reason != 'Other') otherReason = null;
	}
	void setOtherReason(String value) {
		otherReason = value;
		if (!reasons.contains('Other')) reasons.add('Other');
	}
	void setNote(String value) {
		note = value;
	}
	String? validateReasons() {
		// No required validation for reasons in the app, but if 'Other' is selected, require text
		if (reasons.contains('Other') && (otherReason == null || otherReason!.trim().isEmpty)) {
			return 'Please specify your reason for selecting Other';
		}
		return null;
	}
}

void main() {
	group('DMT-MT-02: Reason selection and note', () {
		test('No reason selected is valid (optional)', () {
			final state = DailyCheckinReasonState();
			expect(state.validateReasons(), null);
		});

		test('Selecting a reason adds/removes it', () {
			final state = DailyCheckinReasonState();
			state.selectReason('School');
			expect(state.reasons, contains('School'));
			state.selectReason('School');
			expect(state.reasons, isNot(contains('School')));
		});

		test('Selecting Other requires text', () {
			final state = DailyCheckinReasonState();
			state.selectReason('Other');
			expect(state.validateReasons(), isNotNull);
			state.setOtherReason('Because of something else');
			expect(state.validateReasons(), null);
		});

		test('Adding a note is optional', () {
			final state = DailyCheckinReasonState();
			expect(state.note, isNull);
			state.setNote('This is my note');
			expect(state.note, 'This is my note');
		});
	});
}
