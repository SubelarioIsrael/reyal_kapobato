// SRM-EC-03: Student can update emergency contact
// Test file for updating emergency contact functionality
// Mirrors logic in `student_contacts.dart` (_showContactDialog method for editing)

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

  Future<bool> updateEmergencyContact(int contactId, String userId, Map<String, dynamic> updates) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (_shouldThrowError) {
      throw Exception('Error updating emergency contact');
    }

    final userContacts = _userContacts[userId] ?? [];
    final contactIndex = userContacts.indexWhere((contact) => contact['contact_id'] == contactId);

    if (contactIndex == -1) {
      return false;
    }

    userContacts[contactIndex] = {
      ...userContacts[contactIndex],
      ...updates,
    };

    return true;
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts(String userId) async {
    await Future.delayed(Duration(milliseconds: 50));
    return _userContacts[userId] ?? [];
  }

  void clear() {
    _userContacts.clear();
    _shouldThrowError = false;
  }
}

// Service class for updating emergency contacts
class StudentEmergencyContactUpdateService {
  final MockEmergencyContactDatabase _database;
  List<MockEmergencyContact> _emergencyContacts = [];
  bool _isProcessing = false;
  String? _errorMessage;

  StudentEmergencyContactUpdateService(this._database);

  List<MockEmergencyContact> get emergencyContacts => _emergencyContacts;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  Future<void> loadEmergencyContacts(String userId) async {
    try {
      final contactsData = await _database.getEmergencyContacts(userId);
      _emergencyContacts = contactsData.map((data) => MockEmergencyContact.fromMap(data)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _emergencyContacts = [];
    }
  }

  // Update emergency contact
  Future<bool> updateEmergencyContact({
    required int contactId,
    required String userId,
    required String contactName,
    required String relationship,
    required String contactNumber,
  }) async {
    try {
      _isProcessing = true;
      _errorMessage = null;

      // Validate input
      if (contactName.trim().isEmpty) {
        throw Exception('Contact name cannot be empty');
      }
      if (relationship.trim().isEmpty) {
        throw Exception('Relationship cannot be empty');
      }
      if (contactNumber.trim().isEmpty) {
        throw Exception('Contact number cannot be empty');
      }

      // Clean and validate phone number
      final cleanedNumber = contactNumber.replaceAll(RegExp(r'\D'), '');
      if (cleanedNumber.length != 11) {
        throw Exception('Contact number must be 11 digits');
      }

      final success = await _database.updateEmergencyContact(contactId, userId, {
        'contact_name': contactName.trim(),
        'relationship': relationship.trim(),
        'contact_number': cleanedNumber,
      });

      if (success) {
        await loadEmergencyContacts(userId);
      }

      _isProcessing = false;
      return success;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = e.toString();
      return false;
    }
  }

  // Validation methods
  bool validateContactName(String name) {
    return name.trim().isNotEmpty;
  }

  bool validateRelationship(String relationship) {
    return relationship.trim().isNotEmpty;
  }

  bool validatePhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length == 11;
  }

  String? getContactNameError(String name) {
    if (name.trim().isEmpty) {
      return 'Contact name cannot be empty';
    }
    return null;
  }

  String? getRelationshipError(String relationship) {
    if (relationship.trim().isEmpty) {
      return 'Relationship cannot be empty';
    }
    return null;
  }

  String? getPhoneNumberError(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) {
      return 'Contact number cannot be empty';
    }
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 11) {
      return 'Contact number must be 11 digits';
    }
    return null;
  }

  MockEmergencyContact? findContactById(int contactId) {
    try {
      return _emergencyContacts.firstWhere((contact) => contact.contactId == contactId);
    } catch (e) {
      return null;
    }
  }

  int getContactsCount() {
    return _emergencyContacts.length;
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _emergencyContacts.clear();
    _isProcessing = false;
    _errorMessage = null;
  }
}

