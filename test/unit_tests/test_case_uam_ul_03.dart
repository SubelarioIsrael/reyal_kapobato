import 'package:flutter_test/flutter_test.dart';
import 'shared/test_models.dart';

/// UAM-UL-03: Valid Credentials Login
/// 
/// This test validates that the login system successfully authenticates users
/// with valid credentials and returns appropriate user data for dashboard redirection.

void main() {
  late MockAuthService mockAuthService;
  late LoginValidationService validationService;
  late LoginService loginService;

  setUp(() {
    mockAuthService = MockAuthService();
    validationService = LoginValidationService();
    loginService = LoginService(mockAuthService, validationService);
  });

  group('UAM-UL-03: Valid Credentials Login', () {
    test('should successfully login with valid credentials and redirect to dashboard', () async {
      // Arrange
      const email = 'valid@example.com';
      const password = 'password123';

      // Act
      final result = await loginService.login(
        email: email,
        password: password,
      );

      // Assert
      expect(result.success, true);
      expect(result.errorMessage, isNull);
      expect(result.userId, isNotNull);
      expect(result.userId, 'user-1');
      expect(result.userType, 'student');
    });

    test('should validate email format and allow valid email', () {
      // Arrange
      const validEmails = [
        'user@example.com',
        'test.user@domain.co.uk',
        'valid_email123@test-domain.com',
      ];

      // Act & Assert
      for (final email in validEmails) {
        final error = validationService.validateEmail(email);
        expect(error, isNull, reason: 'Valid email should not produce error: $email');
      }
    });

    test('should return user data after successful authentication', () async {
      // Arrange
      const email = 'valid@example.com';
      const password = 'password123';

      // Act
      final authResponse = await mockAuthService.signInWithPassword(
        email: email,
        password: password,
      );
      final userData = await mockAuthService.getUserData(authResponse['user']['id']);

      // Assert
      expect(userData['user_type'], 'student');
      expect(userData['status'], 'active');
    });
  });
}
