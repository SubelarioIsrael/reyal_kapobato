// UAM-UR-04: Student enters an existing student ID
// Requirement: System should prevent registration with duplicate student IDs

import 'package:flutter_test/flutter_test.dart';

class MockStudentDatabase {
  final List<String> existingStudentIds = ['2021-001', '2022-150', '2023-999'];
  
  Future<bool> studentIdExists(String studentId) async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate database call
    return existingStudentIds.contains(studentId);
  }
}

class MockRegistrationService {
  final MockStudentDatabase database;
  
  MockRegistrationService(this.database);
  
  Future<void> validateStudentId(String studentId) async {
    if (studentId.isEmpty) {
      throw Exception('Please enter your student ID number');
    }
    
    final exists = await database.studentIdExists(studentId);
    if (exists) {
      throw Exception('This Student ID is already registered. Please use a different Student ID.');
    }
  }
  
  Future<bool> registerStudent({
    required String email,
    required String studentId,
    required String firstName,
    required String lastName,
  }) async {
    await validateStudentId(studentId);
    return true;
  }
}

void main() {
  group('UAM-UR-04: Duplicate student ID validation', () {
    late MockStudentDatabase database;
    late MockRegistrationService registrationService;
    
    setUp(() {
      database = MockStudentDatabase();
      registrationService = MockRegistrationService(database);
    });

    test('Registration fails with existing student ID', () async {
      expect(
        () => registrationService.registerStudent(
          email: 'newstudent@example.com',
          studentId: '2021-001',
          firstName: 'John',
          lastName: 'Doe',
        ),
        throwsA(predicate((e) => e.toString().contains('This Student ID is already registered'))),
      );
    });

    test('Student ID validation fails for existing ID', () async {
      expect(
        () => registrationService.validateStudentId('2022-150'),
        throwsA(predicate((e) => e.toString().contains('This Student ID is already registered'))),
      );
    });

    test('Student ID validation passes for new ID', () async {
      await expectLater(
        registrationService.validateStudentId('2024-001'),
        completes,
      );
    });

    test('Database correctly identifies existing student IDs', () async {
      expect(await database.studentIdExists('2021-001'), isTrue);
      expect(await database.studentIdExists('2022-150'), isTrue);
      expect(await database.studentIdExists('2023-999'), isTrue);
    });

    test('Database correctly identifies non-existing student IDs', () async {
      expect(await database.studentIdExists('2024-001'), isFalse);
      expect(await database.studentIdExists('NEW-ID'), isFalse);
    });
  });
}
