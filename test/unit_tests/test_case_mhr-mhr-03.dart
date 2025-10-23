import 'package:flutter_test/flutter_test.dart';

/// MHR-MHR-03: Admin View All Mental Health Resources
/// 
/// This test validates that an admin can view all existing mental health resources
/// with proper ordering, filtering, and search functionality.
///
/// Database Schema:
/// - mental_health_resources table with fields:
///   - resource_id (PK), title, description, resource_type, media_url, tags, publish_date

// Mock Database for Mental Health Resources
class MockMentalHealthResourceDatabase {
  final List<Map<String, dynamic>> _resources = [];
  int _nextId = 1;

  // Get all resources ordered by publish_date (descending)
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

  // Insert new resource
  Future<int> insertResource(Map<String, dynamic> resource) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final newResource = Map<String, dynamic>.from(resource);
    newResource['resource_id'] = _nextId++;
    _resources.add(newResource);
    return newResource['resource_id'] as int;
  }

  void clear() {
    _resources.clear();
    _nextId = 1;
  }

  int get resourceCount => _resources.length;
}

// Service for admin viewing resources
class AdminResourceViewService {
  final MockMentalHealthResourceDatabase database;
  
  List<Map<String, dynamic>> resources = [];
  List<Map<String, dynamic>> filteredResources = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  String filterType = 'all'; // all, article, video

  AdminResourceViewService(this.database);

  // View all resources
  Future<void> loadResources() async {
    isLoading = true;
    errorMessage = null;

    try {
      resources = await database.getAllResources();
      applyFilters();
      isLoading = false;
    } catch (e) {
      errorMessage = 'Failed to load resources';
      isLoading = false;
      rethrow;
    }
  }

  // Apply search and filter
  void applyFilters() {
    filteredResources = resources.where((resource) {
      // Type filter
      final matchesType = filterType == 'all' || 
          resource['resource_type']?.toLowerCase() == filterType;
      
      // Search filter
      final search = searchQuery.toLowerCase();
      final matchesSearch = search.isEmpty ||
          (resource['title']?.toLowerCase().contains(search) ?? false) ||
          (resource['tags']?.toLowerCase().contains(search) ?? false);
      
      return matchesType && matchesSearch;
    }).toList();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    applyFilters();
  }

  void setFilterType(String type) {
    filterType = type;
    applyFilters();
  }

  // Helper methods
  int getTotalResourceCount() => resources.length;
  
