// UAM-CAS-04: Counselor's email receives a verification upon account set-up
// Requirement: System should automatically send verification email to counselor after admin creates their account

import 'package:flutter_test/flutter_test.dart';

class MockEmailVerificationService {
  final List<String> verificationEmailsSent = [];
  bool shouldFailToSend = false;
  
  Future<bool> sendVerificationEmail(String email) async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate email sending
    
    if (shouldFailToSend) {
      throw Exception('Failed to send verification email');
    }
    
    verificationEmailsSent.add(email);
    return true;
  }
  
  bool wasVerificationEmailSentTo(String email) {
    return verificationEmailsSent.contains(email);
  }
}

class MockSupabaseAuth {
  final MockEmailVerificationService emailService;
  
  MockSupabaseAuth(this.emailService);
  
  Future<String> signUpUser({
    required String email,
    required String password,
  }) async {
    // Simulate Supabase auth signup which automatically sends verification email
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    // Supabase automatically sends verification email during signup
    await emailService.sendVerificationEmail(email);
    
    return userId;
  }
}

class MockAdminCounselorCreationService {
  final MockSupabaseAuth auth;
  final MockEmailVerificationService emailService;
  
  MockAdminCounselorCreationService(this.auth, this.emailService);
  
  Future<bool> createCounselorAccount({
    required String fullName,
    required String email,
    required String password,
  }) async {
    // Create auth user (this automatically sends verification email via Supabase)
    final userId = await auth.signUpUser(email: email, password: password);
    
    // Split name for counselor record
    final nameParts = fullName.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    // Simulate creating user record in users table
    await Future.delayed(Duration(milliseconds: 100));
    
    // Simulate creating counselor record in counselors table
    await Future.delayed(Duration(milliseconds: 100));
    
    return true;
  }
}

void main() {
  group('UAM-CAS-04: Counselor receives email verification upon account setup', () {
    late MockEmailVerificationService emailService;
    late MockSupabaseAuth auth;
    late MockAdminCounselorCreationService adminService;
    
    setUp(() {
      emailService = MockEmailVerificationService();
      auth = MockSupabaseAuth(emailService);
      adminService = MockAdminCounselorCreationService(auth, emailService);
    });

    test('Verification email is sent when admin creates counselor account', () async {
      final email = 'counselor@university.edu';
      
      await adminService.createCounselorAccount(
        fullName: 'Dr. Jane Smith',
        email: email,
        password: 'securepassword123',
      );
      
      expect(emailService.wasVerificationEmailSentTo(email), isTrue);
      expect(emailService.verificationEmailsSent.length, 1);
    });

    test('Multiple counselor account creations send verification emails', () async {
      final counselors = [
        {'name': 'Dr. John Doe', 'email': 'john.doe@university.edu'},
        {'name': 'Dr. Alice Johnson', 'email': 'alice.johnson@university.edu'},
      ];
      
      for (final counselor in counselors) {
        await adminService.createCounselorAccount(
          fullName: counselor['name']!,
          email: counselor['email']!,
          password: 'password123',
        );
      }
      
      expect(emailService.verificationEmailsSent.length, 2);
      expect(emailService.wasVerificationEmailSentTo(counselors[0]['email']!), isTrue);
      expect(emailService.wasVerificationEmailSentTo(counselors[1]['email']!), isTrue);
    });

    test('Account creation fails if verification email cannot be sent', () async {
      emailService.shouldFailToSend = true;
      
      expect(
        () => adminService.createCounselorAccount(
          fullName: 'Dr. Bob Wilson',
          email: 'bob.wilson@university.edu',
          password: 'password123',
        ),
        throwsA(predicate((e) => e.toString().contains('Failed to send verification email'))),
      );
    });

    test('Auth service properly handles signup and email verification', () async {
      final email = 'test.counselor@university.edu';
      
      await auth.signUpUser(
        email: email,
        password: 'testpassword123',
      );
      
      expect(emailService.wasVerificationEmailSentTo(email), isTrue);
    });

    test('Verification email is sent for each unique counselor email', () async {
      final emails = [
        'counselor1@university.edu',
        'counselor2@university.edu',
        'counselor3@university.edu',
      ];
      
      for (int i = 0; i < emails.length; i++) {
        await adminService.createCounselorAccount(
          fullName: 'Dr. Counselor ${i + 1}',
          email: emails[i],
          password: 'password123',
        );
      }
      
      expect(emailService.verificationEmailsSent.length, 3);
      for (final email in emails) {
        expect(emailService.wasVerificationEmailSentTo(email), isTrue);
      }
    });

    test('Email service correctly tracks sent verification emails', () async {
      final testEmails = ['test1@university.edu', 'test2@university.edu'];
      
      for (final email in testEmails) {
        await emailService.sendVerificationEmail(email);
      }
      
      expect(emailService.verificationEmailsSent, equals(testEmails));
      expect(emailService.wasVerificationEmailSentTo('test1@university.edu'), isTrue);
      expect(emailService.wasVerificationEmailSentTo('test2@university.edu'), isTrue);
      expect(emailService.wasVerificationEmailSentTo('nonexistent@university.edu'), isFalse);
    });
  });
}
