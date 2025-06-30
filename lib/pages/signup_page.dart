import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_wrapper.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _usernameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedCourse;
  final _yearLevelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _signup() async {
    // Only set loading state after all validation checks pass
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = authResponse.user;

        if (user != null) {
          // Assuming 'user.id' is the primary key for the 'users' table
          final userId = user.id;

          // Insert into the 'users' table (if needed, else this can be omitted)
          await Supabase.instance.client.from('users').insert({
            'user_id': userId, // foreign key to auth.users
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'registration_date': DateTime.now().toIso8601String(),
            'user_type': 'student', // or 'admin' based on your logic
          });

          // Insert into the 'students' table
          await Supabase.instance.client.from('students').insert({
            'user_id': userId, // foreign key to auth.users
            'student_code': _studentIdController.text.trim(),
            'course': _selectedCourse,
            'year_level': int.tryParse(_yearLevelController.text.trim()),
          });

          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } on AuthException catch (e) {
        print('Supabase Auth error: ${e.message}');
      } catch (e) {
        print('Signup error: $e');
      } finally {
        if (context.mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // List of courses (modify as needed)
    final List<String> courses = [
      'Computer Science',
      'Information Technology',
      'Software Engineering',
      'Data Science',
    ];

    return Scaffold(
      body: ResponsiveWrapper(
        scrollable: true,
        child: Center(
          child: Column(
            children: [
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              Icon(Icons.spa,
                  size: ResponsiveUtils.getResponsiveIconSize(
                    context,
                    small: 60.0,
                    medium: 70.0,
                    large: 80.0,
                  ),
                  color: const Color(0xFF81C784)),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              ResponsiveText(
                "Breathe Better",
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    small: 24.0,
                    medium: 26.0,
                    large: 28.0,
                  ),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4F646F),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              ResponsiveText(
                "Create an account to get started",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      small: 12.0,
                      medium: 13.0,
                      large: 14.0,
                    ),
                    color: Colors.grey.shade600),
              ),
              SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 2),
              ResponsiveContainer(
                padding: ResponsiveUtils.getResponsivePadding(context),
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
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          hintText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter your username'
                            : null,
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveSpacing(context)),
                      TextFormField(
                        controller: _studentIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Student ID',
                          prefixIcon: Icon(Icons.card_membership),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter your student ID'
                            : null,
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveSpacing(context)),
                      TextFormField(
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
                          return emailRegex.hasMatch(value)
                              ? null
                              : 'Enter a valid email';
                        },
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveSpacing(context)),
                      TextFormField(
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
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return value.length < 6
                              ? 'Password must be at least 6 characters'
                              : null;
                        },
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveSpacing(context)),
                      // Dropdown for Courses
                      DropdownButtonFormField<String>(
                        value: _selectedCourse,
                        decoration: const InputDecoration(
                          hintText: 'Select Course',
                          prefixIcon: Icon(Icons.school),
                        ),
                        items: courses.map((course) {
                          return DropdownMenuItem<String>(
                            value: course,
                            child: ResponsiveText(
                              course,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCourse = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a course' : null,
                        isExpanded: true,
                      ),

                      SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveSpacing(context)),
                      // Year Level Input (1 to 6)
                      TextFormField(
                        controller: _yearLevelController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Year Level (1-6)',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your year level';
                          }
                          final yearLevel = int.tryParse(value);
                          if (yearLevel == null ||
                              yearLevel < 1 ||
                              yearLevel > 6) {
                            return 'Please enter a valid year level (1-6)';
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveSpacing(context) *
                                  2),
                      SizedBox(
                        width: double.infinity,
                        height:
                            ResponsiveUtils.getResponsiveButtonHeight(context),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF81C784),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : () => _signup(),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : ResponsiveText(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveUtils.getResponsiveFontSize(
                                      context,
                                      small: 14.0,
                                      medium: 16.0,
                                      large: 18.0,
                                    ),
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
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Already have an account? Log in"),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
