// AM-CS-01: Students can select counselor on the counselor list
// Requirement: Students can view and select counselors from the available counselor list
// Mirrors logic in `student_counselors.dart` (load counselors, display list, select counselor)

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent a counselor
class MockCounselor {
  final String id;
  final String firstName;
  final String lastName;
  final String specialization;
  final String availabilityStatus;
  final String? profilePicture;

  MockCounselor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.specialization,
    required this.availabilityStatus,
    this.profilePicture,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'specialization': specialization,
      'availability_status': availabilityStatus,
      'profile_picture': profilePicture,
    };
  }

  factory MockCounselor.fromMap(Map<String, dynamic> map) {
    return MockCounselor(
      id: map['id'],
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      specialization: map['specialization'] ?? '',
      availabilityStatus: map['availability_status'] ?? 'unavailable',
      profilePicture: map['profile_picture'],
    );
  }
}

// Mock database for counselor operations
class MockCounselorDatabase {
  List<Map<String, dynamic>> _counselors = [];
  bool _shouldThrowError = false;

  void seedCounselors(List<Map<String, dynamic>> counselors) {
    _counselors = counselors;
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  Future<List<Map<String, dynamic>>> getCounselors() async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Error loading counselors');
    }
    
    return List.from(_counselors);
  }

  Future<Map<String, dynamic>?> getCounselorById(String counselorId) async {
    await Future.delayed(Duration(milliseconds: 50));
    
    if (_shouldThrowError) {
      throw Exception('Error loading counselor');
    }
    
    try {
      return _counselors.firstWhere((c) => c['id'] == counselorId);
    } catch (e) {
      return null;
    }
  }
}

// Service class for counselor selection
class StudentCounselorSelectionService {
  final MockCounselorDatabase _database;
  List<MockCounselor> _counselors = [];
  bool _isLoading = false;
  String? _errorMessage;
  MockCounselor? _selectedCounselor;

  StudentCounselorSelectionService(this._database);

  List<MockCounselor> get counselors => _counselors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MockCounselor? get selectedCounselor => _selectedCounselor;

  Future<void> loadCounselors() async {
    try {
      _isLoading = true;
      _errorMessage = null;

      final counselorsData = await _database.getCounselors();
      _counselors = counselorsData.map((data) => MockCounselor.fromMap(data)).toList();

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _counselors = [];
    }
  }

  void selectCounselor(MockCounselor counselor) {
    _selectedCounselor = counselor;
  }

  void clearSelection() {
    _selectedCounselor = null;
  }

  bool hasCounselors() {
    return _counselors.isNotEmpty;
  }

  int getCounselorsCount() {
    return _counselors.length;
  }

  List<MockCounselor> getAvailableCounselors() {
    return _counselors.where((c) => c.availabilityStatus.toLowerCase() == 'available').toList();
  }

  List<MockCounselor> getCounselorsBySpecialization(String specialization) {
    return _counselors.where((c) => c.specialization.toLowerCase().contains(specialization.toLowerCase())).toList();
  }

  String formatCounselorName(MockCounselor counselor) {
    if (counselor.fullName.trim().isNotEmpty) {
      return counselor.fullName
          .split(' ')
          .map((part) => part.isNotEmpty
              ? part[0].toUpperCase() + part.substring(1).toLowerCase()
              : '')
          .join(' ');
    }
    return 'Unknown Counselor';
  }

  bool isAvailable(MockCounselor counselor) {
    return counselor.availabilityStatus.toLowerCase() == 'available';
  }

  String getAvailabilityDisplayText(MockCounselor counselor) {
    return counselor.availabilityStatus;
  }

  Color getAvailabilityColor(MockCounselor counselor) {
    switch (counselor.availabilityStatus.toLowerCase()) {
      case 'available':
        return Color(0xFF4CAF50); // Green
      case 'busy':
        return Color(0xFFF57C00); // Orange
      case 'unavailable':
        return Color(0xFFF44336); // Red
      default:
        return Color(0xFF9E9E9E); // Grey
    }
  }

