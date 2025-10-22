// AM-AM-02: Both student and counselor can update appointments
// Requirement: Both users can reschedule, cancel, or modify appointment details
// Mirrors appointment management functionality for status updates and rescheduling

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent an appointment update
class MockAppointmentUpdate {
  final String appointmentId;
  final DateTime? newDate;
  final String? newTimeSlot;
  final String? newStatus;
  final String? newNotes;
  final String? reason;
  final DateTime updatedAt;
  final String updatedBy;

  MockAppointmentUpdate({
    required this.appointmentId,
    this.newDate,
    this.newTimeSlot,
    this.newStatus,
    this.newNotes,
    this.reason,
    required this.updatedAt,
    required this.updatedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'appointment_id': appointmentId,
      'new_date': newDate?.toIso8601String(),
      'new_time_slot': newTimeSlot,
      'new_status': newStatus,
      'new_notes': newNotes,
      'reason': reason,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
    };
  }
}

// Mock class to represent an appointment for updating
class MockUpdatableAppointment {
  final String id;
  final String studentId;
  final String counselorId;
  DateTime appointmentDate;
  String timeSlot;
  String status;
  String? notes;
  final DateTime? createdAt;
  DateTime? updatedAt;
  final String? studentName;
  final String? counselorName;

  MockUpdatableAppointment({
    required this.id,
    required this.studentId,
    required this.counselorId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.studentName,
    this.counselorName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'counselor_id': counselorId,
      'appointment_date': appointmentDate.toIso8601String(),
      'time_slot': timeSlot,
      'status': status,
      'notes': notes,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'student_name': studentName,
      'counselor_name': counselorName,
    };
  }

  factory MockUpdatableAppointment.fromMap(Map<String, dynamic> map) {
    return MockUpdatableAppointment(
      id: map['id'],
      studentId: map['student_id'],
      counselorId: map['counselor_id'],
      appointmentDate: DateTime.parse(map['appointment_date']),
      timeSlot: map['time_slot'],
      status: map['status'],
      notes: map['notes'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      studentName: map['student_name'],
      counselorName: map['counselor_name'],
    );
  }

  bool canBeCancelled() {
    return status.toLowerCase() == 'scheduled' || status.toLowerCase() == 'rescheduled';
  }

  bool canBeRescheduled() {
    return status.toLowerCase() == 'scheduled' || status.toLowerCase() == 'rescheduled';
  }

  bool canBeCompleted() {
    return status.toLowerCase() == 'scheduled' && appointmentDate.isBefore(DateTime.now().add(Duration(hours: 1)));
  }

  bool canBeUpdated() {
    return status.toLowerCase() != 'cancelled' && status.toLowerCase() != 'completed';
  }
}

// Mock database for appointment updates
class MockAppointmentUpdateDatabase {
  Map<String, Map<String, dynamic>> _appointments = {};
  List<Map<String, dynamic>> _updateHistory = [];
  bool _shouldThrowError = false;

  void seedAppointments(Map<String, Map<String, dynamic>> appointments) {
    _appointments = appointments;
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  Future<Map<String, dynamic>?> getAppointment(String appointmentId) async {
    await Future.delayed(Duration(milliseconds: 50));
    
    if (_shouldThrowError) {
      throw Exception('Error loading appointment');
    }
    
    return _appointments[appointmentId];
  }

  Future<bool> updateAppointmentStatus(String appointmentId, String newStatus, String updatedBy, {String? reason}) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Error updating appointment status');
    }
    
    if (!_appointments.containsKey(appointmentId)) {
      return false;
    }
    
    final appointment = _appointments[appointmentId]!;
    appointment['status'] = newStatus;
    appointment['updated_at'] = DateTime.now().toIso8601String();
    
    // Record update history
    _updateHistory.add({
      'appointment_id': appointmentId,
      'new_status': newStatus,
      'reason': reason,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': updatedBy,
    });
    
