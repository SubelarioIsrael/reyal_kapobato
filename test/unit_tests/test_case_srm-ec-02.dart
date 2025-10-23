// SRM-EC-02: Student can add emergency contact
// Test file for adding emergency contact functionality
// Mirrors logic in `student_contacts.dart` (_showContactDialog method for adding)

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

// Service class for adding emergency contacts
class StudentEmergencyContactAddService {
  final MockEmergencyContactDatabase _database;
  List<MockEmergencyContact> _emergencyContacts = [];
  bool _isProcessing = false;
  String? _errorMessage;

  StudentEmergencyContactAddService(this._database);

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
  group('SRM-EC-02: Student can add emergency contact', () {
    late MockEmergencyContactDatabase mockDatabase;
    late StudentEmergencyContactAddService addService;

    setUp(() {
      mockDatabase = MockEmergencyContactDatabase();
      addService = StudentEmergencyContactAddService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('should add emergency contact successfully', () async {
      final result = await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, true);
      expect(addService.isProcessing, false);
      expect(addService.errorMessage, isNull);
      expect(addService.getContactsCount(), 1);
      expect(addService.emergencyContacts[0].contactName, 'John Doe');
      expect(addService.emergencyContacts[0].relationship, 'Father');
      expect(addService.emergencyContacts[0].contactNumber, '09123456789');
    });

    test('should validate contact name is not empty', () async {
      final result = await addService.addEmergencyContact(
        userId: 'student1',
        contactName: '',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(addService.errorMessage, contains('Contact name cannot be empty'));
      expect(addService.getContactsCount(), 0);
    });

    test('should validate contact name with only whitespace', () async {
      final result = await addService.addEmergencyContact(
        userId: 'student1',
        contactName: '   ',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(addService.errorMessage, contains('Contact name cannot be empty'));
    });

    test('should validate relationship is not empty', () async {
      final result = await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: '',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(addService.errorMessage, contains('Relationship cannot be empty'));
      expect(addService.getContactsCount(), 0);
    });

    test('should validate relationship with only whitespace', () async {
      final result = await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: '   ',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(addService.errorMessage, contains('Relationship cannot be empty'));
    });

    test('should validate contact number is not empty', () async {
      final result = await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '',
      );

      expect(result, false);
      expect(addService.errorMessage, contains('Contact number cannot be empty'));
    });

    test('should validate phone number must be 11 digits (too short)', () async {
      final result = await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '0912345678', // 10 digits
      );

      expect(result, false);
      expect(addService.errorMessage, contains('must be 11 digits'));
      expect(addService.getContactsCount(), 0);
    });

    test('should validate phone number must be 11 digits (too long)', () async {
      final result = await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '091234567890', // 12 digits
      );

      expect(result, false);
      expect(addService.errorMessage, contains('must be 11 digits'));
    });

    test('should clean phone number with dashes before saving', () async {
      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '0912-345-6789',
      );

      await addService.loadEmergencyContacts('student1');
      expect(addService.emergencyContacts[0].contactNumber, '09123456789');
    });

    test('should clean phone number with spaces before saving', () async {
      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '0912 345 6789',
      );

      await addService.loadEmergencyContacts('student1');
      expect(addService.emergencyContacts[0].contactNumber, '09123456789');
    });

