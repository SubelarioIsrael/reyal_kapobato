// AM-AB-01: Students can select date and time for appointment
// Requirement: Students can choose appointment dates and times based on counselor availability
// Mirrors appointment booking workflow with date/time selection and validation

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent appointment booking data
class MockAppointmentBooking {
  final String id;
  final String studentId;
  final String counselorId;
  final DateTime appointmentDate;
  final String timeSlot;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  MockAppointmentBooking({
    required this.id,
    required this.studentId,
    required this.counselorId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    this.notes,
    this.createdAt,
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
    };
  }

  factory MockAppointmentBooking.fromMap(Map<String, dynamic> map) {
    return MockAppointmentBooking(
      id: map['id'],
      studentId: map['student_id'],
      counselorId: map['counselor_id'],
      appointmentDate: DateTime.parse(map['appointment_date']),
      timeSlot: map['time_slot'],
      status: map['status'],
      notes: map['notes'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}

// Mock class for counselor availability
class MockCounselorAvailability {
  final String counselorId;
  final DateTime date;
  final List<String> availableTimeSlots;
  final List<String> bookedTimeSlots;

  MockCounselorAvailability({
    required this.counselorId,
    required this.date,
    required this.availableTimeSlots,
    required this.bookedTimeSlots,
  });

  List<String> getAvailableSlots() {
    return availableTimeSlots.where((slot) => !bookedTimeSlots.contains(slot)).toList();
  }

  bool isSlotAvailable(String timeSlot) {
    return availableTimeSlots.contains(timeSlot) && !bookedTimeSlots.contains(timeSlot);
  }
}

// Mock database for appointment booking
class MockAppointmentBookingDatabase {
  List<Map<String, dynamic>> _appointments = [];
  Map<String, MockCounselorAvailability> _availability = {};
  bool _shouldThrowError = false;

  void seedAppointments(List<Map<String, dynamic>> appointments) {
    _appointments = appointments;
  }

  void seedAvailability(Map<String, MockCounselorAvailability> availability) {
    _availability = availability;
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    await Future.delayed(Duration(milliseconds: 50));
    
    if (_shouldThrowError) {
      throw Exception('Error loading appointments');
    }
    
    return List.from(_appointments);
  }

  Future<MockCounselorAvailability?> getCounselorAvailability(String counselorId, DateTime date) async {
    await Future.delayed(Duration(milliseconds: 50));
    
    if (_shouldThrowError) {
      throw Exception('Error loading availability');
    }
    
    final key = '${counselorId}_${date.toIso8601String().split('T')[0]}';
    return _availability[key];
  }

  Future<String> bookAppointment(Map<String, dynamic> appointmentData) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Error booking appointment');
    }
    
    final appointmentId = 'appointment_${DateTime.now().millisecondsSinceEpoch}';
    appointmentData['id'] = appointmentId;
    appointmentData['created_at'] = DateTime.now().toIso8601String();
    
    _appointments.add(appointmentData);
    
    // Update availability by adding the booked slot
    final counselorId = appointmentData['counselor_id'];
    final appointmentDate = DateTime.parse(appointmentData['appointment_date']);
    final timeSlot = appointmentData['time_slot'];
    
    final key = '${counselorId}_${appointmentDate.toIso8601String().split('T')[0]}';
    if (_availability.containsKey(key)) {
      _availability[key]!.bookedTimeSlots.add(timeSlot);
    }
    
    return appointmentId;
  }

  Future<List<String>> getBookedTimeSlots(String counselorId, DateTime date) async {
    await Future.delayed(Duration(milliseconds: 30));
    
    final key = '${counselorId}_${date.toIso8601String().split('T')[0]}';
    return _availability[key]?.bookedTimeSlots ?? [];
  }
}

// Service class for appointment booking
class StudentAppointmentBookingService {
  final MockAppointmentBookingDatabase _database;
  List<MockAppointmentBooking> _appointments = [];
  MockCounselorAvailability? _currentAvailability;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedCounselorId;

  StudentAppointmentBookingService(this._database);

  List<MockAppointmentBooking> get appointments => _appointments;
  MockCounselorAvailability? get currentAvailability => _currentAvailability;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get selectedDate => _selectedDate;
  String? get selectedTimeSlot => _selectedTimeSlot;
  String? get selectedCounselorId => _selectedCounselorId;

