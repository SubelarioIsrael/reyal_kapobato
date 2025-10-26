// UAM-EVW-02: User can successfully verify their email by clicking the verification link
// Requirement: Verification link should verify user's email and update their status

import 'package:flutter_test/flutter_test.dart';

class MockUser {
  final String userId;
  final String email;
  bool isEmailVerified;
  
  MockUser({
    required this.userId,
    required this.email,
    this.isEmailVerified = false,
  });
}

class MockVerificationService {
  final Map<String, MockUser> users = {};
  final Map<String, String> verificationTokens = {}; // token -> userId
  
  String createUser(String email, String password) {
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final user = MockUser(userId: userId, email: email);
    users[userId] = user;
    
    // Generate verification token
    final token = 'token_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    verificationTokens[token] = userId;
    
    return token;
  }
  
  Future<bool> verifyEmail(String token) async {
    await Future.delayed(Duration(milliseconds: 50)); // Simulate verification delay
    
    final userId = verificationTokens[token];
    if (userId == null) {
      throw Exception('Invalid or expired verification token');
    }
    
    final user = users[userId];
    if (user == null) {
      throw Exception('User not found');
    }
    
    if (user.isEmailVerified) {
      throw Exception('Email is already verified');
    }
    
    user.isEmailVerified = true;
    verificationTokens.remove(token); // Token can only be used once
    return true;
  }
  
  bool isEmailVerified(String userId) {
    return users[userId]?.isEmailVerified ?? false;
  }
  
  bool tokenExists(String token) {
    return verificationTokens.containsKey(token);
  }
}

void main() {
  group('UAM-EVW-02: Successful email verification via link', () {
    late MockVerificationService verificationService;
    
    setUp(() {
      verificationService = MockVerificationService();
    });

    test('User successfully verifies email with valid token', () async {
      final token = verificationService.createUser('student@example.com', 'password123');
      final userId = verificationService.verificationTokens[token]!;
      
      // Email should not be verified initially
      expect(verificationService.isEmailVerified(userId), isFalse);
      
      // Verify email using the token
      final result = await verificationService.verifyEmail(token);
      
      expect(result, isTrue);
      expect(verificationService.isEmailVerified(userId), isTrue);
    });

    test('Verification token is consumed after successful verification', () async {
      final token = verificationService.createUser('student@example.com', 'password123');
      
      await verificationService.verifyEmail(token);
      
      // Token should no longer exist after verification
      expect(verificationService.tokenExists(token), isFalse);
    });

    test('Verification fails with invalid token', () async {
      expect(
        () => verificationService.verifyEmail('invalid_token'),
        throwsA(predicate((e) => e.toString().contains('Invalid or expired verification token'))),
      );
    });

    test('Verification fails when using token twice', () async {
      final token = verificationService.createUser('student@example.com', 'password123');
      
      // First verification succeeds
      await verificationService.verifyEmail(token);
      
      // Second verification with same token fails
      expect(
        () => verificationService.verifyEmail(token),
        throwsA(predicate((e) => e.toString().contains('Invalid or expired verification token'))),
      );
    });

    test('Cannot verify already verified email', () async {
      final token = verificationService.createUser('student@example.com', 'password123');
      final userId = verificationService.verificationTokens[token]!;
      
      // Manually set email as verified
      verificationService.users[userId]!.isEmailVerified = true;
      
      expect(
        () => verificationService.verifyEmail(token),
        throwsA(predicate((e) => e.toString().contains('Email is already verified'))),
      );
    });
  });
}
