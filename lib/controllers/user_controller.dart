import 'package:supabase_flutter/supabase_flutter.dart';

/// Result class for login operations
class LoginResult {
  final bool success;
  final String? errorMessage;
  final String? errorType; // 'email_not_verified', 'account_suspended', 'invalid_credentials', 'inactive_account', 'invalid_user_type', 'role_error', 'general'
  final String? userType;
  final String? userId;

  LoginResult({
    required this.success,
    this.errorMessage,
    this.errorType,
    this.userType,
    this.userId,
  });
}

/// Result class for password reset operations
class PasswordResetResult {
  final bool success;
  final String? errorMessage;

  PasswordResetResult({
    required this.success,
    this.errorMessage,
  });
}

/// Result class for signup phase 1 validation
class SignupPhase1Result {
  final bool success;
  final String? errorMessage;
  final String? errorTitle;

  SignupPhase1Result({
    required this.success,
    this.errorMessage,
    this.errorTitle,
  });
}

/// Result class for change password operations
class ChangePasswordResult {
  final bool success;
  final String? errorMessage;

  ChangePasswordResult({
    required this.success,
    this.errorMessage,
  });
}

/// Result class for reset password operations
class ResetPasswordResult {
  final bool success;
  final String? errorMessage;

  ResetPasswordResult({
    required this.success,
    this.errorMessage,
  });
}

/// Result class for signup phase 2 (account creation)
class SignupResult {
  final bool success;
  final String? errorMessage;
  final String? errorTitle;
  final String? userId;
  final String? email;

  SignupResult({
    required this.success,
    this.errorMessage,
    this.errorTitle,
    this.userId,
    this.email,
  });
}

class UserController {
  final _supabase = Supabase.instance.client;

