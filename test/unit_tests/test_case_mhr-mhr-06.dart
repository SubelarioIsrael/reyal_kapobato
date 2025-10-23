import 'package:flutter_test/flutter_test.dart';

/// MHR-MHR-06: Admin Update Mental Health Resource
/// 
/// This test validates that an admin can successfully update a mental health resource
/// with proper validation and error handling.
///
/// Database Schema:
/// - mental_health_resources table with fields:
///   - resource_id (PK), title, description, resource_type, media_url, tags, publish_date

// Mock Database for Mental Health Resources
class MockMentalHealthResourceDatabase {
  final List<Map<String, dynamic>> _resources = [];
  int _nextId = 1;

  // Insert new resource
  Future<int> insertResource(Map<String, dynamic> resource) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final newResource = Map<String, dynamic>.from(resource);
    newResource['resource_id'] = _nextId++;
    _resources.add(newResource);
    return newResource['resource_id'] as int;
  }

  // Update existing resource
  Future<bool> updateResource(int resourceId, Map<String, dynamic> updates) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      final index = _resources.indexWhere((r) => r['resource_id'] == resourceId);
      if (index == -1) return false;
      
      _resources[index] = {
        ..._resources[index],
        ...updates,
        'resource_id': resourceId, // Preserve ID
      };
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get all resources
  Future<List<Map<String, dynamic>>> getAllResources() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List<Map<String, dynamic>>.from(_resources);
  }

  void clear() {
    _resources.clear();
    _nextId = 1;
  }

  int get resourceCount => _resources.length;
}

// Service for admin updating resources
class AdminResourceUpdateService {
  final MockMentalHealthResourceDatabase database;
  
  List<Map<String, dynamic>> resources = [];
  bool isLoading = false;
  String? errorMessage;

  AdminResourceUpdateService(this.database);

  // Load resources
  Future<void> loadResources() async {
    resources = await database.getAllResources();
  }

  // Update existing resource
  Future<bool> updateResource({
    required int resourceId,
    required String title,
    required String description,
    required String resourceType,
    String? mediaUrl,
    String? tags,
    DateTime? publishDate,
  }) async {
    errorMessage = null;

    // Validation
    if (title.trim().isEmpty) {
      errorMessage = 'Please enter a title';
      return false;
    }

    if (description.trim().isEmpty) {
      errorMessage = 'Please enter content';
      return false;
    }

    if (resourceType != 'article' && resourceType != 'video') {
      errorMessage = 'Invalid resource type';
      return false;
    }

    try {
      final success = await database.updateResource(resourceId, {
        'title': title.trim(),
        'description': description.trim(),
        'resource_type': resourceType,
        'media_url': mediaUrl?.trim() ?? '',
        'tags': tags?.trim() ?? '',
        'publish_date': (publishDate ?? DateTime.now()).toIso8601String(),
      });

      if (!success) {
        errorMessage = 'Resource not found';
        return false;
      }

      await loadResources();
      return true;
    } catch (e) {
      errorMessage = 'Failed to update resource';
      return false;
    }
  }

  // Helper methods
  int getTotalResourceCount() => resources.length;
  
  int getVideoCount() => resources.where((r) => r['resource_type'] == 'video').length;
  
  int getArticleCount() => resources.where((r) => r['resource_type'] == 'article').length;

  Map<String, dynamic>? getResourceById(int resourceId) {
    try {
      return resources.firstWhere((r) => r['resource_id'] == resourceId);
    } catch (e) {
      return null;
    }
  }

  // Validation helpers
  String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Please enter a title';
    }
    return null;
  }

  String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'Please enter content';
    }
    return null;
  }

  String? validateResourceType(String? type) {
    if (type != 'article' && type != 'video') {
      return 'Invalid resource type';
    }
    return null;
  }
}

