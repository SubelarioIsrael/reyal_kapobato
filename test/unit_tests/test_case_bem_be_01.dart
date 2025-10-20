// BEM-BE-01: Student can view and select a breathing exercise
// Requirement: Students can access and choose from available breathing exercises

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
  final bool isActive;
  
  MockBreathingExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.pattern,
    required this.colorHex,
    required this.iconName,
    this.isActive = true,
  });
}

// Mock database
List<MockBreathingExercise> _exerciseDatabase = [
  MockBreathingExercise(
    id: 'ex1',
    name: 'Box Breathing',
    description: 'A simple 4-4-4-4 breathing pattern that helps reduce stress and anxiety',
    duration: 240,
    pattern: {'inhale': 4, 'hold': 4, 'exhale': 4, 'hold2': 4},
    colorHex: '#7C83FD',
    iconName: 'square_outlined',
  ),
  MockBreathingExercise(
    id: 'ex2',
    name: '4-7-8 Breathing',
    description: 'Inhale for 4, hold for 7, exhale for 8. Great for falling asleep',
    duration: 300,
    pattern: {'inhale': 4, 'hold': 7, 'exhale': 8},
    colorHex: '#FF6B6B',
    iconName: 'air',
  ),
  MockBreathingExercise(
    id: 'ex3',
    name: 'Deep Breathing',
    description: 'Simple deep breathing exercise for relaxation',
    duration: 180,
    pattern: {'inhale': 6, 'hold': 2, 'exhale': 6},
    colorHex: '#4ECDC4',
    iconName: 'waves',
    isActive: false, // Inactive exercise
  ),
];

Future<MockUser> mockAuthenticateStudent() async {
  return MockUser(email: 'student@college.edu', id: 'student-123', userType: 'student');
}

Future<List<MockBreathingExercise>> mockLoadBreathingExercises() async {
  // Return only active exercises for students, sorted alphabetically by normalized name
  return _exerciseDatabase
      .where((exercise) => exercise.isActive)
      .toList()
    ..sort((a, b) {
      // Normalize names by replacing en/em dashes with ASCII hyphens and trimming spaces
      final nameA = a.name
          .replaceAll(RegExp(r'[–—]'), '-') // replace en/em dash
          .trim()
          .toLowerCase();
      final nameB = b.name
          .replaceAll(RegExp(r'[–—]'), '-')
          .trim()
          .toLowerCase();
      return nameA.compareTo(nameB);
    });
}


Future<MockBreathingExercise?> mockSelectBreathingExercise({required String exerciseId}) async {
  try {
    return _exerciseDatabase.firstWhere(
      (exercise) => exercise.id == exerciseId && exercise.isActive,
    );
  } catch (e) {
    return null;
  }
}

String mockFormatPattern(Map<String, dynamic> pattern) {
  final parts = <String>[];
  if (pattern.containsKey('inhale')) {
    parts.add('Inhale: ${pattern['inhale']}s');
  }
  if (pattern.containsKey('hold')) {
    parts.add('Hold: ${pattern['hold']}s');
  }
  if (pattern.containsKey('exhale')) {
    parts.add('Exhale: ${pattern['exhale']}s');
  }
  if (pattern.containsKey('hold2')) {
    parts.add('Hold: ${pattern['hold2']}s');
  }
  return parts.join(' → ');
}

void main() {
  group('BEM-BE-01: Student can view and select a breathing exercise', () {
    test('Student successfully loads all active breathing exercises', () async {
      final user = await mockAuthenticateStudent();
      expect(user.userType, 'student');
      
      final exercises = await mockLoadBreathingExercises();
      
      expect(exercises.length, 2); // Only active exercises
      expect(exercises[0].name, '4-7-8 Breathing');
      expect(exercises[1].name, 'Box Breathing');
      expect(exercises.every((exercise) => exercise.isActive), true);
    });


    test('Student can view exercise details with proper formatting', () async {
      await mockAuthenticateStudent();

      final exercises = await mockLoadBreathingExercises();
      // Explicitly find Box Breathing instead of relying on list order
      final boxBreathing = exercises.firstWhere((ex) => ex.name == 'Box Breathing');

      expect(boxBreathing.name, 'Box Breathing');
      expect(boxBreathing.description, contains('4-4-4-4 breathing pattern'));
      expect(boxBreathing.duration, 240);
      expect(boxBreathing.pattern['inhale'], 4);
      expect(boxBreathing.pattern['hold'], 4);
      expect(boxBreathing.pattern['exhale'], 4);
      expect(boxBreathing.pattern['hold2'], 4);

      final formattedPattern = mockFormatPattern(boxBreathing.pattern);
      expect(formattedPattern, 'Inhale: 4s → Hold: 4s → Exhale: 4s → Hold: 4s');
    });


    test('Student successfully selects a specific breathing exercise', () async {
      await mockAuthenticateStudent();
      
      final selectedExercise = await mockSelectBreathingExercise(exerciseId: 'ex1');
      
      expect(selectedExercise, isNotNull);
      expect(selectedExercise!.name, 'Box Breathing');
      expect(selectedExercise.id, 'ex1');
      expect(selectedExercise.isActive, true);
    });

    test('Student cannot select inactive breathing exercise', () async {
      await mockAuthenticateStudent();
      
      final selectedExercise = await mockSelectBreathingExercise(exerciseId: 'ex3');
      
      expect(selectedExercise, isNull);
    });

    test('Student cannot select non-existent breathing exercise', () async {
      await mockAuthenticateStudent();
      
      final selectedExercise = await mockSelectBreathingExercise(exerciseId: 'nonexistent');
      
      expect(selectedExercise, isNull);
    });

    test('Different exercise patterns are formatted correctly', () async {
      await mockAuthenticateStudent();
      
      final exercises = await mockLoadBreathingExercises();
      final breathing478 = exercises.firstWhere((ex) => ex.name == '4-7-8 Breathing');
      
      final formattedPattern = mockFormatPattern(breathing478.pattern);
      expect(formattedPattern, 'Inhale: 4s → Hold: 7s → Exhale: 8s');
      expect(breathing478.pattern.containsKey('hold2'), false);
    });

    test('Exercises are sorted by name', () async {
      await mockAuthenticateStudent();
      
      final exercises = await mockLoadBreathingExercises();
      
      expect(exercises[0].name, '4-7-8 Breathing');
      expect(exercises[1].name, 'Box Breathing');
    });
  });
}