void main() {
  group('SRM-EC-03: Student can update emergency contact', () {
    late MockEmergencyContactDatabase mockDatabase;
    late StudentEmergencyContactUpdateService updateService;

    setUp(() {
      mockDatabase = MockEmergencyContactDatabase();
      updateService = StudentEmergencyContactUpdateService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('should update emergency contact successfully', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      final result = await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Updated',
        relationship: 'Dad',
        contactNumber: '09111222333',
      );

      expect(result, true);
      expect(updateService.isProcessing, false);
      expect(updateService.errorMessage, isNull);
      expect(updateService.emergencyContacts[0].contactName, 'John Updated');
      expect(updateService.emergencyContacts[0].relationship, 'Dad');
      expect(updateService.emergencyContacts[0].contactNumber, '09111222333');
    });

    test('should update only contact name', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Updated',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(updateService.emergencyContacts[0].contactName, 'John Updated');
      expect(updateService.emergencyContacts[0].relationship, 'Father');
      expect(updateService.emergencyContacts[0].contactNumber, '09123456789');
    });

    test('should update only relationship', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Dad',
        contactNumber: '09123456789',
      );

      expect(updateService.emergencyContacts[0].relationship, 'Dad');
    });

    test('should update only phone number', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09987654321',
      );

      expect(updateService.emergencyContacts[0].contactNumber, '09987654321');
    });

    test('should validate contact name is not empty when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      final result = await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: '',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(updateService.errorMessage, contains('Contact name cannot be empty'));
    });

    test('should validate contact name with only whitespace when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      final result = await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: '   ',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(updateService.errorMessage, contains('Contact name cannot be empty'));
    });

    test('should validate relationship is not empty when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      final result = await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Doe',
        relationship: '',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(updateService.errorMessage, contains('Relationship cannot be empty'));
    });

    test('should validate phone number is not empty when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      final result = await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '',
      );

      expect(result, false);
      expect(updateService.errorMessage, contains('Contact number cannot be empty'));
    });

    test('should validate phone number must be 11 digits when updating (too short)', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      final result = await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '0912345678', // 10 digits
      );

      expect(result, false);
      expect(updateService.errorMessage, contains('must be 11 digits'));
    });

    test('should validate phone number must be 11 digits when updating (too long)', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      final result = await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '091234567890', // 12 digits
      );

      expect(result, false);
      expect(updateService.errorMessage, contains('must be 11 digits'));
    });

    test('should handle non-existent contact when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', []);

      await updateService.loadEmergencyContacts('student1');

      final result = await updateService.updateEmergencyContact(
        contactId: 999,
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, false);
    });

    test('should preserve contact ID when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 5,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      await updateService.updateEmergencyContact(
        contactId: 5,
        userId: 'student1',
        contactName: 'John Updated',
        relationship: 'Dad',
        contactNumber: '09111222333',
      );

      expect(updateService.emergencyContacts[0].contactId, 5);
    });

    test('should trim whitespace from contact name when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: '  Updated Name  ',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(updateService.emergencyContacts[0].contactName, 'Updated Name');
    });

    test('should trim whitespace from relationship when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Doe',
        relationship: '  Updated Rel  ',
        contactNumber: '09123456789',
      );

      expect(updateService.emergencyContacts[0].relationship, 'Updated Rel');
    });

    test('should clean phone number with dashes when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '0911-122-2333',
      );

      expect(updateService.emergencyContacts[0].contactNumber, '09111222333');
    });

    test('should not affect other contacts when updating', () async {
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

      await updateService.loadEmergencyContacts('student1');

      await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Updated',
        relationship: 'Dad',
        contactNumber: '09111222333',
      );

      // First contact updated
      expect(updateService.emergencyContacts[0].contactName, 'John Updated');
      
      // Second contact unchanged
      expect(updateService.emergencyContacts[1].contactName, 'Jane Doe');
      expect(updateService.emergencyContacts[1].relationship, 'Mother');
      expect(updateService.emergencyContacts[1].contactNumber, '09987654321');
    });

    test('should handle database errors when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');
      mockDatabase.setShouldThrowError(true);

      final result = await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'Updated Name',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(updateService.errorMessage, contains('Error updating emergency contact'));
      expect(updateService.isProcessing, false);
    });

    test('should clear error on successful update', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      // First fail to set error
      await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: '',
        relationship: 'Father',
        contactNumber: '09123456789',
      );
      expect(updateService.errorMessage, isNotNull);

      // Then succeed to clear error
      await updateService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Updated',
        relationship: 'Father',
        contactNumber: '09123456789',
      );
      expect(updateService.errorMessage, isNull);
    });

    test('should validate contact name helper', () {
      expect(updateService.validateContactName('John Doe'), true);
      expect(updateService.validateContactName(''), false);
      expect(updateService.validateContactName('  '), false);
    });

    test('should validate relationship helper', () {
      expect(updateService.validateRelationship('Father'), true);
      expect(updateService.validateRelationship(''), false);
      expect(updateService.validateRelationship('   '), false);
    });

    test('should validate phone number helper', () {
      expect(updateService.validatePhoneNumber('09123456789'), true);
      expect(updateService.validatePhoneNumber('0912-345-6789'), true);
      expect(updateService.validatePhoneNumber('0912345678'), false);
      expect(updateService.validatePhoneNumber('091234567890'), false);
    });

    test('should get contact name error messages', () {
      expect(updateService.getContactNameError(''), isNotNull);
      expect(updateService.getContactNameError('John'), isNull);
    });

    test('should get relationship error messages', () {
      expect(updateService.getRelationshipError(''), isNotNull);
      expect(updateService.getRelationshipError('Father'), isNull);
    });

    test('should get phone number error messages', () {
      expect(updateService.getPhoneNumberError(''), isNotNull);
      expect(updateService.getPhoneNumberError('0912345678'), isNotNull);
      expect(updateService.getPhoneNumberError('09123456789'), isNull);
    });

    test('should find contact by ID', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await updateService.loadEmergencyContacts('student1');

      final contact = updateService.findContactById(1);
      expect(contact, isNotNull);
      expect(contact!.contactName, 'John Doe');
    });

    test('should return null for non-existent contact ID', () async {
      mockDatabase.seedEmergencyContacts('student1', []);

      await updateService.loadEmergencyContacts('student1');

      final contact = updateService.findContactById(999);
      expect(contact, isNull);
    });
  });
}
