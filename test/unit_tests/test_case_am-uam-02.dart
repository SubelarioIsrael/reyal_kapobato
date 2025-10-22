// AM-UAM-02: Admin can update a user accounts
// Requirement: Admin can update existing user accounts
// Mirrors logic in `admin_users.dart` (toggle user status - activate/suspend)

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

  MockUser copyWith({
    String? status,
  }) {
    return MockUser(
      userId: userId,
      email: email,
      userType: userType,
      status: status ?? this.status,
      registrationDate: registrationDate,
    );
  }
}

// Mock database class to simulate Supabase operations
class MockDatabase {
  List<MockUser> _users = [];

  int get usersCount => _users.length;

  void seedUsers(List<MockUser> users) {
    _users = users;
  }

  Future<void> updateUserStatus(String userId, String newStatus) async {
    final index = _users.indexWhere((user) => user.userId == userId);
    if (index == -1) {
      throw Exception('User not found');
    }
    
    _users[index] = _users[index].copyWith(status: newStatus);
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final sortedUsers = List<MockUser>.from(_users);
    sortedUsers.sort((a, b) => a.email.compareTo(b.email));
    
    return sortedUsers.map((user) => user.toMap()).toList();
  }

  MockUser? findUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.userId == userId);
    } catch (e) {
      return null;
    }
  }
}

// Service class to handle user management operations (updating functionality)
class UserManagementService {
  final MockDatabase _database;

  UserManagementService(this._database);

  Future<void> toggleUserStatus(String userId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
    await _database.updateUserStatus(userId, newStatus);
  }

  Future<List<Map<String, dynamic>>> loadUsers() async {
    try {
      return await _database.fetchUsers();
    } catch (e) {
      throw Exception('Error loading users: $e');
    }
  }

  MockUser? findUserById(String userId) {
    return _database.findUserById(userId);
  }

  String getStatusDisplayText(String status) {
    return status.toUpperCase();
  }

  bool isUserActive(String status) {
    return status.toLowerCase() == 'active';
  }

  String getToggleActionText(String currentStatus) {
    return currentStatus == 'active' ? 'Suspend User' : 'Activate User';
  }
}

