// AM-AM-01: Both student and counselor can view appointments schedule
// Requirement: Both users can access and view their scheduled appointments with proper filtering
// Mirrors appointment viewing functionality for both user types

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent an appointment
class MockAppointment {
  final String id;
  final String studentId;
  final String counselorId;
  final DateTime appointmentDate;
  final String timeSlot;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? studentName;
  final String? counselorName;

  MockAppointment({
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

  factory MockAppointment.fromMap(Map<String, dynamic> map) {
    return MockAppointment(
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

  bool isUpcoming() {
    return appointmentDate.isAfter(DateTime.now());
  }

  bool isPast() {
    return appointmentDate.isBefore(DateTime.now());
  }

  bool isToday() {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
           appointmentDate.month == now.month &&
           appointmentDate.day == now.day;
  }
}

// Mock database for appointment viewing
class MockAppointmentViewDatabase {
  List<Map<String, dynamic>> _appointments = [];
  bool _shouldThrowError = false;

  void seedAppointments(List<Map<String, dynamic>> appointments) {
    _appointments = appointments;
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  Future<List<Map<String, dynamic>>> getStudentAppointments(String studentId) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Error loading student appointments');
    }
    
    return _appointments.where((a) => a['student_id'] == studentId).toList();
  }

  Future<List<Map<String, dynamic>>> getCounselorAppointments(String counselorId) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Error loading counselor appointments');
    }
    
    return _appointments.where((a) => a['counselor_id'] == counselorId).toList();
  }

  Future<List<Map<String, dynamic>>> getAllAppointments() async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Error loading appointments');
    }
    
    return List.from(_appointments);
  }

  Future<Map<String, dynamic>?> getAppointmentById(String appointmentId) async {
    await Future.delayed(Duration(milliseconds: 50));
    
    if (_shouldThrowError) {
      throw Exception('Error loading appointment');
    }
    
    try {
      return _appointments.firstWhere((a) => a['id'] == appointmentId);
    } catch (e) {
      return null;
    }
  }
}

// Service class for appointment viewing
class AppointmentViewService {
  final MockAppointmentViewDatabase _database;
  List<MockAppointment> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  String? _currentUserType; // 'student' or 'counselor'

  AppointmentViewService(this._database);

  List<MockAppointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;
  String? get currentUserType => _currentUserType;

