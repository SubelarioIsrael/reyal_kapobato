// SRM-MHH-03: Admin can add a mental health hotlines
// Requirement: Admin can create new mental health hotlines with all required information
// Mirrors logic in `admin_hotlines.dart` (add hotline dialog and creation functionality)

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent hotline creation data
class MockHotlineCreationData {
  final String name;
  final String phone;
  final String? cityOrRegion;
  final String? notes;
  final String? profilePictureBase64;

  MockHotlineCreationData({
    required this.name,
    required this.phone,
    this.cityOrRegion,
    this.notes,
    this.profilePictureBase64,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'city_or_region': cityOrRegion,
      'notes': notes,
      'profile_picture': profilePictureBase64,
    };
  }
}

// Mock class for hotline creation result
class MockCreatedHotline {
  final int hotlineId;
  final String name;
  final String phone;
  final String? cityOrRegion;
  final String? notes;
  final String? profilePicture;
  final DateTime createdAt;

  MockCreatedHotline({
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
}

// Mock database class for hotline creation
class MockHotlineCreationDatabase {
  List<Map<String, dynamic>> _hotlines = [];
  bool _shouldThrowError = false;
  int _nextId = 1;

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  void seedExistingHotlines(List<Map<String, dynamic>> hotlines) {
    _hotlines = hotlines;
    _nextId = hotlines.isEmpty ? 1 : hotlines.map((h) => h['hotline_id'] as int).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<MockCreatedHotline> createHotline(MockHotlineCreationData data) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 200));
    
    if (_shouldThrowError) {
      throw Exception('Failed to create hotline');
    }
    
    // Check for duplicate names
    if (_hotlines.any((h) => h['name'].toString().toLowerCase() == data.name.toLowerCase())) {
      throw Exception('A hotline with this name already exists');
    }
    
    // Create new hotline
    final createdHotline = MockCreatedHotline(
      hotlineId: _nextId++,
      name: data.name,
      phone: data.phone,
      cityOrRegion: data.cityOrRegion,
      notes: data.notes,
      profilePicture: data.profilePictureBase64,
      createdAt: DateTime.now(),
    );
    
    _hotlines.add(createdHotline.toMap());
    return createdHotline;
  }

  List<Map<String, dynamic>> getAllHotlines() {
    return List.from(_hotlines);
  }

  void clearHotlines() {
    _hotlines.clear();
    _nextId = 1;
  }
}

// Service class for admin hotline creation
class AdminHotlineCreationService {
  final MockHotlineCreationDatabase _database;
  bool _isLoading = false;
  String? _errorMessage;

  AdminHotlineCreationService(this._database);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<MockCreatedHotline?> createHotline(MockHotlineCreationData data) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      
      final createdHotline = await _database.createHotline(data);
      
