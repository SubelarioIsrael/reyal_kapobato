// AM-UAM-03: Admin can add all the user accounts
// Requirement: Admin can add new user accounts with validation
// Mirrors logic in `admin_users.dart` (create new users with email/password validation)

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent a user account
class MockUser {
  final String userId;
  final String email;
  final String userType;
  final String status;
  final String registrationDate;

  MockUser({
    required this.userId,
    required this.email,
    required this.userType,
    required this.status,
    required this.registrationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'user_type': userType,
      'status': status,
      'registration_date': registrationDate,
    };
  }
}

// Mock database class to simulate Supabase operations
class MockDatabase {
  List<MockUser> _users = [];
  int _nextIdNumber = 1;

  int get usersCount => _users.length;

  void seedUsers(List<MockUser> users) {
    _users = users;
    _nextIdNumber = users.isEmpty ? 1 : users.length + 1;
  }

  Future<void> createUser(String email, String password, String userType) async {
    // Simulate auth user creation
    final userId = 'user-${_nextIdNumber++}';
    
    final newUser = MockUser(
      userId: userId,
      email: email,
      userType: userType,
      status: 'active',
      registrationDate: DateTime.now().toIso8601String(),
    );
    _users.add(newUser);
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final sortedUsers = List<MockUser>.from(_users);
    sortedUsers.sort((a, b) => a.email.compareTo(b.email));
    
    return sortedUsers.map((user) => user.toMap()).toList();
  }

  bool emailExists(String email) {
    return _users.any((user) => user.email.toLowerCase() == email.toLowerCase());
  }
}

// Service class to handle user management operations (adding functionality)
class UserManagementService {
  final MockDatabase _database;

  UserManagementService(this._database);

  String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Please enter an email';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please enter a password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? validateConfirmPassword(String? confirmPassword, String password) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (confirmPassword != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool isValidUserType(String userType) {
    return ['admin', 'counselor', 'student'].contains(userType);
  }

  Future<void> createUser(String email, String password, String userType) async {
    final emailError = validateEmail(email);
    if (emailError != null) throw Exception(emailError);

    final passwordError = validatePassword(password);
    if (passwordError != null) throw Exception(passwordError);

    if (!isValidUserType(userType)) {
      throw Exception('Invalid user type');
    }

    if (_database.emailExists(email)) {
      throw Exception('Email already exists');
    }

    await _database.createUser(email.trim(), password, userType);
  }

  Future<List<Map<String, dynamic>>> loadUsers() async {
    try {
      return await _database.fetchUsers();
    } catch (e) {
      throw Exception('Error loading users: $e');
    }
  }

  List<String> getAvailableUserTypes() {
    return ['counselor', 'admin'];
  }

  Map<String, String> getUserCreationDetails(String email, String userType) {
    return {
      'email': email,
      'user_type': userType.toUpperCase(),
      'status': 'ACTIVE',
      'created_at': DateTime.now().toIso8601String().split('T')[0],
    };
  }
}