  /// Validates email format
  bool validateEmail(String email) {
    if (email.isEmpty) return false;
    // More permissive RFC-compliant email regex
    // Allows: letters, numbers, dots, hyphens, underscores, percent, plus signs
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Validates password
  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password field is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Main login function
  Future<LoginResult> login(String email, String password) async {
    try {
      // Trim whitespace
      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();

      // Validate email format
      if (!validateEmail(trimmedEmail)) {
        return LoginResult(
          success: false,
          errorMessage: 'Invalid email format',
          errorType: 'invalid_credentials',
        );
      }

      // Validate password
      final passwordError = validatePassword(trimmedPassword);
      if (passwordError != null) {
        return LoginResult(
          success: false,
          errorMessage: passwordError,
          errorType: 'invalid_credentials',
        );
      }

      // Sign in with email and password using Supabase
      final response = await _supabase.auth
          .signInWithPassword(
            email: trimmedEmail,
            password: trimmedPassword,
          )
          .timeout(const Duration(seconds: 10));

      // Check if we have a user
      if (response.user == null) {
        return LoginResult(
          success: false,
          errorMessage: 'No user returned',
          errorType: 'general',
        );
      }

      print("Logged in: ${response.user?.email}");

      // Check if email is verified
      if (response.user!.emailConfirmedAt == null) {
        // Sign out the user since email is not verified
        await _supabase.auth.signOut();
        return LoginResult(
          success: false,
          errorMessage: 'Your email address has ss not been verified. Please check your inbox and click the verification link before logging ins.',
          errorType: 'email_not_verified',
        );
      }

      // Get user role and status from the database
      return await _getUserRoleAndStatus(response.user!.id);

    } on AuthException catch (e) {
      // Handle specific error codes
      if (e.message.contains('Invalid login credentials')) {
        return LoginResult(
          success: false,
          errorMessage: 'Invalid email or password. Please check your credentials and try again.',
          errorType: 'invalid_credentials',
        );
      } else if (e.message.contains('Email not confirmed') ||
          e.message.contains('email_not_confirmed') ||
          e.message.contains('signup_disabled')) {
        return LoginResult(
          success: false,
          errorMessage: 'Your email address has not been verified. Please check your inbox and click the verification link before logging in.',
          errorType: 'email_not_verified',
        );
      } else {
        return LoginResult(
          success: false,
          errorMessage: e.message,
          errorType: 'general',
        );
      }
    } catch (e) {
      return LoginResult(
        success: false,
        errorMessage: 'Something went wrong. Please try again later.',
        errorType: 'general',
      );
    }
  }

  /// Get user role and status from database
  Future<LoginResult> _getUserRoleAndStatus(String userId) async {
    print('Fetching user role for userId: $userId');
    try {
      // Fetch user data from 'users' table based on the userId
      final userData = await _supabase
          .from('users')
          .select('user_type, status')
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      // Log the response for debugging
      print('User Data: $userId');

      // Check if userData is not null and has a valid user_type and status
      if (userData == null) {
        return LoginResult(
          success: false,
          errorMessage: 'Could not determine user role or status. Please contact support.',
          errorType: 'role_error',
        );
      }

      if (userData['user_type'] == null || userData['status'] == null) {
        return LoginResult(
          success: false,
          errorMessage: 'Could not determine user role or status. Please contact support.',
          errorType: 'role_error',
        );
      }

      final userType = userData['user_type'] as String;
      final status = userData['status'] as String;

      // Check account status
      if (status == 'suspended') {
        return LoginResult(
          success: false,
          errorMessage: 'Your account has been suspended. Please contact support for assistance.',
          errorType: 'account_suspended',
        );
      }

      if (status != 'active') {
        return LoginResult(
          success: false,
          errorMessage: 'Your account is not active. Please contact support.',
          errorType: 'inactive_account',
        );
      }

      // Validate user type
      if (userType != 'student' && userType != 'counselor' && userType != 'admin') {
        return LoginResult(
          success: false,
          errorMessage: 'Invalid user type. Please contact support.',
          errorType: 'invalid_user_type',
        );
      }

      // Return success with user type
      return LoginResult(
        success: true,
        userType: userType,
        userId: userId,
      );

    } catch (e) {
      print('Error determining role: $e');
      return LoginResult(
        success: false,
        errorMessage: 'Could not retrieve user role. Please try again later.',
        errorType: 'role_error',
      );
    }
  }

  /// Send password reset email
  Future<PasswordResetResult> sendPasswordResetEmail(String email) async {
    try {
      final trimmedEmail = email.trim();

      // Validate email
      if (trimmedEmail.isEmpty) {
        return PasswordResetResult(
          success: false,
          errorMessage: 'Please enter your email address',
        );
      }

      if (!validateEmail(trimmedEmail)) {
        return PasswordResetResult(
          success: false,
          errorMessage: 'Please enter a valid email address',
        );
      }

      // Send reset email
      await _supabase.auth.resetPasswordForEmail(
        trimmedEmail,
        redirectTo: 'breathebetter://reset-password', // Deep link to open the app directly
      );

      return PasswordResetResult(success: true);

    } on AuthException catch (e) {
      return PasswordResetResult(
        success: false,
        errorMessage: 'Failed to send reset link: ${e.message}',
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        errorMessage: 'Something went wrong. Please try again later.',
      );
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get current user email
  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  /// Validate password confirmation
  String? validatePasswordConfirmation(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate student ID
  String? validateStudentId(String studentId) {
    if (studentId.isEmpty) {
      return 'Please enter your student ID number';
    }
    return null;
  }

  /// Validate name
  String? validateName(String name, String fieldName) {
    if (name.isEmpty) {
      return 'Please enter your $fieldName';
    }
    return null;
  }

  /// Validate year level
  String? validateYearLevel(String yearLevel, String? educationLevel) {
    if (yearLevel.isEmpty) {
      return 'Please enter your year/grade level';
    }
    
    final level = int.tryParse(yearLevel);
    if (level == null) {
      return 'Please enter a valid number';
    }
    
    // Validate based on selected education level
    switch (educationLevel) {
      case 'basic_education':
        if (level < 1 || level > 10) {
          return 'Basic Education grade level must be between 1 and 10';
        }
        break;
      case 'senior_high':
        if (level < 11 || level > 12) {
          return 'Senior High grade level must be between 11 and 12';
        }
        break;
      case 'college':
        if (level < 1 || level > 4) {
          return 'College year level must be between 1 and 4';
        }
        break;
      default:
        return 'Please select an education level first';
    }
    return null;
  }

  /// Phase 1: Validate email doesn't exist
  Future<SignupPhase1Result> validateSignupPhase1(String email) async {
    try {
      final trimmedEmail = email.trim();

      // Validate email format
      if (!validateEmail(trimmedEmail)) {
        return SignupPhase1Result(
          success: false,
          errorTitle: 'Invalid Email',
          errorMessage: 'Please enter a valid email address.',
        );
      }

      // Check if email already exists in users table
      final emailExists = await _supabase
          .from('users')
          .select('user_id')
          .eq('email', trimmedEmail)
          .maybeSingle();

      if (emailExists != null) {
        return SignupPhase1Result(
          success: false,
          errorTitle: 'Account Already Exists',
          errorMessage: 'An account with this email address already exists. Please use a different email address.',
        );
      }

      return SignupPhase1Result(success: true);

    } catch (e) {
      return SignupPhase1Result(
        success: false,
        errorTitle: 'Validation Failed',
        errorMessage: 'Something went wrong. Please try again later.',
      );
    }
  }

  /// Phase 2: Create account with student information
  Future<SignupResult> createStudentAccount({
    required String email,
    required String password,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String educationLevel,
    String? course,
    String? strand,
    required int yearLevel,
  }) async {
    try {
      final trimmedEmail = email.trim();
      final trimmedStudentCode = studentCode.trim();
      final trimmedFirstName = firstName.trim();
      final trimmedLastName = lastName.trim();

      // Additional email validation before Supabase call
      if (!validateEmail(trimmedEmail)) {
        return SignupResult(
          success: false,
          errorTitle: 'Invalid Email',
          errorMessage: 'Please enter a valid email address.',
        );
      }

      // Check for common email issues
      if (trimmedEmail.contains(' ')) {
        return SignupResult(
          success: false,
          errorTitle: 'Invalid Email',
          errorMessage: 'Email address cannot contain spaces.',
        );
      }

      if (trimmedEmail.length < 3 || !trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
        return SignupResult(
          success: false,
          errorTitle: 'Invalid Email',
          errorMessage: 'Please enter a complete email address (e.g., user@example.com).',
        );
      }

      // Validate student ID and name against database
      final validationResult = await validateStudentIdAndName(
        trimmedStudentCode,
        trimmedFirstName,
        trimmedLastName,
      );

      if (!validationResult.success) {
        return SignupResult(
          success: false,
          errorTitle: validationResult.errorTitle,
          errorMessage: validationResult.errorMessage,
        );
      }

      // Check if student_code already exists
      final studentCodeExists = await _supabase
          .from('students')
          .select('user_id')
          .eq('student_code', trimmedStudentCode)
          .maybeSingle();

      if (studentCodeExists != null) {
        return SignupResult(
          success: false,
          errorTitle: 'Student ID Already Exists',
          errorMessage: 'This Student ID is already registered. Please use a different Student ID.',
        );
      }

      // Create the account with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: trimmedEmail,
        password: password,
        emailRedirectTo: 'breathebetter://verify-email',
      );

      final user = authResponse.user;

      // Check if auth was successful
      if (user == null) {
        return SignupResult(
          success: false,
          errorTitle: 'Registration Failed',
          errorMessage: 'Account creation failed. Please try again.',
        );
      }

      // Check if user already exists in our users table (to prevent duplicates)
      final existingUser = await _supabase
          .from('users')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        // Insert into the 'users' table only if not exists
        await _supabase.from('users').insert({
          'user_id': user.id,
          'email': trimmedEmail,
          'registration_date': DateTime.now().toIso8601String(),
          'user_type': 'student',
          'status': 'active',
        });
      }

      // Check if student record already exists (to prevent duplicates)
      final existingStudent = await _supabase
          .from('students')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingStudent == null) {
        // Prepare student data
        Map<String, dynamic> studentData = {
          'user_id': user.id,
          'student_code': trimmedStudentCode,
          'first_name': trimmedFirstName,
          'last_name': trimmedLastName,
          'year_level': yearLevel,
        };

        // Add education-specific fields based on education level
        if (educationLevel == 'college') {
          studentData['education_level'] = 'college';
          studentData['course'] = course;
          studentData['strand'] = null;
        } else if (educationLevel == 'senior_high') {
          studentData['education_level'] = 'senior_high';
          studentData['course'] = null;
          studentData['strand'] = strand;
        } else if (educationLevel == 'basic_education') {
          studentData['education_level'] = 'basic_education';
          studentData['course'] = null;
          studentData['strand'] = null;
        }

        // Insert into the 'students' table
        await _supabase.from('students').insert(studentData);
      }

      return SignupResult(
        success: true,
        userId: user.id,
        email: trimmedEmail,
      );

    } on AuthException catch (e) {
      print('Supabase Auth error: ${e.message}');
      print('Supabase Auth code: ${e.statusCode}');
      String errorMessage = 'Registration failed. Please try again.';
      String errorTitle = 'Registration Failed';

      if (e.message.contains('For security purposes, you can only request this after')) {
        // Rate limiting error
        final match = RegExp(r'after (\d+) seconds?').firstMatch(e.message);
        final seconds = match?.group(1) ?? '13';
        errorMessage = 'Please wait $seconds seconds before trying to register again.';
        errorTitle = 'Too Many Attempts';
      } else if (e.message.contains('Email address') && e.message.contains('is invalid')) {
        // Specific email validation error from Supabase
        errorMessage = 'The email address appears to be invalid. Please check for any typos or extra spaces, or try a different email address.';
        errorTitle = 'Invalid Email Format';
      } else if (e.message.contains('email')) {
        errorMessage = 'Invalid email address or email already in use.';
        errorTitle = 'Invalid Email';
      } else if (e.message.contains('password')) {
        errorMessage = 'Password is too weak. Please use a stronger password.';
        errorTitle = 'Weak Password';
      } else if (e.message.contains('User already registered')) {
        errorMessage = 'An account with this email already exists. Please use a different email or try signing in.';
        errorTitle = 'Account Already Exists';
      }

      return SignupResult(
        success: false,
        errorTitle: errorTitle,
        errorMessage: errorMessage,
      );

    } catch (e) {
      print('Phase 2 signup error: $e');
      return SignupResult(
        success: false,
        errorTitle: 'Registration Failed',
        errorMessage: 'Something went wrong. Please try again later.',
      );
    }
  }

  /// Validate student ID and name against student_ids table
  Future<SignupPhase1Result> validateStudentIdAndName(
    String studentId,
    String firstName,
    String lastName,
  ) async {
    try {
      final trimmedFirstName = firstName.trim();
      final trimmedLastName = lastName.trim();

      print('DEBUG - Validating Student ID: $studentId');
      print('DEBUG - First Name: $trimmedFirstName, Last Name: $trimmedLastName');

      // Query the student_ids table by student_id (this is the reference table)
      // Note: student_id in student_ids table = student_code in students table
      final studentRecordById = await _supabase
          .from('student_ids')
          .select('student_id, first_name, last_name')
          .eq('student_id', studentId)
          .maybeSingle();

      print('DEBUG - Query executed on student_ids table');
      print('DEBUG - Record found by ID: $studentRecordById');

      // Case 1: Student ID exists in reference table - check if name matches
      if (studentRecordById != null) {
        final dbFirstName = (studentRecordById['first_name'] as String?)?.trim().toLowerCase();
        final dbLastName = (studentRecordById['last_name'] as String?)?.trim().toLowerCase();
        final inputFirstName = trimmedFirstName.toLowerCase();
        final inputLastName = trimmedLastName.toLowerCase();

        print('DEBUG - DB First Name: "$dbFirstName", Input: "$inputFirstName"');
        print('DEBUG - DB Last Name: "$dbLastName", Input: "$inputLastName"');

        if (dbFirstName == inputFirstName && dbLastName == inputLastName) {
          // ID and name both match in reference table - success!
          print('DEBUG - Validation SUCCESS: ID and name match');
          return SignupPhase1Result(success: true);
        } else {
          // ID exists but name doesn't match
          print('DEBUG - Validation FAILED: ID found but name mismatch');
          return SignupPhase1Result(
            success: false,
            errorTitle: 'Name Verification Failed',
            errorMessage: 'This Student ID is not registered under the name you provided. Please check that your first and last name match exactly as they appear on your student ID card.',
          );
        }
      }

      // Case 2: Student ID not found in reference table - check if name exists with a different ID
      print('DEBUG - Student ID not found, checking if name exists...');
      final studentRecordByName = await _supabase
          .from('student_ids')
          .select('student_id, first_name, last_name')
          .ilike('first_name', trimmedFirstName)
          .ilike('last_name', trimmedLastName)
          .maybeSingle();

      print('DEBUG - Record found by name: $studentRecordByName');

      if (studentRecordByName != null) {
        // Name exists but with different ID
        print('DEBUG - Validation FAILED: Name found but different ID');
        return SignupPhase1Result(
          success: false,
          errorTitle: 'Student ID Verification Failed',
          errorMessage: 'The name you entered is registered in our system, but under a different Student ID. Please verify your Student ID number and try again.',
        );
      }

      // Case 3: Neither ID nor name found in reference table
      print('DEBUG - Validation FAILED: Neither ID nor name found in student_ids table');
      return SignupPhase1Result(
        success: false,
        errorTitle: 'Invalid Information',
        errorMessage: 'The Student ID and name you entered are not registered in our system. Please verify your student ID card and try again.',
      );

    } catch (e) {
      print('Student ID validation error: $e');
      return SignupPhase1Result(
        success: false,
        errorTitle: 'Validation Failed',
        errorMessage: 'Unable to validate student information. Please try again later.',
      );
    }
  }

  // ===========================
  // Password Management Methods
  // ===========================

  /// Change the current user's password
  /// Verifies the current password before updating to the new one
  Future<ChangePasswordResult> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Verify current password by attempting to sign in
      final signInResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      if (signInResponse.user == null) {
        return ChangePasswordResult(
          success: false,
          errorMessage: 'Current password is incorrect.',
        );
      }

      // Update to new password
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return ChangePasswordResult(success: true);
    } on AuthException catch (e) {
      String errorMessage = 'Failed to change password.';

      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'Current password is incorrect.';
      } else if (e.message.contains('Password should be at least')) {
        errorMessage = 'New password must be at least 6 characters long.';
      } else if (e.message.contains('Same as old password')) {
        errorMessage = 'New password cannot be the same as your current password.';
      } else {
        errorMessage = e.message;
      }

      return ChangePasswordResult(
        success: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return ChangePasswordResult(
        success: false,
        errorMessage: 'An unexpected error occurred. Please try again later.',
      );
    }
  }

  /// Reset password for a user who clicked the reset link from email
  /// The user must have a valid session from the email link
  Future<ResetPasswordResult> resetPassword({
    required String newPassword,
  }) async {
    try {
      // Update the user's password
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return ResetPasswordResult(success: true);
    } on AuthException catch (e) {
      String errorMessage = 'Failed to reset password.';

      if (e.message.contains('Password should be at least')) {
        errorMessage = 'Password must be at least 6 characters long.';
      } else if (e.message.contains('Invalid session')) {
        errorMessage = 'Reset link has expired. Please request a new password reset.';
      } else {
        errorMessage = e.message;
      }

      return ResetPasswordResult(
        success: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return ResetPasswordResult(
        success: false,
        errorMessage: 'An unexpected error occurred. Please try again later.',
      );
    }
  }
}
