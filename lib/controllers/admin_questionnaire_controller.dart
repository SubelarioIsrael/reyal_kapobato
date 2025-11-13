import 'package:supabase_flutter/supabase_flutter.dart';

/// Result class for loading versions
class LoadVersionsResult {
  final bool success;
  final List<Map<String, dynamic>> versions;
  final int? activeVersionId;
  final String? errorMessage;

  LoadVersionsResult({
    required this.success,
    this.versions = const [],
    this.activeVersionId,
    this.errorMessage,
  });
}

/// Result class for loading questions
class LoadQuestionsResult {
  final bool success;
  final List<Map<String, dynamic>> questions;
  final String? errorMessage;

  LoadQuestionsResult({
    required this.success,
    this.questions = const [],
    this.errorMessage,
  });
}

/// Result class for creating a version
class CreateVersionResult {
  final bool success;
  final String? errorMessage;
  final String? errorType;
  final int? versionId;

  CreateVersionResult({
    required this.success,
    this.errorMessage,
    this.errorType,
    this.versionId,
  });
}

/// Result class for creating a question
class CreateQuestionResult {
  final bool success;
  final String? errorMessage;
  final int? questionId;

  CreateQuestionResult({
    required this.success,
    this.errorMessage,
    this.questionId,
  });
}

/// Result class for updating a question
class UpdateQuestionResult {
  final bool success;
  final String? errorMessage;

  UpdateQuestionResult({
    required this.success,
    this.errorMessage,
  });
}

/// Result class for deleting a question
class DeleteQuestionResult {
  final bool success;
  final String? errorMessage;

  DeleteQuestionResult({
    required this.success,
    this.errorMessage,
  });
}

/// Result class for toggling version status
class ToggleVersionStatusResult {
  final bool success;
  final String? errorMessage;
  final String? errorType;

  ToggleVersionStatusResult({
    required this.success,
    this.errorMessage,
    this.errorType,
  });
}

/// Result class for deleting a version
class DeleteVersionResult {
  final bool success;
  final String? errorMessage;
  final String? errorType;

  DeleteVersionResult({
    required this.success,
    this.errorMessage,
    this.errorType,
  });
}

/// Admin Questionnaire Controller - Handles questionnaire management
class AdminQuestionnaireController {
  final _supabase = Supabase.instance.client;

  /// Load all questionnaire versions
  Future<LoadVersionsResult> loadVersions() async {
    try {
      final versionsResponse = await _supabase
          .from('questionnaire_versions')
          .select()
          .order('created_at', ascending: false);

      final versions = List<Map<String, dynamic>>.from(versionsResponse);
      
      // Find active version
      int? activeVersionId;
      if (versions.isNotEmpty) {
        final activeVersion = versions.firstWhere(
          (v) => v['is_active'] == true,
          orElse: () => versions[0],
        );
        activeVersionId = activeVersion['version_id'] as int;
      }

      return LoadVersionsResult(
        success: true,
        versions: versions,
        activeVersionId: activeVersionId,
      );
    } catch (e) {
      print('Error loading versions: $e');
      return LoadVersionsResult(
        success: false,
        errorMessage: 'Failed to load questionnaire versions: ${e.toString()}',
      );
    }
  }

  /// Load questions for a specific version
  Future<LoadQuestionsResult> loadQuestions(int versionId) async {
    try {
      final response = await _supabase
          .from('questionnaire_questions')
          .select('''
            question_id,
            question_order,
            questions:question_id (
              question_id,
              question_text,
              category,
              is_active,
              created_at
            )
          ''')
          .eq('version_id', versionId)
          .order('question_order');

      final questions = List<Map<String, dynamic>>.from(response)
          .map((q) => q['questions'] as Map<String, dynamic>)
          .toList();

      return LoadQuestionsResult(
        success: true,
        questions: questions,
      );
    } catch (e) {
      print('Error loading questions: $e');
      return LoadQuestionsResult(
        success: false,
        errorMessage: 'Failed to load questions: ${e.toString()}',
      );
    }
  }

  /// Create a new questionnaire version
  Future<CreateVersionResult> createVersion({
    required String versionName,
    required List<Map<String, dynamic>> existingVersions,
  }) async {
    try {
      // Check for duplicate version name
      final trimmedVersionName = versionName.trim();
      final duplicateVersion = existingVersions.firstWhere(
        (v) => (v['version_name'] as String).toLowerCase() == 
               trimmedVersionName.toLowerCase(),
        orElse: () => {},
      );

      if (duplicateVersion.isNotEmpty) {
        return CreateVersionResult(
          success: false,
          errorMessage: 'A version with this name already exists',
          errorType: 'duplicate',
        );
      }

      // Deactivate all existing versions first
      await _supabase
          .from('questionnaire_versions')
          .update({'is_active': false})
          .neq('version_id', 0); // Update all versions

      // Create new version and set it as active
      final versionResponse = await _supabase
          .from('questionnaire_versions')
          .insert({
            'version_name': trimmedVersionName,
            'is_active': true,
          })
          .select()
          .single();

      final newVersionId = versionResponse['version_id'] as int;

      // DO NOT copy questions - new version starts empty

      return CreateVersionResult(
        success: true,
        versionId: newVersionId,
      );
    } catch (e) {
      print('Error creating version: $e');
      return CreateVersionResult(
        success: false,
        errorMessage: 'Failed to create new version: ${e.toString()}',
      );
    }
  }

