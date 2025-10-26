import 'package:flutter_test/flutter_test.dart';

/// MHR-MHR-02: Student Select Mental Health Resource
/// 
/// This test validates that a student can select a specific mental health resource
/// and be redirected to the link attached to it.
///
/// Database Schema:
/// - mental_health_resources table with fields:
///   - resource_id (PK), title, description, resource_type, media_url, tags, publish_date

// Mock Database for Mental Health Resources
class MockMentalHealthResourceDatabase {
  final List<Map<String, dynamic>> _resources = [];

  Future<Map<String, dynamic>?> getResourceById(int resourceId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _resources.firstWhere(
        (resource) => resource['resource_id'] == resourceId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> insertResource(Map<String, dynamic> resource) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _resources.add(resource);
  }

  void clear() {
    _resources.clear();
  }
}

// Mock URL Launcher Service
class MockUrlLauncherService {
  String? lastLaunchedUrl;
  bool shouldSucceed = true;
  bool canLaunch = true;

  Future<bool> canLaunchUrl(String url) async {
    await Future.delayed(const Duration(milliseconds: 20));
    return canLaunch;
  }

  Future<bool> launchUrl(String url) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (shouldSucceed && canLaunch) {
      lastLaunchedUrl = url;
      return true;
    }
    return false;
  }

  void reset() {
    lastLaunchedUrl = null;
    shouldSucceed = true;
    canLaunch = true;
  }
}

// Service to handle student selecting and launching resources
class StudentResourceSelectionService {
  final MockMentalHealthResourceDatabase database;
  final MockUrlLauncherService urlLauncher;
  
  Map<String, dynamic>? selectedResource;
  String? errorMessage;

  StudentResourceSelectionService(this.database, this.urlLauncher);

  // Select a resource by ID
  Future<bool> selectResource(int resourceId) async {
    errorMessage = null;
    
    try {
      final resource = await database.getResourceById(resourceId);
      
      if (resource == null) {
        errorMessage = 'Resource not found';
        return false;
      }
      
      selectedResource = resource;
      return true;
    } catch (e) {
      errorMessage = 'Error selecting resource';
      return false;
    }
  }

  // Launch the URL of the selected resource
  Future<bool> launchResourceUrl() async {
    if (selectedResource == null) {
      errorMessage = 'No resource selected';
      return false;
    }

    final url = selectedResource!['media_url'] as String?;
    
    if (url == null || url.isEmpty) {
      errorMessage = 'Invalid URL';
      return false;
    }

    try {
      final canLaunch = await urlLauncher.canLaunchUrl(url);
      
      if (!canLaunch) {
        errorMessage = 'Could not open the link';
        return false;
      }

      final launched = await urlLauncher.launchUrl(url);
      
      if (!launched) {
        errorMessage = 'Failed to launch URL';
        return false;
      }

      return true;
    } catch (e) {
      errorMessage = 'Error launching URL';
      return false;
    }
  }

  // Select and launch in one operation (typical user flow)
  Future<bool> selectAndLaunchResource(int resourceId) async {
    final selected = await selectResource(resourceId);
    if (!selected) {
      return false;
    }
    
    return await launchResourceUrl();
  }

  // Get the URL of the selected resource
  String? getSelectedResourceUrl() {
    return selectedResource?['media_url'] as String?;
  }

  // Check if resource has a valid URL
  bool hasValidUrl() {
    final url = selectedResource?['media_url'] as String?;
    return url != null && url.isNotEmpty;
  }