void main() {
  group('AM-UAM-03: Admin can add all the user accounts', () {
    late MockDatabase mockDatabase;
    late UserManagementService userService;

    setUp(() {
      mockDatabase = MockDatabase();
      userService = UserManagementService(mockDatabase);
    });

    test('Should validate email input correctly', () {
      // Test empty email
      expect(userService.validateEmail(''), 'Please enter an email');
      expect(userService.validateEmail(null), 'Please enter an email');
      expect(userService.validateEmail('   '), 'Please enter an email');
      
      // Test invalid email formats
      expect(userService.validateEmail('invalid-email'), 'Enter a valid email');
      expect(userService.validateEmail('test@'), 'Enter a valid email');
      expect(userService.validateEmail('@domain.com'), 'Enter a valid email');
      expect(userService.validateEmail('test@domain'), 'Enter a valid email');
      
      // Test valid email
      expect(userService.validateEmail('user@breathebetter.com'), null);
      expect(userService.validateEmail('test.user@university.edu'), null);
    });

    test('Should validate password input correctly', () {
      // Test empty password
      expect(userService.validatePassword(''), 'Please enter a password');
      expect(userService.validatePassword(null), 'Please enter a password');
      
      // Test short password
      expect(userService.validatePassword('12345'), 'Password must be at least 6 characters long');
      
      // Test valid password
      expect(userService.validatePassword('password123'), null);
      expect(userService.validatePassword('securePass'), null);
    });

    test('Should validate confirm password correctly', () {
      // Test empty confirm password
      expect(userService.validateConfirmPassword('', 'password123'), 'Please confirm your password');
      expect(userService.validateConfirmPassword(null, 'password123'), 'Please confirm your password');
      
      // Test password mismatch
      expect(userService.validateConfirmPassword('different', 'password123'), 'Passwords do not match');
      
      // Test matching passwords
      expect(userService.validateConfirmPassword('password123', 'password123'), null);
    });

    test('Should create new user successfully', () async {
      final email = 'new.counselor@breathebetter.com';
      final password = 'securePassword123';
      final userType = 'counselor';

      await userService.createUser(email, password, userType);

      expect(mockDatabase.usersCount, 1);
      
      final users = await userService.loadUsers();
      expect(users[0]['email'], email);
      expect(users[0]['user_type'], userType);
      expect(users[0]['status'], 'active');
      expect(users[0]['user_id'], 'user-1');
    });

    test('Should create multiple users with proper ID incrementation', () async {
      // Create first user
      await userService.createUser('user1@test.com', 'password123', 'counselor');
      
      // Create second user
      await userService.createUser('user2@test.com', 'password456', 'admin');

      expect(mockDatabase.usersCount, 2);
      
      final users = await userService.loadUsers();
      expect(users[0]['user_id'], 'user-1');
      expect(users[1]['user_id'], 'user-2');
    });

    test('Should throw exception for invalid email during creation', () async {
      expect(
        () async => await userService.createUser('', 'password123', 'counselor'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Please enter an email'),
        )),
      );

      expect(
        () async => await userService.createUser('invalid-email', 'password123', 'counselor'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Enter a valid email'),
        )),
      );
    });

    test('Should throw exception for invalid password during creation', () async {
      expect(
        () async => await userService.createUser('valid@test.com', '', 'counselor'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Please enter a password'),
        )),
      );

      expect(
        () async => await userService.createUser('valid@test.com', '123', 'counselor'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Password must be at least 6 characters long'),
        )),
      );
    });

    test('Should throw exception for invalid user type', () async {
      expect(
        () async => await userService.createUser('valid@test.com', 'password123', 'invalid_type'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid user type'),
        )),
      );
    });

    test('Should throw exception for duplicate email', () async {
      // Create first user
      await userService.createUser('duplicate@test.com', 'password123', 'counselor');

      // Try to create second user with same email
      expect(
        () async => await userService.createUser('duplicate@test.com', 'password456', 'admin'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email already exists'),
        )),
      );

      // Verify only one user was created
      expect(mockDatabase.usersCount, 1);
    });

    test('Should handle case-insensitive email duplication', () async {
      // Create first user
      await userService.createUser('test@example.com', 'password123', 'counselor');

      // Try to create second user with same email but different case
      expect(
        () async => await userService.createUser('TEST@EXAMPLE.COM', 'password456', 'admin'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email already exists'),
        )),
      );
    });

    test('Should validate user types correctly', () {
      expect(userService.isValidUserType('admin'), true);
      expect(userService.isValidUserType('counselor'), true);
      expect(userService.isValidUserType('student'), true);
      expect(userService.isValidUserType('invalid'), false);
      expect(userService.isValidUserType(''), false);
    });

    test('Should return available user types', () {
      final userTypes = userService.getAvailableUserTypes();
      expect(userTypes, contains('counselor'));
      expect(userTypes, contains('admin'));
      expect(userTypes.length, 2);
    });

    test('Should trim whitespace from email before creation', () async {
      final emailWithSpaces = '   user@test.com   ';
      await userService.createUser(emailWithSpaces, 'password123', 'counselor');

      final users = await userService.loadUsers();
      expect(users[0]['email'], 'user@test.com');
    });

    test('Should create users with different types correctly', () async {
      // Create admin user
      await userService.createUser('admin@test.com', 'adminPass123', 'admin');
      
      // Create counselor user
      await userService.createUser('counselor@test.com', 'counselorPass123', 'counselor');

      final users = await userService.loadUsers();
      expect(users.length, 2);
      
      final admin = users.firstWhere((u) => u['email'] == 'admin@test.com');
      expect(admin['user_type'], 'admin');
      
      final counselor = users.firstWhere((u) => u['email'] == 'counselor@test.com');
      expect(counselor['user_type'], 'counselor');
    });

    test('Should return correct user creation details', () {
      final details = userService.getUserCreationDetails('test@example.com', 'counselor');
      
      expect(details['email'], 'test@example.com');
      expect(details['user_type'], 'COUNSELOR');
      expect(details['status'], 'ACTIVE');
      expect(details['created_at'], isNotEmpty);
    });

    test('Should maintain proper ordering after user creation', () async {
      // Create users in non-alphabetical order
      await userService.createUser('zebra@test.com', 'password123', 'admin');
      await userService.createUser('alpha@test.com', 'password456', 'counselor');
      await userService.createUser('beta@test.com', 'password789', 'admin');

      final users = await userService.loadUsers();
      
      // Should be sorted by email (as per admin_users.dart)
      expect(users[0]['email'], 'alpha@test.com');
      expect(users[1]['email'], 'beta@test.com');
      expect(users[2]['email'], 'zebra@test.com');
    });
  });
}