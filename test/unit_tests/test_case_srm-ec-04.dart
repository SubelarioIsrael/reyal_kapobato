// SRM-EC-04: Student can delete emergency contact
// Test file for deleting emergency contact functionality
// Mirrors logic in `student_contacts.dart` (_deleteContact method)

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
  }
}

// Service class for deleting emergency contacts
class StudentEmergencyContactDeleteService {
  final MockEmergencyContactDatabase _database;
  List<MockEmergencyContact> _emergencyContacts = [];
  bool _isProcessing = false;
  String? _errorMessage;
  bool _showConfirmationDialog = false;
  int? _pendingDeleteId;

  StudentEmergencyContactDeleteService(this._database);

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

  // Delete emergency contact - two-step process
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

  String getDeleteConfirmationMessage(int contactId) {
    final contact = findContactById(contactId);
    if (contact == null) {
      return 'Are you sure you want to delete this contact?';
    }
    return 'Are you sure you want to delete ${contact.contactName}?';
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
}

void main() {
  group('SRM-EC-04: Student can delete emergency contact', () {
    late MockEmergencyContactDatabase mockDatabase;
    late StudentEmergencyContactDeleteService deleteService;

    setUp(() {
      mockDatabase = MockEmergencyContactDatabase();
      deleteService = StudentEmergencyContactDeleteService(mockDatabase);
    });

    tearDown(() {
      mockDatabase.clear();
    });

    test('should delete emergency contact successfully', () async {
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

      await deleteService.loadEmergencyContacts('student1');
      expect(deleteService.getContactsCount(), 2);

      deleteService.requestDeleteContact(1);
      expect(deleteService.showConfirmationDialog, true);
      expect(deleteService.pendingDeleteId, 1);

      final result = await deleteService.confirmDeleteContact('student1');

      expect(result, true);
      expect(deleteService.isProcessing, false);
      expect(deleteService.errorMessage, isNull);
      expect(deleteService.getContactsCount(), 1);
      expect(deleteService.emergencyContacts[0].contactId, 2);
      expect(deleteService.showConfirmationDialog, false);
      expect(deleteService.pendingDeleteId, isNull);
    });

    test('should show confirmation dialog before deleting', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await deleteService.loadEmergencyContacts('student1');

      deleteService.requestDeleteContact(1);

      expect(deleteService.showConfirmationDialog, true);
      expect(deleteService.pendingDeleteId, 1);
      expect(deleteService.getContactsCount(), 1); // Not deleted yet
    });

    test('should cancel delete request', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await deleteService.loadEmergencyContacts('student1');

      deleteService.requestDeleteContact(1);
      expect(deleteService.showConfirmationDialog, true);

      deleteService.cancelDeleteContact();

      expect(deleteService.showConfirmationDialog, false);
      expect(deleteService.pendingDeleteId, isNull);
      expect(deleteService.getContactsCount(), 1); // Contact still exists
    });

    test('should get delete confirmation message with contact name', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await deleteService.loadEmergencyContacts('student1');

      final message = deleteService.getDeleteConfirmationMessage(1);
      expect(message, contains('John Doe'));
      expect(message, equals('Are you sure you want to delete John Doe?'));
    });

    test('should get generic confirmation message for non-existent contact', () async {
      mockDatabase.seedEmergencyContacts('student1', []);

      await deleteService.loadEmergencyContacts('student1');

      final message = deleteService.getDeleteConfirmationMessage(999);
      expect(message, equals('Are you sure you want to delete this contact?'));
    });

    test('should handle non-existent contact deletion', () async {
      mockDatabase.seedEmergencyContacts('student1', []);

      await deleteService.loadEmergencyContacts('student1');

      deleteService.requestDeleteContact(999);
      final result = await deleteService.confirmDeleteContact('student1');

      expect(result, false);
      expect(deleteService.getContactsCount(), 0);
    });

