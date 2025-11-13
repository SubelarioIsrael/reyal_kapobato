import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result class for loading exercises
class LoadExercisesResult {
  final bool success;
  final List<Map<String, dynamic>> exercises;
  final String? errorMessage;

  LoadExercisesResult({
    required this.success,
    this.exercises = const [],
    this.errorMessage,
  });
}

/// Result class for creating an exercise
class CreateExerciseResult {
  final bool success;
  final String? errorMessage;
  final int? exerciseId;

  CreateExerciseResult({
    required this.success,
    this.errorMessage,
    this.exerciseId,
  });
}

/// Result class for updating an exercise
class UpdateExerciseResult {
  final bool success;
  final String? errorMessage;

  UpdateExerciseResult({
    required this.success,
    this.errorMessage,
  });
}

/// Result class for deleting an exercise
class DeleteExerciseResult {
  final bool success;
  final String? errorMessage;

  DeleteExerciseResult({
    required this.success,
    this.errorMessage,
  });
}

/// Admin Breathing Exercises Controller - Handles breathing exercise management
class AdminBreathingExercisesController {
  final _supabase = Supabase.instance.client;

  /// Load all breathing exercises
  Future<LoadExercisesResult> loadExercises() async {
    try {
      final response = await _supabase
          .from('breathing_exercises')
          .select()
          .order('name');

      final exercises = (response as List).map((exercise) {
        final exerciseMap = exercise as Map<String, dynamic>;
        return {
          ...exerciseMap,
          'color': _getColorFromHex(exerciseMap['color_hex']),
          'icon': _getIconFromName(exerciseMap['icon_name']),
        };
      }).toList();

      return LoadExercisesResult(
        success: true,
        exercises: exercises,
      );
    } catch (e) {
      print('Error loading exercises: $e');
      return LoadExercisesResult(
        success: false,
        errorMessage: 'Failed to load exercises: ${e.toString()}',
      );
    }
  }

  /// Create a new breathing exercise
  Future<CreateExerciseResult> createExercise({
    required String name,
    required String description,
    required int duration,
    required Map<String, dynamic> pattern,
    required String colorHex,
    required String iconName,
  }) async {
    try {
      final response = await _supabase
          .from('breathing_exercises')
          .insert({
            'name': name.trim(),
            'description': description.trim(),
            'duration': duration,
            'pattern': pattern,
            'color_hex': colorHex,
            'icon_name': iconName,
          })
          .select('id')
          .single();

      return CreateExerciseResult(
        success: true,
        exerciseId: response['id'] as int?,
      );
    } catch (e) {
      print('Error creating exercise: $e');
      return CreateExerciseResult(
        success: false,
        errorMessage: 'Failed to create exercise: ${e.toString()}',
      );
    }
  }

  /// Update an existing breathing exercise
  Future<UpdateExerciseResult> updateExercise({
    required int exerciseId,
    required String name,
    required String description,
    required int duration,
    required Map<String, dynamic> pattern,
    required String colorHex,
    required String iconName,
  }) async {
    try {
      await _supabase
          .from('breathing_exercises')
          .update({
            'name': name.trim(),
            'description': description.trim(),
            'duration': duration,
            'pattern': pattern,
            'color_hex': colorHex,
            'icon_name': iconName,
          })
          .eq('id', exerciseId);

      return UpdateExerciseResult(success: true);
    } catch (e) {
      print('Error updating exercise: $e');
      return UpdateExerciseResult(
        success: false,
        errorMessage: 'Failed to update exercise: ${e.toString()}',
      );
    }
  }

  /// Delete a breathing exercise
  Future<DeleteExerciseResult> deleteExercise(int exerciseId) async {
    try {
      await _supabase
          .from('breathing_exercises')
          .delete()
          .eq('id', exerciseId);

      return DeleteExerciseResult(success: true);
    } catch (e) {
      print('Error deleting exercise: $e');
      return DeleteExerciseResult(
        success: false,
        errorMessage: 'Failed to delete exercise: ${e.toString()}',
      );
    }
  }

  /// Validate exercise name
  String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Please enter a name';
    }
    return null;
  }

  /// Validate description
  String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'Please enter a description';
    }
    return null;
  }

  /// Validate duration
  String? validateDuration(String? duration) {
    if (duration == null || duration.trim().isEmpty) {
      return 'Please enter duration';
    }
    if (int.tryParse(duration.trim()) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  /// Validate pattern number (inhale, hold, exhale, etc.)
  String? validatePatternNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    if (int.tryParse(value.trim()) == null) {
      return 'Invalid';
    }
    return null;
  }

  /// Validate optional pattern number (for second hold)
  String? validateOptionalPatternNumber(String? value, bool isRequired) {
    if (!isRequired) return null;
    return validatePatternNumber(value);
  }

  /// Helper method to get Color from hex string
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  /// Helper method to get IconData from icon name
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'air':
        return Icons.air;
      case 'square_outlined':
        return Icons.square_outlined;
      case 'waves':
        return Icons.waves;
      default:
        return Icons.self_improvement;
    }
  }

  /// Helper method to format breathing pattern for display
  String formatPattern(Map<String, dynamic> pattern) {
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
}