    return true;
  }

  Future<bool> rescheduleAppointment(String appointmentId, DateTime newDate, String newTimeSlot, String updatedBy, {String? reason}) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Error rescheduling appointment');
    }
    
    if (!_appointments.containsKey(appointmentId)) {
      return false;
    }
    
    final appointment = _appointments[appointmentId]!;
    appointment['appointment_date'] = newDate.toIso8601String();
    appointment['time_slot'] = newTimeSlot;
    appointment['status'] = 'rescheduled';
    appointment['updated_at'] = DateTime.now().toIso8601String();
    
    // Record update history
    _updateHistory.add({
      'appointment_id': appointmentId,
      'new_date': newDate.toIso8601String(),
      'new_time_slot': newTimeSlot,
      'new_status': 'rescheduled',
      'reason': reason,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': updatedBy,
    });
    
    return true;
  }

  Future<bool> updateAppointmentNotes(String appointmentId, String newNotes, String updatedBy) async {
    await Future.delayed(Duration(milliseconds: 50));
    
    if (_shouldThrowError) {
      throw Exception('Error updating appointment notes');
    }
    
    if (!_appointments.containsKey(appointmentId)) {
      return false;
    }
    
    final appointment = _appointments[appointmentId]!;
    appointment['notes'] = newNotes;
    appointment['updated_at'] = DateTime.now().toIso8601String();
    
    // Record update history
    _updateHistory.add({
      'appointment_id': appointmentId,
      'new_notes': newNotes,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': updatedBy,
    });
    
    return true;
  }

  Future<List<String>> getAvailableTimeSlots(String counselorId, DateTime date) async {
    await Future.delayed(Duration(milliseconds: 50));
    
    if (_shouldThrowError) {
      throw Exception('Error loading available time slots');
    }
    
    // Mock available time slots - in reality this would check counselor's schedule
    return ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'];
  }

  List<Map<String, dynamic>> getUpdateHistory(String appointmentId) {
    return _updateHistory.where((update) => update['appointment_id'] == appointmentId).toList();
  }
}

// Service class for appointment updates
class AppointmentUpdateService {
  final MockAppointmentUpdateDatabase _database;
  MockUpdatableAppointment? _currentAppointment;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  String? _currentUserType; // 'student' or 'counselor'

  AppointmentUpdateService(this._database);

  MockUpdatableAppointment? get currentAppointment => _currentAppointment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;
  String? get currentUserType => _currentUserType;

  Future<void> loadAppointment(String appointmentId, String userId, String userType) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _currentUserId = userId;
      _currentUserType = userType;

