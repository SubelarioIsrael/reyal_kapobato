import 'package:supabase_flutter/supabase_flutter.dart';

/// Result class for loading users
class LoadUsersResult {
  final bool success;
  final List<Map<String, dynamic>> users;
  final String? errorMessage;

  LoadUsersResult({
    required this.success,
    this.users = const [],
    this.errorMessage,
  });
}

/// Result class for creating a new user
class CreateUserResult {
  final bool success;
  final String? errorMessage;
  final String? errorType; // 'email_exists', 'general'
  final String? userId;
  final String? email;
  final String? password;
  final String? role;

  CreateUserResult({
    required this.success,
    this.errorMessage,
    this.errorType,
    this.userId,
    this.email,
    this.password,
    this.role,
  });
}

/// Result class for toggling user status
class ToggleUserStatusResult {
  final bool success;
  final String? errorMessage;
  final String? newStatus;

  ToggleUserStatusResult({
    required this.success,
    this.errorMessage,
    this.newStatus,
  });
}

/// Admin Users Controller - Handles user management operations
class AdminUsersController {
  final _supabase = Supabase.instance.client;

  /// Load all users with their student/counselor data
  Future<LoadUsersResult> loadUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('*, students(*), counselors(*)')
          .order('email');

      return LoadUsersResult(
        success: true,
        users: List<Map<String, dynamic>>.from(response),
      );
    } catch (e) {
      print('Error loading users: $e');
      return LoadUsersResult(
        success: false,
        errorMessage: 'Failed to load users: ${e.toString()}',
      );
    }
  }

  /// Toggle user status between active and suspended
  Future<ToggleUserStatusResult> toggleUserStatus(
      String userId, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
      
      await _supabase
          .from('users')
          .update({'status': newStatus})
          .eq('user_id', userId);

      return ToggleUserStatusResult(
        success: true,
        newStatus: newStatus,
      );
    } catch (e) {
      print('Error updating user status: $e');
      return ToggleUserStatusResult(
        success: false,
        errorMessage: 'Failed to update user status: ${e.toString()}',
      );
    }
  }

  /// Create a new user account (admin or counselor)
  Future<CreateUserResult> createUser({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();

      // Check if email already exists
      final existingUser = await _supabase
          .from('users')
          .select('email')
          .eq('email', trimmedEmail)
          .maybeSingle();

      if (existingUser != null) {
        return CreateUserResult(
          success: false,
          errorType: 'email_exists',
          errorMessage: 'The email address "$trimmedEmail" is already registered in the system.',
        );
      }

      // Create auth user
      final authResponse = await _supabase.auth.signUp(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      if (authResponse.user == null) {
        return CreateUserResult(
          success: false,
          errorType: 'general',
          errorMessage: 'Failed to create user account.',
        );
      }

      // Insert user data into users table
      await _supabase.from('users').insert({
        'user_id': authResponse.user!.id,
        'email': trimmedEmail,
        'user_type': role,
        'status': 'active',
        'registration_date': DateTime.now().toIso8601String(),
      });

      return CreateUserResult(
        success: true,
        userId: authResponse.user!.id,
        email: trimmedEmail,
        password: trimmedPassword,
        role: role,
      );
    } catch (e) {
      print('Error creating user: $e');
      return CreateUserResult(
        success: false,
        errorType: 'general',
        errorMessage: 'Failed to create user: ${e.toString()}',
      );
    }
  }

  /// Validate email format
  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter an email';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email';
    }
    return null;
  }

  /// Validate password
  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please enter a password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate password confirmation
  String? validatePasswordConfirmation(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}