      _isLoading = false;
      return createdHotline;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      return null;
    }
  }

  String? validateHotlineName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Please enter a service name';
    }
    if (name.trim().length < 3) {
      return 'Service name must be at least 3 characters';
    }
    if (name.trim().length > 100) {
      return 'Service name must be less than 100 characters';
    }
    return null;
  }

  String? validateHotlinePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Please enter a phone number';
    }
    
    // Remove all non-digit characters for validation
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return 'Phone number must contain at least one digit';
    }
    if (digitsOnly.length < 3) {
      return 'Phone number is too short';
    }
    if (digitsOnly.length > 15) {
      return 'Phone number is too long';
    }
    
    return null;
  }

  String? validateCityOrRegion(String? cityOrRegion) {
    if (cityOrRegion != null && cityOrRegion.trim().length > 50) {
      return 'City/Region must be less than 50 characters';
    }
    return null;
  }

  String? validateNotes(String? notes) {
    if (notes != null && notes.trim().length > 500) {
      return 'Notes must be less than 500 characters';
    }
    return null;
  }

  bool validateAllFields(MockHotlineCreationData data) {
    return validateHotlineName(data.name) == null &&
           validateHotlinePhone(data.phone) == null &&
           validateCityOrRegion(data.cityOrRegion) == null &&
           validateNotes(data.notes) == null;
  }

  Map<String, String?> validateAllFieldsWithDetails(MockHotlineCreationData data) {
    return {
      'name': validateHotlineName(data.name),
      'phone': validateHotlinePhone(data.phone),
      'cityOrRegion': validateCityOrRegion(data.cityOrRegion),
      'notes': validateNotes(data.notes),
    };
  }

  String formatPhoneNumber(String phone) {
    // Simple phone formatting - remove non-digit characters except +
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  String sanitizeInput(String input) {
    return input.trim();
  }

  MockHotlineCreationData sanitizeHotlineData(MockHotlineCreationData data) {
    return MockHotlineCreationData(
      name: sanitizeInput(data.name),
      phone: sanitizeInput(data.phone),
      cityOrRegion: data.cityOrRegion != null ? sanitizeInput(data.cityOrRegion!) : null,
      notes: data.notes != null ? sanitizeInput(data.notes!) : null,
      profilePictureBase64: data.profilePictureBase64,
    );
  }

  bool isValidProfilePicture(String? base64Data) {
    if (base64Data == null) return true; // Optional field
    if (base64Data.isEmpty) return true;
    
    // Basic base64 validation - should be at least 100 characters for a valid image
    return base64Data.length > 100;
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _isLoading = false;
    _errorMessage = null;
  }

  // Helper methods for form management
  bool isFormValid(String name, String phone, String? cityOrRegion, String? notes) {
    final data = MockHotlineCreationData(
      name: name,
      phone: phone,
      cityOrRegion: cityOrRegion,
      notes: notes,
    );
    return validateAllFields(data);
  }

  String getFormattedSuccessMessage(MockCreatedHotline hotline) {
    return 'Hotline "${hotline.name}" has been successfully created';
  }

  Map<String, dynamic> getCreationSummary(MockCreatedHotline hotline) {
    return {
      'hotline_id': hotline.hotlineId,
      'name': hotline.name,
      'phone': hotline.phone,
      'has_region': hotline.cityOrRegion != null && hotline.cityOrRegion!.isNotEmpty,
      'has_notes': hotline.notes != null && hotline.notes!.isNotEmpty,
      'has_profile_picture': hotline.profilePicture != null && hotline.profilePicture!.isNotEmpty,
      'created_at': hotline.createdAt.toIso8601String(),
    };
  }

  List<String> getCommonHotlineNames() {
    return [
      'National Suicide Prevention Lifeline',
      'Crisis Text Line',
      'National Domestic Violence Hotline',
      'SAMHSA National Helpline',
      'National Sexual Assault Hotline',
      'Trans Lifeline',
      'LGBT National Hotline',
      'Veterans Crisis Line',
    ];
  }

  List<String> getCommonPhoneNumbers() {
    return [
      '988',
      '741741',
      '1-800-799-7233',
      '1-800-662-4357',
      '1-800-656-4673',
      '877-565-8860',
      '1-888-843-4564',
      '1-800-273-8255',
    ];
  }

  bool isEmergencyNumber(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly == '911' || digitsOnly == '988';
  }

  String getPhoneDisplayFormat(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length == 3) {
      return digitsOnly; // Emergency numbers like 988, 911
    } else if (digitsOnly.length == 6) {
      return digitsOnly; // Text numbers like 741741
    } else if (digitsOnly.length == 10) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    } else if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
      return '1-${digitsOnly.substring(1, 4)}-${digitsOnly.substring(4, 7)}-${digitsOnly.substring(7)}';
    }
    
    return phone; // Return original if no standard format matches
  }
}

