// SRM-MHH-01: Students can view all the mental health hotlines
// Requirement: Students can view list of mental health hotlines for crisis support
// Mirrors logic in `student_contacts.dart` (load and display mental health hotlines)

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent a mental health hotline
class MockMentalHealthHotline {
  final int hotlineId;
  final String name;
  final String phone;
  final String? cityOrRegion;
  final String? notes;
  final String? profilePicture;
  final DateTime createdAt;

  MockMentalHealthHotline({
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

  factory MockMentalHealthHotline.fromMap(Map<String, dynamic> map) {
    return MockMentalHealthHotline(
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

// Mock database class to simulate Supabase operations
class MockDatabase {
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
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Database connection failed');
    }
    
    return _mentalHealthHotlines.toList();
  }

  Future<List<Map<String, dynamic>>> fetchMentalHealthHotlinesOrderedByName() async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Database connection failed');
    }
    
    final sortedHotlines = List<Map<String, dynamic>>.from(_mentalHealthHotlines);
    sortedHotlines.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    return sortedHotlines;
  }
}

// Service class to handle student mental health hotlines viewing
class StudentMentalHealthHotlinesService {
  final MockDatabase _database;
  List<MockMentalHealthHotline> _hotlines = [];
  bool _isLoading = false;
  String? _errorMessage;

  StudentMentalHealthHotlinesService(this._database);

