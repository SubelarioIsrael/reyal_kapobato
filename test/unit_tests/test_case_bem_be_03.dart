// BEM-BE-03: Admin can view all breathing exercises
// Requirement: Admin can see complete list of breathing exercises including active and inactive ones

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
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
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
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  MockBreathingExercise(
    id: 'ex2',
    name: '4-7-8 Breathing',
    description: 'Inhale for 4, hold for 7, exhale for 8. Great for falling asleep',
    duration: 300,
    pattern: {'inhale': 4, 'hold': 7, 'exhale': 8},
    colorHex: '#FF6B6B',
    iconName: 'air',
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
    updatedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  MockBreathingExercise(
    id: 'ex3',
    name: 'Deep Breathing',
    description: 'Simple deep breathing exercise for relaxation',
    duration: 180,
    pattern: {'inhale': 6, 'hold': 2, 'exhale': 6},
    colorHex: '#4ECDC4',
    iconName: 'waves',
    isActive: false,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  MockBreathingExercise(
    id: 'ex4',
    name: 'Alternate Nostril',
    description: 'Traditional yoga breathing technique for balance',
    duration: 420,
    pattern: {'inhale': 5, 'hold': 3, 'exhale': 5},
    colorHex: '#9B59B6',
    iconName: 'self_improvement',
    isActive: false,
    createdAt: DateTime.now().subtract(const Duration(days: 15)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

Future<MockUser> mockAuthenticateAdmin() async {
  return MockUser(email: 'admin@college.edu', id: 'admin-123', userType: 'admin');
}

Future<List<MockBreathingExercise>> mockLoadAllBreathingExercises({
  String? searchQuery,
  String sortBy = 'name',
  bool ascending = true,
}) async {
  var exercises = List<MockBreathingExercise>.from(_exerciseDatabase);
  
  // Apply search filter if provided
  if (searchQuery != null && searchQuery.isNotEmpty) {
    exercises = exercises.where((exercise) =>
      exercise.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
      exercise.description.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }
  
  // Apply sorting
  exercises.sort((a, b) {
    int comparison;
    switch (sortBy) {
      case 'name':
        comparison = a.name.compareTo(b.name);
        break;
      case 'duration':
        comparison = a.duration.compareTo(b.duration);
        break;
      case 'created':
        comparison = a.createdAt.compareTo(b.createdAt);
        break;
      case 'updated':
        comparison = a.updatedAt.compareTo(b.updatedAt);
        break;
      default:
        comparison = a.name.compareTo(b.name);
    }
    return ascending ? comparison : -comparison;
  });
  
  return exercises;
}

List<MockBreathingExercise> mockFilterExercisesByStatus(List<MockBreathingExercise> exercises, {bool? isActive}) {
  if (isActive == null) return exercises;
  return exercises.where((exercise) => exercise.isActive == isActive).toList();
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
  group('BEM-BE-03: Admin can view all breathing exercises', () {
    test('Admin successfully loads all breathing exercises including inactive ones', () async {
      final admin = await mockAuthenticateAdmin();
      expect(admin.userType, 'admin');
      
      final exercises = await mockLoadAllBreathingExercises();
      
      expect(exercises.length, 4);
      
      final activeCount = exercises.where((ex) => ex.isActive).length;
      final inactiveCount = exercises.where((ex) => !ex.isActive).length;
      
      expect(activeCount, 2);
      expect(inactiveCount, 2);
    });

    test('Admin can view exercise details with complete information', () async {
      await mockAuthenticateAdmin();
      
      final exercises = await mockLoadAllBreathingExercises();
      final boxBreathing = exercises.firstWhere((ex) => ex.name == 'Box Breathing');
      
      expect(boxBreathing.name, 'Box Breathing');
      expect(boxBreathing.description, contains('4-4-4-4 breathing pattern'));
      expect(boxBreathing.duration, 240);
      expect(boxBreathing.colorHex, '#7C83FD');
      expect(boxBreathing.iconName, 'square_outlined');
      expect(boxBreathing.isActive, true);
      expect(boxBreathing.createdAt, isA<DateTime>());
      expect(boxBreathing.updatedAt, isA<DateTime>());
      
      final formattedPattern = mockFormatPattern(boxBreathing.pattern);
      expect(formattedPattern, 'Inhale: 4s → Hold: 4s → Exhale: 4s → Hold: 4s');
    });

    test('Admin can search exercises by name', () async {
      await mockAuthenticateAdmin();
      
      final exercises = await mockLoadAllBreathingExercises(searchQuery: 'box');
      
      expect(exercises.length, 1);
      expect(exercises.first.name, 'Box Breathing');
    });

    test('Admin can search exercises by description', () async {
      await mockAuthenticateAdmin();
      
      final exercises = await mockLoadAllBreathingExercises(searchQuery: 'sleep');
      
      expect(exercises.length, 1);
      expect(exercises.first.name, '4-7-8 Breathing');
      expect(exercises.first.description, contains('falling asleep'));
    });

    test('Admin can sort exercises by name (ascending)', () async {
      await mockAuthenticateAdmin();
      
      final exercises = await mockLoadAllBreathingExercises(sortBy: 'name', ascending: true);
      
      expect(exercises[0].name, '4-7-8 Breathing');
      expect(exercises[1].name, 'Alternate Nostril');
      expect(exercises[2].name, 'Box Breathing');
      expect(exercises[3].name, 'Deep Breathing');
    });

    test('Admin can sort exercises by duration (descending)', () async {
      await mockAuthenticateAdmin();
      
      final exercises = await mockLoadAllBreathingExercises(sortBy: 'duration', ascending: false);
      
      expect(exercises[0].duration, 420); // Alternate Nostril
      expect(exercises[1].duration, 300); // 4-7-8 Breathing
      expect(exercises[2].duration, 240); // Box Breathing
      expect(exercises[3].duration, 180); // Deep Breathing
    });

    test('Admin can filter exercises by active status', () async {
      await mockAuthenticateAdmin();
      
      final allExercises = await mockLoadAllBreathingExercises();
      
      final activeExercises = mockFilterExercisesByStatus(allExercises, isActive: true);
      expect(activeExercises.length, 2);
      expect(activeExercises.every((ex) => ex.isActive), true);
      
      final inactiveExercises = mockFilterExercisesByStatus(allExercises, isActive: false);
      expect(inactiveExercises.length, 2);
      expect(inactiveExercises.every((ex) => !ex.isActive), true);
    });

    test('Admin can view exercises with different pattern types', () async {
      await mockAuthenticateAdmin();
      
      final exercises = await mockLoadAllBreathingExercises();
      
      // Box breathing with 4 phases
      final boxBreathing = exercises.firstWhere((ex) => ex.name == 'Box Breathing');
      expect(boxBreathing.pattern.keys.length, 4);
      expect(boxBreathing.pattern.containsKey('hold2'), true);
      
      // 4-7-8 breathing with 3 phases
      final breathing478 = exercises.firstWhere((ex) => ex.name == '4-7-8 Breathing');
      expect(breathing478.pattern.keys.length, 3);
      expect(breathing478.pattern.containsKey('hold2'), false);
    });

    test('Search returns empty list for non-matching query', () async {
      await mockAuthenticateAdmin();
      
      final exercises = await mockLoadAllBreathingExercises(searchQuery: 'nonexistent');
      
      expect(exercises.isEmpty, true);
    });

    test('Admin can view creation and update timestamps', () async {
      await mockAuthenticateAdmin();
      
      final exercises = await mockLoadAllBreathingExercises(sortBy: 'updated', ascending: false);
      
      // Most recently updated should be first
      expect(exercises.first.updatedAt.isAfter(exercises.last.updatedAt), true);
      
      // Verify all exercises have timestamps
      for (final exercise in exercises) {
        expect(exercise.createdAt, isA<DateTime>());
        expect(exercise.updatedAt, isA<DateTime>());
        expect(exercise.updatedAt.isAfter(exercise.createdAt) || 
               exercise.updatedAt.isAtSameMomentAs(exercise.createdAt), true);
      }
    });
  });
}
