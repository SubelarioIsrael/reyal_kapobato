import 'package:supabase_flutter/supabase_flutter.dart';

class StudentProfileResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  StudentProfileResult({
    required this.success,
    this.data,
    this.errorMessage,
  });
}

class StudentProfileController {
  final _supabase = Supabase.instance.client;

  /// Validates name: only letters, spaces, hyphens, and apostrophes allowed
  bool isValidName(String name) {
    if (name.trim().isEmpty) return false;
    
    // Regular expression: allows letters (uppercase/lowercase), spaces, hyphens, and apostrophes
    // No numbers or special characters except spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    return nameRegex.hasMatch(name.trim());
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Load user profile data
  Future<StudentProfileResult> loadUserProfile() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return StudentProfileResult(
          success: false,
          errorMessage: 'No user logged in',
        );
      }

      // Get user profile data
      final userResponse = await _supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .single();

      // Get student data with all fields
      final studentResponse = await _supabase
          .from('students')
          .select('first_name, last_name, student_code, course, year_level, education_level, strand')
          .eq('user_id', userId)
          .maybeSingle();

      return StudentProfileResult(
        success: true,
        data: {
          'user': userResponse,
          'student': studentResponse,
        },
      );
    } catch (e) {
      return StudentProfileResult(
        success: false,
        errorMessage: 'Failed to load profile: ${e.toString()}',
      );
    }
  }

  /// Update student profile
  Future<StudentProfileResult> updateProfile({
    required String firstName,
    required String lastName,
    required String educationLevel,
    String? course,
    String? strand,
    int? yearLevel,
  }) async {
    try {
      // Validate names
      if (!isValidName(firstName)) {
        return StudentProfileResult(
          success: false,
          errorMessage: 'First name can only contain letters, spaces, hyphens, and apostrophes',
        );
      }

      if (!isValidName(lastName)) {
        return StudentProfileResult(
          success: false,
          errorMessage: 'Last name can only contain letters, spaces, hyphens, and apostrophes',
        );
      }

      final userId = getCurrentUserId();
      if (userId == null) {
        return StudentProfileResult(
          success: false,
          errorMessage: 'No user logged in',
        );
      }

      // Prepare student data update
      Map<String, dynamic> studentData = {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'year_level': yearLevel,
      };

      // Add education-specific fields
      if (educationLevel == 'college') {
        studentData['education_level'] = 'college';
        studentData['course'] = course;
        studentData['strand'] = null;
      } else if (educationLevel == 'senior_high') {
        studentData['education_level'] = 'senior_high';
        studentData['course'] = null;
        studentData['strand'] = strand;
      } else if (educationLevel == 'junior_high') {
        studentData['education_level'] = 'junior_high';
        studentData['course'] = null;
        studentData['strand'] = null;
      } else if (educationLevel == 'basic_education') {
        studentData['education_level'] = 'basic_education';
        studentData['course'] = null;
        studentData['strand'] = null;
      }

      // Update in database
      await _supabase
          .from('students')
          .update(studentData)
          .eq('user_id', userId);

      return StudentProfileResult(
        success: true,
        errorMessage: null,
      );
    } catch (e) {
      return StudentProfileResult(
        success: false,
        errorMessage: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  /// Update profile picture
  Future<StudentProfileResult> updateProfilePicture({
    required String base64Image,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return StudentProfileResult(
          success: false,
          errorMessage: 'No user logged in',
        );
      }

      // Update user profile picture
      await _supabase
          .from('users')
          .update({'profile_picture': base64Image})
          .eq('user_id', userId);

      return StudentProfileResult(
        success: true,
      );
    } catch (e) {
      return StudentProfileResult(
        success: false,
        errorMessage: 'Failed to update profile picture: ${e.toString()}',
      );
    }
  }
}
