// UAM-UR-02: A student enters a password with fewer than six characters during registration
// Requirement: Password validation should reject passwords shorter than 6 characters

import 'package:flutter_test/flutter_test.dart';

class MockRegistrationService {
  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Please enter a password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  Future<bool> registerUser({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final passwordError = validatePassword(password);
    if (passwordError != null) {
      throw Exception(passwordError);
    }
    
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }
    
    return true;
  }
}

void main() {
  group('UAM-UR-02: Password length validation during registration', () {
    late MockRegistrationService registrationService;
    
    setUp(() {
      registrationService = MockRegistrationService();
    });

    test('Registration fails with password shorter than 6 characters', () async {
      expect(
        () => registrationService.registerUser(
          email: 'test@example.com',
          password: '12345',
          confirmPassword: '12345',
        ),
        throwsA(predicate((e) => e.toString().contains('Password must be at least 6 characters'))),
      );
    });

    test('Password validation returns error for 1-character password', () {
      final error = registrationService.validatePassword('1');
      expect(error, 'Password must be at least 6 characters');
    });

    test('Password validation returns error for 5-character password', () {
      final error = registrationService.validatePassword('12345');
      expect(error, 'Password must be at least 6 characters');
    });

    test('Password validation passes for exactly 6 characters', () {
      final error = registrationService.validatePassword('123456');
      expect(error, isNull);
    });

    test('Empty password returns appropriate error message', () {
      final error = registrationService.validatePassword('');
      expect(error, 'Please enter a password');
    });
  });
}
