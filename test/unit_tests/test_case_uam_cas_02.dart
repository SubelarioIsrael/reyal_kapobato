// UAM-CAS-02: Admin leaves a field empty during account set-up
// Requirement: All required fields must be validated during counselor account creation

import 'package:flutter_test/flutter_test.dart';

class MockCounselorAccountForm {
  String? validateName(String? name) {
    return (name == null || name.isEmpty) ? 'Please enter a name' : null;
  }

  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter an email';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email) ? null : 'Enter a valid email';
  }

  String? validatePassword(String? password) {
    return (password == null || password.isEmpty) ? 'Please enter a password' : null;
  }

  String? validateConfirmPassword(String? confirmPassword, String? password) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (confirmPassword != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validateRole(String? role) {
    return role == null ? 'Please select a role' : null;
  }

  List<String> validateAllFields({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    String? role,
  }) {
    List<String> errors = [];
    
    final nameError = validateName(name);
    if (nameError != null) errors.add(nameError);
    
    final emailError = validateEmail(email);
    if (emailError != null) errors.add(emailError);
    
    final passwordError = validatePassword(password);
    if (passwordError != null) errors.add(passwordError);
    
    final confirmPasswordError = validateConfirmPassword(confirmPassword, password);
    if (confirmPasswordError != null) errors.add(confirmPasswordError);
    
    final roleError = validateRole(role);
    if (roleError != null) errors.add(roleError);
    
    return errors;
  }
}

class MockAdminAccountCreationService {
  final MockCounselorAccountForm form;
  
  MockAdminAccountCreationService(this.form);
  
  Future<bool> createAccount({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    String? role,
  }) async {
    final errors = form.validateAllFields(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      role: role,
    );
    
    if (errors.isNotEmpty) {
      throw Exception('Form validation failed: ${errors.join(', ')}');
    }
    
    return true;
  }
}

void main() {
  group('UAM-CAS-02: Admin leaves required field empty during account setup', () {
    late MockCounselorAccountForm form;
    late MockAdminAccountCreationService service;
    
    setUp(() {
      form = MockCounselorAccountForm();
      service = MockAdminAccountCreationService(form);
    });

    test('Empty name field shows validation error', () {
      final error = form.validateName('');
      expect(error, 'Please enter a name');
    });

    test('Empty email field shows validation error', () {
      final error = form.validateEmail('');
      expect(error, 'Please enter an email');
    });

    test('Empty password field shows validation error', () {
      final error = form.validatePassword('');
      expect(error, 'Please enter a password');
    });

    test('Empty confirm password field shows validation error', () {
      final error = form.validateConfirmPassword('', 'password123');
      expect(error, 'Please confirm your password');
    });

    test('No role selected shows validation error', () {
      final error = form.validateRole(null);
      expect(error, 'Please select a role');
    });

    test('Account creation fails with empty name', () async {
      expect(
        () => service.createAccount(
          name: '',
          email: 'counselor@example.com',
          password: 'password123',
          confirmPassword: 'password123',
          role: 'counselor',
        ),
        throwsA(predicate((e) => e.toString().contains('Please enter a name'))),
      );
    });

    test('Account creation fails with empty email', () async {
      expect(
        () => service.createAccount(
          name: 'John Doe',
          email: '',
          password: 'password123',
          confirmPassword: 'password123',
          role: 'counselor',
        ),
        throwsA(predicate((e) => e.toString().contains('Please enter an email'))),
      );
    });

    test('Account creation fails with empty password', () async {
      expect(
        () => service.createAccount(
          name: 'John Doe',
          email: 'counselor@example.com',
          password: '',
          confirmPassword: 'password123',
          role: 'counselor',
        ),
        throwsA(predicate((e) => e.toString().contains('Please enter a password'))),
      );
    });

    test('All empty fields return multiple validation errors', () {
      final errors = form.validateAllFields(
        name: '',
        email: '',
        password: '',
        confirmPassword: '',
        role: null,
      );
      
      expect(errors.length, 5);
      expect(errors, contains('Please enter a name'));
      expect(errors, contains('Please enter an email'));
      expect(errors, contains('Please enter a password'));
      expect(errors, contains('Please confirm your password'));
      expect(errors, contains('Please select a role'));
    });

    test('Account creation succeeds with all required fields filled', () async {
      final result = await service.createAccount(
        name: 'John Doe',
        email: 'counselor@example.com',
        password: 'password123',
        confirmPassword: 'password123',
        role: 'counselor',
      );
      
      expect(result, isTrue);
    });
  });
}
