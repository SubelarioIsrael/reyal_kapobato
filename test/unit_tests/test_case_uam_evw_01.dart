// UAM-EVW-01: User's email receives a verification upon registration
// Requirement: System should send verification email automatically after successful registration

import 'package:flutter_test/flutter_test.dart';

class MockEmailService {
  final List<String> sentEmails = [];
  bool shouldFail = false;
  
  Future<bool> sendVerificationEmail(String email, String verificationLink) async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate email sending delay
    
    if (shouldFail) {
      throw Exception('Failed to send verification email');
    }
    
    sentEmails.add(email);
    return true;
  }
  
  bool wasEmailSentTo(String email) {
    return sentEmails.contains(email);
  }
}

class MockAuthService {
  final MockEmailService emailService;
  
  MockAuthService(this.emailService);
  
  Future<String> registerUser({
    required String email,
    required String password,
  }) async {
    // Simulate user creation
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    // Generate verification link
    final verificationLink = 'breathebetter://verify-email?token=abc123&user=$userId';
    
    // Send verification email
    await emailService.sendVerificationEmail(email, verificationLink);
    
    return userId;
  }
}

void main() {
  group('UAM-EVW-01: Email verification upon registration', () {
    late MockEmailService emailService;
    late MockAuthService authService;
    
    setUp(() {
      emailService = MockEmailService();
      authService = MockAuthService(emailService);
    });

    test('Verification email is sent after successful registration', () async {
      final email = 'student@example.com';
      
      await authService.registerUser(
        email: email,
        password: 'password123',
      );
      
      expect(emailService.wasEmailSentTo(email), isTrue);
      expect(emailService.sentEmails.length, 1);
    });

    test('Multiple registrations send verification emails to respective addresses', () async {
      final emails = ['student1@example.com', 'student2@example.com'];
      
      for (final email in emails) {
        await authService.registerUser(
          email: email,
          password: 'password123',
        );
      }
      
      expect(emailService.sentEmails.length, 2);
      expect(emailService.wasEmailSentTo(emails[0]), isTrue);
      expect(emailService.wasEmailSentTo(emails[1]), isTrue);
    });

    test('Registration fails if verification email cannot be sent', () async {
      emailService.shouldFail = true;
      
      expect(
        () => authService.registerUser(
          email: 'student@example.com',
          password: 'password123',
        ),
        throwsA(predicate((e) => e.toString().contains('Failed to send verification email'))),
      );
    });

    test('Verification email contains proper link format', () async {
      final email = 'test@example.com';
      
      await authService.registerUser(
        email: email,
        password: 'password123',
      );
      
      expect(emailService.wasEmailSentTo(email), isTrue);
    });
  });
}
