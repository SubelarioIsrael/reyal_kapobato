// UAM-UR-03: Student leaves required registration fields empty
// Requirement: All required fields must be validated and show appropriate error messages

import 'package:flutter_test/flutter_test.dart';

class MockRegistrationForm {
  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email) ? null : 'Please enter a valid email address';
  }

  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please enter a password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateFirstName(String? firstName) {
    return (firstName == null || firstName.isEmpty) ? 'Please enter your first name' : null;
  }

  String? validateLastName(String? lastName) {
    return (lastName == null || lastName.isEmpty) ? 'Please enter your last name' : null;
  }

  String? validateStudentId(String? studentId) {
    return (studentId == null || studentId.isEmpty) ? 'Please enter your student ID number' : null;
  }

  String? validateEducationLevel(String? educationLevel) {
    return educationLevel == null ? 'Please select your education level' : null;
  }

  List<String> validateAllFields({
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    String? studentId,
    String? educationLevel,
  }) {
    List<String> errors = [];
    
    final emailError = validateEmail(email);
    if (emailError != null) errors.add(emailError);
    
    final passwordError = validatePassword(password);
    if (passwordError != null) errors.add(passwordError);
    
    final firstNameError = validateFirstName(firstName);
    if (firstNameError != null) errors.add(firstNameError);
    
    final lastNameError = validateLastName(lastName);
    if (lastNameError != null) errors.add(lastNameError);
    
    final studentIdError = validateStudentId(studentId);
    if (studentIdError != null) errors.add(studentIdError);
    
    final educationLevelError = validateEducationLevel(educationLevel);
    if (educationLevelError != null) errors.add(educationLevelError);
    
    return errors;
  }
}

void main() {
  group('UAM-UR-03: Required field validation during registration', () {
    late MockRegistrationForm form;
    
    setUp(() {
      form = MockRegistrationForm();
    });

    test('Empty email field shows validation error', () {
      final error = form.validateEmail('');
      expect(error, 'Please enter your email address');
    });

    test('Empty password field shows validation error', () {
      final error = form.validatePassword('');
      expect(error, 'Please enter a password');
    });

    test('Empty first name field shows validation error', () {
      final error = form.validateFirstName('');
      expect(error, 'Please enter your first name');
    });

    test('Empty last name field shows validation error', () {
      final error = form.validateLastName('');
      expect(error, 'Please enter your last name');
    });

    test('Empty student ID field shows validation error', () {
      final error = form.validateStudentId('');
      expect(error, 'Please enter your student ID number');
    });

    test('No education level selected shows validation error', () {
      final error = form.validateEducationLevel(null);
      expect(error, 'Please select your education level');
    });

    test('All empty fields return multiple validation errors', () {
      final errors = form.validateAllFields(
        email: '',
        password: '',
        firstName: '',
        lastName: '',
        studentId: '',
        educationLevel: null,
      );
      
      expect(errors.length, 6);
      expect(errors, contains('Please enter your email address'));
      expect(errors, contains('Please enter a password'));
      expect(errors, contains('Please enter your first name'));
      expect(errors, contains('Please enter your last name'));
      expect(errors, contains('Please enter your student ID number'));
      expect(errors, contains('Please select your education level'));
    });
  });
}
