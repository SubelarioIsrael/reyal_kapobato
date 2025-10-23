import 'package:flutter_test/flutter_test.dart';

/// MHR-MHR-01: Student View Mental Health Resources
/// 
/// This test validates that a logged-in student can view all available
/// mental health resources (videos and articles) with proper categorization.
///
/// Database Schema:
/// - mental_health_resources table with fields:
///   - resource_id (PK), title, description, resource_type, media_url, tags, publish_date

// Mock Database for Mental Health Resources
class MockMentalHealthResourceDatabase {
  final List<Map<String, dynamic>> _resources = [];

  // Simulate database query to get all resources ordered by title
  Future<List<Map<String, dynamic>>> getAllResources() async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Return resources ordered by title
    final sorted = List<Map<String, dynamic>>.from(_resources);
    sorted.sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
    return sorted;
  }

  // Simulate inserting a resource into the database
  Future<void> insertResource(Map<String, dynamic> resource) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _resources.add(resource);
  }

  // Clear all resources (for test cleanup)
  void clear() {
    _resources.clear();
  }

  // Get count of resources
  int get resourceCount => _resources.length;
}

// Service to handle student viewing mental health resources
class StudentMentalHealthResourceViewService {
  final MockMentalHealthResourceDatabase database;
  
  List<Map<String, dynamic>> videos = [];
  List<Map<String, dynamic>> articles = [];
  bool isLoading = false;
  String? errorMessage;

  StudentMentalHealthResourceViewService(this.database);

  // Load all resources and categorize them
  Future<void> loadResources() async {
    isLoading = true;
    errorMessage = null;

    try {
      final resources = await database.getAllResources();
      
      videos = resources
          .where((resource) => resource['resource_type'] == 'video')
          .toList();
      
      articles = resources
          .where((resource) => resource['resource_type'] == 'article')
          .toList();
      
      isLoading = false;
    } catch (e) {
      errorMessage = 'Error loading resources. Please try again later.';
      isLoading = false;
      rethrow;
    }
  }

  // Get total count of resources
  int getTotalResourceCount() {
    return videos.length + articles.length;
  }

  // Get count of videos
  int getVideoCount() {
    return videos.length;
  }

  // Get count of articles
  int getArticleCount() {
    return articles.length;
  }

  // Check if a specific resource exists
  bool hasResource(String title) {
    return videos.any((v) => v['title'] == title) ||
           articles.any((a) => a['title'] == title);
  }

  // Get resource by title
  Map<String, dynamic>? getResourceByTitle(String title) {
    try {
      return videos.firstWhere((v) => v['title'] == title);
    } catch (e) {
      try {
        return articles.firstWhere((a) => a['title'] == title);
      } catch (e) {
        return null;
      }
    }
  }

  // Check if resources are categorized correctly
  bool areResourcesCategorizedCorrectly() {
    // Check videos
    for (var video in videos) {
      if (video['resource_type'] != 'video') {
        return false;
      }
    }
    
    // Check articles
    for (var article in articles) {
      if (article['resource_type'] != 'article') {
        return false;
      }
    }
    
    return true;
  }
}

