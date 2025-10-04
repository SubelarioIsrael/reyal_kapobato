import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          _showErrorDialog(
              'Your account has been suspended. Please contact support.');
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
          } else if (userType == 'parent') {
            Navigator.pushReplacementNamed(context, 'parent-home');
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
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
        errorMessage = 'Invalid email or password.';
      } else if (e.message.contains('Email not confirmed')) {
        errorMessage = 'Please confirm your email before logging in.';
      } else {
        errorMessage = e.message;
      }

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Login Failed'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Handle unexpected errors
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Login Failed'),
            content: const Text(
              'Something went wrong. Please try again later.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.spa, size: 80, color: Color(0xFF81C784)),
                const SizedBox(height: 20),
                const Text(
                  "BreatheBetter",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F646F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Welcome back. Take a deep breath and log in.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('login_email'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            final emailRegex = RegExp(
                              r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          key: const Key('login_password'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            key: const Key('login_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF81C784),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Log In',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  key: const Key('go_to_signup'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
                const SizedBox(height: 30),
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
