// SRM-MHH-02: Admin can view all the mental health hotlines
// Requirement: Admin can view, search, and filter all mental health hotlines in the system
// Mirrors logic in `admin_hotlines.dart` (load, display, search, and filter hotlines)

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent a mental health hotline for admin view
class MockAdminMentalHealthHotline {
  final int hotlineId;
  final String name;
  final String phone;
  final String? cityOrRegion;
  final String? notes;
  final String? profilePicture;
  final DateTime createdAt;

  MockAdminMentalHealthHotline({
    required this.hotlineId,
    required this.name,
    required this.phone,
    this.cityOrRegion,
    this.notes,
    this.profilePicture,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'hotline_id': hotlineId,
      'name': name,
      'phone': phone,
      'city_or_region': cityOrRegion,
      'notes': notes,
      'profile_picture': profilePicture,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MockAdminMentalHealthHotline.fromMap(Map<String, dynamic> map) {
    return MockAdminMentalHealthHotline(
      hotlineId: map['hotline_id'],
      name: map['name'],
      phone: map['phone'],
      cityOrRegion: map['city_or_region'],
      notes: map['notes'],
      profilePicture: map['profile_picture'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

// Mock database class to simulate Supabase operations for admin
class MockAdminDatabase {
  List<Map<String, dynamic>> _mentalHealthHotlines = [];
  bool _shouldThrowError = false;

  void seedMentalHealthHotlines(List<Map<String, dynamic>> hotlines) {
    _mentalHealthHotlines = hotlines;
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  Future<List<Map<String, dynamic>>> fetchMentalHealthHotlines() async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 150));
    
    if (_shouldThrowError) {
      throw Exception('Database connection failed');
    }
    
    // Return ordered by created_at descending (most recent first)
    final sortedHotlines = List<Map<String, dynamic>>.from(_mentalHealthHotlines);
    sortedHotlines.sort((a, b) {
      final dateA = DateTime.parse(a['created_at']);
      final dateB = DateTime.parse(b['created_at']);
      return dateB.compareTo(dateA);
    });
    
    return sortedHotlines;
  }

  Future<Map<String, dynamic>?> fetchHotlineById(int hotlineId) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Database connection failed');
    }
    
    try {
      return _mentalHealthHotlines.firstWhere((hotline) => hotline['hotline_id'] == hotlineId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> checkDatabaseSchema() async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Schema check failed');
    }
    
    return true; // Simulate successful schema check
  }
}

// Service class to handle admin mental health hotlines management
class AdminMentalHealthHotlinesService {
  final MockAdminDatabase _database;
  List<MockAdminMentalHealthHotline> _hotlines = [];
  List<MockAdminMentalHealthHotline> _filteredHotlines = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  AdminMentalHealthHotlinesService(this._database);

  List<MockAdminMentalHealthHotline> get hotlines => _hotlines;
  List<MockAdminMentalHealthHotline> get filteredHotlines => _filteredHotlines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  Future<void> loadHotlines() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      
      final hotlinesData = await _database.fetchMentalHealthHotlines();
      _hotlines = hotlinesData.map((data) => MockAdminMentalHealthHotline.fromMap(data)).toList();
      _applyFilters();
      
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load hotlines: ${e.toString()}';
      _hotlines = [];
      _filteredHotlines = [];
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredHotlines = List.from(_hotlines);
    } else {
      final lowercaseQuery = _searchQuery.toLowerCase();
      _filteredHotlines = _hotlines.where((hotline) {
        return hotline.name.toLowerCase().contains(lowercaseQuery) ||
               hotline.phone.contains(_searchQuery) ||
               (hotline.cityOrRegion?.toLowerCase().contains(lowercaseQuery) ?? false) ||
               (hotline.notes?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    }
  }

  bool hasHotlines() {
    return _hotlines.isNotEmpty;
  }

  int getTotalHotlinesCount() {
    return _hotlines.length;
  }

  int getFilteredHotlinesCount() {
    return _filteredHotlines.length;
  }

  MockAdminMentalHealthHotline? getHotlineById(int hotlineId) {
    try {
      return _hotlines.firstWhere((hotline) => hotline.hotlineId == hotlineId);
    } catch (e) {
      return null;
    }
  }

  List<String> getAvailableRegions() {
    final regions = _hotlines
        .where((hotline) => hotline.cityOrRegion != null && hotline.cityOrRegion!.isNotEmpty)
        .map((hotline) => hotline.cityOrRegion!)
        .toSet()
        .toList();
    regions.sort();
    return regions;
  }

  List<MockAdminMentalHealthHotline> getHotlinesByRegion(String region) {
    return _hotlines.where((hotline) => hotline.cityOrRegion == region).toList();
  }

  Map<String, int> getRegionCounts() {
    final counts = <String, int>{};
    for (final hotline in _hotlines) {
      if (hotline.cityOrRegion != null && hotline.cityOrRegion!.isNotEmpty) {
        counts[hotline.cityOrRegion!] = (counts[hotline.cityOrRegion!] ?? 0) + 1;
      }
    }
    return counts;
  }

  bool isValidHotline(MockAdminMentalHealthHotline hotline) {
    return hotline.name.isNotEmpty && 
           hotline.phone.isNotEmpty;
  }

  String formatCreatedDate(DateTime createdAt) {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String formatCreatedDateTime(DateTime createdAt) {
    return '${formatCreatedDate(createdAt)} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  void clearError() {
    _errorMessage = null;
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  void reset() {
    _hotlines.clear();
    _filteredHotlines.clear();
    _isLoading = false;
    _errorMessage = null;
    _searchQuery = '';
  }

  Future<bool> checkDatabaseSchema() async {
    try {
      return await _database.checkDatabaseSchema();
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> getHotlinesStatistics() {
    int hotlinesWithImages = 0;
    int hotlinesWithNotes = 0;
    int hotlinesWithRegions = 0;
    final phoneTypes = <String, int>{};

    for (final hotline in _hotlines) {
      if (hotline.profilePicture != null && hotline.profilePicture!.isNotEmpty) {
        hotlinesWithImages++;
      }
      
      if (hotline.notes != null && hotline.notes!.isNotEmpty) {
        hotlinesWithNotes++;
      }
      
      if (hotline.cityOrRegion != null && hotline.cityOrRegion!.isNotEmpty) {
        hotlinesWithRegions++;
      }

      // Classify phone number types
      final phone = hotline.phone.replaceAll(RegExp(r'[^\d]'), '');
      if (phone == '911') {
        phoneTypes['Emergency'] = (phoneTypes['Emergency'] ?? 0) + 1;
      } else if (phone == '988') {
        phoneTypes['Crisis'] = (phoneTypes['Crisis'] ?? 0) + 1;
      } else if (phone.length == 6) {
        phoneTypes['Text'] = (phoneTypes['Text'] ?? 0) + 1;
      } else {
        phoneTypes['Standard'] = (phoneTypes['Standard'] ?? 0) + 1;
      }
    }

    return {
      'total_hotlines': _hotlines.length,
      'filtered_count': _filteredHotlines.length,
      'hotlines_with_images': hotlinesWithImages,
      'hotlines_with_notes': hotlinesWithNotes,
      'hotlines_with_regions': hotlinesWithRegions,
      'phone_types': phoneTypes,
      'regions': getAvailableRegions(),
      'region_counts': getRegionCounts(),
      'is_loaded': !_isLoading && _errorMessage == null,
      'has_search_query': _searchQuery.isNotEmpty,
    };
  }

  List<MockAdminMentalHealthHotline> getMostRecentHotlines(int limit) {
    final sorted = List<MockAdminMentalHealthHotline>.from(_hotlines);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  List<MockAdminMentalHealthHotline> getOldestHotlines(int limit) {
    final sorted = List<MockAdminMentalHealthHotline>.from(_hotlines);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted.take(limit).toList();
  }

  String getSearchResultsText() {
    if (_searchQuery.isEmpty) {
      return '${_filteredHotlines.length} hotlines';
    } else {
      return '${_filteredHotlines.length} results for "${_searchQuery}"';
    }
  }

  bool hasProfilePicture(MockAdminMentalHealthHotline hotline) {
    return hotline.profilePicture != null && hotline.profilePicture!.isNotEmpty;
  }

  String getHotlineDisplayName(MockAdminMentalHealthHotline hotline) {
    return hotline.name.isNotEmpty ? hotline.name : 'Unnamed Hotline';
  }

  String getHotlineDisplayPhone(MockAdminMentalHealthHotline hotline) {
    return hotline.phone.isNotEmpty ? hotline.phone : 'No phone number';
  }
}

void main() {
  group('SRM-MHH-02: Admin can view all the mental health hotlines', () {
    late MockAdminDatabase mockDatabase;
    late AdminMentalHealthHotlinesService adminService;

    setUp(() {
      mockDatabase = MockAdminDatabase();
      adminService = AdminMentalHealthHotlinesService(mockDatabase);
    });

    test('Should load hotlines successfully', () async {
      // Seed test data
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'National Crisis Line',
          'phone': '988',
          'city_or_region': 'National',
          'notes': '24/7 support',
          'profile_picture': null,
          'created_at': '2025-01-01T10:00:00Z',
        },
        {
          'hotline_id': 2,
          'name': 'Local Mental Health',
          'phone': '(555) 123-4567',
          'city_or_region': 'San Francisco',
          'notes': 'Business hours only',
          'profile_picture': 'base64data',
          'created_at': '2025-01-02T10:00:00Z',
        },
        {
          'hotline_id': 3,
          'name': 'Crisis Text Service',
          'phone': '741741',
          'city_or_region': 'National',
          'notes': 'Text messaging support',
          'profile_picture': null,
          'created_at': '2025-01-03T10:00:00Z',
        },
      ]);

      await adminService.loadHotlines();

      expect(adminService.isLoading, false);
      expect(adminService.errorMessage, isNull);
      expect(adminService.hotlines.length, 3);
      expect(adminService.filteredHotlines.length, 3);
      expect(adminService.hasHotlines(), true);
      
      // Verify ordering by created_at descending (most recent first)
      expect(adminService.hotlines[0].name, 'Crisis Text Service');
      expect(adminService.hotlines[2].name, 'National Crisis Line');
    });

    test('Should handle empty hotlines database', () async {
      mockDatabase.seedMentalHealthHotlines([]);

      await adminService.loadHotlines();

      expect(adminService.isLoading, false);
      expect(adminService.errorMessage, isNull);
      expect(adminService.hotlines.length, 0);
      expect(adminService.filteredHotlines.length, 0);
      expect(adminService.hasHotlines(), false);
    });

    test('Should handle database errors', () async {
      mockDatabase.setShouldThrowError(true);

      await adminService.loadHotlines();

      expect(adminService.isLoading, false);
      expect(adminService.errorMessage, contains('Failed to load hotlines'));
      expect(adminService.hotlines.length, 0);
      expect(adminService.filteredHotlines.length, 0);
    });

    test('Should search and filter hotlines correctly', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'National Crisis Line',
          'phone': '988',
          'city_or_region': 'National',
          'notes': 'Emergency support',
          'profile_picture': null,
          'created_at': '2025-01-01T10:00:00Z',
        },
        {
          'hotline_id': 2,
          'name': 'Local Support Center',
          'phone': '(555) 123-4567',
          'city_or_region': 'San Francisco',
          'notes': 'Counseling services',
          'profile_picture': null,
          'created_at': '2025-01-02T10:00:00Z',
        },
        {
          'hotline_id': 3,
          'name': 'Crisis Text Line',
          'phone': '741741',
          'city_or_region': 'National',
          'notes': 'Text support',
          'profile_picture': null,
          'created_at': '2025-01-03T10:00:00Z',
        },
      ]);

      await adminService.loadHotlines();

      // Search by name
      adminService.setSearchQuery('crisis');
      expect(adminService.filteredHotlines.length, 2);
      expect(adminService.filteredHotlines.any((h) => h.name.contains('Crisis')), true);

      // Search by phone
      adminService.setSearchQuery('988');
      expect(adminService.filteredHotlines.length, 1);
      expect(adminService.filteredHotlines[0].phone, '988');

      // Search by region
      adminService.setSearchQuery('San Francisco');
      expect(adminService.filteredHotlines.length, 1);
      expect(adminService.filteredHotlines[0].cityOrRegion, 'San Francisco');

      // Search by notes
      adminService.setSearchQuery('counseling');
      expect(adminService.filteredHotlines.length, 1);

      // Clear search
      adminService.clearSearch();
      expect(adminService.filteredHotlines.length, 3);
      expect(adminService.searchQuery, isEmpty);
    });

    test('Should get hotline by ID correctly', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 123,
          'name': 'Test Hotline',
          'phone': '555-1234',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-01T10:00:00Z',
        },
      ]);

      await adminService.loadHotlines();

      final foundHotline = adminService.getHotlineById(123);
      expect(foundHotline, isNotNull);
      expect(foundHotline!.name, 'Test Hotline');

      final notFoundHotline = adminService.getHotlineById(999);
      expect(notFoundHotline, isNull);
    });

