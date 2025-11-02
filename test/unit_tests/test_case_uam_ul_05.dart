import 'package:flutter_test/flutter_test.dart';
import 'shared/test_models.dart';

/// UAM-UL-05: Suspended Account
/// 
/// This test validates that the login system properly detects and prevents
/// login for accounts with suspended status.

void main() {
  late MockAuthService mockAuthService;
  late LoginValidationService validationService;
  late LoginService loginService;

  setUp(() {
    mockAuthService = MockAuthService();
    validationService = LoginValidationService();
    loginService = LoginService(mockAuthService, validationService);
  });

  group('UAM-UL-05: Suspended Account', () {
    test('should return "Account is Suspended" error for suspended account', () async {
      // Arrange
      const email = 'suspended@example.com';
      const password = 'password123';

      // Act
      final result = await loginService.login(
        email: email,
        password: password,
      );

      // Assert
      expect(result.success, false);
      expect(result.errorMessage, 'Account is Suspended');
      expect(result.errorType, LoginErrorType.accountSuspended);
    });

    test('should detect suspended status from user data', () async {
      // Arrange
      const userId = 'user-2';

      // Act
      final userData = await mockAuthService.getUserData(userId);

      // Assert
      expect(userData['status'], 'suspended');
    });

    test('should prevent login even with correct credentials if account is suspended', () async {
      // Arrange
      const email = 'suspended@example.com';
      const correctPassword = 'password123';

      // Act
      final result = await loginService.login(
        email: email,
        password: correctPassword,
      );

      // Assert
      expect(result.success, false);
      expect(result.errorMessage, contains('Suspended'));
      expect(result.userId, isNull, reason: 'Suspended users should not get userId');
    });
  });
}