    test('should clean phone number with parentheses before saving', () async {
      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '(0912) 345-6789',
      );

      await addService.loadEmergencyContacts('student1');
      expect(addService.emergencyContacts[0].contactNumber, '09123456789');
    });

    test('should trim whitespace from contact name', () async {
      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: '  John Doe  ',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      await addService.loadEmergencyContacts('student1');
      expect(addService.emergencyContacts[0].contactName, 'John Doe');
    });

    test('should trim whitespace from relationship', () async {
      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: '  Father  ',
        contactNumber: '09123456789',
      );

      await addService.loadEmergencyContacts('student1');
      expect(addService.emergencyContacts[0].relationship, 'Father');
    });

    test('should trim all fields when adding contact', () async {
      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: '  John Doe  ',
        relationship: '  Father  ',
        contactNumber: ' 0912-345-6789 ',
      );

      await addService.loadEmergencyContacts('student1');
      expect(addService.emergencyContacts[0].contactName, 'John Doe');
      expect(addService.emergencyContacts[0].relationship, 'Father');
      expect(addService.emergencyContacts[0].contactNumber, '09123456789');
    });

    test('should add multiple contacts', () async {
      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'Jane Doe',
        relationship: 'Mother',
        contactNumber: '09987654321',
      );

      expect(addService.getContactsCount(), 2);
      expect(addService.emergencyContacts[0].contactName, 'John Doe');
      expect(addService.emergencyContacts[1].contactName, 'Jane Doe');
    });

    test('should add three different contacts sequentially', () async {
      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'Jane Doe',
        relationship: 'Mother',
        contactNumber: '09987654321',
      );

      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'Bob Smith',
        relationship: 'Brother',
        contactNumber: '09111222333',
      );

      expect(addService.getContactsCount(), 3);
    });

    test('should store user ID correctly', () async {
      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(addService.emergencyContacts[0].userId, 'student1');
    });

    test('should auto-generate contact IDs', () async {
      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'Jane Doe',
        relationship: 'Mother',
        contactNumber: '09987654321',
      );

      expect(addService.emergencyContacts[0].contactId, 1);
      expect(addService.emergencyContacts[1].contactId, 2);
    });

    test('should handle database errors gracefully', () async {
      mockDatabase.setShouldThrowError(true);

      final result = await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09123456789',
      );

      expect(result, false);
      expect(addService.errorMessage, contains('Error creating emergency contact'));
      expect(addService.isProcessing, false);
    });

    test('should clear error on successful add', () async {
      // First fail to set error
      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: '',
        relationship: 'Father',
        contactNumber: '09123456789',
      );
      expect(addService.errorMessage, isNotNull);

      // Then succeed to clear error
      await addService.addEmergencyContact(
        userId: 'student1',
        contactName: 'John Doe',
        relationship: 'Father',
        contactNumber: '09123456789',
      );
      expect(addService.errorMessage, isNull);
    });

    test('should validate contact name helper returns true for valid name', () {
      expect(addService.validateContactName('John Doe'), true);
    });

    test('should validate contact name helper returns false for empty name', () {
      expect(addService.validateContactName(''), false);
      expect(addService.validateContactName('  '), false);
    });

    test('should validate relationship helper returns true for valid relationship', () {
      expect(addService.validateRelationship('Father'), true);
    });

    test('should validate relationship helper returns false for empty relationship', () {
      expect(addService.validateRelationship(''), false);
      expect(addService.validateRelationship('   '), false);
    });

    test('should validate phone number helper returns true for 11 digits', () {
      expect(addService.validatePhoneNumber('09123456789'), true);
      expect(addService.validatePhoneNumber('0912-345-6789'), true);
    });

    test('should validate phone number helper returns false for invalid length', () {
      expect(addService.validatePhoneNumber('0912345678'), false);
      expect(addService.validatePhoneNumber('091234567890'), false);
    });

    test('should get contact name error for empty name', () {
      expect(addService.getContactNameError(''), isNotNull);
      expect(addService.getContactNameError('John'), isNull);
    });

    test('should get relationship error for empty relationship', () {
      expect(addService.getRelationshipError(''), isNotNull);
      expect(addService.getRelationshipError('Father'), isNull);
    });

    test('should get phone number error for empty number', () {
      expect(addService.getPhoneNumberError(''), isNotNull);
    });

    test('should get phone number error for invalid length', () {
      expect(addService.getPhoneNumberError('0912345678'), isNotNull);
      expect(addService.getPhoneNumberError('09123456789'), isNull);
    });

    test('should clean phone number helper remove non-digits', () {
      expect(addService.cleanPhoneNumber('09123456789'), '09123456789');
      expect(addService.cleanPhoneNumber('0912-345-6789'), '09123456789');
      expect(addService.cleanPhoneNumber('0912 345 6789'), '09123456789');
    });
  });
}
