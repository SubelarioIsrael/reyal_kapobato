// SRM-EC-02: Student can add emergency contact
// SRM-EC-03: Student can update emergency contact
// SRM-EC-04: Student can delete emergency contact
// Combined test file for all emergency contact management operations
// Mirrors logic in `student_contacts.dart` (_showContactDialog, _deleteContact methods)

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
  int _nextId = 1;

  void seedEmergencyContacts(String userId, List<Map<String, dynamic>> contacts) {
    _userContacts[userId] = contacts;
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  Future<int> createEmergencyContact(Map<String, dynamic> contact) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (_shouldThrowError) {
      throw Exception('Error creating emergency contact');
    }

    final contactWithId = {
      ...contact,
      'contact_id': _nextId,
    };

    final userId = contact['user_id'];
    if (!_userContacts.containsKey(userId)) {
      _userContacts[userId] = [];
    }
    _userContacts[userId]!.add(contactWithId);
    
    return _nextId++;
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

  Future<bool> deleteEmergencyContact(int contactId, String userId) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (_shouldThrowError) {
      throw Exception('Error deleting emergency contact');
    }

    final userContacts = _userContacts[userId] ?? [];
    final contactIndex = userContacts.indexWhere((contact) => contact['contact_id'] == contactId);

    if (contactIndex == -1) {
      return false;
    }

    userContacts.removeAt(contactIndex);
    return true;
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts(String userId) async {
    await Future.delayed(Duration(milliseconds: 50));
    return _userContacts[userId] ?? [];
  }

  void clear() {
    _userContacts.clear();
    _shouldThrowError = false;
    _nextId = 1;
  }
}

// Service class for managing emergency contacts
class StudentEmergencyContactManageService {
  final MockEmergencyContactDatabase _database;
  List<MockEmergencyContact> _emergencyContacts = [];
  bool _isProcessing = false;
  String? _errorMessage;
  bool _showConfirmationDialog = false;
  int? _pendingDeleteId;

  StudentEmergencyContactManageService(this._database);

  List<MockEmergencyContact> get emergencyContacts => _emergencyContacts;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get showConfirmationDialog => _showConfirmationDialog;
  int? get pendingDeleteId => _pendingDeleteId;

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

  // Add emergency contact
  Future<bool> addEmergencyContact({
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

      // Clean and validate phone number (11 digits)
      final cleanedNumber = contactNumber.replaceAll(RegExp(r'\D'), '');
      if (cleanedNumber.length != 11) {
        throw Exception('Contact number must be 11 digits');
      }

      await _database.createEmergencyContact({
        'user_id': userId,
        'contact_name': contactName.trim(),
        'relationship': relationship.trim(),
        'contact_number': cleanedNumber,
      });

      await loadEmergencyContacts(userId);

      _isProcessing = false;
      return true;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = e.toString();
      return false;
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

  // Delete emergency contact
  void requestDeleteContact(int contactId) {
    _pendingDeleteId = contactId;
    _showConfirmationDialog = true;
  }

  void cancelDeleteContact() {
    _pendingDeleteId = null;
    _showConfirmationDialog = false;
  }

  Future<bool> confirmDeleteContact(String userId) async {
    if (_pendingDeleteId == null) {
      return false;
    }

    try {
      _isProcessing = true;
      _errorMessage = null;

      final success = await _database.deleteEmergencyContact(_pendingDeleteId!, userId);

      if (success) {
        await loadEmergencyContacts(userId);
      }

      _isProcessing = false;
      _showConfirmationDialog = false;
      _pendingDeleteId = null;

      return success;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = e.toString();
      _showConfirmationDialog = false;
      _pendingDeleteId = null;
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

  String cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'\D'), '');
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
    _showConfirmationDialog = false;
    _pendingDeleteId = null;
  }

  String getDeleteConfirmationMessage(int contactId) {
    final contact = findContactById(contactId);
    if (contact == null) {
      return 'Are you sure you want to delete this contact?';
    }
    return 'Are you sure you want to delete ${contact.contactName}?';
  }
}

void main() {
  group('SRM-EC-02: Student can add emergency contact', () {
    late MockEmergencyContactDatabase mockDatabase;
    late StudentEmergencyContactManageService manageService;

    setUp(() {
      mockDatabase = MockEmergencyContactDatabase();
      manageService = StudentEmergencyContactManageService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('Should add emergency contact successfully', () async {
      final result = await manageService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, true);
      expect(manageService.isProcessing, false);
      expect(manageService.errorMessage, isNull);
      expect(manageService.getContactsCount(), 1);
    });

    test('Should validate contact name', () async {
      final result = await manageService.addEmergencyContact(
        userId: 'student1',
        contactName: '',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(manageService.errorMessage, contains('Contact name cannot be empty'));
    });

    test('Should validate relationship', () async {
      final result = await manageService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: '',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(manageService.errorMessage, contains('Relationship cannot be empty'));
    });

    test('Should validate phone number (11 digits)', () async {
      final result1 = await manageService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '0912345678', // 10 digits
      );

      expect(result1, false);
      expect(manageService.errorMessage, contains('must be 11 digits'));

      final result2 = await manageService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '091234567890', // 12 digits
      );

      expect(result2, false);
    });

    test('Should clean phone number before saving', () async {
      await manageService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '0912-345-6789',
      );

      await manageService.loadEmergencyContacts('student1');
      expect(manageService.emergencyContacts[0].contactNumber, '09123456789');
    });

    test('Should trim whitespace from inputs', () async {
      await manageService.addEmergencyContact(
        userId: 'student1',
        contactName: '  John Doe  ',
        relationship: '  Father  ',
        contactNumber: '09123456789',
      );

      await manageService.loadEmergencyContacts('student1');
      expect(manageService.emergencyContacts[0].contactName, 'John Doe');
      expect(manageService.emergencyContacts[0].relationship, 'Father');
    });

    test('Should add multiple contacts', () async {
      await manageService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      await manageService.addEmergencyContact(
        userId: 'student1',
        contactName: 'Jane Doe',
        relationship: 'Mother',
        contactNumber: '09987654321',
      );

      expect(manageService.getContactsCount(), 2);
    });

    test('Should handle database errors', () async {
      mockDatabase.setShouldThrowError(true);

      final result = await manageService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(manageService.errorMessage, contains('Error creating emergency contact'));
    });
  });

