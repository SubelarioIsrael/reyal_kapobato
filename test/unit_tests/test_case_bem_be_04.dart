// BEM-BE-04: Admin can add a breathing exercise
// Requirement: Admin can create new breathing exercises with patterns, descriptions, and visual settings

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

class MockExerciseInput {
  final String name;
  final String description;
  final int duration;
  final Map<String, dynamic> pattern;
  final String colorHex;
  final String iconName;
  
  MockExerciseInput({
    required this.name,
    required this.description,
    required this.duration,
    required this.pattern,
    required this.colorHex,
    required this.iconName,
  });
}

// Mock database
List<MockBreathingExercise> _exerciseDatabase = [];
int _nextId = 1;

Future<MockUser> mockAuthenticateAdmin() async {
  return MockUser(email: 'admin@college.edu', id: 'admin-123', userType: 'admin');
}

Future<MockBreathingExercise> mockAddBreathingExercise({
  required MockExerciseInput input,
  required String adminId,
}) async {
  // Validate required fields
  if (input.name.trim().isEmpty) {
    throw Exception('Exercise name is required');
  }
  if (input.description.trim().isEmpty) {
    throw Exception('Exercise description is required');
  }
  if (input.duration <= 0) {
    throw Exception('Duration must be greater than 0');
  }
  if (input.pattern.isEmpty) {
    throw Exception('Exercise pattern is required');
  }
  
  // Validate pattern structure
  if (!input.pattern.containsKey('inhale') || 
      !input.pattern.containsKey('hold') || 
      !input.pattern.containsKey('exhale')) {
    throw Exception('Pattern must contain inhale, hold, and exhale phases');
  }
  
  // Validate pattern values
  for (final entry in input.pattern.entries) {
    if (entry.value is! int || entry.value <= 0) {
      throw Exception('Pattern values must be positive integers');
    }
  }
  
  // Check for duplicate names
  final existingExercise = _exerciseDatabase.where(
    (exercise) => exercise.name.toLowerCase() == input.name.toLowerCase().trim()
  ).isNotEmpty;
  
  if (existingExercise) {
    throw Exception('Exercise with this name already exists');
  }
  
  // Validate color hex format
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(input.colorHex)) {
    throw Exception('Invalid color format. Use #RRGGBB format');
  }
  
  // Validate icon name
  final validIcons = ['air', 'square_outlined', 'waves', 'self_improvement'];
  if (!validIcons.contains(input.iconName)) {
    throw Exception('Invalid icon name. Must be one of: ${validIcons.join(', ')}');
  }
  
  final now = DateTime.now();
  final newExercise = MockBreathingExercise(
    id: 'ex${_nextId++}',
    name: input.name.trim(),
    description: input.description.trim(),
    duration: input.duration,
    pattern: Map<String, dynamic>.from(input.pattern),
    colorHex: input.colorHex,
    iconName: input.iconName,
    createdAt: now,
    updatedAt: now,
  );
  
  _exerciseDatabase.add(newExercise);
  return newExercise;
}

bool mockValidatePatternConsistency(Map<String, dynamic> pattern, int duration) {
  // Calculate minimum cycles needed
  int cycleTime = 0;
  pattern.forEach((key, value) => cycleTime += value as int);
  
  if (cycleTime == 0) return false;
  
  final minimumCycles = duration / cycleTime;
  return minimumCycles >= 1; // At least one complete cycle
}

