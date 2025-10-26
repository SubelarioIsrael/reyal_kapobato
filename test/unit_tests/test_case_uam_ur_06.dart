// UAM-UR-06: Student enters a year level out of its educational level range
// Requirement: Year level must be within valid range based on selected education level

import 'package:flutter_test/flutter_test.dart';

class MockEducationValidator {
  String? validateYearLevel(String? yearLevel, String? educationLevel) {
    if (yearLevel == null || yearLevel.isEmpty) {
      return 'Please enter your year/grade level';
    }
    
    final year = int.tryParse(yearLevel);
    if (year == null) {
      return 'Please enter a valid number';
    }
    
    switch (educationLevel) {
      case 'basic_education':
        if (year < 1 || year > 6) {
          return 'Basic Education grade level must be between 1 and 6';
        }
        break;
      case 'junior_high':
        if (year < 7 || year > 10) {
          return 'Junior High grade level must be between 7 and 10';
        }
        break;
      case 'senior_high':
        if (year < 11 || year > 12) {
          return 'Senior High grade level must be between 11 and 12';
        }
        break;
      case 'college':
        if (year < 1 || year > 4) {
          return 'College year level must be between 1 and 4';
        }
        break;
      default:
        return 'Please select an education level first';
    }
    
    return null;
  }
}

class MockRegistrationService {
  final MockEducationValidator validator;
  
  MockRegistrationService(this.validator);
  
  Future<bool> registerStudent({
    required String educationLevel,
    required String yearLevel,
  }) async {
    final error = validator.validateYearLevel(yearLevel, educationLevel);
    if (error != null) {
      throw Exception(error);
    }
    return true;
  }
}

void main() {
  group('UAM-UR-06: Year level validation based on education level', () {
    late MockEducationValidator validator;
    late MockRegistrationService registrationService;
    
    setUp(() {
      validator = MockEducationValidator();
      registrationService = MockRegistrationService(validator);
    });

    test('Basic Education year level out of range (above 6) is rejected', () {
      final error = validator.validateYearLevel('7', 'basic_education');
      expect(error, 'Basic Education grade level must be between 1 and 6');
    });

    test('Basic Education year level out of range (below 1) is rejected', () {
      final error = validator.validateYearLevel('0', 'basic_education');
      expect(error, 'Basic Education grade level must be between 1 and 6');
    });

    test('Junior High year level out of range is rejected', () {
      final error = validator.validateYearLevel('6', 'junior_high');
      expect(error, 'Junior High grade level must be between 7 and 10');
    });

    test('Senior High year level out of range is rejected', () {
      final error = validator.validateYearLevel('13', 'senior_high');
      expect(error, 'Senior High grade level must be between 11 and 12');
    });

    test('College year level out of range is rejected', () {
      final error = validator.validateYearLevel('5', 'college');
      expect(error, 'College year level must be between 1 and 4');
    });

    test('Valid year levels within range are accepted', () {
      expect(validator.validateYearLevel('3', 'basic_education'), isNull);
      expect(validator.validateYearLevel('8', 'junior_high'), isNull);
      expect(validator.validateYearLevel('11', 'senior_high'), isNull);
      expect(validator.validateYearLevel('2', 'college'), isNull);
    });

    test('Registration fails with invalid year level for college', () async {
      expect(
        () => registrationService.registerStudent(
          educationLevel: 'college',
          yearLevel: '5',
        ),
        throwsA(predicate((e) => e.toString().contains('College year level must be between 1 and 4'))),
      );
    });

    test('Non-numeric year level is rejected', () {
      final error = validator.validateYearLevel('abc', 'college');
      expect(error, 'Please enter a valid number');
    });

    test('Empty year level is rejected', () {
      final error = validator.validateYearLevel('', 'college');
      expect(error, 'Please enter your year/grade level');
    });
  });
}