    test('should not delete without confirmation', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await deleteService.loadEmergencyContacts('student1');

      final result = await deleteService.confirmDeleteContact('student1');

      expect(result, false);
      expect(deleteService.getContactsCount(), 1); // Not deleted
    });

    test('should delete first contact from multiple contacts', () async {
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
          'contact_name': 'Bob Smith',
          'relationship': 'Brother',
          'contact_number': '09111222333',
        },
      ]);

      await deleteService.loadEmergencyContacts('student1');

      deleteService.requestDeleteContact(1);
      await deleteService.confirmDeleteContact('student1');

      expect(deleteService.getContactsCount(), 2);
      expect(deleteService.emergencyContacts[0].contactId, 2);
      expect(deleteService.emergencyContacts[1].contactId, 3);
    });

    test('should delete middle contact from multiple contacts', () async {
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
          'contact_name': 'Bob Smith',
          'relationship': 'Brother',
          'contact_number': '09111222333',
        },
      ]);

      await deleteService.loadEmergencyContacts('student1');

      deleteService.requestDeleteContact(2);
      await deleteService.confirmDeleteContact('student1');

      expect(deleteService.getContactsCount(), 2);
      expect(deleteService.emergencyContacts[0].contactId, 1);
      expect(deleteService.emergencyContacts[1].contactId, 3);
    });

    test('should delete last contact from multiple contacts', () async {
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

      await deleteService.loadEmergencyContacts('student1');

      deleteService.requestDeleteContact(2);
      await deleteService.confirmDeleteContact('student1');

      expect(deleteService.getContactsCount(), 1);
      expect(deleteService.emergencyContacts[0].contactId, 1);
    });

    test('should delete multiple contacts sequentially', () async {
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
          'contact_name': 'Bob Smith',
          'relationship': 'Brother',
          'contact_number': '09111222333',
        },
      ]);

      await deleteService.loadEmergencyContacts('student1');

      deleteService.requestDeleteContact(1);
      await deleteService.confirmDeleteContact('student1');

      deleteService.requestDeleteContact(3);
      await deleteService.confirmDeleteContact('student1');

      expect(deleteService.getContactsCount(), 1);
      expect(deleteService.emergencyContacts[0].contactId, 2);
    });

    test('should delete all contacts one by one', () async {
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

      await deleteService.loadEmergencyContacts('student1');

      deleteService.requestDeleteContact(1);
      await deleteService.confirmDeleteContact('student1');

      deleteService.requestDeleteContact(2);
      await deleteService.confirmDeleteContact('student1');

      expect(deleteService.getContactsCount(), 0);
    });

    test('should handle database errors when deleting', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await deleteService.loadEmergencyContacts('student1');
      mockDatabase.setShouldThrowError(true);

      deleteService.requestDeleteContact(1);
      final result = await deleteService.confirmDeleteContact('student1');

      expect(result, false);
      expect(deleteService.errorMessage, contains('Error deleting emergency contact'));
      expect(deleteService.isProcessing, false);
      expect(deleteService.showConfirmationDialog, false);
      expect(deleteService.pendingDeleteId, isNull);
    });

    test('should reset confirmation dialog after failed deletion', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await deleteService.loadEmergencyContacts('student1');

      deleteService.requestDeleteContact(1);
      expect(deleteService.showConfirmationDialog, true);

      mockDatabase.setShouldThrowError(true);
      await deleteService.confirmDeleteContact('student1');

      expect(deleteService.showConfirmationDialog, false);
      expect(deleteService.pendingDeleteId, isNull);
    });

    test('should handle deleting same contact twice', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await deleteService.loadEmergencyContacts('student1');

      deleteService.requestDeleteContact(1);
      await deleteService.confirmDeleteContact('student1');

      deleteService.requestDeleteContact(1);
      final result = await deleteService.confirmDeleteContact('student1');

      expect(result, false);
    });

    test('should find contact by ID before deletion', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await deleteService.loadEmergencyContacts('student1');

      final contact = deleteService.findContactById(1);
      expect(contact, isNotNull);
      expect(contact!.contactName, 'John Doe');
    });

    test('should return null when finding non-existent contact', () async {
      mockDatabase.seedEmergencyContacts('student1', []);

      await deleteService.loadEmergencyContacts('student1');

      final contact = deleteService.findContactById(999);
      expect(contact, isNull);
    });

    test('should cancel delete and then successfully delete', () async {
      mockDatabase.seedEmergencyContacts('student1', [
        {
          'contact_id': 1,
          'user_id': 'student1',
          'contact_name': 'John Doe',
          'relationship': 'Father',
          'contact_number': '09123456789',
        },
      ]);

      await deleteService.loadEmergencyContacts('student1');

      // First cancel
      deleteService.requestDeleteContact(1);
      deleteService.cancelDeleteContact();
      expect(deleteService.getContactsCount(), 1);

      // Then delete
      deleteService.requestDeleteContact(1);
      final result = await deleteService.confirmDeleteContact('student1');
      expect(result, true);
      expect(deleteService.getContactsCount(), 0);
    });

    test('should request delete for different contacts sequentially', () async {
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

      await deleteService.loadEmergencyContacts('student1');

      deleteService.requestDeleteContact(1);
      expect(deleteService.pendingDeleteId, 1);

      deleteService.requestDeleteContact(2);
      expect(deleteService.pendingDeleteId, 2); // Updated to new ID
    });

    test('should clear error on successful deletion', () async {
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

      await deleteService.loadEmergencyContacts('student1');

      // First fail to set error
      deleteService.requestDeleteContact(999);
      await deleteService.confirmDeleteContact('student1');
      expect(deleteService.errorMessage, isNull); // No error for non-existent

      // Then succeed
      deleteService.requestDeleteContact(1);
      await deleteService.confirmDeleteContact('student1');
      expect(deleteService.errorMessage, isNull);
    });
  });
}
