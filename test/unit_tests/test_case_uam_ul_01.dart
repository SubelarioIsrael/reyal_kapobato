import 'package:flutter_test/flutter_test.dart';
import 'shared/test_models.dart';

/// UAM-UL-01: Invalid Email Format
/// 
/// This test validates that the login system properly rejects invalid email formats
/// and returns appropriate error messages before attempting authentication.

void main() {
  late MockAuthService mockAuthService;
  late LoginValidationService validationService;
  late LoginService loginService;

  setUp(() {
    mockAuthService = MockAuthService();
    validationService = LoginValidationService();
    loginService = LoginService(mockAuthService, validationService);
  });

  group('UAM-UL-01: Invalid Email Format', () {
    test('should return "Invalid email format" error for invalid email', () async {
      // Arrange
      const invalidEmails = [
        'invalid-email',
        'invalid@',
        '@example.com',
        'invalid@domain',
        'invalid domain@example.com',
      ];

      // Act & Assert
      for (final email in invalidEmails) {
        final result = await loginService.login(
          email: email,
          password: 'password123',
        );

        expect(result.success, false, reason: 'Login should fail for email: $email');
        expect(result.errorMessage, 'Invalid email format', reason: 'Should return invalid email format error for: $email');
        expect(result.errorType, LoginErrorType.validation);
      }
    });

    test('should validate email format before attempting login', () {
      // Arrange
      const invalidEmail = 'notanemail';

      // Act
      final validationError = validationService.validateEmail(invalidEmail);

      // Assert
      expect(validationError, isNotNull);
      expect(validationError, 'Invalid email format');
    });
  });
}