void main() {
  group('AM-UAM-02: Admin can update a user accounts', () {
    late MockDatabase mockDatabase;
    late UserManagementService userService;

    setUp(() {
      mockDatabase = MockDatabase();
      userService = UserManagementService(mockDatabase);
    });

    test('Should toggle user status from active to suspended', () async {
      // Seed initial data
      mockDatabase.seedUsers([
        MockUser(
          userId: 'user-1',
          email: 'student@test.com',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime(2025, 1, 1).toIso8601String(),
        ),
      ]);

      await userService.toggleUserStatus('user-1', 'active');

      final users = await userService.loadUsers();
      expect(users.length, 1);
      expect(users[0]['status'], 'suspended');
      expect(users[0]['user_id'], 'user-1');
    });

    test('Should toggle user status from suspended to active', () async {
      // Seed initial data
      mockDatabase.seedUsers([
        MockUser(
          userId: 'user-1',
          email: 'student@test.com',
          userType: 'student',
          status: 'suspended',
          registrationDate: DateTime(2025, 1, 1).toIso8601String(),
        ),
      ]);

      await userService.toggleUserStatus('user-1', 'suspended');

      final users = await userService.loadUsers();
      expect(users.length, 1);
      expect(users[0]['status'], 'active');
      expect(users[0]['user_id'], 'user-1');
    });

    test('Should throw exception when updating non-existent user', () async {
      expect(
        () async => await userService.toggleUserStatus('non-existent', 'active'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('User not found'),
        )),
      );
    });

    test('Should update specific user while preserving others', () async {
      // Seed multiple users
      mockDatabase.seedUsers([
        MockUser(
          userId: 'user-1',
          email: 'user1@test.com',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime(2025, 1, 1).toIso8601String(),
        ),
        MockUser(
          userId: 'user-2',
          email: 'user2@test.com',
          userType: 'counselor',
          status: 'active',
          registrationDate: DateTime(2025, 1, 2).toIso8601String(),
        ),
        MockUser(
          userId: 'user-3',
          email: 'user3@test.com',
          userType: 'admin',
          status: 'suspended',
          registrationDate: DateTime(2025, 1, 3).toIso8601String(),
        ),
      ]);

      // Update only user-2 status
      await userService.toggleUserStatus('user-2', 'active');

      final users = await userService.loadUsers();
      expect(users.length, 3);

      // Find the updated user
      final updatedUser = users.firstWhere((u) => u['user_id'] == 'user-2');
      expect(updatedUser['status'], 'suspended');

      // Verify others remained unchanged
      final user1 = users.firstWhere((u) => u['user_id'] == 'user-1');
      expect(user1['status'], 'active');

      final user3 = users.firstWhere((u) => u['user_id'] == 'user-3');
      expect(user3['status'], 'suspended');
    });

    test('Should handle multiple status toggles correctly', () async {
      // Seed initial data
      mockDatabase.seedUsers([
        MockUser(
          userId: 'user-1',
          email: 'test@example.com',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime(2025, 1, 1).toIso8601String(),
        ),
      ]);

      // First toggle: active -> suspended
      await userService.toggleUserStatus('user-1', 'active');
      var users = await userService.loadUsers();
      expect(users[0]['status'], 'suspended');

      // Second toggle: suspended -> active
      await userService.toggleUserStatus('user-1', 'suspended');
      users = await userService.loadUsers();
      expect(users[0]['status'], 'active');

      // Third toggle: active -> suspended
      await userService.toggleUserStatus('user-1', 'active');
      users = await userService.loadUsers();
      expect(users[0]['status'], 'suspended');
    });

    test('Should find user by ID for editing purposes', () {
      // Seed initial data
      mockDatabase.seedUsers([
        MockUser(
          userId: 'user-1',
          email: 'findable@test.com',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime(2025, 1, 1).toIso8601String(),
        ),
      ]);

      final foundUser = userService.findUserById('user-1');
      expect(foundUser, isNotNull);
      expect(foundUser!.email, 'findable@test.com');
      expect(foundUser.status, 'active');

      final notFoundUser = userService.findUserById('non-existent');
      expect(notFoundUser, isNull);
    });

    test('Should return correct status display text', () {
      expect(userService.getStatusDisplayText('active'), 'ACTIVE');
      expect(userService.getStatusDisplayText('suspended'), 'SUSPENDED');
      expect(userService.getStatusDisplayText('pending'), 'PENDING');
    });

    test('Should correctly identify active users', () {
      expect(userService.isUserActive('active'), true);
      expect(userService.isUserActive('ACTIVE'), true); // Case insensitive
      expect(userService.isUserActive('suspended'), false);
      expect(userService.isUserActive('pending'), false);
    });

    test('Should return correct toggle action text', () {
      expect(userService.getToggleActionText('active'), 'Suspend User');
      expect(userService.getToggleActionText('suspended'), 'Activate User');
      expect(userService.getToggleActionText('pending'), 'Activate User');
    });

    test('Should handle user updates for different user types', () async {
      // Seed users of different types
      mockDatabase.seedUsers([
        MockUser(
          userId: 'admin-1',
          email: 'admin@test.com',
          userType: 'admin',
          status: 'active',
          registrationDate: DateTime(2025, 1, 1).toIso8601String(),
        ),
        MockUser(
          userId: 'counselor-1',
          email: 'counselor@test.com',
          userType: 'counselor',
          status: 'active',
          registrationDate: DateTime(2025, 1, 2).toIso8601String(),
        ),
        MockUser(
          userId: 'student-1',
          email: 'student@test.com',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime(2025, 1, 3).toIso8601String(),
        ),
      ]);

      // Test updating admin
      await userService.toggleUserStatus('admin-1', 'active');
      var users = await userService.loadUsers();
      var admin = users.firstWhere((u) => u['user_id'] == 'admin-1');
      expect(admin['status'], 'suspended');
      expect(admin['user_type'], 'admin');

      // Test updating counselor
      await userService.toggleUserStatus('counselor-1', 'active');
      users = await userService.loadUsers();
      var counselor = users.firstWhere((u) => u['user_id'] == 'counselor-1');
      expect(counselor['status'], 'suspended');
      expect(counselor['user_type'], 'counselor');

      // Test updating student
      await userService.toggleUserStatus('student-1', 'active');
      users = await userService.loadUsers();
      var student = users.firstWhere((u) => u['user_id'] == 'student-1');
      expect(student['status'], 'suspended');
      expect(student['user_type'], 'student');
    });

    test('Should preserve user data integrity during updates', () async {
      // Seed initial data
      mockDatabase.seedUsers([
        MockUser(
          userId: 'user-1',
          email: 'preserve@test.com',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime(2025, 1, 1).toIso8601String(),
        ),
      ]);

      await userService.toggleUserStatus('user-1', 'active');

      final users = await userService.loadUsers();
      final updatedUser = users[0];
      
      // Verify only status changed, other data preserved
      expect(updatedUser['user_id'], 'user-1');
      expect(updatedUser['email'], 'preserve@test.com');
      expect(updatedUser['user_type'], 'student');
      expect(updatedUser['registration_date'], DateTime(2025, 1, 1).toIso8601String());
      expect(updatedUser['status'], 'suspended'); // Only this should change
    });
  });
}