import 'package:supabase_flutter/supabase_flutter.dart';

/// Result class for loading resources
class LoadResourcesResult {
  final bool success;
  final List<Map<String, dynamic>> resources;
  final String? errorMessage;

  LoadResourcesResult({
    required this.success,
    this.resources = const [],
    this.errorMessage,
  });
}

/// Result class for creating a resource
class CreateResourceResult {
  final bool success;
  final String? errorMessage;
  final int? resourceId;

  CreateResourceResult({
    required this.success,
    this.errorMessage,
    this.resourceId,
  });
}

/// Result class for updating a resource
class UpdateResourceResult {
  final bool success;
  final String? errorMessage;

  UpdateResourceResult({
    required this.success,
    this.errorMessage,
  });
}

/// Result class for deleting a resource
class DeleteResourceResult {
  final bool success;
  final String? errorMessage;

  DeleteResourceResult({
    required this.success,
    this.errorMessage,
  });
}

/// Admin Mental Health Resources Controller - Handles resource management operations
class AdminMentalHealthResourcesController {
  final _supabase = Supabase.instance.client;

  /// Load all mental health resources
  Future<LoadResourcesResult> loadResources() async {
    try {
      final response = await _supabase
          .from('mental_health_resources')
          .select()
          .order('publish_date', ascending: false);

      return LoadResourcesResult(
        success: true,
        resources: List<Map<String, dynamic>>.from(response),
      );
    } catch (e) {
      print('Error loading resources: $e');
      return LoadResourcesResult(
        success: false,
        errorMessage: 'Failed to load resources: ${e.toString()}',
      );
    }
  }

  /// Create a new mental health resource
  Future<CreateResourceResult> createResource({
    required String title,
    required String description,
    required String resourceType,
    required String mediaUrl,
    required String tags,
    required DateTime publishDate,
  }) async {
    try {
      final response = await _supabase
          .from('mental_health_resources')
          .insert({
            'title': title.trim(),
            'description': description.trim(),
            'resource_type': resourceType,
            'media_url': mediaUrl.trim(),
            'tags': tags.trim(),
            'publish_date': publishDate.toIso8601String(),
          })
          .select('resource_id')
          .single();

      return CreateResourceResult(
        success: true,
        resourceId: response['resource_id'] as int?,
      );
    } catch (e) {
      print('Error creating resource: $e');
      return CreateResourceResult(
        success: false,
        errorMessage: 'Failed to create resource: ${e.toString()}',
      );
    }
  }

  /// Update an existing mental health resource
  Future<UpdateResourceResult> updateResource({
    required int resourceId,
    required String title,
    required String description,
    required String resourceType,
    required String mediaUrl,
    required String tags,
    required DateTime publishDate,
  }) async {
    try {
      await _supabase
          .from('mental_health_resources')
          .update({
            'title': title.trim(),
            'description': description.trim(),
            'resource_type': resourceType,
            'media_url': mediaUrl.trim(),
            'tags': tags.trim(),
            'publish_date': publishDate.toIso8601String(),
          })
          .eq('resource_id', resourceId);

      return UpdateResourceResult(success: true);
    } catch (e) {
      print('Error updating resource: $e');
      return UpdateResourceResult(
        success: false,
        errorMessage: 'Failed to update resource: ${e.toString()}',
      );
    }
  }

  /// Delete a mental health resource
  Future<DeleteResourceResult> deleteResource(int resourceId) async {
    try {
      await _supabase
          .from('mental_health_resources')
          .delete()
          .eq('resource_id', resourceId);

      return DeleteResourceResult(success: true);
    } catch (e) {
      print('Error deleting resource: $e');
      return DeleteResourceResult(
        success: false,
        errorMessage: 'Failed to delete resource: ${e.toString()}',
      );
    }
  }

  /// Validate title
  String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Please enter a title';
    }
    return null;
  }

  /// Validate description/content
  String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'Please enter a description';
    }
    return null;
  }

  /// Validate media URL
  String? validateMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return 'Please enter a media URL';
    }
    
    // More permissive URL validation that supports query parameters
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/?#].*)?$',
      caseSensitive: false,
    );
    
    if (!urlPattern.hasMatch(url.trim())) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }
}