  group('SRM-EC-03: Student can update emergency contact', () {
    late MockEmergencyContactDatabase mockDatabase;
    late StudentEmergencyContactManageService manageService;

    setUp(() {
      mockDatabase = MockEmergencyContactDatabase();
      manageService = StudentEmergencyContactManageService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('Should update emergency contact successfully', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await manageService.loadEmergencyContacts('student1');

      final result = await manageService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Updated',
        relationship: 'Dad',
        contactNumber: '09111222333',
      );

      expect(result, true);
      expect(manageService.emergencyContacts[0].contactName, 'John Updated');
      expect(manageService.emergencyContacts[0].relationship, 'Dad');
      expect(manageService.emergencyContacts[0].contactNumber, '09111222333');
    });

    test('Should validate contact name when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await manageService.loadEmergencyContacts('student1');

      final result = await manageService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: '',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(manageService.errorMessage, contains('Contact name cannot be empty'));
    });

    test('Should validate phone number when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await manageService.loadEmergencyContacts('student1');

      final result = await manageService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '0912345678', // 10 digits
      );

      expect(result, false);
      expect(manageService.errorMessage, contains('must be 11 digits'));
    });

    test('Should handle non-existent contact', () async {
      mockDatabase.seedEmergencyContacts('student1', []);

      await manageService.loadEmergencyContacts('student1');

      final result = await manageService.updateEmergencyContact(
        contactId: 999,
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, false);
    });

    test('Should trim whitespace when updating', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await manageService.loadEmergencyContacts('student1');

      await manageService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: '  Updated Name  ',
        relationship: '  Updated Rel  ',
        contactNumber: '09111222333',
      );

      expect(manageService.emergencyContacts[0].contactName, 'Updated Name');
      expect(manageService.emergencyContacts[0].relationship, 'Updated Rel');
    });

    test('Should handle database errors', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await manageService.loadEmergencyContacts('student1');
      mockDatabase.setShouldThrowError(true);

      final result = await manageService.updateEmergencyContact(
        contactId: 1,
        userId: 'student1',
        contactName: 'Updated Name',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(manageService.errorMessage, contains('Error updating emergency contact'));
    });
  });

  group('SRM-EC-04: Student can delete emergency contact', () {
    late MockEmergencyContactDatabase mockDatabase;
    late StudentEmergencyContactManageService manageService;

    setUp(() {
      mockDatabase = MockEmergencyContactDatabase();
      manageService = StudentEmergencyContactManageService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('Should delete emergency contact successfully', () async {
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

      await manageService.loadEmergencyContacts('student1');
      expect(manageService.getContactsCount(), 2);

      manageService.requestDeleteContact(1);
      expect(manageService.showConfirmationDialog, true);
      expect(manageService.pendingDeleteId, 1);

      final result = await manageService.confirmDeleteContact('student1');

      expect(result, true);
      expect(manageService.getContactsCount(), 1);
      expect(manageService.emergencyContacts[0].contactId, 2);
      expect(manageService.showConfirmationDialog, false);
      expect(manageService.pendingDeleteId, isNull);
    });

    test('Should show confirmation dialog before deleting', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await manageService.loadEmergencyContacts('student1');

      manageService.requestDeleteContact(1);

      expect(manageService.showConfirmationDialog, true);
      expect(manageService.pendingDeleteId, 1);
      expect(manageService.getContactsCount(), 1); // Not deleted yet
    });

    test('Should cancel delete request', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await manageService.loadEmergencyContacts('student1');

      manageService.requestDeleteContact(1);
      expect(manageService.showConfirmationDialog, true);

      manageService.cancelDeleteContact();

      expect(manageService.showConfirmationDialog, false);
      expect(manageService.pendingDeleteId, isNull);
      expect(manageService.getContactsCount(), 1); // Contact still exists
    });

    test('Should get delete confirmation message', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await manageService.loadEmergencyContacts('student1');

      final message = manageService.getDeleteConfirmationMessage(1);
      expect(message, contains('John Doe'));
    });

    test('Should handle non-existent contact deletion', () async {
      mockDatabase.seedEmergencyContacts('student1', []);

      await manageService.loadEmergencyContacts('student1');

      manageService.requestDeleteContact(999);
      final result = await manageService.confirmDeleteContact('student1');

      expect(result, false);
    });

    test('Should handle database errors', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await manageService.loadEmergencyContacts('student1');
      mockDatabase.setShouldThrowError(true);

      manageService.requestDeleteContact(1);
      final result = await manageService.confirmDeleteContact('student1');

      expect(result, false);
      expect(manageService.errorMessage, contains('Error deleting emergency contact'));
    });

    test('Should not delete without confirmation', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await manageService.loadEmergencyContacts('student1');

      final result = await manageService.confirmDeleteContact('student1');

      expect(result, false);
      expect(manageService.getContactsCount(), 1); // Not deleted
    });
  });

  group('Validation Helper Methods', () {
    late StudentEmergencyContactManageService manageService;

    setUp(() {
      manageService = StudentEmergencyContactManageService(MockEmergencyContactDatabase());
    });

    test('Should validate contact name', () {
      expect(manageService.validateContactName('John Doe'), true);
      expect(manageService.validateContactName(''), false);
      expect(manageService.validateContactName('  '), false);
    });

    test('Should validate relationship', () {
      expect(manageService.validateRelationship('Father'), true);
      expect(manageService.validateRelationship(''), false);
      expect(manageService.validateRelationship('   '), false);
    });

    test('Should validate phone number', () {
      expect(manageService.validatePhoneNumber('09123456789'), true);
      expect(manageService.validatePhoneNumber('0912-345-6789'), true);
      expect(manageService.validatePhoneNumber('0912345678'), false);
      expect(manageService.validatePhoneNumber('091234567890'), false);
    });

    test('Should clean phone number', () {
      expect(manageService.cleanPhoneNumber('09123456789'), '09123456789');
      expect(manageService.cleanPhoneNumber('0912-345-6789'), '09123456789');
      expect(manageService.cleanPhoneNumber('0912 345 6789'), '09123456789');
    });

    test('Should get validation error messages', () {
      expect(manageService.getContactNameError(''), isNotNull);
      expect(manageService.getContactNameError('John'), isNull);

      expect(manageService.getRelationshipError(''), isNotNull);
      expect(manageService.getRelationshipError('Father'), isNull);

      expect(manageService.getPhoneNumberError(''), isNotNull);
      expect(manageService.getPhoneNumberError('0912345678'), isNotNull);
      expect(manageService.getPhoneNumberError('09123456789'), isNull);
    });
  });
}