void main() {
  setUp(() {
    _exerciseDatabase.clear();
    _nextId = 1;
  });

  group('BEM-BE-04: Admin can add a breathing exercise', () {
    test('Admin successfully adds a basic breathing exercise', () async {
      final admin = await mockAuthenticateAdmin();
      
      final input = MockExerciseInput(
        name: 'Box Breathing',
        description: 'A simple 4-4-4-4 breathing pattern that helps reduce stress',
        duration: 240,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4, 'hold2': 4},
        colorHex: '#7C83FD',
        iconName: 'square_outlined',
      );
      
      final exercise = await mockAddBreathingExercise(
        input: input,
        adminId: admin.id,
      );
      
      expect(exercise.id, isNotNull);
      expect(exercise.name, 'Box Breathing');
      expect(exercise.description, input.description);
      expect(exercise.duration, 240);
      expect(exercise.pattern['inhale'], 4);
      expect(exercise.pattern['hold'], 4);
      expect(exercise.pattern['exhale'], 4);
      expect(exercise.pattern['hold2'], 4);
      expect(exercise.colorHex, '#7C83FD');
      expect(exercise.iconName, 'square_outlined');
      expect(exercise.createdAt, isA<DateTime>());
      expect(exercise.updatedAt, exercise.createdAt);
    });

    test('Admin successfully adds 4-7-8 breathing exercise without second hold', () async {
      final admin = await mockAuthenticateAdmin();
      
      final input = MockExerciseInput(
        name: '4-7-8 Breathing',
        description: 'Inhale for 4, hold for 7, exhale for 8. Great for sleep',
        duration: 300,
        pattern: {'inhale': 4, 'hold': 7, 'exhale': 8},
        colorHex: '#FF6B6B',
        iconName: 'air',
      );
      
      final exercise = await mockAddBreathingExercise(
        input: input,
        adminId: admin.id,
      );
      
      expect(exercise.pattern.containsKey('hold2'), false);
      expect(exercise.pattern.keys.length, 3);
      expect(exercise.iconName, 'air');
    });

    test('Adding exercise with empty name fails validation', () async {
      final admin = await mockAuthenticateAdmin();
      
      final input = MockExerciseInput(
        name: '',
        description: 'Valid description',
        duration: 180,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4},
        colorHex: '#7C83FD',
        iconName: 'air',
      );
      
      expect(
        () => mockAddBreathingExercise(input: input, adminId: admin.id),
        throwsA(predicate((e) => e.toString().contains('Exercise name is required'))),
      );
    });

    test('Adding exercise with empty description fails validation', () async {
      final admin = await mockAuthenticateAdmin();
      
      final input = MockExerciseInput(
        name: 'Valid Name',
        description: '   ',
        duration: 180,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4},
        colorHex: '#7C83FD',
        iconName: 'air',
      );
      
      expect(
        () => mockAddBreathingExercise(input: input, adminId: admin.id),
        throwsA(predicate((e) => e.toString().contains('Exercise description is required'))),
      );
    });

    test('Adding exercise with invalid duration fails validation', () async {
      final admin = await mockAuthenticateAdmin();
      
      final input = MockExerciseInput(
        name: 'Valid Name',
        description: 'Valid description',
        duration: 0,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4},
        colorHex: '#7C83FD',
        iconName: 'air',
      );
      
      expect(
        () => mockAddBreathingExercise(input: input, adminId: admin.id),
        throwsA(predicate((e) => e.toString().contains('Duration must be greater than 0'))),
      );
    });

    test('Adding exercise with incomplete pattern fails validation', () async {
      final admin = await mockAuthenticateAdmin();
      
      final input = MockExerciseInput(
        name: 'Valid Name',
        description: 'Valid description',
        duration: 180,
        pattern: {'inhale': 4, 'hold': 4}, // Missing exhale
        colorHex: '#7C83FD',
        iconName: 'air',
      );
      
      expect(
        () => mockAddBreathingExercise(input: input, adminId: admin.id),
        throwsA(predicate((e) => e.toString().contains('Pattern must contain inhale, hold, and exhale phases'))),
      );
    });

    test('Adding exercise with invalid pattern values fails validation', () async {
      final admin = await mockAuthenticateAdmin();
      
      final input = MockExerciseInput(
        name: 'Valid Name',
        description: 'Valid description',
        duration: 180,
        pattern: {'inhale': 4, 'hold': 0, 'exhale': 4}, // Invalid hold value
        colorHex: '#7C83FD',
        iconName: 'air',
      );
      
      expect(
        () => mockAddBreathingExercise(input: input, adminId: admin.id),
        throwsA(predicate((e) => e.toString().contains('Pattern values must be positive integers'))),
      );
    });

    test('Adding exercise with duplicate name fails validation', () async {
      final admin = await mockAuthenticateAdmin();
      
      // Add first exercise
      final input1 = MockExerciseInput(
        name: 'Box Breathing',
        description: 'First description',
        duration: 180,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4},
        colorHex: '#7C83FD',
        iconName: 'air',
      );
      await mockAddBreathingExercise(input: input1, adminId: admin.id);
      
      // Try to add duplicate
      final input2 = MockExerciseInput(
        name: 'Box Breathing', // Same name
        description: 'Second description',
        duration: 240,
        pattern: {'inhale': 5, 'hold': 5, 'exhale': 5},
        colorHex: '#FF6B6B',
        iconName: 'waves',
      );
      
      expect(
        () => mockAddBreathingExercise(input: input2, adminId: admin.id),
        throwsA(predicate((e) => e.toString().contains('Exercise with this name already exists'))),
      );
    });

    test('Adding exercise with invalid color format fails validation', () async {
      final admin = await mockAuthenticateAdmin();
      
      final input = MockExerciseInput(
        name: 'Valid Name',
        description: 'Valid description',
        duration: 180,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4},
        colorHex: 'invalid-color',
        iconName: 'air',
      );
      
      expect(
        () => mockAddBreathingExercise(input: input, adminId: admin.id),
        throwsA(predicate((e) => e.toString().contains('Invalid color format'))),
      );
    });

    test('Adding exercise with invalid icon fails validation', () async {
      final admin = await mockAuthenticateAdmin();
      
      final input = MockExerciseInput(
        name: 'Valid Name',
        description: 'Valid description',
        duration: 180,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4},
        colorHex: '#7C83FD',
        iconName: 'invalid_icon',
      );
      
      expect(
        () => mockAddBreathingExercise(input: input, adminId: admin.id),
        throwsA(predicate((e) => e.toString().contains('Invalid icon name'))),
      );
    });

    test('Pattern duration consistency validation works correctly', () async {
      // Valid pattern with sufficient duration
      expect(mockValidatePatternConsistency({'inhale': 4, 'hold': 4, 'exhale': 4}, 60), true);
      
      // Invalid pattern with zero cycle time
      expect(mockValidatePatternConsistency({}, 60), false);
      
      // Pattern with duration that allows multiple cycles
      expect(mockValidatePatternConsistency({'inhale': 2, 'hold': 2, 'exhale': 2}, 30), true);
    });
  });
}
