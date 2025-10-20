// BEM-BE-05: Admin can edit a breathing exercise
// Requirement: Admin can modify existing breathing exercises while maintaining data integrity

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

class MockExerciseUpdateInput {
  final String name;
  final String description;
  final int duration;
  final Map<String, dynamic> pattern;
  final String colorHex;
  final String iconName;
  
  MockExerciseUpdateInput({
    required this.name,
    required this.description,
    required this.duration,
    required this.pattern,
    required this.colorHex,
    required this.iconName,
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

Future<MockBreathingExercise> mockUpdateBreathingExercise({
  required String exerciseId,
  required MockExerciseUpdateInput input,
  required String adminId,
}) async {
  // Find existing exercise
  final existingIndex = _exerciseDatabase.indexWhere((ex) => ex.id == exerciseId);
  if (existingIndex == -1) {
    throw Exception('Exercise not found');
  }
  
  final existing = _exerciseDatabase[existingIndex];
  
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
  
  // Check for duplicate names (excluding current exercise)
  final duplicateExists = _exerciseDatabase.any(
    (exercise) => exercise.id != exerciseId && 
                  exercise.name.toLowerCase() == input.name.toLowerCase().trim()
  );
  
  if (duplicateExists) {
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
  
  final updatedExercise = MockBreathingExercise(
    id: existing.id,
    name: input.name.trim(),
    description: input.description.trim(),
    duration: input.duration,
    pattern: Map<String, dynamic>.from(input.pattern),
    colorHex: input.colorHex,
    iconName: input.iconName,
    createdAt: existing.createdAt,
    updatedAt: DateTime.now(),
  );
  
  _exerciseDatabase[existingIndex] = updatedExercise;
  return updatedExercise;
}

Map<String, dynamic> mockDetectChanges({
  required MockBreathingExercise original,
  required MockExerciseUpdateInput updated,
}) {
  final changes = <String, dynamic>{};
  
  if (original.name != updated.name.trim()) {
    changes['name'] = {'from': original.name, 'to': updated.name.trim()};
  }
  if (original.description != updated.description.trim()) {
    changes['description'] = {'from': original.description, 'to': updated.description.trim()};
  }
  if (original.duration != updated.duration) {
    changes['duration'] = {'from': original.duration, 'to': updated.duration};
  }
  if (original.colorHex != updated.colorHex) {
    changes['colorHex'] = {'from': original.colorHex, 'to': updated.colorHex};
  }
  if (original.iconName != updated.iconName) {
    changes['iconName'] = {'from': original.iconName, 'to': updated.iconName};
  }
  
  // Check pattern changes with proper map comparison
  bool patternsEqual = true;
  if (original.pattern.length != updated.pattern.length) {
    patternsEqual = false;
  } else {
    for (final entry in original.pattern.entries) {
      if (!updated.pattern.containsKey(entry.key) || 
          updated.pattern[entry.key] != entry.value) {
        patternsEqual = false;
        break;
      }
    }
  }
  
  if (!patternsEqual) {
    changes['pattern'] = {'from': original.pattern, 'to': updated.pattern};
  }
  
  return changes;
}

void main() {
  group('BEM-BE-05: Admin can edit a breathing exercise', () {
    setUp(() {
      // Reset database state before each test
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
      ];
    });

    test('Admin successfully updates exercise name and description', () async {
      final admin = await mockAuthenticateAdmin();
      
      final updateInput = MockExerciseUpdateInput(
        name: 'Advanced Box Breathing',
        description: 'An enhanced 4-4-4-4 breathing pattern with detailed instructions',
        duration: 240,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4, 'hold2': 4},
        colorHex: '#7C83FD',
        iconName: 'square_outlined',
      );
      
      final original = await mockGetBreathingExercise(exerciseId: 'ex1');
      expect(original, isNotNull);
      
      final updated = await mockUpdateBreathingExercise(
        exerciseId: 'ex1',
        input: updateInput,
        adminId: admin.id,
      );
      
      expect(updated.id, 'ex1');
      expect(updated.name, 'Advanced Box Breathing');
      expect(updated.description, 'An enhanced 4-4-4-4 breathing pattern with detailed instructions');
      expect(updated.createdAt, original!.createdAt); // Should remain unchanged
      expect(updated.updatedAt.isAfter(original.updatedAt), true);
    });

    test('Admin successfully modifies breathing pattern', () async {
      final admin = await mockAuthenticateAdmin();
      
      final updateInput = MockExerciseUpdateInput(
        name: 'Box Breathing',
        description: 'A simple 4-4-4-4 breathing pattern',
        duration: 300,
        pattern: {'inhale': 5, 'hold': 5, 'exhale': 5, 'hold2': 5}, // Changed pattern
        colorHex: '#7C83FD',
        iconName: 'square_outlined',
      );
      
      final updated = await mockUpdateBreathingExercise(
        exerciseId: 'ex1',
        input: updateInput,
        adminId: admin.id,
      );
      
      expect(updated.pattern['inhale'], 5);
      expect(updated.pattern['hold'], 5);
      expect(updated.pattern['exhale'], 5);
      expect(updated.pattern['hold2'], 5);
      expect(updated.duration, 300);
    });

    test('Admin successfully changes exercise appearance', () async {
      final admin = await mockAuthenticateAdmin();
      
      final updateInput = MockExerciseUpdateInput(
        name: 'Box Breathing',
        description: 'A simple 4-4-4-4 breathing pattern',
        duration: 240,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4, 'hold2': 4},
        colorHex: '#FF9500', // Changed color
        iconName: 'waves', // Changed icon
      );
      
      final updated = await mockUpdateBreathingExercise(
        exerciseId: 'ex1',
        input: updateInput,
        adminId: admin.id,
      );
      
      expect(updated.colorHex, '#FF9500');
      expect(updated.iconName, 'waves');
    });

    test('Admin successfully converts 4-phase to 3-phase pattern', () async {
      final admin = await mockAuthenticateAdmin();
      
      final updateInput = MockExerciseUpdateInput(
        name: 'Box Breathing',
        description: 'A simple 4-4-4-4 breathing pattern',
        duration: 240,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4}, // Removed hold2
        colorHex: '#7C83FD',
        iconName: 'square_outlined',
      );
      
      final updated = await mockUpdateBreathingExercise(
        exerciseId: 'ex1',
        input: updateInput,
        adminId: admin.id,
      );
      
      expect(updated.pattern.containsKey('hold2'), false);
      expect(updated.pattern.keys.length, 3);
    });

    test('Change detection correctly identifies modifications', () async {
      final original = await mockGetBreathingExercise(exerciseId: 'ex1');
      
      final updateInput = MockExerciseUpdateInput(
        name: 'Modified Box Breathing',
        description: 'A simple 4-4-4-4 breathing pattern',
        duration: 300,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4, 'hold2': 4},
        colorHex: '#FF6B6B',
        iconName: 'square_outlined',
      );
      
      final changes = mockDetectChanges(original: original!, updated: updateInput);
      
      expect(changes.containsKey('name'), true);
      expect(changes.containsKey('duration'), true);
      expect(changes.containsKey('colorHex'), true);
      expect(changes.containsKey('description'), false); // No change
      expect(changes.containsKey('pattern'), false); // No change
      
      expect(changes['name']['from'], 'Box Breathing');
      expect(changes['name']['to'], 'Modified Box Breathing');
      expect(changes['duration']['from'], 240);
      expect(changes['duration']['to'], 300);
    });

    test('Updating with empty name fails validation', () async {
      final admin = await mockAuthenticateAdmin();
      
      final updateInput = MockExerciseUpdateInput(
        name: '',
        description: 'Valid description',
        duration: 240,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4},
        colorHex: '#7C83FD',
        iconName: 'air',
      );
      
      expect(
        () => mockUpdateBreathingExercise(
          exerciseId: 'ex1',
          input: updateInput,
          adminId: admin.id,
        ),
        throwsA(predicate((e) => e.toString().contains('Exercise name is required'))),
      );
    });

