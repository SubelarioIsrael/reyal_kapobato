import 'package:flutter_test/flutter_test.dart';
import 'shared/test_models.dart';

/// UAM-UL-02: Empty Field Validation
/// 
/// This test validates that the login system properly validates required fields
/// and prevents login attempts when email or password is empty.

void main() {
  late MockAuthService mockAuthService;
  late LoginValidationService validationService;
  late LoginService loginService;

  setUp(() {
    mockAuthService = MockAuthService();
    validationService = LoginValidationService();
    loginService = LoginService(mockAuthService, validationService);
  });

  group('UAM-UL-02: Empty Field Validation', () {
    test('should return "Email field is required" when email is empty', () async {
      // Arrange
      const emptyEmail = '';
      const password = 'password123';

      // Act
      final result = await loginService.login(
        email: emptyEmail,
        password: password,
      );

      // Assert
      expect(result.success, false);
      expect(result.errorMessage, 'Email field is required');
      expect(result.errorType, LoginErrorType.validation);
    });

    test('should return "Password field is required" when password is empty', () async {
      // Arrange
      const email = 'valid@example.com';
      const emptyPassword = '';

      // Act
      final result = await loginService.login(
        email: email,
        password: emptyPassword,
      );

      // Assert
      expect(result.success, false);
      expect(result.errorMessage, 'Password field is required');
      expect(result.errorType, LoginErrorType.validation);
    });

    test('should validate required fields before attempting login', () {
      // Act
      final emailError = validationService.validateEmail('');
      final passwordError = validationService.validatePassword('');

      // Assert
      expect(emailError, 'Email field is required');
      expect(passwordError, 'Password field is required');
    });
  });
}
