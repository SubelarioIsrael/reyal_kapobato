import 'package:flutter_test/flutter_test.dart';

// Simulated validation for call ID existence
String? validateCallIdExists(String callId) {
  if (callId.isEmpty) {
    return 'Please enter a call ID to join the video call.';
  }

  if (callId != 'VALID_CALL_ID') {
    return 'Call ID not found';
  }
  return null;
}

void main() {
  group('VCM-JC-02: Call ID existence validation', () {
    test('Empty call ID returns missing error', () {
      expect(validateCallIdExists(''), 'Please enter a call ID to join the video call.');
    });

    test('Non-existing call ID returns not found error', () {
      expect(validateCallIdExists('NON_EXISTING_ID'), 'Call ID not found');
      expect(validateCallIdExists('123-456-789'), 'Call ID not found');
      expect(validateCallIdExists('abc-def-ghi'), 'Call ID not found');
    });

    test('Existing call ID returns null', () {
      expect(validateCallIdExists('VALID_CALL_ID'), null);
    });
  });
}