  int getFilteredResourceCount() => filteredResources.length;
  
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
  group('MHR-MHR-03: Admin View All Mental Health Resources', () {
    late MockMentalHealthResourceDatabase mockDatabase;
    late AdminResourceViewService service;

    setUp(() {
      mockDatabase = MockMentalHealthResourceDatabase();
      service = AdminResourceViewService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('should load all resources successfully', () async {
      // Arrange: Add test resources
      await mockDatabase.insertResource({
        'title': 'Anxiety Management',
        'description': 'Guide to managing anxiety',
        'resource_type': 'article',
        'media_url': 'https://example.com/anxiety',
        'tags': 'anxiety, mental health',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'title': 'Meditation Video',
        'description': 'Guided meditation',
        'resource_type': 'video',
        'media_url': 'https://youtube.com/meditation',
        'tags': 'meditation',
        'publish_date': DateTime.now().toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify resources are loaded
      expect(service.isLoading, isFalse);
      expect(service.getTotalResourceCount(), equals(2));
      expect(service.errorMessage, isNull);
    });

    test('should display all resource properties', () async {
      // Arrange: Add complete resource
      await mockDatabase.insertResource({
        'title': 'Complete Resource',
        'description': 'Full resource details',
        'resource_type': 'video',
        'media_url': 'https://example.com/complete',
        'tags': 'complete, test',
        'publish_date': DateTime(2024, 1, 15).toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify all properties are displayed
      final resource = service.resources.first;
      expect(resource['resource_id'], isNotNull);
      expect(resource['title'], equals('Complete Resource'));
      expect(resource['description'], equals('Full resource details'));
      expect(resource['resource_type'], equals('video'));
      expect(resource['media_url'], equals('https://example.com/complete'));
      expect(resource['tags'], equals('complete, test'));
      expect(resource['publish_date'], isNotEmpty);
    });

    test('should order resources by publish date descending', () async {
      // Arrange: Add resources with different dates
      await mockDatabase.insertResource({
        'title': 'Old Resource',
        'description': 'Oldest',
        'resource_type': 'article',
        'media_url': 'https://example.com/old',
        'tags': 'old',
        'publish_date': DateTime(2023, 1, 1).toIso8601String(),
      });

      await mockDatabase.insertResource({
        'title': 'New Resource',
        'description': 'Newest',
        'resource_type': 'video',
        'media_url': 'https://example.com/new',
        'tags': 'new',
        'publish_date': DateTime(2024, 12, 31).toIso8601String(),
      });

      await mockDatabase.insertResource({
        'title': 'Middle Resource',
        'description': 'Middle',
        'resource_type': 'article',
        'media_url': 'https://example.com/middle',
        'tags': 'middle',
        'publish_date': DateTime(2024, 6, 15).toIso8601String(),
      });

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify descending order
      expect(service.resources[0]['title'], equals('New Resource'));
      expect(service.resources[1]['title'], equals('Middle Resource'));
      expect(service.resources[2]['title'], equals('Old Resource'));
    });

    test('should handle empty resource list', () async {
      // Arrange: No resources

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify empty state
      expect(service.getTotalResourceCount(), equals(0));
      expect(service.resources, isEmpty);
      expect(service.isLoading, isFalse);
    });

    test('should filter resources by type - articles', () async {
      // Arrange: Add mixed resources
      await mockDatabase.insertResource({
        'title': 'Article 1',
        'description': 'Article content',
        'resource_type': 'article',
        'media_url': 'https://example.com/article1',
        'tags': 'article',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'title': 'Video 1',
        'description': 'Video content',
        'resource_type': 'video',
        'media_url': 'https://example.com/video1',
        'tags': 'video',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await service.loadResources();

      // Act: Filter by article
      service.setFilterType('article');

      // Assert: Verify only articles are shown
      expect(service.getFilteredResourceCount(), equals(1));
      expect(service.filteredResources[0]['resource_type'], equals('article'));
    });

    test('should filter resources by type - videos', () async {
      // Arrange: Add mixed resources
      await mockDatabase.insertResource({
        'title': 'Article 1',
        'description': 'Article content',
        'resource_type': 'article',
        'media_url': 'https://example.com/article1',
        'tags': 'article',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'title': 'Video 1',
        'description': 'Video content',
        'resource_type': 'video',
        'media_url': 'https://example.com/video1',
        'tags': 'video',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await service.loadResources();

      // Act: Filter by video
      service.setFilterType('video');

      // Assert: Verify only videos are shown
      expect(service.getFilteredResourceCount(), equals(1));
      expect(service.filteredResources[0]['resource_type'], equals('video'));
    });

    test('should search resources by title', () async {
      // Arrange: Add resources
      await mockDatabase.insertResource({
        'title': 'Anxiety Management',
        'description': 'Anxiety guide',
        'resource_type': 'article',
        'media_url': 'https://example.com/anxiety',
        'tags': 'anxiety',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'title': 'Meditation Guide',
        'description': 'Meditation tips',
        'resource_type': 'video',
        'media_url': 'https://example.com/meditation',
        'tags': 'meditation',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await service.loadResources();

      // Act: Search by title
      service.setSearchQuery('anxiety');

      // Assert: Verify search results
      expect(service.getFilteredResourceCount(), equals(1));
      expect(service.filteredResources[0]['title'], equals('Anxiety Management'));
    });

    test('should search resources by tags', () async {
      // Arrange: Add resources
      await mockDatabase.insertResource({
        'title': 'Resource 1',
        'description': 'Content 1',
        'resource_type': 'article',
        'media_url': 'https://example.com/r1',
        'tags': 'depression, mental health',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await mockDatabase.insertResource({
        'title': 'Resource 2',
        'description': 'Content 2',
        'resource_type': 'video',
        'media_url': 'https://example.com/r2',
        'tags': 'anxiety, stress',
        'publish_date': DateTime.now().toIso8601String(),
      });

      await service.loadResources();

      // Act: Search by tag
      service.setSearchQuery('depression');

      // Assert: Verify search results
      expect(service.getFilteredResourceCount(), equals(1));
      expect(service.filteredResources[0]['tags'], contains('depression'));
    });

    test('should show resource count statistics', () async {
      // Arrange: Add mixed resources
      for (int i = 1; i <= 3; i++) {
        await mockDatabase.insertResource({
          'title': 'Article $i',
          'description': 'Article content',
          'resource_type': 'article',
          'media_url': 'https://example.com/article$i',
          'tags': 'article',
          'publish_date': DateTime.now().toIso8601String(),
        });
      }

      for (int i = 1; i <= 2; i++) {
        await mockDatabase.insertResource({
          'title': 'Video $i',
          'description': 'Video content',
          'resource_type': 'video',
          'media_url': 'https://example.com/video$i',
          'tags': 'video',
          'publish_date': DateTime.now().toIso8601String(),
        });
      }

      // Act: Load resources
      await service.loadResources();

      // Assert: Verify statistics
      expect(service.getTotalResourceCount(), equals(5));
      expect(service.getArticleCount(), equals(3));
      expect(service.getVideoCount(), equals(2));
    });
  });
}