  List<MockMentalHealthHotline> get hotlines => _hotlines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMentalHealthHotlines() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      
      final hotlinesData = await _database.fetchMentalHealthHotlinesOrderedByName();
      _hotlines = hotlinesData.map((data) => MockMentalHealthHotline.fromMap(data)).toList();
      
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading mental health hotlines: ${e.toString()}';
      _hotlines = [];
    }
  }

  bool hasHotlines() {
    return _hotlines.isNotEmpty;
  }

  int getHotlinesCount() {
    return _hotlines.length;
  }

  List<MockMentalHealthHotline> getActiveHotlines() {
    // All hotlines in the system are considered active
    return _hotlines;
  }

  MockMentalHealthHotline? getHotlineById(int hotlineId) {
    try {
      return _hotlines.firstWhere((hotline) => hotline.hotlineId == hotlineId);
    } catch (e) {
      return null;
    }
  }

  List<MockMentalHealthHotline> searchHotlines(String query) {
    if (query.isEmpty) return _hotlines;
    
    final lowercaseQuery = query.toLowerCase();
    return _hotlines.where((hotline) {
      return hotline.name.toLowerCase().contains(lowercaseQuery) ||
             hotline.phone.contains(query) ||
             (hotline.cityOrRegion?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (hotline.notes?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  String formatHotlinePhone(String phone) {
    // Simple phone formatting for display
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  String getHotlineDisplayText(MockMentalHealthHotline hotline) {
    String displayText = hotline.name;
    if (hotline.cityOrRegion != null && hotline.cityOrRegion!.isNotEmpty) {
      displayText += ' (${hotline.cityOrRegion})';
    }
    return displayText;
  }

  bool isValidHotline(MockMentalHealthHotline hotline) {
    return hotline.name.isNotEmpty && 
           hotline.phone.isNotEmpty;
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _hotlines.clear();
    _isLoading = false;
    _errorMessage = null;
  }

  Map<String, dynamic> getHotlinesStatistics() {
    final regionsCount = <String, int>{};
    int hotlinesWithImages = 0;
    int hotlinesWithNotes = 0;

    for (final hotline in _hotlines) {
      if (hotline.cityOrRegion != null && hotline.cityOrRegion!.isNotEmpty) {
        regionsCount[hotline.cityOrRegion!] = (regionsCount[hotline.cityOrRegion!] ?? 0) + 1;
      }
      
      if (hotline.profilePicture != null && hotline.profilePicture!.isNotEmpty) {
        hotlinesWithImages++;
      }
      
      if (hotline.notes != null && hotline.notes!.isNotEmpty) {
        hotlinesWithNotes++;
      }
    }

    return {
      'total_hotlines': _hotlines.length,
      'regions': regionsCount.keys.toList(),
      'region_counts': regionsCount,
      'hotlines_with_images': hotlinesWithImages,
      'hotlines_with_notes': hotlinesWithNotes,
      'is_loaded': !_isLoading && _errorMessage == null,
    };
  }

  Future<bool> callHotline(String phoneNumber) async {
    // Simulate calling functionality
    await Future.delayed(Duration(milliseconds: 200));
    
    // Validate phone number format
    if (phoneNumber.isEmpty) {
      return false;
    }
    
    // Remove all non-digit characters for validation
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 3) {
      return false;
    }
    
    return true;
  }

  String getEmergencyMessage() {
    return 'Crisis Text Line: Text HOME to 741741\nNational Suicide Prevention Lifeline: 988\nEmergency Services: 911';
  }

  bool isEmergencyNumber(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly == '911' || digitsOnly == '988' || digitsOnly == '741741';
  }
}

void main() {
  group('SRM-MHH-01: Students can view all the mental health hotlines', () {
    late MockDatabase mockDatabase;
    late StudentMentalHealthHotlinesService hotlinesService;

    setUp(() {
      mockDatabase = MockDatabase();
      hotlinesService = StudentMentalHealthHotlinesService(mockDatabase);
    });

    test('Should load mental health hotlines successfully', () async {
      // Seed test data
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'National Suicide Prevention Lifeline',
          'phone': '988',
          'city_or_region': 'National',
          'notes': '24/7 crisis support',
          'profile_picture': null,
          'created_at': '2025-01-01T00:00:00Z',
        },
        {
          'hotline_id': 2,
          'name': 'Crisis Text Line',
          'phone': '741741',
          'city_or_region': 'National',
          'notes': 'Text HOME to 741741',
          'profile_picture': 'base64imagedata',
          'created_at': '2025-01-02T00:00:00Z',
        },
        {
          'hotline_id': 3,
          'name': 'Local Mental Health Center',
          'phone': '(555) 123-4567',
          'city_or_region': 'San Francisco',
          'notes': 'Mon-Fri 9AM-5PM',
          'profile_picture': null,
          'created_at': '2025-01-03T00:00:00Z',
        },
      ]);

      await hotlinesService.loadMentalHealthHotlines();

      expect(hotlinesService.isLoading, false);
      expect(hotlinesService.errorMessage, isNull);
      expect(hotlinesService.hotlines.length, 3);
      expect(hotlinesService.hasHotlines(), true);
      
      // Check if hotlines are ordered by name
      final firstHotline = hotlinesService.hotlines[0];
      expect(firstHotline.name, 'Crisis Text Line'); // Should be first alphabetically
    });

    test('Should handle empty hotlines database gracefully', () async {
      mockDatabase.seedMentalHealthHotlines([]); // Empty database

      await hotlinesService.loadMentalHealthHotlines();

      expect(hotlinesService.isLoading, false);
      expect(hotlinesService.errorMessage, isNull);
      expect(hotlinesService.hotlines.length, 0);
      expect(hotlinesService.hasHotlines(), false);
      expect(hotlinesService.getHotlinesCount(), 0);
    });

    test('Should handle database connection errors', () async {
      mockDatabase.setShouldThrowError(true);

      await hotlinesService.loadMentalHealthHotlines();

      expect(hotlinesService.isLoading, false);
      expect(hotlinesService.errorMessage, contains('Error loading mental health hotlines'));
      expect(hotlinesService.hotlines.length, 0);
    });

    test('Should search hotlines correctly', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'National Suicide Prevention Lifeline',
          'phone': '988',
          'city_or_region': 'National',
          'notes': '24/7 crisis support',
          'profile_picture': null,
          'created_at': '2025-01-01T00:00:00Z',
        },
        {
          'hotline_id': 2,
          'name': 'Crisis Text Line',
          'phone': '741741',
          'city_or_region': 'National',
          'notes': 'Text messaging support',
          'profile_picture': null,
          'created_at': '2025-01-02T00:00:00Z',
        },
        {
          'hotline_id': 3,
          'name': 'Local Mental Health Center',
          'phone': '(555) 123-4567',
          'city_or_region': 'San Francisco',
          'notes': 'Local counseling services',
          'profile_picture': null,
          'created_at': '2025-01-03T00:00:00Z',
        },
      ]);

      await hotlinesService.loadMentalHealthHotlines();

      // Search by name
      final crisisResults = hotlinesService.searchHotlines('crisis');
      expect(crisisResults.length, 2); // Should find "Crisis Text Line" and one with crisis in notes

      // Search by phone number
      final phoneResults = hotlinesService.searchHotlines('988');
      expect(phoneResults.length, 1);
      expect(phoneResults[0].name, 'National Suicide Prevention Lifeline');

      // Search by region
      final regionResults = hotlinesService.searchHotlines('San Francisco');
      expect(regionResults.length, 1);
      expect(regionResults[0].name, 'Local Mental Health Center');

      // Empty search returns all
      final allResults = hotlinesService.searchHotlines('');
      expect(allResults.length, 3);
    });

    test('Should get hotline by ID correctly', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'Test Hotline',
          'phone': '123-456-7890',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-01T00:00:00Z',
        },
      ]);

      await hotlinesService.loadMentalHealthHotlines();

      final foundHotline = hotlinesService.getHotlineById(1);
      expect(foundHotline, isNotNull);
      expect(foundHotline!.name, 'Test Hotline');

      final notFoundHotline = hotlinesService.getHotlineById(999);
      expect(notFoundHotline, isNull);
    });

    test('Should format phone numbers correctly', () {
      expect(hotlinesService.formatHotlinePhone('(555) 123-4567'), '5551234567');
      expect(hotlinesService.formatHotlinePhone('988'), '988');
      expect(hotlinesService.formatHotlinePhone('1-800-273-8255'), '18002738255');
      expect(hotlinesService.formatHotlinePhone('741741'), '741741');
    });

    test('Should generate display text correctly', () {
      final hotlineWithRegion = MockMentalHealthHotline(
        hotlineId: 1,
        name: 'Local Crisis Center',
        phone: '555-1234',
        cityOrRegion: 'New York',
        createdAt: DateTime.now(),
      );

      final hotlineWithoutRegion = MockMentalHealthHotline(
        hotlineId: 2,
        name: 'National Hotline',
        phone: '988',
        createdAt: DateTime.now(),
      );

      expect(hotlinesService.getHotlineDisplayText(hotlineWithRegion), 'Local Crisis Center (New York)');
      expect(hotlinesService.getHotlineDisplayText(hotlineWithoutRegion), 'National Hotline');
    });

    test('Should validate hotlines correctly', () {
      final validHotline = MockMentalHealthHotline(
        hotlineId: 1,
        name: 'Valid Hotline',
        phone: '555-1234',
        createdAt: DateTime.now(),
      );

      final invalidHotlineName = MockMentalHealthHotline(
        hotlineId: 2,
        name: '', // Empty name
        phone: '555-1234',
        createdAt: DateTime.now(),
      );

      final invalidHotlinePhone = MockMentalHealthHotline(
        hotlineId: 3,
        name: 'Valid Name',
        phone: '', // Empty phone
        createdAt: DateTime.now(),
      );

      expect(hotlinesService.isValidHotline(validHotline), true);
      expect(hotlinesService.isValidHotline(invalidHotlineName), false);
      expect(hotlinesService.isValidHotline(invalidHotlinePhone), false);
    });

    test('Should get hotlines statistics correctly', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'Hotline 1',
          'phone': '988',
          'city_or_region': 'National',
          'notes': 'Has notes',
          'profile_picture': 'base64data',
          'created_at': '2025-01-01T00:00:00Z',
        },
        {
          'hotline_id': 2,
          'name': 'Hotline 2',
          'phone': '741741',
          'city_or_region': 'National',
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-02T00:00:00Z',
        },
        {
          'hotline_id': 3,
          'name': 'Hotline 3',
          'phone': '555-1234',
          'city_or_region': 'Local',
          'notes': 'Also has notes',
          'profile_picture': 'anotherbase64',
          'created_at': '2025-01-03T00:00:00Z',
        },
      ]);

      await hotlinesService.loadMentalHealthHotlines();
      final stats = hotlinesService.getHotlinesStatistics();

      expect(stats['total_hotlines'], 3);
      expect(stats['regions'], containsAll(['National', 'Local']));
      expect(stats['region_counts']['National'], 2);
      expect(stats['region_counts']['Local'], 1);
      expect(stats['hotlines_with_images'], 2);
      expect(stats['hotlines_with_notes'], 2);
      expect(stats['is_loaded'], true);
    });

    test('Should simulate calling functionality', () async {
      expect(await hotlinesService.callHotline('988'), true);
      expect(await hotlinesService.callHotline('(555) 123-4567'), true);
      expect(await hotlinesService.callHotline(''), false);
      expect(await hotlinesService.callHotline('12'), false); // Too short
    });

    test('Should identify emergency numbers', () {
      expect(hotlinesService.isEmergencyNumber('911'), true);
      expect(hotlinesService.isEmergencyNumber('988'), true);
      expect(hotlinesService.isEmergencyNumber('741741'), true);
      expect(hotlinesService.isEmergencyNumber('(555) 123-4567'), false);
    });

    test('Should provide emergency message', () {
      final message = hotlinesService.getEmergencyMessage();
      expect(message, contains('Crisis Text Line'));
      expect(message, contains('988'));
      expect(message, contains('911'));
      expect(message, contains('741741'));
    });

    test('Should clear error correctly', () async {
      mockDatabase.setShouldThrowError(true);
      
      await hotlinesService.loadMentalHealthHotlines();
      expect(hotlinesService.errorMessage, isNotNull);
      
      hotlinesService.clearError();
      expect(hotlinesService.errorMessage, isNull);
    });

    test('Should reset service state correctly', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'Test Hotline',
          'phone': '988',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-01T00:00:00Z',
        },
      ]);

      await hotlinesService.loadMentalHealthHotlines();
      
      expect(hotlinesService.hotlines.length, 1);
      
      hotlinesService.reset();
      
      expect(hotlinesService.hotlines.length, 0);
      expect(hotlinesService.isLoading, false);
      expect(hotlinesService.errorMessage, isNull);
    });

    test('Should get active hotlines correctly', () async {
      mockDatabase.seedMentalHealthHotlines([
        {
          'hotline_id': 1,
          'name': 'Active Hotline 1',
          'phone': '988',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-01T00:00:00Z',
        },
        {
          'hotline_id': 2,
          'name': 'Active Hotline 2',
          'phone': '741741',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-02T00:00:00Z',
        },
      ]);

      await hotlinesService.loadMentalHealthHotlines();
      
      final activeHotlines = hotlinesService.getActiveHotlines();
      expect(activeHotlines.length, 2);
      expect(activeHotlines.every((hotline) => hotline.name.isNotEmpty), true);
    });
  });
}