class Appointment {
  final int id;
  final int counselorId;
  final String userId;
  final DateTime appointmentDate;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? notes;
  final String? statusMessage;
  final String? counselorName;

  Appointment({
    required this.id,
    required this.counselorId,
    required this.userId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
    this.statusMessage,
    this.counselorName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    // Parse the date string (YYYY-MM-DD)
    final dateParts = json['appointment_date'].toString().split('-');
    final appointmentDate = DateTime(
      int.parse(dateParts[0]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[2]), // day
    );

    // Parse the time strings (HH:mm:ss)
    final startTimeParts = json['start_time'].toString().split(':');
    final endTimeParts = json['end_time'].toString().split(':');

    final startTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      int.parse(startTimeParts[0]), // hour
      int.parse(startTimeParts[1]), // minute
    );

    final endTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      int.parse(endTimeParts[0]), // hour
      int.parse(endTimeParts[1]), // minute
    );

    return Appointment(
      id: json['appointment_id'],
      counselorId: json['counselor_id'],
      userId: json['user_id'],
      appointmentDate: appointmentDate,
      startTime: startTime,
      endTime: endTime,
      status: json['status'],
      notes: json['notes'],
      statusMessage: json['status_message'],
      counselorName: json['counselor_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointment_id': id,
      'counselor_id': counselorId,
      'user_id': userId,
      'appointment_date': appointmentDate.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'notes': notes,
      'status_message': statusMessage,
      'counselor_name': counselorName,
    };
  }
}
