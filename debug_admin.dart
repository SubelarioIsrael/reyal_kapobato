import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase - you'll need to replace these with your actual credentials
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  await testAdminQueries();
}

Future<void> testAdminQueries() async {
  try {
    final supabase = Supabase.instance.client;
    
    print('Testing database queries...');
    
    // Test 1: Get total users count
    print('\n1. Testing total users query...');
    try {
      final totalUsersResponse = await supabase.from('users').select('user_id');
      print('Total users found: ${totalUsersResponse.length}');
      print('Sample users: ${totalUsersResponse.take(3)}');
    } catch (e) {
      print('Error fetching total users: $e');
    }
    
    // Test 2: Check students table structure
    print('\n2. Testing students table...');
    try {
      final studentsResponse = await supabase
          .from('students')
          .select('user_id, last_login, student_id, first_name, last_name')
          .limit(5);
      print('Students found: ${studentsResponse.length}');
      print('Sample students: $studentsResponse');
    } catch (e) {
      print('Error fetching students: $e');
    }
    
    // Test 3: Check appointments table
    print('\n3. Testing appointments table...');
    try {
      final appointmentsResponse = await supabase
          .from('counseling_appointments')
          .select('appointment_id, status')
          .limit(10);
      print('Appointments found: ${appointmentsResponse.length}');
      print('Sample appointments: $appointmentsResponse');
      
      // Get unique statuses
      final statuses = appointmentsResponse.map((a) => a['status']).toSet();
      print('Unique statuses found: $statuses');
    } catch (e) {
      print('Error fetching appointments: $e');
    }
    
    // Test 4: Check users table structure
    print('\n4. Testing users table structure...');
    try {
      final usersResponse = await supabase
          .from('users')
          .select('user_id, email, user_type, status, registration_date')
          .limit(5);
      print('Users found: ${usersResponse.length}');
      print('Sample users: $usersResponse');
    } catch (e) {
      print('Error fetching users structure: $e');
    }
    
  } catch (e) {
    print('Overall error: $e');
  }
}