// UAM-CAS-01: Admin enters an existing email for a counselor account
// Requirement: System should prevent creating counselor accounts with duplicate emails

import 'package:flutter_test/flutter_test.dart';

class MockUserDatabase {
  final List<String> existingEmails = [
    'admin@school.edu',
    'counselor1@university.edu',
    'student@example.com'
  ];
  
  Future<bool> emailExists(String email) async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate database query
    return existingEmails.contains(email);
  }
}

class MockAdminAccountService {
  final MockUserDatabase database;
  
  MockAdminAccountService(this.database);
  
  Future<void> validateEmail(String email) async {
    if (email.isEmpty) {
      throw Exception('Please enter an email');
    }
    
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw Exception('Enter a valid email');
    }
    
    final exists = await database.emailExists(email);
    if (exists) {
      throw Exception('Failed to create account: User with this email already exists');
    }
  }
  
  Future<bool> createCounselorAccount({
    required String email,
    required String fullName,
    required String password,
  }) async {
    await validateEmail(email);
    
    // Split name for counselor record
    final nameParts = fullName.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    // Simulate account creation process
    await Future.delayed(Duration(milliseconds: 200));
    
    return true;
  }
}

void main() {
  group('UAM-CAS-01: Admin enters existing email for counselor account', () {
    late MockUserDatabase database;
    late MockAdminAccountService adminService;
    
    setUp(() {
      database = MockUserDatabase();
      adminService = MockAdminAccountService(database);
    });

    test('Counselor account creation fails with existing email', () async {
      expect(
        () => adminService.createCounselorAccount(
          email: 'counselor1@university.edu',
          fullName: 'Jane Smith',
          password: 'password123',
        ),
        throwsA(predicate((e) => e.toString().contains('User with this email already exists'))),
      );
    });

    test('Email validation fails for existing admin email', () async {
      expect(
        () => adminService.validateEmail('admin@school.edu'),
        throwsA(predicate((e) => e.toString().contains('User with this email already exists'))),
      );
    });

    test('Email validation fails for existing student email', () async {
      expect(
        () => adminService.validateEmail('student@example.com'),
        throwsA(predicate((e) => e.toString().contains('User with this email already exists'))),
      );
    });

    test('Email validation passes for new email', () async {
      await expectLater(
        adminService.validateEmail('newcounselor@university.edu'),
        completes,
      );
    });

    test('Database correctly identifies existing emails', () async {
      expect(await database.emailExists('admin@school.edu'), isTrue);
      expect(await database.emailExists('counselor1@university.edu'), isTrue);
      expect(await database.emailExists('student@example.com'), isTrue);
    });

    test('Database correctly identifies non-existing emails', () async {
      expect(await database.emailExists('new@university.edu'), isFalse);
      expect(await database.emailExists('fresh@school.edu'), isFalse);
    });

    test('Counselor account creation succeeds with unique email', () async {
      final result = await adminService.createCounselorAccount(
        email: 'newcounselor@university.edu',
        fullName: 'John Doe',
        password: 'password123',
      );
      
      expect(result, isTrue);
    });
  });
}