  Future<void> loadAppointments() async {
    try {
      _isLoading = true;
      _errorMessage = null;

      final appointmentsData = await _database.getAppointments();
      _appointments = appointmentsData.map((data) => MockAppointmentBooking.fromMap(data)).toList();

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _appointments = [];
    }
  }

  Future<void> loadCounselorAvailability(String counselorId, DateTime date) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _selectedCounselorId = counselorId;

      final availability = await _database.getCounselorAvailability(counselorId, date);
      _currentAvailability = availability;

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _currentAvailability = null;
    }
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    _selectedTimeSlot = null; // Clear time slot when date changes
  }

  void selectTimeSlot(String timeSlot) {
    if (_currentAvailability?.isSlotAvailable(timeSlot) == true) {
      _selectedTimeSlot = timeSlot;
    }
  }

  void clearSelection() {
    _selectedDate = null;
    _selectedTimeSlot = null;
    _selectedCounselorId = null;
    _currentAvailability = null;
  }

  bool canBookAppointment() {
    return _selectedDate != null && 
           _selectedTimeSlot != null && 
           _selectedCounselorId != null &&
           (_currentAvailability?.isSlotAvailable(_selectedTimeSlot!) == true);
  }

  Future<String?> bookAppointment(String studentId, {String? notes}) async {
    if (!canBookAppointment()) {
      throw Exception('Invalid booking selection');
    }

    try {
      _isLoading = true;
      _errorMessage = null;

      final appointmentData = {
        'student_id': studentId,
        'counselor_id': _selectedCounselorId!,
        'appointment_date': _selectedDate!.toIso8601String(),
        'time_slot': _selectedTimeSlot!,
        'status': 'scheduled',
        'notes': notes,
      };

      final appointmentId = await _database.bookAppointment(appointmentData);
      
      // Refresh appointments and availability
      await loadAppointments();
      if (_selectedCounselorId != null && _selectedDate != null) {
        await loadCounselorAvailability(_selectedCounselorId!, _selectedDate!);
      }

      _isLoading = false;
      return appointmentId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      return null;
    }
  }

  List<String> getAvailableTimeSlots() {
    return _currentAvailability?.getAvailableSlots() ?? [];
  }

  List<String> getBookedTimeSlots() {
    return _currentAvailability?.bookedTimeSlots ?? [];
  }

  bool isDateSelectable(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    
    // Can't book appointments in the past
    return !checkDate.isBefore(today);
  }

  String formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String formatTimeSlot(String timeSlot) {
    // Convert 24-hour format to 12-hour format
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

  String getBookingValidationMessage() {
    if (_selectedDate == null) {
      return 'Please select a date';
    }
    
    if (!isDateSelectable(_selectedDate!)) {
      return 'Selected date is not available for booking';
    }
    
    if (_selectedTimeSlot == null) {
      return 'Please select a time slot';
    }
    
    if (_currentAvailability?.isSlotAvailable(_selectedTimeSlot!) != true) {
      return 'Selected time slot is not available';
    }
    
    if (_selectedCounselorId == null) {
      return 'No counselor selected';
    }
    
    return '';
  }

  Map<String, dynamic> getBookingStatistics() {
    final now = DateTime.now();
    final upcomingAppointments = _appointments.where((a) => 
        a.appointmentDate.isAfter(now) && a.status != 'cancelled').toList();
    
    final availableSlots = getAvailableTimeSlots();
    final bookedSlots = getBookedTimeSlots();
    
    return {
      'total_appointments': _appointments.length,
      'upcoming_appointments': upcomingAppointments.length,
      'available_time_slots': availableSlots.length,
      'booked_time_slots': bookedSlots.length,
      'has_date_selection': _selectedDate != null,
      'has_time_selection': _selectedTimeSlot != null,
      'can_book': canBookAppointment(),
      'validation_message': getBookingValidationMessage(),
      'selected_date_formatted': _selectedDate != null ? formatDate(_selectedDate!) : null,
      'selected_time_formatted': _selectedTimeSlot != null ? formatTimeSlot(_selectedTimeSlot!) : null,
    };
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _appointments.clear();
    _currentAvailability = null;
    _selectedDate = null;
    _selectedTimeSlot = null;
    _selectedCounselorId = null;
    _isLoading = false;
    _errorMessage = null;
  }

  bool hasConflictingAppointment(String studentId, DateTime date, String timeSlot) {
    return _appointments.any((appointment) =>
        appointment.studentId == studentId &&
        appointment.appointmentDate.year == date.year &&
        appointment.appointmentDate.month == date.month &&
        appointment.appointmentDate.day == date.day &&
        appointment.timeSlot == timeSlot &&
        appointment.status != 'cancelled');
  }

  List<DateTime> getUnavailableDates(String counselorId) {
    // Return dates that are completely booked or unavailable
    final unavailableDates = <DateTime>[];
    
    // This would typically check counselor's schedule
    // For testing, return some sample unavailable dates
    final now = DateTime.now();
    unavailableDates.add(DateTime(now.year, now.month, now.day + 1));
    
    return unavailableDates;
  }

  String? validateTimeSlotSelection(String timeSlot) {
    if (_currentAvailability == null) {
      return 'No availability data loaded';
    }
    
    if (!_currentAvailability!.availableTimeSlots.contains(timeSlot)) {
      return 'Time slot is not in available slots';
    }
    
    if (_currentAvailability!.bookedTimeSlots.contains(timeSlot)) {
      return 'Time slot is already booked';
    }
    
    return null; // Valid selection
  }

  Future<bool> refreshAvailability() async {
    if (_selectedCounselorId != null && _selectedDate != null) {
      await loadCounselorAvailability(_selectedCounselorId!, _selectedDate!);
      return _errorMessage == null;
    }
    return false;
  }
}

