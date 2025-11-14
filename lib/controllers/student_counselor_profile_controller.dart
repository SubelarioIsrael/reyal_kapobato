import 'package:supabase_flutter/supabase_flutter.dart';

class StudentCounselorProfileResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  StudentCounselorProfileResult({
    required this.success,
    this.data,
    this.errorMessage,
  });
}

class StudentCounselorProfileController {
  final _supabase = Supabase.instance.client;

  /// Fetches counselor profile by counselor ID
  Future<StudentCounselorProfileResult> getCounselorProfile(int counselorId) async {
    try {
      final response = await _supabase
          .from('counselors')
          .select('*, users!inner(email)')
          .eq('counselor_id', counselorId)
          .maybeSingle();

      if (response == null) {
        return StudentCounselorProfileResult(
          success: false,
          errorMessage: 'Counselor not found',
        );
      }

      // Validate name fields (no numbers or special characters)
      final firstName = response['first_name']?.toString() ?? '';
      final lastName = response['last_name']?.toString() ?? '';

      if (!_isValidName(firstName)) {
        return StudentCounselorProfileResult(
          success: false,
          errorMessage: 'Invalid first name format',
        );
      }

      if (!_isValidName(lastName)) {
        return StudentCounselorProfileResult(
          success: false,
          errorMessage: 'Invalid last name format',
        );
      }

      return StudentCounselorProfileResult(
        success: true,
        data: response,
      );
    } catch (e) {
      return StudentCounselorProfileResult(
        success: false,
        errorMessage: 'Failed to load counselor profile: ${e.toString()}',
      );
    }
  }

  /// Validates name: only letters, spaces, hyphens, and apostrophes allowed
  bool _isValidName(String name) {
    if (name.isEmpty) return true; // Empty names are handled separately
    
    // Regular expression: allows letters (uppercase/lowercase), spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    return nameRegex.hasMatch(name);
  }

  /// Validates that a string contains no numbers or special characters (except spaces, hyphens, apostrophes)
  bool isValidTextInput(String text) {
    return _isValidName(text);
  }
}
