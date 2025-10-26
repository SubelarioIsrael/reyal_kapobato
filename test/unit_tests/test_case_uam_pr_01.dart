// UAM-PR-01: User enters their registered email and receives a password reset link email
// Requirement: System should send password reset email to registered users only

import 'package:flutter_test/flutter_test.dart';

class MockPasswordResetService {
  final List<String> registeredEmails = [
    'student1@example.com',
    'student2@university.edu',
    'counselor@school.edu'
  ];
  final List<String> resetEmailsSent = [];
  bool shouldFailToSend = false;
  
  Future<bool> sendPasswordResetEmail(String email) async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate email sending
    
    if (shouldFailToSend) {
      throw Exception('Failed to send password reset email');
    }
    
    if (!registeredEmails.contains(email)) {
      throw Exception('No account found with this email address');
    }
    
    resetEmailsSent.add(email);
    return true;
  }
  
  bool wasResetEmailSentTo(String email) {
    return resetEmailsSent.contains(email);
  }
  
  String generateResetLink(String email) {
    final token = 'reset_${DateTime.now().millisecondsSinceEpoch}';
    return 'breathebetter://reset-password?token=$token&email=${Uri.encodeComponent(email)}';
  }
}

class MockPasswordResetController {
  final MockPasswordResetService resetService;
  
  MockPasswordResetController(this.resetService);
  
  Future<String> requestPasswordReset(String email) async {
    if (email.isEmpty) {
      throw Exception('Please enter your email address');
    }
    
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw Exception('Please enter a valid email address');
    }
    
    await resetService.sendPasswordResetEmail(email);
    return 'Password reset email sent successfully';
  }
}

void main() {
  group('UAM-PR-01: Password reset email functionality', () {
    late MockPasswordResetService resetService;
    late MockPasswordResetController controller;
    
    setUp(() {
      resetService = MockPasswordResetService();
      controller = MockPasswordResetController(resetService);
    });

    test('Password reset email is sent to registered user', () async {
      final email = 'student1@example.com';
      
      final result = await controller.requestPasswordReset(email);
      
      expect(result, 'Password reset email sent successfully');
      expect(resetService.wasResetEmailSentTo(email), isTrue);
    });

    test('Password reset fails for unregistered email', () async {
      expect(
        () => controller.requestPasswordReset('unregistered@example.com'),
        throwsA(predicate((e) => e.toString().contains('No account found with this email address'))),
      );
    });

    test('Password reset fails with invalid email format', () async {
      expect(
        () => controller.requestPasswordReset('invalid-email'),
        throwsA(predicate((e) => e.toString().contains('Please enter a valid email address'))),
      );
    });

    test('Password reset fails with empty email', () async {
      expect(
        () => controller.requestPasswordReset(''),
        throwsA(predicate((e) => e.toString().contains('Please enter your email address'))),
      );
    });

    test('Multiple reset requests can be sent to different registered emails', () async {
      final emails = ['student1@example.com', 'counselor@school.edu'];
      
      for (final email in emails) {
        await controller.requestPasswordReset(email);
      }
      
      expect(resetService.resetEmailsSent.length, 2);
      expect(resetService.wasResetEmailSentTo(emails[0]), isTrue);
      expect(resetService.wasResetEmailSentTo(emails[1]), isTrue);
    });

    test('Reset link generation produces valid format', () {
      final email = 'test@example.com';
      final link = resetService.generateResetLink(email);
      
      expect(link, contains('breathebetter://reset-password'));
      expect(link, contains('token='));
      expect(link, contains('email='));
    });

    test('Service failure throws appropriate exception', () async {
      resetService.shouldFailToSend = true;
      
      expect(
        () => controller.requestPasswordReset('student1@example.com'),
        throwsA(predicate((e) => e.toString().contains('Failed to send password reset email'))),
      );
    });
  });
}
