import 'package:flutter_test/flutter_test.dart';

/// MHR-MHR-04: Admin Add Mental Health Resource
/// 
/// This test validates that an admin can successfully add a new mental health resource
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

// Service for admin adding resources
class AdminResourceAddService {
  final MockMentalHealthResourceDatabase database;
  
  List<Map<String, dynamic>> resources = [];
  bool isLoading = false;
  String? errorMessage;

  AdminResourceAddService(this.database);

  // Load resources
  Future<void> loadResources() async {
    resources = await database.getAllResources();
  }

  // Add new resource
  Future<bool> addResource({
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
      await database.insertResource({
        'title': title.trim(),
        'description': description.trim(),
        'resource_type': resourceType,
        'media_url': mediaUrl?.trim() ?? '',
        'tags': tags?.trim() ?? '',
        'publish_date': (publishDate ?? DateTime.now()).toIso8601String(),
      });

      await loadResources();
      return true;
    } catch (e) {
      errorMessage = 'Failed to add resource';
      return false;
    }
  }

  // Helper methods
  int getTotalResourceCount() => resources.length;
  
  int getVideoCount() => resources.where((r) => r['resource_type'] == 'video').length;
  
  int getArticleCount() => resources.where((r) => r['resource_type'] == 'article').length;

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
  group('MHR-MHR-04: Admin Add Mental Health Resource', () {
    late MockMentalHealthResourceDatabase mockDatabase;
    late AdminResourceAddService service;

    setUp(() {
      mockDatabase = MockMentalHealthResourceDatabase();
      service = AdminResourceAddService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('should successfully add new article resource', () async {
      // Act: Add article
      final result = await service.addResource(
        title: 'New Article',
        description: 'Article content',
        resourceType: 'article',
        mediaUrl: 'https://example.com/article',
        tags: 'test, article',
        publishDate: DateTime.now(),
      );

      // Assert: Verify resource was added
      expect(result, isTrue);
      expect(service.getTotalResourceCount(), equals(1));
      expect(service.resources[0]['title'], equals('New Article'));
      expect(service.resources[0]['resource_type'], equals('article'));
      expect(service.errorMessage, isNull);
    });

    test('should successfully add new video resource', () async {
      // Act: Add video
      final result = await service.addResource(
        title: 'New Video',
        description: 'Video content',
        resourceType: 'video',
        mediaUrl: 'https://youtube.com/video',
        tags: 'test, video',
        publishDate: DateTime.now(),
      );

      // Assert: Verify resource was added
      expect(result, isTrue);
      expect(service.getTotalResourceCount(), equals(1));
      expect(service.resources[0]['title'], equals('New Video'));
      expect(service.resources[0]['resource_type'], equals('video'));
    });

    test('should trim whitespace from title and description', () async {
      // Act: Add resource with whitespace
      await service.addResource(
        title: '  Trimmed Title  ',
        description: '  Trimmed Description  ',
        resourceType: 'article',
      );

      // Assert: Verify whitespace is trimmed
      expect(service.resources[0]['title'], equals('Trimmed Title'));
      expect(service.resources[0]['description'], equals('Trimmed Description'));
    });

    test('should reject empty title', () async {
      // Act: Try to add resource with empty title
      final result = await service.addResource(
        title: '',
        description: 'Valid description',
        resourceType: 'article',
      );

      // Assert: Verify rejection
      expect(result, isFalse);
      expect(service.errorMessage, equals('Please enter a title'));
      expect(service.getTotalResourceCount(), equals(0));
    });

    test('should reject whitespace-only title', () async {
      // Act: Try to add resource with whitespace-only title
      final result = await service.addResource(
        title: '   ',
        description: 'Valid description',
        resourceType: 'article',
      );

      // Assert: Verify rejection
      expect(result, isFalse);
      expect(service.errorMessage, equals('Please enter a title'));
      expect(service.getTotalResourceCount(), equals(0));
    });

    test('should reject empty description', () async {
      // Act: Try to add resource with empty description
      final result = await service.addResource(
        title: 'Valid Title',
        description: '',
        resourceType: 'article',
      );

      // Assert: Verify rejection
      expect(result, isFalse);
      expect(service.errorMessage, equals('Please enter content'));
      expect(service.getTotalResourceCount(), equals(0));
    });

    test('should reject whitespace-only description', () async {
      // Act: Try to add resource with whitespace-only description
      final result = await service.addResource(
        title: 'Valid Title',
        description: '   ',
        resourceType: 'article',
      );

      // Assert: Verify rejection
      expect(result, isFalse);
      expect(service.errorMessage, equals('Please enter content'));
      expect(service.getTotalResourceCount(), equals(0));
    });

    test('should reject invalid resource type', () async {
      // Act: Try to add resource with invalid type
      final result = await service.addResource(
        title: 'Valid Title',
        description: 'Valid description',
        resourceType: 'invalid_type',
      );

      // Assert: Verify rejection
      expect(result, isFalse);
      expect(service.errorMessage, equals('Invalid resource type'));
      expect(service.getTotalResourceCount(), equals(0));
    });

    test('should use default publish date if not provided', () async {
      // Act: Add resource without publish date
      await service.addResource(
        title: 'Test Resource',
        description: 'Test description',
        resourceType: 'article',
      );

      // Assert: Verify publish date is set
      expect(service.resources[0]['publish_date'], isNotEmpty);
      final publishDate = DateTime.tryParse(service.resources[0]['publish_date']);
      expect(publishDate, isNotNull);
    });

    test('should handle optional media URL', () async {
      // Act: Add resource without media URL
      await service.addResource(
        title: 'Test Resource',
        description: 'Test description',
        resourceType: 'article',
      );

      // Assert: Verify media URL is empty string
      expect(service.resources[0]['media_url'], equals(''));
    });

    test('should handle optional tags', () async {
      // Act: Add resource without tags
      await service.addResource(
        title: 'Test Resource',
        description: 'Test description',
        resourceType: 'article',
      );

      // Assert: Verify tags is empty string
      expect(service.resources[0]['tags'], equals(''));
    });

    test('should add multiple resources', () async {
      // Act: Add multiple resources
      await service.addResource(
        title: 'Resource 1',
        description: 'Description 1',
        resourceType: 'article',
      );

      await service.addResource(
        title: 'Resource 2',
        description: 'Description 2',
        resourceType: 'video',
      );

      // Assert: Verify all resources are added
      expect(service.getTotalResourceCount(), equals(2));
    });

    test('should auto-generate resource ID', () async {
      // Act: Add resources
      await service.addResource(
        title: 'Resource 1',
        description: 'Description 1',
        resourceType: 'article',
      );

      await service.addResource(
        title: 'Resource 2',
        description: 'Description 2',
        resourceType: 'video',
      );

      // Assert: Verify IDs are unique
      expect(service.resources[0]['resource_id'], isNotNull);
      expect(service.resources[1]['resource_id'], isNotNull);
      expect(service.resources[0]['resource_id'], 
             isNot(equals(service.resources[1]['resource_id'])));
    });

    test('should store all provided fields correctly', () async {
      // Arrange: Prepare resource data
      final testDate = DateTime(2024, 5, 15);
      
      // Act: Add resource with all fields
      await service.addResource(
        title: 'Complete Resource',
        description: 'Full description',
        resourceType: 'video',
        mediaUrl: 'https://youtube.com/complete',
        tags: 'complete, test, full',
        publishDate: testDate,
      );

      // Assert: Verify all fields are stored correctly
      final resource = service.resources[0];
      expect(resource['title'], equals('Complete Resource'));
      expect(resource['description'], equals('Full description'));
      expect(resource['resource_type'], equals('video'));
      expect(resource['media_url'], equals('https://youtube.com/complete'));
      expect(resource['tags'], equals('complete, test, full'));
      expect(resource['publish_date'], equals(testDate.toIso8601String()));
    });

    test('should trim whitespace from optional fields', () async {
      // Act: Add resource with whitespace in optional fields
      await service.addResource(
        title: 'Test Resource',
        description: 'Test description',
        resourceType: 'article',
        mediaUrl: '  https://example.com/test  ',
        tags: '  tag1, tag2  ',
      );

      // Assert: Verify whitespace is trimmed
      expect(service.resources[0]['media_url'], equals('https://example.com/test'));
      expect(service.resources[0]['tags'], equals('tag1, tag2'));
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

    test('should update count statistics after adding', () async {
      // Act: Add mixed resources
      await service.addResource(
        title: 'Article 1',
        description: 'Article',
        resourceType: 'article',
      );

      await service.addResource(
        title: 'Video 1',
        description: 'Video',
        resourceType: 'video',
      );

      await service.addResource(
        title: 'Article 2',
        description: 'Article',
        resourceType: 'article',
      );

      // Assert: Verify statistics
      expect(service.getTotalResourceCount(), equals(3));
      expect(service.getArticleCount(), equals(2));
      expect(service.getVideoCount(), equals(1));
    });
  });
}
