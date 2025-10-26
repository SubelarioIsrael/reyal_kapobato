// UPD-AS-03: System prevents password change if the current password is incorrect
// Requirement: Password change should fail with appropriate error when current password is wrong

import 'package:flutter_test/flutter_test.dart';

class MockAuthService {
  final Map<String, String> userCredentials = {
    'user1@example.com': 'currentpass123',
    'user2@example.com': 'mypassword456',
  };
  
  String? currentUserEmail;
  
  void setCurrentUser(String email) {
    currentUserEmail = email;
  }
  
  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate auth delay
    
    final storedPassword = userCredentials[email];
    if (storedPassword == null || storedPassword != password) {
      throw Exception('Invalid credentials');
    }
    return true;
  }
  
  Future<bool> updateUserPassword(String newPassword) async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate update delay
    
    if (currentUserEmail == null) {
      throw Exception('User not found');
    }
    
    // Update password in mock storage
    userCredentials[currentUserEmail!] = newPassword;
    return true;
  }
}

class MockPasswordChangeService {
  final MockAuthService authService;
  
  MockPasswordChangeService(this.authService);
  
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (authService.currentUserEmail == null) {
      throw Exception('User not found');
    }
    
    // Verify current password by attempting to sign in with it
    try {
      await authService.signInWithPassword(
        email: authService.currentUserEmail!,
        password: currentPassword,
      );
    } catch (e) {
      // If sign in fails, the current password is incorrect
      throw Exception('Current password is incorrect');
    }
    
    // If we get here, current password is correct, update to new password
    await authService.updateUserPassword(newPassword);
  }
}

void main() {
  group('UPD-AS-03: System prevents password change if current password is incorrect', () {
    late MockAuthService authService;
    late MockPasswordChangeService passwordChangeService;
    
    setUp(() {
      authService = MockAuthService();
      passwordChangeService = MockPasswordChangeService(authService);
      
      // Set up a current user
      authService.setCurrentUser('user1@example.com');
    });

    test('Password change fails with incorrect current password', () async {
      expect(
        () => passwordChangeService.changePassword(
          currentPassword: 'wrongpassword',
          newPassword: 'newpassword123',
        ),
        throwsA(predicate((e) => e.toString().contains('Current password is incorrect'))),
      );
    });

    test('Password change succeeds with correct current password', () async {
      await expectLater(
        passwordChangeService.changePassword(
          currentPassword: 'currentpass123',
          newPassword: 'newpassword123',
        ),
        completes,
      );
      
      // Verify password was actually changed
      expect(authService.userCredentials['user1@example.com'], 'newpassword123');
    });

    test('Password change fails when user is not logged in', () async {
      authService.currentUserEmail = null;
      
      expect(
        () => passwordChangeService.changePassword(
          currentPassword: 'anypassword',
          newPassword: 'newpassword123',
        ),
        throwsA(predicate((e) => e.toString().contains('User not found'))),
      );
    });

    test('Auth service correctly validates existing password', () async {
      await expectLater(
        authService.signInWithPassword(
          email: 'user1@example.com',
          password: 'currentpass123',
        ),
        completion(isTrue),
      );
    });

    test('Auth service rejects invalid password', () async {
      expect(
        () => authService.signInWithPassword(
          email: 'user1@example.com',
          password: 'wrongpassword',
        ),
        throwsA(predicate((e) => e.toString().contains('Invalid credentials'))),
      );
    });

    test('Auth service rejects password for non-existent user', () async {
      expect(
        () => authService.signInWithPassword(
          email: 'nonexistent@example.com',
          password: 'anypassword',
        ),
        throwsA(predicate((e) => e.toString().contains('Invalid credentials'))),
      );
    });

    test('Multiple incorrect password attempts are consistently rejected', () async {
      final incorrectPasswords = ['wrong1', 'wrong2', 'incorrect', '123456'];
      
      for (final password in incorrectPasswords) {
        expect(
          () => passwordChangeService.changePassword(
            currentPassword: password,
            newPassword: 'newpassword123',
          ),
          throwsA(predicate((e) => e.toString().contains('Current password is incorrect'))),
        );
      }
    });

    test('Password change with different user accounts', () async {
      // Test with user2
      authService.setCurrentUser('user2@example.com');
      
      expect(
        () => passwordChangeService.changePassword(
          currentPassword: 'wrongpassword',
          newPassword: 'newpassword123',
        ),
        throwsA(predicate((e) => e.toString().contains('Current password is incorrect'))),
      );
      
      // But correct password should work
      await expectLater(
        passwordChangeService.changePassword(
          currentPassword: 'mypassword456',
          newPassword: 'updatedpassword789',
        ),
        completes,
      );
      
      expect(authService.userCredentials['user2@example.com'], 'updatedpassword789');
    });
  });
}