void main() {
  group('AM-AB-01: Students can select date and time for appointment', () {
    late MockAppointmentBookingDatabase mockDatabase;
    late StudentAppointmentBookingService bookingService;

    setUp(() {
      mockDatabase = MockAppointmentBookingDatabase();
      bookingService = StudentAppointmentBookingService(mockDatabase);
    });

    test('Should load appointments successfully', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments([
        {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': 'Test appointment',
          'created_at': DateTime.now().toIso8601String(),
        },
      ]);

      await bookingService.loadAppointments();

      expect(bookingService.isLoading, false);
      expect(bookingService.errorMessage, isNull);
      expect(bookingService.appointments.length, 1);
    });

    test('Should handle loading errors', () async {
      mockDatabase.setShouldThrowError(true);

      await bookingService.loadAppointments();

      expect(bookingService.isLoading, false);
      expect(bookingService.errorMessage, contains('Error loading appointments'));
      expect(bookingService.appointments.length, 0);
    });

    test('Should load counselor availability', () async {
      final testDate = DateTime.now().add(Duration(days: 1));
      final availability = MockCounselorAvailability(
        counselorId: 'counselor1',
        date: testDate,
        availableTimeSlots: ['09:00', '10:00', '11:00', '14:00', '15:00'],
        bookedTimeSlots: ['10:00'],
      );

      mockDatabase.seedAvailability({
        'counselor1_${testDate.toIso8601String().split('T')[0]}': availability,
      });

      await bookingService.loadCounselorAvailability('counselor1', testDate);

      expect(bookingService.isLoading, false);
      expect(bookingService.errorMessage, isNull);
      expect(bookingService.currentAvailability, isNotNull);
      expect(bookingService.selectedCounselorId, 'counselor1');
    });

    test('Should handle date and time slot selection', () async {
      final testDate = DateTime.now().add(Duration(days: 1));
      final availability = MockCounselorAvailability(
        counselorId: 'counselor1',
        date: testDate,
        availableTimeSlots: ['09:00', '10:00', '11:00'],
        bookedTimeSlots: ['10:00'],
      );

      mockDatabase.seedAvailability({
        'counselor1_${testDate.toIso8601String().split('T')[0]}': availability,
      });

      await bookingService.loadCounselorAvailability('counselor1', testDate);

      // Test date selection
      bookingService.selectDate(testDate);
      expect(bookingService.selectedDate, testDate);
      expect(bookingService.selectedTimeSlot, isNull); // Should clear time slot

      // Test valid time slot selection
      bookingService.selectTimeSlot('09:00'); // Available slot
      expect(bookingService.selectedTimeSlot, '09:00');

      // Test invalid time slot selection
      bookingService.selectTimeSlot('10:00'); // Booked slot
      expect(bookingService.selectedTimeSlot, '09:00'); // Should not change
    });

    test('Should validate booking requirements', () async {
      final testDate = DateTime.now().add(Duration(days: 1));
      final availability = MockCounselorAvailability(
        counselorId: 'counselor1',
        date: testDate,
        availableTimeSlots: ['09:00', '10:00'],
        bookedTimeSlots: [],
      );

      mockDatabase.seedAvailability({
        'counselor1_${testDate.toIso8601String().split('T')[0]}': availability,
      });

      await bookingService.loadCounselorAvailability('counselor1', testDate);

      // Initially cannot book
      expect(bookingService.canBookAppointment(), false);

      // Select date
      bookingService.selectDate(testDate);
      expect(bookingService.canBookAppointment(), false);

      // Select time slot
      bookingService.selectTimeSlot('09:00');
      expect(bookingService.canBookAppointment(), true);
    });

    test('Should book appointment successfully', () async {
      final testDate = DateTime.now().add(Duration(days: 1));
      final availability = MockCounselorAvailability(
        counselorId: 'counselor1',
        date: testDate,
        availableTimeSlots: ['09:00', '10:00'],
        bookedTimeSlots: [],
      );

      mockDatabase.seedAvailability({
        'counselor1_${testDate.toIso8601String().split('T')[0]}': availability,
      });

      await bookingService.loadCounselorAvailability('counselor1', testDate);
      bookingService.selectDate(testDate);
      bookingService.selectTimeSlot('09:00');

      final appointmentId = await bookingService.bookAppointment('student1', notes: 'Test booking');

      expect(appointmentId, isNotNull);
      expect(appointmentId, startsWith('appointment_'));
      expect(bookingService.errorMessage, isNull);
    });

    test('Should handle booking errors', () async {
      final testDate = DateTime.now().add(Duration(days: 1));
      final availability = MockCounselorAvailability(
        counselorId: 'counselor1',
        date: testDate,
        availableTimeSlots: ['09:00'],
        bookedTimeSlots: [],
      );

      mockDatabase.seedAvailability({
        'counselor1_${testDate.toIso8601String().split('T')[0]}': availability,
      });

      await bookingService.loadCounselorAvailability('counselor1', testDate);
      bookingService.selectDate(testDate);
      bookingService.selectTimeSlot('09:00');

      mockDatabase.setShouldThrowError(true);

      final appointmentId = await bookingService.bookAppointment('student1');

      expect(appointmentId, isNull);
      expect(bookingService.errorMessage, contains('Error booking appointment'));
    });

    test('Should validate date selectability', () {
      final past = DateTime.now().subtract(Duration(days: 1));
      final today = DateTime.now();
      final future = DateTime.now().add(Duration(days: 1));

      expect(bookingService.isDateSelectable(past), false);
      expect(bookingService.isDateSelectable(today), true);
      expect(bookingService.isDateSelectable(future), true);
    });

    test('Should format dates correctly', () {
      final testDate = DateTime(2024, 3, 15);
      final formatted = bookingService.formatDate(testDate);
      expect(formatted, 'March 15, 2024');
    });

    test('Should format time slots correctly', () {
      expect(bookingService.formatTimeSlot('09:00'), '9:00 AM');
      expect(bookingService.formatTimeSlot('12:00'), '12:00 PM');
      expect(bookingService.formatTimeSlot('15:30'), '3:30 PM');
      expect(bookingService.formatTimeSlot('00:00'), '12:00 AM');
      expect(bookingService.formatTimeSlot('invalid'), 'invalid');
    });

    test('Should provide booking validation messages', () {
      // No date selected
      expect(bookingService.getBookingValidationMessage(), contains('select a date'));

      // Select past date
      final pastDate = DateTime.now().subtract(Duration(days: 1));
      bookingService.selectDate(pastDate);
      expect(bookingService.getBookingValidationMessage(), contains('not available'));

      // Select valid date but no time slot
      final futureDate = DateTime.now().add(Duration(days: 1));
      bookingService.selectDate(futureDate);
      expect(bookingService.getBookingValidationMessage(), contains('select a time slot'));
    });

    test('Should get available and booked time slots', () async {
      final testDate = DateTime.now().add(Duration(days: 1));
      final availability = MockCounselorAvailability(
        counselorId: 'counselor1',
        date: testDate,
        availableTimeSlots: ['09:00', '10:00', '11:00', '14:00'],
        bookedTimeSlots: ['10:00', '14:00'],
      );

      mockDatabase.seedAvailability({
        'counselor1_${testDate.toIso8601String().split('T')[0]}': availability,
      });

      await bookingService.loadCounselorAvailability('counselor1', testDate);

      final available = bookingService.getAvailableTimeSlots();
      final booked = bookingService.getBookedTimeSlots();

      expect(available, ['09:00', '11:00']);
      expect(booked, ['10:00', '14:00']);
    });

    test('Should generate booking statistics', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments([
        {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
        },
      ]);

      final availability = MockCounselorAvailability(
        counselorId: 'counselor1',
        date: tomorrow,
        availableTimeSlots: ['09:00', '10:00', '11:00'],
        bookedTimeSlots: ['10:00'],
      );

      mockDatabase.seedAvailability({
        'counselor1_${tomorrow.toIso8601String().split('T')[0]}': availability,
      });

      await bookingService.loadAppointments();
      await bookingService.loadCounselorAvailability('counselor1', tomorrow);
      bookingService.selectDate(tomorrow);
      bookingService.selectTimeSlot('09:00');

      final stats = bookingService.getBookingStatistics();

      expect(stats['total_appointments'], 1);
      expect(stats['upcoming_appointments'], 1);
      expect(stats['available_time_slots'], 2);
      expect(stats['booked_time_slots'], 1);
      expect(stats['has_date_selection'], true);
      expect(stats['has_time_selection'], true);
      expect(stats['can_book'], true);
      expect(stats['selected_date_formatted'], contains('${tomorrow.day}'));
      expect(stats['selected_time_formatted'], '9:00 AM');
    });

    test('Should clear selections and reset', () async {
      final testDate = DateTime.now().add(Duration(days: 1));
      final availability = MockCounselorAvailability(
        counselorId: 'counselor1',
        date: testDate,
        availableTimeSlots: ['09:00'],
        bookedTimeSlots: [],
      );

      mockDatabase.seedAvailability({
        'counselor1_${testDate.toIso8601String().split('T')[0]}': availability,
      });

      await bookingService.loadCounselorAvailability('counselor1', testDate);
      bookingService.selectDate(testDate);
      bookingService.selectTimeSlot('09:00');
      
      expect(bookingService.selectedDate, testDate);
      expect(bookingService.selectedTimeSlot, '09:00');
      
      bookingService.clearSelection();
      
      expect(bookingService.selectedDate, isNull);
      expect(bookingService.selectedTimeSlot, isNull);
      expect(bookingService.selectedCounselorId, isNull);
      
      bookingService.reset();
      
      expect(bookingService.appointments.length, 0);
      expect(bookingService.currentAvailability, isNull);
    });

    test('Should detect conflicting appointments', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments([
        {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
        },
      ]);

      await bookingService.loadAppointments();

      expect(bookingService.hasConflictingAppointment('student1', tomorrow, '10:00'), true);
      expect(bookingService.hasConflictingAppointment('student1', tomorrow, '11:00'), false);
      expect(bookingService.hasConflictingAppointment('student2', tomorrow, '10:00'), false);
    });

    test('Should validate time slot selection', () async {
      final testDate = DateTime.now().add(Duration(days: 1));
      final availability = MockCounselorAvailability(
        counselorId: 'counselor1',
        date: testDate,
        availableTimeSlots: ['09:00', '10:00'],
        bookedTimeSlots: ['10:00'],
      );

      mockDatabase.seedAvailability({
        'counselor1_${testDate.toIso8601String().split('T')[0]}': availability,
      });

      await bookingService.loadCounselorAvailability('counselor1', testDate);

      expect(bookingService.validateTimeSlotSelection('09:00'), isNull); // Valid
      expect(bookingService.validateTimeSlotSelection('10:00'), contains('already booked'));
      expect(bookingService.validateTimeSlotSelection('11:00'), contains('not in available slots'));
    });

    test('Should refresh availability', () async {
      final testDate = DateTime.now().add(Duration(days: 1));
      
      bookingService.selectDate(testDate);
      
      // Without counselor selected
      expect(await bookingService.refreshAvailability(), false);
      
      // With counselor selected
      final availability = MockCounselorAvailability(
        counselorId: 'counselor1',
        date: testDate,
        availableTimeSlots: ['09:00'],
        bookedTimeSlots: [],
      );

      mockDatabase.seedAvailability({
        'counselor1_${testDate.toIso8601String().split('T')[0]}': availability,
      });

      await bookingService.loadCounselorAvailability('counselor1', testDate);
      expect(await bookingService.refreshAvailability(), true);
    });
  });
}