  /// Create a new question
  Future<CreateQuestionResult> createQuestion({
    required String questionText,
    required String category,
    required int versionId,
    required int questionOrder,
  }) async {
    try {
      // Insert question
      final questionResponse = await _supabase
          .from('questions')
          .insert({
            'question_text': questionText.trim(),
            'category': category,
            'is_active': true,
          })
          .select()
          .single();

      // Link question to version
      await _supabase
          .from('questionnaire_questions')
          .insert({
        'version_id': versionId,
        'question_id': questionResponse['question_id'],
        'question_order': questionOrder,
      });

      return CreateQuestionResult(
        success: true,
        questionId: questionResponse['question_id'] as int,
      );
    } catch (e) {
      print('Error creating question: $e');
      return CreateQuestionResult(
        success: false,
        errorMessage: 'Failed to add question: ${e.toString()}',
      );
    }
  }

  /// Update an existing question
  Future<UpdateQuestionResult> updateQuestion({
    required int questionId,
    required String questionText,
  }) async {
    try {
      await _supabase
          .from('questions')
          .update({
            'question_text': questionText.trim(),
          })
          .eq('question_id', questionId);

      return UpdateQuestionResult(success: true);
    } catch (e) {
      print('Error updating question: $e');
      return UpdateQuestionResult(
        success: false,
        errorMessage: 'Failed to update question: ${e.toString()}',
      );
    }
  }

  /// Delete a question from a specific version
  Future<DeleteQuestionResult> deleteQuestion(int questionId, int versionId) async {
    try {
      // Delete from questionnaire_questions for this specific version
      await _supabase
          .from('questionnaire_questions')
          .delete()
          .eq('question_id', questionId)
          .eq('version_id', versionId);

      // Check if this question is used in other versions
      final otherVersions = await _supabase
          .from('questionnaire_questions')
          .select()
          .eq('question_id', questionId);

      // Only delete from questions table if not used in any other version
      if (otherVersions.isEmpty) {
        await _supabase
            .from('questions')
            .delete()
            .eq('question_id', questionId);
      }

      return DeleteQuestionResult(success: true);
    } catch (e) {
      print('Error deleting question: $e');
      return DeleteQuestionResult(
        success: false,
        errorMessage: 'Failed to delete question: ${e.toString()}',
      );
    }
  }

  /// Toggle version status (activate/deactivate)
  Future<ToggleVersionStatusResult> toggleVersionStatus(
    int versionId,
    bool currentStatus,
    List<Map<String, dynamic>> allVersions,
  ) async {
    try {
      // If trying to deactivate, check if there are other active versions
      if (currentStatus) {
        final activeVersions = allVersions.where((v) => v['is_active'] == true).toList();
        
        // If this is the only active version, prevent deactivation
        if (activeVersions.length <= 1) {
          return ToggleVersionStatusResult(
            success: false,
            errorMessage: 'This is the only active version. At least one version must remain active.',
            errorType: 'last_active',
          );
        }
      }

      // If activating, deactivate all other versions first (only one can be active)
      if (!currentStatus) {
        await _supabase
            .from('questionnaire_versions')
            .update({'is_active': false})
            .neq('version_id', versionId);
      }

      // Toggle the selected version's status
      await _supabase
          .from('questionnaire_versions')
          .update({'is_active': !currentStatus})
          .eq('version_id', versionId);

      return ToggleVersionStatusResult(success: true);
    } catch (e) {
      print('Error toggling version status: $e');
      return ToggleVersionStatusResult(
        success: false,
        errorMessage: 'Failed to update version status: ${e.toString()}',
      );
    }
  }

  /// Delete a version
  Future<DeleteVersionResult> deleteVersion(
    int versionId,
    List<Map<String, dynamic>> allVersions,
  ) async {
    try {
      // Check if this is the only version
      if (allVersions.length <= 1) {
        return DeleteVersionResult(
          success: false,
          errorMessage: 'Cannot delete the only version. At least one version must exist.',
          errorType: 'last_version',
        );
      }

      // Check if this is the active version
      final versionToDelete = allVersions.firstWhere(
        (v) => v['version_id'] == versionId,
        orElse: () => {},
      );

      if (versionToDelete.isNotEmpty && versionToDelete['is_active'] == true) {
        return DeleteVersionResult(
          success: false,
          errorMessage: 'Cannot delete the active version. Please activate another version first.',
          errorType: 'active_version',
        );
      }

      // Delete all question associations for this version
      await _supabase
          .from('questionnaire_questions')
          .delete()
          .eq('version_id', versionId);

      // Delete the version itself
      await _supabase
          .from('questionnaire_versions')
          .delete()
          .eq('version_id', versionId);

      return DeleteVersionResult(success: true);
    } catch (e) {
      print('Error deleting version: $e');
      return DeleteVersionResult(
        success: false,
        errorMessage: 'Failed to delete version: ${e.toString()}',
      );
    }
  }

  /// Validate question text
  String? validateQuestionText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Please enter a question';
    }
    return null;
  }

  /// Validate version name
  String? validateVersionName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Please enter a version name';
    }
    return null;
  }

  /// Validate category
  String? validateCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      return 'Please select a category';
    }
    return null;
  }
}