  Future<void> loadStudentAppointments(String studentId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _currentUserId = studentId;
      _currentUserType = 'student';

      final appointmentsData = await _database.getStudentAppointments(studentId);
      _appointments = appointmentsData.map((data) => MockAppointment.fromMap(data)).toList();

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _appointments = [];
    }
  }

  Future<void> loadCounselorAppointments(String counselorId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _currentUserId = counselorId;
      _currentUserType = 'counselor';

      final appointmentsData = await _database.getCounselorAppointments(counselorId);
      _appointments = appointmentsData.map((data) => MockAppointment.fromMap(data)).toList();

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _appointments = [];
    }
  }

  List<MockAppointment> getUpcomingAppointments() {
    return _appointments.where((a) => a.isUpcoming() && !a.isToday() && a.status != 'cancelled').toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  List<MockAppointment> getPastAppointments() {
    return _appointments.where((a) => a.isPast()).toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
  }

  List<MockAppointment> getTodayAppointments() {
    return _appointments.where((a) => a.isToday() && a.status != 'cancelled').toList()
      ..sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
  }

  List<MockAppointment> getAppointmentsByStatus(String status) {
    return _appointments.where((a) => a.status.toLowerCase() == status.toLowerCase()).toList();
  }

  List<MockAppointment> getAppointmentsByDateRange(DateTime startDate, DateTime endDate) {
    return _appointments.where((a) =>
        a.appointmentDate.isAfter(startDate.subtract(Duration(days: 1))) &&
        a.appointmentDate.isBefore(endDate.add(Duration(days: 1)))).toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  String formatAppointmentDate(MockAppointment appointment) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final date = appointment.appointmentDate;
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String formatAppointmentTime(MockAppointment appointment) {
    try {
      final parts = appointment.timeSlot.split(':');
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
    
    return appointment.timeSlot;
  }

  String getAppointmentStatusColor(MockAppointment appointment) {
    switch (appointment.status.toLowerCase()) {
      case 'scheduled':
        return '#4CAF50'; // Green
      case 'completed':
        return '#2196F3'; // Blue
      case 'cancelled':
        return '#F44336'; // Red
      case 'rescheduled':
        return '#FF9800'; // Orange
      case 'pending':
        return '#FFC107'; // Yellow
      default:
        return '#9E9E9E'; // Grey
    }
  }

  String getDisplayName(MockAppointment appointment) {
    if (_currentUserType == 'student') {
      return appointment.counselorName ?? 'Unknown Counselor';
    } else {
      return appointment.studentName ?? 'Unknown Student';
    }
  }

  bool hasAppointments() {
    return _appointments.isNotEmpty;
  }

  int getAppointmentsCount() {
    return _appointments.length;
  }

  Map<String, dynamic> getAppointmentStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final upcoming = getUpcomingAppointments();
    final past = getPastAppointments();
    final todayAppts = getTodayAppointments();
    
    final statusCounts = <String, int>{};
    for (final appointment in _appointments) {
      statusCounts[appointment.status] = (statusCounts[appointment.status] ?? 0) + 1;
    }
    
    final thisWeek = _appointments.where((a) {
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(Duration(days: 6));
      final appointmentDate = DateTime(a.appointmentDate.year, a.appointmentDate.month, a.appointmentDate.day);
      return appointmentDate.compareTo(startOfWeek) >= 0 && appointmentDate.compareTo(endOfWeek) <= 0;
    }).length;
    
    final thisMonth = _appointments.where((a) =>
        a.appointmentDate.year == now.year && a.appointmentDate.month == now.month).length;

    return {
      'total_appointments': _appointments.length,
      'upcoming_appointments': upcoming.length,
      'past_appointments': past.length,
      'today_appointments': todayAppts.length,
      'this_week_appointments': thisWeek,
      'this_month_appointments': thisMonth,
      'status_counts': statusCounts,
      'user_type': _currentUserType,
      'user_id': _currentUserId,
      'has_appointments': hasAppointments(),
      'is_loaded': !_isLoading && _errorMessage == null,
    };
  }

  List<MockAppointment> searchAppointments(String query) {
    if (query.isEmpty) return _appointments;
    
    final lowercaseQuery = query.toLowerCase();
    return _appointments.where((appointment) {
      final searchFields = [
        appointment.studentName?.toLowerCase() ?? '',
        appointment.counselorName?.toLowerCase() ?? '',
        appointment.status.toLowerCase(),
        appointment.notes?.toLowerCase() ?? '',
        formatAppointmentDate(appointment).toLowerCase(),
        formatAppointmentTime(appointment).toLowerCase(),
      ];
      
      return searchFields.any((field) => field.contains(lowercaseQuery));
    }).toList();
  }

  void sortAppointments(String sortBy, {bool ascending = true}) {
    switch (sortBy.toLowerCase()) {
      case 'date':
        _appointments.sort((a, b) => ascending
            ? a.appointmentDate.compareTo(b.appointmentDate)
            : b.appointmentDate.compareTo(a.appointmentDate));
        break;
      case 'time':
        _appointments.sort((a, b) => ascending
            ? a.timeSlot.compareTo(b.timeSlot)
            : b.timeSlot.compareTo(a.timeSlot));
        break;
      case 'status':
        _appointments.sort((a, b) => ascending
            ? a.status.compareTo(b.status)
            : b.status.compareTo(a.status));
        break;
      case 'name':
        _appointments.sort((a, b) {
          final nameA = getDisplayName(a).toLowerCase();
          final nameB = getDisplayName(b).toLowerCase();
          return ascending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
        });
        break;
    }
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _appointments.clear();
    _currentUserId = null;
    _currentUserType = null;
    _isLoading = false;
    _errorMessage = null;
  }

  MockAppointment? findAppointmentById(String appointmentId) {
    try {
      return _appointments.firstWhere((a) => a.id == appointmentId);
    } catch (e) {
      return null;
    }
  }

  bool isStudentView() {
    return _currentUserType == 'student';
  }

  bool isCounselorView() {
    return _currentUserType == 'counselor';
  }

  List<String> getUniqueStatuses() {
    return _appointments.map((a) => a.status).toSet().toList()..sort();
  }

  Future<void> refreshAppointments() async {
    if (_currentUserId != null && _currentUserType != null) {
      if (_currentUserType == 'student') {
        await loadStudentAppointments(_currentUserId!);
      } else if (_currentUserType == 'counselor') {
        await loadCounselorAppointments(_currentUserId!);
      }
    }
  }

  String getEmptyStateMessage() {
    if (_currentUserType == 'student') {
      return 'No appointments scheduled. Book your first appointment with a counselor.';
    } else if (_currentUserType == 'counselor') {
      return 'No appointments scheduled. Students will be able to book appointments with you.';
    }
    return 'No appointments found.';
  }

  bool canViewAppointmentDetails(MockAppointment appointment) {
    if (_currentUserType == 'student') {
      return appointment.studentId == _currentUserId;
    } else if (_currentUserType == 'counselor') {
      return appointment.counselorId == _currentUserId;
    }
    return false;
  }
}

void main() {
  group('AM-AM-01: Both student and counselor can view appointments schedule', () {
    late MockAppointmentViewDatabase mockDatabase;
    late AppointmentViewService viewService;

    setUp(() {
      mockDatabase = MockAppointmentViewDatabase();
      viewService = AppointmentViewService(mockDatabase);
    });

    test('Should load student appointments successfully', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      
      mockDatabase.seedAppointments([
        {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': 'First appointment',
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'appointment2',
          'student_id': 'student1',
          'counselor_id': 'counselor2',
          'appointment_date': yesterday.toIso8601String(),
          'time_slot': '14:00',
          'status': 'completed',
          'notes': 'Follow-up session',
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Johnson',
        },
      ]);

      await viewService.loadStudentAppointments('student1');

      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, isNull);
      expect(viewService.appointments.length, 2);
      expect(viewService.currentUserId, 'student1');
      expect(viewService.currentUserType, 'student');
      expect(viewService.isStudentView(), true);
      expect(viewService.isCounselorView(), false);
    });

    test('Should load counselor appointments successfully', () async {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      
      mockDatabase.seedAppointments([
        {
          'id': 'appointment1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': 'Counseling session',
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'appointment2',
          'student_id': 'student2',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '15:00',
          'status': 'scheduled',
          'notes': 'Initial consultation',
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'Jane Smith',
          'counselor_name': 'Dr. Smith',
        },
      ]);

      await viewService.loadCounselorAppointments('counselor1');

      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, isNull);
      expect(viewService.appointments.length, 2);
      expect(viewService.currentUserId, 'counselor1');
      expect(viewService.currentUserType, 'counselor');
      expect(viewService.isStudentView(), false);
      expect(viewService.isCounselorView(), true);
    });

    test('Should handle loading errors', () async {
      mockDatabase.setShouldThrowError(true);

      await viewService.loadStudentAppointments('student1');

      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, contains('Error loading student appointments'));
      expect(viewService.appointments.length, 0);
    });

    test('Should filter upcoming appointments', () async {
      final now = DateTime.now();
      final tomorrow = now.add(Duration(days: 1));
      final nextWeek = now.add(Duration(days: 7));
      final yesterday = now.subtract(Duration(days: 1));
      
      mockDatabase.seedAppointments([
        {
          'id': 'upcoming1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': now.toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'upcoming2',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': nextWeek.toIso8601String(),
          'time_slot': '14:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': now.toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'past1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': yesterday.toIso8601String(),
          'time_slot': '10:00',
          'status': 'completed',
          'notes': null,
          'created_at': now.toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      ]);

      await viewService.loadStudentAppointments('student1');
      final upcoming = viewService.getUpcomingAppointments();

      expect(upcoming.length, 2);
      expect(upcoming.every((a) => a.isUpcoming()), true);
      expect(upcoming[0].appointmentDate.isBefore(upcoming[1].appointmentDate), true); // Sorted by date
    });

    test('Should filter past appointments', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));
      final lastWeek = now.subtract(Duration(days: 7));
      final tomorrow = now.add(Duration(days: 1));
      
      mockDatabase.seedAppointments([
        {
          'id': 'past1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': yesterday.toIso8601String(),
          'time_slot': '10:00',
          'status': 'completed',
          'notes': null,
          'created_at': now.toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'past2',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': lastWeek.toIso8601String(),
          'time_slot': '14:00',
          'status': 'completed',
          'notes': null,
          'created_at': now.toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'future1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': now.toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      ]);

      await viewService.loadStudentAppointments('student1');
      final past = viewService.getPastAppointments();

      expect(past.length, 2);
      expect(past.every((a) => a.isPast()), true);
      expect(past[0].appointmentDate.isAfter(past[1].appointmentDate), true); // Sorted by date desc
    });

    test('Should filter today appointments', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 10, 0);
      final todayLater = DateTime(now.year, now.month, now.day, 15, 0);
      final tomorrow = now.add(Duration(days: 1));
      
      mockDatabase.seedAppointments([
        {
          'id': 'today1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': today.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': now.toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'today2',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': todayLater.toIso8601String(),
          'time_slot': '15:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': now.toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'tomorrow1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': now.toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      ]);

      await viewService.loadStudentAppointments('student1');
      final todayAppointments = viewService.getTodayAppointments();

      expect(todayAppointments.length, 2);
      expect(todayAppointments.every((a) => a.isToday()), true);
      expect(todayAppointments[0].timeSlot.compareTo(todayAppointments[1].timeSlot) <= 0, true); // Sorted by time
    });

    test('Should format appointment dates and times correctly', () async {
      final testDate = DateTime(2024, 3, 15, 14, 30);
      
      mockDatabase.seedAppointments([
        {
          'id': 'test1',
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
      ]);

      await viewService.loadStudentAppointments('student1');
      final appointment = viewService.appointments[0];

      expect(viewService.formatAppointmentDate(appointment), 'Mar 15, 2024');
      expect(viewService.formatAppointmentTime(appointment), '2:30 PM');
    });

    test('Should provide correct status colors', () async {
      mockDatabase.seedAppointments([
        {
          'id': 'scheduled',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      ]);

      await viewService.loadStudentAppointments('student1');
      final appointment = viewService.appointments[0];

      expect(viewService.getAppointmentStatusColor(appointment), '#4CAF50');
    });

    test('Should provide correct display names based on user type', () async {
      mockDatabase.seedAppointments([
        {
          'id': 'test1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      ]);

      // Test student view
      await viewService.loadStudentAppointments('student1');
      expect(viewService.getDisplayName(viewService.appointments[0]), 'Dr. Smith');

      // Test counselor view
      await viewService.loadCounselorAppointments('counselor1');
      expect(viewService.getDisplayName(viewService.appointments[0]), 'John Doe');
    });

    test('Should generate appointment statistics', () async {
      final now = DateTime.now();
      final tomorrow = now.add(Duration(days: 1));
      final yesterday = now.subtract(Duration(days: 1));
      final today = DateTime(now.year, now.month, now.day, 10, 0);
      
      mockDatabase.seedAppointments([
        {
          'id': 'scheduled1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': tomorrow.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': now.toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'completed1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': yesterday.toIso8601String(),
          'time_slot': '14:00',
          'status': 'completed',
          'notes': null,
          'created_at': now.toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'today1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': today.toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': now.toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      ]);

      await viewService.loadStudentAppointments('student1');
      final stats = viewService.getAppointmentStatistics();

      expect(stats['total_appointments'], 3);
      expect(stats['upcoming_appointments'], 1); // Only tomorrow is upcoming
      expect(stats['past_appointments'], 1); // Only yesterday is past
      expect(stats['today_appointments'], 1); // Only one today appointment
      expect(stats['status_counts']['scheduled'], 2);
      expect(stats['status_counts']['completed'], 1);
      expect(stats['user_type'], 'student');
      expect(stats['user_id'], 'student1');
      expect(stats['has_appointments'], true);
      expect(stats['is_loaded'], true);
    });

    test('Should search appointments correctly', () async {
      mockDatabase.seedAppointments([
        {
          'id': 'search1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': 'anxiety counseling session',
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'search2',
          'student_id': 'student1',
          'counselor_id': 'counselor2',
          'appointment_date': DateTime.now().add(Duration(days: 2)).toIso8601String(),
          'time_slot': '14:00',
          'status': 'completed',
          'notes': 'depression therapy',
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Johnson',
        },
      ]);

      await viewService.loadStudentAppointments('student1');

      final searchResults = viewService.searchAppointments('smith');
      expect(searchResults.length, 1);
      expect(searchResults[0].counselorName, 'Dr. Smith');

      final noteSearch = viewService.searchAppointments('anxiety');
      expect(noteSearch.length, 1);
      expect(noteSearch[0].notes, contains('anxiety'));

      final statusSearch = viewService.searchAppointments('completed');
      expect(statusSearch.length, 1);
      expect(statusSearch[0].status, 'completed');
    });

    test('Should sort appointments correctly', () async {
      final date1 = DateTime.now().add(Duration(days: 1));
      final date2 = DateTime.now().add(Duration(days: 2));
      
      mockDatabase.seedAppointments([
        {
          'id': 'sort2',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': date2.toIso8601String(),
          'time_slot': '15:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'sort1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': date1.toIso8601String(),
          'time_slot': '10:00',
          'status': 'completed',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Johnson',
        },
      ]);

      await viewService.loadStudentAppointments('student1');

      // Sort by date ascending
      viewService.sortAppointments('date', ascending: true);
      expect(viewService.appointments[0].appointmentDate.isBefore(viewService.appointments[1].appointmentDate), true);

      // Sort by status ascending
      viewService.sortAppointments('status', ascending: true);
      expect(viewService.appointments[0].status.compareTo(viewService.appointments[1].status) <= 0, true);
    });

    test('Should handle empty appointments correctly', () async {
      mockDatabase.seedAppointments([]);

      await viewService.loadStudentAppointments('student1');

      expect(viewService.hasAppointments(), false);
      expect(viewService.getAppointmentsCount(), 0);
      expect(viewService.getEmptyStateMessage(), contains('No appointments scheduled'));
    });

    test('Should validate appointment access permissions', () async {
      mockDatabase.seedAppointments([
        {
          'id': 'access1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      ]);

      // Test student access
      await viewService.loadStudentAppointments('student1');
      expect(viewService.canViewAppointmentDetails(viewService.appointments[0]), true);

      // Test counselor access
      await viewService.loadCounselorAppointments('counselor1');
      expect(viewService.canViewAppointmentDetails(viewService.appointments[0]), true);
    });

    test('Should refresh appointments', () async {
      mockDatabase.seedAppointments([
        {
          'id': 'refresh1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      ]);

      await viewService.loadStudentAppointments('student1');
      expect(viewService.appointments.length, 1);

      // Add more appointments
      mockDatabase.seedAppointments([
        {
          'id': 'refresh1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
        {
          'id': 'refresh2',
          'student_id': 'student1',
          'counselor_id': 'counselor2',
          'appointment_date': DateTime.now().add(Duration(days: 2)).toIso8601String(),
          'time_slot': '14:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Johnson',
        },
      ]);

      await viewService.refreshAppointments();
      expect(viewService.appointments.length, 2);
    });

    test('Should reset service state', () async {
      mockDatabase.seedAppointments([
        {
          'id': 'reset1',
          'student_id': 'student1',
          'counselor_id': 'counselor1',
          'appointment_date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'time_slot': '10:00',
          'status': 'scheduled',
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'student_name': 'John Doe',
          'counselor_name': 'Dr. Smith',
        },
      ]);

      await viewService.loadStudentAppointments('student1');
      expect(viewService.appointments.length, 1);
      expect(viewService.currentUserId, 'student1');
      expect(viewService.currentUserType, 'student');

      viewService.reset();

      expect(viewService.appointments.length, 0);
      expect(viewService.currentUserId, isNull);
      expect(viewService.currentUserType, isNull);
      expect(viewService.isLoading, false);
      expect(viewService.errorMessage, isNull);
    });
  });
}