void main() {
  group('SRM-MHH-03: Admin can add a mental health hotlines', () {
    late MockHotlineCreationDatabase mockDatabase;
    late AdminHotlineCreationService creationService;

    setUp(() {
      mockDatabase = MockHotlineCreationDatabase();
      creationService = AdminHotlineCreationService(mockDatabase);
    });

    test('Should create hotline successfully with all fields', () async {
      final hotlineData = MockHotlineCreationData(
        name: 'Test Crisis Center',
        phone: '(555) 123-4567',
        cityOrRegion: 'San Francisco',
        notes: '24/7 support available',
        profilePictureBase64: 'base64encodedimagedata',
      );

      final createdHotline = await creationService.createHotline(hotlineData);

      expect(creationService.isLoading, false);
      expect(creationService.errorMessage, isNull);
      expect(createdHotline, isNotNull);
      expect(createdHotline!.name, 'Test Crisis Center');
      expect(createdHotline.phone, '(555) 123-4567');
      expect(createdHotline.cityOrRegion, 'San Francisco');
      expect(createdHotline.notes, '24/7 support available');
      expect(createdHotline.profilePicture, 'base64encodedimagedata');
      expect(createdHotline.hotlineId, greaterThan(0));
    });

    test('Should create hotline with minimum required fields only', () async {
      final hotlineData = MockHotlineCreationData(
        name: 'Minimal Hotline',
        phone: '988',
      );

      final createdHotline = await creationService.createHotline(hotlineData);

      expect(createdHotline, isNotNull);
      expect(createdHotline!.name, 'Minimal Hotline');
      expect(createdHotline.phone, '988');
      expect(createdHotline.cityOrRegion, isNull);
      expect(createdHotline.notes, isNull);
      expect(createdHotline.profilePicture, isNull);
    });

    test('Should handle database errors during creation', () async {
      mockDatabase.setShouldThrowError(true);
      
      final hotlineData = MockHotlineCreationData(
        name: 'Error Test Hotline',
        phone: '555-1234',
      );

      final createdHotline = await creationService.createHotline(hotlineData);

      expect(creationService.isLoading, false);
      expect(creationService.errorMessage, contains('Failed to create hotline'));
      expect(createdHotline, isNull);
    });

    test('Should prevent duplicate hotline names', () async {
      // Seed existing hotline
      mockDatabase.seedExistingHotlines([
        {
          'hotline_id': 1,
          'name': 'Existing Hotline',
          'phone': '123-456-7890',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-01T10:00:00Z',
        },
      ]);

      final duplicateData = MockHotlineCreationData(
        name: 'Existing Hotline', // Same name
        phone: '555-9999',
      );

      final createdHotline = await creationService.createHotline(duplicateData);

      expect(createdHotline, isNull);
      expect(creationService.errorMessage, contains('already exists'));
    });

    test('Should validate hotline name correctly', () {
      expect(creationService.validateHotlineName(null), isNotNull);
      expect(creationService.validateHotlineName(''), isNotNull);
      expect(creationService.validateHotlineName('  '), isNotNull);
      expect(creationService.validateHotlineName('AB'), isNotNull); // Too short
      expect(creationService.validateHotlineName('A' * 101), isNotNull); // Too long
      expect(creationService.validateHotlineName('Valid Hotline Name'), isNull);
    });

    test('Should validate phone number correctly', () {
      expect(creationService.validateHotlinePhone(null), isNotNull);
      expect(creationService.validateHotlinePhone(''), isNotNull);
      expect(creationService.validateHotlinePhone('  '), isNotNull);
      expect(creationService.validateHotlinePhone('abc'), isNotNull); // No digits
      expect(creationService.validateHotlinePhone('12'), isNotNull); // Too short
      expect(creationService.validateHotlinePhone('1' * 16), isNotNull); // Too long
      expect(creationService.validateHotlinePhone('988'), isNull);
      expect(creationService.validateHotlinePhone('(555) 123-4567'), isNull);
      expect(creationService.validateHotlinePhone('1-800-273-8255'), isNull);
    });

    test('Should validate city/region correctly', () {
      expect(creationService.validateCityOrRegion(null), isNull); // Optional field
      expect(creationService.validateCityOrRegion(''), isNull);
      expect(creationService.validateCityOrRegion('San Francisco'), isNull);
      expect(creationService.validateCityOrRegion('A' * 51), isNotNull); // Too long
    });

    test('Should validate notes correctly', () {
      expect(creationService.validateNotes(null), isNull); // Optional field
      expect(creationService.validateNotes(''), isNull);
      expect(creationService.validateNotes('Valid notes'), isNull);
      expect(creationService.validateNotes('A' * 501), isNotNull); // Too long
    });

    test('Should validate all fields together', () {
      final validData = MockHotlineCreationData(
        name: 'Valid Hotline',
        phone: '988',
      );

      final invalidData = MockHotlineCreationData(
        name: '', // Invalid
        phone: '988',
      );

      expect(creationService.validateAllFields(validData), true);
      expect(creationService.validateAllFields(invalidData), false);

      final validationDetails = creationService.validateAllFieldsWithDetails(invalidData);
      expect(validationDetails['name'], isNotNull);
      expect(validationDetails['phone'], isNull);
    });

    test('Should format phone numbers correctly', () {
      expect(creationService.formatPhoneNumber('(555) 123-4567'), '5551234567');
      expect(creationService.formatPhoneNumber('1-800-273-8255'), '18002738255');
      expect(creationService.formatPhoneNumber('988'), '988');
      expect(creationService.formatPhoneNumber('+1 555 123 4567'), '+15551234567');
    });

    test('Should sanitize input data', () {
      final dirtyData = MockHotlineCreationData(
        name: '  Hotline Name  ',
        phone: '  555-1234  ',
        cityOrRegion: '  San Francisco  ',
        notes: '  Some notes  ',
      );

      final cleanData = creationService.sanitizeHotlineData(dirtyData);

      expect(cleanData.name, 'Hotline Name');
      expect(cleanData.phone, '555-1234');
      expect(cleanData.cityOrRegion, 'San Francisco');
      expect(cleanData.notes, 'Some notes');
    });

    test('Should validate profile pictures', () {
      expect(creationService.isValidProfilePicture(null), true); // Optional
      expect(creationService.isValidProfilePicture(''), true); // Empty is OK
      expect(creationService.isValidProfilePicture('short'), false); // Too short
      expect(creationService.isValidProfilePicture('a' * 200), true); // Valid length
    });

    test('Should check form validity', () {
      expect(creationService.isFormValid('Valid Name', '988', null, null), true);
      expect(creationService.isFormValid('', '988', null, null), false); // Invalid name
      expect(creationService.isFormValid('Valid Name', '', null, null), false); // Invalid phone
      expect(creationService.isFormValid('Valid Name', '988', 'A' * 51, null), false); // Invalid region
    });

    test('Should generate success messages', () {
      final hotline = MockCreatedHotline(
        hotlineId: 1,
        name: 'Test Hotline',
        phone: '988',
        createdAt: DateTime.now(),
      );

      final message = creationService.getFormattedSuccessMessage(hotline);
      expect(message, contains('Test Hotline'));
      expect(message, contains('successfully created'));
    });

    test('Should generate creation summary', () {
      final hotline = MockCreatedHotline(
        hotlineId: 123,
        name: 'Summary Test',
        phone: '555-1234',
        cityOrRegion: 'Test City',
        notes: 'Test notes',
        profilePicture: 'base64data',
        createdAt: DateTime.now(),
      );

      final summary = creationService.getCreationSummary(hotline);

      expect(summary['hotline_id'], 123);
      expect(summary['name'], 'Summary Test');
      expect(summary['phone'], '555-1234');
      expect(summary['has_region'], true);
      expect(summary['has_notes'], true);
      expect(summary['has_profile_picture'], true);
      expect(summary['created_at'], isNotEmpty);
    });

    test('Should provide common hotline names and numbers', () {
      final commonNames = creationService.getCommonHotlineNames();
      expect(commonNames, isNotEmpty);
      expect(commonNames, contains('National Suicide Prevention Lifeline'));

      final commonNumbers = creationService.getCommonPhoneNumbers();
      expect(commonNumbers, isNotEmpty);
      expect(commonNumbers, contains('988'));
    });

    test('Should identify emergency numbers', () {
      expect(creationService.isEmergencyNumber('911'), true);
      expect(creationService.isEmergencyNumber('988'), true);
      expect(creationService.isEmergencyNumber('(555) 123-4567'), false);
    });

    test('Should format phone display correctly', () {
      expect(creationService.getPhoneDisplayFormat('988'), '988');
      expect(creationService.getPhoneDisplayFormat('741741'), '741741');
      expect(creationService.getPhoneDisplayFormat('5551234567'), '(555) 123-4567');
      expect(creationService.getPhoneDisplayFormat('18002738255'), '1-800-273-8255');
    });

    test('Should clear errors correctly', () {
      mockDatabase.setShouldThrowError(true);
      
      final hotlineData = MockHotlineCreationData(
        name: 'Error Test',
        phone: '988',
      );

      // This should cause an error
      creationService.createHotline(hotlineData);
      
      // Clear the error
      creationService.clearError();
      expect(creationService.errorMessage, isNull);
    });

    test('Should reset service correctly', () async {
      mockDatabase.setShouldThrowError(true);
      
      final hotlineData = MockHotlineCreationData(
        name: 'Reset Test',
        phone: '988',
      );

      await creationService.createHotline(hotlineData);
      expect(creationService.errorMessage, isNotNull);
      
      creationService.reset();
      expect(creationService.isLoading, false);
      expect(creationService.errorMessage, isNull);
    });

    test('Should handle case-insensitive duplicate checking', () async {
      mockDatabase.seedExistingHotlines([
        {
          'hotline_id': 1,
          'name': 'Crisis Line',
          'phone': '988',
          'city_or_region': null,
          'notes': null,
          'profile_picture': null,
          'created_at': '2025-01-01T10:00:00Z',
        },
      ]);

      final duplicateData = MockHotlineCreationData(
        name: 'CRISIS LINE', // Different case
        phone: '555-9999',
      );

      final createdHotline = await creationService.createHotline(duplicateData);

      expect(createdHotline, isNull);
      expect(creationService.errorMessage, contains('already exists'));
    });

    test('Should assign sequential IDs to new hotlines', () async {
      final hotlineData1 = MockHotlineCreationData(
        name: 'First Hotline',
        phone: '111',
      );

      final hotlineData2 = MockHotlineCreationData(
        name: 'Second Hotline',
        phone: '222',
      );

      final hotline1 = await creationService.createHotline(hotlineData1);
      final hotline2 = await creationService.createHotline(hotlineData2);

      expect(hotline1, isNotNull);
      expect(hotline2, isNotNull);
      expect(hotline2!.hotlineId, hotline1!.hotlineId + 1);
    });
  });
}