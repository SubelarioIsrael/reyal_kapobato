import 'package:supabase_flutter/supabase_flutter.dart';

class CounselorFirstSetupController {
  final _supabase = Supabase.instance.client;

  /// Load existing counselor profile
  Future<Map<String, dynamic>?> loadExistingProfile(String userId) async {
    try {
      final result = await _supabase
          .from('counselors')
          .select('*, users(profile_picture)')
          .eq('user_id', userId)
          .maybeSingle();

      return result;
    } catch (e) {
      print('Error loading existing profile: $e');
      rethrow;
    }
  }

  /// Create new counselor profile
  Future<Map<String, dynamic>> createCounselorProfile(Map<String, dynamic> payload) async {
    try {
      final inserted = await _supabase
          .from('counselors')
          .insert(payload)
          .select()
          .single();

      return inserted;
    } catch (e) {
      print('Error creating counselor profile: $e');
      rethrow;
    }
  }

  /// Update existing counselor profile
  Future<void> updateCounselorProfile(int counselorId, Map<String, dynamic> payload) async {
    try {
      await _supabase
          .from('counselors')
          .update(payload)
          .eq('counselor_id', counselorId);
    } catch (e) {
      print('Error updating counselor profile: $e');
      rethrow;
    }
  }

  /// Update user profile picture
  Future<void> updateUserProfilePicture(String userId, String? profilePicture) async {
    try {
      await _supabase
          .from('users')
          .update({'profile_picture': profilePicture})
          .eq('user_id', userId);
    } catch (e) {
      print('Error updating user profile picture: $e');
      rethrow;
    }
  }
}