  Map<String, dynamic> getCounselorStatistics() {
    final specializationCounts = <String, int>{};
    final statusCounts = <String, int>{};
    int counselorsWithImages = 0;

    for (final counselor in _counselors) {
      // Count specializations
      specializationCounts[counselor.specialization] = 
          (specializationCounts[counselor.specialization] ?? 0) + 1;
      
      // Count availability statuses
      statusCounts[counselor.availabilityStatus] = 
          (statusCounts[counselor.availabilityStatus] ?? 0) + 1;
      
      // Count counselors with profile pictures
      if (counselor.profilePicture != null && counselor.profilePicture!.isNotEmpty) {
        counselorsWithImages++;
      }
    }

    return {
      'total_counselors': _counselors.length,
      'available_counselors': getAvailableCounselors().length,
      'specializations': specializationCounts.keys.toList(),
      'specialization_counts': specializationCounts,
      'status_counts': statusCounts,
      'counselors_with_images': counselorsWithImages,
      'has_selection': _selectedCounselor != null,
      'is_loaded': !_isLoading && _errorMessage == null,
    };
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _counselors.clear();
    _selectedCounselor = null;
    _isLoading = false;
    _errorMessage = null;
  }

  MockCounselor? findCounselorById(String counselorId) {
    try {
      return _counselors.firstWhere((c) => c.id == counselorId);
    } catch (e) {
      return null;
    }
  }

  List<String> getUniqueSpecializations() {
    return _counselors.map((c) => c.specialization).toSet().toList()..sort();
  }

  bool canSelectCounselor(MockCounselor counselor) {
    return isAvailable(counselor);
  }

  String getSelectionValidationMessage(MockCounselor counselor) {
    if (!isAvailable(counselor)) {
      return 'This counselor is currently ${counselor.availabilityStatus.toLowerCase()}';
    }
    return '';
  }
}

// Color class for testing
class Color {
  final int value;
  const Color(this.value);
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Color && other.value == value;
  }
  
  @override
  int get hashCode => value.hashCode;
}

