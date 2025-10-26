// UAM-PR-02: After clicking the reset password verification link, user will be directed to the password reset page
// Requirement: Valid reset links should redirect users to password reset page with proper token validation

import 'package:flutter_test/flutter_test.dart';

class MockResetToken {
  final String token;
  final String email;
  final DateTime createdAt;
  final bool isUsed;
  
  MockResetToken({
    required this.token,
    required this.email,
    required this.createdAt,
    this.isUsed = false,
  });
  
  bool get isExpired {
    final now = DateTime.now();
    final expiry = createdAt.add(Duration(hours: 1)); // 1 hour expiry
    return now.isAfter(expiry);
  }
}

class MockPasswordResetPageService {
  final Map<String, MockResetToken> validTokens = {};
  
  void createResetToken(String email) {
    final token = 'reset_${DateTime.now().millisecondsSinceEpoch}';
    validTokens[token] = MockResetToken(
      token: token,
      email: email,
      createdAt: DateTime.now(),
    );
  }
  
  Future<Map<String, dynamic>> validateResetLink(String token) async {
    await Future.delayed(Duration(milliseconds: 50)); // Simulate validation
    
    final resetToken = validTokens[token];
    
    if (resetToken == null) {
      throw Exception('Invalid reset link. Please request a new password reset.');
    }
    
    if (resetToken.isExpired) {
      throw Exception('Reset link has expired. Please request a new password reset.');
    }
    
    if (resetToken.isUsed) {
      throw Exception('Reset link has already been used. Please request a new password reset.');
    }
    
    return {
      'isValid': true,
      'email': resetToken.email,
      'token': resetToken.token,
      'canResetPassword': true,
    };
  }
  
  Future<bool> resetPassword(String token, String newPassword) async {
    final validation = await validateResetLink(token);
    
    if (!validation['canResetPassword']) {
      throw Exception('Cannot reset password with this token');
    }
    
    if (newPassword.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    
    // Mark token as used
    validTokens[token] = MockResetToken(
      token: token,
      email: validation['email'],
      createdAt: validTokens[token]!.createdAt,
      isUsed: true,
    );
    
    return true;
  }
  
  String? getTokenEmail(String token) {
    return validTokens[token]?.email;
  }
  
  bool isTokenUsed(String token) {
    return validTokens[token]?.isUsed ?? false;
  }
}

void main() {
  group('UAM-PR-02: Password reset page redirection and functionality', () {
    late MockPasswordResetPageService pageService;
    
    setUp(() {
      pageService = MockPasswordResetPageService();
    });

    test('Valid reset link redirects to password reset page with token validation', () async {
      final email = 'student@example.com';
      pageService.createResetToken(email);
      final token = pageService.validTokens.keys.first;
      
      final validation = await pageService.validateResetLink(token);
      
      expect(validation['isValid'], isTrue);
      expect(validation['email'], email);
      expect(validation['token'], token);
      expect(validation['canResetPassword'], isTrue);
    });

    test('Invalid token throws appropriate error', () async {
      expect(
        () => pageService.validateResetLink('invalid_token'),
        throwsA(predicate((e) => e.toString().contains('Invalid reset link'))),
      );
    });

    test('Expired token throws appropriate error', () async {
      final email = 'student@example.com';
      final token = 'expired_token';
      
      // Create an expired token (2 hours ago)
      pageService.validTokens[token] = MockResetToken(
        token: token,
        email: email,
        createdAt: DateTime.now().subtract(Duration(hours: 2)),
      );
      
      expect(
        () => pageService.validateResetLink(token),
        throwsA(predicate((e) => e.toString().contains('Reset link has expired'))),
      );
    });

    test('Used token cannot be used again', () async {
      final email = 'student@example.com';
      pageService.createResetToken(email);
      final token = pageService.validTokens.keys.first;
      
      // Use the token to reset password
      await pageService.resetPassword(token, 'newpassword123');
      
      // Try to validate the same token again
      expect(
        () => pageService.validateResetLink(token),
        throwsA(predicate((e) => e.toString().contains('Reset link has already been used'))),
      );
    });

    test('Password reset succeeds with valid token and strong password', () async {
      final email = 'student@example.com';
      pageService.createResetToken(email);
      final token = pageService.validTokens.keys.first;
      
      final result = await pageService.resetPassword(token, 'newpassword123');
      
      expect(result, isTrue);
      expect(pageService.isTokenUsed(token), isTrue);
    });

    test('Password reset fails with weak password', () async {
      final email = 'student@example.com';
      pageService.createResetToken(email);
      final token = pageService.validTokens.keys.first;
      
      expect(
        () => pageService.resetPassword(token, '12345'),
        throwsA(predicate((e) => e.toString().contains('Password must be at least 6 characters'))),
      );
    });

    test('Reset page displays correct email from token', () async {
      final email = 'test@example.com';
      pageService.createResetToken(email);
      final token = pageService.validTokens.keys.first;
      
      final tokenEmail = pageService.getTokenEmail(token);
      
      expect(tokenEmail, email);
    });
  });
}
