// AM-UAM-01: Admin can view all the user accounts
// Requirement: Admin can view all existing user accounts
// Mirrors logic in `admin_users.dart` (load and display users with filtering)

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent a user account
class MockUser {
  final String userId;
  final String email;
  final String userType;
  final String status;
  final String registrationDate;
  final Map<String, dynamic>? students; // For student-specific data

  MockUser({
    required this.userId,
    required this.email,
    required this.userType,
    required this.status,
    required this.registrationDate,
    this.students,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'user_type': userType,
      'status': status,
      'registration_date': registrationDate,
      'students': students,
    };
  }
}

// Mock database class to simulate Supabase operations
class MockDatabase {
  List<MockUser> _users = [];

  int get usersCount => _users.length;

  void seedUsers(List<MockUser> users) {
    _users = users;
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    // Simulate database ordering: email ascending (as in admin_users.dart)
    final sortedUsers = List<MockUser>.from(_users);
    sortedUsers.sort((a, b) => a.email.compareTo(b.email));
    
    return sortedUsers.map((user) => user.toMap()).toList();
  }

  List<Map<String, dynamic>> filterUsers(String searchQuery, String typeFilter) {
    return _users.where((user) {
      final matchesType = typeFilter == 'all' || user.userType == typeFilter;
      final matchesSearch = searchQuery.isEmpty ||
          user.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (user.students?['student_code'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
      return matchesType && matchesSearch;
    }).map((user) => user.toMap()).toList();
  }
}

// Service class to handle user management operations (viewing only)
class UserManagementService {
  final MockDatabase _database;

  UserManagementService(this._database);

  Future<List<Map<String, dynamic>>> loadUsers() async {
    try {
      return await _database.fetchUsers();
    } catch (e) {
      throw Exception('Error loading users: $e');
    }
  }

  List<Map<String, dynamic>> applyFilters(String searchQuery, String typeFilter) {
    return _database.filterUsers(searchQuery, typeFilter);
  }

  String getUserTypeIcon(String? userType) {
    switch (userType) {
      case 'admin':
        return 'admin_panel_settings';
      case 'counselor':
        return 'psychology';
      case 'student':
        return 'school';
      default:
        return 'person';
    }
  }

  String getUserTypeColor(String? userType) {
    switch (userType) {
      case 'admin':
        return 'indigo';
      case 'counselor':
        return 'green';
      case 'student':
        return 'blue_grey';
      default:
        return 'grey';
    }
  }
}

void main() {
  group('AM-UAM-01: Admin can view all the user accounts', () {
    late MockDatabase mockDatabase;
    late UserManagementService userService;

    setUp(() {
      mockDatabase = MockDatabase();
      userService = UserManagementService(mockDatabase);
    });

    test('Should load and display all user accounts', () async {
      // Seed test data
      mockDatabase.seedUsers([
        MockUser(
          userId: 'user-1',
          email: 'admin@breathebetter.com',
          userType: 'admin',
          status: 'active',
          registrationDate: DateTime(2025, 1, 1).toIso8601String(),
        ),
        MockUser(
          userId: 'user-2',
          email: 'counselor@breathebetter.com',
          userType: 'counselor',
          status: 'active',
          registrationDate: DateTime(2025, 1, 2).toIso8601String(),
        ),
        MockUser(
          userId: 'user-3',
          email: 'student@breathebetter.com',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime(2025, 1, 3).toIso8601String(),
          students: {
            'student_code': 'STU2025001',
            'course': 'Computer Science',
            'year_level': 2,
          },
        ),
      ]);

      // Test loading users
      final users = await userService.loadUsers();

      // Verify results (should be sorted by email)
      expect(users.length, 3);
      expect(users[0]['email'], 'admin@breathebetter.com');
      expect(users[0]['user_type'], 'admin');
      expect(users[0]['status'], 'active');
      
      expect(users[1]['email'], 'counselor@breathebetter.com');
      expect(users[1]['user_type'], 'counselor');
      
      expect(users[2]['email'], 'student@breathebetter.com');
      expect(users[2]['user_type'], 'student');
      expect(users[2]['students']['student_code'], 'STU2025001');
    });

    test('Should handle empty user list', () async {
      // No seeded data
      final users = await userService.loadUsers();
      
      expect(users.length, 0);
      expect(users, isEmpty);
    });

    test('Should filter users by type correctly', () {
      // Seed test data
      mockDatabase.seedUsers([
        MockUser(
          userId: 'admin-1',
          email: 'admin1@test.com',
          userType: 'admin',
          status: 'active',
          registrationDate: DateTime.now().toIso8601String(),
        ),
        MockUser(
          userId: 'counselor-1',
          email: 'counselor1@test.com',
          userType: 'counselor',
          status: 'active',
          registrationDate: DateTime.now().toIso8601String(),
        ),
        MockUser(
          userId: 'student-1',
          email: 'student1@test.com',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime.now().toIso8601String(),
        ),
      ]);

      // Test filtering by student type
      final students = userService.applyFilters('', 'student');
      expect(students.length, 1);
      expect(students[0]['user_type'], 'student');

      // Test filtering by counselor type
      final counselors = userService.applyFilters('', 'counselor');
      expect(counselors.length, 1);
      expect(counselors[0]['user_type'], 'counselor');

      // Test filtering by admin type
      final admins = userService.applyFilters('', 'admin');
      expect(admins.length, 1);
      expect(admins[0]['user_type'], 'admin');

      // Test showing all users
      final allUsers = userService.applyFilters('', 'all');
      expect(allUsers.length, 3);
    });

    test('Should search users by email correctly', () {
      // Seed test data
      mockDatabase.seedUsers([
        MockUser(
          userId: 'user-1',
          email: 'john.doe@university.edu',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime.now().toIso8601String(),
        ),
        MockUser(
          userId: 'user-2',
          email: 'jane.smith@university.edu',
          userType: 'counselor',
          status: 'active',
          registrationDate: DateTime.now().toIso8601String(),
        ),
        MockUser(
          userId: 'user-3',
          email: 'admin@breathebetter.com',
          userType: 'admin',
          status: 'active',
          registrationDate: DateTime.now().toIso8601String(),
        ),
      ]);

      // Test search by partial email
      final universityUsers = userService.applyFilters('university', 'all');
      expect(universityUsers.length, 2);
      expect(universityUsers.every((user) => 
          user['email'].toString().contains('university')), true);

      // Test search by specific name
      final johnUsers = userService.applyFilters('john', 'all');
      expect(johnUsers.length, 1);
      expect(johnUsers[0]['email'], 'john.doe@university.edu');

      // Test case-insensitive search
      final adminUsers = userService.applyFilters('ADMIN', 'all');
      expect(adminUsers.length, 1);
      expect(adminUsers[0]['email'], 'admin@breathebetter.com');
    });

    test('Should search users by student code correctly', () {
      // Seed test data
      mockDatabase.seedUsers([
        MockUser(
          userId: 'student-1',
          email: 'student1@test.com',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime.now().toIso8601String(),
          students: {'student_code': 'CS2025001'},
        ),
        MockUser(
          userId: 'student-2',
          email: 'student2@test.com',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime.now().toIso8601String(),
          students: {'student_code': 'IT2025002'},
        ),
      ]);

      // Test search by student code
      final csStudents = userService.applyFilters('CS2025', 'all');
      expect(csStudents.length, 1);
      expect(csStudents[0]['students']['student_code'], 'CS2025001');

      // Test case-insensitive student code search
      final itStudents = userService.applyFilters('it2025', 'all');
      expect(itStudents.length, 1);
      expect(itStudents[0]['students']['student_code'], 'IT2025002');
    });

    test('Should combine search and filter correctly', () {
      // Seed test data
      mockDatabase.seedUsers([
        MockUser(
          userId: 'user-1',
          email: 'student.cs@university.edu',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime.now().toIso8601String(),
        ),
        MockUser(
          userId: 'user-2',
          email: 'counselor.cs@university.edu',
          userType: 'counselor',
          status: 'active',
          registrationDate: DateTime.now().toIso8601String(),
        ),
        MockUser(
          userId: 'user-3',
          email: 'student.it@university.edu',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime.now().toIso8601String(),
        ),
      ]);

      // Test search + filter combination
      final csStudents = userService.applyFilters('cs', 'student');
      expect(csStudents.length, 1);
      expect(csStudents[0]['email'], 'student.cs@university.edu');
      expect(csStudents[0]['user_type'], 'student');

      // Verify counselor with 'cs' is excluded by filter
      final csCounselors = userService.applyFilters('cs', 'counselor');
      expect(csCounselors.length, 1);
      expect(csCounselors[0]['user_type'], 'counselor');
    });

    test('Should return correct user type icons', () {
      expect(userService.getUserTypeIcon('admin'), 'admin_panel_settings');
      expect(userService.getUserTypeIcon('counselor'), 'psychology');
      expect(userService.getUserTypeIcon('student'), 'school');
      expect(userService.getUserTypeIcon('unknown'), 'person');
      expect(userService.getUserTypeIcon(null), 'person');
    });

    test('Should return correct user type colors', () {
      expect(userService.getUserTypeColor('admin'), 'indigo');
      expect(userService.getUserTypeColor('counselor'), 'green');
      expect(userService.getUserTypeColor('student'), 'blue_grey');
      expect(userService.getUserTypeColor('unknown'), 'grey');
      expect(userService.getUserTypeColor(null), 'grey');
    });

    test('Should handle users with different statuses', () async {
      // Seed test data with different statuses
      mockDatabase.seedUsers([
        MockUser(
          userId: 'active-user',
          email: 'active@test.com',
          userType: 'student',
          status: 'active',
          registrationDate: DateTime.now().toIso8601String(),
        ),
        MockUser(
          userId: 'suspended-user',
          email: 'suspended@test.com',
          userType: 'student',
          status: 'suspended',
          registrationDate: DateTime.now().toIso8601String(),
        ),
      ]);

      final users = await userService.loadUsers();
      expect(users.length, 2);
      
      final activeUser = users.firstWhere((u) => u['email'] == 'active@test.com');
      expect(activeUser['status'], 'active');
      
      final suspendedUser = users.firstWhere((u) => u['email'] == 'suspended@test.com');
      expect(suspendedUser['status'], 'suspended');
    });
  });
}