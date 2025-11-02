import 'package:flutter_test/flutter_test.dart';
import 'shared/test_models.dart';

/// UAM-UL-04: Wrong Password
/// 
/// This test validates that the login system properly handles incorrect passwords
/// and returns appropriate error messages without revealing account existence.

void main() {
  late MockAuthService mockAuthService;
  late LoginValidationService validationService;
  late LoginService loginService;

  setUp(() {
    mockAuthService = MockAuthService();
    validationService = LoginValidationService();
    loginService = LoginService(mockAuthService, validationService);
  });

  group('UAM-UL-04: Wrong Password', () {
    test('should return "Invalid credentials" message for wrong password', () async {
      // Arrange
      const email = 'valid@example.com';
      const wrongPassword = 'wrongpassword';

      // Act
      final result = await loginService.login(
        email: email,
        password: wrongPassword,
      );

      // Assert
      expect(result.success, false);
      expect(result.errorMessage, 'Invalid credentials');
      expect(result.errorType, LoginErrorType.invalidCredentials);
    });

    test('should fail authentication with incorrect password', () async {
      // Arrange
      const email = 'valid@example.com';
      const wrongPassword = 'incorrect123';

      // Act & Assert
      expect(
        () async => await mockAuthService.signInWithPassword(
          email: email,
          password: wrongPassword,
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Invalid login credentials'),
        )),
      );
    });

    test('should fail for correct email but wrong password combination', () async {
      // Arrange
      const testCases = [
        {'email': 'valid@example.com', 'password': 'wrong123'},
        {'email': 'valid@example.com', 'password': 'wrongpass'},
        {'email': 'valid@example.com', 'password': 'notthepassword'},
      ];

      // Act & Assert
      for (final testCase in testCases) {
        final result = await loginService.login(
          email: testCase['email']!,
          password: testCase['password']!,
        );

        expect(result.success, false);
        expect(result.errorMessage, 'Invalid credentials');
        expect(result.errorType, LoginErrorType.invalidCredentials);
      }
    });
  });
}
