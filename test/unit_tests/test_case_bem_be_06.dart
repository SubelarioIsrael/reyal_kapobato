// BEM-BE-06: Admin can delete a breathing exercise
// Requirement: Admin can remove breathing exercises with proper validation and confirmation

import 'package:flutter_test/flutter_test.dart';

class MockUser {
  final String email;
  final String id;
  final String userType;
  MockUser({required this.email, required this.id, required this.userType});
}

class MockBreathingExercise {
  final String id;
  final String name;
  final String description;
  final int duration;
  final Map<String, dynamic> pattern;
  final String colorHex;
  final String iconName;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  MockBreathingExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.pattern,
    required this.colorHex,
    required this.iconName,
    required this.createdAt,
    required this.updatedAt,
  });
}

class MockExerciseSession {
  final String sessionId;
  final String exerciseId;
  final String userId;
  final bool isActive;
  
  MockExerciseSession({
    required this.sessionId,
    required this.exerciseId,
    required this.userId,
    required this.isActive,
  });
}

class MockDeletionResult {
  final bool success;
  final String? reason;
  final Map<String, dynamic>? metadata;
  
  MockDeletionResult({
    required this.success,
    this.reason,
    this.metadata,
  });
}

// Mock database
List<MockBreathingExercise> _exerciseDatabase = [
  MockBreathingExercise(
    id: 'ex1',
    name: 'Box Breathing',
    description: 'A simple 4-4-4-4 breathing pattern',
    duration: 240,
    pattern: {'inhale': 4, 'hold': 4, 'exhale': 4, 'hold2': 4},
    colorHex: '#7C83FD',
    iconName: 'square_outlined',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  MockBreathingExercise(
    id: 'ex2',
    name: '4-7-8 Breathing',
    description: 'Sleep-inducing breathing technique',
    duration: 300,
    pattern: {'inhale': 4, 'hold': 7, 'exhale': 8},
    colorHex: '#FF6B6B',
    iconName: 'air',
    createdAt: DateTime.now().subtract(const Duration(days: 8)),
    updatedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  MockBreathingExercise(
    id: 'ex3',
    name: 'Deep Breathing',
    description: 'Simple deep breathing exercise',
    duration: 180,
    pattern: {'inhale': 6, 'hold': 2, 'exhale': 6},
    colorHex: '#4ECDC4',
    iconName: 'waves',
    createdAt: DateTime.now().subtract(const Duration(days: 15)),
    updatedAt: DateTime.now().subtract(const Duration(days: 8)),
  ),
];

// Mock active sessions
List<MockExerciseSession> _activeSessions = [
  MockExerciseSession(
    sessionId: 'session1',
    exerciseId: 'ex1',
    userId: 'student1',
    isActive: true,
  ),
];

Future<MockUser> mockAuthenticateAdmin() async {
  return MockUser(email: 'admin@college.edu', id: 'admin-123', userType: 'admin');
}

Future<MockBreathingExercise?> mockGetBreathingExercise({required String exerciseId}) async {
  try {
    return _exerciseDatabase.firstWhere((exercise) => exercise.id == exerciseId);
  } catch (e) {
    return null;
  }
}

Future<List<MockExerciseSession>> mockGetActiveSessionsForExercise({required String exerciseId}) async {
  return _activeSessions.where((session) => 
    session.exerciseId == exerciseId && session.isActive
  ).toList();
}

Future<MockDeletionResult> mockDeleteBreathingExercise({
  required String exerciseId,
  required String adminId,
  bool forceDelete = false,
}) async {
  // Check if exercise exists
  final exercise = await mockGetBreathingExercise(exerciseId: exerciseId);
  if (exercise == null) {
    return MockDeletionResult(
      success: false,
      reason: 'Exercise not found',
    );
  }
  
  // Prevent deletion if it's the last exercise (check this first)
  if (_exerciseDatabase.length <= 1) {
    return MockDeletionResult(
      success: false,
      reason: 'Cannot delete the last remaining exercise',
    );
  }
  
  // Check for active sessions unless force delete is enabled
  if (!forceDelete) {
    final activeSessions = await mockGetActiveSessionsForExercise(exerciseId: exerciseId);
    if (activeSessions.isNotEmpty) {
      return MockDeletionResult(
        success: false,
        reason: 'Cannot delete exercise with active sessions',
        metadata: {
          'active_sessions_count': activeSessions.length,
          'session_ids': activeSessions.map((s) => s.sessionId).toList(),
        },
      );
    }
  }
  
  // Perform deletion
  final originalCount = _exerciseDatabase.length;
  _exerciseDatabase.removeWhere((ex) => ex.id == exerciseId);
  
  // If force delete, also remove related active sessions
  if (forceDelete) {
    _activeSessions.removeWhere((session) => session.exerciseId == exerciseId);
  }
  
  return MockDeletionResult(
    success: true,
    metadata: {
      'deleted_exercise_name': exercise.name,
      'exercises_remaining': _exerciseDatabase.length,
      'force_deleted': forceDelete,
    },
  );
}

Future<int> mockGetExerciseUsageStats({required String exerciseId}) async {
  // Simulate getting usage statistics
  switch (exerciseId) {
    case 'ex1':
      return 25; // Box Breathing used 25 times
    case 'ex2':
      return 15; // 4-7-8 Breathing used 15 times
    case 'ex3':
      return 5;  // Deep Breathing used 5 times
    default:
      return 0;
  }
}

Future<bool> mockConfirmDeletion({
  required String exerciseId,
  required String exerciseName,
  required bool hasActiveSessions,
}) async {
  // Simulate admin confirmation dialog
  // In real implementation, this would show a dialog
  // For testing, we'll simulate different confirmation scenarios
  
  if (hasActiveSessions) {
    // Simulate that admin might not confirm if there are active sessions
    return false;
  }
  
  // Simulate confirmation for exercises with low usage
  final usageCount = await mockGetExerciseUsageStats(exerciseId: exerciseId);
  return usageCount < 20; // Only confirm deletion for exercises used less than 20 times
}

void main() {
  setUp(() {
    // Reset database before each test
    _exerciseDatabase = [
      MockBreathingExercise(
        id: 'ex1',
        name: 'Box Breathing',
        description: 'A simple 4-4-4-4 breathing pattern',
        duration: 240,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4, 'hold2': 4},
        colorHex: '#7C83FD',
        iconName: 'square_outlined',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      MockBreathingExercise(
        id: 'ex2',
        name: '4-7-8 Breathing',
        description: 'Sleep-inducing breathing technique',
        duration: 300,
        pattern: {'inhale': 4, 'hold': 7, 'exhale': 8},
        colorHex: '#FF6B6B',
        iconName: 'air',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      MockBreathingExercise(
        id: 'ex3',
        name: 'Deep Breathing',
        description: 'Simple deep breathing exercise',
        duration: 180,
        pattern: {'inhale': 6, 'hold': 2, 'exhale': 6},
        colorHex: '#4ECDC4',
        iconName: 'waves',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
    ];
    
    _activeSessions = [
      MockExerciseSession(
        sessionId: 'session1',
        exerciseId: 'ex1',
        userId: 'student1',
        isActive: true,
      ),
    ];
  });

  group('BEM-BE-06: Admin can delete a breathing exercise', () {
    test('Admin successfully deletes exercise without active sessions', () async {
      final admin = await mockAuthenticateAdmin();
      
      final originalCount = _exerciseDatabase.length;
      final exercise = await mockGetBreathingExercise(exerciseId: 'ex3');
      expect(exercise, isNotNull);
      
      final result = await mockDeleteBreathingExercise(
        exerciseId: 'ex3',
        adminId: admin.id,
      );
      
      expect(result.success, true);
      expect(result.metadata?['deleted_exercise_name'], 'Deep Breathing');
      expect(result.metadata?['exercises_remaining'], originalCount - 1);
      expect(_exerciseDatabase.length, originalCount - 1);
      
      // Verify exercise is actually removed
      final deletedExercise = await mockGetBreathingExercise(exerciseId: 'ex3');
      expect(deletedExercise, isNull);
    });

    test('Admin cannot delete exercise with active sessions', () async {
      final admin = await mockAuthenticateAdmin();
      
      final activeSessions = await mockGetActiveSessionsForExercise(exerciseId: 'ex1');
      expect(activeSessions.length, 1);
      
      final originalCount = _exerciseDatabase.length;
      
      final result = await mockDeleteBreathingExercise(
        exerciseId: 'ex1',
        adminId: admin.id,
      );
      
      expect(result.success, false);
      expect(result.reason, 'Cannot delete exercise with active sessions');
      expect(result.metadata?['active_sessions_count'], 1);
      expect(result.metadata?['session_ids'], contains('session1'));
      expect(_exerciseDatabase.length, originalCount); // No change
    });

    test('Admin can force delete exercise with active sessions', () async {
      final admin = await mockAuthenticateAdmin();
      
      final originalCount = _exerciseDatabase.length;
      final originalSessionCount = _activeSessions.length;
      
      final result = await mockDeleteBreathingExercise(
        exerciseId: 'ex1',
        adminId: admin.id,
        forceDelete: true,
      );
      
      expect(result.success, true);
      expect(result.metadata?['force_deleted'], true);
      expect(result.metadata?['deleted_exercise_name'], 'Box Breathing');
      expect(_exerciseDatabase.length, originalCount - 1);
      
      // Verify active sessions are also removed
      expect(_activeSessions.length, lessThan(originalSessionCount));
      final remainingSessions = await mockGetActiveSessionsForExercise(exerciseId: 'ex1');
      expect(remainingSessions.length, 0);
    });

    test('Admin cannot delete non-existent exercise', () async {
      final admin = await mockAuthenticateAdmin();
      
      final result = await mockDeleteBreathingExercise(
        exerciseId: 'nonexistent',
        adminId: admin.id,
      );
      
      expect(result.success, false);
      expect(result.reason, 'Exercise not found');
    });

    test('Admin cannot delete the last remaining exercise', () async {
      final admin = await mockAuthenticateAdmin();
      
      // Remove all but one exercise
      _exerciseDatabase.removeRange(1, _exerciseDatabase.length);
      expect(_exerciseDatabase.length, 1);
      
      final result = await mockDeleteBreathingExercise(
        exerciseId: _exerciseDatabase.first.id,
        adminId: admin.id,
      );
      
      expect(result.success, false);
      expect(result.reason, 'Cannot delete the last remaining exercise');
      expect(_exerciseDatabase.length, 1); // Still has one exercise
    });

    test('Exercise usage statistics are retrieved correctly', () async {
      final boxBreathingUsage = await mockGetExerciseUsageStats(exerciseId: 'ex1');
      final breathingUsage478 = await mockGetExerciseUsageStats(exerciseId: 'ex2');
      final deepBreathingUsage = await mockGetExerciseUsageStats(exerciseId: 'ex3');
      
      expect(boxBreathingUsage, 25);
      expect(breathingUsage478, 15);
      expect(deepBreathingUsage, 5);
    });

    test('Confirmation logic works based on usage and active sessions', () async {
      // Exercise with active sessions should not be confirmed for deletion
      final confirmWithActiveSessions = await mockConfirmDeletion(
        exerciseId: 'ex1',
        exerciseName: 'Box Breathing',
        hasActiveSessions: true,
      );
      expect(confirmWithActiveSessions, false);
      
      // Exercise with low usage should be confirmed for deletion
      final confirmLowUsage = await mockConfirmDeletion(
        exerciseId: 'ex3',
        exerciseName: 'Deep Breathing',
        hasActiveSessions: false,
      );
      expect(confirmLowUsage, true);
      
      // Exercise with high usage should not be confirmed for deletion
      final confirmHighUsage = await mockConfirmDeletion(
        exerciseId: 'ex1',
        exerciseName: 'Box Breathing',
        hasActiveSessions: false,
      );
      expect(confirmHighUsage, false); // 25 uses > 20 threshold
    });

    test('Active sessions are properly tracked per exercise', () async {
      final ex1Sessions = await mockGetActiveSessionsForExercise(exerciseId: 'ex1');
      final ex2Sessions = await mockGetActiveSessionsForExercise(exerciseId: 'ex2');
      final ex3Sessions = await mockGetActiveSessionsForExercise(exerciseId: 'ex3');
      
      expect(ex1Sessions.length, 1);
      expect(ex2Sessions.length, 0);
      expect(ex3Sessions.length, 0);
      
      expect(ex1Sessions.first.sessionId, 'session1');
      expect(ex1Sessions.first.userId, 'student1');
      expect(ex1Sessions.first.isActive, true);
    });

    test('Deletion maintains database integrity', () async {
      final admin = await mockAuthenticateAdmin();
      final originalExercises = List<MockBreathingExercise>.from(_exerciseDatabase);
      
      // Delete ex2
      final result = await mockDeleteBreathingExercise(
        exerciseId: 'ex2',
        adminId: admin.id,
      );
      
      expect(result.success, true);
      expect(_exerciseDatabase.length, originalExercises.length - 1);
      
      // Verify ex1 and ex3 still exist
      final ex1 = await mockGetBreathingExercise(exerciseId: 'ex1');
      final ex3 = await mockGetBreathingExercise(exerciseId: 'ex3');
      expect(ex1, isNotNull);
      expect(ex3, isNotNull);
      
      // Verify ex2 is gone
      final ex2 = await mockGetBreathingExercise(exerciseId: 'ex2');
      expect(ex2, isNull);
    });
  });
}
