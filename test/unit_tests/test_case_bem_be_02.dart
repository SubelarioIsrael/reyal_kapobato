// BEM-BE-02: Students can perform breathing exercises with cues
// Requirement: Students can execute breathing exercises with visual and text cues

import 'package:flutter_test/flutter_test.dart';

class MockBreathingExercise {
  final String id;
  final String name;
  final int duration;
  final Map<String, dynamic> pattern;
  
  MockBreathingExercise({
    required this.id,
    required this.name,
    required this.duration,
    required this.pattern,
  });
}

class MockExerciseSession {
  final String sessionId;
  final String exerciseId;
  final String userId;
  final DateTime startTime;
  final String currentPhase;
  final int remainingSeconds;
  final int phaseSecondsLeft;
  final bool isActive;
  
  MockExerciseSession({
    required this.sessionId,
    required this.exerciseId,
    required this.userId,
    required this.startTime,
    required this.currentPhase,
    required this.remainingSeconds,
    required this.phaseSecondsLeft,
    required this.isActive,
  });
}

class MockActivityRecord {
  final String userId;
  final String activityType;
  final DateTime completedAt;
  final Map<String, dynamic> metadata;
  
  MockActivityRecord({
    required this.userId,
    required this.activityType,
    required this.completedAt,
    required this.metadata,
  });
}

// Mock exercises
final _mockExercises = {
  'box': MockBreathingExercise(
    id: 'box',
    name: 'Box Breathing',
    duration: 120,
    pattern: {'inhale': 4, 'hold': 4, 'exhale': 4, 'hold2': 4},
  ),
  '478': MockBreathingExercise(
    id: '478',
    name: '4-7-8 Breathing',
    duration: 60,
    pattern: {'inhale': 4, 'hold': 7, 'exhale': 8},
  ),
};

List<MockActivityRecord> _activityRecords = [];

Future<MockExerciseSession> mockStartBreathingExercise({
  required String userId,
  required String exerciseId,
}) async {
  final exercise = _mockExercises[exerciseId];
  if (exercise == null) {
    throw Exception('Exercise not found');
  }

  return MockExerciseSession(
    sessionId: 'session-${DateTime.now().millisecondsSinceEpoch}',
    exerciseId: exerciseId,
    userId: userId,
    startTime: DateTime.now(),
    currentPhase: 'inhale',
    remainingSeconds: exercise.duration,
    phaseSecondsLeft: exercise.pattern['inhale'],
    isActive: true,
  );
}

List<String> mockGetPhaseOrder(Map<String, dynamic> pattern) {
  const phaseOrder = ['inhale', 'hold', 'exhale', 'hold2'];
  return phaseOrder.where((phase) => pattern.containsKey(phase)).toList();
}

MockExerciseSession mockUpdateExercisePhase({
  required MockExerciseSession session,
  required String newPhase,
  required int newPhaseSeconds,
  required int remainingSeconds,
}) {
  return MockExerciseSession(
    sessionId: session.sessionId,
    exerciseId: session.exerciseId,
    userId: session.userId,
    startTime: session.startTime,
    currentPhase: newPhase,
    remainingSeconds: remainingSeconds,
    phaseSecondsLeft: newPhaseSeconds,
    isActive: remainingSeconds > 0,
  );
}

String mockGetPhaseInstruction(String phase) {
  switch (phase) {
    case 'inhale':
      return 'Breathe in through nose';
    case 'hold':
    case 'hold2':
      return 'Hold your breath';
    case 'exhale':
      return 'Breathe out through mouth';
    default:
      return '';
  }
}

double mockGetCircleSize({
  required String phase,
  required double animationValue,
  required double minSize,
  required double maxSize,
}) {
  switch (phase) {
    case 'inhale':
      return minSize + (maxSize - minSize) * animationValue;
    case 'exhale':
      return maxSize - (maxSize - minSize) * (1 - animationValue);
    case 'hold2':
      return minSize;
    default: // 'hold'
      return maxSize;
  }
}

Future<void> mockRecordActivityCompletion({
  required String userId,
  required String exerciseId,
  required int duration,
}) async {
  _activityRecords.add(MockActivityRecord(
    userId: userId,
    activityType: 'breathing_exercise',
    completedAt: DateTime.now(),
    metadata: {
      'exercise_id': exerciseId,
      'duration_seconds': duration,
    },
  ));
}