  // Validate URL format (basic validation)
  bool isValidUrlFormat(String url) {
    if (url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }
}

void main() {
  group('MHR-MHR-02: Student Select Mental Health Resource', () {
    late MockMentalHealthResourceDatabase mockDatabase;
    late MockUrlLauncherService mockUrlLauncher;
    late StudentResourceSelectionService service;

    setUp(() {
      mockDatabase = MockMentalHealthResourceDatabase();
      mockUrlLauncher = MockUrlLauncherService();
      service = StudentResourceSelectionService(mockDatabase, mockUrlLauncher);
    });

    tearDown(() {
      mockDatabase.clear();
      mockUrlLauncher.reset();
    });

    test('should successfully select a resource by ID', () async {
      // Arrange: Add resource to database
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Stress Management Video',
        'description': 'Learn stress management techniques',
        'resource_type': 'video',
        'media_url': 'https://youtube.com/watch?v=stress123',
        'tags': 'stress, coping',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Select resource
      final result = await service.selectResource(1);

      // Assert: Verify resource is selected
      expect(result, isTrue);
      expect(service.selectedResource, isNotNull);
      expect(service.selectedResource!['resource_id'], equals(1));
      expect(service.selectedResource!['title'], equals('Stress Management Video'));
      expect(service.errorMessage, isNull);
    });

    test('should launch URL when resource is selected', () async {
      // Arrange: Add resource and select it
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Meditation Guide',
        'description': 'Guided meditation video',
        'resource_type': 'video',
        'media_url': 'https://example.com/meditation',
        'tags': 'meditation',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.selectResource(1);

      // Act: Launch URL
      final result = await service.launchResourceUrl();

      // Assert: Verify URL was launched
      expect(result, isTrue);
      expect(mockUrlLauncher.lastLaunchedUrl, equals('https://example.com/meditation'));
      expect(service.errorMessage, isNull);
    });

    test('should redirect to YouTube video URL', () async {
      // Arrange: Add YouTube video resource
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Breathing Exercises',
        'description': 'Breathing techniques video',
        'resource_type': 'video',
        'media_url': 'https://youtube.com/watch?v=breathing123',
        'tags': 'breathing',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Select and launch resource
      final result = await service.selectAndLaunchResource(1);

      // Assert: Verify YouTube URL was launched
      expect(result, isTrue);
      expect(mockUrlLauncher.lastLaunchedUrl, equals('https://youtube.com/watch?v=breathing123'));
    });

    test('should redirect to article URL', () async {
      // Arrange: Add article resource
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Mental Health Tips',
        'description': 'Top 10 mental health tips',
        'resource_type': 'article',
        'media_url': 'https://example.com/articles/mental-health-tips',
        'tags': 'tips',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Select and launch resource
      final result = await service.selectAndLaunchResource(1);

      // Assert: Verify article URL was launched
      expect(result, isTrue);
      expect(mockUrlLauncher.lastLaunchedUrl, equals('https://example.com/articles/mental-health-tips'));
    });

    test('should handle non-existent resource selection', () async {
      // Arrange: No resources in database

      // Act: Try to select non-existent resource
      final result = await service.selectResource(999);

      // Assert: Verify error is handled
      expect(result, isFalse);
      expect(service.selectedResource, isNull);
      expect(service.errorMessage, equals('Resource not found'));
    });

    test('should handle resource with empty URL', () async {
      // Arrange: Add resource with empty URL
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Resource Without URL',
        'description': 'Test resource',
        'resource_type': 'article',
        'media_url': '',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.selectResource(1);

      // Act: Try to launch URL
      final result = await service.launchResourceUrl();

      // Assert: Verify error is handled
      expect(result, isFalse);
      expect(service.errorMessage, equals('Invalid URL'));
    });

    test('should handle resource with null URL', () async {
      // Arrange: Add resource with null URL
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Resource Without URL',
        'description': 'Test resource',
        'resource_type': 'article',
        'media_url': null,
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.selectResource(1);

      // Act: Try to launch URL
      final result = await service.launchResourceUrl();

      // Assert: Verify error is handled
      expect(result, isFalse);
      expect(service.errorMessage, equals('Invalid URL'));
    });

    test('should show error when URL cannot be launched', () async {
      // Arrange: Add resource and set URL launcher to fail
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Test Resource',
        'description': 'Test',
        'resource_type': 'video',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.selectResource(1);
      mockUrlLauncher.canLaunch = false;

      // Act: Try to launch URL
      final result = await service.launchResourceUrl();

      // Assert: Verify error message
      expect(result, isFalse);
      expect(service.errorMessage, equals('Could not open the link'));
    });

    test('should get selected resource URL', () async {
      // Arrange: Add and select resource
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Test Resource',
        'description': 'Test',
        'resource_type': 'video',
        'media_url': 'https://example.com/resource',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.selectResource(1);

      // Act: Get URL
      final url = service.getSelectedResourceUrl();

      // Assert: Verify URL is returned
      expect(url, equals('https://example.com/resource'));
    });

    test('should validate that selected resource has URL', () async {
      // Arrange: Add resource with URL
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Valid Resource',
        'description': 'Has URL',
        'resource_type': 'video',
        'media_url': 'https://example.com/valid',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.selectResource(1);

      // Act: Check if has valid URL
      final hasUrl = service.hasValidUrl();

      // Assert: Verify URL is valid
      expect(hasUrl, isTrue);
    });

    test('should detect resource without valid URL', () async {
      // Arrange: Add resource without URL
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Invalid Resource',
        'description': 'No URL',
        'resource_type': 'article',
        'media_url': '',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.selectResource(1);

      // Act: Check if has valid URL
      final hasUrl = service.hasValidUrl();

      // Assert: Verify URL is invalid
      expect(hasUrl, isFalse);
    });

    test('should handle multiple resource selections', () async {
      // Arrange: Add multiple resources
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Resource 1',
        'description': 'First resource',
        'resource_type': 'video',
        'media_url': 'https://example.com/resource1',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await mockDatabase.insertResource({
        'resource_id': 2,
        'title': 'Resource 2',
        'description': 'Second resource',
        'resource_type': 'article',
        'media_url': 'https://example.com/resource2',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Select first resource
      await service.selectResource(1);
      expect(service.selectedResource!['resource_id'], equals(1));

      // Act: Select second resource
      await service.selectResource(2);

      // Assert: Verify second resource is now selected
      expect(service.selectedResource!['resource_id'], equals(2));
      expect(service.selectedResource!['title'], equals('Resource 2'));
    });

    test('should validate HTTP URL format', () {
      // Arrange & Act & Assert: Test HTTP URLs
      expect(service.isValidUrlFormat('http://example.com'), isTrue);
      expect(service.isValidUrlFormat('https://example.com'), isTrue);
      expect(service.isValidUrlFormat('ftp://example.com'), isFalse);
      expect(service.isValidUrlFormat('example.com'), isFalse);
      expect(service.isValidUrlFormat(''), isFalse);
    });

    test('should launch different types of resource URLs', () async {
      // Arrange: Test with video
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Video Resource',
        'description': 'Video',
        'resource_type': 'video',
        'media_url': 'https://youtube.com/watch?v=abc123',
        'tags': 'video',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Launch video
      await service.selectAndLaunchResource(1);
      expect(mockUrlLauncher.lastLaunchedUrl, equals('https://youtube.com/watch?v=abc123'));

      // Arrange: Test with article
      await mockDatabase.insertResource({
        'resource_id': 2,
        'title': 'Article Resource',
        'description': 'Article',
        'resource_type': 'article',
        'media_url': 'https://blog.example.com/article',
        'tags': 'article',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Launch article
      await service.selectAndLaunchResource(2);

      // Assert: Verify article URL was launched
      expect(mockUrlLauncher.lastLaunchedUrl, equals('https://blog.example.com/article'));
    });

    test('should maintain resource details after selection', () async {
      // Arrange: Add resource with all details
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Complete Resource',
        'description': 'Full resource with all details',
        'resource_type': 'video',
        'media_url': 'https://example.com/complete',
        'tags': 'complete, test, full',
        'publish_date': DateTime(2024, 1, 15).toIso8601String(),
      });

      // Act: Select resource
      await service.selectResource(1);

      // Assert: Verify all details are maintained
      expect(service.selectedResource!['title'], equals('Complete Resource'));
      expect(service.selectedResource!['description'], equals('Full resource with all details'));
      expect(service.selectedResource!['resource_type'], equals('video'));
      expect(service.selectedResource!['media_url'], equals('https://example.com/complete'));
      expect(service.selectedResource!['tags'], equals('complete, test, full'));
    });

    test('should handle URL launch failure gracefully', () async {
      // Arrange: Add resource and configure launcher to fail
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Test Resource',
        'description': 'Test',
        'resource_type': 'video',
        'media_url': 'https://example.com/test',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await service.selectResource(1);
      mockUrlLauncher.shouldSucceed = false;

      // Act: Try to launch URL
      final result = await service.launchResourceUrl();

      // Assert: Verify failure is handled
      expect(result, isFalse);
      expect(service.errorMessage, equals('Failed to launch URL'));
    });

    test('should prevent launching URL without selecting resource', () async {
      // Arrange: No resource selected

      // Act: Try to launch URL without selection
      final result = await service.launchResourceUrl();

      // Assert: Verify error is shown
      expect(result, isFalse);
      expect(service.errorMessage, equals('No resource selected'));
    });

    test('should track last launched URL', () async {
      // Arrange: Add resources
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'First Resource',
        'description': 'First',
        'resource_type': 'video',
        'media_url': 'https://example.com/first',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });
      await mockDatabase.insertResource({
        'resource_id': 2,
        'title': 'Second Resource',
        'description': 'Second',
        'resource_type': 'article',
        'media_url': 'https://example.com/second',
        'tags': 'test',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Launch first resource
      await service.selectAndLaunchResource(1);
      expect(mockUrlLauncher.lastLaunchedUrl, equals('https://example.com/first'));

      // Act: Launch second resource
      await service.selectAndLaunchResource(2);

      // Assert: Verify last launched URL is updated
      expect(mockUrlLauncher.lastLaunchedUrl, equals('https://example.com/second'));
    });
  });
}
