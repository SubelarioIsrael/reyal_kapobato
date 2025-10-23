// SRM-EC-01: Student can view emergency contact list
// Requirement: Students can view their emergency contacts with name, relationship, and phone
// Mirrors logic in `student_contacts.dart` (_loadContacts method)

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent an emergency contact
class MockEmergencyContact {
  final int contactId;
  final String userId;
  final String contactName;
  final String relationship;
  final String contactNumber;

  MockEmergencyContact({
    required this.contactId,
    required this.userId,
    required this.contactName,
    required this.relationship,
    required this.contactNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'contact_id': contactId,
      'user_id': userId,
      'contact_name': contactName,
      'relationship': relationship,
      'contact_number': contactNumber,
    };
  }

  factory MockEmergencyContact.fromMap(Map<String, dynamic> map) {
    return MockEmergencyContact(
      contactId: map['contact_id'],
      userId: map['user_id'],
      contactName: map['contact_name'],
      relationship: map['relationship'],
      contactNumber: map['contact_number'],
    );
  }
}

// Mock database for emergency contacts
class MockEmergencyContactDatabase {
  Map<String, List<Map<String, dynamic>>> _userContacts = {};
  bool _shouldThrowError = false;

  void seedEmergencyContacts(String userId, List<Map<String, dynamic>> contacts) {
    _userContacts[userId] = contacts;
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts(String userId) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (_shouldThrowError) {
      throw Exception('Error loading emergency contacts');
    }

    return _userContacts[userId] ?? [];
  }

  void clear() {
    _userContacts.clear();
    _shouldThrowError = false;
  }
}

// Service class for viewing emergency contacts
class StudentEmergencyContactViewService {
  final MockEmergencyContactDatabase _database;
  List<MockEmergencyContact> _emergencyContacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  StudentEmergencyContactViewService(this._database);

  List<MockEmergencyContact> get emergencyContacts => _emergencyContacts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadEmergencyContacts(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;

      final contactsData = await _database.getEmergencyContacts(userId);
      _emergencyContacts = contactsData.map((data) => MockEmergencyContact.fromMap(data)).toList();

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _emergencyContacts = [];
    }
  }

  bool hasEmergencyContacts() {
    return _emergencyContacts.isNotEmpty;
  }

  int getContactsCount() {
    return _emergencyContacts.length;
  }

  MockEmergencyContact? findContactById(int contactId) {
    try {
      return _emergencyContacts.firstWhere((contact) => contact.contactId == contactId);
    } catch (e) {
      return null;
    }
  }

  List<MockEmergencyContact> searchContacts(String query) {
    if (query.isEmpty) return _emergencyContacts;

    return _emergencyContacts.where((contact) {
      return contact.contactName.toLowerCase().contains(query.toLowerCase()) ||
          contact.relationship.toLowerCase().contains(query.toLowerCase()) ||
          contact.contactNumber.contains(query);
    }).toList();
  }

  List<MockEmergencyContact> getContactsByRelationship(String relationship) {
    return _emergencyContacts
        .where((contact) => contact.relationship.toLowerCase() == relationship.toLowerCase())
        .toList();
  }

  String getEmptyStateMessage() {
    return 'No emergency contacts added yet';
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _emergencyContacts.clear();
    _isLoading = false;
    _errorMessage = null;
  }

  Map<String, dynamic> getViewStatistics() {
    final relationships = <String, int>{};
    for (var contact in _emergencyContacts) {
      relationships[contact.relationship] = (relationships[contact.relationship] ?? 0) + 1;
    }

    return {
      'total_contacts': _emergencyContacts.length,
      'relationships': relationships,
      'is_loaded': !_isLoading && _errorMessage == null,
    };
  }

  String formatPhoneNumber(String phoneNumber) {
    // Remove non-digits
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Format as 09XX-XXX-XXXX for 11-digit Philippine numbers
    if (digitsOnly.length == 11 && digitsOnly.startsWith('09')) {
      return '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4, 7)}-${digitsOnly.substring(7)}';
    }
    
    return digitsOnly;
  }

  bool validatePhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length == 11;
  }
}