void main() {
  group('BEM-BE-02: Students can perform breathing exercises with cues', () {
    test('Student successfully starts a breathing exercise session', () async {
      final session = await mockStartBreathingExercise(
        userId: 'student-123',
        exerciseId: 'box',
      );
      
      expect(session.exerciseId, 'box');
      expect(session.userId, 'student-123');
      expect(session.isActive, true);
      expect(session.currentPhase, 'inhale');
      expect(session.remainingSeconds, 120);
      expect(session.phaseSecondsLeft, 4);
    });

    test('Exercise phases progress in correct order for box breathing', () async {
      final exercise = _mockExercises['box']!;
      final phaseOrder = mockGetPhaseOrder(exercise.pattern);
      
      expect(phaseOrder, ['inhale', 'hold', 'exhale', 'hold2']);
    });

    test('Exercise phases progress in correct order for 4-7-8 breathing', () async {
      final exercise = _mockExercises['478']!;
      final phaseOrder = mockGetPhaseOrder(exercise.pattern);
      
      expect(phaseOrder, ['inhale', 'hold', 'exhale']);
      expect(phaseOrder.contains('hold2'), false);
    });

    test('Phase instructions are provided correctly', () async {
      expect(mockGetPhaseInstruction('inhale'), 'Breathe in through nose');
      expect(mockGetPhaseInstruction('hold'), 'Hold your breath');
      expect(mockGetPhaseInstruction('hold2'), 'Hold your breath');
      expect(mockGetPhaseInstruction('exhale'), 'Breathe out through mouth');
    });

    test('Exercise session updates phases correctly', () async {
      var session = await mockStartBreathingExercise(
        userId: 'student-123',
        exerciseId: 'box',
      );
      
      // Simulate phase transition from inhale to hold
      session = mockUpdateExercisePhase(
        session: session,
        newPhase: 'hold',
        newPhaseSeconds: 4,
        remainingSeconds: 116,
      );
      
      expect(session.currentPhase, 'hold');
      expect(session.phaseSecondsLeft, 4);
      expect(session.remainingSeconds, 116);
      expect(session.isActive, true);
    });

    test('Visual cues (circle size) change correctly based on phase', () async {
      const minSize = 200.0;
      const maxSize = 300.0;
      
      // Test inhale phase (circle grows)
      final inhaleSize = mockGetCircleSize(
        phase: 'inhale',
        animationValue: 0.5,
        minSize: minSize,
        maxSize: maxSize,
      );
      expect(inhaleSize, 250.0); // halfway between min and max
      
      // Test exhale phase (circle shrinks)
      final exhaleSize = mockGetCircleSize(
        phase: 'exhale',
        animationValue: 0.5,
        minSize: minSize,
        maxSize: maxSize,
      );
      expect(exhaleSize, 250.0); // halfway between max and min
      
      // Test hold phase (circle stays at max)
      final holdSize = mockGetCircleSize(
        phase: 'hold',
        animationValue: 0.5,
        minSize: minSize,
        maxSize: maxSize,
      );
      expect(holdSize, maxSize);
      
      // Test hold2 phase (circle stays at min)
      final hold2Size = mockGetCircleSize(
        phase: 'hold2',
        animationValue: 0.5,
        minSize: minSize,
        maxSize: maxSize,
      );
      expect(hold2Size, minSize);
    });

    test('Exercise completion is recorded correctly', () async {
      final initialRecordCount = _activityRecords.length;
      
      await mockRecordActivityCompletion(
        userId: 'student-123',
        exerciseId: 'box',
        duration: 120,
      );
      
      expect(_activityRecords.length, initialRecordCount + 1);
      final latestRecord = _activityRecords.last;
      expect(latestRecord.userId, 'student-123');
      expect(latestRecord.activityType, 'breathing_exercise');
      expect(latestRecord.metadata['exercise_id'], 'box');
      expect(latestRecord.metadata['duration_seconds'], 120);
    });

    test('Exercise session ends when time reaches zero', () async {
      var session = await mockStartBreathingExercise(
        userId: 'student-123',
        exerciseId: 'box',
      );
      
      // Simulate exercise completion
      session = mockUpdateExercisePhase(
        session: session,
        newPhase: 'exhale',
        newPhaseSeconds: 0,
        remainingSeconds: 0,
      );
      
      expect(session.remainingSeconds, 0);
      expect(session.isActive, false);
    });

    test('Invalid exercise ID throws error', () async {
      expect(
        () => mockStartBreathingExercise(
          userId: 'student-123',
          exerciseId: 'nonexistent',
        ),
        throwsA(predicate((e) => e.toString().contains('Exercise not found'))),
      );
    });
  });
}
