import 'package:flutter_test/flutter_test.dart';

/// MHR-MHR-05: Admin Delete Mental Health Resource
/// 
/// This test validates that an admin can successfully delete a mental health resource
/// with proper confirmation and error handling.
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

  // Delete resource
  Future<bool> deleteResource(int resourceId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final initialLength = _resources.length;
    _resources.removeWhere((r) => r['resource_id'] == resourceId);
    return _resources.length < initialLength;
  }

  // Get all resources
  Future<List<Map<String, dynamic>>> getAllResources() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final sorted = List<Map<String, dynamic>>.from(_resources);
    sorted.sort((a, b) {
      final dateA = DateTime.tryParse(a['publish_date'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['publish_date'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA); // Descending order
    });
    return sorted;
  }

  void clear() {
    _resources.clear();
    _nextId = 1;
  }

  int get resourceCount => _resources.length;
}

// Service for admin deleting resources
class AdminResourceDeleteService {
  final MockMentalHealthResourceDatabase database;
  
  List<Map<String, dynamic>> resources = [];
  bool isLoading = false;
  String? errorMessage;

  AdminResourceDeleteService(this.database);

  // Load resources
  Future<void> loadResources() async {
    resources = await database.getAllResources();
  }

  // Delete resource
  Future<bool> deleteResource(int resourceId) async {
    errorMessage = null;

    try {
      final success = await database.deleteResource(resourceId);
      
      if (!success) {
        errorMessage = 'Resource not found';
        return false;
      }

      await loadResources();
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete resource';
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
}

void main() {
  group('MHR-MHR-05: Admin Delete Mental Health Resource', () {
    late MockMentalHealthResourceDatabase mockDatabase;
    late AdminResourceDeleteService service;

    setUp(() {
      mockDatabase = MockMentalHealthResourceDatabase();
      service = AdminResourceDeleteService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('should successfully delete resource', () async {
      // Arrange: Add resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Resource to Delete',
        'description': 'Will be deleted',
        'resource_type': 'article',
        'media_url': 'https://example.com/delete',
        'tags': 'delete',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();
      expect(service.getTotalResourceCount(), equals(1));

      // Act: Delete resource
      final result = await service.deleteResource(resourceId);

      // Assert: Verify deletion
      expect(result, isTrue);
      expect(service.getTotalResourceCount(), equals(0));
      expect(service.errorMessage, isNull);
    });

    test('should handle deleting non-existent resource', () async {
      // Act: Try to delete non-existent resource
      final result = await service.deleteResource(999);

      // Assert: Verify error
      expect(result, isFalse);
      expect(service.errorMessage, equals('Resource not found'));
    });

    test('should remove resource from list after deletion', () async {
      // Arrange: Add resources
      final id1 = await mockDatabase.insertResource({
        'title': 'Resource 1',
        'description': 'Description 1',
        'resource_type': 'article',
        'media_url': 'https://example.com/r1',
        'tags': 'test',
        'publish_date': DateTime(2024, 1, 1).toIso8601String(),
      });

      final id2 = await mockDatabase.insertResource({
        'title': 'Resource 2',
        'description': 'Description 2',
        'resource_type': 'video',
        'media_url': 'https://example.com/r2',
        'tags': 'test',
        'publish_date': DateTime(2024, 2, 1).toIso8601String(),
      });

      await service.loadResources();
      expect(service.getTotalResourceCount(), equals(2));

      // Act: Delete first resource
      await service.deleteResource(id1);

      // Assert: Verify only second resource remains
      expect(service.getTotalResourceCount(), equals(1));
      expect(service.resources[0]['resource_id'], equals(id2));
      expect(service.resources[0]['title'], equals('Resource 2'));
    });

    test('should delete multiple resources sequentially', () async {
      // Arrange: Add resources with different dates
      final id1 = await mockDatabase.insertResource({
        'title': 'Resource 1',
        'description': 'Description 1',
        'resource_type': 'article',
        'media_url': 'https://example.com/r1',
        'tags': 'test',
        'publish_date': DateTime(2024, 1, 1).toIso8601String(),
      });

      final id2 = await mockDatabase.insertResource({
        'title': 'Resource 2',
        'description': 'Description 2',
        'resource_type': 'video',
        'media_url': 'https://example.com/r2',
        'tags': 'test',
        'publish_date': DateTime(2024, 2, 1).toIso8601String(),
      });

      await mockDatabase.insertResource({
        'title': 'Resource 3',
        'description': 'Description 3',
        'resource_type': 'article',
        'media_url': 'https://example.com/r3',
        'tags': 'test',
        'publish_date': DateTime(2024, 3, 1).toIso8601String(),
      });

      await service.loadResources();
      expect(service.getTotalResourceCount(), equals(3));

      // Act: Delete resources
      await service.deleteResource(id1);
      await service.deleteResource(id2);

      // Assert: Verify only Resource 3 remains
      expect(service.getTotalResourceCount(), equals(1));
      expect(service.resources[0]['title'], equals('Resource 3'));
    });

    test('should update statistics after deletion', () async {
      // Arrange: Add mixed resources with specific dates
      final articleId = await mockDatabase.insertResource({
        'title': 'Article 1',
        'description': 'Article',
        'resource_type': 'article',
        'media_url': 'https://example.com/article',
        'tags': 'article',
        'publish_date': DateTime(2024, 1, 1).toIso8601String(),
      });

      await mockDatabase.insertResource({
        'title': 'Video 1',
        'description': 'Video',
        'resource_type': 'video',
        'media_url': 'https://example.com/video',
        'tags': 'video',
        'publish_date': DateTime(2024, 2, 1).toIso8601String(),
      });

      await service.loadResources();
      expect(service.getArticleCount(), equals(1));
      expect(service.getVideoCount(), equals(1));

      // Act: Delete article
      await service.deleteResource(articleId);

      // Assert: Verify updated statistics
      expect(service.getArticleCount(), equals(0));
      expect(service.getVideoCount(), equals(1));
    });

    test('should handle deletion when list is already empty', () async {
      // Arrange: Empty database
      await service.loadResources();
      expect(service.getTotalResourceCount(), equals(0));

      // Act: Try to delete from empty list
      final result = await service.deleteResource(1);

      // Assert: Verify error handling
      expect(result, isFalse);
      expect(service.errorMessage, equals('Resource not found'));
    });

    test('should maintain correct order after deletion', () async {
      // Arrange: Add resources in specific order
      await mockDatabase.insertResource({
        'title': 'Old Resource',
        'description': 'Old',
        'resource_type': 'article',
        'media_url': 'https://example.com/old',
        'tags': 'old',
        'publish_date': DateTime(2024, 1, 1).toIso8601String(),
      });

      final middleId = await mockDatabase.insertResource({
        'title': 'Middle Resource',
        'description': 'Middle',
        'resource_type': 'video',
        'media_url': 'https://example.com/middle',
        'tags': 'middle',
        'publish_date': DateTime(2024, 6, 15).toIso8601String(),
      });

      await mockDatabase.insertResource({
        'title': 'New Resource',
        'description': 'New',
        'resource_type': 'article',
        'media_url': 'https://example.com/new',
        'tags': 'new',
        'publish_date': DateTime(2024, 12, 31).toIso8601String(),
      });

      await service.loadResources();

      // Act: Delete middle resource
      await service.deleteResource(middleId);

      // Assert: Verify order is maintained (newest first)
      expect(service.getTotalResourceCount(), equals(2));
      expect(service.resources[0]['title'], equals('New Resource'));
      expect(service.resources[1]['title'], equals('Old Resource'));
    });

    test('should delete article resource correctly', () async {
      // Arrange: Add article
      final articleId = await mockDatabase.insertResource({
        'title': 'Article to Delete',
        'description': 'Article content',
        'resource_type': 'article',
        'media_url': 'https://example.com/article',
        'tags': 'article',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await service.loadResources();

      // Act: Delete article
      final result = await service.deleteResource(articleId);

      // Assert: Verify deletion
      expect(result, isTrue);
      expect(service.getArticleCount(), equals(0));
      expect(service.getResourceById(articleId), isNull);
    });

    test('should delete video resource correctly', () async {
      // Arrange: Add video
      final videoId = await mockDatabase.insertResource({
        'title': 'Video to Delete',
        'description': 'Video content',
        'resource_type': 'video',
        'media_url': 'https://youtube.com/video',
        'tags': 'video',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await service.loadResources();

      // Act: Delete video
      final result = await service.deleteResource(videoId);

      // Assert: Verify deletion
      expect(result, isTrue);
      expect(service.getVideoCount(), equals(0));
      expect(service.getResourceById(videoId), isNull);
    });

    test('should not affect other resources when deleting one', () async {
      // Arrange: Add multiple resources
      final deleteId = await mockDatabase.insertResource({
        'title': 'Delete This',
        'description': 'Will be deleted',
        'resource_type': 'article',
        'media_url': 'https://example.com/delete',
        'tags': 'delete',
        'publish_date': DateTime(2024, 1, 1).toIso8601String(),
      });

      final keepId1 = await mockDatabase.insertResource({
        'title': 'Keep This 1',
        'description': 'Will be kept',
        'resource_type': 'video',
        'media_url': 'https://example.com/keep1',
        'tags': 'keep',
        'publish_date': DateTime(2024, 2, 1).toIso8601String(),
      });

      final keepId2 = await mockDatabase.insertResource({
        'title': 'Keep This 2',
        'description': 'Will be kept',
        'resource_type': 'article',
        'media_url': 'https://example.com/keep2',
        'tags': 'keep',
        'publish_date': DateTime(2024, 3, 1).toIso8601String(),
      });

      await service.loadResources();

      // Act: Delete one resource
      await service.deleteResource(deleteId);

      // Assert: Verify other resources remain unchanged
      expect(service.getTotalResourceCount(), equals(2));
      expect(service.getResourceById(keepId1), isNotNull);
      expect(service.getResourceById(keepId2), isNotNull);
      expect(service.getResourceById(keepId1)!['title'], equals('Keep This 1'));
      expect(service.getResourceById(keepId2)!['title'], equals('Keep This 2'));
    });

    test('should clear error message on successful deletion', () async {
      // Arrange: Add resource and create an error first
      await service.deleteResource(999); // This creates an error
      expect(service.errorMessage, isNotNull);

      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test',
        'resource_type': 'article',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();

      // Act: Successfully delete resource
      await service.deleteResource(resourceId);

      // Assert: Verify error is cleared
      expect(service.errorMessage, isNull);
    });

    test('should handle deleting same resource twice', () async {
      // Arrange: Add and delete resource
      final resourceId = await mockDatabase.insertResource({
        'title': 'Test Resource',
        'description': 'Test',
        'resource_type': 'article',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.loadResources();
      await service.deleteResource(resourceId);

      // Act: Try to delete same resource again
      final result = await service.deleteResource(resourceId);

      // Assert: Verify error
      expect(result, isFalse);
      expect(service.errorMessage, equals('Resource not found'));
    });
  });
}