void main() {
  group('MHR-MHR-06: Admin Update Mental Health Resource', () {
    late MockMentalHealthResourceDatabase mockDatabase;
    late AdminResourceUpdateService service;

    setUp(() {
      mockDatabase = MockMentalHealthResourceDatabase();
      service = AdminResourceUpdateService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('should successfully update resource', () async {
      // Arrange: Add resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Original Title',
        'description': 'Original description',
        'resource_type': 'article',
        'media_url': 'https://example.com/original',
        'tags': 'original',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();

      // Act: Update resource
      final result = await service.updateResource(
        resourceId: resourceId,
        title: 'Updated Title',
        description: 'Updated description',
        resourceType: 'video',
        mediaUrl: 'https://example.com/updated',
        tags: 'updated',
      );

      // Assert: Verify update
      expect(result, isTrue);
      final updated = service.getResourceById(resourceId);
      expect(updated!['title'], equals('Updated Title'));
      expect(updated['description'], equals('Updated description'));
      expect(updated['resource_type'], equals('video'));
      expect(updated['media_url'], equals('https://example.com/updated'));
      expect(updated['tags'], equals('updated'));
      expect(service.errorMessage, isNull);
    });

    test('should update resource media URL', () async {
      // Arrange: Add resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test description',
        'resource_type': 'video',
        'media_url': 'https://example.com/old',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();

      // Act: Update media URL
      await service.updateResource(
        resourceId: resourceId,
        title: 'Test Resource',
        description: 'Test description',
        resourceType: 'video',
        mediaUrl: 'https://example.com/new',
      );

      // Assert: Verify URL is updated
      final updated = service.getResourceById(resourceId);
      expect(updated!['media_url'], equals('https://example.com/new'));
    });

    test('should update resource publish date', () async {
      // Arrange: Add resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test description',
        'resource_type': 'article',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime(2023, 1, 1).toIso8601String(),
      });
      await service.loadResources();
      final newDate = DateTime(2024, 12, 31);

      // Act: Update publish date
      await service.updateResource(
        resourceId: resourceId,
        title: 'Test Resource',
        description: 'Test description',
        resourceType: 'article',
        publishDate: newDate,
      );

      // Assert: Verify date is updated
      final updated = service.getResourceById(resourceId);
      final updatedDate = DateTime.tryParse(updated!['publish_date']);
      expect(updatedDate?.year, equals(2024));
      expect(updatedDate?.month, equals(12));
      expect(updatedDate?.day, equals(31));
    });

    test('should trim whitespace when updating', () async {
      // Arrange: Add resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test description',
        'resource_type': 'article',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();

      // Act: Update with whitespace
      await service.updateResource(
        resourceId: resourceId,
        title: '  Updated Title  ',
        description: '  Updated Description  ',
        resourceType: 'article',
        mediaUrl: '  https://example.com/updated  ',
        tags: '  updated  ',
      );

      // Assert: Verify whitespace is trimmed
      final updated = service.getResourceById(resourceId);
      expect(updated!['title'], equals('Updated Title'));
      expect(updated['description'], equals('Updated Description'));
      expect(updated['media_url'], equals('https://example.com/updated'));
      expect(updated['tags'], equals('updated'));
    });

    test('should reject update with empty title', () async {
      // Arrange: Add resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test description',
        'resource_type': 'article',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();

      // Act: Try to update with empty title
      final result = await service.updateResource(
        resourceId: resourceId,
        title: '',
        description: 'Valid description',
        resourceType: 'article',
      );

      // Assert: Verify rejection
      expect(result, isFalse);
      expect(service.errorMessage, equals('Please enter a title'));
    });

    test('should reject update with whitespace-only title', () async {
      // Arrange: Add resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test description',
        'resource_type': 'article',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();

      // Act: Try to update with whitespace-only title
      final result = await service.updateResource(
        resourceId: resourceId,
        title: '   ',
        description: 'Valid description',
        resourceType: 'article',
      );

      // Assert: Verify rejection
      expect(result, isFalse);
      expect(service.errorMessage, equals('Please enter a title'));
    });

    test('should reject update with empty description', () async {
      // Arrange: Add resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test description',
        'resource_type': 'article',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();

      // Act: Try to update with empty description
      final result = await service.updateResource(
        resourceId: resourceId,
        title: 'Valid Title',
        description: '',
        resourceType: 'article',
      );

      // Assert: Verify rejection
      expect(result, isFalse);
      expect(service.errorMessage, equals('Please enter content'));
    });

    test('should reject update with whitespace-only description', () async {
      // Arrange: Add resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test description',
        'resource_type': 'article',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();

      // Act: Try to update with whitespace-only description
      final result = await service.updateResource(
        resourceId: resourceId,
        title: 'Valid Title',
        description: '   ',
        resourceType: 'article',
      );

      // Assert: Verify rejection
      expect(result, isFalse);
      expect(service.errorMessage, equals('Please enter content'));
    });

    test('should reject update with invalid resource type', () async {
      // Arrange: Add resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test description',
        'resource_type': 'article',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();

      // Act: Try to update with invalid type
      final result = await service.updateResource(
        resourceId: resourceId,
        title: 'Valid Title',
        description: 'Valid description',
        resourceType: 'invalid_type',
      );

      // Assert: Verify rejection
      expect(result, isFalse);
      expect(service.errorMessage, equals('Invalid resource type'));
    });

    test('should handle updating non-existent resource', () async {
      // Act: Try to update non-existent resource
      final result = await service.updateResource(
        resourceId: 999,
        title: 'Test',
        description: 'Test',
        resourceType: 'article',
      );

      // Assert: Verify error
      expect(result, isFalse);
      expect(service.errorMessage, equals('Resource not found'));
    });

    test('should preserve resource ID after update', () async {
      // Arrange: Add resource
      final originalId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test description',
        'resource_type': 'article',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();

      // Act: Update resource
      await service.updateResource(
        resourceId: originalId,
        title: 'Updated Title',
        description: 'Updated description',
        resourceType: 'video',
      );

      // Assert: Verify ID is preserved
      final updated = service.getResourceById(originalId);
      expect(updated, isNotNull);
      expect(updated!['resource_id'], equals(originalId));
    });

    test('should change resource type from article to video', () async {
      // Arrange: Add article
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Article',
        'description': 'Article content',
        'resource_type': 'article',
        'media_url': 'https://example.com/article',
        'tags': 'article',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();
      expect(service.getArticleCount(), equals(1));
      expect(service.getVideoCount(), equals(0));

      // Act: Change to video
      await service.updateResource(
        resourceId: resourceId,
        title: 'Test Video',
        description: 'Video content',
        resourceType: 'video',
      );

      // Assert: Verify type change
      final updated = service.getResourceById(resourceId);
      expect(updated!['resource_type'], equals('video'));
      expect(service.getArticleCount(), equals(0));
      expect(service.getVideoCount(), equals(1));
    });

    test('should change resource type from video to article', () async {
      // Arrange: Add video
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Video',
        'description': 'Video content',
        'resource_type': 'video',
        'media_url': 'https://youtube.com/video',
        'tags': 'video',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();
      expect(service.getVideoCount(), equals(1));
      expect(service.getArticleCount(), equals(0));

      // Act: Change to article
      await service.updateResource(
        resourceId: resourceId,
        title: 'Test Article',
        description: 'Article content',
        resourceType: 'article',
      );

      // Assert: Verify type change
      final updated = service.getResourceById(resourceId);
      expect(updated!['resource_type'], equals('article'));
      expect(service.getVideoCount(), equals(0));
      expect(service.getArticleCount(), equals(1));
    });

    test('should update only specific fields', () async {
      // Arrange: Add resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Original Title',
        'description': 'Original description',
        'resource_type': 'article',
        'media_url': 'https://example.com/original',
        'tags': 'original, tags',
        'publish_date': DateTime(2024, 1, 1).toIso8601String(),
      });
      await service.loadResources();

      // Act: Update only title
      await service.updateResource(
        resourceId: resourceId,
        title: 'New Title',
        description: 'Original description',
        resourceType: 'article',
        mediaUrl: 'https://example.com/original',
        tags: 'original, tags',
        publishDate: DateTime(2024, 1, 1),
      );

      // Assert: Verify only title changed
      final updated = service.getResourceById(resourceId);
      expect(updated!['title'], equals('New Title'));
      expect(updated['description'], equals('Original description'));
    });

    test('should handle optional fields when updating', () async {
      // Arrange: Add resource with optional fields
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test description',
        'resource_type': 'article',
        'media_url': 'https://example.com/test',
        'tags': 'test, tags',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();

      // Act: Update without optional fields
      await service.updateResource(
        resourceId: resourceId,
        title: 'Updated Title',
        description: 'Updated description',
        resourceType: 'article',
      );

      // Assert: Verify optional fields are empty strings
      final updated = service.getResourceById(resourceId);
      expect(updated!['media_url'], equals(''));
      expect(updated['tags'], equals(''));
    });

    test('should validate title helper method', () {
      // Assert: Test validation helper
      expect(service.validateTitle('Valid Title'), isNull);
      expect(service.validateTitle(''), equals('Please enter a title'));
      expect(service.validateTitle(null), equals('Please enter a title'));
      expect(service.validateTitle('   '), equals('Please enter a title'));
    });

    test('should validate description helper method', () {
      // Assert: Test validation helper
      expect(service.validateDescription('Valid description'), isNull);
      expect(service.validateDescription(''), equals('Please enter content'));
      expect(service.validateDescription(null), equals('Please enter content'));
      expect(service.validateDescription('   '), equals('Please enter content'));
    });

    test('should validate resource type helper method', () {
      // Assert: Test validation helper
      expect(service.validateResourceType('article'), isNull);
      expect(service.validateResourceType('video'), isNull);
      expect(service.validateResourceType('invalid'), equals('Invalid resource type'));
      expect(service.validateResourceType(''), equals('Invalid resource type'));
      expect(service.validateResourceType(null), equals('Invalid resource type'));
    });

    test('should not affect other resources when updating one', () async {
      // Arrange: Add multiple resources
      final updateId = await mockDatabase.insertResource({
        'title': 'Update This',
        'description': 'Will be updated',
        'resource_type': 'article',
        'media_url': 'https://example.com/update',
        'tags': 'update',
        'publish_date': DateTime.now().toIso8601String(),
      });

      final keepId = await mockDatabase.insertResource({
        'title': 'Keep This',
        'description': 'Will not change',
        'resource_type': 'video',
        'media_url': 'https://example.com/keep',
        'tags': 'keep',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await service.loadResources();

      // Act: Update one resource
      await service.updateResource(
        resourceId: updateId,
        title: 'Updated Title',
        description: 'Updated description',
        resourceType: 'video',
      );

      // Assert: Verify other resource unchanged
      final kept = service.getResourceById(keepId);
      expect(kept!['title'], equals('Keep This'));
      expect(kept['description'], equals('Will not change'));
      expect(kept['resource_type'], equals('video'));
    });

    test('should clear error message on successful update', () async {
      // Arrange: Create an error first
      await service.updateResource(
        resourceId: 999,
        title: 'Test',
        description: 'Test',
        resourceType: 'article',
      );
      expect(service.errorMessage, isNotNull);

      // Add resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test',
        'resource_type': 'article',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();

      // Act: Successfully update resource
      await service.updateResource(
        resourceId: resourceId,
        title: 'Updated Title',
        description: 'Updated description',
        resourceType: 'article',
      );

      // Assert: Verify error is cleared
      expect(service.errorMessage, isNull);
    });
  });
}