void main() {
  group('SRM-EC-01: Student can view emergency contact list', () {
    late MockEmergencyContactDatabase mockDatabase;
    late StudentEmergencyContactViewService viewService;

    setUp(() {
      mockDatabase = MockEmergencyContactDatabase();
      viewService = StudentEmergencyContactViewService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('Should load emergency contacts successfully', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
        {
          'contact_id': 2,
          'user_id': 'student1',
          'contact_name': 'Jane Doe',
          'relationship': 'Mother',
          'contact_number': '09987654321',
        },
      ]);

      await viewService.loadEmergencyContacts('student1');

      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, isNull);
      expect(viewService.emergencyContacts.length, 2);
      expect(viewService.hasEmergencyContacts(), true);
    });

    test('Should handle empty emergency contacts', () async {
      mockDatabase.seedEmergencyContacts('student1', []);

      await viewService.loadEmergencyContacts('student1');

      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, isNull);
      expect(viewService.emergencyContacts.length, 0);
      expect(viewService.hasEmergencyContacts(), false);
      expect(viewService.getEmptyStateMessage(), 'No emergency contacts added yet');
    });

    test('Should handle loading errors', () async {
      mockDatabase.setShouldThrowError(true);

      await viewService.loadEmergencyContacts('student1');

      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, contains('Error loading emergency contacts'));
      expect(viewService.emergencyContacts.length, 0);
    });

    test('Should display contact name, relationship, and phone number', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await viewService.loadEmergencyContacts('student1');

      final contact = viewService.emergencyContacts[0];
      expect(contact.contactName, 'John Doe');
      expect(contact.relationship, 'Father');
      expect(contact.contactNumber, '09123456789');
    });

    test('Should find contact by ID', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
        {
          'contact_id': 2,
          'user_id': 'student1',
          'contact_name': 'Jane Doe',
          'relationship': 'Mother',
          'contact_number': '09987654321',
        },
      ]);

      await viewService.loadEmergencyContacts('student1');

      final found = viewService.findContactById(1);
      expect(found, isNotNull);
      expect(found!.contactName, 'John Doe');

      final notFound = viewService.findContactById(999);
      expect(notFound, isNull);
    });

    test('Should search contacts by name', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
        {
          'contact_id': 2,
          'user_id': 'student1',
          'contact_name': 'Jane Smith',
          'relationship': 'Mother',
          'contact_number': '09987654321',
        },
      ]);

      await viewService.loadEmergencyContacts('student1');

      final results = viewService.searchContacts('John');
      expect(results.length, 1);
      expect(results[0].contactName, 'John Doe');
    });

    test('Should search contacts by relationship', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
        {
          'contact_id': 2,
          'user_id': 'student1',
          'contact_name': 'Jane Doe',
          'relationship': 'Mother',
          'contact_number': '09987654321',
        },
      ]);

      await viewService.loadEmergencyContacts('student1');

      final results = viewService.searchContacts('Father');
      expect(results.length, 1);
      expect(results[0].relationship, 'Father');
    });

    test('Should search contacts by phone number', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
        {
          'contact_id': 2,
          'user_id': 'student1',
          'contact_name': 'Jane Doe',
          'relationship': 'Mother',
          'contact_number': '09987654321',
        },
      ]);

      await viewService.loadEmergencyContacts('student1');

      final results = viewService.searchContacts('0912');
      expect(results.length, 1);
      expect(results[0].contactNumber, '09123456789');
    });

    test('Should get contacts by relationship', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
        {
          'contact_id': 2,
          'user_id': 'student1',
          'contact_name': 'Jane Doe',
          'relationship': 'Mother',
          'contact_number': '09987654321',
        },
        {
          'contact_id': 3,
          'user_id': 'student1',
          'contact_name': 'Jack Doe',
          'relationship': 'Father',
          'contact_number': '09111222333',
        },
      ]);

      await viewService.loadEmergencyContacts('student1');

      final fathers = viewService.getContactsByRelationship('Father');
      expect(fathers.length, 2);
    });

    test('Should get contacts count', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
        {
          'contact_id': 2,
          'user_id': 'student1',
          'contact_name': 'Jane Doe',
          'relationship': 'Mother',
          'contact_number': '09987654321',
        },
      ]);

      await viewService.loadEmergencyContacts('student1');

      expect(viewService.getContactsCount(), 2);
    });

    test('Should generate view statistics', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
        {
          'contact_id': 2,
          'user_id': 'student1',
          'contact_name': 'Jane Doe',
          'relationship': 'Mother',
          'contact_number': '09987654321',
        },
        {
          'contact_id': 3,
          'user_id': 'student1',
          'contact_name': 'Jack Doe',
          'relationship': 'Father',
          'contact_number': '09111222333',
        },
      ]);

      await viewService.loadEmergencyContacts('student1');

      final stats = viewService.getViewStatistics();

      expect(stats['total_contacts'], 3);
      expect(stats['relationships']['Father'], 2);
      expect(stats['relationships']['Mother'], 1);
      expect(stats['is_loaded'], true);
    });

    test('Should format phone numbers correctly', () {
      expect(viewService.formatPhoneNumber('09123456789'), '0912-345-6789');
      expect(viewService.formatPhoneNumber('0912-345-6789'), '0912-345-6789');
      expect(viewService.formatPhoneNumber('0912 345 6789'), '0912-345-6789');
    });

    test('Should validate phone numbers', () {
      expect(viewService.validatePhoneNumber('09123456789'), true);
      expect(viewService.validatePhoneNumber('0912-345-6789'), true);
      expect(viewService.validatePhoneNumber('0912345678'), false);
      expect(viewService.validatePhoneNumber('091234567890'), false);
    });

    test('Should clear error message', () async {
      mockDatabase.setShouldThrowError(true);

      await viewService.loadEmergencyContacts('student1');

      expect(viewService.errorMessage, isNotNull);

      viewService.clearError();
      expect(viewService.errorMessage, isNull);
    });

    test('Should reset service state', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await viewService.loadEmergencyContacts('student1');

      expect(viewService.emergencyContacts.length, 1);

      viewService.reset();

      expect(viewService.emergencyContacts.length, 0);
      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, isNull);
    });

    test('Should handle case-insensitive search', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await viewService.loadEmergencyContacts('student1');

      final results1 = viewService.searchContacts('JOHN');
      expect(results1.length, 1);

      final results2 = viewService.searchContacts('father');
      expect(results2.length, 1);
    });

    test('Should return all contacts when search query is empty', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
        {
          'contact_id': 2,
          'user_id': 'student1',
          'contact_name': 'Jane Doe',
          'relationship': 'Mother',
          'contact_number': '09987654321',
        },
      ]);

      await viewService.loadEmergencyContacts('student1');

      final results = viewService.searchContacts('');
      expect(results.length, 2);
    });
  });
}