    test('Updating with duplicate name fails validation', () async {
      final admin = await mockAuthenticateAdmin();
      
      final updateInput = MockExerciseUpdateInput(
        name: '4-7-8 Breathing', // Name of ex2
        description: 'Valid description',
        duration: 240,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4},
        colorHex: '#7C83FD',
        iconName: 'air',
      );
      
      expect(
        () => mockUpdateBreathingExercise(
          exerciseId: 'ex1',
          input: updateInput,
          adminId: admin.id,
        ),
        throwsA(predicate((e) => e.toString().contains('Exercise with this name already exists'))),
      );
    });

    test('Updating non-existent exercise fails', () async {
      final admin = await mockAuthenticateAdmin();
      
      final updateInput = MockExerciseUpdateInput(
        name: 'Valid Name',
        description: 'Valid description',
        duration: 240,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4},
        colorHex: '#7C83FD',
        iconName: 'air',
      );
      
      expect(
        () => mockUpdateBreathingExercise(
          exerciseId: 'nonexistent',
          input: updateInput,
          adminId: admin.id,
        ),
        throwsA(predicate((e) => e.toString().contains('Exercise not found'))),
      );
    });

    test('Updating with invalid pattern fails validation', () async {
      final admin = await mockAuthenticateAdmin();
      
      final updateInput = MockExerciseUpdateInput(
        name: 'Valid Name',
        description: 'Valid description',
        duration: 240,
        pattern: {'inhale': 4, 'hold': -2, 'exhale': 4}, // Invalid negative value
        colorHex: '#7C83FD',
        iconName: 'air',
      );
      
      expect(
        () => mockUpdateBreathingExercise(
          exerciseId: 'ex1',
          input: updateInput,
          adminId: admin.id,
        ),
        throwsA(predicate((e) => e.toString().contains('Pattern values must be positive integers'))),
      );
    });

    test('Exercise can be updated with same name (no conflict with itself)', () async {
      final admin = await mockAuthenticateAdmin();
      
      final updateInput = MockExerciseUpdateInput(
        name: 'Box Breathing', // Same name as current
        description: 'Updated description',
        duration: 300,
        pattern: {'inhale': 4, 'hold': 4, 'exhale': 4},
        colorHex: '#7C83FD',
        iconName: 'air',
      );
      
      final updated = await mockUpdateBreathingExercise(
        exerciseId: 'ex1',
        input: updateInput,
        adminId: admin.id,
      );
      
      expect(updated.name, 'Box Breathing');
      expect(updated.description, 'Updated description');
    });
  });
}