void main() {
  group('MHR-MHR-01: Student View Mental Health Resources', () {
    late MockMentalHealthResourceDatabase mockDatabase;
    late StudentMentalHealthResourceViewService service;

    setUp(() {
      mockDatabase = MockMentalHealthResourceDatabase();
      service = StudentMentalHealthResourceViewService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('should load all mental health resources successfully', () async {
      // Arrange: Add test resources to database
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Understanding Anxiety',
        'description': 'A comprehensive guide to understanding anxiety',
        'resource_type': 'article',
        'media_url': 'https://example.com/anxiety-article',
        'tags': 'anxiety, mental health',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'resource_id': 2,
        'title': 'Meditation Techniques',
        'description': 'Learn effective meditation techniques',
        'resource_type': 'video',
        'media_url': 'https://example.com/meditation-video',
        'tags': 'meditation, relaxation',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify resources are loaded
      expect(service.isLoading, isFalse);
      expect(service.getTotalResourceCount(), equals(2));
      expect(service.errorMessage, isNull);
    });

    test('should categorize resources into videos and articles correctly', () async {
      // Arrange: Add resources of different types
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Breathing Exercises',
        'description': 'Video guide for breathing exercises',
        'resource_type': 'video',
        'media_url': 'https://example.com/breathing-video',
        'tags': 'breathing, stress',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'resource_id': 2,
        'title': 'Depression Guide',
        'description': 'Article about understanding depression',
        'resource_type': 'article',
        'media_url': 'https://example.com/depression-article',
        'tags': 'depression, mental health',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'resource_id': 3,
        'title': 'Mindfulness Practice',
        'description': 'Video on mindfulness meditation',
        'resource_type': 'video',
        'media_url': 'https://example.com/mindfulness-video',
        'tags': 'mindfulness, meditation',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify categorization
      expect(service.getVideoCount(), equals(2));
      expect(service.getArticleCount(), equals(1));
      expect(service.areResourcesCategorizedCorrectly(), isTrue);
    });

    test('should display video resources with correct properties', () async {
      // Arrange: Add video resource
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Stress Management Video',
        'description': 'Learn how to manage stress effectively',
        'resource_type': 'video',
        'media_url': 'https://example.com/stress-management',
        'tags': 'stress, coping',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify video properties
      expect(service.videos.length, equals(1));
      final video = service.videos.first;
      expect(video['title'], equals('Stress Management Video'));
      expect(video['description'], equals('Learn how to manage stress effectively'));
      expect(video['resource_type'], equals('video'));
      expect(video['media_url'], equals('https://example.com/stress-management'));
      expect(video['tags'], equals('stress, coping'));
    });

    test('should display article resources with correct properties', () async {
      // Arrange: Add article resource
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Mental Health Tips',
        'description': 'Top 10 tips for maintaining mental health',
        'resource_type': 'article',
        'media_url': 'https://example.com/mental-health-tips',
        'tags': 'mental health, tips',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify article properties
      expect(service.articles.length, equals(1));
      final article = service.articles.first;
      expect(article['title'], equals('Mental Health Tips'));
      expect(article['description'], equals('Top 10 tips for maintaining mental health'));
      expect(article['resource_type'], equals('article'));
      expect(article['media_url'], equals('https://example.com/mental-health-tips'));
    });

    test('should handle empty resource list gracefully', () async {
      // Arrange: No resources in database

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify empty state
      expect(service.getTotalResourceCount(), equals(0));
      expect(service.getVideoCount(), equals(0));
      expect(service.getArticleCount(), equals(0));
      expect(service.isLoading, isFalse);
      expect(service.errorMessage, isNull);
    });

    test('should display empty state for videos when no videos exist', () async {
      // Arrange: Add only article resources
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Self-Care Guide',
        'description': 'Article on self-care practices',
        'resource_type': 'article',
        'media_url': 'https://example.com/self-care',
        'tags': 'self-care',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify video section is empty
      expect(service.getVideoCount(), equals(0));
      expect(service.getArticleCount(), equals(1));
      expect(service.videos, isEmpty);
    });

    test('should display empty state for articles when no articles exist', () async {
      // Arrange: Add only video resources
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Relaxation Techniques',
        'description': 'Video on relaxation methods',
        'resource_type': 'video',
        'media_url': 'https://example.com/relaxation',
        'tags': 'relaxation',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify article section is empty
      expect(service.getVideoCount(), equals(1));
      expect(service.getArticleCount(), equals(0));
      expect(service.articles, isEmpty);
    });

    test('should order resources by title', () async {
      // Arrange: Add resources in random order
      await mockDatabase.insertResource({
        'resource_id': 3,
        'title': 'Yoga for Mental Health',
        'description': 'Video on yoga practices',
        'resource_type': 'video',
        'media_url': 'https://example.com/yoga',
        'tags': 'yoga',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Anxiety Management',
        'description': 'Article on anxiety',
        'resource_type': 'article',
        'media_url': 'https://example.com/anxiety',
        'tags': 'anxiety',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'resource_id': 2,
        'title': 'Meditation Guide',
        'description': 'Video guide on meditation',
        'resource_type': 'video',
        'media_url': 'https://example.com/meditation',
        'tags': 'meditation',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify ordering by title - videos and articles are separated
      // Videos ordered by title
      expect(service.videos.length, equals(2));
      expect(service.videos[0]['title'], equals('Meditation Guide'));
      expect(service.videos[1]['title'], equals('Yoga for Mental Health'));
      
      // Articles ordered by title
      expect(service.articles.length, equals(1));
      expect(service.articles[0]['title'], equals('Anxiety Management'));
    });

    test('should display resource with media URL', () async {
      // Arrange: Add resource with media URL
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Stress Relief Video',
        'description': 'Quick stress relief techniques',
        'resource_type': 'video',
        'media_url': 'https://youtube.com/watch?v=example123',
        'tags': 'stress, relief',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify media URL is present
      final resource = service.getResourceByTitle('Stress Relief Video');
      expect(resource, isNotNull);
      expect(resource!['media_url'], equals('https://youtube.com/watch?v=example123'));
      expect(resource['media_url'], isNotEmpty);
    });

    test('should display resource tags correctly', () async {
      // Arrange: Add resource with tags
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Coping Strategies',
        'description': 'Various coping strategies article',
        'resource_type': 'article',
        'media_url': 'https://example.com/coping',
        'tags': 'anxiety, depression, self-care',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify tags are displayed
      final resource = service.getResourceByTitle('Coping Strategies');
      expect(resource, isNotNull);
      expect(resource!['tags'], equals('anxiety, depression, self-care'));
    });

    test('should handle multiple resources of same type', () async {
      // Arrange: Add multiple videos
      for (int i = 1; i <= 5; i++) {
        await mockDatabase.insertResource({
          'resource_id': i,
          'title': 'Video $i',
          'description': 'Description for video $i',
          'resource_type': 'video',
          'media_url': 'https://example.com/video$i',
          'tags': 'tag$i',
          'publish_date': DateTime.now().toIso8601String(),
        });
      }

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify all videos are loaded
      expect(service.getVideoCount(), equals(5));
      expect(service.videos.length, equals(5));
    });

    test('should display publish date for resources', () async {
      // Arrange: Add resource with specific publish date
      final publishDate = DateTime(2024, 1, 15);
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Mental Wellness',
        'description': 'Guide to mental wellness',
        'resource_type': 'article',
        'media_url': 'https://example.com/wellness',
        'tags': 'wellness',
        'publish_date': publishDate.toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify publish date is present
      final resource = service.getResourceByTitle('Mental Wellness');
      expect(resource, isNotNull);
      expect(resource!['publish_date'], equals(publishDate.toIso8601String()));
    });

    test('should find specific resource by title', () async {
      // Arrange: Add multiple resources
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Sleep Hygiene',
        'description': 'Article on sleep hygiene',
        'resource_type': 'article',
        'media_url': 'https://example.com/sleep',
        'tags': 'sleep',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'resource_id': 2,
        'title': 'Exercise Benefits',
        'description': 'Video on exercise and mental health',
        'resource_type': 'video',
        'media_url': 'https://example.com/exercise',
        'tags': 'exercise',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify specific resource can be found
      expect(service.hasResource('Sleep Hygiene'), isTrue);
      expect(service.hasResource('Exercise Benefits'), isTrue);
      expect(service.hasResource('Non-existent Resource'), isFalse);
    });

    test('should handle mixed resource types correctly', () async {
      // Arrange: Add alternating video and article resources
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Resource A',
        'description': 'Article A',
        'resource_type': 'article',
        'media_url': 'https://example.com/a',
        'tags': 'tag-a',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'resource_id': 2,
        'title': 'Resource B',
        'description': 'Video B',
        'resource_type': 'video',
        'media_url': 'https://example.com/b',
        'tags': 'tag-b',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'resource_id': 3,
        'title': 'Resource C',
        'description': 'Article C',
        'resource_type': 'article',
        'media_url': 'https://example.com/c',
        'tags': 'tag-c',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify proper categorization
      expect(service.getVideoCount(), equals(1));
      expect(service.getArticleCount(), equals(2));
      expect(service.getTotalResourceCount(), equals(3));
      expect(service.areResourcesCategorizedCorrectly(), isTrue);
    });

    test('should display all required fields for each resource', () async {
      // Arrange: Add complete resource
      await mockDatabase.insertResource({
        'resource_id': 1,
        'title': 'Complete Resource',
        'description': 'A complete resource with all fields',
        'resource_type': 'video',
        'media_url': 'https://example.com/complete',
        'tags': 'complete, test',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify all fields are present
      final resource = service.videos.first;
      expect(resource.containsKey('resource_id'), isTrue);
      expect(resource.containsKey('title'), isTrue);
      expect(resource.containsKey('description'), isTrue);
      expect(resource.containsKey('resource_type'), isTrue);
      expect(resource.containsKey('media_url'), isTrue);
      expect(resource.containsKey('tags'), isTrue);
      expect(resource.containsKey('publish_date'), isTrue);
    });
  });
}
