import 'package:flutter_test/flutter_test.dart';
import 'shared/test_models.dart';

/// UAM-UL-06: Unverified Email
/// 
/// This test validates that the login system properly prevents login for
/// accounts with unverified email addresses and shows appropriate messages.

void main() {
  late MockAuthService mockAuthService;
  late LoginValidationService validationService;
  late LoginService loginService;

  setUp(() {
    mockAuthService = MockAuthService();
    validationService = LoginValidationService();
    loginService = LoginService(mockAuthService, validationService);
  });

  group('UAM-UL-06: Unverified Email', () {
    test('should return email not verified error message', () async {
      // Arrange
      const email = 'unverified@example.com';
      const password = 'password123';

      // Act
      final result = await loginService.login(
        email: email,
        password: password,
      );

      // Assert
      expect(result.success, false);
      expect(
        result.errorMessage,
        'Your email address has not been verified. Please check your inbox and click the verification link before logging in.',
      );
      expect(result.errorType, LoginErrorType.emailNotVerified);
    });

    test('should throw exception during authentication for unverified email', () async {
      // Arrange
      const email = 'unverified@example.com';
      const password = 'password123';

      // Act & Assert
      expect(
        () async => await mockAuthService.signInWithPassword(
          email: email,
          password: password,
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Email not confirmed'),
        )),
      );
    });

    test('should prevent login for unverified accounts even with correct credentials', () async {
      // Arrange
      const email = 'unverified@example.com';
      const correctPassword = 'password123';

      // Act
      final result = await loginService.login(
        email: email,
        password: correctPassword,
      );

      // Assert
      expect(result.success, false);
      expect(result.errorType, LoginErrorType.emailNotVerified);
      expect(result.userId, isNull);
    });
  });
}
