import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Get the Supabase client instance
  final _supabase = Supabase.instance.client;

  // Function to get user role and redirect
  Future<void> _redirectBasedOnRole(String userId) async {
    print('Fetching user role for userId: $userId');
    try {
      // Fetch user data from 'users' table based on the userId
      final userData = await _supabase
          .from('users')
          .select('user_type, status') // Select the user_type and status fields
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      // Log the response for debugging
      print('User Data: $userId');

      // Check if userData is not null and has a valid user_type and status
      if (userData != null &&
          userData['user_type'] != null &&
          userData['status'] != null) {
        final userType = userData['user_type'];
        final status = userData['status'];
        if (status == 'suspended') {
          _showAccountSuspendedDialog();
          return;
        }
        if (status != 'active') {
          _showErrorDialog(
              'Your account is not active. Please contact support.');
          return;
        }
        if (mounted) {
          // Redirect based on user_type
          if (userType == 'student') {
            Navigator.pushReplacementNamed(context, 'student-home');
          } else if (userType == 'counselor') {
            Navigator.pushReplacementNamed(context, 'counselor-home');
          } else if (userType == 'admin') {
            Navigator.pushReplacementNamed(context, 'admin-home');
          } else {
            _showErrorDialog('Invalid user type. Please contact support.');
          }
        }
      } else {
        // If userData is null or user_type/status is not found
        _showErrorDialog(
          'Could not determine user role or status. Please contact support.',
        );
      }
    } catch (e) {
      print('Error determining role: $e');
      _showErrorDialog('Could not retrieve user role. Please try again later.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to show error dialog
  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Login Failed',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7C83FD),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Helper method to show success dialog
  void _showSuccessDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4CAF50),
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7C83FD),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Helper method to show email not verified dialog
  void _showEmailNotVerifiedDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Email Not Verified',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
          content: Text(
            'Your email address has not been verified. Please check your inbox and click the verification link before logging in.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7C83FD),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Helper method to show account suspended dialog
  void _showAccountSuspendedDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Account Suspended',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          content: Text(
            'Your account has been suspended. Please contact support for assistance.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7C83FD),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Show forgot password dialog
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Reset Password',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A50),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: 'Email Address',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7C83FD)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5D5D72),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter your email address',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a valid email address',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() {
                  isLoading = true;
                });

                try {
                  await _supabase.auth.resetPasswordForEmail(
                    email,
                    redirectTo: 'breathebetter://reset-password', // Deep link to open the app directly
                  );
                  Navigator.pop(ctx);
                  _showSuccessDialog(
                    'Reset Link Sent',
                    'A password reset link has been sent to $email. Please check your inbox and follow the instructions to reset your password.',
                  );
                } on AuthException catch (e) {
                  Navigator.pop(ctx);
                  _showErrorDialog('Failed to send reset link: ${e.message}');
                } catch (e) {
                  Navigator.pop(ctx);
                  _showErrorDialog('Something went wrong. Please try again later.');
                } finally {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C83FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Send Reset Link',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with email and password using Supabase
      final response = await _supabase.auth
          .signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
          .timeout(const Duration(seconds: 10));

      // Check if we have a user
      if (response.user != null) {
        print("Logged in: ${response.user?.email}");

        // Check if email is verified
        if (response.user!.emailConfirmedAt == null) {
          _showEmailNotVerifiedDialog();
          // Sign out the user since email is not verified
          await _supabase.auth.signOut();
          return;
        }

        // Get user role from the database
        await _redirectBasedOnRole(response.user!.id);
      } else {
        // This should generally not happen as errors are thrown
        throw const AuthException("No user returned");
      }
    } on AuthException catch (e) {
      String errorMessage = '';

      // Handle specific error codes
      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'Please confirm your email before logging in.';
      } else if (e.message.contains('Email not confirmed') || 
                 e.message.contains('email_not_confirmed') ||
                 e.message.contains('signup_disabled')) {
        _showEmailNotVerifiedDialog();
        return;
      } else {
        errorMessage = e.message;
      }

      // Show error dialog
      if (mounted) {
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      // Handle unexpected errors
      if (mounted) {
        _showErrorDialog('Something went wrong. Please try again later.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                const Icon(Icons.spa, size: 80, color: Color(0xFF81C784)),
                const SizedBox(height: 20),
                // Title
                Text(
                  "BreatheBetter",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4F646F),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  "Welcome back. Take a deep breath and log in.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),
                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section title
                        
                        const SizedBox(height: 20),
                        TextFormField(
                          key: const Key('login_email'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            hintText: 'Email Address',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7C83FD)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email field is required';
                            }
                            final emailRegex = RegExp(
                              r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value)) {
                              return 'Invalid email format';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('login_password'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7C83FD)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password field is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF7C83FD),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            key: const Key('login_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C83FD),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Log In',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Signup Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    TextButton(
                      key: const Key('go_to_signup'),
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: Text(
                        "Sign up",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C83FD),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
