/// Shared test models and services for UAM-UL test cases
/// 
/// This file contains the mock services and data models used across
/// all login test cases (UAM-UL-01 to UAM-UL-06).

// Mock Authentication Service
class MockAuthService {
  final Map<String, Map<String, dynamic>> _users = {
    'valid@example.com': {
      'password': 'password123',
      'user_id': 'user-1',
      'user_type': 'student',
      'status': 'active',
      'email_verified': true,
    },
    'suspended@example.com': {
      'password': 'password123',
      'user_id': 'user-2',
      'user_type': 'student',
      'status': 'suspended',
      'email_verified': true,
    },
    'unverified@example.com': {
      'password': 'password123',
      'user_id': 'user-3',
      'user_type': 'student',
      'status': 'active',
      'email_verified': false,
    },
  };

  Future<Map<String, dynamic>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    final user = _users[email];
    
    if (user == null || user['password'] != password) {
      throw AuthException('Invalid login credentials');
    }

    if (!user['email_verified']) {
      throw AuthException('Email not confirmed');
    }

    return {
      'user': {
        'id': user['user_id'],
        'email': email,
        'email_verified': user['email_verified'],
      }
    };
  }

  Future<Map<String, dynamic>> getUserData(String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final user = _users.values.firstWhere(
      (u) => u['user_id'] == userId,
      orElse: () => {},
    );

    if (user.isEmpty) {
      throw Exception('User not found');
    }

    return {
      'user_type': user['user_type'],
      'status': user['status'],
    };
  }
}

// Login Validation Service
class LoginValidationService {
  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email field is required';
    }
    
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }
    
    return null;
  }

  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password field is required';
    }
    
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
}

// Login Service that uses MockAuthService
class LoginService {
  final MockAuthService authService;
  final LoginValidationService validationService;

  LoginService(this.authService, this.validationService);

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    // Validate email
    final emailError = validationService.validateEmail(email);
    if (emailError != null) {
      return LoginResult(
        success: false,
        errorMessage: emailError,
        errorType: LoginErrorType.validation,
      );
    }

    // Validate password
    final passwordError = validationService.validatePassword(password);
    if (passwordError != null) {
      return LoginResult(
        success: false,
        errorMessage: passwordError,
        errorType: LoginErrorType.validation,
      );
    }

    try {
      // Attempt sign in
      final response = await authService.signInWithPassword(
        email: email,
        password: password,
      );

      final userId = response['user']['id'];

      // Get user data
      final userData = await authService.getUserData(userId);
      
      // Check account status
      if (userData['status'] == 'suspended') {
        return LoginResult(
          success: false,
          errorMessage: 'Account is Suspended',
          errorType: LoginErrorType.accountSuspended,
        );
      }

      if (userData['status'] != 'active') {
        return LoginResult(
          success: false,
          errorMessage: 'Your account is not active. Please contact support.',
          errorType: LoginErrorType.accountInactive,
        );
      }

      // Success
      return LoginResult(
        success: true,
        userId: userId,
        userType: userData['user_type'],
      );

    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        return LoginResult(
          success: false,
          errorMessage: 'Invalid credentials',
          errorType: LoginErrorType.invalidCredentials,
        );
      } else if (e.message.contains('Email not confirmed') || 
                 e.message.contains('email_not_confirmed')) {
        return LoginResult(
          success: false,
          errorMessage: 'Your email address has not been verified. Please check your inbox and click the verification link before logging in.',
          errorType: LoginErrorType.emailNotVerified,
        );
      }
      
      return LoginResult(
        success: false,
        errorMessage: e.message,
        errorType: LoginErrorType.other,
      );
    } catch (e) {
      return LoginResult(
        success: false,
        errorMessage: 'Something went wrong. Please try again later.',
        errorType: LoginErrorType.other,
      );
    }
  }
}

// Result classes
class LoginResult {
  final bool success;
  final String? errorMessage;
  final LoginErrorType? errorType;
  final String? userId;
  final String? userType;

  LoginResult({
    required this.success,
    this.errorMessage,
    this.errorType,
    this.userId,
    this.userType,
  });
}

enum LoginErrorType {
  validation,
  invalidCredentials,
  accountSuspended,
  accountInactive,
  emailNotVerified,
  other,
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
