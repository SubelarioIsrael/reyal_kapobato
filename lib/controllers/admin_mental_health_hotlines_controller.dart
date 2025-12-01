import 'package:supabase_flutter/supabase_flutter.dart';

/// Result class for loading hotlines
class LoadHotlinesResult {
  final bool success;
  final List<Map<String, dynamic>> hotlines;
  final String? errorMessage;

  LoadHotlinesResult({
    required this.success,
    this.hotlines = const [],
    this.errorMessage,
  });
}

/// Result class for creating a hotline
class CreateHotlineResult {
  final bool success;
  final String? errorMessage;
  final bool isDuplicate;
  final int? hotlineId;

  CreateHotlineResult({
    required this.success,
    this.errorMessage,
    this.hotlineId,
    this.isDuplicate = false,
  });
}

/// Result class for updating a hotline
class UpdateHotlineResult {
  final bool success;
  final String? errorMessage;
  final bool isDuplicate;

  UpdateHotlineResult({
    required this.success,
    this.errorMessage,
    this.isDuplicate = false,
  });
}

/// Result class for deleting a hotline
class DeleteHotlineResult {
  final bool success;
  final String? errorMessage;

  DeleteHotlineResult({
    required this.success,
    this.errorMessage,
  });
}

/// Admin Mental Health Hotlines Controller - Handles hotline management
class AdminMentalHealthHotlinesController {
  final _supabase = Supabase.instance.client;

  /// Load all mental health hotlines
  Future<LoadHotlinesResult> loadHotlines() async {
    try {
      final response = await _supabase
          .from('mental_health_hotlines')
          .select()
          .order('created_at', ascending: false);

      final hotlines = List<Map<String, dynamic>>.from(response);

      return LoadHotlinesResult(
        success: true,
        hotlines: hotlines,
      );
    } catch (e) {
      print('Error loading hotlines: $e');
      return LoadHotlinesResult(
        success: false,
        errorMessage: 'Failed to load hotlines: ${e.toString()}',
      );
    }
  }

  /// Create a new mental health hotline
  Future<CreateHotlineResult> createHotline({
    required String name,
    required String phone,
    String? cityOrRegion,
    String? notes,
    String? profilePicture,
  }) async {
    try {
      // normalize phone to digits only for consistent duplicate checks
      final cleanedPhone = phone.replaceAll(RegExp(r'\D'), '');

      // check duplicate phone
      final duplicate = await _supabase
          .from('mental_health_hotlines')
          .select('hotline_id')
          .eq('phone', cleanedPhone)
          .maybeSingle();

      if (duplicate != null) {
        return CreateHotlineResult(
          success: false,
          errorMessage: 'duplicate',
          isDuplicate: true,
        );
      }

      final response = await _supabase
          .from('mental_health_hotlines')
          .insert({
            'name': name.trim(),
            'phone': cleanedPhone,
            'city_or_region': cityOrRegion?.trim(),
            'notes': notes?.trim(),
            'profile_picture': profilePicture,
          })
          .select()
          .single();

      return CreateHotlineResult(
        success: true,
        hotlineId: response['hotline_id'] as int,
      );
    } catch (e) {
      print('Error creating hotline: $e');
      return CreateHotlineResult(
        success: false,
        errorMessage: 'Failed to add hotline: ${e.toString()}',
      );
    }
  }

  /// Update an existing mental health hotline
  Future<UpdateHotlineResult> updateHotline({
    required int hotlineId,
    required String name,
    required String phone,
    String? cityOrRegion,
    String? notes,
    String? profilePicture,
  }) async {
    try {
      final cleanedPhone = phone.replaceAll(RegExp(r'\D'), '');

      // check duplicate phone for other records
      final duplicate = await _supabase
          .from('mental_health_hotlines')
          .select('hotline_id')
          .eq('phone', cleanedPhone)
          .maybeSingle();

      if (duplicate != null && duplicate['hotline_id'] != hotlineId) {
        return UpdateHotlineResult(
          success: false,
          errorMessage: 'duplicate',
          isDuplicate: true,
        );
      }

      await _supabase
          .from('mental_health_hotlines')
          .update({
            'name': name.trim(),
            'phone': cleanedPhone,
            'city_or_region': cityOrRegion?.trim(),
            'notes': notes?.trim(),
            'profile_picture': profilePicture,
          })
          .eq('hotline_id', hotlineId);

      return UpdateHotlineResult(success: true);
    } catch (e) {
      print('Error updating hotline: $e');
      return UpdateHotlineResult(
        success: false,
        errorMessage: 'Failed to update hotline: ${e.toString()}',
      );
    }
  }

  /// Delete a mental health hotline
  Future<DeleteHotlineResult> deleteHotline(int hotlineId) async {
    try {
      await _supabase
          .from('mental_health_hotlines')
          .delete()
          .eq('hotline_id', hotlineId);

      return DeleteHotlineResult(success: true);
    } catch (e) {
      print('Error deleting hotline: $e');
      return DeleteHotlineResult(
        success: false,
        errorMessage: 'Failed to delete hotline: ${e.toString()}',
      );
    }
  }

  /// Validate hotline name
  String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Please enter a service name';
    }
    return null;
  }

  /// Validate phone number
  String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Please enter a phone number';
    }
    return null;
  }
}
