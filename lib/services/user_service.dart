import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class UserService {
  static final _studentNameController = StreamController<String>.broadcast();
  static Stream<String> get studentNameStream => _studentNameController.stream;

  // Helper function to properly capitalize names (keeps internal capitals)
  static String formatName(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }

  static Future<String> getStudentName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Guest';

    try {
      // First try to get student info from students table
      final studentResponse = await Supabase.instance.client
          .from('students')
          .select('first_name, last_name')
          .eq('user_id', user.id)
          .maybeSingle();

      if (studentResponse != null &&
          studentResponse['first_name'] != null &&
          studentResponse['last_name'] != null) {
        final firstName = formatName(studentResponse['first_name']);
        final lastName = formatName(studentResponse['last_name']);
        final fullName = '$firstName $lastName';
        _studentNameController.add(fullName);
        return fullName;
      }

      // Fallback to email if student info not found
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('email')
          .eq('user_id', user.id)
          .maybeSingle();

      final fallbackName = userResponse?['email'] ?? 'Guest';
      _studentNameController.add(fallbackName);
      return fallbackName;
    } catch (e) {
      print('Error fetching student name: $e');
      _studentNameController.add('Guest');
      return 'Guest';
    }
  }

  static Future<void> updateStudentName(String firstName, String lastName) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('students')
          .update({
            'first_name': firstName,
            'last_name': lastName,
          }).eq('user_id', user.id);

      final formattedFirstName = formatName(firstName);
      final formattedLastName = formatName(lastName);
      final fullName = '$formattedFirstName $formattedLastName';
      _studentNameController.add(fullName);
    } catch (e) {
      print('Error updating student name: $e');
    }
  }

  static void dispose() {
    _studentNameController.close();
  }
}
