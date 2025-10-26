// UAM-UR-05: Student enters special characters in their name
// Requirement: Names should only contain letters, spaces, hyphens, and apostrophes

import 'package:flutter_test/flutter_test.dart';

class MockNameValidator {
  String? validateName(String? name, String fieldName) {
    if (name == null || name.isEmpty) {
      return 'Please enter your $fieldName';
    }
    
    // Allow letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(name)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }
  
  String? validateFirstName(String? firstName) {
    return validateName(firstName, 'First name');
  }
  
  String? validateLastName(String? lastName) {
    return validateName(lastName, 'Last name');
  }
}

class MockRegistrationService {
  final MockNameValidator validator;
  
  MockRegistrationService(this.validator);
  
  Future<bool> registerStudent({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final firstNameError = validator.validateFirstName(firstName);
    if (firstNameError != null) {
      throw Exception(firstNameError);
    }
    
    final lastNameError = validator.validateLastName(lastName);
    if (lastNameError != null) {
      throw Exception(lastNameError);
    }
    
    return true;
  }
}

void main() {
  group('UAM-UR-05: Special characters in name validation', () {
    late MockNameValidator validator;
    late MockRegistrationService registrationService;
    
    setUp(() {
      validator = MockNameValidator();
      registrationService = MockRegistrationService(validator);
    });

    test('First name with numbers is rejected', () {
      final error = validator.validateFirstName('John123');
      expect(error, 'First name can only contain letters, spaces, hyphens, and apostrophes');
    });

    test('Last name with special characters is rejected', () {
      final error = validator.validateLastName('Doe@#');
      expect(error, 'Last name can only contain letters, spaces, hyphens, and apostrophes');
    });

    test('Valid names with allowed characters are accepted', () {
      expect(validator.validateFirstName('Mary-Jane'), isNull);
      expect(validator.validateLastName("O'Connor"), isNull);
      expect(validator.validateFirstName('Ana Maria'), isNull);
      expect(validator.validateLastName('Van Der Berg'), isNull);
    });

    test('Registration fails with invalid first name', () async {
      expect(
        () => registrationService.registerStudent(
          firstName: 'John@#',
          lastName: 'Doe',
          email: 'john@example.com',
        ),
        throwsA(predicate((e) => e.toString().contains('First name can only contain letters'))),
      );
    });

    test('Registration fails with invalid last name', () async {
      expect(
        () => registrationService.registerStudent(
          firstName: 'John',
          lastName: 'Doe123',
          email: 'john@example.com',
        ),
        throwsA(predicate((e) => e.toString().contains('Last name can only contain letters'))),
      );
    });

    test('Names with symbols and numbers are rejected', () {
      final invalidNames = ['John\$', 'Mary@gmail', 'Test123', 'Name!', 'User#1'];
      
      for (final name in invalidNames) {
        final error = validator.validateFirstName(name);
        expect(error, isNotNull);
        expect(error, contains('can only contain letters, spaces, hyphens, and apostrophes'));
      }
    });
  });
}