    test('Should get available regions correctly', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'Hotline 1',
          'phone': '111',
          'city_or_region': 'New York',
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-01T10:00:00Z',
        },
        {
          'hotline_id': 2,
          'name': 'Hotline 2',
          'phone': '222',
          'city_or_region': 'California',
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-02T10:00:00Z',
        },
        {
          'hotline_id': 3,
          'name': 'Hotline 3',
          'phone': '333',
          'city_or_region': 'New York',
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-03T10:00:00Z',
        },
        {
          'hotline_id': 4,
          'name': 'Hotline 4',
          'phone': '444',
          'city_or_region': null, // No region
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-04T10:00:00Z',
        },
      ]);

      await adminService.loadHotlines();

      final regions = adminService.getAvailableRegions();
      expect(regions.length, 2);
      expect(regions, containsAll(['California', 'New York']));
      expect(regions, orderedEquals(['California', 'New York'])); // Should be sorted

      final regionCounts = adminService.getRegionCounts();
      expect(regionCounts['New York'], 2);
      expect(regionCounts['California'], 1);
    });

    test('Should get hotlines by region correctly', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'NY Hotline 1',
          'phone': '111',
          'city_or_region': 'New York',
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-01T10:00:00Z',
        },
        {
          'hotline_id': 2,
          'name': 'CA Hotline',
          'phone': '222',
          'city_or_region': 'California',
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-02T10:00:00Z',
        },
        {
          'hotline_id': 3,
          'name': 'NY Hotline 2',
          'phone': '333',
          'city_or_region': 'New York',
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-03T10:00:00Z',
        },
      ]);

      await adminService.loadHotlines();

      final nyHotlines = adminService.getHotlinesByRegion('New York');
      expect(nyHotlines.length, 2);
      expect(nyHotlines.every((h) => h.cityOrRegion == 'New York'), true);

      final caHotlines = adminService.getHotlinesByRegion('California');
      expect(caHotlines.length, 1);
      expect(caHotlines[0].name, 'CA Hotline');

      final nonExistentRegion = adminService.getHotlinesByRegion('Texas');
      expect(nonExistentRegion.length, 0);
    });

    test('Should format dates correctly', () {
      final testDate = DateTime(2025, 1, 15, 14, 30, 0);
      
      expect(adminService.formatCreatedDate(testDate), '15/1/2025');
      expect(adminService.formatCreatedDateTime(testDate), '15/1/2025 14:30');
    });

    test('Should validate hotlines correctly', () {
      final validHotline = MockAdminMentalHealthHotline(
        hotlineId: 1,
        name: 'Valid Hotline',
        phone: '555-1234',
        createdAt: DateTime.now(),
      );

      final invalidHotlineName = MockAdminMentalHealthHotline(
        hotlineId: 2,
        name: '', // Empty name
        phone: '555-1234',
        createdAt: DateTime.now(),
      );

      final invalidHotlinePhone = MockAdminMentalHealthHotline(
        hotlineId: 3,
        name: 'Valid Name',
        phone: '', // Empty phone
        createdAt: DateTime.now(),
      );

      expect(adminService.isValidHotline(validHotline), true);
      expect(adminService.isValidHotline(invalidHotlineName), false);
      expect(adminService.isValidHotline(invalidHotlinePhone), false);
    });

    test('Should get statistics correctly', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'Crisis Line',
          'phone': '988',
          'city_or_region': 'National',
          'notes': 'Has notes',
          'profile_picture': 'base64data',
          'created_at': '2025-01-01T10:00:00Z',
        },
        {
          'hotline_id': 2,
          'name': 'Text Line',
          'phone': '741741',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-02T10:00:00Z',
        },
        {
          'hotline_id': 3,
          'name': 'Emergency',
          'phone': '911',
          'city_or_region': 'Local',
          'notes': 'Emergency only',
          'profile_picture': 'anotherbase64',
          'created_at': '2025-01-03T10:00:00Z',
        },
      ]);

      await adminService.loadHotlines();
      adminService.setSearchQuery('crisis');
      
      final stats = adminService.getHotlinesStatistics();

      expect(stats['total_hotlines'], 3);
      expect(stats['filtered_count'], 1); // Only "Crisis Line" matches search
      expect(stats['hotlines_with_images'], 2);
      expect(stats['hotlines_with_notes'], 2);
      expect(stats['hotlines_with_regions'], 2);
      expect(stats['phone_types']['Crisis'], 1);
      expect(stats['phone_types']['Text'], 1);
      expect(stats['phone_types']['Emergency'], 1);
      expect(stats['is_loaded'], true);
      expect(stats['has_search_query'], true);
    });

    test('Should get most recent and oldest hotlines', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'Oldest',
          'phone': '111',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-01T10:00:00Z',
        },
        {
          'hotline_id': 2,
          'name': 'Middle',
          'phone': '222',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-02T10:00:00Z',
        },
        {
          'hotline_id': 3,
          'name': 'Newest',
          'phone': '333',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-03T10:00:00Z',
        },
      ]);

      await adminService.loadHotlines();

      final mostRecent = adminService.getMostRecentHotlines(2);
      expect(mostRecent.length, 2);
      expect(mostRecent[0].name, 'Newest');
      expect(mostRecent[1].name, 'Middle');

      final oldest = adminService.getOldestHotlines(2);
      expect(oldest.length, 2);
      expect(oldest[0].name, 'Oldest');
      expect(oldest[1].name, 'Middle');
    });

    test('Should generate search results text correctly', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'Test Hotline',
          'phone': '123',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-01T10:00:00Z',
        },
        {
          'hotline_id': 2,
          'name': 'Another Hotline',
          'phone': '456',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-02T10:00:00Z',
        },
      ]);

      await adminService.loadHotlines();

      // No search query
      expect(adminService.getSearchResultsText(), '2 hotlines');

      // With search query
      adminService.setSearchQuery('test');
      expect(adminService.getSearchResultsText(), '1 results for "test"');
    });

    test('Should check database schema', () async {
      expect(await adminService.checkDatabaseSchema(), true);

      mockDatabase.setShouldThrowError(true);
      expect(await adminService.checkDatabaseSchema(), false);
    });

    test('Should handle profile picture checks', () {
      final withPicture = MockAdminMentalHealthHotline(
        hotlineId: 1,
        name: 'Test',
        phone: '123',
        profilePicture: 'base64data',
        createdAt: DateTime.now(),
      );

      final withoutPicture = MockAdminMentalHealthHotline(
        hotlineId: 2,
        name: 'Test',
        phone: '123',
        createdAt: DateTime.now(),
      );

      expect(adminService.hasProfilePicture(withPicture), true);
      expect(adminService.hasProfilePicture(withoutPicture), false);
    });

    test('Should get display names and phones correctly', () {
      final normalHotline = MockAdminMentalHealthHotline(
        hotlineId: 1,
        name: 'Normal Hotline',
        phone: '555-1234',
        createdAt: DateTime.now(),
      );

      final emptyNameHotline = MockAdminMentalHealthHotline(
        hotlineId: 2,
        name: '',
        phone: '555-5678',
        createdAt: DateTime.now(),
      );

      final emptyPhoneHotline = MockAdminMentalHealthHotline(
        hotlineId: 3,
        name: 'Good Name',
        phone: '',
        createdAt: DateTime.now(),
      );

      expect(adminService.getHotlineDisplayName(normalHotline), 'Normal Hotline');
      expect(adminService.getHotlineDisplayName(emptyNameHotline), 'Unnamed Hotline');

      expect(adminService.getHotlineDisplayPhone(normalHotline), '555-1234');
      expect(adminService.getHotlineDisplayPhone(emptyPhoneHotline), 'No phone number');
    });

    test('Should reset service correctly', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'Test',
          'phone': '123',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-01T10:00:00Z',
        },
      ]);

      await adminService.loadHotlines();
      adminService.setSearchQuery('test');
      
      expect(adminService.hotlines.length, 1);
      expect(adminService.searchQuery, 'test');
      
      adminService.reset();
      
      expect(adminService.hotlines.length, 0);
      expect(adminService.filteredHotlines.length, 0);
      expect(adminService.searchQuery, isEmpty);
      expect(adminService.isLoading, false);
      expect(adminService.errorMessage, isNull);
    });
  });
}