      final appointmentData = await _database.getAppointment(appointmentId);
      if (appointmentData != null) {
        _currentAppointment = MockUpdatableAppointment.fromMap(appointmentData);
      } else {
        _currentAppointment = null;
        _errorMessage = 'Appointment not found';
      }

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _currentAppointment = null;
    }
  }

  Future<bool> cancelAppointment({String? reason}) async {
    if (_currentAppointment == null || !_currentAppointment!.canBeCancelled()) {
      _errorMessage = 'Cannot cancel appointment';
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;

      final success = await _database.updateAppointmentStatus(
        _currentAppointment!.id,
        'cancelled',
        _currentUserId!,
        reason: reason,
      );

      if (success) {
        _currentAppointment!.status = 'cancelled';
        _currentAppointment!.updatedAt = DateTime.now();
      }

      _isLoading = false;
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> rescheduleAppointment(DateTime newDate, String newTimeSlot, {String? reason}) async {
    if (_currentAppointment == null || !_currentAppointment!.canBeRescheduled()) {
      _errorMessage = 'Cannot reschedule appointment';
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;

      final success = await _database.rescheduleAppointment(
        _currentAppointment!.id,
        newDate,
        newTimeSlot,
        _currentUserId!,
        reason: reason,
      );

      if (success) {
        _currentAppointment!.appointmentDate = newDate;
        _currentAppointment!.timeSlot = newTimeSlot;
        _currentAppointment!.status = 'rescheduled';
        _currentAppointment!.updatedAt = DateTime.now();
      }

      _isLoading = false;
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> completeAppointment({String? notes}) async {
    if (_currentAppointment == null || !_currentAppointment!.canBeCompleted()) {
      _errorMessage = 'Cannot complete appointment';
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;

      final success = await _database.updateAppointmentStatus(
        _currentAppointment!.id,
        'completed',
        _currentUserId!,
        reason: 'Session completed',
      );

      if (success && notes != null) {
        await _database.updateAppointmentNotes(_currentAppointment!.id, notes, _currentUserId!);
        _currentAppointment!.notes = notes;
      }

      if (success) {
        _currentAppointment!.status = 'completed';
        _currentAppointment!.updatedAt = DateTime.now();
      }

      _isLoading = false;
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateNotes(String newNotes) async {
    if (_currentAppointment == null || !_currentAppointment!.canBeUpdated()) {
      _errorMessage = 'Cannot update appointment notes';
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;

      final success = await _database.updateAppointmentNotes(
        _currentAppointment!.id,
        newNotes,
        _currentUserId!,
      );

      if (success) {
        _currentAppointment!.notes = newNotes;
        _currentAppointment!.updatedAt = DateTime.now();
      }

      _isLoading = false;
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<List<String>> getAvailableTimeSlots(DateTime date) async {
    if (_currentAppointment == null) {
      return [];
    }

    try {
      return await _database.getAvailableTimeSlots(_currentAppointment!.counselorId, date);
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  bool hasPermissionToUpdate() {
    if (_currentAppointment == null) return false;

    if (_currentUserType == 'student') {
      return _currentAppointment!.studentId == _currentUserId;
    } else if (_currentUserType == 'counselor') {
      return _currentAppointment!.counselorId == _currentUserId;
    }

    return false;
  }

  bool canUserCancelAppointment() {
    return hasPermissionToUpdate() && _currentAppointment?.canBeCancelled() == true;
  }

  bool canUserRescheduleAppointment() {
    return hasPermissionToUpdate() && _currentAppointment?.canBeRescheduled() == true;
  }

  bool canUserCompleteAppointment() {
    // Only counselors can mark appointments as completed
    return _currentUserType == 'counselor' && 
           hasPermissionToUpdate() && 
           _currentAppointment?.canBeCompleted() == true;
  }

  bool canUserUpdateNotes() {
    return hasPermissionToUpdate() && _currentAppointment?.canBeUpdated() == true;
  }

  String formatAppointmentDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String formatTimeSlot(String timeSlot) {
    try {
      final parts = timeSlot.split(':');
      if (parts.length == 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        
        String period = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        
        return '${hour}:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      // Return original format if parsing fails
    }
    
    return timeSlot;
  }

  bool isDateSelectable(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    
    // Can't reschedule to past dates
    return !checkDate.isBefore(today);
  }

  String validateRescheduleRequest(DateTime newDate, String newTimeSlot) {
    if (_currentAppointment == null) {
      return 'No appointment selected';
    }

    if (!canUserRescheduleAppointment()) {
      return 'You do not have permission to reschedule this appointment';
    }

    if (!isDateSelectable(newDate)) {
      return 'Selected date is in the past';
    }

    if (newTimeSlot.isEmpty) {
      return 'Please select a time slot';
    }

    return ''; // Valid request
  }

  String validateCancelRequest() {
    if (_currentAppointment == null) {
      return 'No appointment selected';
    }

    if (!canUserCancelAppointment()) {
      return 'You do not have permission to cancel this appointment';
    }

    return ''; // Valid request
  }

  Map<String, dynamic> getAppointmentUpdateStatistics() {
    if (_currentAppointment == null) {
      return {
        'has_appointment': false,
        'can_update': false,
        'can_cancel': false,
        'can_reschedule': false,
        'can_complete': false,
        'can_update_notes': false,
      };
    }

    return {
      'has_appointment': true,
      'appointment_id': _currentAppointment!.id,
      'current_status': _currentAppointment!.status,
      'appointment_date': formatAppointmentDate(_currentAppointment!.appointmentDate),
      'appointment_time': formatTimeSlot(_currentAppointment!.timeSlot),
      'can_update': hasPermissionToUpdate(),
      'can_cancel': canUserCancelAppointment(),
      'can_reschedule': canUserRescheduleAppointment(),
      'can_complete': canUserCompleteAppointment(),
      'can_update_notes': canUserUpdateNotes(),
      'user_type': _currentUserType,
      'user_id': _currentUserId,
      'is_loaded': !_isLoading && _errorMessage == null,
      'has_notes': _currentAppointment!.notes?.isNotEmpty == true,
      'last_updated': _currentAppointment!.updatedAt?.toIso8601String(),
    };
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _currentAppointment = null;
    _currentUserId = null;
    _currentUserType = null;
    _isLoading = false;
    _errorMessage = null;
  }

  String getDisplayName() {
    if (_currentAppointment == null) return '';
    
    if (_currentUserType == 'student') {
      return _currentAppointment!.counselorName ?? 'Unknown Counselor';
    } else {
      return _currentAppointment!.studentName ?? 'Unknown Student';
    }
  }

  String getAppointmentTitle() {
    if (_currentAppointment == null) return 'No Appointment';
    
    final displayName = getDisplayName();
    final date = formatAppointmentDate(_currentAppointment!.appointmentDate);
    final time = formatTimeSlot(_currentAppointment!.timeSlot);
    
    return 'Appointment with $displayName on $date at $time';
  }

  List<String> getValidStatuses() {
    if (_currentUserType == 'counselor') {
      return ['scheduled', 'rescheduled', 'completed', 'cancelled'];
    } else {
      return ['scheduled', 'rescheduled', 'cancelled'];
    }
  }

  Future<void> refreshAppointment() async {
    if (_currentAppointment != null && _currentUserId != null && _currentUserType != null) {
      await loadAppointment(_currentAppointment!.id, _currentUserId!, _currentUserType!);
    }
  }
}

void main() {
  group('AM-AM-02: Both student and counselor can update appointments', () {
    late MockAppointmentUpdateDatabase mockDatabase;
    late AppointmentUpdateService updateService;

    setUp(() {
      mockDatabase = MockAppointmentUpdateDatabase();
      updateService = AppointmentUpdateService(mockDatabase);
    });

    test('Should load appointment for student successfully', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': 'Initial consultation',
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'student1', 'student');

      expect(updateService.isLoading, false);
      expect(updateService.errorMessage, isNull);
      expect(updateService.currentAppointment, isNotNull);
      expect(updateService.currentUserId, 'student1');
      expect(updateService.currentUserType, 'student');
      expect(updateService.hasPermissionToUpdate(), true);
    });

    test('Should load appointment for counselor successfully', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': 'Session notes',
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'counselor1', 'counselor');

      expect(updateService.isLoading, false);
      expect(updateService.errorMessage, isNull);
      expect(updateService.currentAppointment, isNotNull);
      expect(updateService.currentUserId, 'counselor1');
      expect(updateService.currentUserType, 'counselor');
      expect(updateService.hasPermissionToUpdate(), true);
    });

    test('Should handle appointment not found', () async {
      mockDatabase.seedAppointments({});

      await updateService.loadAppointment('nonexistent', 'student1', 'student');

      expect(updateService.isLoading, false);
      expect(updateService.errorMessage, contains('not found'));
      expect(updateService.currentAppointment, isNull);
    });

    test('Should cancel appointment successfully', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'student1', 'student');

      final success = await updateService.cancelAppointment(reason: 'Emergency cancellation');

      expect(success, true);
      expect(updateService.currentAppointment!.status, 'cancelled');
      expect(updateService.errorMessage, isNull);
    });

    test('Should reschedule appointment successfully', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final nextWeek = DateTime.now().add(Duration(days: 7));
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'student1', 'student');

      final success = await updateService.rescheduleAppointment(
          nextWeek, '14:00', reason: 'Schedule conflict');

      expect(success, true);
      expect(updateService.currentAppointment!.appointmentDate, nextWeek);
      expect(updateService.currentAppointment!.timeSlot, '14:00');
      expect(updateService.currentAppointment!.status, 'rescheduled');
      expect(updateService.errorMessage, isNull);
    });

    test('Should complete appointment successfully (counselor only)', () async {
      final yesterday = DateTime.now().subtract(Duration(hours: 2));
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': yesterday.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'counselor1', 'counselor');

      final success = await updateService.completeAppointment(notes: 'Session completed successfully');

      expect(success, true);
      expect(updateService.currentAppointment!.status, 'completed');
      expect(updateService.currentAppointment!.notes, 'Session completed successfully');
      expect(updateService.errorMessage, isNull);
    });

    test('Should update appointment notes successfully', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': 'Original notes',
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'counselor1', 'counselor');

      final success = await updateService.updateNotes('Updated appointment notes');

      expect(success, true);
      expect(updateService.currentAppointment!.notes, 'Updated appointment notes');
      expect(updateService.errorMessage, isNull);
    });

    test('Should validate permissions correctly', () async {
      final yesterday = DateTime.now().subtract(Duration(hours: 2)); // Past appointment for completion test
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': yesterday.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      // Test student permissions
      await updateService.loadAppointment('appointment1', 'student1', 'student');
      expect(updateService.canUserCancelAppointment(), true);
      expect(updateService.canUserRescheduleAppointment(), true);
      expect(updateService.canUserCompleteAppointment(), false); // Only counselors can complete
      expect(updateService.canUserUpdateNotes(), true);

      // Test counselor permissions
      await updateService.loadAppointment('appointment1', 'counselor1', 'counselor');
      expect(updateService.canUserCancelAppointment(), true);
      expect(updateService.canUserRescheduleAppointment(), true);
      expect(updateService.canUserCompleteAppointment(), true);
      expect(updateService.canUserUpdateNotes(), true);

      // Test unauthorized user
      await updateService.loadAppointment('appointment1', 'other_user', 'student');
      expect(updateService.canUserCancelAppointment(), false);
      expect(updateService.canUserRescheduleAppointment(), false);
      expect(updateService.canUserCompleteAppointment(), false);
      expect(updateService.canUserUpdateNotes(), false);
    });

    test('Should validate reschedule requests', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final pastDate = DateTime.now().subtract(Duration(days: 1));
      final futureDate = DateTime.now().add(Duration(days: 7));
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'student1', 'student');

      // Valid reschedule request
      expect(updateService.validateRescheduleRequest(futureDate, '14:00'), isEmpty);

      // Invalid reschedule request - past date
      expect(updateService.validateRescheduleRequest(pastDate, '14:00'), contains('past'));

      // Invalid reschedule request - empty time slot
      expect(updateService.validateRescheduleRequest(futureDate, ''), contains('time slot'));
    });

    test('Should handle appointment status constraints', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      // Test cancelled appointment - cannot be updated
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'cancelled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'student1', 'student');

      expect(updateService.currentAppointment!.canBeCancelled(), false);
      expect(updateService.currentAppointment!.canBeRescheduled(), false);
      expect(updateService.currentAppointment!.canBeUpdated(), false);

      final cancelSuccess = await updateService.cancelAppointment();
      expect(cancelSuccess, false);
      expect(updateService.errorMessage, contains('Cannot cancel'));
    });

    test('Should get available time slots', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'student1', 'student');

      final availableSlots = await updateService.getAvailableTimeSlots(tomorrow);

      expect(availableSlots.isNotEmpty, true);
      expect(availableSlots, contains('09:00'));
      expect(availableSlots, contains('14:00'));
    });

    test('Should format dates and times correctly', () async {
      final testDate = DateTime(2024, 3, 15, 14, 30);
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': testDate.toIso8601String(),
          'time_slot': '14:30',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'student1', 'student');

      expect(updateService.formatAppointmentDate(testDate), 'March 15, 2024');
      expect(updateService.formatTimeSlot('14:30'), '2:30 PM');
      expect(updateService.getDisplayName(), 'Dr. Smith'); // Student sees counselor name
      expect(updateService.getAppointmentTitle(), contains('Dr. Smith'));
      expect(updateService.getAppointmentTitle(), contains('March 15, 2024'));
      expect(updateService.getAppointmentTitle(), contains('2:30 PM'));
    });

    test('Should generate update statistics', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': 'Test notes',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'student1', 'student');

      final stats = updateService.getAppointmentUpdateStatistics();

      expect(stats['has_appointment'], true);
      expect(stats['appointment_id'], 'appointment1');
      expect(stats['current_status'], 'scheduled');
      expect(stats['can_update'], true);
      expect(stats['can_cancel'], true);
      expect(stats['can_reschedule'], true);
      expect(stats['can_complete'], false); // Student cannot complete
      expect(stats['can_update_notes'], true);
      expect(stats['user_type'], 'student');
      expect(stats['user_id'], 'student1');
      expect(stats['is_loaded'], true);
      expect(stats['has_notes'], true);
    });

    test('Should handle database errors', () async {
      mockDatabase.setShouldThrowError(true);

      await updateService.loadAppointment('appointment1', 'student1', 'student');

      expect(updateService.isLoading, false);
      expect(updateService.errorMessage, contains('Error loading appointment'));
      expect(updateService.currentAppointment, isNull);
    });

    test('Should reset service state', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'student1', 'student');
      expect(updateService.currentAppointment, isNotNull);
      expect(updateService.currentUserId, 'student1');

      updateService.reset();

      expect(updateService.currentAppointment, isNull);
      expect(updateService.currentUserId, isNull);
      expect(updateService.currentUserType, isNull);
      expect(updateService.isLoading, false);
      expect(updateService.errorMessage, isNull);
    });

    test('Should validate date selectability', () {
      final past = DateTime.now().subtract(Duration(days: 1));
      final today = DateTime.now();
      final future = DateTime.now().add(Duration(days: 1));

      expect(updateService.isDateSelectable(past), false);
      expect(updateService.isDateSelectable(today), true);
      expect(updateService.isDateSelectable(future), true);
    });

    test('Should provide valid statuses based on user type', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      // Test student valid statuses
      await updateService.loadAppointment('appointment1', 'student1', 'student');
      final studentStatuses = updateService.getValidStatuses();
      expect(studentStatuses, contains('scheduled'));
      expect(studentStatuses, contains('cancelled'));
      expect(studentStatuses, isNot(contains('completed'))); // Students cannot complete

      // Test counselor valid statuses
      await updateService.loadAppointment('appointment1', 'counselor1', 'counselor');
      final counselorStatuses = updateService.getValidStatuses();
      expect(counselorStatuses, contains('scheduled'));
      expect(counselorStatuses, contains('completed'));
      expect(counselorStatuses, contains('cancelled'));
    });

    test('Should refresh appointment data', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': 'Original notes',
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.loadAppointment('appointment1', 'student1', 'student');
      expect(updateService.currentAppointment!.notes, 'Original notes');

      // Update the database
      mockDatabase.seedAppointments({
        'appointment1': {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': 'Updated notes',
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      });

      await updateService.refreshAppointment();
      expect(updateService.currentAppointment!.notes, 'Updated notes');
    });
  });
}