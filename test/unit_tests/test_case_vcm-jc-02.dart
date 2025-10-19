// BB-VCM-JC-02: User enters a not existing call id for video call join
// Requirement: Show error for call code that does not exist or is not active
// This test matches the logic in student_appointments.dart

import 'package:flutter_test/flutter_test.dart';

// Simulate database lookup for call code
String? checkCallCodeExists(String callCode, Map<String, dynamic>? dbResult) {
	if (dbResult == null) {
		return 'Call code does not exist or has expired';
	}
	if (dbResult['status'] != 'active') {
		return 'Call code exists but is not active (Status: ${dbResult['status']})';
	}
	return null;
}

void main() {
	group('BB-VCM-JC-02: Call code existence validation', () {
		test('Non-existent call code returns error', () {
			final result = checkCallCodeExists('abc-def-ghi', null);
			expect(result, 'Call code does not exist or has expired');
		});

		test('Inactive call code returns status error', () {
			final result = checkCallCodeExists('abc-def-ghi', {'status': 'expired'});
			expect(result, contains('not active'));
			expect(result, contains('expired'));
		});

		test('Active call code returns null', () {
			final result = checkCallCodeExists('abc-def-ghi', {'status': 'active'});
			expect(result, null);
		});
	});
}