void main() {
  group('AM-CS-01: Students can select counselor on the counselor list', () {
    late MockCounselorDatabase mockDatabase;
    late StudentCounselorSelectionService selectionService;

    setUp(() {
      mockDatabase = MockCounselorDatabase();
      selectionService = StudentCounselorSelectionService(mockDatabase);
    });

    test('Should load counselors successfully', () async {
      mockDatabase.seedCounselors([
        {
          'id': 'counselor1',
          'first_name': 'Dr. Sarah',
          'last_name': 'Johnson',
          'specialization': 'Anxiety and Depression',
          'availability_status': 'available',
          'profile_picture': 'base64image1',
        },
        {
          'id': 'counselor2',
          'first_name': 'Dr. Michael',
          'last_name': 'Brown',
          'specialization': 'Trauma Therapy',
          'availability_status': 'busy',
          'profile_picture': null,
        },
        {
          'id': 'counselor3',
          'first_name': 'Dr. Emily',
          'last_name': 'Davis',
          'specialization': 'Relationship Counseling',
          'availability_status': 'available',
          'profile_picture': 'base64image3',
        },
      ]);

      await selectionService.loadCounselors();

      expect(selectionService.isLoading, false);
      expect(selectionService.errorMessage, isNull);
      expect(selectionService.counselors.length, 3);
      expect(selectionService.hasCounselors(), true);
      expect(selectionService.getCounselorsCount(), 3);
    });

    test('Should handle empty counselors list', () async {
      mockDatabase.seedCounselors([]);

      await selectionService.loadCounselors();

      expect(selectionService.isLoading, false);
      expect(selectionService.errorMessage, isNull);
      expect(selectionService.counselors.length, 0);
      expect(selectionService.hasCounselors(), false);
    });

    test('Should handle loading errors', () async {
      mockDatabase.setShouldThrowError(true);

      await selectionService.loadCounselors();

      expect(selectionService.isLoading, false);
      expect(selectionService.errorMessage, contains('Error loading counselors'));
      expect(selectionService.counselors.length, 0);
    });

    test('Should select and clear counselor selection', () async {
      mockDatabase.seedCounselors([
        {
          'id': 'counselor1',
          'first_name': 'Dr. Sarah',
          'last_name': 'Johnson',
          'specialization': 'Anxiety',
          'availability_status': 'available',
          'profile_picture': null,
        },
      ]);

      await selectionService.loadCounselors();
      final counselor = selectionService.counselors[0];

      // Test selection
      selectionService.selectCounselor(counselor);
      expect(selectionService.selectedCounselor, equals(counselor));

      // Test clearing selection
      selectionService.clearSelection();
      expect(selectionService.selectedCounselor, isNull);
    });

    test('Should filter available counselors', () async {
      mockDatabase.seedCounselors([
        {
          'id': 'counselor1',
          'first_name': 'Available',
          'last_name': 'One',
          'specialization': 'General',
          'availability_status': 'available',
          'profile_picture': null,
        },
        {
          'id': 'counselor2',
          'first_name': 'Busy',
          'last_name': 'One',
          'specialization': 'General',
          'availability_status': 'busy',
          'profile_picture': null,
        },
        {
          'id': 'counselor3',
          'first_name': 'Available',
          'last_name': 'Two',
          'specialization': 'General',
          'availability_status': 'available',
          'profile_picture': null,
        },
      ]);

      await selectionService.loadCounselors();
      final available = selectionService.getAvailableCounselors();

      expect(available.length, 2);
      expect(available.every((c) => c.availabilityStatus == 'available'), true);
    });

    test('Should filter counselors by specialization', () async {
      mockDatabase.seedCounselors([
        {
          'id': 'counselor1',
          'first_name': 'Anxiety',
          'last_name': 'Expert',
          'specialization': 'Anxiety and Depression',
          'availability_status': 'available',
          'profile_picture': null,
        },
        {
          'id': 'counselor2',
          'first_name': 'Trauma',
          'last_name': 'Expert',
          'specialization': 'Trauma Therapy',
          'availability_status': 'available',
          'profile_picture': null,
        },
        {
          'id': 'counselor3',
          'first_name': 'Another',
          'last_name': 'Anxiety',
          'specialization': 'Anxiety Disorders',
          'availability_status': 'available',
          'profile_picture': null,
        },
      ]);

      await selectionService.loadCounselors();
      final anxietyCounselors = selectionService.getCounselorsBySpecialization('anxiety');

      expect(anxietyCounselors.length, 2);
      expect(anxietyCounselors.every((c) => c.specialization.toLowerCase().contains('anxiety')), true);
    });

    test('Should format counselor names correctly', () {
      final counselor = MockCounselor(
        id: 'test',
        firstName: 'dr. sarah',
        lastName: 'JOHNSON',
        specialization: 'Test',
        availabilityStatus: 'available',
      );

      final formatted = selectionService.formatCounselorName(counselor);
      expect(formatted, 'Dr. Sarah Johnson');

      final emptyCounselor = MockCounselor(
        id: 'empty',
        firstName: '',
        lastName: '',
        specialization: 'Test',
        availabilityStatus: 'available',
      );

      final emptyFormatted = selectionService.formatCounselorName(emptyCounselor);
      expect(emptyFormatted, 'Unknown Counselor');
    });

    test('Should check availability correctly', () {
      final available = MockCounselor(
        id: 'available',
        firstName: 'Available',
        lastName: 'Counselor',
        specialization: 'Test',
        availabilityStatus: 'available',
      );

      final busy = MockCounselor(
        id: 'busy',
        firstName: 'Busy',
        lastName: 'Counselor',
        specialization: 'Test',
        availabilityStatus: 'busy',
      );

      expect(selectionService.isAvailable(available), true);
      expect(selectionService.isAvailable(busy), false);
    });

    test('Should return correct availability colors', () {
      final available = MockCounselor(
        id: 'available',
        firstName: 'Test',
        lastName: 'User',
        specialization: 'Test',
        availabilityStatus: 'available',
      );

      final busy = MockCounselor(
        id: 'busy',
        firstName: 'Test',
        lastName: 'User',
        specialization: 'Test',
        availabilityStatus: 'busy',
      );

      expect(selectionService.getAvailabilityColor(available), Color(0xFF4CAF50)); // Green
      expect(selectionService.getAvailabilityColor(busy), Color(0xFFF57C00)); // Orange
    });

    test('Should generate counselor statistics', () async {
      mockDatabase.seedCounselors([
        {
          'id': 'counselor1',
          'first_name': 'First',
          'last_name': 'Counselor',
          'specialization': 'Anxiety',
          'availability_status': 'available',
          'profile_picture': 'base64image',
        },
        {
          'id': 'counselor2',
          'first_name': 'Second',
          'last_name': 'Counselor',
          'specialization': 'Anxiety',
          'availability_status': 'busy',
          'profile_picture': null,
        },
        {
          'id': 'counselor3',
          'first_name': 'Third',
          'last_name': 'Counselor',
          'specialization': 'Trauma',
          'availability_status': 'available',
          'profile_picture': 'base64image2',
        },
      ]);

      await selectionService.loadCounselors();
      selectionService.selectCounselor(selectionService.counselors[0]);
      
      final stats = selectionService.getCounselorStatistics();

      expect(stats['total_counselors'], 3);
      expect(stats['available_counselors'], 2);
      expect(stats['specializations'], containsAll(['Anxiety', 'Trauma']));
      expect(stats['specialization_counts']['Anxiety'], 2);
      expect(stats['specialization_counts']['Trauma'], 1);
      expect(stats['status_counts']['available'], 2);
      expect(stats['status_counts']['busy'], 1);
      expect(stats['counselors_with_images'], 2);
      expect(stats['has_selection'], true);
      expect(stats['is_loaded'], true);
    });

    test('Should find counselor by ID', () async {
      mockDatabase.seedCounselors([
        {
          'id': 'find-me',
          'first_name': 'Findable',
          'last_name': 'Counselor',
          'specialization': 'Test',
          'availability_status': 'available',
          'profile_picture': null,
        },
      ]);

      await selectionService.loadCounselors();

      final found = selectionService.findCounselorById('find-me');
      expect(found, isNotNull);
      expect(found!.id, 'find-me');

      final notFound = selectionService.findCounselorById('not-exist');
      expect(notFound, isNull);
    });

    test('Should get unique specializations', () async {
      mockDatabase.seedCounselors([
        {
          'id': 'counselor1',
          'first_name': 'First',
          'last_name': 'Test',
          'specialization': 'Anxiety',
          'availability_status': 'available',
          'profile_picture': null,
        },
        {
          'id': 'counselor2',
          'first_name': 'Second',
          'last_name': 'Test',
          'specialization': 'Trauma',
          'availability_status': 'available',
          'profile_picture': null,
        },
        {
          'id': 'counselor3',
          'first_name': 'Third',
          'last_name': 'Test',
          'specialization': 'Anxiety', // Duplicate
          'availability_status': 'available',
          'profile_picture': null,
        },
      ]);

      await selectionService.loadCounselors();
      final specializations = selectionService.getUniqueSpecializations();

      expect(specializations.length, 2);
      expect(specializations, containsAll(['Anxiety', 'Trauma']));
      expect(specializations, orderedEquals(['Anxiety', 'Trauma'])); // Should be sorted
    });

    test('Should validate counselor selection', () {
      final available = MockCounselor(
        id: 'available',
        firstName: 'Available',
        lastName: 'Counselor',
        specialization: 'Test',
        availabilityStatus: 'available',
      );

      final busy = MockCounselor(
        id: 'busy',
        firstName: 'Busy',
        lastName: 'Counselor',
        specialization: 'Test',
        availabilityStatus: 'busy',
      );

      expect(selectionService.canSelectCounselor(available), true);
      expect(selectionService.canSelectCounselor(busy), false);

      expect(selectionService.getSelectionValidationMessage(available), isEmpty);
      expect(selectionService.getSelectionValidationMessage(busy), contains('busy'));
    });

    test('Should clear errors and reset correctly', () async {
      mockDatabase.setShouldThrowError(true);
      
      await selectionService.loadCounselors();
      expect(selectionService.errorMessage, isNotNull);
      
      selectionService.clearError();
      expect(selectionService.errorMessage, isNull);

      // Add some data and selection
      mockDatabase.setShouldThrowError(false);
      mockDatabase.seedCounselors([
        {
          'id': 'test',
          'first_name': 'Test',
          'last_name': 'User',
          'specialization': 'Test',
          'availability_status': 'available',
          'profile_picture': null,
        },
      ]);
      
      await selectionService.loadCounselors();
      selectionService.selectCounselor(selectionService.counselors[0]);
      
      expect(selectionService.counselors.length, 1);
      expect(selectionService.selectedCounselor, isNotNull);
      
      selectionService.reset();
      
      expect(selectionService.counselors.length, 0);
      expect(selectionService.selectedCounselor, isNull);
      expect(selectionService.isLoading, false);
      expect(selectionService.errorMessage, isNull);
    });
  });
}